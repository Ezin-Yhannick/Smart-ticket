// lib/features/super_admin/presentation/super_admin_stats_screen.dart
//
// ════════════════════════════════════════════════════════
// PAGE STATISTIQUES GLOBALES — Super-Admin
// ════════════════════════════════════════════════════════
//
// Contenu :
//   1. Résumé global (admins, événements, FCFA, fraudes)
//   2. Graphique d'activité mensuelle (barres simples)
//   3. Classement des meilleurs admins
//   4. Alertes fraude récentes
part of 'super_admin_shell.dart';

class _MonthData {
  final String month;
  final int tickets;
  const _MonthData(this.month, this.tickets);
}

class SuperAdminStatsScreen extends ConsumerStatefulWidget {
  const SuperAdminStatsScreen({super.key});

  @override
  ConsumerState<SuperAdminStatsScreen> createState() =>
      _SuperAdminStatsScreenState();
}

class _SuperAdminStatsScreenState
    extends ConsumerState<SuperAdminStatsScreen> {

  Map<String, dynamic>? _stats;
  List<AdminModel> _topAdmins = [];
  bool _isLoading = true;
  String? _error;

  // Données mensuelles statiques (pas d'API pour ça pour l'instant)
  static const _monthlyData = [
    _MonthData('Jan', 120), _MonthData('Fév', 95),
    _MonthData('Mar', 210), _MonthData('Avr', 180),
    _MonthData('Mai', 340), _MonthData('Jun', 290),
    _MonthData('Jul', 420), _MonthData('Aoû', 380),
  ];

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
        // Tri des admins par nombre d'événements décroissant
        _topAdmins = admins.map((a) => AdminModel(
          id: a['id'].toString(),
          name: a['name'],
          email: a['email'],
          status: a['status'] == 'ACTIVE'
              ? AdminStatus.active
              : AdminStatus.suspended,
          eventsCount: a['totalEvents'] ?? 0,
          ticketsCount: a['totalTickets'] ?? 0,
          revenue: 0,
        )).toList()
          ..sort((a, b) => b.eventsCount.compareTo(a.eventsCount));
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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_rounded,
                  color: AppColors.textTertiary, size: 48),
              const SizedBox(height: 12),
              Text(_error!, style: AppTextStyles.adminSubtitle),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        )
            : RefreshIndicator(
          onRefresh: _loadData,
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre
                const Text('Statistiques',
                    style: AppTextStyles.screenTitle),
                const SizedBox(height: 4),
                const Text('Vue globale de la plateforme',
                    style: AppTextStyles.adminSubtitle),
                const SizedBox(height: 24),

                // ── 1. Résumé global depuis l'API ──
                const Text('Résumé global',
                    style: AppTextStyles.sectionTitle),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _SummaryCard(
                    value: '${_stats!['activeAdmins'] ?? 0}',
                    label: 'Admins actifs',
                    icon: Icons.people_outline_rounded,
                    iconColor: AppColors.iconBlue,
                    iconBg: AppColors.iconBlueBackground,
                    trend: '${_stats!['totalAdmins'] ?? 0} total',
                    positive: true,
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _SummaryCard(
                    value: '${_stats!['totalEvents'] ?? 0}',
                    label: 'Événements',
                    icon: Icons.event_outlined,
                    iconColor: AppColors.iconGreen,
                    iconBg: AppColors.iconGreenBackground,
                    trend: 'Sur la plateforme',
                    positive: true,
                  )),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _SummaryCard(
                    value: '${_stats!['totalSold'] ?? 0}',
                    label: 'Tickets vendus',
                    icon: Icons.confirmation_number_outlined,
                    iconColor: AppColors.iconOrange,
                    iconBg: AppColors.iconOrangeBackground,
                    trend: '${_stats!['totalTickets'] ?? 0} générés',
                    positive: true,
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _SummaryCard(
                    value: '${_stats!['totalUsed'] ?? 0}',
                    label: 'Entrées validées',
                    icon: Icons.how_to_reg_outlined,
                    iconColor: AppColors.iconRed,
                    iconBg: AppColors.iconRedBackground,
                    trend: 'Total scans',
                    positive: true,
                  )),
                ]),
                const SizedBox(height: 12),

                // Suspendus
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.statusSuspendedBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppColors.statusSuspended
                            .withOpacity(0.3),
                        width: 0.5),
                  ),
                  child: Row(children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.statusSuspended
                            .withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                          Icons.person_off_outlined,
                          color: AppColors.statusSuspended,
                          size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_stats!['suspendedAdmins'] ?? 0}',
                          style: const TextStyle(
                              color: AppColors.statusSuspended,
                              fontSize: 22,
                              fontWeight: FontWeight.w700),
                        ),
                        const Text('Admins suspendus',
                            style: AppTextStyles.caption),
                      ],
                    ),
                  ]),
                ),
                const SizedBox(height: 28),

                // ── 2. Graphique mensuel (statique) ──
                const Text('Activité mensuelle',
                    style: AppTextStyles.sectionTitle),
                const SizedBox(height: 4),
                const Text('Tickets vendus par mois',
                    style: AppTextStyles.adminSubtitle),
                const SizedBox(height: 16),
                _buildBarChart(),
                const SizedBox(height: 28),

                // ── 3. Top admins depuis l'API ──
                const Text('Top Administrateurs',
                    style: AppTextStyles.sectionTitle),
                const SizedBox(height: 4),
                const Text('Classés par nombre d\'événements',
                    style: AppTextStyles.adminSubtitle),
                const SizedBox(height: 12),

                if (_topAdmins.isEmpty)
                  const Center(
                    child: Text('Aucun administrateur',
                        style: AppTextStyles.adminSubtitle),
                  )
                else
                  ..._topAdmins
                      .take(5) // Top 5
                      .toList()
                      .asMap()
                      .entries
                      .map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _TopAdminTile(
                      rank: e.key + 1,
                      admin: e.value,
                    ),
                  )),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    final maxValue = _monthlyData
        .map((d) => d.tickets)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(children: [
        SizedBox(
          height: 140,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _monthlyData.map((data) {
              final barHeight = (data.tickets / maxValue) * 120;
              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('${data.tickets}',
                      style: const TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 9,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Container(
                    width: 28,
                    height: barHeight,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withOpacity(0.5),
                        ],
                      ),
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6)),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        const Divider(height: 1),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: _monthlyData
              .map((d) => Text(d.month,
              style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 10,
                  fontWeight: FontWeight.w500)))
              .toList(),
        ),
      ]),
    );
  }
}

