// lib/features/agent/presentation/scan_screen.dart
//
// ════════════════════════════════════════════════════════
// ÉCRAN DE SCAN — le cœur de l'interface Agent
// ════════════════════════════════════════════════════════
//
// Flux complet :
//   1. L'agent ouvre l'app → les événements se chargent depuis l'API
//   2. Il choisit son événement dans le sélecteur
//   3. La caméra s'ouvre en plein écran
//   4. Il pointe la caméra sur un QR code
//   5. onDetect() est appelée automatiquement
//   6. On envoie l'UUID + l'eventId au backend
//   7. Le résultat s'affiche en vert / orange / rouge
//   8. Après 3 secondes → retour au scan automatique

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../shared/models/ticket_model.dart';
import 'agent_shell.dart';

// ════════════════════════════════════════════════════════
// MODÈLE — résultat d'un scan
// ════════════════════════════════════════════════════════
class ScanResultData {
  final ScanStatus status;
  final String ticketId;
  final String message;
  final String? detail;

  const ScanResultData({
    required this.status,
    required this.ticketId,
    required this.message,
    this.detail,
  });

  Color get color {
    switch (status) {
      case ScanStatus.valide:      return AppColors.statusActive;
      case ScanStatus.dejaScanne:  return AppColors.statusPending;
      case ScanStatus.fraude:      return AppColors.statusSuspended;
    }
  }

  Color get backgroundColor {
    switch (status) {
      case ScanStatus.valide:      return AppColors.statusActiveBackground;
      case ScanStatus.dejaScanne:  return AppColors.statusPendingBackground;
      case ScanStatus.fraude:      return AppColors.statusSuspendedBackground;
    }
  }

  IconData get icon {
    switch (status) {
      case ScanStatus.valide:      return Icons.check_circle_rounded;
      case ScanStatus.dejaScanne:  return Icons.warning_amber_rounded;
      case ScanStatus.fraude:      return Icons.cancel_rounded;
    }
  }
}

// ════════════════════════════════════════════════════════
// ÉCRAN PRINCIPAL
// ════════════════════════════════════════════════════════
class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {

  late MobileScannerController _cameraController;

  bool _isScanning = true;
  bool _torchOn = false;
  ScanResultData? _lastResult;

  // ── Événements chargés depuis l'API ──
  String? _selectedEventId;           // ID envoyé au backend
  String _selectedEventName = 'Choisir un événement...';
  List<Map<String, dynamic>> _assignedEvents = [];
  bool _loadingEvents = true;

