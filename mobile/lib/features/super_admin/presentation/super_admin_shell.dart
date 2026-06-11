import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../shared/models/admin_model.dart';
import '../../../shared/widgets/avatar_circle.dart';
import '../../../shared/widgets/profile_menu.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

part 'super_admin_dashboard_screen.dart';
part 'super_admin_admins_screen.dart';
part 'super_admin_stats_screen.dart';
part 'super_admin_settings_screen.dart';

class SuperAdminShell extends StatelessWidget {
  final Widget child;
  const SuperAdminShell({super.key, required this.child});

  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/super-admin/admins')) return 1;
    if (location.startsWith('/super-admin/stats')) return 2;
    if (location.startsWith('/super-admin/settings')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.navBarBackground,
          border: Border(
              top: BorderSide(color: AppColors.border, width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _getCurrentIndex(context),
          onTap: (index) {
            switch (index) {
              case 0: context.go('/super-admin'); break;
              case 1: context.go('/super-admin/admins'); break;
              case 2: context.go('/super-admin/stats'); break;
              case 3: context.go('/super-admin/settings'); break;
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_outlined),
              activeIcon: Icon(Icons.grid_view_rounded),
              label: 'Tableau de bord',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline_rounded),
              activeIcon: Icon(Icons.people_rounded),
              label: 'Admins',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.show_chart_rounded),
              activeIcon: Icon(Icons.show_chart_rounded),
              label: 'Statistiques',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings_rounded),
              label: 'Gestion',
            ),
          ],
        ),
      ),
    );
  }
}

class SuperAdminDashboardPage extends StatelessWidget {
  const SuperAdminDashboardPage({super.key});
  @override
  Widget build(BuildContext context) => const SuperAdminDashboardScreen();
}

class SuperAdminAdminsPage extends StatelessWidget {
  const SuperAdminAdminsPage({super.key});
  @override
  Widget build(BuildContext context) => const SuperAdminAdminsScreen();
}

class SuperAdminStatsPage extends StatelessWidget {
  const SuperAdminStatsPage({super.key});
  @override
  Widget build(BuildContext context) => const SuperAdminStatsScreen();
}

class SuperAdminSettingsPage extends StatelessWidget {
  const SuperAdminSettingsPage({super.key});
  @override
  Widget build(BuildContext context) => const SuperAdminSettingsScreen();
}