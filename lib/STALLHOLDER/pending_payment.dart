import 'package:ambulantcollector/STALLHOLDER/mainscaffold.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PendingPaymentPage extends StatefulWidget {
  const PendingPaymentPage({super.key});

  @override
  _PendingPaymentPageState createState() => _PendingPaymentPageState();
}

class _PendingPaymentPageState extends State<PendingPaymentPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? currentUser;
  List<Map<String, dynamic>> pendingPayments = [];
  bool isLoading = true;
  String billingCycle = 'monthly'; // Default billing cycle
  double dailyRent = 0.0;
  double dailyGarbageFee = 0.0;
  double penaltyPercentage = 0.0;
  double interestRate = 0.0;
  DateTime approvedAt = DateTime.now(); // Replace with actual approved date

  @override
  void initState() {
    super.initState();
    initializePendingPaymentData();
  }

  Future<void> initializePendingPaymentData() async {
    try {
      setState(() {
        isLoading = true;
      });

      currentUser = _auth.currentUser;
      await fetchBillingCycle();
      await fetchRates();
      await fetchDailyRental();
      await fetchGarbageFee();
      await fetchPendingPayments();
    } catch (e) {
      print('Error initializing pending payment data: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> fetchBillingCycle() async {
    try {
      final vendorDoc = await FirebaseFirestore.instance
          .collection('approvedVendors')
          .doc(currentUser?.uid)
          .get();

      if (vendorDoc.exists) {
        final vendorData = vendorDoc.data() as Map<String, dynamic>;
        setState(() {
          billingCycle = vendorData['billingCycle'] ?? 'monthly';
          approvedAt = vendorData['approvedAt'].toDate();
        });
      }
    } catch (e) {
      print('Error fetching billing cycle: $e');
    }
  }

  Future<void> fetchRates() async {
    try {
      final billingConfigSnapshot =
          await FirebaseFirestore.instance.collection('billingconfig').get();

      final billingConfigData = billingConfigSnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      for (var config in billingConfigData) {
        if (config['title'] == 'RateperMeter') {
          setState(() {
            dailyRent = config['value1'] as double;
          });
        } else if (config['title'] == 'Penalty') {
          setState(() {
            penaltyPercentage = config['value1'] as double;
          });
        } else if (config['title'] == 'Interest Rate') {
          setState(() {
            interestRate = config['value1'] as double;
          });
        }
      }
    } catch (e) {
      print('Error fetching rates: $e');
    }
  }

  Future<void> fetchDailyRental() async {
    try {
      final vendorDoc = await FirebaseFirestore.instance
          .collection('approvedVendors')
          .doc(currentUser?.uid)
          .get();

      if (!vendorDoc.exists) {
        print('No vendor found with ID: ${currentUser?.uid}');
        return;
      }

      final stallInfo = vendorDoc.get('stallInfo') as Map<String, dynamic>;
      final stallSize = stallInfo['stallSize'] as num;

      final billingConfigSnapshot = await FirebaseFirestore.instance
          .collection('billingconfig')
          .where('title', isEqualTo: 'RateperMeter')
          .get();

      if (billingConfigSnapshot.docs.isEmpty) {
        print('No RateperMeter document found');
        return;
      }

      final billingConfigDoc = billingConfigSnapshot.docs.first;
      final value1 = billingConfigDoc.get('value1') as num;

      final calculatedRent = value1 * stallSize;

      if (mounted) {
        setState(() {
          dailyRent = calculatedRent.toDouble();
        });
      }
    } catch (e, stackTrace) {
      print('Error in fetchDailyRental:');
      print(e);
      print(stackTrace);
    }
  }

  Future<void> fetchGarbageFee() async {
    try {
      final garbageFeeSnapshot = await FirebaseFirestore.instance
          .collection('billingconfig')
          .where('title', isEqualTo: 'Garbage Fee')
          .get();

      if (garbageFeeSnapshot.docs.isEmpty) {
        print('No Garbage Fee document found');
        return;
      }

      final garbageFeeDoc = garbageFeeSnapshot.docs.first;
      final value1 = garbageFeeDoc.get('value1') as num;

      print('Daily garbage fee: $value1');

      if (mounted) {
        setState(() {
          dailyGarbageFee = value1.toDouble();
        });
      }
    } catch (e, stackTrace) {
      print('Error in fetchGarbageFee:');
      print(e);
      print(stackTrace);
    }
  }

  Future<void> fetchPendingPayments() async {
    try {
      final paymentsQuery = await FirebaseFirestore.instance
          .collection('stall_payment')
          .where('vendorId', isEqualTo: currentUser?.uid)
          .where('status', isEqualTo: 'Pending')
          .orderBy('paymentDate', descending: true)
          .get();

      if (mounted) {
        setState(() {
          pendingPayments = paymentsQuery.docs
              .map((doc) => doc.data() as Map<String, dynamic>)
              .toList();
        });
      }
    } catch (e) {
      print('Error fetching pending payments: $e');
    }
  }

  String formatDate(DateTime date) {
    return DateFormat('MMMM d, y').format(date);
  }

  List<Map<String, dynamic>> calculatePendingPayments() {
    List<Map<String, dynamic>> payments = [];
    DateTime currentDate = DateTime.now();
    DateTime startDate = approvedAt;
    DateTime endDate;

    switch (billingCycle.toLowerCase()) {
      case 'monthly':
        for (int month = 0; month < 12; month++) {
          DateTime monthStartDate =
              DateTime(startDate.year, startDate.month + month, 8);
          DateTime monthEndDate =
              DateTime(startDate.year, startDate.month + month + 1, 7, 23, 59);
          int numOfDays = monthEndDate.difference(monthStartDate).inDays;
          double amount = numOfDays * dailyRent;
          double totalGarbageFee = numOfDays * dailyGarbageFee;
          double surcharge = 0.0;
          double interestAmount = 0.0;
          double totalAmountDue =
              amount + totalGarbageFee + surcharge + interestAmount;

          if (monthStartDate.isBefore(currentDate)) {
            int daysLate = currentDate.difference(monthStartDate).inDays;
            surcharge = (amount + totalGarbageFee) *
                (penaltyPercentage / 100) *
                daysLate;
            if (billingCycle.toLowerCase() != 'daily') {
              interestAmount = totalAmountDue * (interestRate / 100);
            }
            totalAmountDue =
                amount + totalGarbageFee + surcharge + interestAmount;
          }

          payments.add({
            'startDate': monthStartDate,
            'endDate': monthEndDate,
            'numOfDays': numOfDays,
            'amount': amount,
            'totalGarbageFee': totalGarbageFee,
            'surcharge': surcharge,
            'interestRate': interestRate,
            'interestAmount': interestAmount,
            'totalAmountDue': totalAmountDue,
            'dailyRent': dailyRent, // Add dailyRent to the payment details
          });
        }
        break;

      case 'weekly':
        for (int week = 0; week < 52; week++) {
          DateTime weekStartDate = startDate.add(Duration(days: week * 7));
          DateTime weekEndDate = weekStartDate.add(Duration(days: 7));
          int numOfDays = 7;
          double amount = numOfDays * dailyRent;
          double totalGarbageFee = numOfDays * dailyGarbageFee;
          double surcharge = 0.0;
          double interestAmount = 0.0;
          double totalAmountDue =
              amount + totalGarbageFee + surcharge + interestAmount;

          if (weekStartDate.isBefore(currentDate)) {
            int daysLate = currentDate.difference(weekStartDate).inDays;
            surcharge = (amount + totalGarbageFee) *
                (penaltyPercentage / 100) *
                daysLate;
            if (billingCycle.toLowerCase() != 'daily') {
              interestAmount = totalAmountDue * (interestRate / 100);
            }
            totalAmountDue =
                amount + totalGarbageFee + surcharge + interestAmount;
          }

          payments.add({
            'startDate': weekStartDate,
            'endDate': weekEndDate,
            'numOfDays': numOfDays,
            'amount': amount,
            'totalGarbageFee': totalGarbageFee,
            'surcharge': surcharge,
            'interestRate': interestRate,
            'interestAmount': interestAmount,
            'totalAmountDue': totalAmountDue,
            'dailyRent': dailyRent, // Add dailyRent to the payment details
          });
        }
        break;

      case 'daily':
        for (int day = 0; day < 365; day++) {
          DateTime dayStartDate = startDate.add(Duration(days: day));
          DateTime dayEndDate =
              dayStartDate.add(Duration(days: 1, hours: 23, minutes: 59));
          int numOfDays = 1;
          double amount = numOfDays * dailyRent;
          double totalGarbageFee = numOfDays * dailyGarbageFee;
          double surcharge = 0.0;
          double interestAmount = 0.0;
          double totalAmountDue =
              amount + totalGarbageFee + surcharge + interestAmount;

          if (dayStartDate.isBefore(currentDate)) {
            int daysLate = currentDate.difference(dayStartDate).inDays;
            surcharge = (amount + totalGarbageFee) *
                (penaltyPercentage / 100) *
                daysLate;
            totalAmountDue =
                amount + totalGarbageFee + surcharge + interestAmount;
          }

          payments.add({
            'startDate': dayStartDate,
            'endDate': dayEndDate,
            'numOfDays': numOfDays,
            'amount': amount,
            'totalGarbageFee': totalGarbageFee,
            'surcharge': surcharge,
            'interestRate': interestRate,
            'interestAmount': interestAmount,
            'totalAmountDue': totalAmountDue,
            'dailyRent': dailyRent, // Add dailyRent to the payment details
          });
        }
        break;

      default:
        break;
    }

    return payments;
  }
  //nuewww

  void _showPaymentDetails(Map<String, dynamic> payment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return PaymentDetailsBottomSheet(payment: payment);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return MainScaffold(
        currentIndex: 4, // Set the index to match the "Pending Payment" tab
        child: Center(child: CircularProgressIndicator()),
      );
    }

    List<Map<String, dynamic>> calculatedPayments = calculatePendingPayments();

    // Filter out payments that are already paid
    calculatedPayments = calculatedPayments.where((payment) {
      final dueDate = payment['endDate'] as DateTime;
      final isPaid = pendingPayments.any((paidPayment) =>
          paidPayment['dueDate'].toDate().isAtSameMomentAs(dueDate) &&
          paidPayment['status'] == 'Paid');
      return !isPaid;
    }).toList();

    return MainScaffold(
      currentIndex: 4, // Set the index to match the "Pending Payment" tab
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10), // Add some spacing
            if (calculatedPayments.isNotEmpty) ...[
              Text(
                'Pending Payments',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 41, 98, 46)),
              ),
              SizedBox(height: 10), // Add some spacing
              Expanded(
                child: ListView.builder(
                  itemCount: calculatedPayments.length,
                  itemBuilder: (context, index) {
                    final payment = calculatedPayments[index];
                    return GestureDetector(
                      onTap: () => _showPaymentDetails(payment),
                      child: Card(
                        margin: EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 2,
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Amount Due: ₱${payment['totalAmountDue'].toStringAsFixed(2)}',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Due Date: ${formatDate(payment['endDate'])}',
                                style: TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ] else ...[
              Text(
                'No pending payments available.',
                style: TextStyle(fontSize: 16, color: Colors.red),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class PaymentDetailsBottomSheet extends StatelessWidget {
  final Map<String, dynamic> payment;

  PaymentDetailsBottomSheet({required this.payment});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Details',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          _buildRow('Start Date', formatDate(payment['startDate'])),
          _buildRow('End Date', formatDate(payment['endDate'])),
          _buildRow('Number of Days', payment['numOfDays'].toString()),
          _buildRow(
              'Daily Rental', '₱${payment['dailyRent'].toStringAsFixed(2)}'),
          _buildRow('Amount', '₱${payment['amount'].toStringAsFixed(2)}'),
          _buildRow('Garbage Fee',
              '₱${payment['totalGarbageFee'].toStringAsFixed(2)}'),
          _buildRow('Surcharge', '₱${payment['surcharge'].toStringAsFixed(2)}'),
          _buildRow('Interest Rate',
              '${payment['interestRate'].toStringAsFixed(2)}%'),
          _buildRow('Interest Amount',
              '₱${payment['interestAmount'].toStringAsFixed(2)}'),
          _buildRow('Total Amount Due',
              '₱${payment['totalAmountDue'].toStringAsFixed(2)}'),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text(
              'Close',
              style: TextStyle(color: const Color.fromARGB(255, 156, 46, 46)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 16),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  String formatDate(DateTime date) {
    return DateFormat('MMMM d, y').format(date);
  }
}