  @override
  void initState() {
    super.initState();
    _cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
    );
    // On charge les événements dès que l'écran s'ouvre
    _loadEvents();
  }

  // ── Charge les événements depuis le backend ──
  Future<void> _loadEvents() async {
    try {
      final token = ref.read(authStateProvider).token!;
      final data = await ApiService.getAllEvents(token);

      setState(() {
        _assignedEvents = data.map((e) => {
          'id': e['id'].toString(),
          'name': e['name'] as String,
        }).toList();

        // Sélectionne le premier événement automatiquement
        if (_assignedEvents.isNotEmpty) {
          _selectedEventId = _assignedEvents[0]['id'];
          _selectedEventName = _assignedEvents[0]['name'];
        }
        _loadingEvents = false;
      });
    } catch (e) {
      // En cas d'erreur réseau on affiche quand même l'écran
      setState(() => _loadingEvents = false);
    }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  // ── Appelée automatiquement quand un QR est détecté ──
  Future<void> _onDetect(BarcodeCapture capture) async {
    if (!_isScanning) return;

    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    final qrValue = barcode.rawValue!;
    setState(() => _isScanning = false);

    // Appel API avec l'UUID ET l'eventId
    final result = await _verifyTicket(qrValue);

    // Vibration selon le résultat
    switch (result.status) {
      case ScanStatus.valide:
        HapticFeedback.lightImpact();
        break;
      case ScanStatus.dejaScanne:
        HapticFeedback.mediumImpact();
        break;
      case ScanStatus.fraude:
        HapticFeedback.heavyImpact();
        break;
    }

    // Enregistre dans l'historique
    ref.read(scanHistoryProvider.notifier).add(
      ScanRecord(
        ticketId: qrValue,
        result: result.status,
        scannedAt: DateTime.now(),
        eventName: _selectedEventName,
      ),
    );

    setState(() => _lastResult = result);

    // Reset après 3 secondes
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isScanning = true;
          _lastResult = null;
        });
      }
    });
  }

  // ── Vérification du ticket via le backend ──
  Future<ScanResultData> _verifyTicket(String qrValue) async {
    try {
      final token = ref.read(authStateProvider).token!;

      // On envoie l'UUID + l'ID de l'événement sélectionné
      // Le backend sait ainsi à quel événement appartient ce scan
      final data = await ApiService.scanTicket(
        token,
        qrValue,
        eventId: _selectedEventId, // ← l'ID réel depuis la BDD
      );

      ScanStatus status;
      switch (data['status']) {
        case 'VALID':
          status = ScanStatus.valide;
          break;
        case 'ALREADY_USED':
          status = ScanStatus.dejaScanne;
          break;
        default:
          status = ScanStatus.fraude;
      }

      return ScanResultData(
        status: status,
        ticketId: qrValue,
        message: data['message'] ?? 'Résultat inconnu',
        detail: data['detail'],
      );
    } catch (e) {
      // Erreur réseau → fraude par sécurité
      return ScanResultData(
        status: ScanStatus.fraude,
        ticketId: qrValue,
        message: 'Erreur réseau',
        detail: 'Impossible de vérifier le ticket',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Caméra plein écran
          MobileScanner(
            controller: _cameraController,
            onDetect: _onDetect,
          ),

          // Interface superposée
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                const Spacer(),
                _buildScanFrame(),
                const Spacer(),
                if (_lastResult != null)
                  _buildResultCard(_lastResult!)
                else
                  _buildHintBar(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Barre du haut : sélecteur événement + torche ──
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          // Sélecteur d'événement
          Expanded(
            child: GestureDetector(
              onTap: _showEventPicker,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24, width: 0.5),
                ),
                child: Row(children: [
                  // Spinner si chargement en cours
                  if (_loadingEvents)
                    const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white70,
                        strokeWidth: 2,
                      ),
                    )
                  else
                    const Icon(Icons.event_outlined,
                        color: Colors.white70, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _loadingEvents
                          ? 'Chargement...'
                          : _selectedEventName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down_rounded,
                      color: Colors.white54, size: 18),
                ]),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Bouton torche
          GestureDetector(
            onTap: () {
              _cameraController.toggleTorch();
              setState(() => _torchOn = !_torchOn);
            },
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: _torchOn ? AppColors.primary : Colors.black54,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24, width: 0.5),
              ),
              child: const Icon(Icons.flashlight_on_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // ── Cadre de scan ──
  Widget _buildScanFrame() {
    final frameColor = _lastResult?.color ?? AppColors.primary;
    return SizedBox(
      width: 240,
      height: 240,
      child: CustomPaint(
        painter: _ScanFramePainter(color: frameColor),
        child: const Center(child: SizedBox.shrink()),
      ),
    );
  }

  // ── Carte de résultat ──
  Widget _buildResultCard(ScanResultData result) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: result.backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: result.color.withOpacity(0.5), width: 1),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: result.color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(result.icon, color: result.color, size: 36),
          ),
          const SizedBox(height: 12),
          Text(result.message,
              style: TextStyle(
                  color: result.color, fontSize: 20,
                  fontWeight: FontWeight.w700)),
          if (result.detail != null) ...[
            const SizedBox(height: 6),
            Text(result.detail!,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 13),
                textAlign: TextAlign.center),
          ],
          const SizedBox(height: 10),
          Text(
            result.ticketId.length > 30
                ? '${result.ticketId.substring(0, 30)}...'
                : result.ticketId,
            style: const TextStyle(
                color: Colors.white38, fontSize: 11,
                fontFamily: 'monospace'),
          ),
          const SizedBox(height: 10),
          const Text('Prochain scan dans 3 secondes...',
              style: TextStyle(color: Colors.white38, fontSize: 12)),
        ]),
      ),
    );
  }

  // ── Barre d'indications ──
  Widget _buildHintBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12, width: 0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _HintItem(icon: Icons.check_circle_outline_rounded,
              color: AppColors.statusActive, label: 'Valide'),
          _HintItem(icon: Icons.warning_amber_rounded,
              color: AppColors.statusPending, label: 'Doublon'),
          _HintItem(icon: Icons.cancel_outlined,
              color: AppColors.statusSuspended, label: 'Fraude'),
        ],
      ),
    );
  }

  // ── Sélecteur d'événement (bottom sheet) ──
  void _showEventPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
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
            const Text('Choisir un événement',
                style: AppTextStyles.sectionTitle),
            const SizedBox(height: 16),

            // Spinner pendant le chargement
            if (_loadingEvents)
              const Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(
                    color: AppColors.primary),
              )
            // Message si aucun événement
            else if (_assignedEvents.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Aucun événement disponible.\n'
                      'Contactez votre administrateur.',
                  style: AppTextStyles.adminSubtitle,
                  textAlign: TextAlign.center,
                ),
              )
            // Liste des vrais événements depuis la BDD
            else
              ..._assignedEvents.map((event) => ListTile(
                title: Text(event['name'],
                    style: const TextStyle(
                        color: AppColors.textPrimary)),
                leading: Icon(Icons.event_rounded,
                    color: _selectedEventId == event['id']
                        ? AppColors.primary
                        : AppColors.textTertiary),
                trailing: _selectedEventId == event['id']
                    ? const Icon(Icons.check_rounded,
                    color: AppColors.primary)
                    : null,
                onTap: () {
                  setState(() {
                    _selectedEventId = event['id'];
                    _selectedEventName = event['name'];
                  });
                  Navigator.pop(ctx);
                },
              )),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════
// WIDGETS INTERNES
// ════════════════════════════════════════════════════════

class _ScanFramePainter extends CustomPainter {
  final Color color;
  const _ScanFramePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const c = 28.0;

    canvas.drawLine(const Offset(0, c), const Offset(0, 0), paint);
    canvas.drawLine(const Offset(0, 0), Offset(c, 0), paint);
    canvas.drawLine(Offset(size.width - c, 0), Offset(size.width, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, c), paint);
    canvas.drawLine(Offset(0, size.height - c), Offset(0, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(c, size.height), paint);
    canvas.drawLine(Offset(size.width - c, size.height),
        Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height - c),
        Offset(size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(_ScanFramePainter old) => old.color != color;
}

class _HintItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  const _HintItem({required this.icon, required this.color,
    required this.label});

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: color, size: 24),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(
          color: color, fontSize: 12, fontWeight: FontWeight.w500)),
    ],
  );
}