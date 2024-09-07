import 'package:ambulantcollector/screens/vendor_payment.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For formatting the date

class AssignPaymentAllScreen extends StatefulWidget {
  @override
  _AssignPaymentScreenState createState() => _AssignPaymentScreenState();
}

class _AssignPaymentScreenState extends State<AssignPaymentAllScreen> {
  TextEditingController payorController = TextEditingController();
  TextEditingController garbageFeeController = TextEditingController();
  TextEditingController ticketRateController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  TextEditingController ticketController = TextEditingController(); // Ticket controller
  TextEditingController totalAmountController = TextEditingController(); // Total amount controller

  int ticketCount = 0; // Initialize ticket count

  @override
  void initState() {
    super.initState();
    _loadPayorData();
    _loadGarbageFee();
    _loadTicketRate();
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

  // Function to load garbage fee
  Future<void> _loadGarbageFee() async {
    DocumentSnapshot garbageSnapshot = await FirebaseFirestore.instance
        .collection('rate')
        .doc('garbage')
        .get();

    if (garbageSnapshot.exists) {
      setState(() {
        garbageFeeController.text = garbageSnapshot.get('garbage_fee').toString();
        _updateTotalAmount(); // Update total amount when garbage fee is loaded
      });
    }
  }

  // Function to load ticket rate
  Future<void> _loadTicketRate() async {
    DocumentSnapshot ticketRateSnapshot = await FirebaseFirestore.instance
        .collection('rate')
        .doc('ticket')
        .get();

    if (ticketRateSnapshot.exists) {
      setState(() {
        ticketRateController.text = ticketRateSnapshot.get('ticket_rate').toString();
        _updateTotalAmount(); // Update total amount when ticket rate is loaded
      });
    }
  }

  // Function to pick a date
  Future<void> _selectDate(BuildContext context) async {
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (selectedDate != null) {
      setState(() {
        dateController.text = DateFormat('MM/dd/yyyy').format(selectedDate);
      });
    }
  }

  // Function to update total amount
  void _updateTotalAmount() {
    double garbageFee = double.tryParse(garbageFeeController.text) ?? 0;
    double ticketRate = double.tryParse(ticketRateController.text) ?? 0;
    int tickets = int.tryParse(ticketController.text) ?? 0;

    double totalAmount = garbageFee + (ticketRate * tickets);

    totalAmountController.text = totalAmount.toStringAsFixed(2); // Format to 2 decimal places
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Assign Payment"),
        backgroundColor: Color.fromARGB(255, 51, 206, 30),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 24),

      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            const Text(
              'Payor Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 52, 180, 35),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: payorController,
                  decoration: const InputDecoration(
                    labelText: 'Payor',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  readOnly: true, // Payor is not editable
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Section Header
            const Text(
              'Fee Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 52, 180, 35),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Garbage Fee
                    TextField(
                      controller: garbageFeeController,
                      decoration: const InputDecoration(
                        labelText: 'Garbage Fee',
                        prefixIcon: Icon(Icons.delete),
                        border: OutlineInputBorder(),
                      ),
                      readOnly: true, // Garbage Fee is not editable
                    ),
                    const SizedBox(height: 16),

                    // Ticket Rate
                    TextField(
                      controller: ticketRateController,
                      decoration: const InputDecoration(
                        labelText: 'Ticket Rate',
                        prefixIcon: Icon(Icons.receipt),
                        border: OutlineInputBorder(),
                      ),
                      readOnly: true, // Ticket Rate is not editable
                    ),
                    const SizedBox(height: 16),

                    // Total Amount
                    TextField(
                      controller: totalAmountController,
                      decoration: const InputDecoration(
                        labelText: 'Total Amount',
/*                         prefixIcon: Icon(Icons.attach_money_sharp),
 */                        border: OutlineInputBorder(),
                      ),
                      readOnly: true, // Total Amount is not editable
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Section Header
            const Text(
              'Ticket Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 52, 180, 35),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Number of Tickets (with + and - buttons)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Number of Tickets:',
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 10),
                        // Decrement Button
                        IconButton(
                          icon: const Icon(Icons.remove, color: Color.fromARGB(255, 13, 13, 13)),
                          onPressed: () {
                            setState(() {
                              if (ticketCount > 0) ticketCount--;
                              ticketController.text =
                                  ticketCount.toString(); // Update the text field
                              _updateTotalAmount(); // Update total amount
                            });
                          },
                        ),
                        SizedBox(
                          width: 80,
                          child: TextField(
                            controller: ticketController,
                            keyboardType: TextInputType.number, // Only allows number input
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              setState(() {
                                if (value.isNotEmpty) {
                                  ticketCount = int.tryParse(value) ?? 0; // Update the ticket count
                                  _updateTotalAmount(); // Update total amount
                                }
                              });
                            },
                          ),
                        ),
                        // Increment Button
                        IconButton(
                          icon: const Icon(Icons.add, color: Color.fromARGB(255, 76, 214, 51)),
                          onPressed: () {
                            setState(() {
                              ticketCount++;
                              ticketController.text =
                                  ticketCount.toString(); // Update the text field
                              _updateTotalAmount(); // Update total amount
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Select Date
                    TextField(
                      controller: dateController,
                      decoration: const InputDecoration(
                        labelText: 'Payment Date',
                        prefixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(),
                      ),
                      onTap: () => _selectDate(context),
                      readOnly: true, // Date should be selected via calendar
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Payment button
            Center(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    backgroundColor: const Color.fromARGB(255, 53, 208, 51),
                  ),
                  onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SelectVendorsScreen()),
                      );
                    // Your payment submission logic
                  },
                  child: const Text(
                    'Submit Payment',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
