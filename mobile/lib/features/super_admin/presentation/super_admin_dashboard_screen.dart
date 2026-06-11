// lib/features/super_admin/presentation/super_admin_dashboard_screen.dart
//
// Le tableau de bord du Super-Admin (Écran 1 de tes maquettes).
// Contient : 4 cartes de stats + liste des admins récents.
//
// Note : ce fichier utilise "part of" pour être lié au shell.
// C'est une façon de découper un gros fichier en plusieurs morceaux.
part of 'super_admin_shell.dart';

class SuperAdminDashboardScreen extends ConsumerStatefulWidget {
  const SuperAdminDashboardScreen({super.key});

  @override
  ConsumerState<SuperAdminDashboardScreen> createState() =>
      _SuperAdminDashboardScreenState();
}

class _SuperAdminDashboardScreenState
    extends ConsumerState<SuperAdminDashboardScreen> {

  Map<String, dynamic>? _stats;
  List<AdminModel> _recentAdmins = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final token = ref.read(authStateProvider).token!;
      final stats  = await ApiService.getPlatformStats(token);
      final admins = await ApiService.getAllAdmins(token);

      setState(() {
        _stats = stats;
        _recentAdmins = admins.take(3).map((a) => AdminModel(
          id: a['id'].toString(),
          name: a['name'],
          email: a['email'],
          status: a['status'] == 'ACTIVE'
              ? AdminStatus.active
              : AdminStatus.suspended,
          eventsCount: a['totalEvents'] ?? 0,
          ticketsCount: a['totalTickets'] ?? 0,
          revenue: 0,
        )).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppColors.primary,
          child: CustomScrollView(
            slivers: [
              // AppBar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(children: [
                    Container(
                      width: 34, height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.grid_view_rounded,
                          color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Text('Smart-Ticket',
                        style: AppTextStyles.appBarTitle),
                    const Spacer(),
                    const ProfileMenu(),
                  ]),
                ),
              ),

              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.wifi_off_rounded,
                            color: AppColors.textTertiary, size: 48),
                        const SizedBox(height: 12),
                        Text(_error!,
                            style: AppTextStyles.adminSubtitle),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadData,
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                  // Stats
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Vue d\'ensemble',
                              style: AppTextStyles.sectionTitle),
                          const SizedBox(height: 16),
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.85,
                            children: [
                              StatCard(
                                icon: Icons.people_outline_rounded,
                                iconColor: AppColors.iconBlue,
                                iconBackground: AppColors.iconBlueBackground,
                                value: '${_stats!['activeAdmins'] ?? 0}',
                                label: 'Admins actifs',
                                trend: '${_stats!['totalAdmins'] ?? 0} total',
                                trendColor: AppColors.statusActive,
                              ),
                              StatCard(
                                icon: Icons.calendar_month_outlined,
                                iconColor: AppColors.iconGreen,
                                iconBackground: AppColors.iconGreenBackground,
                                value: '${_stats!['totalEvents'] ?? 0}',
                                label: 'Événements',
                                trend: 'Sur la plateforme',
                                trendColor: AppColors.statusActive,
                              ),
                              StatCard(
                                icon: Icons.confirmation_number_outlined,
                                iconColor: AppColors.iconOrange,
                                iconBackground: AppColors.iconOrangeBackground,
                                value: '${_stats!['totalSold'] ?? 0}',
                                label: 'Tickets vendus',
                                trend:
                                '${_stats!['totalTickets'] ?? 0} générés',
                                trendColor: AppColors.statusPending,
                              ),
                              StatCard(
                                icon: Icons.how_to_reg_outlined,
                                iconColor: AppColors.iconRed,
                                iconBackground: AppColors.iconRedBackground,
                                value: '${_stats!['totalUsed'] ?? 0}',
                                label: 'Entrées validées',
                                trend: 'Total scans',
                                trendColor: AppColors.statusSuspended,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Header admins récents
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Admins récents',
                              style: AppTextStyles.sectionTitle),
                          TextButton(
                            onPressed: () =>
                                context.go('/super-admin/admins'),
                            child: const Text('Voir tous',
                                style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Liste admins récents
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (context, i) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _AdminTile(
                              admin: _recentAdmins[i], compact: true),
                        ),
                        childCount: _recentAdmins.length,
                      ),
                    ),
                  ),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

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
      child: Row(children: [
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
      ]),
    );
  }
}