// lib/shared/models/admin_model.dart
//
// Le modèle de données représente la structure d'un objet dans l'application.
// AdminModel décrit à quoi ressemble un "administrateur" dans le code.
//
// Quand le backend nous envoie du JSON comme :
// {
//   "id": "abc123",
//   "name": "ASSOUMA Kamal",
//   "email": "k.assouma@epac.bj",
//   "status": "ACTIVE",
//   "eventsCount": 12,
//   "ticketsCount": 847,
//   "revenue": 1200000
// }
//
// On le convertit en AdminModel avec fromJson().

import '../widgets/status_badge.dart';

class AdminModel {
  final String id;
  final String name;
  final String email;
  final AdminStatus status;
  final int eventsCount;
  final int ticketsCount;
  final double revenue; // en FCFA

  const AdminModel({
    required this.id,
    required this.name,
    required this.email,
    required this.status,
    required this.eventsCount,
    required this.ticketsCount,
    required this.revenue,
  });

  // Convertit le JSON du backend en objet Dart
  factory AdminModel.fromJson(Map<String, dynamic> json) {
    return AdminModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      status: _statusFromString(json['status'] as String),
      eventsCount: json['eventsCount'] as int? ?? 0,
      ticketsCount: json['ticketsCount'] as int? ?? 0,
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0.0,
    );
  }

  // Convertit la chaîne du backend en enum AdminStatus
  static AdminStatus _statusFromString(String s) {
    switch (s.toUpperCase()) {
      case 'ACTIVE':
        return AdminStatus.active;
      case 'PENDING':
        return AdminStatus.pending;
      case 'SUSPENDED':
        return AdminStatus.suspended;
      default:
        return AdminStatus.pending;
    }
  }

  // Formate le revenu en "1,2M FCFA" ou "890K FCFA"
  String get revenueFormatted {
    if (revenue >= 1000000) {
      final m = revenue / 1000000;
      return '${m.toStringAsFixed(m % 1 == 0 ? 0 : 1)}M FCFA';
    } else if (revenue >= 1000) {
      final k = revenue / 1000;
      return '${k.toStringAsFixed(0)}K FCFA';
    }
    return '${revenue.toStringAsFixed(0)} FCFA';
  }

  // Résumé court pour la liste : "12 événements · 1,2M FCFA"
  String get subtitle {
    if (eventsCount == 0) return 'Aucun événement encore';
    return '$eventsCount événement${eventsCount > 1 ? 's' : ''} · $revenueFormatted';
  }
}