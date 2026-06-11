// lib/features/super_admin/presentation/super_admin_admins_screen.dart
//
// La page "Admins" du Super-Admin (Écran 2 de tes maquettes).
// Contient : bouton + nouvel admin, barre de recherche, filtres par statut,
// et la liste complète des admins avec boutons d'action.
part of 'super_admin_shell.dart';

class SuperAdminAdminsScreen extends ConsumerStatefulWidget {
  const SuperAdminAdminsScreen({super.key});

  @override
  ConsumerState<SuperAdminAdminsScreen> createState() =>
      _SuperAdminAdminsScreenState();
}

class _SuperAdminAdminsScreenState
    extends ConsumerState<SuperAdminAdminsScreen> {

  final _searchController = TextEditingController();
  AdminStatus? _filterStatus;
  String _searchQuery = '';
  List<AdminModel> _allAdmins = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAdmins();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAdmins() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final token = ref.read(authStateProvider).token!;
      final data = await ApiService.getAllAdmins(token);
      setState(() {
        _allAdmins = data.map((a) => AdminModel(
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

  List<AdminModel> get _filteredAdmins {
    return _allAdmins.where((admin) {
      final matchesSearch = _searchQuery.isEmpty ||
          admin.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          admin.email.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesFilter =
          _filterStatus == null || admin.status == _filterStatus;
      return matchesSearch && matchesFilter;
    }).toList();
  }

  int _countByStatus(AdminStatus? status) {
    if (status == null) return _allAdmins.length;
    return _allAdmins.where((a) => a.status == status).length;
  }

  Future<void> _suspendAdmin(AdminModel admin) async {
    try {
      final token = ref.read(authStateProvider).token!;
      await ApiService.suspendAdmin(token, int.parse(admin.id));
      await _loadAdmins();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${admin.name} suspendu'),
          backgroundColor: AppColors.statusSuspended,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<void> _activateAdmin(AdminModel admin) async {
    try {
      final token = ref.read(authStateProvider).token!;
      await ApiService.activateAdmin(token, int.parse(admin.id));
      await _loadAdmins();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${admin.name} activé'),
          backgroundColor: AppColors.statusActive,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<void> _deleteAdmin(AdminModel admin) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Supprimer cet admin ?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'Le compte de ${admin.name} sera supprimé définitivement.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer',
                style: TextStyle(
                    color: AppColors.statusSuspended,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final token = ref.read(authStateProvider).token!;
      await ApiService.deleteAdmin(token, int.parse(admin.id));
      await _loadAdmins();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${admin.name} supprimé'),
          backgroundColor: AppColors.statusSuspended,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredAdmins;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // AppBar
            Padding(
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

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off_rounded,
                        color: AppColors.textTertiary,
                        size: 48),
                    const SizedBox(height: 12),
                    Text(_error!,
                        style: AppTextStyles.adminSubtitle),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadAdmins,
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              )
                  : RefreshIndicator(
                onRefresh: _loadAdmins,
                color: AppColors.primary,
                child: SingleChildScrollView(
                  physics:
                  const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),

                      // Bouton créer
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () => context.go(
                              '/super-admin/admins/create'),
                          icon: const Icon(Icons.add_rounded,
                              size: 20),
                          label: const Text(
                              'Nouvel administrateur'),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Recherche
                      TextField(
                        controller: _searchController,
                        onChanged: (v) =>
                            setState(() => _searchQuery = v),
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'Rechercher...',
                          prefixIcon: Icon(Icons.search_rounded,
                              color: AppColors.textTertiary,
                              size: 20),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Filtres
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(children: [
                          _FilterChip(
                            label: 'Tous',
                            count: _countByStatus(null),
                            isSelected: _filterStatus == null,
                            onTap: () => setState(
                                    () => _filterStatus = null),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Actifs',
                            count: _countByStatus(
                                AdminStatus.active),
                            isSelected: _filterStatus ==
                                AdminStatus.active,
                            onTap: () => setState(() =>
                            _filterStatus =
                                AdminStatus.active),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Suspendus',
                            count: _countByStatus(
                                AdminStatus.suspended),
                            isSelected: _filterStatus ==
                                AdminStatus.suspended,
                            onTap: () => setState(() =>
                            _filterStatus =
                                AdminStatus.suspended),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 16),

                      // Liste
                      ...filtered.map((admin) => Padding(
                        padding: const EdgeInsets.only(
                            bottom: 12),
                        child: _AdminDetailCard(
                          admin: admin,
                          onSuspend: () =>
                              _suspendAdmin(admin),
                          onActivate: () =>
                              _activateAdmin(admin),
                          onDelete: () =>
                              _deleteAdmin(admin),
                        ),
                      )),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminDetailCard extends StatelessWidget {
  final AdminModel admin;
  final VoidCallback onSuspend;
  final VoidCallback onActivate;
  final VoidCallback onDelete;

  const _AdminDetailCard({
    required this.admin,
    required this.onSuspend,
    required this.onActivate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(children: [
        Row(children: [
          AvatarCircle(name: admin.name, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(admin.name, style: AppTextStyles.adminName),
                const SizedBox(height: 2),
                Text(admin.email, style: AppTextStyles.adminSubtitle),
              ],
            ),
          ),
          StatusBadge(status: admin.status),
        ]),

        if (admin.eventsCount > 0) ...[
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),
          Row(children: [
            _StatMini(
                label: 'Événements',
                value: admin.eventsCount.toString()),
            _Separator(),
            _StatMini(
                label: 'Tickets',
                value: admin.ticketsCount.toString()),
          ]),
        ],

        const SizedBox(height: 14),

        Row(children: [
          if (admin.status == AdminStatus.active)
            Expanded(
              child: SizedBox(
                height: 38,
                child: OutlinedButton(
                  onPressed: onSuspend,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.statusSuspended,
                    side: BorderSide(
                        color: AppColors.statusSuspended
                            .withOpacity(0.4)),
                  ),
                  child: const Text('Suspendre',
                      style: AppTextStyles.buttonText),
                ),
              ),
            )
          else
            Expanded(
              child: SizedBox(
                height: 38,
                child: ElevatedButton(
                  onPressed: onActivate,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.statusActive),
                  child: const Text('Activer',
                      style: AppTextStyles.buttonText),
                ),
              ),
            ),

          const SizedBox(width: 8),

          SizedBox(
            height: 38,
            child: IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.statusSuspended, size: 20),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.statusSuspendedBackground,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ]),
      ]),
    );
  }
}

class _StatMini extends StatelessWidget {
  final String label;
  final String value;
  const _StatMini({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(children: [
      Text(value, style: const TextStyle(
          color: AppColors.textPrimary, fontSize: 15,
          fontWeight: FontWeight.w700)),
      const SizedBox(height: 2),
      Text(label, style: AppTextStyles.caption),
    ]),
  );
}

class _Separator extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
      width: 0.5, height: 30, color: AppColors.border);
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label, required this.count,
    required this.isSelected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary
            : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text('$label ($count)',
          style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w500,
              color: isSelected
                  ? Colors.white
                  : AppColors.textSecondary)),
    ),
  );
}