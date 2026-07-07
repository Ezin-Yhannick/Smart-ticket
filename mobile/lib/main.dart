// lib/main.dart
//
// C'est le point d'entrée de toute application Flutter.
// Quand tu lances l'app, Flutter exécute d'abord la fonction main().
// Elle appelle runApp() qui démarre l'interface graphique.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/providers/settings_provider.dart'; // Import ajouté

void main() {
  // S'assure que Flutter est bien initialisé avant de démarrer
  // (nécessaire pour le secure storage et certains plugins)
  WidgetsFlutterBinding.ensureInitialized();

  // ProviderScope est le "conteneur" de Riverpod
  // Il doit envelopper toute l'application pour que la gestion d'état fonctionne
  runApp(
    const ProviderScope( 
      child: SQR_Code(),
    ),
  );
}

// SmartTicketApp est le widget racine de l'application.
// On utilise ConsumerWidget (au lieu de StatelessWidget) pour avoir accès
// aux providers Riverpod (notamment le router).
class SQR_Code extends ConsumerWidget {
  const SQR_Code({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // On récupère le router configuré dans app_router.dart
    final router = ref.watch(appRouterProvider);
    // On écoute les réglages (thème et langue)
    final settings = ref.watch(settingsProvider);

    return MaterialApp.router(
      // Le nom de l'app (affiché dans le switcher d'applications du téléphone)
      title: 'Smart-Ticket',

      // On applique notre thème dark personnalisé
      theme: AppTheme.lightTheme,      // mode clair
      darkTheme: AppTheme.darkTheme,   // mode sombre
      themeMode: settings.themeMode,   // Dynamique !
      locale: settings.locale,         // Dynamique !

      // Configuration du router (gestion de la navigation)
      routerConfig: router,

      // Désactive le bandeau "DEBUG" en haut à droite pendant le développement
      debugShowCheckedModeBanner: false,
    );
  }
}