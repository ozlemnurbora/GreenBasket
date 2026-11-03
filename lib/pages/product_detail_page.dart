import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product_model.dart';
import '../services/favorite_service.dart';
import '../services/cart_service.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/custom_refresh_indicator.dart';

class ProductDetailPage extends StatefulWidget {
  final Product product;

  const ProductDetailPage({super.key, required this.product});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final Color freshGreen = const Color(0xFF4CAF50);
  final FavoriteService _favoriteService = FavoriteService();
  final CartService _cartService = CartService();
  int _quantity = 1;

  // Yorumlar bölümüne otomatik kaydırma için global anahtar
  final GlobalKey _reviewsKey = GlobalKey();

  // Yorum penceresi için gerekli state değişkenleri ve kontrolcü
  int _selectedRating = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmittingReview = false;

  void _increment() {
    setState(() {
      _quantity++;
    });
  }

  void _decrement() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
    }
  }

  // Üstteki reviews yazısına tıklayınca aşağı kayma
  void _scrollToReviews() {
    final context = _reviewsKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    }
  }

  // Canlı Yorum Ekleme ve Dinamik Ortalama Hesaplama
  Future<void> _submitReviewAndRecalculate() async {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a rating star! 🌟"), backgroundColor: Colors.orangeAccent),
      );
      return;
    }

    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please write a comment first!"), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _isSubmittingReview = true);

    try {
      final String productId = widget.product.id!;

      String buyerName = FirebaseAuth.instance.currentUser?.displayName ?? "";
      if (buyerName.isEmpty) {
        buyerName = FirebaseAuth.instance.currentUser?.email ?? "anonymous@mail.com";
      }

      DocumentReference reviewRef = FirebaseFirestore.instance.collection('reviews').doc();
      WriteBatch batch = FirebaseFirestore.instance.batch();

      batch.set(reviewRef, {
        'productId': productId,
        'buyerId': uid,
        'buyerName': buyerName,
        'rating': _selectedRating,
        'comment': _commentController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      QuerySnapshot reviewsSnapshot = await FirebaseFirestore.instance
          .collection('reviews')
          .where('productId', isEqualTo: productId)
          .get();

      int totalReviewsCount = reviewsSnapshot.docs.length + 1;
      double totalRatingSum = _selectedRating.toDouble();

      for (var doc in reviewsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        totalRatingSum += (data['rating'] as num? ?? 0).toDouble();
      }

      double newAverageRating = totalRatingSum / totalReviewsCount;

      DocumentReference productRef = FirebaseFirestore.instance.collection('products').doc(productId);
      batch.update(productRef, {
        'rating': double.parse(newAverageRating.toStringAsFixed(1)),
        'reviewCount': totalReviewsCount,
      });

      await batch.commit();

      if (mounted) {
        _commentController.clear();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text("Thank you for your review! 🌟"), backgroundColor: freshGreen),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to submit review: $e"), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmittingReview = false);
    }
  }

  void _showReviewDialog() {
    _selectedRating = 0;
    _commentController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 20),
              const Text("Rate the Product", style: TextStyle(fontSize: 20, fontStyle: FontStyle.normal, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () {
                      setModalState(() {
                        _selectedRating = index + 1;
                      });
                    },
                    child: Icon(
                      index < _selectedRating ? Icons.star_rounded : Icons.star_border_rounded,
                      size: 44,
                      color: index < _selectedRating ? Colors.orange : Colors.grey[400],
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _commentController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Write your comment here...",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: freshGreen), borderRadius: BorderRadius.circular(15)),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSubmittingReview ? null : _submitReviewAndRecalculate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: freshGreen,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: _isSubmittingReview
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Submit Review", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CommonAppBar(),
      body: Column(
        children: [
          Expanded(
            child: CustomRefreshIndicator(
              onRefresh: () async {
                await Future.delayed(const Duration(seconds: 1));
              },
              // Parantez hatası düzeltildi
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('products').doc(product.id).snapshots(),
                builder: (context, productSnapshot) {
                  double currentRating = product.rating;
                  int currentReviewCount = product.reviewCount;

                  if (productSnapshot.hasData && productSnapshot.data!.exists) {
                    final pData = productSnapshot.data!.data() as Map<String, dynamic>;
                    currentRating = (pData['rating'] as num? ?? 0.0).toDouble();
                    currentReviewCount = (pData['reviewCount'] as num? ?? 0).toInt();
                  }

                  // Düzeltildi
                  return _buildProductContent(product, currentRating, currentReviewCount);
                },
              ),
            ),
          ),

          // Alt Sepet Alanı
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(30)),
                  child: Row(
                    children: [
                      _buildQuantityBtn(Icons.remove, _decrement),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text("$_quantity", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                      _buildQuantityBtn(Icons.add, _increment),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      await _cartService.addToCart(product, _quantity);

                      messenger.showSnackBar(
                          SnackBar(
                            content: Text("Added $_quantity ${product.unit} of ${product.name} to cart! 🛒"),
                            backgroundColor: freshGreen,
                            duration: const Duration(seconds: 2),
                          )
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: freshGreen,
                      minimumSize: const Size(0, 55),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: const Text("Add to Cart", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // parantez hatası düzeltildi
  Widget _buildProductContent(Product product, double currentRating, int currentReviewCount) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                height: 240,
                width: double.infinity,
                color: Colors.grey[100],
                child: product.imageUrl.startsWith('http')
                    ? Image.network(
                  product.imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        color: freshGreen,
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(Icons.image_not_supported_outlined, size: 60, color: freshGreen),
                )
                    : Image.asset(
                  product.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.image_outlined, size: 80, color: Colors.grey),
                ),
              ),
              Positioned(
                top: 15,
                right: 15,
                child: StreamBuilder<bool>(
                  stream: _favoriteService.isFavorite(product.id!),
                  builder: (context, snapshot) {
                    final isFav = snapshot.data ?? false;
                    return CircleAvatar(
                      backgroundColor: Colors.white,
                      child: IconButton(
                        onPressed: () => _favoriteService.toggleFavorite(product.id!),
                        icon: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          color: Colors.red,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(
                      "\$${product.price.toStringAsFixed(2)}",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: freshGreen),
                    ),
                  ],
                ),
                Text("1 ${product.unit}", style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600)),
                const SizedBox(height: 15),

                // Tıklanabilir ve Aşağı Kaydıran Reviews Satırı
                GestureDetector(
                  onTap: _scrollToReviews,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.orange, size: 22),
                        const SizedBox(width: 4),
                        Text(currentRating.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(width: 8),
                        Text(
                          "($currentReviewCount Reviews)",
                          style: TextStyle(
                            color: Colors.grey[600],
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 25),

                const Text("Producer", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(backgroundColor: freshGreen, child: const Icon(Icons.store, color: Colors.white)),
                  title: Text(product.producer, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text("Certified Organic Producer"),
                  trailing: const Icon(Icons.verified, color: Colors.blue, size: 20),
                ),
                const SizedBox(height: 20),
                const Text("Description", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  product.description,
                  style: const TextStyle(color: Colors.black87, height: 1.5, fontSize: 15),
                ),
                const SizedBox(height: 30),

                // Otomatik kaydırma hedefi için GlobalKey bağlanan başlık
                Row(
                  key: _reviewsKey,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Customer Reviews", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.rate_review_outlined, size: 22),
                          color: freshGreen,
                          onPressed: _showReviewDialog,
                        ),
                      ],
                    ),
                  ],
                ),

                // Canlı Yorum Akışı Listesi
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('reviews')
                      .where('productId', isEqualTo: product.id)
                      .snapshots(),
                  builder: (context, reviewSnapshot) {
                    if (reviewSnapshot.hasError) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: Text("Error loading reviews...", style: TextStyle(color: Colors.grey)),
                      );
                    }
                    if (reviewSnapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 12.0),
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      );
                    }

                    final reviewDocs = reviewSnapshot.data?.docs ?? [];

                    if (reviewDocs.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 16.0, bottom: 10.0),
                        child: Center(
                          child: Text(
                            "No reviews yet. Be the first to review! ✨",
                            style: TextStyle(color: Colors.grey[500], fontSize: 13, fontStyle: FontStyle.italic),
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: reviewDocs.length,
                      itemBuilder: (context, idx) {
                        final rData = reviewDocs[idx].data() as Map<String, dynamic>;
                        final String name = rData['buyerName'] ?? 'Anonymous';
                        final String comment = rData['comment'] ?? '';
                        final int score = (rData['rating'] ?? 5).toInt();

                        return _buildReviewItem(name, comment, score);
                      },
                    );
                  },
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: Icon(icon, size: 20, color: Colors.black),
      ),
    );
  }

  Widget _buildReviewItem(String name, String comment, int rating) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Row(
                children: List.generate(5, (index) => Icon(Icons.star_rounded, size: 16, color: index < rating ? Colors.orange : Colors.grey[300])),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(comment, style: const TextStyle(fontSize: 13, color: Colors.black54)),
        ],
      ),
    );
  }
}