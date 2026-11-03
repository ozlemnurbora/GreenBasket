class CartItem {
  final String productId;
  final String name;
  final String imageUrl;
  final double price;
  final int quantity;
  final String unit;
  final String producerId; // Üretici takibi için eklendi

  CartItem({
    required this.productId,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.quantity,
    required this.unit,
    required this.producerId, // Buraya eklendi
  });

  // Firebase'den gelen veriyi modele çevir
  factory CartItem.fromFirestore(Map<String, dynamic> data, String id) {
    return CartItem(
      productId: id,
      name: data['name'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      quantity: data['quantity'] ?? 1,
      unit: data['unit'] ?? '',
      producerId: data['producerId'] ?? '', // Buraya eklendi
    );
  }

  // Modeli Firebase'e uygun Map yapısına çevir
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'imageUrl': imageUrl,
      'price': price,
      'quantity': quantity,
      'unit': unit,
      'producerId': producerId, // Buraya eklendi
    };
  }
}