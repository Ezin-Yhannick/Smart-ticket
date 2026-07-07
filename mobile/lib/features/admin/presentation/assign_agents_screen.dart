// lib/features/admin/presentation/assign_agents_screen.dart
//
// ════════════════════════════════════════════════════════
// PAGE D'ASSIGNATION DES AGENTS À UN ÉVÉNEMENT
// ════════════════════════════════════════════════════════
//
// L'Admin voit ici tous ses agents avec des checkboxes.
// Il coche les agents qu'il veut assigner à l'événement.
// Quand il valide → email + WhatsApp envoyés aux agents assignés.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../shared/widgets/avatar_circle.dart';
import '../../../shared/models/event_model.dart';
import 'package:go_router/go_router.dart';

class AssignAgentsScreen extends ConsumerStatefulWidget {
  final EventModel event;

  const AssignAgentsScreen({super.key, required this.event});

  @override
  ConsumerState<AssignAgentsScreen> createState() =>
      _AssignAgentsScreenState();
}

class _AssignAgentsScreenState extends ConsumerState<AssignAgentsScreen> {

  // Tous les agents de l'Admin
  List<_AgentItem> _allAgents = [];

  // IDs des agents déjà assignés à cet événement
  Set<int> _assignedAgentIds = {};

  // IDs sélectionnés dans les checkboxes (état local)
  Set<int> _selectedIds = {};

  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ── Charge les agents + ceux déjà assignés ──
  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final token = ref.read(authStateProvider).token!;

      // Charge tous les agents de l'Admin
      final allData = await ApiService.getMyAgents(token);

      // Charge les agents déjà assignés à cet événement
      final assignedData = await ApiService.getEventAgents(
          token, widget.event.id);

      final assignedIds = assignedData
          .map((a) => a['id'] as int)
          .toSet();

      setState(() {
        _allAgents = allData.map((a) => _AgentItem(
          id: a['id'] as int,
          name: a['name'] as String,
          email: a['email'] as String,
          status: a['status'] as String,
        )).toList();

        _assignedAgentIds = assignedIds;
        // Préselectionne les agents déjà assignés
        _selectedIds = Set.from(assignedIds);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  // ── Sauvegarde les assignations ──
  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final token = ref.read(authStateProvider).token!;

      // Agents à assigner (nouveaux seulement)
      final toAssign = _selectedIds
          .where((id) => !_assignedAgentIds.contains(id))
          .toList();

      // Agents à désassigner
      final toUnassign = _assignedAgentIds
          .where((id) => !_selectedIds.contains(id))
          .toList();

      // Assigne les nouveaux
      if (toAssign.isNotEmpty) {
        await ApiService.assignAgents(
            token, widget.event.id, toAssign);
      }

      // Désassigne les retirés
      for (final agentId in toUnassign) {
        await ApiService.unassignAgent(
            token, widget.event.id, agentId);
      }

      if (mounted) {
        // Message de succès
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            toAssign.isEmpty && toUnassign.isEmpty
                ? 'Aucune modification'
                : '${toAssign.length} agent(s) assigné(s), '
                '${toUnassign.length} retiré(s). '
                'Emails et WhatsApp envoyés !',
          ),
          backgroundColor: AppColors.statusActive,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Nombre d'agents sélectionnés
    final selectedCount = _selectedIds.length;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Assigner des agents',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600)),
            Text(widget.event.name,
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary)),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator(
          color: AppColors.primary))
          : _error != null
          ? _buildErrorState()
          : _allAgents.isEmpty
          ? _buildEmptyState()
          : Column(
        children: [
          // Info bar
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 12),
            color: AppColors.iconBlueBackground,
            child: Row(children: [
              const Icon(Icons.info_outline_rounded,
                  color: AppColors.iconBlue, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$selectedCount agent(s) sélectionné(s) '
                      'pour "${widget.event.name}"',
                  style: const TextStyle(
                      color: AppColors.iconBlue,
                      fontSize: 13),
                ),
              ),
            ]),
          ),

          // Liste des agents avec checkboxes
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _allAgents.length,
              separatorBuilder: (_, __) =>
              const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final agent = _allAgents[i];
                final isSelected =
                _selectedIds.contains(agent.id);
                final wasAssigned =
                _assignedAgentIds.contains(agent.id);

                return _AgentCheckTile(
                  agent: agent,
                  isSelected: isSelected,
                  wasAssigned: wasAssigned,
                  onChanged: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedIds.add(agent.id);
                      } else {
                        _selectedIds.remove(agent.id);
                      }
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),

      // Bouton de validation en bas
      bottomNavigationBar: _allAgents.isEmpty || _isLoading
          ? null
          : Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: const Border(
              top: BorderSide(
                  color: AppColors.border, width: 0.5)),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
                : Text(
              'Valider ($selectedCount agent(s))',
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }

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
          const Text('Aucun agent disponible',
              style: AppTextStyles.sectionTitle),
          const SizedBox(height: 8),
          const Text(
            'Créez d\'abord des agents dans\nl\'onglet "Mes Agents".',
            style: AppTextStyles.adminSubtitle,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

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
            onPressed: _loadData,
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════
// MODÈLE LOCAL
// ════════════════════════════════════════════════════════
class _AgentItem {
  final int id;
  final String name;
  final String email;
  final String status;

  const _AgentItem({
    required this.id,
    required this.name,
    required this.email,
    required this.status,
  });
}

// ════════════════════════════════════════════════════════
// TUILE D'UN AGENT AVEC CHECKBOX
// ════════════════════════════════════════════════════════
class _AgentCheckTile extends StatelessWidget {
  final _AgentItem agent;
  final bool isSelected;
  final bool wasAssigned; // était déjà assigné avant
  final ValueChanged<bool> onChanged;

  const _AgentCheckTile({
    required this.agent,
    required this.isSelected,
    required this.wasAssigned,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!isSelected),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          // Fond bleu si sélectionné
          color: isSelected
              ? AppColors.primary.withOpacity(0.08)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppColors.primary.withOpacity(0.5)
                : AppColors.border,
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Row(children: [
          // Avatar
          AvatarCircle(name: agent.name, size: 44),
          const SizedBox(width: 12),

          // Nom + email
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(agent.name, style: AppTextStyles.adminName),
                const SizedBox(height: 2),
                Text(agent.email,
                    style: AppTextStyles.adminSubtitle),

                // Badge "Déjà assigné" si applicable
                if (wasAssigned) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.statusActiveBackground,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Déjà assigné',
                      style: TextStyle(
                          color: AppColors.statusActive,
                          fontSize: 10,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Checkbox personnalisée
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 24, height: 24,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.textTertiary,
                width: 1.5,
              ),
            ),
            child: isSelected
                ? const Icon(Icons.check_rounded,
                color: Colors.white, size: 16)
                : null,
          ),
        ]),
      ),
    );
  }
}