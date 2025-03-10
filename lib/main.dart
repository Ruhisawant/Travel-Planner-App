import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'database_helper.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized(); // Important for database initialization
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Travel & Adoption Planner',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: PlanManagerScreen(),
    );
  }
}

class PlanManagerScreen extends StatefulWidget {
  const PlanManagerScreen({Key? key}) : super(key: key);

  @override
  PlanScreenState createState() => PlanScreenState();
}

class PlanScreenState extends State<PlanManagerScreen> {
  List<Plan> plans = [];
  final dateFormat = DateFormat('MMM d, yyyy');
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  
  // For drag plan creation
  final _dragPlaceholder = Plan(
    id: -1,
    name: 'New Plan',
    description: 'Drag to create',
    date: DateTime.now(),
    priority: 'Medium',
    isCompleted: false,
  );
  
  @override
  void initState() {
    super.initState();
    _loadPlansFromDatabase();
  }
  
  Future<void> _loadPlansFromDatabase() async {
    final loadedPlans = await DatabaseHelper.instance.getPlans();
    setState(() {
      plans = loadedPlans;
      // Sort plans by priority (High > Medium > Low)
      _sortPlansByPriority();
    });
  }
  
  void _sortPlansByPriority() {
    plans.sort((a, b) {
      // First sort by priority
      final priorityComparison = _getPriorityValue(b.priority).compareTo(_getPriorityValue(a.priority));
      if (priorityComparison != 0) return priorityComparison;
      
      // Then by date
      return a.date.compareTo(b.date);
    });
  }
  
  int _getPriorityValue(String priority) {
    switch (priority) {
      case 'High': return 3;
      case 'Medium': return 2;
      case 'Low': return 1;
      default: return 0;
    }
  }

  Future<void> _createPlan(String name, String description, DateTime date, String priority) async {
    if (name.isEmpty) return; // Don't create plans with empty names
    
    final newPlan = Plan(
      id: DateTime.now().millisecondsSinceEpoch,
      name: name,
      description: description,
      date: date,
      priority: priority,
      isCompleted: false,
    );
    
    // Add to database
    await DatabaseHelper.instance.insertPlan(newPlan);
    
    setState(() {
      plans.add(newPlan);
      _sortPlansByPriority();
    });
  }

  Future<void> _updatePlan(Plan plan) async {
    await DatabaseHelper.instance.updatePlan(plan);
    setState(() {
      _sortPlansByPriority();
    });
  }

