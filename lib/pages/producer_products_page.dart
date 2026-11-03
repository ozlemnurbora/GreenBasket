import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/custom_refresh_indicator.dart';

class ProducerProductsPage extends StatefulWidget {
  const ProducerProductsPage({super.key});

  @override
  State<ProducerProductsPage> createState() => _ProducerProductsPageState();
}

class _ProducerProductsPageState extends State<ProducerProductsPage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final Color freshGreen = const Color(0xFF4CAF50);

  // Stok miktarını hızlı butonlarla Firestore'da güncelleyen fonksiyon
  Future<void> _updateStock(String docId, int currentStock, int change) async {
    int newStock = currentStock + change;
    if (newStock < 0) return; // Stok negatif olamaz

    try {
      await FirebaseFirestore.instance
          .collection('products')
          .doc(docId)
          .update({'stock': newStock});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update stock: $e"), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  // --- Ürün Düzenleme (Edit) Penceresini Açan Fonksiyon ---
  void _showEditBottomSheet({
    required BuildContext context,
    required String docId,
    required String currentName,
    required double currentPrice,
    required int currentStock,
    required String currentDescription,
    required String currentUnit,
    required String currentCategory,
    required String currentImageUrl,
  }) {
    final TextEditingController nameEditController = TextEditingController(text: currentName);
    final TextEditingController priceEditController = TextEditingController(text: currentPrice.toString());
    final TextEditingController stockEditController = TextEditingController(text: currentStock.toString());
    final TextEditingController descEditController = TextEditingController(text: currentDescription);

    String selectedCategory = currentCategory;
    String selectedUnit = currentUnit;

    final GlobalKey<FormState> editFormKey = GlobalKey<FormState>();

    final List<String> categories = ["Fruits", "Vegetables", "Dairy"];
    final List<String> units = ["kg", "Pack", "Piece", "Dozen"];

    if (!categories.contains(selectedCategory)) selectedCategory = "Fruits";
    if (!units.contains(selectedUnit)) selectedUnit = "kg";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setBottomSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                top: 20,
                left: 20,
                right: 20,
              ),
              child: Form(
                key: editFormKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Edit Product Details",
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          )
                        ],
                      ),
                      const Divider(),
                      const SizedBox(height: 12),

                      // 1. Ürün Adı Düzenleme
                      TextFormField(
                        controller: nameEditController,
                        decoration: InputDecoration(
                          labelText: "Product Name",
                          prefixIcon: Icon(Icons.shopping_basket_outlined, color: freshGreen),
                          filled: true,
                          fillColor: const Color(0xFFF0F4F0),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        validator: (v) => v!.isEmpty ? "Enter product name" : null,
                      ),
                      const SizedBox(height: 14),

                      // 2. Fiyat ve Stok Düzenleme Yan Yana
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: priceEditController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: "Price (\$)",
                                prefixIcon: Icon(Icons.attach_money_rounded, color: freshGreen),
                                filled: true,
                                fillColor: const Color(0xFFF0F4F0),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              ),
                              validator: (v) => v!.isEmpty ? "Enter price" : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: stockEditController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: "Stock",
                                prefixIcon: Icon(Icons.inventory_2_outlined, color: freshGreen),
                                filled: true,
                                fillColor: const Color(0xFFF0F4F0),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              ),
                              validator: (v) => v!.isEmpty ? "Enter stock" : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // 3. Kategori ve Birim Seçimi (Dropdown)
                      // --- DÜZELTME: Deprecated 'value' parametresi 'initialValue' olarak güncellendi ve uyarılar silindi ---
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: selectedCategory,
                              decoration: InputDecoration(
                                labelText: "Category",
                                prefixIcon: Icon(Icons.grid_view_rounded, color: freshGreen),
                                filled: true,
                                fillColor: const Color(0xFFF0F4F0),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              ),
                              items: categories.map((String cat) {
                                return DropdownMenuItem<String>(value: cat, child: Text(cat));
                              }).toList(),
                              onChanged: (String? newValue) {
                                setBottomSheetState(() {
                                  selectedCategory = newValue!;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: selectedUnit,
                              decoration: InputDecoration(
                                labelText: "Unit",
                                prefixIcon: Icon(Icons.scale_outlined, color: freshGreen),
                                filled: true,
                                fillColor: const Color(0xFFF0F4F0),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              ),
                              items: units.map((String ut) {
                                return DropdownMenuItem<String>(value: ut, child: Text(ut));
                              }).toList(),
                              onChanged: (String? newValue) {
                                setBottomSheetState(() {
                                  selectedUnit = newValue!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // --- DÜZELTME: Saçma duran resim linki (URL) metin alanı senin isteğin üzerine tamamen kaldırıldı ---

                      // 4. Ürün Açıklaması (Description)
                      TextFormField(
                        controller: descEditController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: "Description",
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(bottom: 40.0),
                            child: Icon(Icons.description_outlined, color: freshGreen),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF0F4F0),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        validator: (v) => v!.isEmpty ? "Enter description" : null,
                      ),
                      const SizedBox(height: 20),

                      // 5. Kaydet Butonu
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (!editFormKey.currentState!.validate()) return;

                            try {
                              await FirebaseFirestore.instance.collection('products').doc(docId).update({
                                'name': nameEditController.text.trim(),
                                'price': double.parse(priceEditController.text.trim()),
                                'stock': int.parse(stockEditController.text.trim()),
                                'description': descEditController.text.trim(),
                                'category': selectedCategory,
                                'unit': selectedUnit,
                                // Resim URL'si değişmediği için mevcut resmi koruyoruz
                                'imageUrl': currentImageUrl,
                              });
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: const Text("Product details updated successfully!"), backgroundColor: freshGreen),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Update failed: $e"), backgroundColor: Colors.redAccent),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: freshGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text("Save Changes", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Ürünü mağazadan tamamen silen fonksiyon
  Future<void> _deleteProduct(String docId) async {
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Product", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Are you sure you want to permanently remove this product from your inventory?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      try {
        await FirebaseFirestore.instance.collection('products').doc(docId).delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Product removed successfully 🗑️"), backgroundColor: Colors.black87),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to delete product: $e"), backgroundColor: Colors.redAccent),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Scaffold(
        appBar: CommonAppBar(title: "My Product Inventory", showBackButton: true),
        body: Center(child: Text("Please log in to manage your products.")),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F7),
      appBar: const CommonAppBar(title: "My Product Inventory", showBackButton: true),
      body: CustomRefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('products')
              .where('producerId', isEqualTo: currentUser!.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text("Something went wrong: ${snapshot.error}"));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: freshGreen));
            }

            final docs = snapshot.data!.docs;

            if (docs.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                  const Center(
                    child: Column(
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          "You haven't added any products yet.",
                          style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            // Envanter Özeti Hesaplama (Üst Kartlar İçin)
            int totalProducts = docs.length;
            int totalStock = 0;
            for (var doc in docs) {
              final data = doc.data() as Map<String, dynamic>;
              if (data.containsKey('stock') && data['stock'] != null) {
                totalStock += (data['stock'] as num).toInt();
              }
            }

            return Column(
              children: [
                // 1. Üst Kısım: Mağaza Envanter Bilgi Kartı
                Container(
                  padding: const EdgeInsets.all(16.0),
                  color: Colors.white,
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          title: "Total Items",
                          value: totalProducts.toString(),
                          icon: Icons.grid_view_rounded,
                          color: freshGreen,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSummaryCard(
                          title: "Total Stock",
                          value: totalStock.toString(),
                          icon: Icons.layers_outlined,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
                // 2. Ürün Listesi
                Expanded(
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(14.0),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;

                      String docId = doc.id;
                      String name = data['name'] ?? 'Unknown Product';
                      double price = (data['price'] as num?)?.toDouble() ?? 0.0;
                      int stock = (data['stock'] as num?)?.toInt() ?? 0;
                      String unit = data['unit'] ?? 'kg';
                      String imageUrl = data['imageUrl'] ?? 'assets/images/fruits.jpg';

                      String description = data['description'] ?? 'No description provided.';
                      String category = data['category'] ?? 'Fruits';

                      bool isOutOfStock = stock == 0;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              // Resim Alanı (Hibrit Yapı)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: imageUrl.startsWith('http')
                                    ? Image.network(
                                  imageUrl,
                                  width: 75,
                                  height: 75,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    width: 75,
                                    height: 75,
                                    color: const Color(0xFFF0F4F0),
                                    child: Icon(Icons.image_not_supported_outlined, color: freshGreen),
                                  ),
                                )
                                    : Image.asset(
                                  imageUrl,
                                  width: 75,
                                  height: 75,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    width: 75,
                                    height: 75,
                                    color: const Color(0xFFF0F4F0),
                                    child: Icon(Icons.image_not_supported_outlined, color: freshGreen),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              // Ürün Bilgileri
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "\$$price / $unit",
                                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: freshGreen),
                                    ),
                                    const SizedBox(height: 6),
                                    // Stok Durum Etiketi
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isOutOfStock ? Colors.red.withValues(alpha: 0.1) : freshGreen.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        isOutOfStock ? "Out of Stock" : "Stock: $stock $unit",
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: isOutOfStock ? Colors.redAccent : freshGreen,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Sağ Kısım: Düzenleme, Silme
                              Column(
                                children: [
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.edit_outlined, color: freshGreen, size: 22),
                                        onPressed: () => _showEditBottomSheet(
                                          context: context,
                                          docId: docId,
                                          currentName: name,
                                          currentPrice: price,
                                          currentStock: stock,
                                          currentDescription: description,
                                          currentUnit: unit,
                                          currentCategory: category,
                                          currentImageUrl: imageUrl,
                                        ),
                                        constraints: const BoxConstraints(),
                                        padding: EdgeInsets.zero,
                                      ),
                                      const SizedBox(width: 10),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
                                        onPressed: () => _deleteProduct(docId),
                                        constraints: const BoxConstraints(),
                                        padding: EdgeInsets.zero,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      _buildActionButton(
                                        icon: Icons.remove,
                                        onPressed: isOutOfStock ? null : () => _updateStock(docId, stock, -1),
                                      ),
                                      const SizedBox(width: 6),
                                      _buildActionButton(
                                        icon: Icons.add,
                                        onPressed: () => _updateStock(docId, stock, 1),
                                      ),
                                    ],
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

  // Stok aksiyon butonları tasarımı
  Widget _buildActionButton({required IconData icon, required VoidCallback? onPressed}) {
    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        color: Colors.black87,
        style: IconButton.styleFrom(
          backgroundColor: const Color(0xFFF0F4F0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }

  // Üst özet istatistik kartları tasarımı
  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.1),
            radius: 20,
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}