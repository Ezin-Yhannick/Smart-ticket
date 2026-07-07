import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../core/services/api_service.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final settings = ref.watch(settingsProvider);

    String initials(String name) {
      final parts = name.trim().split(' ');
      if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      return name.isNotEmpty ? name[0].toUpperCase() : 'U';
    }

    Color roleColor() {
      switch (auth.role) {
        case UserRole.superAdmin: return const Color(0xFF8E24AA);
        case UserRole.admin:      return AppColors.primary;
        case UserRole.agent:      return AppColors.statusActive;
        default:                  return AppColors.textSecondary;
      }
    }

    String roleLabel() {
      switch (auth.role) {
        case UserRole.superAdmin: return 'Super Administrateur';
        case UserRole.admin:      return 'Administrateur';
        case UserRole.agent:      return 'Agent / Marchand';
        default:                  return 'Inconnu';
      }
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── AppBar avec avatar ──
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded,
                  color: Colors.white),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.primaryDark,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        child: Text(
                          initials(auth.userName ?? 'U'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        auth.userName ?? 'Utilisateur',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          roleLabel(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Infos du compte ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Informations du compte',
                          style: AppTextStyles.sectionTitle),
                      TextButton.icon(
                        onPressed: () => _showEditProfileDialog(context, ref, auth),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Modifier'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _InfoCard(children: [
                    _InfoRow(
                      icon: Icons.person_outline_rounded,
                      label: 'Nom complet',
                      value: auth.userName ?? '-',
                    ),
                    const Divider(height: 1, indent: 52),
                    _InfoRow(
                      icon: Icons.mail_outline_rounded,
                      label: 'Email',
                      value: auth.userEmail ?? '-',
                    ),
                    const Divider(height: 1, indent: 52),
                    _InfoRow(
                      icon: Icons.phone_android_rounded,
                      label: 'WhatsApp',
                      value: auth.userPhone ?? '-',
                    ),
                    const Divider(height: 1, indent: 52),
                    _InfoRow(
                      icon: Icons.badge_outlined,
                      label: 'Identifiant',
                      value: '#${auth.userId ?? '-'}',
                    ),
                    const Divider(height: 1, indent: 52),
                    _InfoRow(
                      icon: Icons.shield_outlined,
                      label: 'Rôle',
                      value: roleLabel(),
                      valueColor: roleColor(),
                    ),
                  ]),

                  const SizedBox(height: 28),

                  // ── Sécurité ──
                  const Text('Sécurité', style: AppTextStyles.sectionTitle),
                  const SizedBox(height: 12),
                  _InfoCard(children: [
                    _ActionRow(
                      icon: Icons.lock_outline_rounded,
                      label: 'Changer le mot de passe',
                      onTap: () => _showComingSoon(context),
                    ),
                    const Divider(height: 1, indent: 52),
                    _ActionRow(
                      icon: Icons.fingerprint_rounded,
                      label: 'Authentification biométrique',
                      trailing: Switch(
                        value: false,
                        onChanged: (_) => _showComingSoon(context),
                        activeColor: AppColors.primary,
                      ),
                      onTap: () => _showComingSoon(context),
                    ),
                    const Divider(height: 1, indent: 52),
                    _ActionRow(
                      icon: Icons.devices_rounded,
                      label: 'Sessions actives',
                      onTap: () => _showComingSoon(context),
                    ),
                  ]),

                  const SizedBox(height: 28),

                  // ── Confidentialité ──
                  const Text('Confidentialité',
                      style: AppTextStyles.sectionTitle),
                  const SizedBox(height: 12),
                  _InfoCard(children: [
                    _ActionRow(
                      icon: Icons.notifications_outlined,
                      label: 'Notifications',
                      trailing: Switch(
                        value: true,
                        onChanged: (_) => _showComingSoon(context),
                        activeColor: AppColors.primary,
                      ),
                      onTap: () {},
                    ),
                    const Divider(height: 1, indent: 52),
                    _ActionRow(
                      icon: Icons.history_rounded,
                      label: 'Historique d\'activité',
                      onTap: () => _showComingSoon(context),
                    ),
                    const Divider(height: 1, indent: 52),
                    _ActionRow(
                      icon: Icons.privacy_tip_outlined,
                      label: 'Politique de confidentialité',
                      onTap: () => _showComingSoon(context),
                    ),
                  ]),

                  const SizedBox(height: 28),

                  // ── Préférences ──
                  const Text('Préférences', style: AppTextStyles.sectionTitle),
                  const SizedBox(height: 12),
                  _InfoCard(children: [
                    _ActionRow(
                      icon: Icons.language_rounded,
                      label: 'Langue',
                      value: settings.locale.languageCode == 'fr' ? 'Français' : 'English',
                      onTap: () {
                        final newLang = settings.locale.languageCode == 'fr' ? 'en' : 'fr';
                        ref.read(settingsProvider.notifier).setLocale(newLang);
                      },
                    ),
                    const Divider(height: 1, indent: 52),
                    _ActionRow(
                      icon: Icons.dark_mode_outlined,
                      label: 'Thème sombre',
                      trailing: Switch(
                        value: settings.themeMode == ThemeMode.dark,
                        onChanged: (isDark) => ref.read(settingsProvider.notifier).toggleTheme(isDark),
                        activeColor: AppColors.primary,
                      ),
                      onTap: () => ref.read(settingsProvider.notifier).toggleTheme(settings.themeMode != ThemeMode.dark),
                    ),
                  ]),

                  const SizedBox(height: 28),

                  // ── À propos ──
                  const Text('À propos', style: AppTextStyles.sectionTitle),
                  const SizedBox(height: 12),
                  _InfoCard(children: [
                    _ActionRow(
                      icon: Icons.info_outline_rounded,
                      label: 'Version',
                      value: 'Smart-Ticket v1.0 MVP',
                      onTap: () {},
                    ),
                    const Divider(height: 1, indent: 52),
                    _ActionRow(
                      icon: Icons.school_outlined,
                      label: 'Projet académique',
                      value: 'EPAC / GIT4 · 2025-2026',
                      onTap: () {},
                    ),
                    const Divider(height: 1, indent: 52),
                    _ActionRow(
                      icon: Icons.description_outlined,
                      label: 'Conditions d\'utilisation',
                      onTap: () => _showComingSoon(context),
                    ),
                  ]),

                  const SizedBox(height: 32),

                  // ── Bouton déconnexion ──
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmLogout(context, ref),
                      icon: const Icon(Icons.logout_rounded,
                          color: AppColors.statusSuspended, size: 20),
                      label: const Text(
                        'Se déconnecter',
                        style: TextStyle(
                          color: AppColors.statusSuspended,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: AppColors.statusSuspended.withOpacity(0.5)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Smart-Ticket · EPAC/GIT4 · Cotonou, Bénin',
                      style: AppTextStyles.caption,
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Fonctionnalité à venir'),
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _showEditProfileDialog(BuildContext context, WidgetRef ref, AuthState auth) {
    final nameCtrl = TextEditingController(text: auth.userName);
    final phoneCtrl = TextEditingController(text: auth.userPhone);
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Modifier le profil'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nom complet'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: 'WhatsApp'),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: isSaving ? null : () async {
                setState(() => isSaving = true);
                try {
                  await ApiService.updateProfile(
                    token: auth.token!,
                    name: nameCtrl.text.trim(),
                    phone: phoneCtrl.text.trim(),
                  );
                  // Mettre à jour l'état local via Riverpod
                  ref.read(authStateProvider.notifier).login(
                    token: auth.token!,
                    role: auth.role,
                    userId: auth.userId!,
                    userName: nameCtrl.text.trim(),
                    userEmail: auth.userEmail!,
                    userPhone: phoneCtrl.text.trim(),
                  );
                  if (context.mounted) Navigator.pop(ctx);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
                    );
                  }
                } finally {
                  setState(() => isSaving = false);
                }
              },
              child: isSaving 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Se déconnecter ?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'Vous serez redirigé vers l\'écran de connexion.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authStateProvider.notifier).logout();
              context.go('/login');
            },
            child: const Text('Déconnecter',
                style: TextStyle(
                    color: AppColors.statusSuspended,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ── Widgets internes ──

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border, width: 0.5),
    ),
    child: Column(children: children),
  );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: Row(children: [
      Icon(icon, color: AppColors.textSecondary, size: 20),
      const SizedBox(width: 16),
      Expanded(
        child: Text(label,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 14)),
      ),
      Text(value,
          style: TextStyle(
              color: valueColor ?? AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500)),
    ]),
  );
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final Widget? trailing;
  final VoidCallback onTap;

  const _ActionRow({
    required this.icon,
    required this.label,
    this.value,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Icon(icon, color: AppColors.textSecondary, size: 20),
        const SizedBox(width: 16),
        Expanded(
          child: Text(label,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
        ),
        if (value != null)
          Text(value!,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
        if (trailing != null) trailing!,
        if (trailing == null && value == null)
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.textTertiary, size: 20),
      ]),
    ),
  );
}