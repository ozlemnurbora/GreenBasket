import 'package:flutter/material.dart';
import '../services/cart_service.dart';
import '../services/order_service.dart';
import 'home_page.dart';

class OrderSuccessPage extends StatelessWidget {
  const OrderSuccessPage({super.key});

  // kargo ücreti 2.00$  hesaba dahil edildi
  Future<void> _processOrderAndGoHome(BuildContext context) async {
    final CartService cartService = CartService();
    final OrderService orderService = OrderService();

    try {
      // 1. Mevcut sepet öğelerini alır
      final items = await cartService.getCartItems().first;

      if (items.isNotEmpty) {
        // Ürünlerin alt toplamını hesaplar
        double subtotal = 0;
        for (var item in items) {
          subtotal += (item.price * item.quantity);
        }

        //  Toplam tutara 2.00$ teslimat ücreti ekler
        double finalTotal = subtotal + 2.00;

        // 2. Siparişi "orders" koleksiyonuna güncel tutarla kaydeder
        await orderService.placeOrder(
            items.map((e) => e.toMap()).toList(),
            finalTotal // 6.00$ yerine artık kargo dahil 8.00$ gidecek
        );

        // 3. Sepetteki tüm ürünleri Firebase'den temizler
        for (var item in items) {
          await cartService.removeFromCart(item.productId);
        }
      }

      // 4. Ana sayfaya  yönlendirir
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
              (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("An error occurred while processing your order.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color freshGreen = Color(0xFF4CAF50);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Başarı ikonu
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: freshGreen.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 100,
                  color: freshGreen,
                ),
              ),
              const SizedBox(height: 32),

              const Text(
                "Order Successful!",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 16),

              const Text(
                "Your organic products are being prepared and will be on their way soon. Thank you for choosing GreenBasket!",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
              ),
              const SizedBox(height: 60),

              // Ana Sayfaya Dön Butonu
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () => _processOrderAndGoHome(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: freshGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_bag_outlined),
                      SizedBox(width: 10),
                      Text("Back to Shopping", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}