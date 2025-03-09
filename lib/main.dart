import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plan Manager',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const PlanManagerScreen(title: 'Plan Manager'),
    );
  }
}

class Plan {
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
  // List of plans with name and completion status
  final List<Plan> _plans = [
    Plan(name: 'Plan 1'),
    Plan(name: 'Plan 2'),
    Plan(name: 'Plan 3'),
  ];

  // Method to add a new plan
  void _addPlan(String name) {
    setState(() {
      _plans.add(Plan(name: name));
    });
  }

  // Method to update the name of a plan
  void _updatePlan(int index, String newName) {
    setState(() {
      _plans[index].name = newName;
    });
  }

  // Method to toggle the completion status of a plan
  void _togglePlanCompletion(int index) {
    setState(() {
      _plans[index].isCompleted = !_plans[index].isCompleted;
    });
  }

  // Method to remove a plan from the list
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
      body: ListView.builder(
        itemCount: _plans.length,
        itemBuilder: (context, index) {
          final plan = _plans[index];
          return ListTile(
            title: Text(plan.name),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Checkbox to toggle completion status
                IconButton(
                  icon: Icon(plan.isCompleted ? Icons.check_box : Icons.check_box_outline_blank),
                  onPressed: () => _togglePlanCompletion(index),
                ),
                // Button to update the plan's name
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    _updatePlan(index, 'Updated Plan Name');
                  },
                ),
                // Button to delete the plan
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _removePlan(index),
                ),
              ],
            ),
            // Style for completed plan
            tileColor: plan.isCompleted ? Colors.green[100] : null,
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _addPlan('New Plan');
        },
        tooltip: 'Add Plan',
        child: const Icon(Icons.add),
      ),
    );
  }
}