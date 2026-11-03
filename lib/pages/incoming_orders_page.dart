import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/custom_refresh_indicator.dart';

class IncomingOrdersPage extends StatefulWidget {
  const IncomingOrdersPage({super.key});

  @override
  State<IncomingOrdersPage> createState() => _IncomingOrdersPageState();
}

class _IncomingOrdersPageState extends State<IncomingOrdersPage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final Color freshGreen = const Color(0xFF4CAF50);

  // Sipariş durumunu güncelleyen fonksiyon
  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({'status': newStatus});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Order status updated to $newStatus! 📦"),
            backgroundColor: freshGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update status: $e"), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Scaffold(
        appBar: CommonAppBar(title: "Incoming Orders", showBackButton: true),
        body: Center(child: Text("Please log in to see incoming orders.")),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F7),
      appBar: const CommonAppBar(title: "Incoming Orders", showBackButton: true),
      body: CustomRefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: StreamBuilder<QuerySnapshot>(
          //  producerId'ye göre fitreleme yapıyoruz
          stream: FirebaseFirestore.instance
              .collection('orders')
              .where('producerId', isEqualTo: currentUser!.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text("Something went wrong: ${snapshot.error}"));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: freshGreen));
            }

            final producerOrders = snapshot.data?.docs ?? [];

            if (producerOrders.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                  const Center(
                    child: Column(
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          "No incoming orders yet.",
                          style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    itemCount: producerOrders.length,
                    itemBuilder: (context, index) {
                      final order = producerOrders[index];
                      final orderData = order.data() as Map<String, dynamic>;

                      String orderId = order.id;
                      String status = orderData['status'] ?? 'Pending';

                      String productName = orderData['productName'] ?? 'Unknown Product';
                      int quantity = (orderData['quantity'] ?? 1).toInt();
                      String unit = orderData['unit'] ?? 'kg';
                      double price = (orderData['price'] ?? 0.0).toDouble();
                      double totalPrice = (orderData['totalPrice'] ?? (price * quantity)).toDouble();

                      Color statusColor = Colors.orange;
                      if (status == 'Shipped') statusColor = Colors.blue;
                      if (status == 'Delivered') statusColor = freshGreen;
                      if (status == 'Cancelled') statusColor = Colors.redAccent;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        color: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            // düzeltme yapıldı
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Order ID: #${orderId.substring(orderId.length - 6).toUpperCase()}",
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      status,
                                      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),

                              Text(
                                "Customer ID: ${orderData['buyerId']?.toString().substring(0, 6).toUpperCase() ?? 'Generic Customer'}",
                                style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87, fontSize: 14),
                              ),
                              const SizedBox(height: 10),
                              const Text("Products:", style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 6),

                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        "$productName x$quantity $unit",
                                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                                      ),
                                    ),
                                    Text(
                                      "\$${(price * quantity).toStringAsFixed(2)}",
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Total: \$${totalPrice.toStringAsFixed(2)}",
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: freshGreen),
                                  ),
                                  if (status == 'Pending')
                                    ElevatedButton.icon(
                                      onPressed: () => _updateOrderStatus(orderId, 'Shipped'),
                                      icon: const Icon(Icons.local_shipping_outlined, size: 16),
                                      label: const Text("Ship Order", style: TextStyle(fontWeight: FontWeight.bold)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: freshGreen,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                    ),
                                  if (status == 'Shipped')
                                    ElevatedButton.icon(
                                      onPressed: () => _updateOrderStatus(orderId, 'Delivered'),
                                      icon: const Icon(Icons.done_all_rounded, size: 16),
                                      label: const Text("Mark Delivered", style: TextStyle(fontWeight: FontWeight.bold)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}