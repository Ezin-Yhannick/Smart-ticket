// lib/shared/widgets/stat_card.dart
//
// La carte de statistique qu'on voit sur le tableau de bord :
// icône colorée + grand chiffre + label + petit badge "+X ce mois"
//
// Utilisation :
//   StatCard(
//     icon: Icons.people_outline,
//     iconColor: AppColors.iconBlue,
//     iconBackground: AppColors.iconBlueBackground,
//     value: '24',
//     label: 'Admins actifs',
//     trend: '+3 ce mois',
//     trendColor: AppColors.statusActive,
//   )

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String value;
  final String label;
  final String? trend;       // texte du badge en bas, ex: "+3 ce mois"
  final Color? trendColor;   // couleur du badge

  const StatCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.value,
    required this.label,
    this.trend,
    this.trendColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icône dans son carré coloré
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),

          const SizedBox(height: 12),

          // Grand chiffre
          Text(value, style: AppTextStyles.statNumber),

          const SizedBox(height: 2),

          // Label sous le chiffre
          Text(label, style: AppTextStyles.statLabel),

          // Badge de tendance (optionnel)
          if (trend != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: (trendColor ?? AppColors.statusActive).withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                trend!,
                style: AppTextStyles.chipLabel.copyWith(
                  color: trendColor ?? AppColors.statusActive,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}