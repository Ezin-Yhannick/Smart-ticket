// lib/theme/app_colors.dart
//
// Ce fichier contient TOUTES les couleurs de l'application.
// Avantage : si tu veux changer une couleur, tu le fais ici une seule fois
// et ça se met à jour partout dans l'app.

import 'package:flutter/material.dart';

class AppColors {
  // Constructeur privé : cette classe ne peut pas être instanciée
  // On l'utilise comme : AppColors.background (pas new AppColors())
  AppColors._();

  // --- Couleurs de fond (arrière-plan) ---
  // C'est le fond très sombre qu'on voit sur tes maquettes
  static const Color background = Color(0xFF0F0F0F);

  // Fond des cartes (un peu plus clair que le background)
  static const Color surface = Color(0xFF1A1A1A);

  // Fond des éléments interactifs (boutons secondaires, champs de texte)
  static const Color surfaceVariant = Color(0xFF252525);

  // --- Couleur principale (bleu comme dans tes maquettes) ---
  static const Color primary = Color(0xFF3B82F6);       // bleu principal
  static const Color primaryDark = Color(0xFF2563EB);   // bleu foncé (bouton pressé)
  static const Color primaryLight = Color(0xFF60A5FA);  // bleu clair (texte sur fond sombre)

  // --- Couleurs de statut ---
  // Ces couleurs correspondent aux badges de statut dans tes maquettes
  static const Color statusActive = Color(0xFF22C55E);      // vert  → "Actif"
  static const Color statusActiveBackground = Color(0xFF14532D); // fond vert foncé
  static const Color statusPending = Color(0xFFF59E0B);     // orange → "Attente"
  static const Color statusPendingBackground = Color(0xFF451A03); // fond orange foncé
  static const Color statusSuspended = Color(0xFFEF4444);   // rouge → "Suspendu"
  static const Color statusSuspendedBackground = Color(0xFF450A0A); // fond rouge foncé

  // --- Couleurs de texte ---
  static const Color textPrimary = Color(0xFFFFFFFF);       // blanc → titres, noms
  static const Color textSecondary = Color(0xFF9CA3AF);     // gris clair → sous-titres, emails
  static const Color textTertiary = Color(0xFF6B7280);      // gris → texte discret

  // --- Couleurs des icônes de stats (les petites icônes carrées) ---
  static const Color iconBlueBackground = Color(0xFF1E3A5F);   // fond bleu
  static const Color iconBlue = Color(0xFF60A5FA);             // icône bleue
  static const Color iconGreenBackground = Color(0xFF14532D);  // fond vert
  static const Color iconGreen = Color(0xFF4ADE80);            // icône verte
  static const Color iconOrangeBackground = Color(0xFF451A03); // fond orange
  static const Color iconOrange = Color(0xFFFB923C);           // icône orange
  static const Color iconRedBackground = Color(0xFF450A0A);    // fond rouge
  static const Color iconRed = Color(0xFFF87171);              // icône rouge

  // --- Bordures et séparateurs ---
  static const Color border = Color(0xFF2D2D2D);  // ligne fine entre les éléments
  static const Color divider = Color(0xFF1F1F1F); // séparateur encore plus discret

  // --- Couleurs des boutons d'action ---
  static const Color buttonPrimary = Color(0xFF3B82F6);    // "Voir détail" → bleu
  static const Color buttonNeutral = Color(0xFF374151);    // "Modifier" → gris
  static const Color buttonSuccess = Color(0xFF16A34A);    // "Valider" → vert
  static const Color buttonDanger = Color(0xFF991B1B);     // "Suspendre/Rejeter" → rouge

  // --- Couleur de la bottom navigation bar ---
  static const Color navBarBackground = Color(0xFF111111);
  static const Color navBarSelected = Color(0xFF3B82F6);   // icône sélectionnée → bleu
  static const Color navBarUnselected = Color(0xFF6B7280); // icône non sélectionnée → gris

  // --- Couleurs des avatars (les cercles avec les initiales) ---
  // Flutter va choisir automatiquement une couleur selon l'index
  static const List<Color> avatarColors = [
    Color(0xFF7C3AED), // violet  → ex: "KA"
    Color(0xFF0891B2), // cyan    → ex: "SJ"
    Color(0xFFD97706), // ambre   → ex: "ME"
    Color(0xFF059669), // vert    → ex: "AB"
    Color(0xFFDC2626), // rouge   → ex: "TC"
  ];
}