// ── Carte de stat ──
class _SummaryCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String trend;
  final bool positive;

  const _SummaryCard({
    required this.value, required this.label,
    required this.icon, required this.iconColor,
    required this.iconBg, required this.trend,
    required this.positive,
  });

  @override
  Widget build(BuildContext context) {
    final trendColor = positive
        ? AppColors.statusActive
        : AppColors.statusSuspended;
    final trendBg = positive
        ? AppColors.statusActiveBackground
        : AppColors.statusSuspendedBackground;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // ✅ évite l'overflow
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 10),
          Text(value, style: AppTextStyles.statNumber),
          const SizedBox(height: 2),
          Text(label,
              style: AppTextStyles.statLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
                color: trendBg,
                borderRadius: BorderRadius.circular(20)),
            child: Text(trend,
                style: TextStyle(
                    color: trendColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

// ── Top Admin tile ──
class _TopAdminTile extends StatelessWidget {
  final int rank;
  final AdminModel admin;
  const _TopAdminTile({required this.rank, required this.admin});

  Color get _rankColor {
    switch (rank) {
      case 1: return const Color(0xFFFFD700);
      case 2: return const Color(0xFFC0C0C0);
      case 3: return const Color(0xFFCD7F32);
      default: return AppColors.textTertiary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: rank == 1
              ? _rankColor.withOpacity(0.4)
              : AppColors.border,
          width: rank == 1 ? 1 : 0.5,
        ),
      ),
      child: Row(children: [
        SizedBox(
          width: 28,
          child: Text('#$rank',
              style: TextStyle(
                  color: _rankColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w800)),
        ),
        const SizedBox(width: 10),
        AvatarCircle(name: admin.name, size: 40),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(admin.name, style: AppTextStyles.adminName),
              const SizedBox(height: 3),
              Text(
                '${admin.eventsCount} événements · '
                    '${admin.ticketsCount} tickets',
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ),
        StatusBadge(status: admin.status),
      ]),
    );
  }
}