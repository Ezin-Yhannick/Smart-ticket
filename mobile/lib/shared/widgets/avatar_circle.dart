// lib/shared/widgets/avatar_circle.dart
//
// Affiche un cercle coloré avec les initiales d'une personne.
// Ex : "ASSOUMA Kamal" → cercle violet avec "KA"
//
// Utilisation :
//   AvatarCircle(name: 'ASSOUMA Kamal')
//   AvatarCircle(name: 'SONON Jehovas-nis', size: 40)

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class AvatarCircle extends StatelessWidget {
  final String name;
  final double size;

  const AvatarCircle({
    super.key,
    required this.name,
    this.size = 44,
  });

  // Extrait les initiales depuis le nom complet
  // "ASSOUMA Kamal" → "AK"
  // "EDOH Maxim"    → "EM"
  String _getInitials(String fullName) {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return fullName.substring(0, 2).toUpperCase();
  }

  // Choisit une couleur en fonction du nom (toujours la même pour le même nom)
  Color _getColor(String name) {
    final index = name.codeUnits.fold(0, (a, b) => a + b) %
        AppColors.avatarColors.length;
    return AppColors.avatarColors[index];
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor(name);
    final initials = _getInitials(name);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.25), // fond semi-transparent
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: size * 0.33,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}