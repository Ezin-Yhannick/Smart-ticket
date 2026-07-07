// lib/features/admin/presentation/admin_shell.dart
//
// Shell de l'interface Admin avec bottom nav bar.
// Contient 4 écrans en un seul fichier pour faciliter le démarrage.
// À mesure que l'app grandit, on pourra découper en fichiers séparés.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/api_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../shared/models/event_model.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/widgets/avatar_circle.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../shared/widgets/profile_menu.dart';
import 'agents_screen.dart';

part 'admin_event_screen.dart';
part 'admin_create_event_screen.dart';
part 'admin_stat_screen.dart';

// ─────────────────────────────────────────────
// Shell — contient la bottom nav bar Admin
// ─────────────────────────────────────────────
class AdminShell extends StatelessWidget {
  final Widget child;
  const AdminShell({super.key, required this.child});

  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/admin/events')) return 1;
    if (location.startsWith('/admin/stats')) return 2;
    if (location.startsWith('/admin/agents')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.navBarBackground,
          border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _getCurrentIndex(context),
          type: BottomNavigationBarType.fixed,
          onTap: (i) {
            switch (i) {
              case 0: context.go('/admin'); break;
              case 1: context.go('/admin/events'); break;
              case 2: context.go('/admin/stats'); break;
              case 3: context.go('/admin/agents'); break;
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_outlined),
              activeIcon: Icon(Icons.grid_view_rounded),
              label: 'Tableau de bord',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.event_outlined),
              activeIcon: Icon(Icons.event_rounded),
              label: 'Événements',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart_rounded),
              label: 'Statistiques',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline_rounded),
              activeIcon: Icon(Icons.people_rounded),
              label: 'Mes Agents',
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Pages routées par app_router.dart
// ─────────────────────────────────────────────
class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});
  @override
  Widget build(BuildContext context) => const AdminDashboardScreen();
}

class AdminEventsPage extends StatelessWidget {
  const AdminEventsPage({super.key});
  @override
  Widget build(BuildContext context) => const AdminEventsScreen();
}

class AdminCreateEventPage extends StatelessWidget {
  const AdminCreateEventPage({super.key});
  @override
  Widget build(BuildContext context) => const CreateEventScreen();
}

class AdminStatsPage extends StatelessWidget {
  const AdminStatsPage({super.key});
  @override
  Widget build(BuildContext context) => const AdminStatsScreen();
}
// ─────────────────────────────────────────────
// ÉCRAN 1 — Dashboard Admin
// ─────────────────────────────────────────────
class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  List<EventModel> _events = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      final token = ref.read(authStateProvider).token!;
      final data = await ApiService.getMyEvents(token);

      if (!mounted) return;
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
      if (!mounted) return;
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
    final authState = ref.watch(authStateProvider);

    final totalQuota   = _events.fold(0, (s, e) => s + e.ticketQuota);
    final totalSold    = _events.fold(0, (s, e) => s + e.ticketsSold);
    final totalUsed    = _events.fold(0, (s, e) => s + e.ticketsUsed);
    final activeEvents = _events.length;

    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: _loadEvents,
              color: AppColors.primary,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _AdminAppBar(userName: authState.userName ?? 'Admin'),
                  ),

                  // ── Stats ──
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Vue d\'ensemble', style: AppTextStyles.sectionTitle),
                          const SizedBox(height: 16),
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.80,
                            children: [
                              StatCard(
                                icon: Icons.event_outlined,
                                iconColor: AppColors.iconBlue,
                                iconBackground: AppColors.iconBlueBackground,
                                value: '$activeEvents',
                                label: 'Événements actifs',
                              ),
                              StatCard(
                                icon: Icons.confirmation_number_outlined,
                                iconColor: AppColors.iconGreen,
                                iconBackground: AppColors.iconGreenBackground,
                                value: '$totalQuota',
                                label: 'Tickets générés',
                              ),
                              StatCard(
                                icon: Icons.sell_outlined,
                                iconColor: AppColors.iconOrange,
                                iconBackground: AppColors.iconOrangeBackground,
                                value: '$totalSold',
                                label: 'Tickets vendus',
                                trend: totalQuota > 0
                                    ? '${(totalSold / totalQuota * 100).toStringAsFixed(1)}%'
                                    : '0%',
                                trendColor: AppColors.statusActive,
                              ),
                              StatCard(
                                icon: Icons.how_to_reg_outlined,
                                iconColor: AppColors.iconRed,
                                iconBackground: AppColors.iconRedBackground,
                                value: '$totalUsed',
                                label: 'Entrées validées',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Header liste événements ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Mes événements', style: AppTextStyles.sectionTitle),
                          TextButton(
                            onPressed: () => context.go('/admin/events'),
                            child: const Text('Voir tous',
                                style: TextStyle(color: AppColors.primary, fontSize: 13)),
                          ),
                        ],
                      ),
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
                            Text(_error!, style: AppTextStyles.adminSubtitle),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadEvents,
                              child: const Text('Réessayer'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (_events.isEmpty)
                      const SliverFillRemaining(
                        child: Center(
                          child: Text('Aucun événement créé pour l\'instant',
                              style: AppTextStyles.adminSubtitle),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                                (context, i) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _EventTile(event: _events[i]),
                            ),
                            childCount: _events.length > 3 ? 3 : _events.length,
                          ),
                        ),
                      ),
                ],
              ),
            ),
            Positioned(
              bottom: 20,
              right: 20,
              child: FloatingActionButton.extended(
                onPressed: () => context.go('/admin/events/create'),
                backgroundColor: AppColors.primary,
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                label: const Text('Nouvel événement',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Widgets internes réutilisables
// ─────────────────────────────────────────────

class _AdminAppBar extends ConsumerWidget {
  final String userName;
  const _AdminAppBar({required this.userName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.grid_view_rounded, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 10),
        const Text('Smart-Ticket', style: AppTextStyles.appBarTitle),
        const Spacer(),
        const ProfileMenu(),
      ]),
    );
  }
}

