// lib/features/admin/presentation/agents_screen.dart
//
// ════════════════════════════════════════════════════════
// PAGE MES AGENTS — Interface Admin
// ════════════════════════════════════════════════════════
//
// L'Admin voit ici tous ses agents de contrôle.
// Il peut :
//   - Voir la liste de ses agents
//   - Créer un nouvel agent (nom + email + mot de passe)
//   - Supprimer un agent
//
// Quand un agent est créé → email envoyé automatiquement
// avec ses identifiants de connexion.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../shared/widgets/avatar_circle.dart';

// ════════════════════════════════════════════════════════
// MODÈLE LOCAL — un agent
// ════════════════════════════════════════════════════════
class AgentModel {
  final int id;
  final String name;
  final String email;
  final String status;
  final String createdAt;

  const AgentModel({
    required this.id,
    required this.name,
    required this.email,
    required this.status,
    required this.createdAt,
  });

  factory AgentModel.fromJson(Map<String, dynamic> json) {
    return AgentModel(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      status: json['status'] as String,
      createdAt: json['createdAt'] as String,
    );
  }

  bool get isActive => status == 'ACTIVE';
}

// ════════════════════════════════════════════════════════
// ÉCRAN PRINCIPAL
// ════════════════════════════════════════════════════════
class AgentsScreen extends ConsumerStatefulWidget {
  const AgentsScreen({super.key});

  @override
  ConsumerState<AgentsScreen> createState() => _AgentsScreenState();
}

class _AgentsScreenState extends ConsumerState<AgentsScreen> {
  List<AgentModel> _agents = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAgents();
  }

  // ── Charge les agents depuis le backend ──
  Future<void> _loadAgents() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final token = ref.read(authStateProvider).token!;
      final data = await ApiService.getMyAgents(token);
      setState(() {
        _agents = data
            .map((a) => AgentModel.fromJson(a as Map<String, dynamic>))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  // ── Supprime un agent avec confirmation ──
  Future<void> _deleteAgent(AgentModel agent) async {
    // Demande confirmation avant de supprimer
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Supprimer cet agent ?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          '${agent.name} ne pourra plus accéder à l\'application.',
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
      await ApiService.deleteAgent(token, agent.id);

      // Recharge la liste après suppression
      await _loadAgents();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${agent.name} supprimé'),
          backgroundColor: AppColors.statusSuspended,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
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

  // ── Ouvre le formulaire de création d'agent ──
  void _showCreateAgentSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true, // permet au sheet de prendre plus de hauteur
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _CreateAgentSheet(
        // Callback appelé quand l'agent est créé avec succès
        onAgentCreated: () {
          Navigator.pop(ctx);
          _loadAgents(); // recharge la liste
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── En-tête ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  const Text('Mes Agents',
                      style: AppTextStyles.screenTitle),
                  const Spacer(),
                  // Bouton créer un agent
                  GestureDetector(
                    onTap: _showCreateAgentSheet,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(children: [
                        Icon(Icons.add_rounded,
                            color: Colors.white, size: 18),
                        SizedBox(width: 4),
                        Text('Nouvel agent',
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

            const SizedBox(height: 8),

            // Sous-titre
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Vos agents reçoivent leurs identifiants par email',
                  style: AppTextStyles.adminSubtitle,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Contenu principal ──
            Expanded(
              child: _isLoading
                  ? const Center(
                  child: CircularProgressIndicator(
                      color: AppColors.primary))
                  : _error != null
                  ? _buildErrorState()
                  : _agents.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                onRefresh: _loadAgents,
                color: AppColors.primary,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                      20, 0, 20, 24),
                  itemCount: _agents.length,
                  separatorBuilder: (_, __) =>
                  const SizedBox(height: 10),
                  itemBuilder: (_, i) => _AgentTile(
                    agent: _agents[i],
                    onDelete: () =>
                        _deleteAgent(_agents[i]),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── État vide ──
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.people_outline_rounded,
                color: AppColors.textTertiary, size: 40),
          ),
          const SizedBox(height: 16),
          const Text('Aucun agent pour l\'instant',
              style: AppTextStyles.sectionTitle),
          const SizedBox(height: 8),
          const Text(
            'Créez vos agents de contrôle.\nIls recevront leurs identifiants par email.',
            style: AppTextStyles.adminSubtitle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showCreateAgentSheet,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Créer mon premier agent'),
          ),
        ],
      ),
    );
  }

  // ── État erreur ──
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded,
              color: AppColors.textTertiary, size: 48),
          const SizedBox(height: 12),
          Text(_error!, style: AppTextStyles.adminSubtitle),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadAgents,
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════
// TUILE D'UN AGENT
// ════════════════════════════════════════════════════════
class _AgentTile extends StatelessWidget {
  final AgentModel agent;
  final VoidCallback onDelete;

  const _AgentTile({
    required this.agent,
    required this.onDelete,
  });

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
        // Avatar avec initiales
        AvatarCircle(name: agent.name, size: 44),
        const SizedBox(width: 12),

        // Nom + email
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(agent.name, style: AppTextStyles.adminName),
              const SizedBox(height: 2),
              Text(agent.email, style: AppTextStyles.adminSubtitle),
            ],
          ),
        ),

        // Badge statut
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: agent.isActive
                ? AppColors.statusActiveBackground
                : AppColors.statusSuspendedBackground,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            agent.isActive ? 'Actif' : 'Suspendu',
            style: TextStyle(
              color: agent.isActive
                  ? AppColors.statusActive
                  : AppColors.statusSuspended,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        const SizedBox(width: 8),

        // Bouton supprimer
        IconButton(
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline_rounded,
              color: AppColors.statusSuspended, size: 20),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.statusSuspendedBackground,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ]),
    );
  }
}

