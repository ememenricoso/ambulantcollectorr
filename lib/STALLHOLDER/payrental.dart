import 'package:ambulantcollector/STALLHOLDER/history_payment.dart';
import 'package:ambulantcollector/STALLHOLDER/mainscaffold.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

class PaymentScreen extends StatefulWidget {
  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final currencyFormat = NumberFormat.currency(symbol: '₱', decimalDigits: 2);
  final FirebaseAuth _auth = FirebaseAuth.instance;

  int numOfDays = 1;
  DateTime deadlineDate = DateTime.now();
  double dailyRent = 0.0;
  double dailyGarbageFee = 0.0;
  bool isLoading = true;
  bool isFirstPayment = true;
  bool isPaid = false;
  double amountDue = 0.0; // Declare amountDue as a class-level variable
  List<Map<String, dynamic>> paidPayments = [];
  User? currentUser;
  String billingCycle = 'monthly'; // Default billing cycle
  Map<String, dynamic>? recentPayment;
  double penaltyPercentage = 0.0;
  double interestRate = 0.0;
  DateTime approvedAt = DateTime.now(); // Replace with actual approved date
  List<Map<String, dynamic>> pendingPayments = [];

  @override
  void initState() {
    super.initState();
    initializePaymentData();
  }

  Future<void> initializePaymentData() async {
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
      calculateDeadlineAndDays();
    } catch (e) {
      print('Error initializing payment data: $e');
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

  void calculateDeadlineAndDays() {
    DateTime now = DateTime.now();
    DateTime startDate;
    DateTime newDeadline;

    switch (billingCycle.toLowerCase()) {
      case 'monthly':
        newDeadline = now.day < 7
            ? DateTime(now.year, now.month, 7, 23, 59)
            : DateTime(now.year, now.month + 1, 7, 23, 59);
        startDate =
            isFirstPayment ? approvedAt : DateTime(now.year, now.month, 1);
        numOfDays = DateTime(now.year, now.month + 1, 0).day;
        break;

      case 'weekly':
        int daysUntilMonday = (DateTime.monday - now.weekday + 7) % 7;
        newDeadline =
            DateTime(now.year, now.month, now.day + daysUntilMonday, 23, 59);
        startDate = isFirstPayment
            ? approvedAt
            : now.subtract(Duration(days: now.weekday - 1));
        numOfDays = 7;
        break;

      case 'daily':
        newDeadline = DateTime(now.year, now.month, now.day, 23, 59);
        startDate = now;
        numOfDays = 1;
        break;

      default:
        newDeadline = now;
        startDate = approvedAt;
        numOfDays = 1;
    }

    if (mounted) {
      setState(() {
        deadlineDate = newDeadline;
      });
    }
  }

  Future<void> checkPaymentHistory() async {
    try {
      final paymentsQuery = await FirebaseFirestore.instance
          .collection('stall_payment')
          .where('vendorId', isEqualTo: currentUser?.uid)
          .orderBy('paymentDate', descending: true)
          .get();

      if (mounted) {
        setState(() {
          isFirstPayment = paymentsQuery.docs.isEmpty;
          isPaid = paymentsQuery.docs.any((doc) => doc['status'] == 'Paid');
          paidPayments = paymentsQuery.docs
              .where((doc) => doc['status'] == 'Paid')
              .map((doc) => doc.data() as Map<String, dynamic>)
              .toList();
          recentPayment = paidPayments.isNotEmpty ? paidPayments.first : null;
        });
      }
    } catch (e) {
      print('Error checking payment history: $e');
      if (mounted) {
        setState(() {
          isFirstPayment = true;
          isPaid = false;
        });
      }
    }
  }

  String formatDeadlineDate() {
    return DateFormat('MMMM d, y').format(deadlineDate);
  }

  bool isPaymentOverdue() {
    return DateTime.now().isAfter(deadlineDate);
  }

  Widget _buildRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
                fontSize: 16,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
          ),
          Text(
            value,
            style: TextStyle(
                fontSize: 16,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
          ),
        ],
      ),
    );
  }

  Future<void> paymentCheckout(double amountDue) async {
    final url = Uri.parse('https://api.paymongo.com/v1/checkout_sessions');
    const credentials =
        'Basic c2tfdGVzdF9VV1AzaFhWUm9CQWs0R3VIOFE4NUR2cms6YzJ0ZmRHVnpkRjlWVjFBemFGaFdVbTlDUVdzMFIzVklPRkU0TlVSMmNtczY='; // Replace with actual credentials
    final body = {
      'data': {
        'type': 'checkout_session',
        'attributes': {
          'success_url':
              'https://redirecting-flutter-checkout-paymongo.netlify.app/',
          'cancel_url':
              'https://redirecting-flutter-checkout-paymongo.netlify.app/',
          'payment_method_allowed': ['card', 'gcash', 'grab_pay', 'paymaya'],
          'payment_method_options': {
            'card': {'request_three_d_secure': 'any'}
          },
          'payment_method_types': [
            // 'card',
            'gcash',
            // 'grab_pay',
            // 'paymaya',
          ],
          'description': 'Rental Payment',
          'line_items': [
            {
              'name': 'Test Item',
              'quantity': 1,
              'amount': (amountDue * 100).toInt(),
              'currency': 'PHP',
            },
          ],
          'billing': {
            'name': 'Payor Name',
          },
          'statement_descriptor': 'string',
        }
      }
    };

    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': credentials,
    };

    final response =
        await http.post(url, headers: headers, body: jsonEncode(body));

    if (response.statusCode == 200) {
      print(response.body);
      var responseBody = jsonDecode(response.body);
      print(responseBody);
      print('Checkout Session ID: ${responseBody['data']['id']}');
      var checkoutURL =
          Uri.parse(responseBody['data']['attributes']['checkout_url']);
      // Using the checkout_session.payment.paid webhooks = ['data']['attributes']['data']['attributes']['payments']['attributes']['status']
      print(checkoutURL);
      if (await canLaunchUrl(checkoutURL)) {
        await launchUrl(
          checkoutURL,
          mode: LaunchMode.externalApplication,
          // mode: LaunchMode.inAppWebView,
        );
        await storePaymentDetails(amountDue);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentScreen(),
          ),
        );
      } else {
        throw 'Could not launch $checkoutURL';
      }
    } else {
      print('Error: ${response.body}');
    }
  }

  Future<void> storePaymentDetails(double amountDue) async {
    try {
      final vendorDoc = await FirebaseFirestore.instance
          .collection('approvedVendors')
          .doc(currentUser?.uid)
          .get();

      if (!vendorDoc.exists) {
        print('No vendor found with ID: ${currentUser?.uid}');
        return;
      }

      final vendorData = vendorDoc.data() as Map<String, dynamic>;
      final firstName = vendorData['firstName'];
      final middleName = vendorData['middleName'];
      final lastName = vendorData['lastName'];

      final paymentDocRef =
          FirebaseFirestore.instance.collection('stall_payment').doc();

      await paymentDocRef.set({
        'vendorId': currentUser?.uid,
        'firstName': firstName,
        'middleName': middleName,
        'lastName': lastName,
        'status': 'Paid',
        'amountDue': amountDue,
        'paymentDate': DateTime.now(),
        'numOfDays': numOfDays,
        'dailyRent': dailyRent,
        'garbageFee': numOfDays * dailyGarbageFee,
        'surcharge': isPaymentOverdue() ? 50.00 : 0.00,
        'interestRate': isPaymentOverdue() ? 0.05 : 0.00,
        'interestAmount': amountDue * (isPaymentOverdue() ? 0.05 : 0.00),
        'totalAmountDue': amountDue,
        'dueDate': deadlineDate, // Store the due date in Firestore
        'billingCycle': billingCycle, // Store the billing cycle in Firestore
      });
    } catch (e) {
      print('Error storing payment details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return MainScaffold(
        currentIndex: 1,
        child: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
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

    if (calculatedPayments.isEmpty) {
      return MainScaffold(
        currentIndex: 1,
        child: Scaffold(
          body: Center(
            child: Text(
              'No pending payments available.',
              style: TextStyle(fontSize: 16, color: Colors.red),
            ),
          ),
        ),
      );
    }

    // Display the first pending payment details
    final payment = calculatedPayments.first;
    double totalAmount = payment['amount'];
    double garbageFee = payment['totalGarbageFee'];
    double surcharge = payment['surcharge'];
    double interestRate = payment['interestRate'];
    double interestAmount = payment['interestAmount'];
    amountDue = payment['totalAmountDue'];

    return MainScaffold(
      currentIndex: 1,
      child: Scaffold(
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Billing Cycle: $billingCycle'
                          .toUpperCase(), // Replace with actual billing cycle if needed
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 16),
                    Text('Rent Breakdown:', style: TextStyle(fontSize: 16)),
                    SizedBox(height: 16),
                    _buildRow('No. of Days', numOfDays.toString()),
                    _buildRow(
                        'Daily Stall Rental', currencyFormat.format(dailyRent)),
                    _buildRow('Amount', currencyFormat.format(totalAmount)),
                    _buildRow('Garbage Fee', currencyFormat.format(garbageFee)),
                    // Always show these rows, with zero values when not overdue
                    _buildRow('Surcharge', currencyFormat.format(surcharge),
                        isBold: surcharge > 0),
                    _buildRow(
                      'Interest Rate',
                      '${(interestRate * 100).toStringAsFixed(0)}%',
                      isBold: interestRate > 0,
                    ),
                    _buildRow(
                      'Interest Amount',
                      currencyFormat.format(interestAmount),
                      isBold: interestAmount > 0,
                    ),
                    Divider(height: 20, thickness: 1),
                    _buildRow(
                        'Total Amount Due', currencyFormat.format(amountDue),
                        isBold: true),
                    SizedBox(height: 32),
                    Text(
                      'Payment Details',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'Due Date: ${formatDeadlineDate()}',
                          style: TextStyle(
                            fontSize: 16,
                            color: isPaymentOverdue()
                                ? Colors.red
                                : Colors.black87,
                          ),
                        ),
                        SizedBox(width: 8),
                        if (isPaymentOverdue())
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'OVERDUE',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (isFirstPayment)
                      Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'First Payment',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          paymentCheckout(amountDue);
                        },
                        child: Text(
                          'Pay Now',
                          style: TextStyle(color: Colors.white, fontSize: 16),
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
    );
  }
}
