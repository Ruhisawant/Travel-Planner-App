import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'database_helper.dart'; // Add this import

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Travel Planner',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const PlanManagerScreen(title: 'Home'),
    );
  }
}

class Plan {
  final int? id;
  String name;
  bool isCompleted;
  DateTime? date;
  String priority;
  String description;

  Plan({
    this.id,
    this.isCompleted = false,
    required this.name,
    required this.description,
    required this.priority,
    required this.date,
  });

  // Convert a Plan object into a Map object for storing in the database
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'priority': priority,
      'date': date?.toIso8601String(),
      'isCompleted': isCompleted ? 1 : 0,
    };
  }

  // Extract a Plan object from a Map object (for retrieving from the database)
  Plan.fromMap(Map<String, dynamic> map)
      : id = map['_id'],
        name = map['name'],
        description = map['description'],
        priority = map['priority'],
        date = DateTime.parse(map['date']),
        isCompleted = map['isCompleted'] == 1;

  // Define the copyWith method for updating a Plan object with new values
  Plan copyWith({
    int? id,
    String? name,
    bool? isCompleted,
    DateTime? date,
    String? priority,
    String? description,
  }) {
    return Plan(
      id: id ?? this.id,
      name: name ?? this.name,
      isCompleted: isCompleted ?? this.isCompleted,
      date: date ?? this.date,
      priority: priority ?? this.priority,
      description: description ?? this.description,
    );
  }
}

class PlanManagerScreen extends StatefulWidget {
  const PlanManagerScreen({super.key, required this.title});

  final String title;

  @override
  State<PlanManagerScreen> createState() => _PlanManagerScreenState();
}

class _PlanManagerScreenState extends State<PlanManagerScreen> {
  final Map<DateTime, List<Plan>> _scheduledPlans = {};
  DateTime _selectedDate = DateTime.now();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;  // Initialize the database helper

  List<Plan> _plans = [];

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  // Fetch plans from the database
  void _loadPlans() async {
    final plans = await _dbHelper.getPlans();
    setState(() {
      _plans = plans;
    });
  }

  void _addPlan(
    String name,
    String description,
    String priority,
    DateTime date,
  ) async {
    Plan newPlan = Plan(
      name: name,
      description: description,
      priority: priority,
      date: date,
    );
    int id = await _dbHelper.insertPlan(newPlan); // Add to database
    setState(() {
      newPlan = newPlan.copyWith(id: id); // Update with ID returned from the DB
      _plans.add(newPlan);
    });
  }

  void _updatePlan(
    int index,
    String newName,
    String newDescription,
    String newPriority,
    DateTime newDate,
  ) async {
    Plan updatedPlan = _plans[index].copyWith(
      name: newName,
      description: newDescription,
      priority: newPriority,
      date: newDate,
    );
    await _dbHelper.updatePlan(updatedPlan);
    setState(() {
      _plans[index] = updatedPlan;
    });
  }

  void _togglePlanCompletion(int index) async {
    Plan updatedPlan = _plans[index].copyWith(
      isCompleted: !_plans[index].isCompleted,
    );
    await _dbHelper.updatePlan(updatedPlan);
    setState(() {
      _plans[index] = updatedPlan;
    });
  }

  void _removePlan(int index) async {
    await _dbHelper.deletePlan(_plans[index].id!);
    setState(() {
      _plans.removeAt(index);
    });
  }

  Future<void> _showPlanDialog({int? index}) async {
    final TextEditingController nameController = TextEditingController(
      text: index != null ? _plans[index].name : '',
    );
    final TextEditingController descriptionController = TextEditingController(
      text: index != null ? _plans[index].description : '',
    );
    String selectedPriority = index != null ? _plans[index].priority : 'Medium';
    DateTime selectedDate =
        index != null ? _plans[index].date ?? DateTime.now() : DateTime.now();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(index == null ? 'Create New Plan' : 'Update Plan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Plan Name
              TextField(
                controller: nameController,
                decoration: const InputDecoration(hintText: 'Enter plan name'),
              ),

              const SizedBox(height: 10),
              // Plan Description
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  hintText: 'Enter plan description',
                ),
              ),

              const SizedBox(height: 10),
              // Date Picker
              TextButton(
                onPressed: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null && picked != selectedDate) {
                    setState(() {
                      selectedDate = picked;
                    });
                  }
                },
                child: Text('Select Date: ${selectedDate.toLocal()}'),
              ),

              const SizedBox(height: 10),
              // Priority Dropdown
              DropdownButtonFormField<String>(
                value: selectedPriority,
                items:
                    ['High', 'Medium', 'Low']
                        .map(
                          (priority) => DropdownMenuItem(
                            value: priority,
                            child: Text(priority),
                          ),
                        )
                        .toList(),
                onChanged: (value) {
                  selectedPriority = value!;
                },
                decoration: const InputDecoration(labelText: 'Select Priority'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (nameController.text.isNotEmpty &&
                    descriptionController.text.isNotEmpty) {
                  if (index == null) {
                    _addPlan(
                      nameController.text,
                      descriptionController.text,
                      selectedPriority,
                      selectedDate,
                    );
                  } else {
                    _updatePlan(
                      index,
                      nameController.text,
                      descriptionController.text,
                      selectedPriority,
                      selectedDate,
                    );
                  }
                }
                Navigator.pop(context);
              },
              child: Text(index == null ? 'Create' : 'Update'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          // Calendar Widget
          TableCalendar(
            focusedDay: DateTime.now(),
            firstDay: DateTime(2020),
            lastDay: DateTime(2030),
            selectedDayPredicate: (day) {
              return isSameDay(day, DateTime.now());
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDate = DateTime(
                  selectedDay.year,
                  selectedDay.month,
                  selectedDay.day,
                );
              });
            },
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, date, events) {
                return Container(
                  margin: const EdgeInsets.all(4),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('${date.day}'),
                );
              },
            ),
          ),
          const SizedBox(height: 50),

          // ListView for plans
          Expanded(
            child: ListView.builder(
              itemCount: _plans.length,
              itemBuilder: (context, index) {
                final plan = _plans[index];
                Color priorityColor;

                // Set priority text color based on the priority level
                switch (plan.priority) {
                  case 'High':
                    priorityColor = Colors.red;
                    break;
                  case 'Medium':
                    priorityColor = Colors.orange;
                    break;
                  case 'Low':
                    priorityColor = Colors.amber;
                    break;
                  default:
                    priorityColor = Colors.black;
                }

                return Dismissible(
                  key: Key(plan.id.toString()),
                  onDismissed: (direction) => _removePlan(index),
                  child: ListTile(
                    title: Text(plan.name),
                    subtitle: Row(
                      children: [
                        Text(
                          'Priority: ',
                          style: TextStyle(color: Colors.black),
                        ),
                        Text(
                          plan.priority,
                          style: TextStyle(
                            color: priorityColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          ' | Date: ${plan.date?.toLocal().toString().split(' ')[0]}',
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: Icon(
                        plan.isCompleted
                            ? Icons.check_circle
                            : Icons.check_circle_outline,
                      ),
                      onPressed: () => _togglePlanCompletion(index),
                    ),
                    onTap: () => _showPlanDialog(index: index),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPlanDialog(),
        tooltip: 'Add Plan',
        child: const Icon(Icons.add),
      ),
    );
  }
}
