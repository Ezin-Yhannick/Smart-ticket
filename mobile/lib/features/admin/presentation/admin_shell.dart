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
          onTap: (i) {
            switch (i) {
              case 0: context.go('/admin'); break;
              case 1: context.go('/admin/events'); break;
              case 2: context.go('/admin/stats'); break;
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
    final authState = ref.watch(authStateProvider);

    // Calculs des stats globales
    final totalQuota   = _events.fold(0, (s, e) => s + e.ticketQuota);
    final totalSold    = _events.fold(0, (s, e) => s + e.ticketsSold);
    final totalUsed    = _events.fold(0, (s, e) => s + e.ticketsUsed);
    final activeEvents = _events.length;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          // Pull-to-refresh pour recharger les données
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
                        childAspectRatio: 0.95,
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

              // ── Contenu : loading / erreur / liste ──
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/admin/events/create'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Nouvel événement',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// ÉCRAN 2 — Liste des événements
// ─────────────────────────────────────────────
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

// ─────────────────────────────────────────────
// ÉCRAN 3 — Créer un événement
// ─────────────────────────────────────────────
class CreateEventScreen extends ConsumerStatefulWidget {
  const CreateEventScreen({super.key});

  @override
  ConsumerState<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends ConsumerState<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  EventType _selectedType = EventType.concert;
  DateTime? _selectedDate;
  bool _isLoading = false;

  // Liste des catégories — démarre avec une catégorie vide
  final List<_CategoryForm> _categories = [_CategoryForm()];

  // Couleurs disponibles pour les catégories
  final List<Map<String, dynamic>> _availableColors = [
    {'label': 'Bleu',     'hex': '#1E88E5'},
    {'label': 'Or',       'hex': '#FFB300'},
    {'label': 'Rouge',    'hex': '#E53935'},
    {'label': 'Vert',     'hex': '#43A047'},
    {'label': 'Violet',   'hex': '#8E24AA'},
    {'label': 'Orange',   'hex': '#FB8C00'},
    {'label': 'Noir',     'hex': '#212121'},
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locationCtrl.dispose();
    _descCtrl.dispose();
    for (final c in _categories) c.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2027),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            surface: AppColors.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickCategoryDate(int index, bool isFrom) async {
    final cat = _categories[index];
    final initial = isFrom
        ? (cat.validFrom ?? DateTime.now())
        : (cat.validTo ?? DateTime.now().add(const Duration(days: 1)));

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now(),
      lastDate: DateTime(2027),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            surface: AppColors.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          cat.validFrom = picked;
        } else {
          cat.validTo = picked;
        }
      });
    }
  }

  String _formatDate(DateTime? d) {
    if (d == null) return 'Choisir...';
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year}';
  }

  Color _hexToColor(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  void _addCategory() {
    setState(() => _categories.add(_CategoryForm()));
  }

  void _removeCategory(int index) {
    if (_categories.length == 1) return; // toujours au moins une
    setState(() {
      _categories[index].dispose();
      _categories.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez choisir une date')));
      return;
    }

    // Vérifie que chaque catégorie a ses dates de validité
    for (int i = 0; i < _categories.length; i++) {
      final cat = _categories[i];
      if (cat.validFrom == null || cat.validTo == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(
              'Catégorie ${i + 1} : veuillez définir la période de validité')),
        );
        return;
      }
      if (cat.validTo!.isBefore(cat.validFrom!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(
              'Catégorie ${i + 1} : la date de fin doit être après la date de début')),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final token = ref.read(authStateProvider).token!;

      final dateStr = '${_selectedDate!.year}-'
          '${_selectedDate!.month.toString().padLeft(2, '0')}-'
          '${_selectedDate!.day.toString().padLeft(2, '0')}';

      // Construit la liste des catégories pour l'API
      final categoriesData = _categories.map((cat) => {
        'name': cat.nameCtrl.text.trim().isEmpty
            ? 'Standard'
            : cat.nameCtrl.text.trim(),
        'price': int.parse(cat.priceCtrl.text.trim()),
        'quota': int.parse(cat.quotaCtrl.text.trim()),
        'color': cat.color,
        'validFrom': '${cat.validFrom!.year}-'
            '${cat.validFrom!.month.toString().padLeft(2, '0')}-'
            '${cat.validFrom!.day.toString().padLeft(2, '0')}',
        'validTo': '${cat.validTo!.year}-'
            '${cat.validTo!.month.toString().padLeft(2, '0')}-'
            '${cat.validTo!.day.toString().padLeft(2, '0')}',
      }).toList();

      await ApiService.createEvent(
        token: token,
        name: _nameCtrl.text.trim(),
        type: _selectedType.name,
        date: dateStr,
        location: _locationCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        categories: categoriesData,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ Événement créé ! Les QR codes ont été générés.'),
          backgroundColor: AppColors.statusActive,
        ));
        context.go('/admin/events');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvel événement'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/admin/events'),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Infos générales ──
              _FieldLabel('Nom de l\'événement'),
              TextFormField(
                controller: _nameCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                    hintText: 'Ex: Foire de Cotonou 2025'),
                validator: (v) =>
                v == null || v.isEmpty ? 'Champ requis' : null,
              ),
              const SizedBox(height: 20),

              _FieldLabel('Type d\'événement'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<EventType>(
                    value: _selectedType,
                    isExpanded: true,
                    dropdownColor: AppColors.surface,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 14),
                    items: EventType.values
                        .map((t) => DropdownMenuItem(
                        value: t, child: Text(t.label)))
                        .toList(),
                    onChanged: (t) =>
                        setState(() => _selectedType = t!),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              _FieldLabel('Date de l\'événement'),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(children: [
                    const Icon(Icons.calendar_today_outlined,
                        color: AppColors.textTertiary, size: 18),
                    const SizedBox(width: 12),
                    Text(
                      _formatDate(_selectedDate),
                      style: TextStyle(
                        color: _selectedDate == null
                            ? AppColors.textTertiary
                            : AppColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 20),

              _FieldLabel('Lieu'),
              TextFormField(
                controller: _locationCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                    hintText: 'Ex: Stade de l\'Amitié'),
                validator: (v) =>
                v == null || v.isEmpty ? 'Champ requis' : null,
              ),
              const SizedBox(height: 20),

              _FieldLabel('Description (optionnel)'),
              TextFormField(
                controller: _descCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                    hintText: 'Décrivez l\'événement...'),
                maxLines: 3,
              ),

              const SizedBox(height: 32),

              // ── Catégories de tickets ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Catégories de tickets',
                      style: AppTextStyles.sectionTitle),
                  TextButton.icon(
                    onPressed: _addCategory,
                    icon: const Icon(Icons.add_rounded,
                        color: AppColors.primary, size: 18),
                    label: const Text('Ajouter',
                        style: TextStyle(color: AppColors.primary)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Par défaut une seule catégorie suffit. '
                    'Ajoutez-en d\'autres pour VIP, Carré OR, etc.',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 16),

              // Liste des catégories
              ...List.generate(_categories.length, (i) =>
                  _CategoryCard(
                    index: i,
                    cat: _categories[i],
                    total: _categories.length,
                    availableColors: _availableColors,
                    onRemove: () => _removeCategory(i),
                    onPickFrom: () => _pickCategoryDate(i, true),
                    onPickTo: () => _pickCategoryDate(i, false),
                    onColorChange: (hex) =>
                        setState(() => _categories[i].color = hex),
                    formatDate: _formatDate,
                    hexToColor: _hexToColor,
                  ),
              ),

              const SizedBox(height: 16),

              // Info box
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.iconBlueBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(children: [
                  Icon(Icons.info_outline_rounded,
                      color: AppColors.iconBlue, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Les QR codes seront générés automatiquement '
                          'pour chaque catégorie. '
                          'Vous pourrez les exporter en Word pour impression.',
                      style:
                      TextStyle(color: AppColors.iconBlue, fontSize: 12),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                      : const Text('Créer et générer les QR codes'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Widget carte d'une catégorie ──
class _CategoryCard extends StatelessWidget {
  final int index;
  final _CategoryForm cat;
  final int total;
  final List<Map<String, dynamic>> availableColors;
  final VoidCallback onRemove;
  final VoidCallback onPickFrom;
  final VoidCallback onPickTo;
  final Function(String) onColorChange;
  final String Function(DateTime?) formatDate;
  final Color Function(String) hexToColor;

  const _CategoryCard({
    required this.index,
    required this.cat,
    required this.total,
    required this.availableColors,
    required this.onRemove,
    required this.onPickFrom,
    required this.onPickTo,
    required this.onColorChange,
    required this.formatDate,
    required this.hexToColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Header catégorie
          Row(
            children: [
              // Bande colorée
              Container(
                width: 4, height: 40,
                decoration: BoxDecoration(
                  color: hexToColor(cat.color),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  index == 0 && total == 1
                      ? 'Catégorie unique'
                      : 'Catégorie ${index + 1}',
                  style: AppTextStyles.sectionTitle,
                ),
              ),
              // Bouton supprimer (sauf si c'est la seule)
              if (total > 1)
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: AppColors.statusSuspended, size: 20),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Nom de la catégorie
          const Text('Nom', style: TextStyle(
              fontSize: 12, color: AppColors.textSecondary,
              fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          TextFormField(
            controller: cat.nameCtrl,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              hintText: 'Ex: Standard, VIP, Carré OR...',
              contentPadding:
              EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
          const SizedBox(height: 14),

          // Prix + Quota sur la même ligne
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Prix (FCFA)', style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: cat.priceCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        hintText: '2000',
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Requis';
                        final n = int.tryParse(v);
                        if (n == null || n < 0) return 'Invalide';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Nombre de tickets', style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: cat.quotaCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        hintText: '500',
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Requis';
                        final n = int.tryParse(v);
                        if (n == null || n <= 0) return 'Invalide';
                        if (n > 10000) return 'Max 10 000';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Validité du X au Y
          const Text('Période de validité', style: TextStyle(
              fontSize: 12, color: AppColors.textSecondary,
              fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onPickFrom,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 14, color: AppColors.textTertiary),
                      const SizedBox(width: 6),
                      Text(
                        formatDate(cat.validFrom),
                        style: TextStyle(
                          fontSize: 13,
                          color: cat.validFrom == null
                              ? AppColors.textTertiary
                              : AppColors.textPrimary,
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('→', style: TextStyle(
                    color: AppColors.textSecondary)),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: onPickTo,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 14, color: AppColors.textTertiary),
                      const SizedBox(width: 6),
                      Text(
                        formatDate(cat.validTo),
                        style: TextStyle(
                          fontSize: 13,
                          color: cat.validTo == null
                              ? AppColors.textTertiary
                              : AppColors.textPrimary,
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Couleur de la bande
          const Text('Couleur du ticket', style: TextStyle(
              fontSize: 12, color: AppColors.textSecondary,
              fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: availableColors.map((c) {
              final isSelected = cat.color == c['hex'];
              return GestureDetector(
                onTap: () => onColorChange(c['hex']),
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: Color(int.parse(
                        'FF${c['hex'].replaceAll('#', '')}',
                        radix: 16)),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? Colors.white
                          : Colors.transparent,
                      width: 2.5,
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.4),
                        blurRadius: 4,
                      )
                    ] : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 16)
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

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
                      Row(children: [
                        _MiniStat(
                          label: 'Événements',
                          value: '${_events.length}',
                        ),
                        _MiniStat(
                          label: 'Générés',
                          value: '$totalQuota',
                        ),
                        _MiniStat(
                          label: 'Vendus',
                          value: '$totalSold',
                        ),
                        _MiniStat(
                          label: 'Entrées',
                          value: '$totalUsed',
                        ),
                      ]),
                      const SizedBox(height: 14),

                      // Barre de progression globale
                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Taux de vente global',
                              style: AppTextStyles.caption),
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
        AvatarCircle(name: userName, size: 38),
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

        // Barre de progression
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

        // Boutons
        Row(children: [
          Expanded(
            child: SizedBox(
              height: 36,
              child: ElevatedButton.icon(
                onPressed: () {
                  context.go(
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
                  context.go(
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
          _MiniStat(label: 'Quota', value: event.ticketQuota.toString()),
          _MiniStat(label: 'Vendus', value: event.ticketsSold.toString()),
          _MiniStat(label: 'Entrées', value: event.ticketsUsed.toString()),
          _MiniStat(label: 'Taux', value: '${event.soldPercentage.toStringAsFixed(0)}%'),
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
  Widget build(BuildContext context) => Expanded(
    child: Column(children: [
      Text(value, style: const TextStyle(
          color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 2),
      Text(label, style: AppTextStyles.caption),
    ]),
  );
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

IconData _eventIcon(EventType type) {
  switch (type) {
    case EventType.concert:  return Icons.music_note_outlined;
    case EventType.foire:    return Icons.storefront_outlined;
    case EventType.marche:   return Icons.shopping_basket_outlined;
    case EventType.festival: return Icons.celebration_outlined;
    case EventType.autre:    return Icons.event_outlined;
  }
}