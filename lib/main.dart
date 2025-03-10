import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

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
  final String id = UniqueKey().toString();
  String name;
  bool isCompleted;
  DateTime? date;
  String priority;
  String description;

  Plan({
    this.isCompleted = false,
    required this.name,
    required this.description,
    required this.priority,
    required this.date,
  });
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

  final List<Plan> _plans = [
    Plan(
      name: 'Plan 1',
      description: 'description',
      priority: 'High',
      date: DateTime.now(),
    ),
    Plan(
      name: 'Plan 2',
      description: 'description',
      priority: 'Medium',
      date: DateTime.now(),
    ),
    Plan(
      name: 'Plan 3',
      description: 'description',
      priority: 'Low',
      date: DateTime.now(),
    ),
  ];

  void _addCalendarPlan(
    String name,
    String description,
    String priority,
    DateTime date,
  ) {
    setState(() {
      final newPlan = Plan(
        name: name,
        description: description,
        priority: priority,
        date: date,
      );
      _plans.add(newPlan);
      if (_scheduledPlans[date] == null) {
        _scheduledPlans[date] = [];
      }
      _scheduledPlans[date]?.add(newPlan);
    });
  }

  void _addPlan(
    String name,
    String description,
    String priority,
    DateTime date,
  ) {
    setState(() {
      _plans.add(
        Plan(
          name: name,
          description: description,
          priority: priority,
          date: date,
        ),
      );
      _sortPlans();
    });
  }

  void _updatePlan(
    int index,
    String newName,
    String newDescription,
    String newPriority,
    DateTime newDate,
  ) {
    setState(() {
      _plans[index].name = newName;
      _plans[index].description = newDescription;
      _plans[index].priority = newPriority;
      _plans[index].date = newDate;
      _sortPlans();
    });
  }

  void _togglePlanCompletion(int index) {
    setState(() {
      _plans[index].isCompleted = !_plans[index].isCompleted;
    });
  }

  void _removePlan(int index) {
    setState(() {
      _plans.removeAt(index);
    });
  }

  void _sortPlans() {
    _plans.sort((a, b) {
      const priorityOrder = {'High': 1, 'Medium': 2, 'Low': 3};
      return priorityOrder[a.priority]!.compareTo(priorityOrder[b.priority]!);
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
                ); // Reset time to 00:00:00
              });
            },
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, date, events) {
                return DragTarget<Plan>(
                  onAcceptWithDetails: (details) {
                    setState(() {
                      Plan receivedPlan = details.data;
                      receivedPlan.date = date; // Correctly updating the date
                      
                      _scheduledPlans[date] ??= [];
                      _scheduledPlans[date]!.add(receivedPlan);
                    });
                  },
                  builder: (context, candidateData, rejectedData) {
                    return Container(
                      margin: const EdgeInsets.all(4),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: candidateData.isNotEmpty ? Colors.blue.shade100 : null,
                      ),
                      child: Text('${date.day}'),
                    );
                  },
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
                  key: Key(plan.id),
                  onDismissed: (direction) => _removePlan(index),
                  child: GestureDetector(
                    onLongPress: () => _showPlanDialog(index: index),
                    onDoubleTap: () => _removePlan(index),
                    child: Draggable<Plan>(
                      data: plan,
                      feedback: Material(
                        child: Container(), // Empty container to avoid visual disruption
                      ),
                      childWhenDragging: Container(),
                      child: DragTarget<Plan>(
                        onAcceptWithDetails: (details) {
                          setState(() {
                            Plan receivedPlan = details.data;
                            receivedPlan.date = _selectedDate; // ✅ Use _selectedDate instead
                            _scheduledPlans[_selectedDate] ??= [];
                            _scheduledPlans[_selectedDate]!.add(receivedPlan);
                          });
                        },
                        builder: (context, candidateData, rejectedData) {
                          return Container(
                            margin: const EdgeInsets.all(8.0),
                            padding: const EdgeInsets.all(10),
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
                                      ? Icons.check_box
                                      : Icons.check_box_outline_blank,
                                ),
                                onPressed: () => _togglePlanCompletion(index),
                              ),
                              tileColor: plan.isCompleted
                                  ? Colors.green[100]
                                  : Colors.blue[100],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Create Plan Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () => _showPlanDialog(),
              child: const Text('Create Plan'),
            ),
          ),
        ],
      ),
    );
  }
}