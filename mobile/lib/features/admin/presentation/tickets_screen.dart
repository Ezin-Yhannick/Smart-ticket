// lib/features/admin/presentation/tickets_screen.dart
//
// ════════════════════════════════════════════════════════
// PAGE DES TICKETS D'UN ÉVÉNEMENT
// ════════════════════════════════════════════════════════
//
// Cette page s'ouvre quand l'admin clique sur "QR Codes"
// depuis la liste de ses événements.
//
// Ce que l'admin peut faire ici :
//   ① Voir tous les tickets organisés en 3 onglets
//      — Non vendus / Vendus / Utilisés
//   ② Cliquer sur un ticket pour voir son QR code en grand
//   ③ Marquer un ticket comme "vendu" (le marchand a pris le cash)
//   ④ Exporter les QR codes dans un fichier Word pour impression

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../shared/models/event_model.dart';

// ────────────────────────────────────────────
// Modèle simplifié d'un ticket (pour la démo)
// ────────────────────────────────────────────
enum TicketStatus { nonVendu, vendu, utilise }

class _Ticket {
  final String id;        // ex: "TKT-EVT001-0042"
  final TicketStatus status;

  const _Ticket({required this.id, required this.status});

  // Crée une copie avec un statut différent
  _Ticket withStatus(TicketStatus s) => _Ticket(id: id, status: s);
}

// ────────────────────────────────────────────
// Page principale
// ────────────────────────────────────────────
class TicketsScreen extends ConsumerStatefulWidget {
  final EventModel event;
  const TicketsScreen({super.key, required this.event});

