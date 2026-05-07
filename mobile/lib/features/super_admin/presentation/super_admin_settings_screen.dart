// lib/features/super_admin/presentation/super_admin_settings_screen.dart
//
// ════════════════════════════════════════════════════════
// PAGE GESTION — Super-Admin
// ════════════════════════════════════════════════════════
//
// Le Super-Admin configure ici toute la plateforme :
//   1. Son profil connecté
//   2. Infos de la plateforme
//   3. Paramètres financiers (frais de service)
//   4. Paramètres système (maintenance, notifications)
//   5. Actions de maintenance
//   6. Déconnexion

part of 'super_admin_shell.dart';
// ════════════════════════════════════════════════════════
// ÉCRAN PRINCIPAL
// ════════════════════════════════════════════════════════
class SuperAdminSettingsScreen extends ConsumerStatefulWidget {
  const SuperAdminSettingsScreen({super.key});

  @override
  ConsumerState<SuperAdminSettingsScreen> createState() =>
      _SuperAdminSettingsScreenState();
}

class _SuperAdminSettingsScreenState
    extends ConsumerState<SuperAdminSettingsScreen> {

  // Frais de service en % (modifiable avec le slider)
  double _serviceFee = 5.0;

  // Mode maintenance : bloque l'accès aux admins
  bool _maintenanceMode = false;

  // Notifications fraude en temps réel
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Titre
              const Text('Gestion', style: AppTextStyles.screenTitle),
              const SizedBox(height: 4),
              const Text('Configuration de la plateforme',
                  style: AppTextStyles.adminSubtitle),
              const SizedBox(height: 24),

              // ── 1. Profil ──
              _buildProfile(authState),
              const SizedBox(height: 24),

              // ── 2. Infos plateforme ──
              _SectionLabel(title: 'Plateforme',
                  icon: Icons.info_outline_rounded),
              const SizedBox(height: 12),
              _SettingsCard(children: [
                _InfoRow(label: 'Nom', value: 'Smart-Ticket'),
                _Separator(),
                _InfoRow(label: 'Version', value: '1.0.0 (MVP)'),
                _Separator(),
                _InfoRow(label: 'Environnement', value: 'Développement'),
                _Separator(),
                _InfoRow(label: 'Admins actifs', value: '24'),
                _Separator(),
                _InfoRow(label: 'Événements', value: '138'),
              ]),
              const SizedBox(height: 24),

              // ── 3. Paramètres financiers ──
              _SectionLabel(title: 'Finances',
                  icon: Icons.tune_rounded),
              const SizedBox(height: 12),
              _SettingsCard(children: [
                // Slider pour les frais de service
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Frais de service',
                              style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500)),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.iconBlueBackground,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_serviceFee.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                  color: AppColors.iconBlue,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Text('Prélevé sur chaque transaction',
                          style: AppTextStyles.caption),
                      const SizedBox(height: 8),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppColors.primary,
                          inactiveTrackColor: AppColors.surfaceVariant,
                          thumbColor: AppColors.primary,
                          overlayColor:
                          AppColors.primary.withOpacity(0.1),
                          trackHeight: 4,
                        ),
                        child: Slider(
                          value: _serviceFee,
                          min: 0,
                          max: 20,
                          divisions: 40, // pas de 0.5%
                          onChanged: (v) =>
                              setState(() => _serviceFee = v),
                        ),
                      ),
                    ],
                  ),
                ),
                _Separator(),
                _InfoRow(label: 'Devise', value: 'FCFA'),
                _Separator(),
                _InfoRow(label: 'Passerelles',
                    value: 'FedaPay / Kkiapay'),
              ]),
              const SizedBox(height: 24),

              // ── 4. Système ──
              _SectionLabel(title: 'Système',
                  icon: Icons.settings_outlined),
              const SizedBox(height: 12),
              _SettingsCard(children: [
                _ToggleRow(
                  label: 'Mode maintenance',
                  subtitle: 'Bloque l\'accès aux admins',
                  value: _maintenanceMode,
                  onChanged: (v) => v
                      ? _confirmMaintenance()
                      : setState(() => _maintenanceMode = false),
                  activeColor: AppColors.statusSuspended,
                ),
                _Separator(),
                _ToggleRow(
                  label: 'Alertes fraude',
                  subtitle: 'Notifications en temps réel',
                  value: _notificationsEnabled,
                  onChanged: (v) =>
                      setState(() => _notificationsEnabled = v),
                  activeColor: AppColors.statusActive,
                ),
                _Separator(),
                _ActionRow(
                  label: 'Logs système',
                  subtitle: 'Historique des activités',
                  icon: Icons.receipt_long_outlined,
                  onTap: () => _showComingSoon('Logs système'),
                ),
              ]),
              const SizedBox(height: 24),

              // ── 5. Maintenance ──
              _SectionLabel(title: 'Maintenance',
                  icon: Icons.build_outlined),
              const SizedBox(height: 12),
              _SettingsCard(children: [
                _ActionRow(
                  label: 'Sauvegarder la base de données',
                  subtitle: 'Dernière sauvegarde : il y a 2h',
                  icon: Icons.backup_outlined,
                  onTap: () => _showComingSoon('Sauvegarde'),
                ),
                _Separator(),
                _ActionRow(
                  label: 'Exporter les statistiques',
                  subtitle: 'Rapport complet en Excel',
                  icon: Icons.download_outlined,
                  onTap: () => _showComingSoon('Export stats'),
                ),
                _Separator(),
                _ActionRow(
                  label: 'Vider le cache',
                  subtitle: 'Libère de l\'espace serveur',
                  icon: Icons.cleaning_services_outlined,
                  onTap: () => _showComingSoon('Cache vidé'),
                ),
              ]),
              const SizedBox(height: 32),

              // ── Bouton déconnexion ──
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _confirmLogout,
                  icon: const Icon(Icons.logout_rounded,
                      color: AppColors.statusSuspended, size: 20),
                  label: const Text('Se déconnecter',
                      style: TextStyle(
                          color: AppColors.statusSuspended,
                          fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: AppColors.statusSuspended.withOpacity(0.4)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Center(
                child: Text(
                  'Smart-Ticket v1.0 · MVP · EPAC/GIT4',
                  style: AppTextStyles.caption,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ── Profil connecté ──
  Widget _buildProfile(AuthState authState) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(children: [
        AvatarCircle(
            name: authState.userName ?? 'Super Admin', size: 52),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(authState.userName ?? 'Super Admin',
                  style: AppTextStyles.adminName),
              const SizedBox(height: 3),
              Text(
                  authState.userEmail ??
                      'superadmin@smart-ticket.bj',
                  style: AppTextStyles.adminSubtitle),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.iconBlueBackground,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('Super-Administrateur',
                    style: TextStyle(
                        color: AppColors.iconBlue,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => _showComingSoon('Modifier le profil'),
          icon: const Icon(Icons.edit_outlined,
              color: AppColors.textSecondary, size: 20),
        ),
      ]),
    );
  }

  // ── Confirmation mode maintenance ──
  void _confirmMaintenance() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Activer la maintenance ?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'Tous les administrateurs seront déconnectés '
              'et ne pourront plus accéder à la plateforme.',
          style: TextStyle(
              color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              setState(() => _maintenanceMode = true);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Mode maintenance activé'),
                  backgroundColor: AppColors.statusSuspended,
                ),
              );
            },
            child: const Text('Activer',
                style: TextStyle(
                    color: AppColors.statusSuspended,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ── Confirmation déconnexion ──
  void _confirmLogout() {
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
              // Vide l'état d'auth → GoRouter redirige vers /login
              ref.read(authStateProvider.notifier).logout();
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

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$feature — disponible avec le backend'),
      backgroundColor: AppColors.iconBlueBackground,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10)),
    ));
  }
}

