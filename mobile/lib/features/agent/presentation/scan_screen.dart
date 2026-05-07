// lib/features/agent/presentation/scan_screen.dart
//
// ════════════════════════════════════════════════════════
// ÉCRAN DE SCAN — le cœur de l'interface Agent
// ════════════════════════════════════════════════════════
//
// Cet écran remplace le placeholder dans AgentScanPage.
//
// Flux complet :
//   1. L'agent ouvre l'app → il choisit son événement
//   2. La caméra s'ouvre en plein écran
//   3. Il pointe la caméra sur un QR code
//   4. onDetect() est appelée automatiquement
//   5. On vérifie le ticket (simulation pour l'instant)
//   6. Le résultat s'affiche en vert / orange / rouge
//   7. Après 3 secondes → retour au scan automatique

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../shared/models/ticket_model.dart';
import 'agent_shell.dart'; // pour accéder à scanHistoryProvider et ScanRecord

// ════════════════════════════════════════════════════════
// MODÈLE — résultat d'un scan
// ════════════════════════════════════════════════════════
//
// Ce modèle représente ce qu'on affiche à l'agent
// après qu'il a scanné un QR code.
class ScanResultData {
  final ScanStatus status;  // valide / doublon / fraude
  final String ticketId;    // l'ID du ticket scanné
  final String message;     // message principal affiché
  final String? detail;     // détail optionnel (ex: heure du 1er scan)

  const ScanResultData({
    required this.status,
    required this.ticketId,
    required this.message,
    this.detail,
  });

  // Couleur selon le résultat
  Color get color {
    switch (status) {
      case ScanStatus.valide:
        return AppColors.statusActive;       // vert
      case ScanStatus.dejaScanne:
        return AppColors.statusPending;      // orange
      case ScanStatus.fraude:
        return AppColors.statusSuspended;    // rouge
    }
  }

  // Fond coloré selon le résultat
  Color get backgroundColor {
    switch (status) {
      case ScanStatus.valide:
        return AppColors.statusActiveBackground;
      case ScanStatus.dejaScanne:
        return AppColors.statusPendingBackground;
      case ScanStatus.fraude:
        return AppColors.statusSuspendedBackground;
    }
  }

