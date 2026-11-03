import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddressService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get currentUserId => _auth.currentUser?.uid ?? "";

  // Adresleri anlık dinle (Stream)
  Stream<QuerySnapshot> getAddresses() {
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('addresses')
        .orderBy('createdAt', descending: true) // Yeni eklenenler en üstte görünsün
        .snapshots();
  }

  // Yeni adres ekle
  Future<void> addAddress(String title, String detail) async {
    if (currentUserId.isEmpty) return;
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('addresses')
        .add({
      'title': title,
      'detail': detail,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  //  Mevcut adresi güncelle
  Future<void> updateAddress(String addressId, String title, String detail) async {
    if (currentUserId.isEmpty) return;
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('addresses')
        .doc(addressId)
        .update({
      'title': title,
      'detail': detail,
      // 'updatedAt': FieldValue.serverTimestamp(), // İstersen güncelleme tarihini de tutabilirsin
    });
  }

  // Adres sil
  Future<void> deleteAddress(String addressId) async {
    if (currentUserId.isEmpty) return;
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('addresses')
        .doc(addressId)
        .delete();
  }
}