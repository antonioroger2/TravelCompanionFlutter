import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'sign_up_page.dart';
import 'forgot_password_page.dart';
import 'home_page.dart';

import 'package:geolocator/geolocator.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

import 'package:intl/intl.dart';

void main() {
  runApp(const TravelExpenseApp());
}

class TravelExpenseApp extends StatelessWidget {
  const TravelExpenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tour App',
      theme: ThemeData(
        primaryColor: Colors.blue,
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: Colors.orangeAccent,
        ),
        scaffoldBackgroundColor: const Color(0xFFF3F5F7),
      ),
      home: const TravelExpensePage(),
    );
  }
}

class TravelExpensePage extends StatefulWidget {
  const TravelExpensePage({super.key});

  @override
  _TravelExpensePageState createState() => _TravelExpensePageState();
}

class _TravelExpensePageState extends State<TravelExpensePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const RecordsPage(),
    const AnalysisPage(),
    const BudgetsPage(),
    const AccountsPage(),
    const CategoriesPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Gradient Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Column(
            children: [
              // Navigation Bar
              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
              ),
              // Title at the Center-Top
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 0.5),
                  child: Text(
                    'Expense Tracker',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 50),
              // MainBar Widget
              MainBar(
                selectedIndex: _selectedIndex,
                onSelect: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
              ),
              const SizedBox(height: 20),
              // Dynamic Content Below the Bar
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _pages[_selectedIndex],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MainBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const MainBar({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.6,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildIconWithLabel(
                icon: Icons.receipt,
                label: "Records",
                isSelected: selectedIndex == 0,
                onTap: () => onSelect(0),
              ),
              _buildIconWithLabel(
                icon: Icons.analytics,
                label: "Analysis",
                isSelected: selectedIndex == 1,
                onTap: () => onSelect(1),
              ),
              _buildIconWithLabel(
                icon: Icons.attach_money,
                label: "Budgets",
                isSelected: selectedIndex == 2,
                onTap: () => onSelect(2),
              ),
              _buildIconWithLabel(
                icon: Icons.account_circle,
                label: "Accounts",
                isSelected: selectedIndex == 3,
                onTap: () => onSelect(3),
              ),
              _buildIconWithLabel(
                icon: Icons.category,
                label: "Categories",
                isSelected: selectedIndex == 4,
                onTap: () => onSelect(4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconWithLabel({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white.withOpacity(0.3)
                  : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

//Records Page

class RecordsPage extends StatefulWidget {
  const RecordsPage({super.key});

  @override
  State<RecordsPage> createState() => _RecordsPageState();
}

class _RecordsPageState extends State<RecordsPage> {
  String selectedType = "Income"; // Default radio button value
  DateTime currentFilterDate = DateTime.now(); // For date filtering
  double totalIncome = 0.0;
  double totalSpent = 0.0;
  double total = 0.0; // Add this line

  // Form fields for Income and Expense subforms
  String? selectedExpenseName;
  String? selectedTaskName;
  double? inputAmount;
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    fetchTotals();
  }

  Future<void> updateFinalCollection(
      double incomeTotal, double expenseTotal) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Sanitize email
    final sanitizedEmail = user.email!.replaceAll('.', '_');
    final dateKey = "${currentFilterDate.month}/${currentFilterDate.year}";
    final docRef = FirebaseFirestore.instance
        .collection('final')
        .doc("$sanitizedEmail-${dateKey.replaceAll('/', '_')}");

    final doc = await docRef.get();

    if (doc.exists) {
      await docRef.update({
        'totalIncome': incomeTotal,
        'totalSpent': expenseTotal,
      });
    } else {
      await docRef.set({
        'email': user.email,
        'date': dateKey,
        'totalIncome': incomeTotal,
        'totalSpent': expenseTotal,
      });
    }
  }

  void openAddRecordForm() {
    // Clear fields to avoid conflicts
    setState(() {
      selectedExpenseName = null;
      selectedTaskName = null;
      inputAmount = null;
      selectedDate = DateTime.now();
    });
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("User not logged in."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Record'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Radio Buttons for selecting Income/Expense
                    Row(
                      children: [
                        Radio<String>(
                          value: "Income",
                          groupValue: selectedType,
                          onChanged: (value) {
                            setDialogState(() {
                              selectedType = value!;
                              selectedTaskName = null;
                              selectedExpenseName = null;
                              inputAmount = null;
                            });
                          },
                        ),
                        const Text('Income'),
                        Radio<String>(
                          value: "Expense",
                          groupValue: selectedType,
                          onChanged: (value) {
                            setDialogState(() {
                              selectedType = value!;
                              selectedTaskName = null;
                              selectedExpenseName = null;
                              inputAmount = null;
                            });
                          },
                        ),
                        const Text('Expense'),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Income Subform
                    if (selectedType == "Income")
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Select Account",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          FutureBuilder<QuerySnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('expenses')
                                .where('userEmail',
                                    isEqualTo: user
                                        .email) // Filter by logged-in user's email
                                .get(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const CircularProgressIndicator();
                              }

                              final incomeNames = snapshot.data!.docs
                                  .map((doc) => doc['name'].toString())
                                  .toList();

                              return DropdownButton<String>(
                                value: selectedExpenseName,
                                isExpanded: true,
                                hint: const Text("Select Account Name"),
                                underline: const SizedBox.shrink(),
                                items: incomeNames
                                    .map<DropdownMenuItem<String>>((name) {
                                  return DropdownMenuItem<String>(
                                    value: name,
                                    child: Text(name),
                                  );
                                }).toList(),
                                onChanged: (value) => setDialogState(
                                    () => selectedExpenseName = value),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "Select Category",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          FutureBuilder<QuerySnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('categories')
                                .where('name', isEqualTo: "Income")
                                .where('userEmail',
                                    isEqualTo:
                                        user.email) // Add filter for user email
                                .get(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const CircularProgressIndicator();
                              }

                              final taskList = snapshot.data!.docs
                                  .expand((doc) => (doc['tasks'] as List)
                                      .map((task) => task.toString()))
                                  .toList();

                              return DropdownButton<String>(
                                value: selectedTaskName,
                                isExpanded: true,
                                hint: const Text("Select Category"),
                                underline: const SizedBox.shrink(),
                                items: taskList
                                    .map<DropdownMenuItem<String>>((task) {
                                  return DropdownMenuItem<String>(
                                    value: task,
                                    child: Text(task),
                                  );
                                }).toList(),
                                onChanged: (value) => setDialogState(
                                    () => selectedTaskName = value),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),

                    // Expense Subform
                    if (selectedType == "Expense")
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Select Account",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          FutureBuilder<QuerySnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('expenses')
                                .where('userEmail',
                                    isEqualTo: user
                                        .email) // Filter by logged-in user's email
                                .get(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const CircularProgressIndicator();
                              }

                              final expenseNames = snapshot.data!.docs
                                  .map((doc) => doc['name'].toString())
                                  .toList();

                              return DropdownButton<String>(
                                value: selectedExpenseName,
                                isExpanded: true,
                                hint: const Text("Select Account Name"),
                                underline: const SizedBox.shrink(),
                                items: expenseNames
                                    .map<DropdownMenuItem<String>>((name) {
                                  return DropdownMenuItem<String>(
                                    value: name,
                                    child: Text(name),
                                  );
                                }).toList(),
                                onChanged: (value) => setDialogState(
                                    () => selectedExpenseName = value),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "Select Category",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          FutureBuilder<QuerySnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('categories')
                                .where('name', isEqualTo: "Expenses")
                                .where('userEmail',
                                    isEqualTo:
                                        user.email) // Add filter for user email
                                .get(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const CircularProgressIndicator();
                              }

                              final taskList = snapshot.data!.docs
                                  .expand((doc) => (doc['tasks'] as List)
                                      .map((task) => task.toString()))
                                  .toList();

                              return DropdownButton<String>(
                                value: selectedTaskName,
                                isExpanded: true,
                                hint: const Text("Select Categories Name"),
                                underline: const SizedBox.shrink(),
                                items: taskList
                                    .map<DropdownMenuItem<String>>((task) {
                                  return DropdownMenuItem<String>(
                                    value: task,
                                    child: Text(task),
                                  );
                                }).toList(),
                                onChanged: (value) => setDialogState(
                                    () => selectedTaskName = value),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),

                    // Amount Input Field
                    TextField(
                      decoration: InputDecoration(
                        labelText: "Amount",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0)),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) =>
                          inputAmount = double.tryParse(value),
                    ),
                    const SizedBox(height: 16),

                    // Date Picker Field
                    TextField(
                      controller: TextEditingController(
                        text: selectedDate != null
                            ? "${selectedDate!.month}/${selectedDate!.year}"
                            : "",
                      ),
                      decoration: InputDecoration(
                        labelText: "Date (MM/YYYY)",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0)),
                        suffixIcon: const Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: selectedDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (pickedDate != null) {
                          setDialogState(() => selectedDate = pickedDate);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (inputAmount == null ||
                        selectedDate == null ||
                        (selectedType == "Expense" &&
                            selectedExpenseName == null) ||
                        (selectedType == "Income" &&
                            selectedTaskName == null)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Please fill all required fields!"),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    try {
                      await FirebaseFirestore.instance
                          .collection('history')
                          .add({
                        'type': selectedType,
                        'name': selectedType == "Income"
                            ? selectedExpenseName
                            : selectedExpenseName,
                        'task': selectedTaskName,
                        'amount': inputAmount,
                        'date': "${selectedDate!.month}/${selectedDate!.year}",
                        'email': user.email,
                      });

                      await fetchTotals(); // Refresh totals after submission
                      Navigator.pop(context);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Error: $e"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> fetchTotals() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final dateKey = "${currentFilterDate.month}/${currentFilterDate.year}";
    double incomeSum = 0.0;
    double expenseSum = 0.0;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('history')
          .where('email', isEqualTo: user.email)
          .where('date', isEqualTo: dateKey)
          .get();

      for (var doc in snapshot.docs) {
        final amount = (doc['amount'] as num).toDouble();
        if (doc['type'] == 'Income') {
          incomeSum += amount;
        } else if (doc['type'] == 'Expense') {
          expenseSum += amount;
        }
      }
      final totalValue = incomeSum - expenseSum; // Calculate total

      setState(() {
        totalIncome = incomeSum;
        totalSpent = expenseSum;
        total = totalValue;
      });
      await FirebaseFirestore.instance.collection('final').add({
        'email': user.email,
        'date': dateKey,
        'total': totalValue,
        'Income': totalIncome,
        'Spent': totalSpent
      });
      await updateFinalCollection(incomeSum, expenseSum);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error fetching totals: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void changeFilterDate(int months) {
    setState(() {
      currentFilterDate =
          DateTime(currentFilterDate.year, currentFilterDate.month + months, 1);
    });
    fetchTotals();
  }

  Stream<QuerySnapshot> getFilteredRecords() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection('history')
        .where('date',
            isEqualTo: "${currentFilterDate.month}/${currentFilterDate.year}")
        .where('email', isEqualTo: user.email)
        .snapshots();
  }

  void openEditRecordForm(
      BuildContext context, Map<String, dynamic> record, String recordId) {
    String updatedName = record['name'];
    String updatedTask = record['task'];
    double? updatedAmount = record['amount'];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Record'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Name'),
                controller: TextEditingController(text: record['name']),
                onChanged: (value) => updatedName = value,
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Task'),
                controller: TextEditingController(text: record['task']),
                onChanged: (value) => updatedTask = value,
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Amount'),
                controller:
                    TextEditingController(text: record['amount'].toString()),
                keyboardType: TextInputType.number,
                onChanged: (value) => updatedAmount = double.tryParse(value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (updatedName.isEmpty ||
                    updatedTask.isEmpty ||
                    updatedAmount == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("All fields are required!"),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  await FirebaseFirestore.instance
                      .collection('history')
                      .doc(recordId)
                      .update({
                    'name': updatedName,
                    'task': updatedTask,
                    'amount': updatedAmount,
                  });

                  Navigator.pop(context); // Close the dialog
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Error: $e"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void confirmDeleteRecord(BuildContext context, String recordId) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Delete Record"),
          content: const Text("Are you sure you want to delete this record?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close the dialog only
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  // Perform deletion
                  await FirebaseFirestore.instance
                      .collection('history')
                      .doc(recordId)
                      .delete();

                  // Close the dialog after successful deletion
                  Navigator.of(dialogContext).pop();

                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Record deleted successfully."),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  // Close the dialog in case of an error
                  Navigator.of(dialogContext).pop();

                  // Show error message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Error: $e"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Make the background transparent

      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 16.0, bottom: 16.0),
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: GestureDetector(
              onTap: openAddRecordForm,
              child: const Text(
                "+ Add Record",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () => changeFilterDate(-1),
                  icon: const Icon(
                    Icons.arrow_back_ios,
                    color: Colors.white, // Change icon color to white
                  ),
                ),
                const SizedBox(width: 12.0),
                Text(
                  "${DateFormat('MMMM yyyy').format(currentFilterDate)}",
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white, // Change text color to white
                  ),
                ),
                const SizedBox(width: 12.0),
                IconButton(
                  onPressed: () => changeFilterDate(1),
                  icon: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white, // Change icon color to white
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    const Text(
                      'Total Income',
                      style: TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      totalIncome.toStringAsFixed(2),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      total.toStringAsFixed(2),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: total >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Text(
                      'Total Spent',
                      style: TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      totalSpent.toStringAsFixed(2),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: getFilteredRecords(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "No records found.",
                      style: TextStyle(
                          color: Colors.white), // Change text color to white
                    ),
                  );
                }

                return ListView(
                  children: snapshot.data!.docs.map((doc) {
                    final record = doc.data() as Map<String, dynamic>;
                    final recordId =
                        doc.id; // Document ID for editing or deleting

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12.0, vertical: 6.0),
                      color: Colors.black.withOpacity(0.5), // Transparent card
                      child: ListTile(
                        title: Text(
                          record['name'] ?? '',
                          style: const TextStyle(
                              color:
                                  Colors.white), // Change text color to white
                        ),
                        subtitle: Text(
                          record['task'] ?? '',
                          style: const TextStyle(
                              color:
                                  Colors.white), // Change text color to white
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              record['amount'].toStringAsFixed(2),
                              style: const TextStyle(
                                  color: Colors
                                      .white), // Change text color to white
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.white),
                              onPressed: () {
                                openEditRecordForm(context, record, recordId);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                confirmDeleteRecord(context, recordId);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

//analysis page starts
class AnalysisPage extends StatefulWidget {
  const AnalysisPage({Key? key}) : super(key: key);

  @override
  _AnalysisPageState createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  double totalIncome = 0.0;
  double totalSpent = 0.0;
  double total = 0.0;

  DateTime currentFilterDate = DateTime.now();

  Future<void> fetchTotals() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final dateKey = "${currentFilterDate.month}/${currentFilterDate.year}";
    double incomeSum = 0.0;
    double expenseSum = 0.0;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('history')
          .where('email', isEqualTo: user.email)
          .where('date', isEqualTo: dateKey)
          .get();

      for (var doc in snapshot.docs) {
        final amount = (doc['amount'] as num).toDouble();
        if (doc['type'] == 'Income') {
          incomeSum += amount;
        } else if (doc['type'] == 'Expense') {
          expenseSum += amount;
        }
      }

      final totalValue = incomeSum - expenseSum;

      setState(() {
        totalIncome = incomeSum;
        totalSpent = expenseSum;
        total = totalValue;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error fetching totals: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void changeFilterDate(int months) {
    setState(() {
      currentFilterDate =
          DateTime(currentFilterDate.year, currentFilterDate.month + months, 1);
    });
    fetchTotals();
  }

  @override
  void initState() {
    super.initState();
    fetchTotals();
  }

  String getFormattedDate() {
    final months = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December"
    ];
    return "${months[currentFilterDate.month - 1]} ${currentFilterDate.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Date Filter
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => changeFilterDate(-1),
                ),
                Text(
                  getFormattedDate(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: () => changeFilterDate(1),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Display Totals
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text(
                      'Total Income',
                      style: TextStyle(color: Colors.black),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      totalIncome.toStringAsFixed(2),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(color: Colors.black),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      total.toStringAsFixed(2),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Text(
                      'Total Spent',
                      style: TextStyle(color: Colors.black),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      totalSpent.toStringAsFixed(2),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Main content with Pie Chart and Explanation
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pie Chart
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: CustomPaint(
                      size: const Size(200, 200),
                      painter: PieChartPainter(
                        income: totalIncome,
                        spent: totalSpent,
                        remaining: total,
                      ),
                    ),
                  ),

                  // Explanation Text
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(
                          left: 20.0), // Padding for explanation part
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(
                              height:
                                  32), // Increased gap between pie chart and explanation
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Analysis of Your Financial Breakdown",
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  RichText(
                                    text: TextSpan(
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.black,
                                      ),
                                      children: [
                                        const TextSpan(
                                          text:
                                              "The pie chart provides a comprehensive view of your financial activity for the selected date:\n\n",
                                        ),
                                        WidgetSpan(
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 8.0),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 12,
                                                  height: 12,
                                                  color: Colors.green,
                                                ),
                                                const SizedBox(width: 6),
                                                const Expanded(
                                                  child: Text(
                                                    "Income: Indicates the total earnings for the month.",
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        WidgetSpan(
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 8.0),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 12,
                                                  height: 12,
                                                  color: Colors.red,
                                                ),
                                                const SizedBox(width: 6),
                                                const Expanded(
                                                  child: Text(
                                                    "Spent: Displays the total expenses incurred during the month.",
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        WidgetSpan(
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 8.0),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 12,
                                                  height: 12,
                                                  color: Colors.blue,
                                                ),
                                                const SizedBox(width: 6),
                                                const Expanded(
                                                  child: Text(
                                                    "Remaining: Represents the leftover balance after all expenses.",
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 26),

            // Legend for Pie Chart
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _buildLegendItem(Colors.green, "Income"),
                const SizedBox(width: 16),
                _buildLegendItem(Colors.red, "Spent"),
                const SizedBox(width: 16),
                _buildLegendItem(Colors.blue, "Remaining"),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }
}

class PieChartPainter extends CustomPainter {
  final double income;
  final double spent;
  final double remaining;

  PieChartPainter({
    required this.income,
    required this.spent,
    required this.remaining,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.stroke;
    final radius = min(size.width / 2, size.height / 2);
    final total = income + spent + (remaining > 0 ? remaining : 0);

    if (total == 0) return;

    final incomeSweepAngle = (income / total) * 2 * pi;
    paint.color = Colors.green;
    paint.strokeWidth = 40;
    canvas.drawArc(
      Rect.fromCircle(
          center: Offset(size.width / 2, size.height / 2), radius: radius),
      -pi / 2,
      incomeSweepAngle,
      false,
      paint,
    );

    final spentSweepAngle = (spent / total) * 2 * pi;
    paint.color = Colors.red;
    canvas.drawArc(
      Rect.fromCircle(
          center: Offset(size.width / 2, size.height / 2), radius: radius),
      -pi / 2 + incomeSweepAngle,
      spentSweepAngle,
      false,
      paint,
    );

    final remainingSweepAngle =
        ((remaining > 0 ? remaining : 0) / total) * 2 * pi;
    paint.color = Colors.blue;
    canvas.drawArc(
      Rect.fromCircle(
          center: Offset(size.width / 2, size.height / 2), radius: radius),
      -pi / 2 + incomeSweepAngle + spentSweepAngle,
      remainingSweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

//budgets
class BudgetsPage extends StatefulWidget {
  const BudgetsPage({Key? key}) : super(key: key);

  @override
  _BudgetsPageState createState() => _BudgetsPageState();
}

class _BudgetsPageState extends State<BudgetsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late CollectionReference budgetCollection;
  late CollectionReference categoryCollection;
  late String userEmail;
  double totalBudget = 0;
  double totalSpent = 0;

  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    userEmail = FirebaseAuth.instance.currentUser?.email ?? '';
    budgetCollection = _firestore.collection('budget');
    categoryCollection = _firestore.collection('categories');
    _calculateTotals();
  }

  Future<void> _calculateTotals() async {
    final startOfMonth = DateTime(selectedYear, selectedMonth, 1);
    final endOfMonth = DateTime(selectedYear, selectedMonth + 1, 0);

    final snapshot = await budgetCollection
        .where('userEmail', isEqualTo: userEmail)
        .where('date', isGreaterThanOrEqualTo: startOfMonth)
        .where('date', isLessThanOrEqualTo: endOfMonth)
        .get();

    setState(() {
      totalBudget = snapshot.docs.fold(0, (sum, doc) {
        final data = doc.data() as Map<String, dynamic>;
        return sum + (data['limit'] as double? ?? 0);
      });
      totalSpent = snapshot.docs.fold(0, (sum, doc) {
        final data = doc.data() as Map<String, dynamic>;
        return sum + (data['spent'] as double? ?? 0);
      });
    });
  }

  void _editBudget(String budgetId, Map<String, dynamic> currentData) {
    // Logic to open the set budget form pre-filled with `currentData`
    _showSetBudgetForm(); // Customize to pre-fill with current data
  }

  Future<void> _deleteBudget(String budgetId) async {
    await budgetCollection.doc(budgetId).delete();
    _calculateTotals(); // Recalculate totals after deletion
  }

  void _showSetBudgetForm() {
    String selectedCategoryId = '';
    String selectedItem = '';
    double limit = 0;
    DateTime selectedDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Load categories
                  StreamBuilder<QuerySnapshot>(
                    stream: categoryCollection
                        .where('userEmail',
                            isEqualTo:
                                userEmail) // Filter categories by user email
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }

                      if (snapshot.hasError) {
                        return const Text('Error loading categories.');
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Text('No categories available.');
                      }

                      return DropdownButtonFormField<String>(
                        value: selectedCategoryId.isNotEmpty
                            ? selectedCategoryId
                            : null,
                        items: snapshot.data!.docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return DropdownMenuItem<String>(
                            value: doc.id,
                            child: Text(data['name'] ?? 'Unnamed Category'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setModalState(() {
                            selectedCategoryId = value ?? '';
                            selectedItem = ''; // Reset item on category change
                          });
                        },
                        hint: const Text('Select Category'),
                      );
                    },
                  ),

                  const SizedBox(height: 10),
                  // Load tasks/items based on selected category
                  if (selectedCategoryId.isNotEmpty)
                    StreamBuilder<DocumentSnapshot>(
                      stream: categoryCollection
                          .doc(selectedCategoryId)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        }

                        if (!snapshot.hasData ||
                            snapshot.data!.data() == null) {
                          return const Text('No items available.');
                        }

                        final data =
                            snapshot.data!.data() as Map<String, dynamic>;
                        final tasks = data['tasks'] as List<dynamic>?;

                        if (tasks == null || tasks.isEmpty) {
                          return const Text('No items available.');
                        }

                        return DropdownButtonFormField<String>(
                          value: selectedItem.isNotEmpty ? selectedItem : null,
                          items: tasks.map((item) {
                            return DropdownMenuItem<String>(
                              value: item.toString(),
                              child: Text(item.toString()),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setModalState(() {
                              selectedItem = value ?? '';
                            });
                          },
                          hint: const Text('Select Item'),
                        );
                      },
                    ),
                  const SizedBox(height: 10),
                  // Budget limit input
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Set Limit',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setModalState(() {
                        limit = double.tryParse(value) ?? 0;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  // Date Picker
                  Row(
                    children: [
                      Text(
                        'Date: ${DateFormat.yMMMMd().format(selectedDate)}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (pickedDate != null) {
                            setModalState(() {
                              selectedDate = pickedDate;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      if (limit > 0 &&
                          selectedCategoryId.isNotEmpty &&
                          selectedItem.isNotEmpty) {
                        await budgetCollection.add({
                          'userEmail': userEmail,
                          'category': selectedCategoryId,
                          'item': selectedItem,
                          'limit': limit,
                          'spent': 0,
                          'remaining': limit,
                          'date': selectedDate,
                        });
                        Navigator.pop(context);
                        _calculateTotals();
                      }
                    },
                    child: const Text('Add Budget'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _navigateMonth(bool isNext) {
    setState(() {
      if (isNext) {
        if (selectedMonth == 12) {
          selectedMonth = 1;
          selectedYear += 1;
        } else {
          selectedMonth += 1;
        }
      } else {
        if (selectedMonth == 1) {
          selectedMonth = 12;
          selectedYear -= 1;
        } else {
          selectedMonth -= 1;
        }
      }
      _calculateTotals();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Transparent background
      body: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_left, size: 32),
                  onPressed: () => _navigateMonth(false),
                ),
                Text(
                  DateFormat.MMMM()
                      .format(DateTime(selectedYear, selectedMonth)),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_right, size: 32),
                  onPressed: () => _navigateMonth(true),
                ),
              ],
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
            child: Text(
              'Total Budget: \$${totalBudget.toStringAsFixed(2)}\nTotal Spent: \$${totalSpent.toStringAsFixed(2)}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white, // Text color set to white
                fontSize: 16, // Font size for readability
              ),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              backgroundColor: Colors.white.withOpacity(0.15), // Updated color
              elevation: 5, // Slight elevation for better visual appeal
            ),
            onPressed: _showSetBudgetForm,
            child: const Text(
              'Set Budget',
              style: TextStyle(
                color: Colors.white, // Text color set to white
                fontSize: 16, // Font size for readability
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: budgetCollection
                  .where('userEmail', isEqualTo: userEmail)
                  .where(
                    'date',
                    isGreaterThanOrEqualTo:
                        DateTime(selectedYear, selectedMonth, 1),
                  )
                  .where(
                    'date',
                    isLessThanOrEqualTo:
                        DateTime(selectedYear, selectedMonth + 1, 0),
                  )
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading budgets.'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No budgets set.'));
                }

                return ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final category = data['category'] as String? ?? 'Unknown';
                    final item = data['item'] as String? ?? 'Unknown';
                    final limit = data['limit'] as double? ?? 0;
                    final spent = data['spent'] as double? ?? 0;
                    final remaining = data['remaining'] as double? ?? limit;

                    return FractionallySizedBox(
                      widthFactor: 0.6,
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 16.0),
                        elevation: 5,
                        color: Colors.white.withOpacity(0.1), // Updated color
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Limit: \$${limit.toStringAsFixed(2)}',
                                style: const TextStyle(color: Colors.white70),
                              ),
                              Text(
                                'Spent: \$${spent.toStringAsFixed(2)}',
                                style: const TextStyle(color: Colors.white70),
                              ),
                              Text(
                                'Remaining: \$${remaining.toStringAsFixed(2)}',
                                style: const TextStyle(color: Colors.white70),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.blue),
                                    onPressed: () {
                                      // Call the edit budget functionality
                                      _editBudget(doc.id, data);
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () {
                                      // Call the delete budget functionality
                                      _deleteBudget(doc.id);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AccountsPage extends StatefulWidget {
  const AccountsPage({super.key});

  @override
  _AccountsPageState createState() => _AccountsPageState();
}

class _AccountsPageState extends State<AccountsPage>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late CollectionReference accountsCollection;
  late String userEmail;

  @override
  void initState() {
    super.initState();
    userEmail = FirebaseAuth.instance.currentUser?.email ??
        ''; // Fetch logged-in user's email
    accountsCollection = _firestore.collection('expenses');
  }

  // Function for adding or editing an account
  // Inside your _AccountsPageState class

  Future<void> _addOrEditAccount(
      {String? docId, Map<String, dynamic>? accountData}) async {
    final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
    String accountName = accountData != null ? accountData['name'] ?? '' : '';
    String accountType = accountData != null
        ? accountData['type'] ?? ''
        : 'CASH'; // Default value
    double balance = accountData != null ? accountData['balance'] ?? 0.0 : 0.0;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(docId == null ? 'Add Account' : 'Edit Account'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: accountName,
                  decoration: const InputDecoration(labelText: 'Account Name'),
                  onSaved: (value) => accountName = value ?? '',
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter an account name'
                      : null,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: accountType,
                  items: const [
                    DropdownMenuItem(
                      value: 'CASH',
                      child: Text('CASH'),
                    ),
                    DropdownMenuItem(
                      value: 'CARD',
                      child: Text('CARD'),
                    ),
                    DropdownMenuItem(
                      value: 'E-WALLET',
                      child: Text('E-WALLET'),
                    ),
                    DropdownMenuItem(
                      value: 'BANK',
                      child: Text('BANK'),
                    ),
                    DropdownMenuItem(
                      value: 'BITCOIN',
                      child: Text('BITCOIN'),
                    ),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Account Type',
                  ),
                  onChanged: (value) => accountType = value ?? 'CASH',
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please select an account type'
                      : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  initialValue: balance.toString(),
                  decoration:
                      const InputDecoration(labelText: 'Initial Balance'),
                  keyboardType: TextInputType.number,
                  onSaved: (value) => balance = double.parse(value ?? '0'),
                  validator: (value) =>
                      value == null || double.tryParse(value) == null
                          ? 'Please enter a valid number'
                          : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState?.validate() ?? false) {
                  _formKey.currentState?.save();
                  final newAccountData = {
                    'userEmail': userEmail,
                    'name': accountName,
                    'type': accountType,
                    'balance': balance,
                    'expenses': accountData?['expenses'] ??
                        0.0, // Keep original expenses if editing
                  };

                  if (docId == null) {
                    // Adding new account
                    await accountsCollection.add(newAccountData);
                  } else {
                    // Editing existing account
                    await accountsCollection.doc(docId).update(newAccountData);
                  }
                  Navigator.pop(context);
                }
              },
              child: Text(docId == null ? 'Add' : 'Update'),
            ),
          ],
        );
      },
    );
  }

  // Function to delete an account
  Future<void> _deleteAccount(String docId) async {
    await accountsCollection.doc(docId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: Colors.white.withOpacity(
                0.15), // Changed to a theme color or appropriate button color
            elevation: 5, // Added slight elevation for better visual appeal
          ),
          onPressed: () => _addOrEditAccount(),
          child: const Text(
            'Add Account',
            style: TextStyle(
              color: Colors.white, // Set text color to white for visibility
              fontSize: 16, // Font size for better readability
            ),
          ),
        ),
        const SizedBox(height: 40),
        Expanded(
          child: StreamBuilder(
            stream: accountsCollection
                .where('userEmail', isEqualTo: userEmail)
                .snapshots(),
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data?.docs.isEmpty == true) {
                return const Center(child: Text('No accounts found.'));
              }

              double totalBalance = 0;

              for (var doc in snapshot.data!.docs) {
                final account = doc.data() as Map<String, dynamic>;
                totalBalance +=
                    account['balance'] ?? 0.0; // Handle null gracefully
              }

              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: Colors.white.withOpacity(0.1),
                    ),
                    child: Text(
                      'Total Balance: \$${totalBalance.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView(
                      children: snapshot.data!.docs.map((doc) {
                        final account = doc.data() as Map<String, dynamic>;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(
                              vertical: 5, horizontal: 20),
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 5,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: ListTile(
                            title: Text(account['name'] ?? 'Unnamed Account',
                                style: const TextStyle(color: Colors.white)),
                            subtitle: Text(
                              'Balance: \$${account['balance']?.toStringAsFixed(2) ?? '0.00'}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Colors.blue),
                                  onPressed: () => _addOrEditAccount(
                                      docId: doc.id, accountData: account),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.redAccent),
                                  onPressed: () => _deleteAccount(doc.id),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  _CategoriesPageState createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late CollectionReference categoriesCollection;
  late CollectionReference accountsCollection;

  late String userEmail;
  String radioSelection =
      'Create New Category'; // Default radio button selection
  String categoryName = '';
  List<String> tasks = [];
  String selectedCategoryId = ''; // For existing category editing

  final List<Map<String, dynamic>> defaultCategories = [
    {
      'name': 'Income',
      'tasks': ['Business', 'Awards', 'Coupons', 'Lottery'],
    },
    {
      'name': 'Expenses',
      'tasks': ['Bills', 'Car', 'Clothing', 'Entertainment'],
    },
  ];

  @override
  void initState() {
    super.initState();
    userEmail = FirebaseAuth.instance.currentUser?.email ?? '';
    categoriesCollection = _firestore.collection('categories');
    accountsCollection = _firestore.collection('expenses');
    _checkAndAddDefaultCategories();
  }

  /// Adds default categories if no categories exist for the user.
  void _checkAndAddDefaultCategories() async {
    final categoriesSnapshot = await categoriesCollection
        .where('userEmail', isEqualTo: userEmail)
        .get();

    if (categoriesSnapshot.docs.isEmpty) {
      // Add default categories for the user if none exist
      for (var category in defaultCategories) {
        await categoriesCollection.add({
          'name': category['name'],
          'tasks': category['tasks'],
          'userEmail': userEmail,
        });
      }
    }
  }

  Future<double> _fetchTotalBalance() async {
    double totalBalance = 0;
    final expensesSnapshot =
        await accountsCollection.where('userEmail', isEqualTo: userEmail).get();

    for (var doc in expensesSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      totalBalance += data['balance'] ?? 0;
    }

    return totalBalance;
  }

  void _toggleForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Category',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  StreamBuilder<QuerySnapshot>(
                    stream: categoriesCollection
                        .where('userEmail', isEqualTo: userEmail)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData ||
                          snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }

                      if (snapshot.data!.docs.isEmpty) {
                        return const Text('No categories available.');
                      }

                      return DropdownButtonFormField<String>(
                        value: selectedCategoryId.isNotEmpty
                            ? selectedCategoryId
                            : null,
                        items: snapshot.data!.docs.map((doc) {
                          return DropdownMenuItem<String>(
                            value: doc.id,
                            child: Text(doc['name']),
                          );
                        }).toList(),
                        onChanged: (value) async {
                          final selectedDoc =
                              await categoriesCollection.doc(value).get();
                          final data =
                              selectedDoc.data() as Map<String, dynamic>;

                          setModalState(() {
                            selectedCategoryId = value!;
                            categoryName = data['name'];
                            tasks = List<String>.from(data['tasks'] ?? []);
                          });
                        },
                        hint: const Text('Select Category'),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  const Text('Tasks'),
                  for (int i = 0; i < tasks.length; i++)
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: tasks[i],
                            decoration: InputDecoration(
                              labelText: 'Task ${i + 1}',
                            ),
                            onChanged: (value) {
                              setModalState(() {
                                tasks[i] = value;
                              });
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setModalState(() {
                              tasks.removeAt(i);
                            });
                          },
                        ),
                      ],
                    ),
                  ElevatedButton(
                    onPressed: () {
                      setModalState(() {
                        tasks.add('');
                      });
                    },
                    child: const Text('+ Add Task'),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: selectedCategoryId.isNotEmpty
                        ? () async {
                            await categoriesCollection
                                .doc(selectedCategoryId)
                                .update({'tasks': tasks});
                            Navigator.pop(context);
                          }
                        : null,
                    child: const Text('Submit'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _deleteCategory(String categoryId) async {
    try {
      await categoriesCollection.doc(categoryId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting category: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: FutureBuilder<double>(
            future: _fetchTotalBalance(),
            builder: (context, snapshot) {
              if (!snapshot.hasData ||
                  snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              double totalBalance = snapshot.data!;

              return FutureBuilder<double>(
                future: _fetchTotalSpent(), // Fetch Total Spent
                builder: (context, spentSnapshot) {
                  if (!spentSnapshot.hasData ||
                      spentSnapshot.connectionState ==
                          ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  double totalSpent = spentSnapshot.data!;

                  return Column(
                    children: [
                      const SizedBox(height: 20), // Top gap
                      Text(
                        'All Accounts Income : \$${totalBalance.toStringAsFixed(2)}',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 20),
                      ),
                      const SizedBox(height: 10), // Spacing between values
                      Text(
                        'Total Spent : \$${totalSpent.toStringAsFixed(2)}',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 20),
                      ),
                      const SizedBox(height: 20), // Bottom gap
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: categoriesCollection
                              .where('userEmail', isEqualTo: userEmail)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData ||
                                snapshot.connectionState ==
                                    ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }

                            final categories = snapshot.data!.docs;

                            return ListView(
                              padding: const EdgeInsets.all(15),
                              children: categories.map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                return Container(
                                  padding: const EdgeInsets.all(20),
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        data['name'],
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      if (data['tasks'] != null &&
                                          (data['tasks'] as List).isNotEmpty)
                                        ...List.generate(
                                          (data['tasks'] as List).length,
                                          (index) {
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 20, top: 5),
                                              child: Text(
                                                '- ${data['tasks'][index]}',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.white70,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
        FloatingActionButton(
          onPressed: _toggleForm,
          backgroundColor: Colors.blue,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ],
    );
  }

  Future<double> _fetchTotalSpent() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 0.0;

    double totalSpent = 0.0;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('history')
          .where('email', isEqualTo: user.email)
          .get();

      for (var doc in snapshot.docs) {
        final amount = (doc['amount'] as num).toDouble();
        if (doc['type'] == 'Expense') {
          totalSpent += amount;
        }
      }
    } catch (e) {
      debugPrint("Error fetching total spent: $e");
    }

    return totalSpent;
  }
}
