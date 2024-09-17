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
  TextEditingController ticketController = TextEditingController();
  TextEditingController numberOfTicketsController = TextEditingController();
  TextEditingController totalAmountController = TextEditingController();
  Map<String, TextEditingController> feeControllers = {};
  Map<String, String> feeLabels = {};
  Map<String, String> feeRates = {}; // Map to store fee rates from Firestore

  double ticketRate = 5.0; // Set ticket rate to 5 (as per your example)
  int numberOfTickets = 4; // Default number of tickets

  @override
  void initState() {
    super.initState();
    _loadPayorData();
    _initializeDate();
    ticketController.text = ticketRate.toStringAsFixed(2);
    numberOfTicketsController.text = numberOfTickets.toString();
    _calculateTotalAmount(); // Calculate the total amount when initializing
    _loadFees();  }

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

  void _initializeDate() {
    setState(() {
      dateController.text = DateFormat('MM/dd/yyyy').format(DateTime.now());
    });
  }

  void _onNumberOfTicketsChanged(String value) {
    setState(() {
      numberOfTickets = int.tryParse(value) ?? 0; // If input is invalid, default to 0
      _calculateTotalAmount(); // Ensure the total amount is recalculated whenever tickets are changed
    });
  }

  void _incrementNumberOfTickets() {
    setState(() {
      numberOfTickets += 1;
      numberOfTicketsController.text = numberOfTickets.toString();
      _calculateTotalAmount();
    });
  }

  void _decrementNumberOfTickets() {
    if (numberOfTickets > 0) {
      setState(() {
        numberOfTickets -= 1;
        numberOfTicketsController.text = numberOfTickets.toString();
        _calculateTotalAmount();
      });
    }
  }

  // Function to calculate the total amount
  void _calculateTotalAmount() {
    setState(() {
      double totalAmount = ticketRate * numberOfTickets; // Ensure ticket rate * number of tickets is calculated correctly
      totalAmountController.text = '₱ ${totalAmount.toStringAsFixed(2)}'; // Display the result
    });
  }

 Future<void> _loadFees() async {
  QuerySnapshot rateSnapshot = await FirebaseFirestore.instance.collection('rate').get();
  List<QueryDocumentSnapshot> rateDocuments = rateSnapshot.docs;

  Map<String, String> tempFees = {};

  setState(() {
    for (var doc in rateDocuments) {
      String feeName = doc.get('name');
      String feeRate = doc.get('rate');

      tempFees[feeName] = feeRate;

      if (feeName == 'Ticket Rate') {
        ticketRate = double.tryParse(feeRate) ?? 5.0; // Update ticket rate
        ticketController.text = '₱ ${ticketRate.toStringAsFixed(2)}';
      }

      if (!feeControllers.containsKey(feeName) && (feeName == 'Ticket Rate' || feeName == 'Garbage Fee')) {
        feeControllers[feeName] = TextEditingController(text: '₱ $feeRate');
        feeLabels[feeName] = feeName;
      }

      feeRates[feeName] = feeRate;
    }
  });

  _calculateTotalAmount(); // Recalculate total amount after loading fees
}

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
              children: feeRates.entries.where((entry) => !feeControllers.containsKey(entry.key)).map((entry) {
                return ListTile(
                  title: Text(entry.key),
                  subtitle: Text('₱ ${entry.value}'),
                  onTap: () {
                    _addSelectedFee(entry.key, entry.key);
                    Navigator.of(context).pop();
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

  void _addSelectedFee(String feeName, String feeLabel) {
    setState(() {
      if (!feeControllers.containsKey(feeName)) {
        feeControllers[feeName] = TextEditingController(text: '₱ ${feeRates[feeName]}');
        feeLabels[feeName] = feeLabel;
      }
    });
  }

  void _removeFee(String feeName) {
    setState(() {
      if (feeControllers.containsKey(feeName)) {
        feeControllers[feeName]?.dispose();
        feeControllers.remove(feeName);

        if (feeName == 'Ticket Rate') {
          ticketRate = 5.0; // Reset to default value of 5
          ticketController.text = ticketRate.toStringAsFixed(2);
        }
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
                    TextButton.icon(
                      onPressed: () {
                        _showAddFeeDialog(context);
                      },
                      icon: const Icon(Icons.add, color: Color.fromARGB(255, 218, 224, 218)),
                      label: const Text('Add Fee'),
                      style: TextButton.styleFrom(
                        textStyle: const TextStyle(fontSize: 16, color: Colors.white),
                        backgroundColor: const Color.fromARGB(255, 50, 189, 55),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 8),
                Column(
                  children: feeControllers.entries.map((entry) {
                    String feeName = entry.key;
                    TextEditingController feeController = entry.value;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: feeController,
                              decoration: InputDecoration(
                                labelText: feeLabels[feeName],
                                border: const OutlineInputBorder(),
                              ),
                              readOnly: true,
                            ),
                          ),
                          if (feeName == 'Ticket Rate') ...[
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 3, // Adjust flex to make the field bigger
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove),
                                    onPressed: _decrementNumberOfTickets,
                                  ),
                                  Expanded(
                                    child: TextField(
                                      controller: numberOfTicketsController,
                                      keyboardType: TextInputType.number,
                                      onChanged: _onNumberOfTicketsChanged,
                                      decoration: const InputDecoration(
                                        labelText: 'Number of Tickets',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add, color: Color.fromARGB(255, 18, 167, 28)),
                                    onPressed: _incrementNumberOfTickets,
                                    
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 3, // Adjust flex to make the field bigger
                              child: TextField(
                                controller: totalAmountController,
                                decoration: const InputDecoration(
                                  labelText: 'Total Amount',
                                  border: OutlineInputBorder(),
                                ),
                                readOnly: true,
                              ),
                            ),
                          ],
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              _removeFee(feeName);
                            },
                          ),
                        ],
                      ),
                    );
                  }).toList(),
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