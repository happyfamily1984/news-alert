import 'package:flutter/material.dart';

import '../theme.dart';

/// v3 화면 배경: 라이트는 위아래 그라데이션 + 옅은 파란 장식 원,
/// 다크는 단색. 각 화면의 Scaffold 뒤(Stack 맨 아래)에 깐다.
/// Scaffold와 AppBar는 투명이어야 배경이 비친다.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    if (brightness == Brightness.dark) {
      return Container(color: AppColors.backgroundDark);
    }
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: AppColors.backgroundGradientLight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -70,
            right: -50,
            child: Container(
              width: 220,
              height: 220,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.backgroundBlobLight,
              ),
            ),
          ),
          Positioned(
            bottom: 140,
            left: -80,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.backgroundBlobLight.withOpacity(0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
