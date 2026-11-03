import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/custom_refresh_indicator.dart';
import 'package:intl/intl.dart';
import '../models/product_model.dart';
import 'product_detail_page.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    const Color freshGreen = Color(0xFF4CAF50);
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBF8),
      appBar: const CommonAppBar(title: "My Orders", showBackButton: true),
      body: currentUserId.isEmpty
          ? const Center(child: Text("Please log in to see your orders."))
          : CustomRefreshIndicator(
        onRefresh: () async => await Future.delayed(const Duration(seconds: 1)),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('orders')
              .where('buyerId', isEqualTo: currentUserId)
              .orderBy('orderDate', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              if (snapshot.error.toString().contains('index')) {
                return const Center(child: Text("Firebase index is building, please wait."));
              }
              return const Center(child: Text("An error occurred"));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: freshGreen));
            }

            final ordersDocs = snapshot.data?.docs ?? [];

            if (ordersDocs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.assignment_outlined, size: 80, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    const Text("No orders found", style: TextStyle(color: Colors.grey, fontSize: 16)),
                  ],
                ),
              );
            }


            Map<String, List<Map<String, dynamic>>> groupedOrders = {};

            for (var doc in ordersDocs) {
              final data = doc.data() as Map<String, dynamic>;
              final Timestamp? timestamp = data['orderDate'] as Timestamp?;
              final DateTime date = timestamp != null ? timestamp.toDate() : DateTime.now();

              // tarihi 'Yıl-Ay-Gün Saat:Dakika' formatında alıyoruz
              final String groupKey = DateFormat('yyyy-MM-dd HH:mm').format(date);

              if (!groupedOrders.containsKey(groupKey)) {
                groupedOrders[groupKey] = [];
              }
              groupedOrders[groupKey]!.add(data);
            }

            final List<String> sortedKeys = groupedOrders.keys.toList();

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount: sortedKeys.length,
              itemBuilder: (context, index) {
                final String key = sortedKeys[index];
                final List<Map<String, dynamic>> itemsInOrder = groupedOrders[key]!;

                return GroupedOrderCardWidget(
                  orderItems: itemsInOrder,
                  themeColor: freshGreen,
                  groupDateTimeKey: key,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class GroupedOrderCardWidget extends StatefulWidget {
  final List<Map<String, dynamic>> orderItems;
  final Color themeColor;
  final String groupDateTimeKey;

  const GroupedOrderCardWidget({
    super.key,
    required this.orderItems,
    required this.themeColor,
    required this.groupDateTimeKey,
  });

  @override
  State<GroupedOrderCardWidget> createState() => _GroupedOrderCardWidgetState();
}

class _GroupedOrderCardWidgetState extends State<GroupedOrderCardWidget> {
  bool _isExpanded = false;

  // Statü renklendirmelerini merkezi bir fonksiyona aldık
  Color _getStatusColor(String status) {
    if (status == "Completed" || status == "shipped" || status == "Shipped" || status == "Delivered" || status == "delivered") {
      return Colors.green;
    }
    if (status == "Cancelled" || status == "Rejected") return Colors.redAccent;
    return Colors.orange; // Pending, Preparing vb. durumlar için
  }

  @override
  Widget build(BuildContext context) {
    final firstItem = widget.orderItems.first;
    final Timestamp? timestamp = firstItem['orderDate'] as Timestamp?;
    final DateTime date = timestamp != null ? timestamp.toDate() : DateTime.now();
    final String formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(date);

    // Tüm grubun (sepetteki tüm ürünlerin) toplam fiyatını hesaplıyoruz
    double orderTotalSum = 0.0;
    for (var item in widget.orderItems) {
      final double itemTotal = (item['totalPrice'] ?? 0.0).toDouble();
      orderTotalSum += itemTotal;
    }

    // --- DÜZELTME: Kargo ücretini toplama dahil ediyoruz ---
    const double deliveryFee = 2.00;
    double finalTotalPayment = orderTotalSum + deliveryFee;

    // Arka planda statü çeşitliliğini kontrol ediyoruz
    final Set<String> uniqueStatuses = widget.orderItems.map((item) => (item['status'] ?? "Pending").toString()).toSet();
    final String displayMainStatus = uniqueStatuses.length == 1 ? uniqueStatuses.first : "Multiple Statuses";

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFEDF4ED),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                    "Order Summary",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)
                ),
                Text(formattedDate, style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
            const Divider(height: 20),

            SizedBox(
              height: 55,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: widget.orderItems.length,
                itemBuilder: (context, i) {
                  final item = widget.orderItems[i];
                  final String imageUrl = item['imageUrl'] ?? '';
                  final String pId = item['productId'] ?? '';

                  final dummyProduct = Product(
                    id: pId,
                    name: item['productName'] ?? 'Product',
                    price: (item['price'] ?? 0.0).toDouble(),
                    unit: item['unit'] ?? 'kg',
                    imageUrl: imageUrl,
                    producer: item['producerId'] ?? '',
                    producerId: item['producerId'] ?? '',
                    description: 'Organic product from GreenBasket.',
                    stock: 100,
                    category: 'Vegetables',
                    rating: 4.5,
                    reviewCount: 12,
                    tags: ['fresh_farm'],
                  );

                  return GestureDetector(
                    onTap: pId.isEmpty ? null : () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ProductDetailPage(product: dummyProduct)),
                    ),
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300, width: 1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: imageUrl.startsWith('http')
                            ? Image.network(imageUrl, width: 50, height: 50, fit: BoxFit.cover)
                            : Image.asset(imageUrl.isNotEmpty ? imageUrl : "assets/images/vegetables1.jpg", width: 50, height: 50, fit: BoxFit.cover),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(displayMainStatus).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    displayMainStatus,
                    style: TextStyle(color: _getStatusColor(displayMainStatus), fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                const Spacer(),
                // --- DÜZELTME: (inc. delivery) ibaresi eklenerek UX netleştirildi ve toplam güncellendi ---
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        const Text("Total Payment: ", style: TextStyle(color: Colors.grey)),
                        Text("\$${finalTotalPayment.toStringAsFixed(2)}",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      ],
                    ),
                    if (!_isExpanded)
                      const Text(
                        "(includes \$2.00 delivery)",
                        style: TextStyle(color: Colors.grey, fontSize: 11, fontStyle: FontStyle.italic),
                      ),
                  ],
                ),
              ],
            ),

            if (_isExpanded) ...[
              const Divider(height: 30),
              const Text("Products in this Order:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 8),

              ...widget.orderItems.map((item) {
                final String pName = item['productName'] ?? 'Unknown Product';
                final int qty = (item['quantity'] ?? 1).toInt();
                final double prc = (item['price'] ?? 0.0).toDouble();
                final String unt = item['unit'] ?? 'kg';
                final String itemStatus = item['status'] ?? 'Pending';

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("$pName (x$qty $unt)", style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 2),
                          Text(
                              "Status: $itemStatus",
                              style: TextStyle(color: _getStatusColor(itemStatus), fontSize: 12, fontWeight: FontWeight.bold)
                          ),
                        ],
                      ),
                      Text("\$${(prc * qty).toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Delivery Fee", style: TextStyle(color: Colors.grey, fontSize: 13)),
                  Text("\$${deliveryFee.toStringAsFixed(2)}", style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                ],
              ),
            ],

            const SizedBox(height: 20),

            InkWell(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              borderRadius: BorderRadius.circular(15),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: widget.themeColor, width: 1.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: widget.themeColor, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      _isExpanded ? "Hide Details" : "Order Details",
                      style: TextStyle(color: widget.themeColor, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}