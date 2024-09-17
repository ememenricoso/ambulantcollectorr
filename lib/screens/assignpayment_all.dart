import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For formatting the date

class AssignPaymentAllScreen extends StatefulWidget {
  const AssignPaymentAllScreen({Key? key}) : super(key: key);

  @override
  _AssignPaymentScreenState createState() => _AssignPaymentScreenState();
}

class _AssignPaymentScreenState extends State<AssignPaymentAllScreen> {
  TextEditingController payorController = TextEditingController();
  TextEditingController ticketRateController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  TextEditingController ticketController = TextEditingController(); // Ticket controller
  TextEditingController totalAmountController = TextEditingController(); // Total amount controller

  int ticketCount = 0; // Initialize ticket count
  Map<String, TextEditingController> feeControllers = {}; // To manage dynamic fee controllers

  bool isTicketRateAdded = false; // Check if Ticket Rate is added

  @override
  void initState() {
    super.initState();
    _loadPayorData();
    _initializeDate(); // Set the current date
    ticketController.text = ticketCount.toString(); // Initialize ticket controller text
  }

  // Function to load payor's data
  Future<void> _loadPayorData() async {
    DocumentSnapshot payorSnapshot = await FirebaseFirestore.instance
        .collection('user_ambulant')
        .doc('payor')
        .get();

    if (payorSnapshot.exists) {
      setState(() {
        var firstName = payorSnapshot.get('firstname');
        var lastName = payorSnapshot.get('lastname');
        payorController.text = '$firstName $lastName';
      });
    }
  }

  // Function to initialize the current date
  void _initializeDate() {
    setState(() {
      dateController.text = DateFormat('MM/dd/yyyy').format(DateTime.now());
    });
  }

  // Function to update total amount
  void _updateTotalAmount() {
    double ticketRate = double.tryParse(ticketRateController.text) ?? 0;
    int tickets = int.tryParse(ticketController.text) ?? 0;

    double totalAmount = (ticketRate * tickets); // Calculate total amount

    totalAmountController.text = totalAmount.toStringAsFixed(2); // Format to 2 decimal places
  }

  // Increment ticket count
  void _incrementTickets() {
    setState(() {
      ticketCount++;
      ticketController.text = ticketCount.toString();
      _updateTotalAmount();
    });
  }

  // Decrement ticket count
  void _decrementTickets() {
    if (ticketCount > 0) {
      setState(() {
        ticketCount--;
        ticketController.text = ticketCount.toString();
        _updateTotalAmount();
      });
    }
  }

  void _showAddFeeDialog(BuildContext context) async {
    final QuerySnapshot rateSnapshot = await FirebaseFirestore.instance.collection('rate').get();
    List<QueryDocumentSnapshot> rateDocuments = rateSnapshot.docs;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select a Fee'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: rateDocuments.map((doc) {
                String feeName = doc['name'];
                String feeRate = doc['rate'];

                return ListTile(
                  title: Text(feeName),
                  subtitle: Text('₱ $feeRate'),
                  onTap: () {
                    _addSelectedFee(feeName, feeRate);
                    Navigator.of(context).pop(); // Close the dialog after selection
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _addSelectedFee(String feeName, String feeRate) {
    setState(() {
      // Only add the fee if it's not already present
      if (!feeControllers.containsKey(feeName) && feeName != "Ticket Rate") {
        feeControllers[feeName] = TextEditingController(text: feeRate);
      }

      // If the added fee is "Ticket Rate", update ticket rate controller and flag
      if (feeName == "Ticket Rate") {
        ticketRateController.text = feeRate;
        isTicketRateAdded = true; // Flag to show ticket controls
      }
    });
  }

  void _removeFee(String feeName) {
    setState(() {
      if (feeControllers.containsKey(feeName)) {
        feeControllers[feeName]?.dispose(); // Dispose the controller to prevent memory leaks
        feeControllers.remove(feeName); // Remove fee controller
      }

      // If removing "Ticket Rate", reset ticket-related controls
      if (feeName == "Ticket Rate") {
        ticketRateController.clear();
        isTicketRateAdded = false; // Hide ticket controls
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Assign Payment"),
        backgroundColor: const Color.fromARGB(255, 51, 206, 30),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 24),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Container for Payor and Payment Date
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.white, // Background color similar to fees container
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Payor Information
                  const Text(
                    'Payor Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 52, 180, 35),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: payorController,
                    decoration: const InputDecoration(
                      labelText: 'Payor',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    readOnly: true, // Payor is not editable
                  ),
                  const SizedBox(height: 16),

                  // Payment Date
                  TextField(
                    controller: dateController,
                    decoration: const InputDecoration(
                      labelText: 'Payment Date',
                      prefixIcon: Icon(Icons.calendar_today),
                      border: OutlineInputBorder(),
                    ),
                    readOnly: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Fee Information Header and New Fees Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Fee Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 52, 180, 35),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddFeeDialog(context), // Pass context via lambda
                  icon: const Icon(Icons.add), // Plus icon
                  label: const Text('New Fees'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 51, 206, 30), // Button color
                    foregroundColor: Colors.white, // Text color
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Display container for dynamic Fee TextFields only if there are selected fees
            if (feeControllers.isNotEmpty || isTicketRateAdded)
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white, // Background color same as the payor container
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Add dynamic fee fields
                    ...feeControllers.entries.map((entry) {
                      String feeName = entry.key;
                      TextEditingController controller = entry.value;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: controller,
                                decoration: InputDecoration(
                                  labelText: feeName, // Use fee name as the label
                                  prefixText: '₱ ',
                                  border: const OutlineInputBorder(),
                                ),
                                readOnly: true, // Fee amount is not editable
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeFee(feeName), // Delete the fee
                            ),
                          ],
                        ),
                      );
                    }).toList(),

                    // Display Ticket Rate and Number of Tickets if added
                    if (isTicketRateAdded)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: TextField(
                                    controller: ticketRateController,
                                    decoration: const InputDecoration(
                                      labelText: 'Ticket Rate',
                                      prefixText: '₱ ',
                                      border: OutlineInputBorder(),
                                    ),
                                    readOnly: true, // Ticket rate is not editable
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove),
                                      onPressed: _decrementTickets,
                                    ),
                                    Expanded(
                                      child: TextField(
                                        controller: ticketController,
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          labelText: 'No. of Tickets',
                                          border: OutlineInputBorder(),
                                        ),
                                        readOnly: true, // Ticket count is controlled by buttons
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add),
                                      onPressed: _incrementTickets,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: totalAmountController,
                                  decoration: const InputDecoration(
                                    labelText: 'Total Amount',
                                    prefixText: '₱ ',
                                    border: OutlineInputBorder(),
                                  ),
                                  readOnly: true, // Total amount is calculated, not editable
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _removeFee('Ticket Rate'), // Delete Ticket Rate
                              ),
                            ],
                          ),
                        ],
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
