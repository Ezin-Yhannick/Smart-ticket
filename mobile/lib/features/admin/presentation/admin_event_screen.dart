// ─────────────────────────────────────────────
// ÉCRAN 2 — Liste des événements
// ─────────────────────────────────────────────

part of 'admin_shell.dart';

class AdminEventsScreen extends ConsumerStatefulWidget {
  const AdminEventsScreen({super.key});
  @override
  ConsumerState<AdminEventsScreen> createState() => _AdminEventsScreenState();
}

class _AdminEventsScreenState extends ConsumerState<AdminEventsScreen> {
  List<EventModel> _events = [];
  bool _isLoading = true;
  String? _error;
  EventType? _filterType;

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

  List<EventModel> get _filtered => _filterType == null
      ? _events
      : _events.where((e) => e.type == _filterType).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const _AdminAppBar(userName: 'Admin'),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Événements', style: AppTextStyles.screenTitle),
                  GestureDetector(
                    onTap: () => context.go('/admin/events/create'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(children: [
                        Icon(Icons.add_rounded, color: Colors.white, size: 18),
                        SizedBox(width: 4),
                        Text('Créer',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Filtres par type
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _TypeChip(
                    label: 'Tous',
                    isSelected: _filterType == null,
                    onTap: () => setState(() => _filterType = null),
                  ),
                  const SizedBox(width: 8),
                  ...EventType.values.map((t) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _TypeChip(
                      label: t.label,
                      isSelected: _filterType == t,
                      onTap: () => setState(() => _filterType = t),
                    ),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Contenu
            Expanded(
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
                    Text(_error!,
                        style: AppTextStyles.adminSubtitle),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadEvents,
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              )
                  : _filtered.isEmpty
                  ? const Center(
                child: Text(
                  'Aucun événement dans cette catégorie',
                  style: AppTextStyles.adminSubtitle,
                ),
              )
                  : RefreshIndicator(
                onRefresh: _loadEvents,
                color: AppColors.primary,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                      20, 0, 20, 24),
                  itemCount: _filtered.length,
                  separatorBuilder: (_, __) =>
                  const SizedBox(height: 12),
                  itemBuilder: (_, i) =>
                      _EventDetailCard(event: _filtered[i]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────
// MODÈLE LOCAL — une catégorie dans le formulaire
// ─────────────────────────────────────────────
class _CategoryForm {
  final TextEditingController nameCtrl;
  final TextEditingController priceCtrl;
  final TextEditingController quotaCtrl;
  String color;
  DateTime? validFrom;
  DateTime? validTo;

  _CategoryForm({
    String name = '',
    String price = '',
    String quota = '',
    this.color = '#1E88E5',
    this.validFrom,
    this.validTo,
  })  : nameCtrl = TextEditingController(text: name),
        priceCtrl = TextEditingController(text: price),
        quotaCtrl = TextEditingController(text: quota);

  void dispose() {
    nameCtrl.dispose();
    priceCtrl.dispose();
    quotaCtrl.dispose();
  }
}