  // Icône selon le résultat
  IconData get icon {
    switch (status) {
      case ScanStatus.valide:
        return Icons.check_circle_rounded;
      case ScanStatus.dejaScanne:
        return Icons.warning_amber_rounded;
      case ScanStatus.fraude:
        return Icons.cancel_rounded;
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

// ConsumerStatefulWidget nous donne accès à :
//   - setState() pour mettre à jour l'interface
//   - ref pour accéder aux providers Riverpod
class _ScanScreenState extends ConsumerState<ScanScreen> {

  // Le controller de la caméra
  // Il nous permet de contrôler la torche et de stopper/démarrer la caméra
  late MobileScannerController _cameraController;

  // true  = la caméra accepte les scans
  // false = on attend 3 secondes après un scan
  bool _isScanning = true;

  // true = la torche est allumée
  bool _torchOn = false;

  // Le dernier résultat de scan (null = aucun scan encore)
  ScanResultData? _lastResult;

  // L'événement que l'agent contrôle en ce moment
  String _selectedEvent = 'Foire de Cotonou 2025';

  // Liste des événements assignés à cet agent
  // (sera chargée depuis l'API plus tard)
  String? _selectedEventId; // ID de l'événement sélectionné
  String _selectedEventName = 'Choisir un événement...';
  List<Map<String, dynamic>> _assignedEvents = []; // {id, name}
  bool _loadingEvents = true;

  @override
  void initState() {
    super.initState();
    _cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
    );
    _loadEvents(); //  charge les vrais événements
  }

  Future<void> _loadEvents() async {
    try {
      final token = ref
          .read(authStateProvider)
          .token!;
      final data = await ApiService.getAllEvents(token);
      setState(() {
        _assignedEvents = data.map((e) =>
        {
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
      setState(() => _loadingEvents = false);
    }
  }

  @override
  void dispose() {
    // IMPORTANT : toujours libérer le controller quand l'écran est détruit
    // sinon la caméra reste ouverte en arrière-plan
    _cameraController.dispose();
    super.dispose();
  }

  // ── Appelée automatiquement quand un QR est détecté ──
  // Rend _onDetect async
  Future<void> _onDetect(BarcodeCapture capture) async {
    if (!_isScanning) return;

    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    final qrValue = barcode.rawValue!;
    setState(() => _isScanning = false);

    // Appel API réel
    final result = await _verifyTicket(qrValue);

    // Vibration
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

    // Historique
    ref.read(scanHistoryProvider.notifier).add(
      ScanRecord(
        ticketId: qrValue,
        result: result.status,
        scannedAt: DateTime.now(),
        eventName: _selectedEventName,
      ),
    );

    setState(() => _lastResult = result);

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isScanning = true;
          _lastResult = null;
        });
      }
    });
  }

// Remplace _verifyTicket par un vrai appel API
  Future<ScanResultData> _verifyTicket(String qrValue) async {
    try {
      final token = ref
          .read(authStateProvider)
          .token!;
      final data = await ApiService.scanTicket(token, qrValue);

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
        message: data['message'],
        detail: data['detail'],
      );
    } catch (e) {
      // En cas d'erreur réseau → on affiche fraude par sécurité
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
      // Fond noir pour que la caméra soit immersive
      backgroundColor: Colors.black,
      body: Stack(
        // Stack permet de superposer plusieurs widgets
        // La caméra est en bas, l'UI est par-dessus
        children: [
          // ── Caméra plein écran (couche du bas) ──
          MobileScanner(
            controller: _cameraController,
            onDetect: _onDetect,
          ),

          // ── Interface superposée sur la caméra ──
          SafeArea(
            child: Column(
              children: [
                // Barre du haut : événement + torche
                _buildTopBar(),

                const Spacer(),

                // Cadre de scan au centre
                _buildScanFrame(),

                const Spacer(),

                // Zone du bas : résultat ou indications
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

  // ── Barre du haut ──
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
                  border: Border.all(
                      color: Colors.white24, width: 0.5),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event_outlined,
                        color: Colors.white70, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedEventName,
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
                  ],
                ),
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
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                // Fond bleu si torche allumée, noir si éteinte
                color: _torchOn
                    ? AppColors.primary
                    : Colors.black54,
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white24, width: 0.5),
              ),
              child: const Icon(
                Icons.flashlight_on_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Cadre de scan ──
  // Le cadre change de couleur selon le résultat du scan
  Widget _buildScanFrame() {
    // Couleur du cadre : bleu par défaut, sinon couleur du résultat
    final frameColor = _lastResult?.color ?? AppColors.primary;

    return SizedBox(
      width: 240,
      height: 240,
      child: CustomPaint(
        // On dessine le cadre avec un CustomPainter
        painter: _ScanFramePainter(color: frameColor),
        child: const Center(
          child: SizedBox.shrink(),
        ),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icône principale (grande)
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: result.color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(result.icon, color: result.color, size: 36),
            ),
            const SizedBox(height: 12),

            // Message principal
            Text(
              result.message,
              style: TextStyle(
                color: result.color,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),

            // Détail (optionnel)
            if (result.detail != null) ...[
              const SizedBox(height: 6),
              Text(
                result.detail!,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: 10),

            // ID du ticket en petit
            Text(
              result.ticketId.length > 30
                  ? '${result.ticketId.substring(0, 30)}...'
                  : result.ticketId,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),

            const SizedBox(height: 10),
            const Text(
              'Prochain scan dans 3 secondes...',
              style: TextStyle(
                  color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // ── Barre d'indications (quand pas de résultat) ──
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
          _HintItem(
            icon: Icons.check_circle_outline_rounded,
            color: AppColors.statusActive,
            label: 'Valide',
          ),
          _HintItem(
            icon: Icons.warning_amber_rounded,
            color: AppColors.statusPending,
            label: 'Doublon',
          ),
          _HintItem(
            icon: Icons.cancel_outlined,
            color: AppColors.statusSuspended,
            label: 'Fraude',
          ),
        ],
      ),
    );
  }

  // ── Bottom sheet pour choisir l'événement ──
  void _showEventPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) =>
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Choisir un événement',
                    style: AppTextStyles.sectionTitle),
                const SizedBox(height: 16),

                // ✅ Vrais événements depuis l'API
                if (_loadingEvents)
                  const CircularProgressIndicator()
                else
                  if (_assignedEvents.isEmpty)
                    const Text('Aucun événement disponible',
                        style: AppTextStyles.adminSubtitle)
                  else
                    ..._assignedEvents.map((event) =>
                        ListTile(
                          title: Text(event['name'],
                              style: const TextStyle(
                                  color: AppColors.textPrimary)),
                          leading: Icon(
                            Icons.event_rounded,
                            color: _selectedEventId == event['id']
                                ? AppColors.primary
                                : AppColors.textTertiary,
                          ),
                          trailing: _selectedEventId == event['id']
                              ? const Icon(
                              Icons.check_rounded, color: AppColors.primary)
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

// ── Cadre de scan personnalisé ──
// On dessine les 4 coins du cadre manuellement
// C'est plus propre qu'une simple bordure
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

    const cornerLength = 28.0; // longueur de chaque coin

    // Coin haut-gauche
    canvas.drawLine(
        const Offset(0, cornerLength), const Offset(0, 0), paint);
    canvas.drawLine(
        const Offset(0, 0), const Offset(cornerLength, 0), paint);

    // Coin haut-droit
    canvas.drawLine(
        Offset(size.width - cornerLength, 0),
        Offset(size.width, 0), paint);
    canvas.drawLine(
        Offset(size.width, 0),
        Offset(size.width, cornerLength), paint);

    // Coin bas-gauche
    canvas.drawLine(
        Offset(0, size.height - cornerLength),
        Offset(0, size.height), paint);
    canvas.drawLine(
        Offset(0, size.height),
        Offset(cornerLength, size.height), paint);

    // Coin bas-droit
    canvas.drawLine(
        Offset(size.width - cornerLength, size.height),
        Offset(size.width, size.height), paint);
    canvas.drawLine(
        Offset(size.width, size.height - cornerLength),
        Offset(size.width, size.height), paint);
  }

  // Redessine seulement si la couleur change
  // (optimisation Flutter)
  @override
  bool shouldRepaint(_ScanFramePainter old) => old.color != color;
}

// ── Petite indication en bas (Valide / Doublon / Fraude) ──
class _HintItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const _HintItem({
    required this.icon,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}