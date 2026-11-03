import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Oturumun açık kalması için
  // await FirebaseAuth.instance.signOut();

  runApp(const GreenBasket());
}

class GreenBasket extends StatelessWidget {
  const GreenBasket({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GreenBasket',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      // OTURUM KONTROLÜ VE ANA SAYFA YÖNLENDİRMESİ
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Firebase'den veri gelene kadar bekleme ekranı
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator(color: Colors.green)),
            );
          }

          // Eğer giriş yapılmış bir kullanıcı varsa direkt HomePage'e gönder
          if (snapshot.hasData) {
            return const HomePage();
          }

          // Giriş yapılmamışsa Login ekranına gönder
          return const LoginPage();
        },
      ),
    );
  }
}