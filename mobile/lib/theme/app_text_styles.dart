// lib/theme/app_text_styles.dart
//
// Ce fichier centralise tous les styles de texte.
// Au lieu d'écrire TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: ...)
// partout dans le code, tu écris juste : AppTextStyles.heading1
//
// C'est plus rapide, plus cohérent, et plus facile à modifier.

import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // --- Grands titres ---
  // Utilisé pour : le titre "Smart-Ticket" dans la top bar
  static const TextStyle appBarTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
  );

  // --- Titres de section ---
  // Utilisé pour : "Vue d'ensemble", "Admins récents"
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
  );

  // --- Grands chiffres dans les cartes de stats ---
  // Utilisé pour : "24", "138", "4,2M"
  static const TextStyle statNumber = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  // --- Labels sous les chiffres ---
  // Utilisé pour : "Admins actifs", "Événements"
  static const TextStyle statLabel = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  // --- Nom d'un admin dans la liste ---
  // Utilisé pour : "ASSOUMA Kamal"
  static const TextStyle adminName = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.1,
  );

  // --- Email ou sous-titre d'un admin ---
  // Utilisé pour : "k.assouma@epac.bj", "12 événements · 1,2M FCFA"
  static const TextStyle adminSubtitle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  // --- Texte dans les badges de statut ---
  // Utilisé pour : "Actif", "Attente", "Suspendu"
  static const TextStyle badgeText = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );

  // --- Petit texte indicateur ---
  // Utilisé pour : "+3 ce mois", "Cette sem."
  static const TextStyle chipLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
  );

  // --- Labels de navigation (bottom nav) ---
  // Utilisé pour : "Tableau de bord", "Admins"
  static const TextStyle navLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
  );

  // --- Texte des boutons ---
  static const TextStyle buttonText = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );

  // --- Titre des écrans (dans le corps de la page) ---
  static const TextStyle screenTitle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.4,
  );

  // --- Texte informatif discret ---
  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.textTertiary,
  );
}
