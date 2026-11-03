import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/database_seeder.dart';
import '../services/favorite_service.dart';
import '../services/cart_service.dart';
import '../models/product_model.dart';
import '../widgets/custom_refresh_indicator.dart';
import 'product_detail_page.dart';
import 'product_list_page.dart';
import 'cart_page.dart';
import 'profile_page.dart';
import 'favorites_page.dart';
import 'search_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    DatabaseSeeder.uploadProducts();
  }

  String _getAppBarTitle(int index) {
    switch (index) {
      case 0:
        return "GreenBasket";
      case 1:
        return "Search";
      case 2:
        return "Favorites";
      case 3:
        return "My Cart";
      case 4:
        return "My Profile";
      default:
        return "GreenBasket";
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const HomeContent(),
      const SearchPage(),
      const FavoritesPage(),
      const CartPage(),
      const ProfilePage(),
    ];

    const Color freshGreen = Color(0xFF4CAF50);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: freshGreen,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.eco, color: Colors.white, size: 24),
            const SizedBox(width: 8),
            Text(
              _getAppBarTitle(_selectedIndex),
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 21),
            ),
          ],
        ),
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
        ),
        child: NavigationBar(
          backgroundColor: Colors.white,
          elevation: 0,
          selectedIndex: _selectedIndex,
          onDestinationSelected: (int index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
            NavigationDestination(icon: Icon(Icons.favorite_border), label: 'Favs'),
            NavigationDestination(icon: Icon(Icons.shopping_cart_outlined), label: 'Cart'),
            NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    const Color freshGreen = Color(0xFF4CAF50);
    final FavoriteService favoriteService = FavoriteService();
    final CartService cartService = CartService();

    return CustomRefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(seconds: 1));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Categories", style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildCategoryBox(context, "Fruits", "assets/images/fruits.jpg"),
                      _buildCategoryBox(context, "Vegetables", "assets/images/vegetables1.jpg"),
                      _buildCategoryBox(context, "Dairy", "assets/images/dairy.jpg"),
                    ],
                  ),
                ],
              ),
            ),

            _buildSectionHeader("Best Sellers", freshGreen, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProductListPage(title: "Best Sellers", tag: "best_seller"),
                ),
              );
            }),
            _buildDynamicProductGrid(freshGreen, "best_seller", 2, favoriteService, cartService),

            const SizedBox(height: 20),

            _buildSectionHeader("Fresh from the Farm", freshGreen, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProductListPage(title: "Fresh from the Farm", tag: "fresh_farm"),
                ),
              );
            }),
            _buildDynamicProductGrid(freshGreen, "fresh_farm", 2, favoriteService, cartService),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color themeColor, VoidCallback onSeeAll) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          TextButton(
            onPressed: onSeeAll,
            child: Text("See All", style: TextStyle(color: themeColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicProductGrid(Color themeColor, String tagFilter, int limit, FavoriteService favoriteService, CartService cartService) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .where('tags', arrayContains: tagFilter)
          .limit(limit)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text("Something went wrong"));
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.green));
        }
        final docs = snapshot.data!.docs;
        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
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
            return ProductCardWidget(product: product, themeColor: themeColor, favoriteService: favoriteService, cartService: cartService);
          },
        );
      },
    );
  }

  Widget _buildCategoryBox(BuildContext context, String label, String assetPath) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductListPage(
              title: label,
              category: label,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(22),
      child: Column(
        children: [
          Container(
            width: 95,
            height: 95,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.grey.shade300, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                assetPath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.image_not_supported, color: Colors.grey, size: 30),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
        ],
      ),
    );
  }
}

class ProductCardWidget extends StatefulWidget {
  final Product product;
  final Color themeColor;
  final FavoriteService favoriteService;
  final CartService cartService;

  const ProductCardWidget({
    super.key,
    required this.product,
    required this.themeColor,
    required this.favoriteService,
    required this.cartService
  });

  @override
  State<ProductCardWidget> createState() => _ProductCardWidgetState();
}

class _ProductCardWidgetState extends State<ProductCardWidget> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      // artık tüm kart tıklanabilir
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductDetailPage(product: widget.product),
        ),
      ),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200, width: 1.5),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 5))
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                    child: widget.product.imageUrl.startsWith('http')
                        ? Image.network(
                      widget.product.imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            color: widget.themeColor,
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: const Color(0xFFF0F4F0),
                        width: double.infinity,
                        child: Icon(Icons.image_not_supported_outlined, color: widget.themeColor),
                      ),
                    )
                        : Image.asset(
                      widget.product.imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),

                      FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('products')
                            .doc(widget.product.id)
                            .get(),
                        builder: (context, productSnapshot) {
                          String displayProducer = widget.product.producer;

                          if (productSnapshot.hasData && productSnapshot.data!.exists) {
                            final productData = productSnapshot.data!.data() as Map<String, dynamic>?;
                            if (productData != null && productData.containsKey('producerId')) {
                              String pId = productData['producerId'];

                              return FutureBuilder<DocumentSnapshot>(
                                future: FirebaseFirestore.instance.collection('users').doc(pId).get(),
                                builder: (context, userSnapshot) {
                                  if (userSnapshot.hasData && userSnapshot.data!.exists) {
                                    final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                                    displayProducer = userData?['fullName'] ?? displayProducer;
                                  }
                                  return Text(
                                    "By $displayProducer",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                                  );
                                },
                              );
                            }
                          }
                          return Text(
                            "By $displayProducer",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                          );
                        },
                      ),

                      Text("1 ${widget.product.unit}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, size: 16, color: Colors.orangeAccent),
                          const SizedBox(width: 2),
                          Text(widget.product.rating.toString(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 4),
                          Text("(${widget.product.reviewCount})", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),

                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _qtyBtn(Icons.remove, () { if(_quantity > 1) setState(() => _quantity--); }),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text("$_quantity", style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          _qtyBtn(Icons.add, () => setState(() => _quantity++)),
                        ],
                      ),
                      const SizedBox(height: 8),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("\$${widget.product.price.toStringAsFixed(2)}", style: TextStyle(color: widget.themeColor, fontWeight: FontWeight.bold, fontSize: 16)),
                          InkWell(
                            onTap: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              final String pName = widget.product.name;
                              final Color tColor = widget.themeColor;
                              final int qValue = _quantity;
                              final String pUnit = widget.product.unit;

                              await widget.cartService.addToCart(widget.product, qValue);

                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text("Added $qValue $pUnit of $pName to cart! 🛒"),
                                  backgroundColor: tColor,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: widget.themeColor, shape: BoxShape.circle),
                              child: const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 18),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                )
              ],
            ),
            Positioned(
              top: 5,
              right: 5,
              child: StreamBuilder<bool>(
                stream: widget.favoriteService.isFavorite(widget.product.id!),
                builder: (context, snapshot) {
                  final isFav = snapshot.data ?? false;
                  return Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () => widget.favoriteService.toggleFavorite(widget.product.id!),
                      icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: Colors.redAccent, size: 20),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback action) {
    return InkWell(
      onTap: action,
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), shape: BoxShape.circle),
        child: Icon(icon, size: 16, color: Colors.black87),
      ),
    );
  }
}