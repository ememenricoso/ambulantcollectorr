import 'dart:convert';

import 'package:http/http.dart' as http;

class PayMongoService {
  final String apiKey = 'sk_test_UWP3hXVRoBAk4GuH8Q85Dvrk'; // Replace with your PayMongo API key

  Future<Map<String, dynamic>> createPaymentIntent(double amount) async {
/*     final url = 'http://localhost:3000/create-payment-intent'; // Change to your Node.js server URL */
    final url = 'http://192.168.55.111:3000/create-payment-intent';


    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'amount': (amount * 100).toInt(), // Convert to cents
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body); // Parse the response
    } else {
      print('Failed to create payment intent: ${response.body}'); // Log error details
      throw Exception('Failed to create payment intent: ${response.body}');
    }
  }
}
