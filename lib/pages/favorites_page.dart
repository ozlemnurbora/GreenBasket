import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/favorite_service.dart';
import '../models/product_model.dart';
import '../widgets/custom_refresh_indicator.dart';
import 'product_detail_page.dart';
import 'home_page.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final FavoriteService favoriteService = FavoriteService();
    const Color freshGreen = Color(0xFF4CAF50);

    return Scaffold(
      backgroundColor: Colors.white,
      // düzeltildi
      appBar: null,
      body: CustomRefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(seconds: 1));
        },
        child: StreamBuilder<List<String>>(
          stream: favoriteService.getFavorites(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return const Center(child: Text("Something went wrong"));
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: freshGreen));
            }

            final favIds = snapshot.data ?? [];

            if (favIds.isEmpty) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.7,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.favorite_border_rounded, size: 80, color: Colors.grey[300]),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "Your favorites list is empty",
                        style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Items you favorite will appear here for easy access later.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => const HomePage()),
                                (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: freshGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          elevation: 0,
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.shopping_bag_outlined, size: 20),
                            SizedBox(width: 8),
                            Text("Start Shopping", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('products')
                  .where(FieldPath.documentId, whereIn: favIds)
                  .snapshots(),
              builder: (context, productSnapshot) {
                if (productSnapshot.hasError) return const Center(child: Text("Error loading products"));
                if (productSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: freshGreen));
                }

                final docs = productSnapshot.data!.docs;

                return ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final product = Product.fromFirestore(data, docs[index].id);
                    return _buildFavoriteItem(context, product, favoriteService);
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildFavoriteItem(BuildContext context, Product product, FavoriteService favoriteService) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ProductDetailPage(product: product)),
          );
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: product.imageUrl.startsWith('http')
                ? Image.network(
              product.imageUrl,
              width: 60,
              height: 60,
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
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported_outlined, color: Color(0xFF4CAF50)),
            )
                : Image.asset(
              product.imageUrl,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.eco, color: Colors.green),
            ),
          ),
        ),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text("\$${product.price.toStringAsFixed(2)} / ${product.unit}"),
        trailing: IconButton(
          icon: const Icon(Icons.favorite, color: Colors.red),
          onPressed: () => favoriteService.toggleFavorite(product.id!),
        ),
      ),
    );
  }
}