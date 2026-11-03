import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get currentUserId => _auth.currentUser?.uid ?? "";

  // Yeni sipariş oluştur
  Future<void> placeOrder(List<dynamic> cartItems, double totalAmount) async {
    if (currentUserId.isEmpty) return;

    await _firestore.collection('users').doc(currentUserId).collection('orders').add({
      'orderNumber': '#${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      'date': DateTime.now(),
      'total': totalAmount,
      'status': 'Delivered', // düzenlendi
      'items': cartItems, // Sepetteki ürün detayları
    });
  }

  // Siparişleri anlık dinle
  Stream<QuerySnapshot> getOrders() {
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('orders')
        .orderBy('date', descending: true)
        .snapshots();
  }
}