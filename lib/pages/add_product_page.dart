import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart'; // Galeriye erişim için import
import 'package:http/http.dart' as http; // Ücretsiz resim yükleme servisi için import
import '../widgets/common_app_bar.dart';
import '../widgets/custom_refresh_indicator.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();

  // Form Kontrolcüleri
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String _selectedCategory = 'Fruits';
  String _selectedUnit = 'kg';
  bool _isSaving = false;

  File? _pickedImage; // Galeriden seçilen resmi geçici tutacak dosya nesnesi
  final ImagePicker _picker = ImagePicker();

  final Color freshGreen = const Color(0xFF4CAF50);

  final List<String> _categories = ['Fruits', 'Vegetables', 'Dairy'];
  final List<String> _units = ['kg', 'Litre', 'Pack', 'Piece'];

  //  API Key
  final String _imgBbApiKey = "07b768f1bde96561ddc08ea64729c3a9";

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Galeriden resim seçmeyi sağlayan asenkron fonksiyon
  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70, // Boyutu küçültüp yükleme hızını tavan yaptırıyoruz
      );
      if (image != null) {
        setState(() {
          _pickedImage = File(image.path);
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  // Seçilen resmi ImgBB bulutuna yükleyen fonksiyon
  Future<String> _uploadImageToImgBb() async {
    if (_pickedImage == null) {
      switch (_selectedCategory) {
        case 'Fruits': return 'assets/images/fruits.jpg';
        case 'Vegetables': return 'assets/images/vegetables1.jpg';
        case 'Dairy': return 'assets/images/dairy.jpg';
        default: return 'assets/images/fruits.jpg';
      }
    }

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.imgbb.com/1/upload?key=$_imgBbApiKey'),
      );

      var multipartFile = await http.MultipartFile.fromPath('image', _pickedImage!.path);
      request.files.add(multipartFile);

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        String directUrl = responseData['data']['url'];
        return directUrl;
      } else {
        throw Exception("ImgBB upload failed with status: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Cloud image upload failed: $e");
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      String producerName = "Organic Farm";
      if (userDoc.exists) {
        producerName = userDoc.get('fullName') ?? "Organic Farm";
      }

      String finalImageUrl = await _uploadImageToImgBb();

      Map<String, dynamic> newProduct = {
        'name': _nameController.text.trim(),
        'price': double.parse(_priceController.text.trim()),
        'stock': int.parse(_stockController.text.trim()),
        'unit': _selectedUnit,
        'category': _selectedCategory,
        'producer': producerName,
        'producerId': currentUser.uid,
        'description': _descriptionController.text.trim(),
        'rating': 0.0,
        'reviewCount': 0,
        'imageUrl': finalImageUrl,
        'tags': ['fresh_farm'],
      };

      await FirebaseFirestore.instance.collection('products').add(newProduct);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Product successfully added to your inventory!"),
            backgroundColor: freshGreen,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to add product: $e"), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // düzeltildi
      appBar: const CommonAppBar(title: "Add New Product", showBackButton: true),
      body: _isSaving
          ? Center(child: CircularProgressIndicator(color: freshGreen))
          : CustomRefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(seconds: 1));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Product Image", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                const SizedBox(height: 10),

                // Düzeltildi
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: _pickImageFromGallery,
                    child: Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F4F0),
                        borderRadius: BorderRadius.circular(20),
                        // .withAlpha uyarısını engellemek için withValues standardına çekildi
                        border: Border.all(color: freshGreen.withValues(alpha: 0.3), width: 2),
                      ),
                      child: _pickedImage != null
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.file(_pickedImage!, fit: BoxFit.cover),
                      )
                          : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined, size: 40, color: freshGreen),
                          const SizedBox(height: 6),
                          const Text(
                            "Select Photo",
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                _buildTextField(
                  controller: _nameController,
                  label: "Product Name",
                  hint: "e.g., Organic Avocado",
                  icon: Icons.shopping_basket_outlined,
                  validator: (v) => v!.isEmpty ? "Please enter product name" : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _priceController,
                        label: "Price (\$)",
                        hint: "e.g., 4.50",
                        icon: Icons.attach_money_rounded,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) => v!.isEmpty ? "Enter price" : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        controller: _stockController,
                        label: "Stock Quantity",
                        hint: "e.g., 50",
                        icon: Icons.inventory_2_outlined,
                        keyboardType: TextInputType.number,
                        validator: (v) => v!.isEmpty ? "Enter stock" : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdownField(
                        label: "Category",
                        value: _selectedCategory,
                        items: _categories,
                        onChanged: (v) => setState(() => _selectedCategory = v!),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDropdownField(
                        label: "Unit",
                        value: _selectedUnit,
                        items: _units,
                        onChanged: (v) => setState(() => _selectedUnit = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _descriptionController,
                  label: "Description",
                  hint: "Tell customers about your fresh and organic product...",
                  icon: Icons.description_outlined,
                  maxLines: 4,
                  validator: (v) => v!.isEmpty ? "Please enter description" : null,
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _saveProduct,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: freshGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 0,
                    ),
                    child: const Text("List Product", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          cursorColor: freshGreen,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
            prefixIcon: Icon(icon, color: freshGreen),
            filled: true,
            fillColor: const Color(0xFFF0F4F0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F4F0),
            borderRadius: BorderRadius.circular(15),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: Icon(Icons.arrow_drop_down, color: freshGreen),
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item, style: const TextStyle(fontWeight: FontWeight.w500)),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}