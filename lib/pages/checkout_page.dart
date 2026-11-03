import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/address_service.dart';
import '../services/cart_service.dart';
import '../models/cart_model.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/custom_refresh_indicator.dart';
import 'order_success_page.dart';
import 'addresses_page.dart';

class CheckoutPage extends StatefulWidget {
  final double totalAmount;

  const CheckoutPage({super.key, required this.totalAmount});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();

  final Color freshGreen = const Color(0xFF4CAF50);
  final AddressService _addressService = AddressService();
  final CartService _cartService = CartService();

  String? _selectedAddressId;
  bool _isProcessing = false;

  Future<void> _processOrderAndDeductStock() async {
    setState(() => _isProcessing = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception("User not logged in");

      List<CartItem> items = await _cartService.getCartItems().first;
      if (items.isEmpty) throw Exception("Cart is empty");

      WriteBatch batch = FirebaseFirestore.instance.batch();

      for (var item in items) {
        DocumentReference productRef = FirebaseFirestore.instance.collection('products').doc(item.productId);

        DocumentSnapshot prodSnap = await productRef.get();
        if (prodSnap.exists) {
          final prodData = prodSnap.data() as Map<String, dynamic>;

          int currentStock = 0;
          if (prodData.containsKey('stock') && prodData['stock'] != null) {
            currentStock = (prodData['stock'] as num).toInt();
          }

          int newStock = currentStock - item.quantity;
          if (newStock < 0) newStock = 0;

          batch.update(productRef, {'stock': newStock});
        }

        DocumentReference orderRef = FirebaseFirestore.instance.collection('orders').doc();

        final prodData = prodSnap.exists ? prodSnap.data() as Map<String, dynamic> : null;

        String finalProducerId = '';
        if (item.producerId.isNotEmpty) {
          finalProducerId = item.producerId;
        } else if (prodData != null && prodData.containsKey('producerId') && prodData['producerId'] != null) {
          finalProducerId = prodData['producerId'].toString();
        }

        batch.set(orderRef, {
          'buyerId': uid,
          'productId': item.productId,
          'productName': item.name,
          'quantity': item.quantity,
          'unit': item.unit,
          'price': item.price,
          'totalPrice': item.price * item.quantity,
          'imageUrl': item.imageUrl,
          'producerId': finalProducerId,
          'addressId': _selectedAddressId,
          'orderDate': FieldValue.serverTimestamp(),
          'status': 'Pending',
        });
      }

      await batch.commit();
      await _cartService.clearCart();

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const OrderSuccessPage()),
            (route) => false,
      );

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Order processing failed: $e"), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const double deliveryFee = 2.00;
    final double finalTotal = widget.totalAmount + deliveryFee;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CommonAppBar(title: "Checkout", showBackButton: true),
      body: _isProcessing
          ? Center(child: CircularProgressIndicator(color: freshGreen))
          : CustomRefreshIndicator(
        onRefresh: () async => await Future.delayed(const Duration(seconds: 1)),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Select Delivery Address", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),

                SizedBox(
                  height: 110,
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _addressService.getAddresses(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) return const Text("Error loading addresses");
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final docs = snapshot.data?.docs ?? [];

                      if (docs.isEmpty) {
                        return Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("No addresses found.", style: TextStyle(color: Colors.grey)),
                              TextButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const AddressesPage()),
                                  );
                                },
                                icon: Icon(Icons.add_location_alt, color: freshGreen, size: 20),
                                label: Text("Add New Address", style: TextStyle(color: freshGreen, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        );
                      }

                      _selectedAddressId ??= docs.first.id;

                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final address = docs[index].data() as Map<String, dynamic>;
                          final String docId = docs[index].id;
                          final bool isSelected = _selectedAddressId == docId;

                          return GestureDetector(
                            onTap: () => setState(() => _selectedAddressId = docId),
                            child: Container(
                              width: 220,
                              margin: const EdgeInsets.only(right: 12, bottom: 5),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected ? freshGreen.withValues(alpha: 0.05) : Colors.grey[50],
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: isSelected ? freshGreen : Colors.grey.shade300,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.location_on, color: isSelected ? freshGreen : Colors.grey, size: 18),
                                      const SizedBox(width: 5),
                                      Text(address['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    address['detail'],
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

                const Divider(height: 40),

                const Text("Payment Method", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),

                _buildModernTextField(
                  controller: _cardNumberController,
                  label: "Card Number",
                  hint: "0000 0000 0000 0000",
                  icon: Icons.credit_card,
                  keyboardType: TextInputType.number,
                  maxLength: 16, // Fazla basımı engeller
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) => (value == null || value.length < 16) ? "Enter 16 digits" : null,
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildModernTextField(
                        controller: _expiryController,
                        label: "Expiry Date",
                        hint: "MM/YY",
                        keyboardType: TextInputType.number, // 🎯 Samsung klavye uyumu için number yapıldı
                        maxLength: 5, // MM/YY toplam 5 karakter
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          CardExpirationFormatter(), // 🚀 Otomatik '/' koyan sihirli formatter
                        ],
                        validator: (value) => (value == null || value.length < 5 || !value.contains("/")) ? "Invalid" : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildModernTextField(
                        controller: _cvvController,
                        label: "CVV",
                        hint: "000",
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        maxLength: 3,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (value) => (value == null || value.length < 3) ? "Required" : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                const Text("Order Summary", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                _buildPriceRow("Subtotal", "\$${widget.totalAmount.toStringAsFixed(2)}"),
                _buildPriceRow("Delivery", "\$${deliveryFee.toStringAsFixed(2)}"),
                const Divider(height: 30),
                _buildPriceRow("Total", "\$${finalTotal.toStringAsFixed(2)}", isTotal: true),

                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_selectedAddressId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Please add and select a delivery address first!"),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                        return;
                      }
                      if (_formKey.currentState!.validate()) {
                        _processOrderAndDeductStock();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: freshGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      elevation: 0,
                    ),
                    child: const Text("Pay & Complete Order", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  //  maxLength ve inputFormatters eklendi
  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    IconData? icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        counterText: "", // Alttaki o çirkin karakter sayacını gizler
        prefixIcon: icon != null ? Icon(icon, color: freshGreen) : null,
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: freshGreen, width: 2),
        ),
        errorStyle: const TextStyle(color: Colors.redAccent),
      ),
    );
  }

  Widget _buildPriceRow(String label, String price, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: isTotal ? 18 : 16, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
          Text(price, style: TextStyle(fontSize: isTotal ? 22 : 16, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, color: isTotal ? freshGreen : Colors.black87)),
        ],
      ),
    );
  }
}

// KREDİ KARTI TARİHİNE OTOMATİK '/' KOYAN FORMATTER
class CardExpirationFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final String newText = newValue.text;

    if (newValue.selection.baseOffset < oldValue.selection.baseOffset) {
      return newValue;
    }

    var buffer = StringBuffer();
    for (int i = 0; i < newText.length; i++) {
      buffer.write(newText[i]);
      var nonZeroIndex = i + 1;

      if (nonZeroIndex == 2 && nonZeroIndex != newText.length) {
        buffer.write('/');
      }
    }

    var string = buffer.toString();
    return newValue.copyWith(
        text: string,
        selection: TextSelection.collapsed(offset: string.length));
  }
}