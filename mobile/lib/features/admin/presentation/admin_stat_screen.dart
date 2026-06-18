// lib/features/admin/presentation/admin_stats_screen.dart
part of 'admin_shell.dart';

// ─────────────────────────────────────────────
// ÉCRAN 4 — Statistiques Admin
// ─────────────────────────────────────────────
class AdminStatsScreen extends ConsumerStatefulWidget {
  const AdminStatsScreen({super.key});

  @override
  ConsumerState<AdminStatsScreen> createState() => _AdminStatsScreenState();
}

class _AdminStatsScreenState extends ConsumerState<AdminStatsScreen> {
  List<EventModel> _events = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final token = ref.read(authStateProvider).token!;
      final data = await ApiService.getMyEvents(token);
      setState(() {
        _events = data.map((e) => EventModel(
          id: e['id'].toString(),
          name: e['name'],
          type: _parseEventType(e['type']),
          date: DateTime.parse(e['date']),
          location: e['location'],
          description: e['description'] ?? '',
          ticketQuota: e['ticketQuota'],
          ticketsSold: e['ticketsSold'],
          ticketsUsed: e['ticketsUsed'],
          status: EventStatus.active,
          createdAt: DateTime.parse(e['createdAt']),
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

  EventType _parseEventType(String type) {
    switch (type.toLowerCase()) {
      case 'concert':  return EventType.concert;
      case 'foire':    return EventType.foire;
      case 'marche':   return EventType.marche;
      case 'festival': return EventType.festival;
      default:         return EventType.autre;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Stats globales calculées depuis les vrais événements
    final totalQuota = _events.fold(0, (s, e) => s + e.ticketQuota);
    final totalSold  = _events.fold(0, (s, e) => s + e.ticketsSold);
    final totalUsed  = _events.fold(0, (s, e) => s + e.ticketsUsed);

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
                onPressed: _loadEvents,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        )
            : RefreshIndicator(
          onRefresh: _loadEvents,
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Statistiques',
                    style: AppTextStyles.screenTitle),
                const SizedBox(height: 20),

                // ── Résumé global ──
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppColors.border, width: 0.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Résumé global',
                          style: AppTextStyles.sectionTitle),
                      const SizedBox(height: 16),

                      // 🔄 Grille 2x2 propre, équilibrée avec Expanded pour occuper tout l'espace des cartes
                      Column(
                        children: [
                          Row(children: [
                            Expanded(child: _MiniStat(
                              label: 'Événements',
                              value: '${_events.length}',
                            )),
                            const SizedBox(width: 12),
                            Expanded(child: _MiniStat(
                              label: 'Générés',
                              value: '$totalQuota',
                            )),
                          ]),
                          const SizedBox(height: 12),
                          Row(children: [
                            Expanded(child: _MiniStat(
                              label: 'Vendus',
                              value: '$totalSold',
                            )),
                            const SizedBox(width: 12),
                            Expanded(child: _MiniStat(
                              label: 'Entrées',
                              value: '$totalUsed',
                            )),
                          ]),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Barre de progression globale sécurisée
                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text('Taux de vente global',
                                style: AppTextStyles.caption,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                          Text(
                            totalQuota > 0
                                ? '${(totalSold / totalQuota * 100).toStringAsFixed(1)}%'
                                : '0%',
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: totalQuota > 0
                              ? totalSold / totalQuota
                              : 0,
                          minHeight: 8,
                          backgroundColor: AppColors.surfaceVariant,
                          valueColor:
                          const AlwaysStoppedAnimation<Color>(
                              AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Stats par événement ──
                if (_events.isEmpty)
                  const Center(
                    child: Text('Aucun événement',
                        style: AppTextStyles.adminSubtitle),
                  )
                else ...[
                  const Text('Par événement',
                      style: AppTextStyles.sectionTitle),
                  const SizedBox(height: 12),
                  ..._events.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _EventStatCard(event: e),
                  )),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}