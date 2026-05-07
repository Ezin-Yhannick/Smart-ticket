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

// ── Données de démo ──

class _MonthData {
  final String month;
  final int tickets;
  const _MonthData(this.month, this.tickets);
}

class _TopAdmin {
  final String name;
  final int events;
  final double revenue;
  final int tickets;
  const _TopAdmin({
    required this.name,
    required this.events,
    required this.revenue,
    required this.tickets,
  });

  String get revenueFormatted {
    if (revenue >= 1000000) {
      return '${(revenue / 1000000).toStringAsFixed(1)}M FCFA';
    }
    return '${(revenue / 1000).toStringAsFixed(0)}K FCFA';
  }
}

class _FraudAlert {
  final String eventName;
  final String ticketId;
  final String agentName;
  final DateTime detectedAt;
  const _FraudAlert({
    required this.eventName,
    required this.ticketId,
    required this.agentName,
    required this.detectedAt,
  });

  String get timeAgo {
    final diff = DateTime.now().difference(detectedAt);
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    return 'Hier';
  }
}

// ════════════════════════════════════════════════════════
// ÉCRAN PRINCIPAL
// ════════════════════════════════════════════════════════
class SuperAdminStatsScreen extends StatelessWidget {
  const SuperAdminStatsScreen({super.key});

  static const _monthlyData = [
    _MonthData('Jan', 120),
    _MonthData('Fév', 95),
    _MonthData('Mar', 210),
    _MonthData('Avr', 180),
    _MonthData('Mai', 340),
    _MonthData('Jun', 290),
    _MonthData('Jul', 420),
    _MonthData('Aoû', 380),
  ];

  static const _topAdmins = [
    _TopAdmin(name: 'ASSOUMA Kamal',
        events: 12, revenue: 1200000, tickets: 847),
    _TopAdmin(name: 'SONON Jehovas-nis',
        events: 8, revenue: 890000, tickets: 612),
    _TopAdmin(name: 'BOCO Melina',
        events: 5, revenue: 450000, tickets: 320),
    _TopAdmin(name: 'EZIN Yannick',
        events: 3, revenue: 220000, tickets: 180),
  ];

