import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/address_service.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/custom_refresh_indicator.dart';

class AddressesPage extends StatelessWidget {
  const AddressesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final AddressService addressService = AddressService();
    const Color freshGreen = Color(0xFF4CAF50);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBF8),
      appBar: const CommonAppBar(title: "My Addresses"),
      body: StreamBuilder<QuerySnapshot>(
        stream: addressService.getAddresses(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("An error occurred"));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: freshGreen));
          }

          final docs = snapshot.data?.docs ?? [];

          // Sayfa Tamamen Boşsa
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_off_outlined, size: 100, color: freshGreen.withValues(alpha: 0.2)),
                  const SizedBox(height: 20),
                  const Text("Your address book is empty", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    onPressed: () => _showAddressDialog(context, addressService),
                    icon: const Icon(Icons.add_location_alt, color: Colors.white),
                    label: const Text("Add Your First Address", style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: freshGreen,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                ],
              ),
            );
          }

          // Liste Varsa
          return Column(
            children: [
              Expanded(
                child: CustomRefreshIndicator(
                  onRefresh: () async => await Future.delayed(const Duration(seconds: 1)),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final String docId = docs[index].id;
                      return _buildAddressCard(context, data['title'], data['detail'], docId, addressService);
                    },
                  ),
                ),
              ),
              // --- SAYFANIN SONUNA SABİT GENİŞ BUTON ---
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    onPressed: () => _showAddressDialog(context, addressService),
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text("Add New Address", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: freshGreen,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAddressCard(BuildContext context, String title, String detail, String docId, AddressService service) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFEDF4ED),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: const Icon(Icons.location_on, color: Color(0xFF4CAF50), size: 32),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(detail, style: const TextStyle(color: Colors.black87, fontSize: 14, height: 1.4)),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.blueGrey),
              onPressed: () => _showAddressDialog(context, service, docId: docId, initialTitle: title, initialDetail: detail),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => service.deleteAddress(docId),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddressDialog(BuildContext context, AddressService service, {String? docId, String? initialTitle, String? initialDetail}) {
    final TextEditingController titleController = TextEditingController(text: initialTitle);
    final TextEditingController detailController = TextEditingController(text: initialDetail);
    const Color freshGreen = Color(0xFF4CAF50);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF0F4F0), // Arka planı hafif yeşilimsi yapıp kaba duruşu yumuşattık
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(docId == null ? "Add New Address" : "Update Address", style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                hintText: "Address Title (e.g. Home)",
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: freshGreen, width: 2)),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: detailController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: "Full Address Detail",
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: freshGreen, width: 2)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty && detailController.text.isNotEmpty) {
                if (docId == null) {
                  await service.addAddress(titleController.text, detailController.text);
                } else {
                  await service.updateAddress(docId, titleController.text, detailController.text);
                }
                if (context.mounted) Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: freshGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(docId == null ? "Save" : "Update", style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}