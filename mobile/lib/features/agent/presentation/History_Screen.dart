// lib/features/agent/presentation/history_screen.dart
//
// ════════════════════════════════════════════════════════
// ÉCRAN HISTORIQUE DES SCANS
// ════════════════════════════════════════════════════════
//
// Cet écran remplace le placeholder dans AgentHistoryPage.
//
// Il affiche tous les tickets scannés pendant la session
// en cours. L'historique est partagé avec l'écran de scan
// via le provider scanHistoryProvider (défini dans agent_shell.dart).
//
// Quand l'agent ferme l'app, l'historique est perdu.
// C'est voulu : chaque session de contrôle est indépendante.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../shared/models/ticket_model.dart';
import 'agent_shell.dart'; // pour ScanRecord et scanHistoryProvider

// ════════════════════════════════════════════════════════
// ÉCRAN PRINCIPAL
// ════════════════════════════════════════════════════════
//
// On utilise ConsumerWidget (et non StatelessWidget)
// parce qu'on a besoin de ref.watch() pour lire
// l'historique depuis le provider Riverpod.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // On écoute le provider — chaque nouveau scan
    // met automatiquement à jour cet écran
    final history = ref.watch(scanHistoryProvider);

    // Compteurs calculés depuis la liste complète
    final totalScans = history.length;
    final validCount = history
        .where((r) => r.result == ScanStatus.valide)
        .length;
    final duplicateCount = history
        .where((r) => r.result == ScanStatus.dejaScanne)
        .length;
    final fraudCount = history
        .where((r) => r.result == ScanStatus.fraude)
        .length;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── En-tête ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  const Text('Historique',
                      style: AppTextStyles.screenTitle),
                  const Spacer(),

                  // Bouton effacer — visible seulement s'il y a des scans
                  if (history.isNotEmpty)
                    TextButton.icon(
                      onPressed: () => _confirmClear(context, ref),
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        size: 16,
                        color: AppColors.statusSuspended,
                      ),
                      label: const Text(
                        'Effacer',
                        style: TextStyle(
                          color: AppColors.statusSuspended,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Compteurs de la session ──
            // Affichés seulement s'il y a au moins un scan
            if (history.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _CounterCard(
                      value: totalScans,
                      label: 'Total',
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    _CounterCard(
                      value: validCount,
                      label: 'Valides',
                      color: AppColors.statusActive,
                    ),
                    const SizedBox(width: 8),
                    _CounterCard(
                      value: duplicateCount,
                      label: 'Doublons',
                      color: AppColors.statusPending,
                    ),
                    const SizedBox(width: 8),
                    _CounterCard(
                      value: fraudCount,
                      label: 'Fraudes',
                      color: AppColors.statusSuspended,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Liste ou message vide ──
            Expanded(
              child: history.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                itemCount: history.length,
                separatorBuilder: (_, __) =>
                const SizedBox(height: 8),
                itemBuilder: (_, i) =>
                    _ScanTile(record: history[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Message quand aucun scan n'a été fait ──
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icône
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.history_rounded,
              color: AppColors.textTertiary,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            'Aucun scan pour cette session',
            style: AppTextStyles.sectionTitle,
          ),
          const SizedBox(height: 8),

          const Text(
            'Les tickets scannés apparaîtront ici\nen temps réel.',
            style: AppTextStyles.adminSubtitle,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Dialog de confirmation avant d'effacer ──
  // On demande toujours confirmation avant une action destructive
  void _confirmClear(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Effacer l\'historique ?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Tous les scans de cette session seront supprimés. '
              'Cette action est irréversible.',
          style: TextStyle(
              color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          // Annuler
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Annuler',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          // Confirmer
          TextButton(
            onPressed: () {
              // On efface via le provider
              ref.read(scanHistoryProvider.notifier).clear();
              Navigator.pop(ctx);
            },
            child: const Text(
              'Effacer',
              style: TextStyle(
                color: AppColors.statusSuspended,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════
// WIDGETS INTERNES
// ════════════════════════════════════════════════════════

// ── Carte compteur (Total / Valides / Doublons / Fraudes) ──
class _CounterCard extends StatelessWidget {
  final int value;
  final String label;
  final Color color;

  const _CounterCard({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          // Fond légèrement coloré selon la couleur du statut
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color.withOpacity(0.8),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tuile d'un scan dans la liste ──
class _ScanTile extends StatelessWidget {
  final ScanRecord record;
  const _ScanTile({required this.record});

  // Couleur selon le résultat du scan
  Color get _color {
    switch (record.result) {
      case ScanStatus.valide:
        return AppColors.statusActive;
      case ScanStatus.dejaScanne:
        return AppColors.statusPending;
      case ScanStatus.fraude:
        return AppColors.statusSuspended;
    }
  }

  // Icône selon le résultat
  IconData get _icon {
    switch (record.result) {
      case ScanStatus.valide:
        return Icons.check_circle_rounded;
      case ScanStatus.dejaScanne:
        return Icons.warning_amber_rounded;
      case ScanStatus.fraude:
        return Icons.cancel_rounded;
    }
  }

  // Libellé selon le résultat
  String get _label {
    switch (record.result) {
      case ScanStatus.valide:
        return 'Valide';
      case ScanStatus.dejaScanne:
        return 'Déjà scanné';
      case ScanStatus.fraude:
        return 'Fraude';
    }
  }

  // Formate l'heure : "14:32:05"
  String get _time {
    final dt = record.scannedAt;
    return '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}:'
        '${dt.second.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          // ── Icône résultat ──
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(_icon, color: _color, size: 22),
          ),
          const SizedBox(width: 12),

          // ── ID du ticket + événement ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ID du ticket en monospace (plus lisible)
                Text(
                  record.ticketId.length > 25
                      ? '${record.ticketId.substring(0, 25)}...'
                      : record.ticketId,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  record.eventName,
                  style: AppTextStyles.caption,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // ── Résultat + heure ──
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _label,
                style: TextStyle(
                  color: _color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(_time, style: AppTextStyles.caption),
            ],
          ),
        ],
      ),
    );
  }
}