import 'package:flutter/material.dart';

import '../theme.dart';

/// v3 파란 그라데이션 버튼 (가로 전체 폭, 높이 60dp).
/// onPressed가 null이면 회색으로 비활성화 표시한다.
class GradientButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final IconData? trailingIcon;
  final VoidCallback? onPressed;
  final double height;

  const GradientButton({
    super.key,
    required this.label,
    this.icon,
    this.trailingIcon,
    required this.onPressed,
    this.height = AppSizes.buttonHeight,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final enabled = onPressed != null;
    final gradient =
        enabled
            ? AppColors.buttonGradientLight
            : const [Color(0xFFCBD5E1), Color(0xFF94A3B8)];
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: gradient),
            borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
            boxShadow:
                enabled
                    ? [
                      BoxShadow(
                        color: const Color(0xFF246BCE).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ]
                    : null,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
            onTap: onPressed,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: Colors.white, size: 20),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    label,
                    style: AppTextStyles.button(brightness),
                  ),
                  if (trailingIcon != null) ...[
                    const SizedBox(width: 6),
                    Icon(trailingIcon, color: Colors.white, size: 20),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// v3 외곽선 버튼 (흰 배경, 파란 테두리·글자). '지금 확인'에 쓴다.
class OutlineButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final double height;

  const OutlineButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.height = AppSizes.buttonHeight,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final enabled = onPressed != null;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon:
            icon != null
                ? Icon(icon, size: 20, color: AppColors.primary(brightness))
                : null,
        label: Text(
          label,
          style: AppTextStyles.button(brightness).copyWith(
            color:
                enabled
                    ? AppColors.primary(brightness)
                    : AppColors.textSecondary(brightness),
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.surface(brightness),
          side: BorderSide(
            color:
                enabled
                    ? AppColors.primary(brightness)
                    : AppColors.border(brightness),
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
          ),
        ),
      ),
    );
  }
}
