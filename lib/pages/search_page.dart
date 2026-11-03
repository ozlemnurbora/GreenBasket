import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../services/favorite_service.dart';
import '../services/cart_service.dart';
import '../widgets/custom_refresh_indicator.dart';
import 'home_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  final FavoriteService _favoriteService = FavoriteService();
  final CartService _cartService = CartService();

  final Color freshGreen = const Color(0xFF4CAF50);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Modern Arama Çubuğu
          Padding(
            padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 16.0, bottom: 8.0),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4F0),
                borderRadius: BorderRadius.circular(15),
              ),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                cursorColor: freshGreen,
                style: const TextStyle(fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: "Search products or categories...",
                  hintStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: Icon(Icons.search_rounded, color: freshGreen),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear_rounded, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = "");
                    },
                  )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.trim().toLowerCase();
                  });
                },
              ),
            ),
          ),

          // Dinamik Arama Sonuç Alanı
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('products').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text("An error occurred"));
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: freshGreen));
                }

                final docs = snapshot.data?.docs ?? [];

                final filteredProducts = docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return Product.fromFirestore(data, doc.id);
                }).where((product) {
                  //  Kategori kapaklarının dökümanlarını filtre dışı bırakıyoruz
                  final String pNameLower = product.name.toLowerCase();
                  if (product.price <= 0 ||
                      pNameLower == "fruits" ||
                      pNameLower == "vegetables" ||
                      pNameLower == "dairy") {
                    return false;
                  }

                  final nameMatch = pNameLower.contains(_searchQuery);
                  final categoryMatch = product.category.toLowerCase().contains(_searchQuery);
                  return nameMatch || categoryMatch;
                }).toList();

                if (_searchQuery.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_outlined, size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        const Text(
                          "Type to find organic products",
                          style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  );
                }

                if (filteredProducts.isEmpty) {
                  return CustomRefreshIndicator(
                    onRefresh: () async => await Future.delayed(const Duration(seconds: 1)),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                        Center(
                          child: Column(
                            children: [
                              Icon(Icons.sentiment_dissatisfied_rounded, size: 80, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text(
                                "No results found for \"$_searchQuery\"",
                                style: const TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return CustomRefreshIndicator(
                  onRefresh: () async => await Future.delayed(const Duration(seconds: 1)),
                  child: GridView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.61,
                      mainAxisSpacing: 15,
                      crossAxisSpacing: 15,
                    ),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      // düzenlendi
                      return ProductCardWidget(
                        product: product,
                        themeColor: freshGreen,
                        favoriteService: _favoriteService,
                        cartService: _cartService,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}