import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/cart_model.dart';
import '../models/product_model.dart';

class CartService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get currentUserId => _auth.currentUser?.uid ?? "";

  // Sepeti anlık dinle (Fiyat hesaplaması için lazım)
  Stream<List<CartItem>> getCartItems() {
    if (currentUserId.isEmpty) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('cart')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => CartItem.fromFirestore(doc.data(), doc.id))
        .toList());
  }

  // Sepete ürün ekle veya adedini artır
  Future<void> addToCart(Product product, int quantity) async {
    if (currentUserId.isEmpty) return;

    final cartDoc = _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('cart')
        .doc(product.id);

    final docSnapshot = await cartDoc.get();

    if (docSnapshot.exists) {
      // Ürün zaten varsa adedini artır
      await cartDoc.update({
        'quantity': FieldValue.increment(quantity),
      });
    } else {
      // Ürün sepet dökümanı ilk kez oluşturulurken producerId alanı da kaydediliyor ---
      await cartDoc.set({
        'name': product.name,
        'imageUrl': product.imageUrl,
        'price': product.price,
        'quantity': quantity,
        'unit': product.unit,
        'producerId': product.producerId, // Sipariş takibi için burası şart!
      });
    }
  }

  // Sepetteki ürünün adedini doğrudan güncelle (Artırma/Azaltma butonları için)
  Future<void> updateQuantity(String productId, int newQuantity) async {
    if (currentUserId.isEmpty) return;

    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('cart')
        .doc(productId)
        .update({'quantity': newQuantity});
  }

  // Ürünü sepetten tamamen sil
  Future<void> removeFromCart(String productId) async {
    if (currentUserId.isEmpty) return;

    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('cart')
        .doc(productId)
        .delete();
  }

  // Sipariş sonrası sepeti topluca boşaltıyor
  Future<void> clearCart() async {
    if (currentUserId.isEmpty) return;

    try {
      final cartDocs = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('cart')
          .get();

      WriteBatch batch = _firestore.batch();
      for (var doc in cartDocs.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      debugPrint("Cart cleared successfully after order completion!");
    } catch (e) {
      debugPrint("Error clearing cart: $e");
      rethrow;
    }
  }
}