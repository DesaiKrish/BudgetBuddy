import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';  // Firestore import

class ExpensesScreen extends StatefulWidget {
  @override
  _ExpensesScreenState createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  DateTime selectedMonth = DateTime.now(); // Default to the current month
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime? selectedDate;
  User? user = FirebaseAuth.instance.currentUser; // Get the current user
  CollectionReference expensesCollection = FirebaseFirestore.instance.collection('expenses');

  // Function to show the month picker
  Future<void> _selectMonth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: 'Select Month',
      fieldHintText: 'Month/Year',
    );

    if (picked != null && picked != selectedMonth) {
      setState(() {
        selectedMonth = DateTime(picked.year, picked.month);
      });
    }
  }

  // Fetch expenses for the selected month from Firestore
  Stream<List<Map<String, dynamic>>> _fetchExpenses() {
    return expensesCollection
        .where('userId', isEqualTo: user!.uid)
        .where('date', isGreaterThanOrEqualTo: DateTime(selectedMonth.year, selectedMonth.month, 1))
        .where('date', isLessThan: DateTime(selectedMonth.year, selectedMonth.month + 1, 1))
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
      return {
        'date': (doc['date'] as Timestamp).toDate(),
        'amount': doc['amount'],
        'description': doc['description'],
      };
    }).toList());
  }

  // Calculate the total expenses for the selected month
  double _totalMonthlyExpenses(List<Map<String, dynamic>> expenses) {
    return expenses.fold(0.0, (sum, expense) => sum + expense['amount']);
  }

  // Add a new expense to Firestore
  Future<void> _addExpense() async {
    if (_amountController.text.isEmpty || _descriptionController.text.isEmpty || selectedDate == null) return;

    await expensesCollection.add({
      'date': selectedDate!,
      'amount': double.parse(_amountController.text),
      'description': _descriptionController.text,
      'userId': user!.uid,
    });

    _amountController.clear();
    _descriptionController.clear();
    selectedDate = null;
    Navigator.of(context).pop(); // Close the dialog
  }

  // Show the dialog to add a new expense
  void _showAddExpenseDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add New Expense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: 'Description'),
            ),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Amount'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (pickedDate != null) {
                  setState(() {
                    selectedDate = pickedDate;
                  });
                }
              },
              child: Text(
                selectedDate == null
                    ? 'Select Date'
                    : DateFormat('yyyy-MM-dd').format(selectedDate!),
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: _addExpense,
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Group Expenses'),
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: () => _selectMonth(context), // Open the month picker
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Expenses (${DateFormat('MMMM yyyy').format(selectedMonth)})',
              style: TextStyle(
                fontSize: 19.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            // StreamBuilder to fetch expenses from Firestore
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _fetchExpenses(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Text('Error fetching expenses');
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Text('No expenses found for this month.');
                  }

                  List<Map<String, dynamic>> expenses = snapshot.data!;
                  double totalExpenses = _totalMonthlyExpenses(expenses);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Expenses: \$${totalExpenses.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 20),
                      Expanded(
                        child: ListView.builder(
                          itemCount: expenses.length,
                          itemBuilder: (context, index) {
                            final expense = expenses[index];
                            return Card(
                              child: ListTile(
                                title: Text(expense['description']),
                                subtitle: Text(
                                    'Date: ${DateFormat('yyyy-MM-dd').format(expense['date'])}'),
                                trailing: Text(
                                  '\$${expense['amount'].toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.cyan,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddExpenseDialog,
        child: Icon(Icons.add),
        backgroundColor: Colors.cyan,
      ),
    );
  }
}
