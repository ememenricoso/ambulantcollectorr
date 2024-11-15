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

  bool isLoading = true;
  User? currentUser;
  Map<String, dynamic>? recentPendingPayment;
  List<Map<String, dynamic>> overduePayments = [];
  double totalOverdueAmount = 0.0;

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
      await fetchRecentPendingPayment();
      await fetchOverduePayments();
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

  Future<void> fetchRecentPendingPayment() async {
    try {
      final paymentsQuery = await FirebaseFirestore.instance
          .collection('stall_payment')
          .where('vendorId', isEqualTo: currentUser?.uid)
          .where('status', isEqualTo: 'Pending')
          .limit(1)
          .get();

      if (paymentsQuery.docs.isNotEmpty) {
        setState(() {
          recentPendingPayment =
              paymentsQuery.docs.first.data() as Map<String, dynamic>;
        });
      } else {
        print('No pending payments found.');
      }
    } catch (e) {
      print('Error fetching recent pending payment: $e');
    }
  }

  Future<void> fetchOverduePayments() async {
    try {
      final paymentsQuery = await FirebaseFirestore.instance
          .collection('stall_payment')
          .where('vendorId', isEqualTo: currentUser?.uid)
          .where('status', isEqualTo: 'Overdue')
          .get();

      if (paymentsQuery.docs.isNotEmpty) {
        setState(() {
          overduePayments = paymentsQuery.docs
              .map((doc) => doc.data() as Map<String, dynamic>)
              .toList();
          totalOverdueAmount = overduePayments
              .map((payment) => payment['totalAmountDue'] as double)
              .reduce((a, b) => a + b);
        });
      } else {
        print('No overdue payments found.');
      }
    } catch (e) {
      print('Error fetching overdue payments: $e');
    }
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
        'numOfDays': recentPendingPayment?['numOfDays'] ?? 0,
        'dailyRent': recentPendingPayment?['dailyRent'] ?? 0.0,
        'garbageFee': recentPendingPayment?['totalGarbageFee'] ?? 0.0,
        'surcharge': recentPendingPayment?['surcharge'] ?? 0.0,
        'interestRate': recentPendingPayment?['interestRate'] ?? 0.0,
        'interestAmount': recentPendingPayment?['interestAmount'] ?? 0.0,
        'totalAmountDue': amountDue,
        'dueDate': recentPendingPayment?['endDate'] ??
            DateTime.now(), // Store the due date in Firestore
        'billingCycle': recentPendingPayment?['billingCycle'] ??
            'monthly', // Store the billing cycle in Firestore
      });
    } catch (e) {
      print('Error storing payment details: $e');
    }
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

    if (recentPendingPayment == null && overduePayments.isEmpty) {
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

    return MainScaffold(
      currentIndex: 1,
      child: Scaffold(
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Overdue Payments section comes first
              if (overduePayments.isNotEmpty)
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
                        'Overdue Payments',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 16),
                      _buildRow('Total Overdue Amount',
                          currencyFormat.format(totalOverdueAmount),
                          isBold: true),
                      SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () {
                            paymentCheckout(totalOverdueAmount);
                          },
                          child: Text(
                            'Pay Now',
                            style: TextStyle(
                                color: const Color.fromARGB(255, 255, 255, 255),
                                fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20), //space
              // Most Recent Pending Payment section comes second
              if (recentPendingPayment != null)
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
                        'Most Recent Pending Payment',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 16),
                      _buildRow(
                          'Amount',
                          currencyFormat
                              .format(recentPendingPayment!['amount'])),
                      _buildRow(
                          'Daily Rent',
                          currencyFormat
                              .format(recentPendingPayment!['dailyRent'])),
                      _buildRow(
                          'Garbage Fee',
                          currencyFormat.format(
                              recentPendingPayment!['totalGarbageFee'])),
                      _buildRow(
                          'Surcharge',
                          currencyFormat
                              .format(recentPendingPayment!['surcharge'])),
                      _buildRow(
                          'Interest Amount',
                          currencyFormat
                              .format(recentPendingPayment!['interestAmount'])),
                      Divider(height: 20, thickness: 1),
                      _buildRow(
                          'Total Amount Due',
                          currencyFormat
                              .format(recentPendingPayment!['totalAmountDue']),
                          isBold: true),
                      _buildRow(
                          'Due Date',
                          DateFormat('MMMM d, yyyy hh:mm a').format(
                              recentPendingPayment!['endDate'].toDate())),
                      SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () {
                            paymentCheckout(
                                recentPendingPayment!['totalAmountDue']);
                          },
                          child: Text(
                            'Pay Now',
                            style: TextStyle(
                                color: const Color.fromARGB(255, 255, 255, 255),
                                fontSize: 16),
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
