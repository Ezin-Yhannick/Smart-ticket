// lib/shared/models/event_model.dart
//
// Un événement c'est ce que l'Admin crée : un concert, une foire, un marché.
// Ce modèle décrit exactement à quoi ressemble un événement dans le code.

class EventModel {
  final String id;
  final String name;
  final EventType type;
  final DateTime date;
  final String location;
  final String description;
  final int ticketQuota;    // nombre total de tickets à générer
  final int ticketsSold;    // tickets vendus (cash par les marchands)
  final int ticketsUsed;    // tickets scannés à l'entrée
  final EventStatus status;
  final DateTime createdAt;

  const EventModel({
    required this.id,
    required this.name,
    required this.type,
    required this.date,
    required this.location,
    required this.description,
    required this.ticketQuota,
    required this.ticketsSold,
    required this.ticketsUsed,
    required this.status,
    required this.createdAt,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] as String,
      name: json['name'] as String,
      type: EventType.fromString(json['type'] as String),
      date: DateTime.parse(json['date'] as String),
      location: json['location'] as String,
      description: json['description'] as String? ?? '',
      ticketQuota: json['ticketQuota'] as int? ?? 0,
      ticketsSold: json['ticketsSold'] as int? ?? 0,
      ticketsUsed: json['ticketsUsed'] as int? ?? 0,
      status: EventStatus.fromString(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'type': type.value,
    'date': '${date.year}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}',
    'location': location,
    'description': description,
    'ticketQuota': ticketQuota,
  };

  // Calculs utiles
  int get ticketsRemaining => ticketQuota - ticketsSold;
  double get soldPercentage =>
      ticketQuota > 0 ? (ticketsSold / ticketQuota) * 100 : 0;
  double get attendancePercentage =>
      ticketsSold > 0 ? (ticketsUsed / ticketsSold) * 100 : 0;

  // "15 août 2025"
  String get dateFormatted {
    const months = ['jan.','fév.','mars','avr.','mai','juin',
      'juil.','août','sept.','oct.','nov.','déc.'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

// Types d'événements disponibles dans le formulaire
enum EventType {
  concert('CONCERT', 'Concert'),
  foire('FOIRE', 'Foire'),
  marche('MARCHE', 'Marché'),
  festival('FESTIVAL', 'Festival'),
  autre('AUTRE', 'Autre');

  final String value;
  final String label;
  const EventType(this.value, this.label);

  static EventType fromString(String s) => EventType.values.firstWhere(
        (e) => e.value == s.toUpperCase(),
    orElse: () => EventType.autre,
  );
}

// Statuts possibles d'un événement
enum EventStatus {
  active('ACTIVE'),
  closed('CLOSED'),
  archived('ARCHIVED');

  final String value;
  const EventStatus(this.value);

  static EventStatus fromString(String s) => EventStatus.values.firstWhere(
        (e) => e.value == s.toUpperCase(),
    orElse: () => EventStatus.active,
  );
}

enum ScanStatus {
  valide,      // ✅ ticket OK → accès autorisé
  dejaScanne,  // ⚠️ ticket déjà utilisé
  fraude,      // ❌ QR inconnu / faux ticket
}