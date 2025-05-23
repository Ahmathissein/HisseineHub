import 'package:flutter/material.dart';
import 'navbar.dart';

class AppLayout extends StatelessWidget {
  final Widget child;
  final String? selectedItemLabel;

  const AppLayout({
    super.key,
    required this.child,
    this.selectedItemLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 1300;

    return Scaffold(
      backgroundColor: const Color(0xFFf1f0fb),
      body: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                const CustomAppBar(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: child,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}
