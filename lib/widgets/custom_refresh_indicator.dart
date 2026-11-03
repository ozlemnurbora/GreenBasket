import 'package:flutter/material.dart';

class CustomRefreshIndicator extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;

  const CustomRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: Colors.green, // Uygulama rengimiz
      backgroundColor: Colors.white,
      onRefresh: onRefresh,
      child: child,
    );
  }
}