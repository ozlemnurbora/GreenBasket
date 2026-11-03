import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoriteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Şu anki kullanıcının ID'sini alıyoruz
  String get currentUserId => _auth.currentUser?.uid ?? "";

  // Favori durumunu değiştir (Varsa sil, yoksa ekle)
  Future<void> toggleFavorite(String productId) async {
    if (currentUserId.isEmpty) return;

    final favoriteDoc = _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('favorites')
        .doc(productId);

    final docSnapshot = await favoriteDoc.get();

    if (docSnapshot.exists) {
      // Zaten favorideyse sil
      await favoriteDoc.delete();
    } else {
      // Favoride değilse ekle
      await favoriteDoc.set({
        'productId': productId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  // Bir ürünün favori olup olmadığını anlık dinle (Kalp dolu mu boş mu?)
  Stream<bool> isFavorite(String productId) {
    if (currentUserId.isEmpty) return Stream.value(false);

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('favorites')
        .doc(productId)
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }

  // YENİ EKLENDİ
  // Favori sayfasında kullanıcının tüm favori ürün ID'lerini liste olarak getirir
  Stream<List<String>> getFavorites() {
    if (currentUserId.isEmpty) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('favorites')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
  }
}