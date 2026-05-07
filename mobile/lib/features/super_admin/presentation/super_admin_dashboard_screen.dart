// lib/features/super_admin/presentation/super_admin_dashboard_screen.dart
//
// Le tableau de bord du Super-Admin (Écran 1 de tes maquettes).
// Contient : 4 cartes de stats + liste des admins récents.
//
// Note : ce fichier utilise "part of" pour être lié au shell.
// C'est une façon de découper un gros fichier en plusieurs morceaux.

part of 'super_admin_shell.dart';

class SuperAdminDashboardScreen extends ConsumerWidget {
  const SuperAdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Données de démonstration (seront remplacées par de vraies données API)
    final recentAdmins = [
      AdminModel(
        id: '1',
        name: 'ASSOUMA Kamal',
        email: 'k.assouma@epac.bj',
        status: AdminStatus.active,
        eventsCount: 12,
        ticketsCount: 847,
        revenue: 1200000,
      ),
      AdminModel(
        id: '2',
        name: 'SONON Jehovas-nis',
        email: 's.jehovas@epac.bj',
        status: AdminStatus.active,
        eventsCount: 8,
        ticketsCount: 0,
        revenue: 890000,
      ),
      AdminModel(
        id: '3',
        name: 'EDOH Maxim',
        email: 'm.edoh@concert.bj',
        status: AdminStatus.pending,
        eventsCount: 0,
        ticketsCount: 0,
        revenue: 0,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // --- App Bar personnalisée ---
            SliverToBoxAdapter(
              child: _buildAppBar(context, ref),
            ),

            // --- Section "Vue d'ensemble" + cartes de stats ---
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Vue d\'ensemble',
                        style: AppTextStyles.sectionTitle),
                    const SizedBox(height: 16),

                    // Grille 2x2 de cartes de stats
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      // shrinkWrap + NeverScrollableScrollPhysics permet
                      // d'intégrer un GridView dans un ScrollView parent
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.85,
                      children: const [
                        StatCard(
                          icon: Icons.people_outline_rounded,
                          iconColor: AppColors.iconBlue,
                          iconBackground: AppColors.iconBlueBackground,
                          value: '24',
                          label: 'Admins actifs',
                          trend: '+3 ce mois',
                          trendColor: AppColors.statusActive,
                        ),
                        StatCard(
                          icon: Icons.calendar_month_outlined,
                          iconColor: AppColors.iconGreen,
                          iconBackground: AppColors.iconGreenBackground,
                          value: '138',
                          label: 'Événements',
                          trend: '+12 ce mois',
                          trendColor: AppColors.statusActive,
                        ),
                        StatCard(
                          icon: Icons.attach_money_rounded,
                          iconColor: AppColors.iconOrange,
                          iconBackground: AppColors.iconOrangeBackground,
                          value: '4,2M',
                          label: 'Transactions',
                          trend: 'FCFA',
                          trendColor: AppColors.statusPending,
                        ),
                        StatCard(
                          icon: Icons.warning_amber_rounded,
                          iconColor: AppColors.iconRed,
                          iconBackground: AppColors.iconRedBackground,
                          value: '7',
                          label: 'Alertes fraude',
                          trend: 'Cette sem.',
                          trendColor: AppColors.statusSuspended,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // --- Section "Admins récents" ---
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Admins récents',
                        style: AppTextStyles.sectionTitle),
                    // Bouton "Voir tous" → navigue vers l'onglet Admins
                    TextButton(
                      onPressed: () => context.go('/super-admin/admins'),
                      child: const Text(
                        'Voir tous',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // --- Liste des admins récents ---
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final admin = recentAdmins[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _AdminTile(admin: admin, compact: true),
                    );
                  },
                  childCount: recentAdmins.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- App Bar personnalisée ---
  Widget _buildAppBar(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          // Logo + nom de l'app
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.grid_view_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          const Text('Smart-Ticket', style: AppTextStyles.appBarTitle),
          const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.textTertiary, size: 20),

          const Spacer(),

          // Cloche de notification
          Stack(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: const Icon(Icons.notifications_outlined,
                    color: AppColors.textSecondary, size: 20),
              ),
              // Point rouge de notification
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.statusSuspended,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 10),

          // Avatar de l'utilisateur connecté
          AvatarCircle(
            name: authState.userName ?? 'Super Admin',
            size: 40,
          ),
        ],
      ),
    );
  }
}

// --- Tuile d'admin (ligne dans la liste) ---
// compact = true  → version courte pour le dashboard
// compact = false → version complète avec boutons d'action (page Admins)
class _AdminTile extends StatelessWidget {
  final AdminModel admin;
  final bool compact;

  const _AdminTile({required this.admin, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          AvatarCircle(name: admin.name, size: 42),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(admin.name, style: AppTextStyles.adminName),
                const SizedBox(height: 2),
                Text(admin.subtitle, style: AppTextStyles.adminSubtitle),
              ],
            ),
          ),
          StatusBadge(status: admin.status),
        ],
      ),
    );
  }
}