import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GoalsScreen extends StatefulWidget {
  @override
  _GoalsScreenState createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final TextEditingController _goalController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? user = FirebaseAuth.instance.currentUser; // Get the current user

  // This function retrieves goals from Firestore, including their IDs
  Future<List<Map<String, dynamic>>> _fetchGoals() async {
    final querySnapshot = await _firestore.collection('goals').orderBy('deadline').get();
    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id; // Add the document ID to the data map
      return data;
    }).toList();
  }

  // This function adds a new goal to Firestore
  Future<void> _addGoal(String title, DateTime deadline) async {
    await _firestore.collection('goals').add({
      'title': title,
      'deadline': deadline,
      'completed': false,
      'userId': user!.uid,
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      setState(() {
        _dateController.text = picked.toLocal().toString().split(' ')[0]; // Format to YYYY-MM-DD
      });
    }
  }

  void _showAddGoalDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add New Goal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _goalController,
              decoration: InputDecoration(labelText: 'Goal Title'),
            ),
            TextField(
              controller: _dateController,
              readOnly: true, // Make the date field read-only
              decoration: InputDecoration(labelText: 'Deadline'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _selectDate(ctx), // Open date picker
              child: const Text(
                'Select Date',
                style: TextStyle(color: Colors.white), // Set text color to white
              ),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (_goalController.text.isEmpty || _dateController.text.isEmpty) return;

              // Parse the date from the input
              DateTime? deadline = DateTime.tryParse(_dateController.text);
              if (deadline != null) {
                await _addGoal(_goalController.text, deadline);
                _goalController.clear();
                _dateController.clear();
                Navigator.of(ctx).pop();
                setState(() {}); // Refresh the screen
              }
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  // This function toggles the completion status of a goal
  Future<void> _toggleGoalCompletion(String goalId, bool currentStatus) async {
    await _firestore.collection('goals').doc(goalId).update({'completed': !currentStatus});
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Savings Goals',
          style: TextStyle(
            fontWeight: FontWeight.bold, // Set the font weight to bold
          ),),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchGoals(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error fetching goals'));
          }

          // Filter out completed goals
          final goals = snapshot.data!.where((goal) => !goal['completed']).toList();

          return ListView.builder(
            itemCount: goals.length,
            itemBuilder: (ctx, index) {
              final goal = goals[index];
              return ListTile(
                title: Text(
                  goal['title'],
                  style: TextStyle(fontSize: 18),
                ),
                subtitle: Text(
                  'Deadline: ${goal['deadline'].toDate().toLocal()}',
                  style: TextStyle(fontSize: 12),
                ),
                trailing: IconButton(
                  icon: Icon(
                    Icons.check_box_outline_blank,
                    color: Colors.green,
                  ),
                  onPressed: () => _toggleGoalCompletion(goal['id'], goal['completed']),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddGoalDialog,
        child: Icon(Icons.add),
        backgroundColor: Colors.cyan, // Use your preferred color
      ),
    );
  }
}