class _EventTile extends StatelessWidget {
  final EventModel event;
  const _EventTile({required this.event});

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
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: AppColors.iconBlueBackground,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(_eventIcon(event.type), color: AppColors.iconBlue, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(event.name, style: AppTextStyles.adminName),
            const SizedBox(height: 2),
            Text('${event.dateFormatted} · ${event.location}',
                style: AppTextStyles.adminSubtitle,
                overflow: TextOverflow.ellipsis),
          ]),
        ),
        const SizedBox(width: 8),
        Text('${event.ticketsSold}/${event.ticketQuota}',
            style: AppTextStyles.caption),
      ]),
    );
  }
}

class _EventDetailCard extends StatelessWidget {
  final EventModel event;
  const _EventDetailCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: AppColors.iconBlueBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_eventIcon(event.type), color: AppColors.iconBlue, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(event.name, style: AppTextStyles.adminName),
              Text(event.type.label, style: AppTextStyles.adminSubtitle),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.statusActiveBackground,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(event.dateFormatted,
                style: AppTextStyles.badgeText
                    .copyWith(color: AppColors.statusActive)),
          ),
        ]),

        const SizedBox(height: 10),
        Row(children: [
          const Icon(Icons.place_outlined, color: AppColors.textTertiary, size: 14),
          const SizedBox(width: 4),
          Text(event.location, style: AppTextStyles.adminSubtitle),
        ]),

        const SizedBox(height: 14),
        const Divider(height: 1),
        const SizedBox(height: 14),

        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Tickets vendus', style: AppTextStyles.caption),
          Text('${event.ticketsSold} / ${event.ticketQuota}',
              style: AppTextStyles.caption),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: event.soldPercentage / 100,
            minHeight: 6,
            backgroundColor: AppColors.surfaceVariant,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),

        const SizedBox(height: 14),

        Row(children: [
          Expanded(
            child: SizedBox(
              height: 36,
              child: ElevatedButton.icon(
                onPressed: () {
                  context.push(
                    '/admin/events/${event.id}/tickets',
                    extra: event,
                  );
                },
                icon: const Icon(Icons.qr_code_2_rounded, size: 16),
                label: const Text('QR Codes', style: AppTextStyles.buttonText),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SizedBox(
              height: 36,
              child: OutlinedButton.icon(
                onPressed: () {
                  context.push(
                    '/admin/events/${event.id}/assign',
                    extra: event,
                  );
                },
                icon: const Icon(Icons.people_outline_rounded, size: 16),
                label: const Text('Agents',
                    style: AppTextStyles.buttonText),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SizedBox(
              height: 36,
              child: OutlinedButton.icon(
                onPressed: () {
                  context.push(
                    '/admin/events/${event.id}/tickets',
                    extra: event,
                  );
                },
                icon: const Icon(Icons.download_outlined, size: 16),
                label: const Text('Exporter', style: AppTextStyles.buttonText),
              ),
            ),
          ),
        ]),
      ]),
    );
  }
}

class _EventStatCard extends StatelessWidget {
  final EventModel event;
  const _EventStatCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(event.name, style: AppTextStyles.sectionTitle),
        const SizedBox(height: 4),
        Text(event.dateFormatted, style: AppTextStyles.adminSubtitle),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _MiniStat(label: 'Quota', value: event.ticketQuota.toString())),
          Expanded(child: _MiniStat(label: 'Vendus', value: event.ticketsSold.toString())),
          Expanded(child: _MiniStat(label: 'Entrées', value: event.ticketsUsed.toString())),
          Expanded(child: _MiniStat(label: 'Taux', value: '${event.soldPercentage.toStringAsFixed(0)}%')),
        ]),
      ]),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Flexible(
          child: Text(
            label,
            style: AppTextStyles.caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(
        fontSize: 13, fontWeight: FontWeight.w500,
        color: AppColors.textSecondary)),
  );
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _TypeChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w500,
          color: isSelected ? Colors.white : AppColors.textSecondary)),
    ),
  );
}

class AdminAgentsPage extends StatelessWidget {
  const AdminAgentsPage({super.key});
  @override
  Widget build(BuildContext context) => const AgentsScreen();
}

IconData _eventIcon(EventType type) {
  switch (type) {
    case EventType.concert:  return Icons.music_note_outlined;
    case EventType.foire:    return Icons.storefront_outlined;
    case EventType.marche:   return Icons.shopping_basket_outlined;
    case EventType.festival: return Icons.celebration_outlined;
    case EventType.autre:    return Icons.event_outlined;
  }
}