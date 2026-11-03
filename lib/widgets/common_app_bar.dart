import 'package:flutter/material.dart';

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;

  const CommonAppBar({
    super.key,
    this.title = "GreenBasket",
    this.showBackButton = true
  });

  @override
  Widget build(BuildContext context) {
    const Color freshGreen = Color(0xFF4CAF50);

    return AppBar(
      backgroundColor: freshGreen,
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: showBackButton, // Geri tuşunu otomatik yönetir
      foregroundColor: Colors.white,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.eco_rounded, color: Colors.white, size: 24),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}