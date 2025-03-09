import 'package:flutter/material.dart';

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

  Plan({required this.name, this.isCompleted = false});
}

class PlanManagerScreen extends StatefulWidget {
  const PlanManagerScreen({super.key, required this.title});

  final String title;

  @override
  State<PlanManagerScreen> createState() => _PlanManagerScreenState();
}

class _PlanManagerScreenState extends State<PlanManagerScreen> {
  final List<Plan> _plans = [
    Plan(name: 'Plan 1'),
    Plan(name: 'Plan 2'),
    Plan(name: 'Plan 3'),
  ];

  void _addPlan(String name) {
    setState(() {
      _plans.add(Plan(name: name));
    });
  }

  void _updatePlan(int index, String newName) {
    setState(() {
      _plans[index].name = newName;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _plans.length,
              itemBuilder: (context, index) {
                final plan = _plans[index];
                return Dismissible(
                  key: Key(plan.id),
                  onDismissed: (direction) {
                    _removePlan(index);
                  },
                  child: GestureDetector(
                    onLongPress: () async {
                      String? updatedName = await showDialog<String>(
                        context: context,
                        builder: (BuildContext context) {
                          final controller = TextEditingController(text: plan.name);
                          return AlertDialog(
                            title: const Text('Update Plan Name'),
                            content: TextField(
                              controller: controller,
                              decoration: const InputDecoration(hintText: 'Enter new name'),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context, controller.text);
                                },
                                child: const Text('Update'),
                              ),
                            ],
                          );
                        },
                      );

                      if (updatedName != null && updatedName.isNotEmpty) {
                        _updatePlan(index, updatedName);
                      }
                    },
                    onDoubleTap: () => _removePlan(index),
                    child: ListTile(
                      title: Text(plan.name),
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
          Center(
            child: ElevatedButton(
              onPressed: () {
                _addPlan('New Plan');
              },
              child: const Text('Create Plan'),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}