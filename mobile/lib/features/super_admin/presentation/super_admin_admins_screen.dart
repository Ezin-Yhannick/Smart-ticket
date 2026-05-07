// lib/features/super_admin/presentation/super_admin_admins_screen.dart
//
// La page "Admins" du Super-Admin (Écran 2 de tes maquettes).
// Contient : bouton + nouvel admin, barre de recherche, filtres par statut,
// et la liste complète des admins avec boutons d'action.

part of 'super_admin_shell.dart';

class SuperAdminAdminsScreen extends StatefulWidget {
  const SuperAdminAdminsScreen({super.key});

  @override
  State<SuperAdminAdminsScreen> createState() => _SuperAdminAdminsScreenState();
}

class _SuperAdminAdminsScreenState extends State<SuperAdminAdminsScreen> {
  final _searchController = TextEditingController();
  AdminStatus? _filterStatus; // null = "Tous"
  String _searchQuery = '';

  // Données de démonstration
  final List<AdminModel> _allAdmins = [
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
      ticketsCount: 612,
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
    AdminModel(
      id: '4',
      name: 'BOCO Melina',
      email: 'b.melina@foire.bj',
      status: AdminStatus.active,
      eventsCount: 5,
      ticketsCount: 320,
      revenue: 450000,
    ),
    AdminModel(
      id: '5',
      name: 'EZIN Yannick',
      email: 'e.yannick@events.bj',
      status: AdminStatus.suspended,
      eventsCount: 3,
      ticketsCount: 180,
      revenue: 220000,
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Filtre les admins selon la recherche et le filtre de statut actif
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

  // Compte les admins par statut pour les badges des filtres
  int _countByStatus(AdminStatus? status) {
    if (status == null) return _allAdmins.length;
    return _allAdmins.where((a) => a.status == status).length;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredAdmins;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // --- App Bar ---
            _buildAppBar(),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 16),

                    // --- Bouton + Nouvel administrateur ---
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // TODO: ouvrir le dialog de création d'admin
                          _showCreateAdminDialog(context);
                        },
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: const Text('Nouvel administrateur'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.surface,
                          foregroundColor: AppColors.textPrimary,
                          side: const BorderSide(
                              color: AppColors.border, width: 0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // --- Barre de recherche + bouton Filtrer ---
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (v) =>
                                setState(() => _searchQuery = v),
                            style: const TextStyle(
                                color: AppColors.textPrimary, fontSize: 14),
                            decoration: const InputDecoration(
                              hintText: 'Rechercher...',
                              prefixIcon: Icon(Icons.search_rounded,
                                  color: AppColors.textTertiary, size: 20),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.filter_list_rounded,
                                  color: AppColors.textSecondary, size: 18),
                              SizedBox(width: 6),
                              Text('Filtrer',
                                  style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // --- Filtres par statut (chips horizontaux) ---
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _FilterChip(
                            label: 'Tous',
                            count: _countByStatus(null),
                            isSelected: _filterStatus == null,
                            onTap: () =>
                                setState(() => _filterStatus = null),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Actifs',
                            count: _countByStatus(AdminStatus.active),
                            isSelected: _filterStatus == AdminStatus.active,
                            onTap: () => setState(
                                    () => _filterStatus = AdminStatus.active),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Attente',
                            count: _countByStatus(AdminStatus.pending),
                            isSelected: _filterStatus == AdminStatus.pending,
                            onTap: () => setState(
                                    () => _filterStatus = AdminStatus.pending),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Suspendus',
                            count: _countByStatus(AdminStatus.suspended),
                            isSelected:
                            _filterStatus == AdminStatus.suspended,
                            onTap: () => setState(
                                    () => _filterStatus = AdminStatus.suspended),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // --- Liste des admins filtrés ---
                    ...filtered.map((admin) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _AdminDetailCard(admin: admin),
                    )),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // App bar réutilisant le même style que le Dashboard
  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
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
        ],
      ),
    );
  }

  void _showCreateAdminDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Nouvel administrateur',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'Cette fonctionnalité sera connectée au backend.\nPour l\'instant, c\'est un placeholder.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fermer',
                style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

// --- Carte détaillée d'un admin (avec boutons d'action) ---
class _AdminDetailCard extends StatelessWidget {
  final AdminModel admin;
  const _AdminDetailCard({required this.admin});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          // En-tête : avatar + nom + email + badge statut
          Row(
            children: [
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
            ],
          ),

          // Stats de l'admin (événements, tickets, FCFA)
          if (admin.eventsCount > 0) ...[
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),
            Row(
              children: [
                _StatMini(
                    label: 'Événements',
                    value: admin.eventsCount.toString()),
                _Separator(),
                _StatMini(
                    label: 'Tickets',
                    value: admin.ticketsCount.toString()),
                _Separator(),
                _StatMini(label: 'FCFA', value: admin.revenueFormatted),
              ],
            ),
          ],

          const SizedBox(height: 14),

          // Boutons d'action selon le statut
          Row(
            children: [
              // "Voir détail" toujours visible
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: ElevatedButton(
                    onPressed: () {},
                    child: const Text('Voir détail',
                        style: AppTextStyles.buttonText),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Bouton contextuel selon le statut
              if (admin.status == AdminStatus.active) ...[
                Expanded(
                  child: SizedBox(
                    height: 38,
                    child: OutlinedButton(
                      onPressed: () {},
                      child: const Text('Modifier',
                          style: AppTextStyles.buttonText),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 38,
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.statusSuspended,
                        side: BorderSide(
                            color: AppColors.statusSuspended.withOpacity(0.4)),
                      ),
                      child: const Text('Suspendre',
                          style: AppTextStyles.buttonText),
                    ),
                  ),
                ),
              ] else if (admin.status == AdminStatus.pending) ...[
                Expanded(
                  child: SizedBox(
                    height: 38,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.buttonSuccess),
                      child: const Text('Valider',
                          style: AppTextStyles.buttonText),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 38,
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.statusSuspended,
                        side: BorderSide(
                            color: AppColors.statusSuspended.withOpacity(0.4)),
                      ),
                      child: const Text('Rejeter',
                          style: AppTextStyles.buttonText),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// Petite stat centrée (Événements / Tickets / FCFA)
class _StatMini extends StatelessWidget {
  final String label;
  final String value;
  const _StatMini({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              )),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

// Séparateur vertical entre les stats
class _Separator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 0.5,
      height: 30,
      color: AppColors.border,
    );
  }
}

// Chip de filtre (Tous / Actifs / Attente / Suspendus)
class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '$label ($count)',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}