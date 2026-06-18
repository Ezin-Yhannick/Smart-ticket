part of 'admin_shell.dart';


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
