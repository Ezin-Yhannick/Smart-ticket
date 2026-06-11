// lib/features/agent/presentation/agent_shell.dart
//
// ════════════════════════════════════════════════════════
// SHELL DE L'AGENT
// ════════════════════════════════════════════════════════
//
// Le Shell c'est le conteneur de toutes les pages de l'Agent.
// Il affiche la bottom navigation bar en bas avec 2 onglets :
//   - Onglet 1 : Scanner   → l'agent scanne les QR codes
//   - Onglet 2 : Historique → liste des scans de la session
//
// Pour l'instant les 2 pages sont des placeholders (pages vides).
// On les remplacera étape par étape.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../shared/models/ticket_model.dart';
import 'History_Screen.dart';
import 'scan_screen.dart';


// ════════════════════════════════════════════════════════
// MODÈLE DE DONNÉES — un enregistrement de scan
// ════════════════════════════════════════════════════════
//
// Chaque fois que l'agent scanne un QR code, on crée un
// _ScanRecord et on l'ajoute à l'historique de la session.
// L'historique est perdu quand l'agent ferme l'app — c'est voulu.
class ScanRecord {
  final String ticketId;    // contenu du QR scanné, ex: "TKT-EVT001-0042"
  final ScanStatus result;  // valide / déjà scanné / fraude
  final DateTime scannedAt; // heure du scan
  final String eventName;   // nom de l'événement en cours

  const ScanRecord({
    required this.ticketId,
    required this.result,
    required this.scannedAt,
    required this.eventName,
  });
}

// ════════════════════════════════════════════════════════
// PROVIDER — historique des scans de la session
// ════════════════════════════════════════════════════════
//
// On utilise Riverpod pour stocker l'historique des scans.
// Pourquoi Riverpod et pas juste une variable ?
// → Parce que l'historique doit être partagé entre
//   l'écran Scanner ET l'écran Historique.
//   Riverpod permet à ces 2 écrans de lire/modifier
//   la même liste sans se passer des données manuellement.

class ScanHistoryNotifier extends StateNotifier<List<ScanRecord>> {
  // On démarre avec une liste vide
  ScanHistoryNotifier() : super([]);

  // Ajoute un nouveau scan en tête de liste (le plus récent en premier)
  void add(ScanRecord record) {
    state = [record, ...state];
  }

  // Efface tout l'historique (bouton "Effacer" dans l'écran historique)
  void clear() {
    state = [];
  }
}

// Le provider qu'on utilise dans les écrans avec ref.watch(...)
final scanHistoryProvider =
StateNotifierProvider<ScanHistoryNotifier, List<ScanRecord>>(
      (ref) => ScanHistoryNotifier(),
);

// ════════════════════════════════════════════════════════
// SHELL — conteneur avec la bottom nav bar
// ════════════════════════════════════════════════════════
class AgentShell extends StatelessWidget {
  // child = la page active injectée par GoRouter
  // (soit AgentScanPage, soit AgentHistoryPage)
  final Widget child;
  const AgentShell({super.key, required this.child});

  // Retourne 0 pour Scanner, 1 pour Historique
  // selon l'URL courante
  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/agent/history')) return 1;
    return 0; // Scanner par défaut
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child, // la page active s'affiche ici

      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.navBarBackground,
          border: Border(
            top: BorderSide(color: AppColors.border, width: 0.5),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _getCurrentIndex(context),
          onTap: (index) {
            // Quand l'agent appuie sur un onglet,
            // GoRouter navigue vers la bonne route
            switch (index) {
              case 0:
                context.go('/agent');
                break;
              case 1:
                context.go('/agent/history');
                break;
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_scanner_outlined),
              activeIcon: Icon(Icons.qr_code_scanner_rounded),
              label: 'Scanner',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_outlined),
              activeIcon: Icon(Icons.history_rounded),
              label: 'Historique',
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════
// PAGES — routées par app_router.dart
// ════════════════════════════════════════════════════════
//
// Ces classes sont des "portes d'entrée" vers les vrais écrans.
// Pour l'instant elles affichent juste un placeholder.
// On remplacera le contenu à l'étape suivante.

class AgentScanPage extends StatelessWidget {
  const AgentScanPage({super.key});

  @override
  Widget build(BuildContext context) => const ScanScreen();
}

class AgentHistoryPage extends StatelessWidget {
  const AgentHistoryPage({super.key});

  @override
  Widget build(BuildContext context) => const HistoryScreen();
  }
