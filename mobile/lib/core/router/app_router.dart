// lib/core/router/app_router.dart
//
// Ce fichier gère toute la navigation de l'application.
// GoRouter analyse le rôle de l'utilisateur connecté et l'envoie
// automatiquement sur la bonne interface.
//
// Comment ça marche ?
// 1. L'utilisateur ouvre l'app → il va sur /splash (écran de chargement)
// 2. /splash vérifie si un token JWT est stocké
//    - Pas de token → /login
//    - Token présent → on lit le rôle → /super-admin, /admin, ou /agent

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// On importera les vrais écrans au fur et à mesure qu'on les crée.
// Pour l'instant on met des placeholders (pages vides temporaires).
import '../../features/admin/presentation/tickets_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/super_admin/presentation/super_admin_shell.dart';
import '../../features/admin/presentation/admin_shell.dart';
import '../../features/agent/presentation/agent_shell.dart';
import '../../shared/models/event_model.dart';
import '../providers/auth_provider.dart';
import '../../features/super_admin/presentation/create_admin_screen.dart';
import '../../shared/presentation/profile_page.dart';
import '../../features/admin/presentation/assign_agents_screen.dart';

// Le Provider qui expose le router à toute l'application
final appRouterProvider = Provider<GoRouter>((ref) {
  // On écoute l'état d'authentification
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    // Route initiale : l'app démarre toujours ici
    initialLocation: '/splash',

    // redirect est appelé avant CHAQUE navigation
    // C'est ici qu'on vérifie si l'utilisateur a le droit d'aller quelque part
    redirect: (context, state) {
      final isLoggedIn = authState.isLoggedIn;
      final userRole = authState.role;
      final currentPath = state.matchedLocation;

      // Si pas connecté et pas sur /login → on envoie vers /login
      if (!isLoggedIn && currentPath != '/login') {
        return '/login';
      }

      // Si connecté et sur /login ou /splash → on redirige vers la bonne interface
      if (isLoggedIn && (currentPath == '/login' || currentPath == '/splash')) {
        switch (userRole) {
          case UserRole.superAdmin:
            return '/super-admin';
          case UserRole.admin:
            return '/admin';
          case UserRole.agent:
            return '/agent';
          default:
            return '/login';
        }
      }

      // null = pas de redirection, on laisse la navigation se faire normalement
      return null;
    },

    routes: [
      // --- Écran de démarrage (splash) ---
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // --- Écran de connexion ---
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // --- Interface Super-Admin ---
      // ShellRoute permet d'avoir une bottom nav bar persistante
      ShellRoute(
        builder: (context, state, child) => SuperAdminShell(child: child),
        routes: [
          GoRoute(
            path: '/super-admin',
            builder: (context, state) => const SuperAdminDashboardPage(),
          ),
          GoRoute(
            path: '/super-admin/admins',
            builder: (context, state) => const SuperAdminAdminsPage(),
          ),
          GoRoute(
            path: '/super-admin/stats',
            builder: (context, state) => const SuperAdminStatsPage(),
          ),
          GoRoute(
            path: '/super-admin/settings',
            builder: (context, state) => const SuperAdminSettingsPage(),
          ),
          GoRoute(
            path: '/super-admin/admins/create',
            builder: (context, state) => const CreateAdminScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfilePage(),
          ),
        ],
      ),

      // --- Interface Admin ---
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: '/admin',
            builder: (context, state) => const AdminDashboardPage(),
          ),
          GoRoute(
            path: '/admin/events',
            builder: (context, state) => const AdminEventsPage(),
          ),
          GoRoute(
            path: '/admin/events/create',
            builder: (context, state) => const AdminCreateEventPage(),
          ),
          GoRoute(
            path: '/admin/stats',
            builder: (context, state) => const AdminStatsPage(),
          ),
          GoRoute(
            path: '/admin/events/:eventId/tickets',
            builder: (context, state){
              final event = state.extra as EventModel;
              return TicketsScreen(event: event);
            }
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfilePage(),
          ),
          GoRoute(
            path: '/admin/agents',
            builder: (context, state) => const AdminAgentsPage(),
          ),
          GoRoute(
            path: '/admin/events/:eventId/assign',
            builder: (context, state) {
              final event = state.extra as EventModel;
              return AssignAgentsScreen(event: event);
            },
          ),
        ],
      ),

      // --- Interface Agent de scan ---
          ShellRoute(
        builder: (context, state, child) => AgentShell(child: child),
        routes: [
          GoRoute(
            path: '/agent',
            builder: (context, state) => const AgentScanPage(),
          ),
          GoRoute(
            path: '/agent/history',
            builder: (context, state) => const AgentHistoryPage(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfilePage(),
          ),
        ],
      ),
    ],

    // Page affichée si une route n'existe pas
    errorBuilder: (context, state) => Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: Center(
        child: Text(
          'Page introuvable',
          style: TextStyle(color: Colors.white),
        ),
      ),
    ),
  );
});

// --- Écran Splash temporaire ---
// Il sera remplacé plus tard par une vraie animation de démarrage
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}