  @override
  ConsumerState<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends ConsumerState<TicketsScreen>
    with SingleTickerProviderStateMixin {

  late TabController _tabController;
  List<_Ticket> _tickets = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final token = ref.read(authStateProvider).token!;
      final data = await ApiService.getEventTickets(token, widget.event.id);

      setState(() {
        _tickets = data.map((t) {
          TicketStatus status;
          switch (t['status']) {
            case 'VENDU':   status = TicketStatus.vendu; break;
            case 'UTILISE': status = TicketStatus.utilise; break;
            default:        status = TicketStatus.nonVendu;
          }
          return _Ticket(id: t['uuid'], status: status);
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Helpers : compter et filtrer ──

  int _count(TicketStatus s) =>
      _tickets.where((t) => t.status == s).length;

  List<_Ticket> _filtered(TicketStatus s) =>
      _tickets.where((t) => t.status == s).toList();

  // ── Actions ──

  // Appelle l'API pour marquer comme vendu et met à jour l'état local
  Future<void> _markAsSold(String ticketId) async {
    try {
      final token = ref.read(authStateProvider).token!;
      await ApiService.sellTicket(token, ticketId);

      // Met à jour localement après confirmation API
      setState(() {
        final i = _tickets.indexWhere((t) => t.id == ticketId);
        if (i != -1) {
          _tickets[i] = _tickets[i].withStatus(TicketStatus.vendu);
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Ticket vendu ✅'),
            backgroundColor: AppColors.statusActive,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Affiche le QR code en plein écran dans un dialog
  void _showQRDialog(String ticketId) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('QR Code', style: AppTextStyles.sectionTitle),
              const SizedBox(height: 4),
              Text(ticketId,
                  style: AppTextStyles.caption,
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: QrImageView(
                  data: ticketId,
                  version: QrVersions.auto,
                  size: 200,
                  backgroundColor: Colors.white,
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Fermer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Affiche le menu d'export (bottom sheet)
  void _showExportSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            const Text('Exporter les QR codes',
                style: AppTextStyles.sectionTitle),
            const SizedBox(height: 4),
            const Text(
              'Le fichier Word contiendra les QR codes\n'
                  'disposés en grille, prêts à imprimer.',
              style: AppTextStyles.adminSubtitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            _ExportOption(
              icon: Icons.select_all_rounded,
              label: 'Tous les tickets',
              subtitle: '${_tickets.length} tickets au total',
              onTap: () {
                Navigator.pop(ctx);
                _doExport('tous');
              },
            ),
            const SizedBox(height: 10),

            _ExportOption(
              icon: Icons.radio_button_unchecked_rounded,
              label: 'Non vendus seulement',
              subtitle: '${_count(TicketStatus.nonVendu)} tickets disponibles',
              onTap: () {
                Navigator.pop(ctx);
                _doExport('non_vendus');
              },
            ),
          ],
        ),
      ),
    );
  }

  // Déclenche la vente collective puis l'exportation Word
  Future<void> _doExport(String filter) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Génération et vente des tickets...')),
      );

      final token = ref.read(authStateProvider).token!;

      // 1. Marque tous les tickets non vendus comme VENDUS avant export
      final ticketsToSell = filter == 'non_vendus'
          ? _tickets.where((t) => t.status == TicketStatus.nonVendu).toList()
          : _tickets.where((t) => t.status == TicketStatus.nonVendu).toList();

      for (final ticket in ticketsToSell) {
        await ApiService.sellTicket(token, ticket.id);
      }

      // 2. Recharge les tickets depuis l'API
      await _loadTickets();

      // 3. Génère le fichier Word
      final path = await ApiService.exportTicketsWord(
          token, widget.event.id, filter);

      // 4. Ouvre le fichier
      await OpenFilex.open(path);

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erreur : $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  // ── Build principal ──
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.event.name,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          TextButton.icon(
            onPressed: _showExportSheet,
            icon: const Icon(Icons.download_outlined,
                size: 18, color: AppColors.primary),
            label: const Text('Exporter',
                style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600),
          tabs: [
            Tab(text: 'Non vendus (${_count(TicketStatus.nonVendu)})'),
            Tab(text: 'Vendus (${_count(TicketStatus.vendu)})'),
            Tab(text: 'Utilisés (${_count(TicketStatus.utilise)})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
          : Column(
        children: [
          _SummaryBar(tickets: _tickets),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _TicketList(
                  tickets: _filtered(TicketStatus.nonVendu),
                  onMarkSold: (id) => _markAsSold(id),
                  onShowQR: _showQRDialog,
                ),
                _TicketList(
                  tickets: _filtered(TicketStatus.vendu),
                  onMarkSold: null,
                  onShowQR: _showQRDialog,
                ),
                _TicketList(
                  tickets: _filtered(TicketStatus.utilise),
                  onMarkSold: null,
                  onShowQR: _showQRDialog,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════
// WIDGETS RÉUTILISABLES
// ════════════════════════════════════════════════════════

class _SummaryBar extends StatelessWidget {
  final List<_Ticket> tickets;
  const _SummaryBar({required this.tickets});

  int _count(TicketStatus s) =>
      tickets.where((t) => t.status == s).length;

  @override
  Widget build(BuildContext context) {
    final total = tickets.length;
    final sold = _count(TicketStatus.vendu);
    final used = _count(TicketStatus.utilise);
    final pct = total > 0
        ? '${(sold / total * 100).toStringAsFixed(0)}%'
        : '0%';

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          _StatCell(value: '$total', label: 'Total',
              color: AppColors.textSecondary),
          _StatCell(value: '$sold', label: 'Vendus',
              color: AppColors.statusActive),
          _StatCell(value: '$used', label: 'Utilisés',
              color: AppColors.primary),
          _StatCell(value: pct, label: 'Taux vente',
              color: AppColors.statusPending),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _StatCell(
      {required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(children: [
      Text(value,
          style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w700)),
      const SizedBox(height: 2),
      Text(label, style: AppTextStyles.caption),
    ]),
  );
}

class _TicketList extends StatelessWidget {
  final List<_Ticket> tickets;
  final void Function(String ticketId)? onMarkSold;
  final void Function(String ticketId) onShowQR;

  const _TicketList({
    required this.tickets,
    required this.onMarkSold,
    required this.onShowQR,
  });

  @override
  Widget build(BuildContext context) {
    if (tickets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.confirmation_number_outlined,
                color: AppColors.textTertiary, size: 52),
            const SizedBox(height: 12),
            const Text('Aucun ticket dans cette catégorie',
                style: AppTextStyles.adminSubtitle),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tickets.length,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _TicketTile(
          ticket: tickets[i],
          onMarkSold: onMarkSold != null
              ? () => onMarkSold!(tickets[i].id)
              : null,
          onShowQR: () => onShowQR(tickets[i].id),
        ),
      ),
    );
  }
}

class _TicketTile extends StatelessWidget {
  final _Ticket ticket;
  final VoidCallback? onMarkSold;
  final VoidCallback onShowQR;

  const _TicketTile({
    required this.ticket,
    required this.onMarkSold,
    required this.onShowQR,
  });

  Color get _statusColor {
    switch (ticket.status) {
      case TicketStatus.nonVendu: return AppColors.textTertiary;
      case TicketStatus.vendu:    return AppColors.statusActive;
      case TicketStatus.utilise:  return AppColors.primary;
    }
  }

  String get _statusLabel {
    switch (ticket.status) {
      case TicketStatus.nonVendu: return 'Non vendu';
      case TicketStatus.vendu:    return 'Vendu';
      case TicketStatus.utilise:  return 'Utilisé';
    }
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
          GestureDetector(
            onTap: onShowQR,
            child: Container(
              width: 52,
              height: 52,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: QrImageView(
                data: ticket.id,
                version: QrVersions.auto,
                backgroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ticket.id,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusLabel,
                    style: TextStyle(
                        color: _statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          if (onMarkSold != null)
            TextButton(
              onPressed: onMarkSold,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.statusActive,
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
              ),
              child: const Text('Vendu',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700)),
            )
          else
            IconButton(
              onPressed: onShowQR,
              icon: const Icon(Icons.zoom_in_rounded,
                  color: AppColors.textSecondary, size: 24),
            ),
        ],
      ),
    );
  }
}

class _ExportOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _ExportOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.caption),
                ]),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.textTertiary, size: 20),
        ]),
      ),
    );
  }
}