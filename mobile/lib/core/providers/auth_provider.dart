// lib/core/providers/auth_provider.dart
//
// Ce fichier gère l'état de connexion de l'utilisateur.
//
// Qu'est-ce qu'un "provider" Riverpod ?
// C'est une boîte qui contient des données et les met à jour automatiquement
// dans toute l'application quand elles changent.
//
// Ici, AuthState contient : est-ce que l'user est connecté ? quel est son rôle ?
// Quand l'user se connecte ou se déconnecte, tous les widgets qui écoutent
// ce provider se mettent à jour automatiquement.

import 'package:flutter_riverpod/flutter_riverpod.dart';

// --- Les rôles disponibles dans l'application ---
enum UserRole {
  superAdmin, // Gestionnaire de la plateforme entière
  admin,      // Organisateur d'événements
  agent,      // Agent de contrôle (scan QR à l'entrée)
  none,       // Non connecté
}

// --- L'état d'authentification ---
// C'est un objet qui contient toutes les infos sur l'utilisateur connecté
class AuthState {
  final bool isLoggedIn;
  final UserRole role;
  final String? token;        // Le JWT reçu du backend
  final String? userId;
  final String? userName;
  final String? userEmail;
  final String? userPhone;

  const AuthState({
    this.isLoggedIn = false,
    this.role = UserRole.none,
    this.token,
    this.userId,
    this.userName,
    this.userEmail,
    this.userPhone,
  });

  // copyWith permet de créer une copie avec certains champs modifiés
  // Ex: state.copyWith(isLoggedIn: true) crée un nouvel état avec isLoggedIn = true
  // mais garde tous les autres champs identiques
  AuthState copyWith({
    bool? isLoggedIn,
    UserRole? role,
    String? token,
    String? userId,
    String? userName,
    String? userEmail,
    String? userPhone,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      role: role ?? this.role,
      token: token ?? this.token,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      userPhone: userPhone ?? this.userPhone,
    );
  }
}

// --- Le Notifier : c'est lui qui gère les changements d'état ---
// StateNotifier est la classe Riverpod qui contient la logique
class AuthNotifier extends StateNotifier<AuthState> {
  // On commence avec un état "déconnecté"
  AuthNotifier() : super(const AuthState());

  // Appelée quand l'utilisateur se connecte avec succès
  // On reçoit le token et les infos du backend
  void login({
    required String token,
    required UserRole role,
    required String userId,
    required String userName,
    required String userEmail,
    required String userPhone,
  }) {
    state = state.copyWith(
      isLoggedIn: true,
      token: token,
      role: role,
      userId: userId,
      userName: userName,
      userEmail: userEmail,
      userPhone: userPhone,
    );
  }

  // Appelée quand l'utilisateur se déconnecte
  void logout() {
    // On remet l'état à zéro (comme au démarrage)
    state = const AuthState();
  }

  // Utilitaire pour convertir la chaîne de rôle reçue du backend en enum
  // Ex: "SUPER_ADMIN" → UserRole.superAdmin
  static UserRole roleFromString(String roleString) {
    switch (roleString.toUpperCase()) {
      case 'SUPER_ADMIN':
        return UserRole.superAdmin;
      case 'ADMIN':
        return UserRole.admin;
      case 'AGENT':
        return UserRole.agent;
      default:
        return UserRole.none;
    }
  }
}

// --- Le Provider exposé à toute l'application ---
// StateNotifierProvider crée le lien entre AuthNotifier et le reste de l'app
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});