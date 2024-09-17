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
  TextEditingController totalAmountController = TextEditingController();

  Map<String, TextEditingController> feeControllers = {};
  Map<String, String> feeLabels = {};
  Map<String, String> feeRates = {}; // Map to store fee rates from Firestore

  int ticketCount = 0;
  bool isTicketRateAdded = false;

  @override
  void initState() {
    super.initState();
    _loadPayorData();
    _initializeDate();
    ticketController.text = ticketCount.toString();
    _loadFees(); // Load fees from Firestore
  }

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

  void _updateTotalAmount() {
    double ticketRate = double.tryParse(feeControllers['Ticket Rate']?.text.replaceAll('₱ ', '').replaceAll(',', '') ?? '0') ?? 0;
    int tickets = int.tryParse(ticketController.text) ?? 0;

    double totalAmount = (ticketRate * tickets);

    totalAmountController.text = totalAmount.toStringAsFixed(2);
  }

  void _incrementTickets() {
    setState(() {
      ticketCount++;
      ticketController.text = ticketCount.toString();
      _updateTotalAmount();
    });
  }

  void _decrementTickets() {
    if (ticketCount > 0) {
      setState(() {
        ticketCount--;
        ticketController.text = ticketCount.toString();
        _updateTotalAmount();
      });
    }
  }

  Future<void> _loadFees() async {
    QuerySnapshot rateSnapshot = await FirebaseFirestore.instance.collection('rate').get();
    List<QueryDocumentSnapshot> rateDocuments = rateSnapshot.docs;

    // Temporary map to hold fee data
    Map<String, String> tempFees = {};

    setState(() {
      for (var doc in rateDocuments) {
        String feeName = doc.get('name');
        String feeRate = doc.get('rate');

        // Store fee data in a temporary map
        tempFees[feeName] = feeRate;

        // Store rates in a separate map
        feeRates[feeName] = feeRate;

        // Add fee controllers dynamically based on the retrieved data
        if (!feeControllers.containsKey(feeName)) {
          feeControllers[feeName] = TextEditingController(text: '₱ $feeRate');
          feeLabels[feeName] = feeName;
        }
      }
    });

    // Ensure that rates in the feeControllers are updated to reflect the Firestore data
    feeLabels.forEach((feeName, _) {
      if (feeRates.containsKey(feeName)) {
        feeControllers[feeName]?.text = '₱ ${feeRates[feeName]}';
      }
    });
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
              children: feeLabels.entries.map((entry) {
                bool isDisabled = feeControllers.containsKey(entry.key);

                return ListTile(
                  title: Text(
                    entry.value,
                    style: TextStyle(
                      color: isDisabled ? Colors.grey : Colors.black,
                    ),
                  ),
                  subtitle: Text(
                    isDisabled ? '₱ ${feeRates[entry.key]}' : '₱ ${feeRates[entry.key]}',
                    style: TextStyle(
                      color: isDisabled ? Colors.grey : Colors.black,
                    ),
                  ),
                  onTap: isDisabled ? null : () {
                    _addSelectedFee(entry.key, entry.value);
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
        feeControllers[feeName] = TextEditingController(text: '₱ ${feeRates[feeName]}'); // Use the rate from feeRates
        feeLabels[feeName] = feeLabel;
      }

      if (feeName == 'Ticket Rate') {
        isTicketRateAdded = true;
      }
    });
  }

  void _removeFee(String feeName) {
    setState(() {
      if (feeControllers.containsKey(feeName)) {
        feeControllers[feeName]?.dispose();
        feeControllers.remove(feeName);

        if (feeName == 'Ticket Rate') {
          isTicketRateAdded = false;
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
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
                boxShadow: const [BoxShadow(color: Colors.grey, blurRadius: 4, spreadRadius: 2)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: feeControllers.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.key,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Text(
                          entry.value.text,
                          style: const TextStyle(fontSize: 16, color: Colors.black),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle, color: Colors.red),
                          onPressed: () => _removeFee(entry.key),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text(
                  'Number of Tickets:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: _decrementTickets,
                ),
                Text(
                  ticketController.text,
                  style: const TextStyle(fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _incrementTickets,
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: totalAmountController,
              decoration: const InputDecoration(
                labelText: 'Total Amount',
                prefixIcon: Icon(Icons.monetization_on),
                border: OutlineInputBorder(),
              ),
              readOnly: true,
            ),
          ],
        ),
      ),
    );
  }
}
