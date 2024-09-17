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
  TextEditingController dateController = TextEditingController();
  TextEditingController ticketController = TextEditingController(); // Ticket controller
  TextEditingController totalAmountController = TextEditingController(); // Total amount controller

  Map<String, TextEditingController> feeControllers = {}; // To manage dynamic fee controllers
  Map<String, String> feeLabels = {}; // To store fee labels

  int ticketCount = 0; // Initialize ticket count
  bool isTicketRateAdded = false; // Check if Ticket Rate is added

  @override
  void initState() {
    super.initState();
    _loadPayorData();
    _initializeDate(); // Set the current date
    ticketController.text = ticketCount.toString(); // Initialize ticket controller text
    _loadFees(); // Load fees from Firestore
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
    double ticketRate = double.tryParse(feeControllers['Ticket Rate']?.text.replaceAll('₱ ', '').replaceAll(',', '') ?? '0') ?? 0;
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

  // Function to load fees from Firestore
// Function to load fees from Firestore
Future<void> _loadFees() async {
  QuerySnapshot rateSnapshot = await FirebaseFirestore.instance.collection('rate').get();
  List<QueryDocumentSnapshot> rateDocuments = rateSnapshot.docs;

  setState(() {
    for (var doc in rateDocuments) {
      String feeName = doc.get('name');
      String feeRate = doc.get('rate');

      // Add fee controllers dynamically based on the retrieved data
      feeControllers[feeName] = TextEditingController(text: '₱ $feeRate');
      feeLabels[feeName] = feeName;

      // Flag to show ticket controls if the fee is "Ticket Rate"
      if (feeName == 'Ticket Rate') {
        isTicketRateAdded = true;
      }
    }
  });
}


  // Function to show dialog to add new fee
  void _showAddFeeDialog(BuildContext context) {
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
              children: feeLabels.entries.map((entry) {
                return ListTile(
                  title: Text(entry.value),
                  subtitle: Text(feeControllers[entry.key]?.text ?? ''),
                  onTap: () {
                    _addSelectedFee(entry.key, entry.value);
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

  // Function to add selected fee
  void _addSelectedFee(String feeName, String feeLabel) {
    setState(() {
      // Only add the fee if it's not already present
      if (!feeControllers.containsKey(feeName)) {
        feeControllers[feeName] = feeControllers[feeLabel]!; // Use existing controller
      }

      // If the added fee is "Ticket Rate", update ticket rate controller and flag
      if (feeName == 'Ticket Rate') {
        isTicketRateAdded = true; // Flag to show ticket controls
      }
    });
  }

  // Function to remove fee
  void _removeFee(String feeName) {
    setState(() {
      if (feeControllers.containsKey(feeName)) {
        feeControllers[feeName]?.dispose(); // Dispose the controller to prevent memory leaks
        feeControllers.remove(feeName); // Remove fee controller
      }

      // If removing "Ticket Rate", reset ticket-related controls
      if (feeName == 'Ticket Rate') {
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
                color: Colors.white,
                boxShadow: const [BoxShadow(color: Colors.grey, blurRadius: 4, spreadRadius: 2)],
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
                    readOnly: true,
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
                  onPressed: () => _showAddFeeDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('New Fees'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 51, 206, 30),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Display container for Garbage Fee, Ticket Rate, and amounts
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
              boxShadow: const [BoxShadow(color: Colors.grey, blurRadius: 4, spreadRadius: 2)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Display Garbage Fee, Ticket Rate, and other fees
                // Inside the Row for displaying fees
                ...feeControllers.entries.map((entry) {
                  String feeName = entry.key;
                  TextEditingController? controller = entry.value;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        // Fee Input Field
                        Flexible(
                          flex: 3, // Adjust the flex value to balance the layout
                          child: TextField(
                            controller: controller,
                            decoration: InputDecoration(
                              labelText: feeLabels[feeName],
                              border: const OutlineInputBorder(),
                            ),
                            readOnly: true,
                          ),
                        ),

                        // If it's the Ticket Rate, show ticket controls
                        if (feeName == 'Ticket Rate' && isTicketRateAdded) ...[
                          const SizedBox(width: 10),
                          // Adjust size of the ticket controls
                          Flexible(
                            flex: 2, // Allocate a smaller flex to the ticket controls
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove),
                                  onPressed: _decrementTickets,
                                ),
                                Expanded(
                                  child: TextField(
                                    controller: ticketController,
                                    decoration: const InputDecoration(
                                      labelText: 'Tickets',
                                      border: OutlineInputBorder(),
                                    ),
                                    textAlign: TextAlign.center,
                                    readOnly: true,
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

                        const SizedBox(width: 8), // Add some space between ticket controls and the delete button

                        // Delete Button (moved after the ticket controls)
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            _removeFee(feeName); // Remove the fee when pressed
                          },
                        ),
                      ],
                    ),
                  );
                }).toList(),

                const SizedBox(height: 16),

                // Display Total Amount
                TextField(
                  controller: totalAmountController,
                  decoration: const InputDecoration(
                    labelText: 'Total Amount',
                    border: OutlineInputBorder(),
                    prefixText: '₱',
                  ),
                  readOnly: true,
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