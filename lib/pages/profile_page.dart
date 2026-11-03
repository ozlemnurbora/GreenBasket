import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/custom_refresh_indicator.dart';
import 'orders_page.dart';
import 'addresses_page.dart';
import 'login_page.dart';
import 'settings_page.dart';
import 'producer_products_page.dart';
import 'add_product_page.dart';
import 'incoming_orders_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _userName = "Loading...";
  String _userRole = "Consumer";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getUserData();
  }

  Future<void> _getUserData() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (userDoc.exists && mounted) {
          setState(() {
            _userName = userDoc.get('fullName') ?? "No Name";
            _userRole = userDoc.get('role') ?? "Consumer";
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching user data: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.green)));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: null,
      body: CustomRefreshIndicator(
        onRefresh: _getUserData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),

              _buildProfileHeader(_userName, _userRole),

              const SizedBox(height: 20),

              // PRODUCER  ÖZEL ALANI
              if (_userRole == "Producer") ...[
                _buildSectionTitle("Store Management"),
                _buildProfileOption(
                  icon: Icons.inventory_2_outlined,
                  title: "My Products & Inventory",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ProducerProductsPage()),
                    );
                  },
                ),
                _buildProfileOption(
                  icon: Icons.receipt_long_outlined,
                  title: "Incoming Orders",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const IncomingOrdersPage()),
                    );
                  },
                ),
                _buildProfileOption(
                  icon: Icons.add_business_outlined,
                  title: "Add New Product",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AddProductPage()),
                    ).then((value) {
                      if (mounted) _getUserData();
                    });
                  },
                ),
                const Divider(),
              ],

              _buildSectionTitle("Personal"),

              _buildProfileOption(
                icon: Icons.shopping_bag_outlined,
                title: "My Orders",
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const OrdersPage()));
                },
              ),

              // Düzeltildi
              _buildProfileOption(
                icon: Icons.location_on_outlined,
                title: "My Addresses",
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const AddressesPage()));
                },
              ),

              const Divider(),

              _buildProfileOption(
                icon: Icons.logout,
                title: "Logout",
                textColor: Colors.red,
                onTap: () async {
                  final navigator = Navigator.of(context, rootNavigator: true);
                  await FirebaseAuth.instance.signOut();
                  if (!mounted) return;
                  navigator.pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                        (route) => false,
                  );
                },
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(String name, String role) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 40,
            backgroundColor: Colors.green,
            child: Icon(Icons.person, size: 40, color: Colors.white),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    role,
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.black54, size: 26),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              ).then((value) {
                if (mounted) _getUserData();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 10),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600], letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color textColor = Colors.black,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: textColor == Colors.red ? Colors.red.withValues(alpha: 0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: textColor == Colors.red ? Colors.red : Colors.green, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 15),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: onTap,
    );
  }
}