// ════════════════════════════════════════════════════════
// WIDGETS INTERNES
// ════════════════════════════════════════════════════════

class _SectionLabel extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionLabel({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, color: AppColors.textSecondary, size: 18),
    const SizedBox(width: 8),
    Text(title, style: AppTextStyles.sectionTitle),
  ]);
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

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
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(
            color: AppColors.textSecondary, fontSize: 14)),
        Text(value, style: const TextStyle(
            color: AppColors.textPrimary, fontSize: 14,
            fontWeight: FontWeight.w500)),
      ],
    ),
  );
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color activeColor;
  const _ToggleRow({
    required this.label, required this.subtitle,
    required this.value, required this.onChanged,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    child: Row(children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(
              color: AppColors.textPrimary, fontSize: 14,
              fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(subtitle, style: AppTextStyles.caption),
        ]),
      ),
      Switch(
        value: value, onChanged: onChanged,
        activeColor: activeColor,
        inactiveThumbColor: AppColors.textTertiary,
        inactiveTrackColor: AppColors.surfaceVariant,
      ),
    ]),
  );
}

class _ActionRow extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  const _ActionRow({
    required this.label, required this.subtitle,
    required this.icon, required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(
                color: AppColors.textPrimary, fontSize: 14,
                fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(subtitle, style: AppTextStyles.caption),
          ]),
        ),
        const Icon(Icons.chevron_right_rounded,
            color: AppColors.textTertiary, size: 20),
      ]),
    ),
  );
}
