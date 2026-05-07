// lib/shared/widgets/status_badge.dart
//
// Ce widget affiche un petit badge coloré selon le statut.
// On l'utilise partout dans l'app : dans les listes d'admins, de tickets, etc.
//
// Utilisation :
//   StatusBadge(status: AdminStatus.active)   → badge vert "Actif"
//   StatusBadge(status: AdminStatus.pending)  → badge orange "Attente"
//   StatusBadge(status: AdminStatus.suspended)→ badge rouge "Suspendu"

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

enum AdminStatus { active, pending, suspended }

class StatusBadge extends StatelessWidget {
  final AdminStatus status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    // On choisit les couleurs et le texte selon le statut
    final Color bgColor;
    final Color textColor;
    final String label;

    switch (status) {
      case AdminStatus.active:
        bgColor = AppColors.statusActiveBackground;
        textColor = AppColors.statusActive;
        label = 'Actif';
        break;
      case AdminStatus.pending:
        bgColor = AppColors.statusPendingBackground;
        textColor = AppColors.statusPending;
        label = 'Attente';
        break;
      case AdminStatus.suspended:
        bgColor = AppColors.statusSuspendedBackground;
        textColor = AppColors.statusSuspended;
        label = 'Suspendu';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20), // pill shape
      ),
      child: Text(
        label,
        style: AppTextStyles.badgeText.copyWith(color: textColor),
      ),
    );
  }
}