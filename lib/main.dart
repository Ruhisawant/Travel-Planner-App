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

  Plan({
    required this.name, 
    this.isCompleted = false, 
    this.date,
    required this.priority
  });
}

class PlanManagerScreen extends StatefulWidget {
  const PlanManagerScreen({super.key, required this.title});

  final String title;

  @override
  State<PlanManagerScreen> createState() => _PlanManagerScreenState();
}

class _PlanManagerScreenState extends State<PlanManagerScreen> {
  final List<Plan> _calendarPlans = [];
  final Map<DateTime, List<Plan>> _scheduledPlans = {};  // Stores plans for specific dates

  final List<Plan> _plans = [
    Plan(name: 'Plan 1', priority: 'High'),
    Plan(name: 'Plan 2', priority: 'Medium'),
    Plan(name: 'Plan 3', priority: 'Low'),
  ];

  void _addCalendarPlan(String name, DateTime date, String priority) {
    setState(() {
      final newPlan = Plan(name: name, date: date, priority: priority);
      _plans.add(newPlan);
      if (_scheduledPlans[date] == null) {
        _scheduledPlans[date] = [];
      }
      _scheduledPlans[date]?.add(newPlan);
    });
  }

  void _addPlan(String name, String priority) {
    setState(() {
      _plans.add(Plan(name: name, priority: priority));
      _sortPlans();
    });
  }

  void _updatePlan(int index, String newName, String newPriority) {
    setState(() {
      _plans[index].name = newName;
      _plans[index].priority = newPriority;
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
    String selectedPriority = index != null ? _plans[index].priority : 'Medium';

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(index == null ? 'Create New Plan' : 'Update Plan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(hintText: 'Enter plan name'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedPriority,
                items: ['High', 'Medium', 'Low']
                    .map((priority) => DropdownMenuItem(
                          value: priority,
                          child: Text(priority),
                        ))
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
                if (nameController.text.isNotEmpty) {
                  if (index == null) {
                    _addPlan(nameController.text, selectedPriority);
                  } else {
                    _updatePlan(index, nameController.text, selectedPriority);
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
          TableCalendar(
            focusedDay: DateTime.now(),
            firstDay: DateTime(2020),
            lastDay: DateTime(2030),
            selectedDayPredicate: (day) {
              return isSameDay(day, DateTime.now());
            },
            onDaySelected: (selectedDay, focusedDay) {
              showDialog<String>(
                context: context,
                builder: (BuildContext context) {
                  TextEditingController planController = TextEditingController();
                  String selectedPriority = 'Medium';
                  return AlertDialog(
                    title: const Text('Create Plan'),
                    content: Column(
                      children: [
                        TextField(
                          controller: planController,
                          decoration: const InputDecoration(hintText: 'Enter Plan Name'),
                        ),
                        DropdownButton<String>(
                          value: selectedPriority,
                          items: <String>['Low', 'Medium', 'High']
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedPriority = newValue!;
                            });
                          },
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
                          if (planController.text.isNotEmpty) {
                            _addCalendarPlan(planController.text, selectedDay, selectedPriority);
                          }
                          Navigator.pop(context);
                        },
                        child: const Text('Create'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          SizedBox(height: 50),

          Expanded(
            child: ListView.builder(
              itemCount: _plans.length,
              itemBuilder: (context, index) {
                final plan = _plans[index];
                return Dismissible(
                  key: Key(plan.id),
                  onDismissed: (direction) => _removePlan(index),
                  child: GestureDetector(
                    onLongPress: () => _showPlanDialog(index: index),
                    onDoubleTap: () => _removePlan(index),
                    child: ListTile(
                      title: Text(plan.name),
                      subtitle: Text('Priority: ${plan.priority}'),
                      trailing: IconButton(
                        icon: Icon(plan.isCompleted ? Icons.check_box : Icons.check_box_outline_blank),
                        onPressed: () => _togglePlanCompletion(index),
                      ),
                      tileColor: plan.isCompleted ? Colors.green[100] : null,
                    ),
                  ),
                );
              },
            ),
          ),

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