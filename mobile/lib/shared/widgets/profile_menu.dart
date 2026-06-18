// lib/shared/widgets/profile_menu.dart
//
// Menu profil réutilisable pour Admin et Agent.
// S'ouvre quand l'utilisateur appuie sur son avatar.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class ProfileMenu extends ConsumerWidget {
  const ProfileMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);

    return PopupMenuButton<String>(
      offset: const Offset(0, 48),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border, width: 0.5),
      ),
      onSelected: (value) async {
        if (value == 'logout') {
          // Déconnexion
          ref.read(authStateProvider.notifier).logout();
          if (context.mounted) context.go('/login');
        } else if (value == 'profile') {
          context.push('/profile');
        }
      },
      itemBuilder: (_) => [
        // En-tête du menu (non cliquable)
        PopupMenuItem(
          enabled: false,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                auth.userName ?? 'Utilisateur',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                auth.userEmail ?? '',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              // Badge rôle
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _roleColor(auth.role).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _roleLabel(auth.role),
                  style: TextStyle(
                    color: _roleColor(auth.role),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
            ],
          ),
        ),

        // Profil
        PopupMenuItem(
          value: 'profile',
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 4),
          child: const Row(
            children: [
              Icon(Icons.person_outline_rounded,
                  color: AppColors.textSecondary, size: 18),
              SizedBox(width: 12),
              Text('Mon profil',
                  style: TextStyle(
                      color: AppColors.textPrimary, fontSize: 14)),
            ],
          ),
        ),

        // Séparateur
        const PopupMenuDivider(height: 1),

        // Déconnexion
        PopupMenuItem(
          value: 'logout',
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 4),
          child: const Row(
            children: [
              Icon(Icons.logout_rounded,
                  color: AppColors.statusSuspended, size: 18),
              SizedBox(width: 12),
              Text('Se déconnecter',
                  style: TextStyle(
                      color: AppColors.statusSuspended,
                      fontSize: 14,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],

      // L'avatar qui déclenche le menu
      child: _AvatarTrigger(name: auth.userName ?? 'U'),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }

  String _roleLabel(UserRole role) {
    switch (role) {
      case UserRole.superAdmin: return 'Super Administrateur';
      case UserRole.admin:      return 'Administrateur';
      case UserRole.agent:      return 'Agent / Marchand';
      default:                  return 'Inconnu';
    }
  }

  Color _roleColor(UserRole role) {
    switch (role) {
      case UserRole.superAdmin: return const Color(0xFF8E24AA);
      case UserRole.admin:      return AppColors.primary;
      case UserRole.agent:      return AppColors.statusActive;
      default:                  return AppColors.textSecondary;
    }
  }
}

// Avatar avec initiales qui déclenche le menu
class _AvatarTrigger extends StatelessWidget {
  final String name;
  const _AvatarTrigger({required this.name});

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 19,
      backgroundColor: AppColors.primary,
      child: Text(
        _initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}