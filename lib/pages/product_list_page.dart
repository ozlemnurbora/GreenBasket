import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../widgets/custom_refresh_indicator.dart';
import '../widgets/common_app_bar.dart';
import '../services/favorite_service.dart';
import '../services/cart_service.dart';
import 'home_page.dart';

class ProductListPage extends StatelessWidget {
  final String title;
  final String? category;
  final String? tag;

  const ProductListPage({
    super.key,
    required this.title,
    this.category,
    this.tag
  });

  @override
  Widget build(BuildContext context) {
    const Color freshGreen = Color(0xFF4CAF50);
    final FavoriteService favoriteService = FavoriteService();
    final CartService cartService = CartService();

    // Firebase Sorgusu
    Query query = FirebaseFirestore.instance.collection('products');
    if (category != null) {
      query = query.where('category', isEqualTo: category);
    } else if (tag != null) {
      query = query.where('tags', arrayContains: tag);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      // Başlık  yeşil bara taşındı ve geri dönme oku aktif edildi
      appBar: CommonAppBar(title: title, showBackButton: true),
      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Something went wrong"));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: freshGreen));
          }

          final docs = snapshot.data!.docs;

          //  Boş durumlar için CustomRefreshIndicator uyumlu
          if (docs.isEmpty) {
            return CustomRefreshIndicator(
              onRefresh: () async {
                await Future.delayed(const Duration(seconds: 1));
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_basket_outlined, size: 70, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          "No products found in '$title'.",
                          style: const TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          // Başlık yukarı taşındığı için Column yapısından kurtulup doğrudan GridView yerleştirildi
          return CustomRefreshIndicator(
            onRefresh: () async {
              await Future.delayed(const Duration(seconds: 1));
            },
            child: GridView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.61,
                mainAxisSpacing: 15,
                crossAxisSpacing: 15,
              ),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                final product = Product.fromFirestore(data, docs[index].id);

                // home_page.dart içinde güncellediğimiz akıllı hibrit kart yapısı burada da var.
                return ProductCardWidget(
                    product: product,
                    themeColor: freshGreen,
                    favoriteService: favoriteService,
                    cartService: cartService
                );
              },
            ),
          );
        },
      ),
    );
  }
}