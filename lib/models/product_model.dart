class Product {
  final String? id;
  final String name;
  final double price;
  final int stock;          // YENİ: Mağaza stok yönetimi için eklendi
  final String unit;
  final String category;
  final double rating;
  final int reviewCount;
  final String imageUrl;
  final List<String> tags;
  final String description;
  final String producer;
  final String producerId;  // YENİ: Siparişlerin doğru satıcıya düşmesi için eklendi

  Product({
    this.id,
    required this.name,
    required this.price,
    required this.stock,    // Buraya eklendi
    required this.unit,
    required this.category,
    required this.rating,
    required this.reviewCount,
    required this.imageUrl,
    required this.tags,
    required this.description,
    required this.producer,
    required this.producerId, // Buraya eklendi
  });

  // --- Firestore'dan gelen veriyi modele dönüştüren kısım ---
  factory Product.fromFirestore(Map<String, dynamic> data, String id) {
    return Product(
      id: id,
      name: data['name'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      stock: (data['stock'] ?? 0).toInt(), // Firestore'dan int olarak okuyoruz
      unit: data['unit'] ?? 'kg',
      category: data['category'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviewCount: (data['reviewCount'] ?? 0).toInt(),
      imageUrl: data['imageUrl'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      description: data['description'] ?? 'No description available.',
      producer: data['producer'] ?? 'Unknown Producer',
      producerId: data['producerId'] ?? '', // Firestore'dan string olarak okuyoruz
    );
  }

  // --- Veriyi DB'ye gönderirken (Yazma işlemleri için) ---
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'stock': stock,       // Veritabanına yazılması için eklendi
      'unit': unit,
      'category': category,
      'rating': rating,
      'reviewCount': reviewCount,
      'imageUrl': imageUrl,
      'tags': tags,
      'description': description,
      'producer': producer,
      'producerId': producerId, // Veritabanına yazılması için eklendi
    };
  }
}