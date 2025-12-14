import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../functions/functions.dart';

class SubscriptionService {
  static final String baseUrl = '${url}api/v1/user';

  static Map<String, String> headers() {
    print('🔐 TOKEN USED: ${bearerToken[0].token}');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${bearerToken[0].token}',
    };
  }

  static Future<List<dynamic>> getPlans() async {
    print('📡 GET PLANS API CALL');

    final response = await http.get(
      Uri.parse('$baseUrl/subscriptions/plans'),
      headers: headers(),
    );

    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');

    final data = jsonDecode(response.body);
    return data['data'] ?? [];
  }

  static Future<Map<String, dynamic>> createSubscription(int planId) async {
    print('📡 CREATE SUBSCRIPTION');
    print('Plan ID: $planId');

    final response = await http.post(
      Uri.parse('$baseUrl/subscriptions/subscribe'),
      headers: headers(),
      body: jsonEncode({
        'subscription_plan_id': planId,
      }),
    );

    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> confirmPayment(
      int subscriptionId, {
        required String paymentId,
        required String transactionId,
      }) async {
    print('📡 CONFIRM PAYMENT');
    print('Subscription ID: $subscriptionId');
    print('Payment ID: $paymentId');
    print('Transaction ID: $transactionId');

    final response = await http.put(
      Uri.parse('$baseUrl/subscriptions/subscribe'),
      headers: headers(),
      body: jsonEncode({
        'subscription_id': subscriptionId,
        'payment_id': paymentId,
        'transaction_id': transactionId,
      }),
    );

    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');

    return jsonDecode(response.body);
  }

  static Future<bool> checkActive() async {
    print('📡 CHECK ACTIVE SUBSCRIPTION');

    final response = await http.get(
      Uri.parse('$baseUrl/subscriptions/check-active'),
      headers: headers(),
    );

    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');

    final data = jsonDecode(response.body);
    print('Subscription Active: ${data['status']}');

    return data['status'] == true;
  }
}