  static final _fraudAlerts = [
    _FraudAlert(
      eventName: 'Foire de Cotonou',
      ticketId: 'QR-UNKNOWN-001',
      agentName: 'Agent Kouassi',
      detectedAt: DateTime.now().subtract(const Duration(minutes: 23)),
    ),
    _FraudAlert(
      eventName: 'Concert Urban Vibe',
      ticketId: 'QR-FAKE-042',
      agentName: 'Agent Adjobi',
      detectedAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    _FraudAlert(
      eventName: 'Foire de Cotonou',
      ticketId: 'TKT-EVT001-0099',
      agentName: 'Agent Mensah',
      detectedAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Titre
              const Text('Statistiques', style: AppTextStyles.screenTitle),
              const SizedBox(height: 4),
              const Text('Vue globale de la plateforme Smart-Ticket',
                  style: AppTextStyles.adminSubtitle),
              const SizedBox(height: 24),

              // ── 1. Résumé global ──
              const Text('Résumé global', style: AppTextStyles.sectionTitle),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _SummaryCard(
                  value: '24', label: 'Admins actifs',
                  icon: Icons.people_outline_rounded,
                  iconColor: AppColors.iconBlue,
                  iconBg: AppColors.iconBlueBackground,
                  trend: '+3 ce mois', positive: true,
                )),
                const SizedBox(width: 12),
                Expanded(child: _SummaryCard(
                  value: '138', label: 'Événements',
                  icon: Icons.event_outlined,
                  iconColor: AppColors.iconGreen,
                  iconBg: AppColors.iconGreenBackground,
                  trend: '+12 ce mois', positive: true,
                )),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _SummaryCard(
                  value: '4,2M', label: 'FCFA collectés',
                  icon: Icons.attach_money_rounded,
                  iconColor: AppColors.iconOrange,
                  iconBg: AppColors.iconOrangeBackground,
                  trend: '+18% ce mois', positive: true,
                )),
                const SizedBox(width: 12),
                Expanded(child: _SummaryCard(
                  value: '7', label: 'Alertes fraude',
                  icon: Icons.warning_amber_rounded,
                  iconColor: AppColors.iconRed,
                  iconBg: AppColors.iconRedBackground,
                  trend: 'Cette semaine', positive: false,
                )),
              ]),
              const SizedBox(height: 28),

              // ── 2. Graphique mensuel ──
              const Text('Activité mensuelle',
                  style: AppTextStyles.sectionTitle),
              const SizedBox(height: 4),
              const Text('Tickets vendus par mois',
                  style: AppTextStyles.adminSubtitle),
              const SizedBox(height: 16),
              _buildBarChart(),
              const SizedBox(height: 28),

              // ── 3. Classement admins ──
              const Text('Top Administrateurs',
                  style: AppTextStyles.sectionTitle),
              const SizedBox(height: 4),
              const Text('Classés par revenus générés',
                  style: AppTextStyles.adminSubtitle),
              const SizedBox(height: 12),
              ..._topAdmins.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _TopAdminTile(rank: e.key + 1, admin: e.value),
              )),
              const SizedBox(height: 28),

              // ── 4. Alertes fraude ──
              Row(children: [
                const Text('Alertes fraude récentes',
                    style: AppTextStyles.sectionTitle),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.statusSuspendedBackground,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_fraudAlerts.length}',
                    style: const TextStyle(
                      color: AppColors.statusSuspended,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              ..._fraudAlerts.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _FraudAlertTile(alert: a),
              )),
              const SizedBox(height: 24),
            ],
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
          children: _monthlyData.map((d) => Text(d.month,
              style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 10,
                  fontWeight: FontWeight.w500))).toList(),
        ),
      ]),
    );
  }
}

// ════════════════════════════════════════════════════════
// WIDGETS INTERNES
// ════════════════════════════════════════════════════════

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
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
              color: iconBg, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(height: 12),
        Text(value, style: AppTextStyles.statNumber),
        const SizedBox(height: 2),
        Text(label, style: AppTextStyles.statLabel),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
              color: trendBg,
              borderRadius: BorderRadius.circular(20)),
          child: Text(trend,
              style: TextStyle(
                  color: trendColor, fontSize: 10,
                  fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }
}

class _TopAdminTile extends StatelessWidget {
  final int rank;
  final _TopAdmin admin;
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
                  color: _rankColor, fontSize: 15,
                  fontWeight: FontWeight.w800)),
        ),
        const SizedBox(width: 10),
        AvatarCircle(name: admin.name, size: 40),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(admin.name, style: AppTextStyles.adminName),
            const SizedBox(height: 3),
            Text('${admin.events} événements · ${admin.tickets} tickets',
                style: AppTextStyles.caption),
          ]),
        ),
        Text(admin.revenueFormatted,
            style: const TextStyle(
                color: AppColors.statusActive,
                fontSize: 13,
                fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class _FraudAlertTile extends StatelessWidget {
  final _FraudAlert alert;
  const _FraudAlertTile({required this.alert});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.statusSuspendedBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppColors.statusSuspended.withOpacity(0.3),
            width: 0.5),
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: AppColors.statusSuspended.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.warning_amber_rounded,
              color: AppColors.statusSuspended, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(alert.eventName,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 3),
            Text('ID: ${alert.ticketId} · ${alert.agentName}',
                style: AppTextStyles.caption,
                overflow: TextOverflow.ellipsis),
          ]),
        ),
        const SizedBox(width: 8),
        Text(alert.timeAgo,
            style: const TextStyle(
                color: AppColors.statusSuspended,
                fontSize: 11,
                fontWeight: FontWeight.w500)),
      ]),
    );
  }
}