// ════════════════════════════════════════════════════════
// FORMULAIRE DE CRÉATION D'AGENT (bottom sheet)
// ════════════════════════════════════════════════════════
class _CreateAgentSheet extends ConsumerStatefulWidget {
  final VoidCallback onAgentCreated;

  const _CreateAgentSheet({required this.onAgentCreated});

  @override
  ConsumerState<_CreateAgentSheet> createState() =>
      _CreateAgentSheetState();
}

class _CreateAgentSheetState extends ConsumerState<_CreateAgentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final token = ref.read(authStateProvider).token!;
      await ApiService.createAgent(
        token: token,
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        phone: _phoneCtrl.text.trim(),
      );

      if (mounted) {
        // Affiche un message de succès
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            '${_nameCtrl.text} créé ! Email envoyé avec les identifiants.',
          ),
          backgroundColor: AppColors.statusActive,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ));

        // Ferme le sheet et recharge la liste
        widget.onAgentCreated();
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
    // padding pour éviter que le clavier cache le formulaire
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomPadding),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Barre grise en haut
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Titre
            const Text('Nouvel agent',
                style: AppTextStyles.sectionTitle),
            const SizedBox(height: 4),
            const Text(
              'L\'agent recevra ses identifiants par email automatiquement.',
              style: AppTextStyles.adminSubtitle,
            ),
            const SizedBox(height: 24),

            // Champ nom
            _FieldLabel('Nom complet'),
            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Ex: Kouassi Jean',
                prefixIcon: Icon(Icons.person_outline_rounded,
                    color: AppColors.textTertiary, size: 20),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Champ requis';
                if (v.trim().length < 3) return 'Nom trop court';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Champ email
            _FieldLabel('Adresse email'),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Ex: kouassi@gmail.com',
                prefixIcon: Icon(Icons.mail_outline_rounded,
                    color: AppColors.textTertiary, size: 20),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Champ requis';
                if (!v.contains('@')) return 'Email invalide';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Ajoute le champ dans le formulaire après l'email
            _FieldLabel('Numéro WhatsApp'),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Ex: +22901234567',
                prefixIcon: Icon(Icons.phone_outlined,
                    color: AppColors.textTertiary, size: 20),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Champ requis';
                return null;
              },
            ),

            const SizedBox(height: 16),
            // Champ mot de passe
            _FieldLabel('Mot de passe temporaire'),
            TextFormField(
              controller: _passwordCtrl,
              obscureText: _obscurePassword,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Minimum 6 caractères',
                prefixIcon: const Icon(Icons.lock_outline_rounded,
                    color: AppColors.textTertiary, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.textTertiary,
                    size: 20,
                  ),
                  onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Champ requis';
                if (v.length < 6) return 'Minimum 6 caractères';
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Info box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.iconBlueBackground,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(children: [
                Icon(Icons.info_outline_rounded,
                    color: AppColors.iconBlue, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Un email avec les identifiants sera envoyé '
                        'automatiquement à l\'agent.',
                    style: TextStyle(
                        color: AppColors.iconBlue, fontSize: 12),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 20),

            // Bouton créer
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
                    : const Text('Créer l\'agent'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Label de champ
class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary)),
  );
}