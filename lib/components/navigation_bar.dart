import 'package:flutter/material.dart';

class AppNavigationBar extends StatelessWidget {
  const AppNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.height = 60,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: height,
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: Row(
          children: [
            _NavItem(
              icon: Icons.add,
              isSelected: currentIndex == 0,
              onTap: () => onTap(0),
            ),
            const _Divider(),
            _NavItem(
              icon: Icons.home,
              isSelected: currentIndex == 1,
              onTap: () => onTap(1),
            ),
            const _Divider(),
            _NavItem(
              icon: Icons.person,
              isSelected: currentIndex == 2,
              onTap: () => onTap(2),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color iconColor = isSelected ? Colors.black : Colors.grey;

    return Expanded(
      child: InkResponse(
        onTap: onTap,
        radius: 28,
        child: Center(
          child: Icon(
            icon,
            color: iconColor,
            size: 28,
          ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 26,
      color: Colors.grey.shade300,
    );
  }
}
