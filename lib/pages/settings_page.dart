import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/custom_refresh_indicator.dart';
import '../widgets/common_app_bar.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _currentName = "User Name";
  String _currentEmail = "Email Address";
  String _userRole = "Consumer";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists && mounted) {
        setState(() {
          _currentName = userDoc.get('fullName') ?? "No Name Provided";
          _currentEmail = userDoc.get('email') ?? user.email ?? "No Email Provided";
          _userRole = userDoc.get('role') ?? "Consumer";
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _reauthenticate(String password) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        appBar: CommonAppBar(title: "Settings", showBackButton: true),
        body: Center(child: CircularProgressIndicator(color: Colors.green)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: const CommonAppBar(title: "Settings", showBackButton: true),
      body: CustomRefreshIndicator(
        onRefresh: _fetchUserData,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            _buildUserCard(),
            _buildSectionTitle("Account Security"),
            _buildSettingsCard([
              _buildSettingsItem(
                icon: Icons.edit_outlined,
                title: "Edit Profile Name",
                subtitle: "Current: $_currentName",
                onTap: _showEditNameDialog,
              ),
              _buildSettingsItem(
                icon: Icons.lock_outline,
                title: "Change Password",
                subtitle: "Security updates",
                onTap: _showChangePasswordDialog,
              ),
            ]),
            _buildSectionTitle("Other"),
            _buildSettingsCard([
              const ListTile(
                enabled: false,
                leading: Icon(Icons.info_outline, color: Colors.black87),
                title: Text("About GreenBasket", style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                subtitle: Text("App version 1.0.0", style: TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.bold)),
              ),
            ]),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 35,
            backgroundColor: Colors.green,
            child: Icon(Icons.person, color: Colors.white, size: 35),
          ),
          const SizedBox(height: 12),
          Text(_currentName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(_currentEmail, style: TextStyle(color: Colors.grey[800], fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildRoleBadge(),
        ],
      ),
    );
  }

  Widget _buildRoleBadge() {
    Color color = _userRole == "Admin" ? Colors.amber[800]! : Colors.green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(_userRole.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(children: children),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 8),
      child: Text(title.toUpperCase(), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.black, letterSpacing: 0.5)),
    );
  }

  Widget _buildSettingsItem({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.green),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      onTap: onTap,
    );
  }

  void _showEditNameDialog() {
    final controller = TextEditingController(text: _currentName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Name"),
        content: SingleChildScrollView(
          child: TextField(controller: controller, decoration: const InputDecoration(labelText: "Full Name")),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () async {
              String newName = controller.text.trim();
              if (newName.isNotEmpty) {
                final navigator = Navigator.of(context);
                final scaffoldMessenger = ScaffoldMessenger.of(context);

                try {
                  User? currentUser = FirebaseAuth.instance.currentUser;
                  if (currentUser != null) {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(currentUser.uid)
                        .update({'fullName': newName});

                    QuerySnapshot producerProducts = await FirebaseFirestore.instance
                        .collection('products')
                        .where('producerId', isEqualTo: currentUser.uid)
                        .get();

                    WriteBatch batch = FirebaseFirestore.instance.batch();
                    for (var doc in producerProducts.docs) {
                      batch.update(doc.reference, {'producer': newName});
                    }
                    await batch.commit();
                  }

                  if (!mounted) return;
                  setState(() => _currentName = newName);
                  navigator.pop();

                  scaffoldMessenger.showSnackBar(
                      const SnackBar(
                          content: Text("Profile Name updated successfully!"),
                          backgroundColor: Colors.green
                      )
                  );
                } catch (e) {
                  scaffoldMessenger.showSnackBar(SnackBar(content: Text("Update failed: $e"), backgroundColor: Colors.redAccent));
                }
              }
            },
            child: const Text("Save", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPw = TextEditingController();
    final newPw = TextEditingController();
    final confirmPw = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          String? dialogError;
          return AlertDialog(
            title: const Text("Change Password"),
            // düzenlendi
            content: SingleChildScrollView(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: currentPw, obscureText: true, decoration: const InputDecoration(labelText: "Current Password")),
                  TextField(controller: newPw, obscureText: true, decoration: const InputDecoration(labelText: "New Password")),
                  Builder(
                    builder: (context) => TextField(
                        controller: confirmPw,
                        obscureText: true,
                        decoration: InputDecoration(
                            labelText: "Confirm New Password",
                            errorText: dialogError
                        )
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  final scaffoldMessenger = ScaffoldMessenger.of(context);

                  if (newPw.text != confirmPw.text) {
                    scaffoldMessenger.showSnackBar(const SnackBar(content: Text("Failed: Passwords do not match!"), backgroundColor: Colors.red));
                    setDialogState(() => dialogError = "Passwords do not match!");
                    return;
                  }

                  try {
                    await _reauthenticate(currentPw.text);
                    await FirebaseAuth.instance.currentUser!.updatePassword(newPw.text);
                    if (!mounted) return;
                    navigator.pop();
                    scaffoldMessenger.showSnackBar(const SnackBar(content: Text("Password updated successfully!"), backgroundColor: Colors.green));
                  } catch (e) {
                    scaffoldMessenger.showSnackBar(const SnackBar(content: Text("Failed: Current password incorrect!"), backgroundColor: Colors.red));
                    setDialogState(() => dialogError = "Current password incorrect!");
                  }
                },
                child: const Text("Update", style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }
}