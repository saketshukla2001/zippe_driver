import 'package:flutter/material.dart';
import 'package:flutter_driver/pages/onTripPage/map_page.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'subscription_service.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool loading = true;
  List plans = [];
  late Razorpay _razorpay;

  int? _subscriptionId;

  @override
  void initState() {
    super.initState();
    loadPlans();

    _razorpay = Razorpay();
    _razorpay.on(
        Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(
        Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(
        Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }


  Future<void> loadPlans() async {
    try {
      plans = await SubscriptionService.getPlans();
    } catch (e) {
      showSnack('Failed to load plans');
    }
    setState(() => loading = false);
  }


  Future<void> buyPlan(dynamic plan) async {
    print('👉 Buy clicked for plan: ${plan['name']}');

    final result =
    await SubscriptionService.createSubscription(plan['id']);

    print('📦 Create subscription response: $result');

    if (result['status'] != true) {
      showSnack(result['message'] ?? 'Something went wrong');
      return;
    }

    if (plan['price'].toString() == '0' ||
        plan['price'].toString() == '0.00') {
      showSnack('Subscription Activated');
      Navigator.pop(context);
      return;
    }

    _subscriptionId = result['subscription_id'];

    double price =
        double.tryParse(plan['price'].toString()) ?? 0.0;
    int amountInPaise = (price * 100).round();

    print('💰 Opening Razorpay for ₹$price');

    var options = {
      'key': 'rzp_test_L96fF7vkpakUq7',
      'amount': amountInPaise,
      'name': 'Your App Name',
      'description': plan['name'],
      'theme': {'color': '#2563eb'},
    };

    _razorpay.open(options);
  }


  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    print('✅ Payment Success');
    print('PaymentId: ${response.paymentId}');
    print('OrderId: ${response.orderId}');
    print('Signature: ${response.signature}');

    if (_subscriptionId == null) {
      print('❌ subscriptionId null');
      return;
    }

    final String paymentId = response.paymentId ?? '';

    final String transactionId =
        response.orderId ??
            response.signature ??
            paymentId;

    print('📡 CONFIRM PAYMENT');
    print('Subscription ID: $_subscriptionId');
    print('Payment ID: $paymentId');
    print('Transaction ID: $transactionId');

    final res = await SubscriptionService.confirmPayment(
      _subscriptionId!,
      paymentId: paymentId,
      transactionId: transactionId,
    );

    print('📦 Payment confirm response: $res');

    showSnack('Payment Success & Subscription Activated');
    Navigator.push(context, MaterialPageRoute(builder: (context)=> Maps()));
  }


  void _handlePaymentError(PaymentFailureResponse response) {
    print('❌ Payment Failed: ${response.message}');
    showSnack('Payment Failed');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    showSnack('External Wallet: ${response.walletName}');
  }

  void showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: AppBar(
        title: const Text(
          'Choose Your Plan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: plans.length,
        itemBuilder: (context, index) {
          final plan = plans[index];
          final bool isFree =
              plan['price'].toString() == '0';

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                colors: isFree
                    ? [
                  Colors.grey.shade300,
                  Colors.grey.shade100
                ]
                    : const [
                  Color(0xff2563eb),
                  Color(0xff1e40af)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                )
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    plan['name'],
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color:
                      isFree ? Colors.black : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isFree
                        ? 'Free Plan'
                        : '₹ ${plan['price']} / ${plan['duration']} days',
                    style: TextStyle(
                      fontSize: 15,
                      color: isFree
                          ? Colors.black54
                          : Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                        isFree ? Colors.black : Colors.white,
                        foregroundColor:
                        isFree ? Colors.white : Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => buyPlan(plan),
                      child: Text(
                        isFree
                            ? 'Activate Free'
                            : 'Subscribe Now',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
