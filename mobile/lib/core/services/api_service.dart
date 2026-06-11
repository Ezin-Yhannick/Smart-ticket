// lib/core/services/api_service.dart
//
// Ce fichier centralise tous les appels HTTP vers le backend Spring Boot.
// Avantage : si l'URL du serveur change, on ne modifie qu'ici.

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class ApiService {
  // Sur émulateur Android → 10.0.2.2 remplace localhost
  // Sur vrai téléphone → l'IP locale de ton PC
  static const String baseUrl = 'http://10.114.148.206:8080/api';

  // ════════════════════════════════════════════════════════
  // AUTHENTIFICATION
  // ════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data; // { token, role, name, email, userId }
    } else {
      throw Exception(
          data['message'] ?? 'Email ou mot de passe incorrect');
    }
  }

  // ════════════════════════════════════════════════════════
  // ÉVÉNEMENTS
  // ════════════════════════════════════════════════════════

  // Récupère les événements de l'admin connecté
  static Future<List<dynamic>> getMyEvents(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/events'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Erreur chargement événements');
  }

  // Récupère TOUS les événements actifs (utilisé par l'Agent)
  static Future<List<dynamic>> getAllEvents(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/events/all'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Erreur chargement événements');
  }

  // Crée un événement + génère les tickets
  static Future<Map<String, dynamic>> createEvent({
    required String token,
    required String name,
    required String type,
    required String date,
    required String location,
    required String description,
    required List<Map<String, dynamic>> categories,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/events'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
        'type': type,
        'date': date,
        'location': location,
        'description': description,
        'categories': categories,
      }),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return data;
    throw Exception(data['message'] ?? 'Erreur création événement');
  }

  // ════════════════════════════════════════════════════════
  // TICKETS
  // ════════════════════════════════════════════════════════

  // Récupère les tickets d'un événement (version int)
  static Future<List<dynamic>> getTickets(
      String token, int eventId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/events/$eventId/tickets'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Erreur chargement tickets');
  }

  // Récupère les tickets d'un événement (version String)
  static Future<List<dynamic>> getEventTickets(
      String token, String eventId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/events/$eventId/tickets'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Erreur chargement tickets');
  }

  // Télécharge les QR codes en fichier Word
  static Future<String> exportTicketsWord(
      String token, String eventId, String filter) async {
    final response = await http.get(
      Uri.parse('$baseUrl/events/$eventId/export?filter=$filter'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/tickets-$eventId.docx');
      await file.writeAsBytes(response.bodyBytes);
      return file.path;
    }
    throw Exception('Erreur export Word');
  }

  // ════════════════════════════════════════════════════════
  // SCAN
  // ════════════════════════════════════════════════════════
  //
  // Scan d'un ticket QR à l'entrée de l'événement.
  // On envoie l'UUID du QR + l'eventId de l'événement en cours.
  // Le backend vérifie si le ticket existe, s'il est vendu,
  // et s'il n'a pas déjà été scanné.
  //
  // Réponse backend attendue :
  // {
  //   "status": "VALID" | "ALREADY_USED" | "INVALID",
  //   "message": "Accès autorisé" | "Ticket déjà scanné" | "QR inconnu",
  //   "detail": "..." (optionnel)
  // }
  static Future<Map<String, dynamic>> scanTicket(
      String token,
      String uuid, {
        String? eventId, // ID de l'événement sélectionné par l'agent
      }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/scan'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'uuid': uuid,
        // On envoie l'eventId seulement s'il est disponible
        if (eventId != null) 'eventId': eventId,
      }),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Erreur lors du scan');
  }

  // ════════════════════════════════════════════════════════
  // SUPER ADMIN
  // ════════════════════════════════════════════════════════

  // Stats globales de la plateforme
  static Future<Map<String, dynamic>> getPlatformStats(
      String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/super-admin/stats'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Erreur chargement stats plateforme');
  }

  // Liste de tous les admins
  static Future<List<dynamic>> getAllAdmins(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/super-admin/admins'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Erreur chargement admins');
  }

  // Créer un nouvel admin
  static Future<Map<String, dynamic>> createAdmin({
    required String token,
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/super-admin/admins'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
      }),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return data;
    throw Exception(data['message'] ?? 'Erreur création admin');
  }

  // Suspendre un admin
  static Future<void> suspendAdmin(String token, int adminId) async {
    final response = await http.put(
      Uri.parse('$baseUrl/super-admin/admins/$adminId/suspend'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) throw Exception('Erreur suspension');
  }

  // Activer un admin
  static Future<void> activateAdmin(String token, int adminId) async {
    final response = await http.put(
      Uri.parse('$baseUrl/super-admin/admins/$adminId/activate'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) throw Exception('Erreur activation');
  }

  // Supprimer un admin
  static Future<void> deleteAdmin(String token, int adminId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/super-admin/admins/$adminId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) throw Exception('Erreur suppression');
  }
}