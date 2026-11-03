import 'package:flutter/material.dart';
import '../services/cart_service.dart';
import '../models/cart_model.dart';
import '../widgets/custom_refresh_indicator.dart';
import 'checkout_page.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final CartService cartService = CartService();
    const Color freshGreen = Color(0xFF4CAF50);
    const double deliveryFee = 2.00;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomRefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(seconds: 1));
        },
        child: StreamBuilder<List<CartItem>>(
          stream: cartService.getCartItems(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return const Center(child: Text("An error occurred"));
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: freshGreen));
            }

            final cartItems = snapshot.data ?? [];

            if (cartItems.isEmpty) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.7,
                  alignment: Alignment.center,
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text("Your cart is empty", style: TextStyle(color: Colors.grey, fontSize: 16)),
                    ],
                  ),
                ),
              );
            }

            double subtotal = 0;
            for (var item in cartItems) {
              subtotal += (item.price * item.quantity);
            }

            final double finalTotal = subtotal + deliveryFee;

            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      return _buildCartItem(context, cartItems[index], cartService, freshGreen);
                    },
                  ),
                ),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Subtotal:", style: TextStyle(fontSize: 15, color: Colors.black54)),
                            Text("\$${subtotal.toStringAsFixed(2)}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
                          ],
                        ),
                        const SizedBox(height: 8),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Delivery Fee:", style: TextStyle(fontSize: 15, color: Colors.black54)),
                            Text("\$${deliveryFee.toStringAsFixed(2)}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Divider(height: 1),
                        ),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Total:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                            Text("\$${finalTotal.toStringAsFixed(2)}",
                                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: freshGreen)),
                          ],
                        ),
                        const SizedBox(height: 16),

                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CheckoutPage(totalAmount: subtotal),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: freshGreen,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              elevation: 0,
                            ),
                            child: const Text("Go to Checkout", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCartItem(BuildContext context, CartItem item, CartService cartService, Color themeColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              // --- GÜNCELLENDİ: İnternet resimlerini ve yerel assetleri çakışmadan ayıran hibrit yapı ---
              child: item.imageUrl.startsWith('http')
                  ? Image.network(
                item.imageUrl,
                width: 70,
                height: 70,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Color(0xFF4CAF50), strokeWidth: 2),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported_outlined, color: Color(0xFF4CAF50), size: 24),
              )
                  : Image.asset(
                item.imageUrl,
                width: 70,
                height: 70,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.eco, color: Colors.green, size: 24),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text("\$${item.price.toStringAsFixed(2)} / ${item.unit}",
                    style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _qtyBtn(Icons.remove, () {
                      if (item.quantity > 1) {
                        cartService.updateQuantity(item.productId, item.quantity - 1);
                      }
                    }),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text("${item.quantity}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    _qtyBtn(Icons.add, () {
                      cartService.updateQuantity(item.productId, item.quantity + 1);
                    }),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () => cartService.removeFromCart(item.productId),
          ),
        ],
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: Colors.black87),
      ),
    );
  }
}