  Future<void> _deletePlan(Plan plan) async {
    await DatabaseHelper.instance.deletePlan(plan.id);
    
    setState(() {
      plans.remove(plan);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Plan "${plan.name}" deleted'),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () async {
            await DatabaseHelper.instance.insertPlan(plan);
            setState(() {
              plans.add(plan);
              _sortPlansByPriority();
            });
          },
        ),
      ),
    );
  }

  Future<void> _togglePlanCompletion(Plan plan) async {
    setState(() {
      plan.isCompleted = !plan.isCompleted;
    });
    await DatabaseHelper.instance.updatePlan(plan);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Travel & Adoption Planner'),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildCalendar(),
          Divider(height: 1),
          Expanded(
            child: plans.isEmpty 
                ? _buildEmptyState() 
                : _buildPlansList(),
          ),
        ],
      ),
      floatingActionButton: _buildDraggablePlanCreator(),
    );
  }
  
  Widget _buildCalendar() {
    // Group plans by date for the event marker
    Map<DateTime, List<Plan>> plansByDay = {};
    for (var plan in plans) {
      final date = DateTime(plan.date.year, plan.date.month, plan.date.day);
      if (plansByDay[date] == null) plansByDay[date] = [];
      plansByDay[date]!.add(plan);
    }
    
    return TableCalendar(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,
      calendarFormat: _calendarFormat,
      eventLoader: (day) {
        final date = DateTime(day.year, day.month, day.day);
        return plansByDay[date] ?? [];
      },
      selectedDayPredicate: (day) {
        return isSameDay(_selectedDay, day);
      },
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
      },
      onFormatChanged: (format) {
        setState(() {
          _calendarFormat = format;
        });
      },
      onPageChanged: (focusedDay) {
        _focusedDay = focusedDay;
      },
      calendarStyle: CalendarStyle(
        markersMaxCount: 3,
        markerDecoration: BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
        ),
      ),
      // Make the calendar a drop target for plans
      calendarBuilders: CalendarBuilders(
        defaultBuilder: (context, date, _) {
          return DragTarget<Plan>(
            builder: (context, candidateData, rejectedData) {
              return Container(
                margin: const EdgeInsets.all(4.0),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: candidateData.isNotEmpty ? Colors.blue.withOpacity(0.3) : null,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  '${date.day}',
                  style: TextStyle(
                    color: candidateData.isNotEmpty ? Colors.blue[800] : null,
                  ),
                ),
              );
            },
            onAccept: (plan) {
              // If it's the placeholder plan, show create dialog instead
              if (plan.id == -1) {
                _showCreatePlanModal(context, initialDate: date);
              } else {
                // Update the plan's date
                setState(() {
                  plan.date = date;
                  _updatePlan(plan);
                });
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildDraggablePlanCreator() {
    return Draggable<Plan>(
      data: _dragPlaceholder,
      feedback: Card(
        elevation: 4,
        color: Colors.blue,
        child: Container(
          padding: EdgeInsets.all(16),
          child: Text(
            'New Plan',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      childWhenDragging: FloatingActionButton(
        onPressed: null,
        backgroundColor: Colors.grey,
        child: Icon(Icons.add, color: Colors.white70),
      ),
      child: FloatingActionButton(
        onPressed: () => _showCreatePlanModal(context),
        child: Icon(Icons.add),
        tooltip: 'Create New Plan',
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.landscape, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No plans yet',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Drag the + button to a date or tap it to create a new plan',
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPlansList() {
    return ReorderableListView.builder(
      padding: EdgeInsets.all(8.0),
      itemCount: plans.length,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (oldIndex < newIndex) {
            newIndex -= 1;
          }
          final item = plans.removeAt(oldIndex);
          plans.insert(newIndex, item);
        });
      },
      itemBuilder: (context, index) {
        final plan = plans[index];
        return _buildPlanItem(plan, index);
      },
    );
  }
  
  Widget _buildPlanItem(Plan plan, int index) {
    return Draggable<Plan>(
      key: ValueKey(plan.id),
      data: plan,
      feedback: Card(
        elevation: 4,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          padding: EdgeInsets.all(16),
          child: Text(
            plan.name,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
      childWhenDragging: Container(
        height: 0,
      ),
      child: GestureDetector(
        // Double tap to delete
        onDoubleTap: () => _deletePlan(plan),
        // Long press to edit
        onLongPress: () => _showEditPlanModal(context, plan),
        child: Dismissible(
          key: Key(plan.id.toString()),
          background: Container(
            color: Colors.green,
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.only(left: 20.0),
            child: Icon(Icons.check, color: Colors.white),
          ),
          secondaryBackground: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: EdgeInsets.only(right: 20.0),
            child: Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (direction) {
            if (direction == DismissDirection.endToStart) {
              _deletePlan(plan);
            } else {
              _togglePlanCompletion(plan);
            }
          },
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.startToEnd) {
              await _togglePlanCompletion(plan);
              return false; // Don't dismiss, just toggle completion
            }
            return true; // Allow dismiss for delete
          },
          child: Card(
            elevation: 2,
            margin: EdgeInsets.symmetric(vertical: 6.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: _getPriorityColor(plan.priority).withOpacity(0.5),
                width: 1.5,
              ),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              leading: IconButton(
                icon: Icon(
                  plan.isCompleted
                      ? Icons.check_circle
                      : Icons.circle_outlined,
                  color: plan.isCompleted ? Colors.green : Colors.grey,
                  size: 28,
                ),
                onPressed: () => _togglePlanCompletion(plan),
              ),
              title: Text(
                plan.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  decoration: plan.isCompleted ? TextDecoration.lineThrough : null,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 4),
                  Text(plan.description),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                      SizedBox(width: 4),
                      Text(
                        dateFormat.format(plan.date),
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      SizedBox(width: 12),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getPriorityColor(plan.priority).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          plan.priority,
                          style: TextStyle(
                            fontSize: 12,
                            color: _getPriorityColor(plan.priority),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Double-tap to delete\nLong-press to edit',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                    textAlign: TextAlign.right,
                  ),
                  Icon(Icons.drag_handle, color: Colors.grey),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'High':
        return Colors.red[700]!;
      case 'Medium':
        return Colors.orange[700]!;
      case 'Low':
        return Colors.green[700]!;
      default:
        return Colors.blue[700]!;
    }
  }

  void _showCreatePlanModal(BuildContext context, {DateTime? initialDate}) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime selectedDate = initialDate ?? DateTime.now();
    String selectedPriority = 'Medium';
    
    // This ensures the state updates correctly inside the modal
    StateSetter? modalSetState;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            modalSetState = setModalState;
            
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16.0,
                right: 16.0,
                top: 16.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create New Plan',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Plan Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.flight),
                    ),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 3,
                  ),
                  SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2101),
                      );
                      if (pickedDate != null) {
                        modalSetState!(() {
                          selectedDate = pickedDate;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Date',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(dateFormat.format(selectedDate)),
                    ),
                  ),
                  SizedBox(height: 12),
                  InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Priority',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.flag),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedPriority,
                        isDense: true,
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            modalSetState!(() {
                              selectedPriority = newValue;
                            });
                          }
                        },
                        items: ['Low', 'Medium', 'High']
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: _getPriorityColor(value),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(value),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('CANCEL'),
                      ),
                      SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          if (nameController.text.isNotEmpty) {
                            _createPlan(
                              nameController.text,
                              descriptionController.text,
                              selectedDate,
                              selectedPriority,
                            );
                            Navigator.pop(context);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Plan name cannot be empty')),
                            );
                          }
                        },
                        child: Text('CREATE'),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showEditPlanModal(BuildContext context, Plan plan) {
    final nameController = TextEditingController(text: plan.name);
    final descriptionController = TextEditingController(text: plan.description);
    DateTime selectedDate = plan.date;
    String selectedPriority = plan.priority;
    
    StateSetter? modalSetState;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            modalSetState = setModalState;
            
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16.0,
                right: 16.0,
                top: 16.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Edit Plan',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Plan Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.flight),
                    ),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 3,
                  ),
                  SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2101),
                      );
                      if (pickedDate != null) {
                        modalSetState!(() {
                          selectedDate = pickedDate;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Date',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(dateFormat.format(selectedDate)),
                    ),
                  ),
                  SizedBox(height: 12),
                  InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Priority',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.flag),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedPriority,
                        isDense: true,
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            modalSetState!(() {
                              selectedPriority = newValue;
                            });
                          }
                        },
                        items: ['Low', 'Medium', 'High']
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: _getPriorityColor(value),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(value),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('CANCEL'),
                      ),
                      SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          if (nameController.text.isNotEmpty) {
                            setState(() {
                              plan.name = nameController.text;
                              plan.description = descriptionController.text;
                              plan.date = selectedDate;
                              plan.priority = selectedPriority;
                              _updatePlan(plan);
                            });
                            Navigator.pop(context);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Plan name cannot be empty')),
                            );
                          }
                        },
                        child: Text('SAVE'),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class Plan {
  final int id;
  String name;
  String description;
  DateTime date;
  String priority;
  bool isCompleted;

  Plan({
    required this.id,
    required this.name,
    required this.description,
    required this.date,
    required this.priority,
    this.isCompleted = false,
  });

  // Convert Plan object into a Map for the database
  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'name': name,
      'description': description,
      'priority': priority,
      'date': date.toIso8601String(),
      'isCompleted': isCompleted ? 1 : 0,
    };
  }

  // Convert a Map from the database into a Plan object
  static Plan fromMap(Map<String, dynamic> map) {
    return Plan(
      id: map['_id'],
      name: map['name'],
      description: map['description'],
      priority: map['priority'],
      date: DateTime.parse(map['date']),
      isCompleted: map['isCompleted'] == 1,
    );
  }
}