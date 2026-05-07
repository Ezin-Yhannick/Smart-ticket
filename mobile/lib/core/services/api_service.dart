// lib/core/services/api_service.dart
//
// Ce fichier centralise tous les appels HTTP vers le backend Spring Boot.
// Avantage : si l'URL du serveur change, on ne modifie qu'ici.

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class ApiService {
  // Sur émulateur Android 10.0.2.2 remplace localhost
  // Sur vrai téléphone l'IP locale de ton PC (ex: 192.168.1.X)
  static const String baseUrl = 'http://10.69.19.70:8080/api';

  // --- Login ---
  static Future<Map<String, dynamic>> login(String email, String password) async {
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
      // Le backend renvoie une erreur
      throw Exception(data['message'] ?? 'Email ou mot de passe incorrect');
    }
  }

  // ── Events ──

  // Récupère les événements de l'admin connecté
  static Future<List<dynamic>> getMyEvents(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/events'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',  // JWT obligatoire
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
    required List<Map<String, dynamic>> categories, // ✅ remplace ticketQuota
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
        'categories': categories, //
      }),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return data;
    throw Exception(data['message'] ?? 'Erreur création événement');
  }
  // Récupère les tickets d'un événement
  static Future<List<dynamic>> getTickets(String token, int eventId) async {
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

  // Ajoute ces deux méthodes dans ApiService

// Tickets d'un événement
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

// Télécharge le fichier Word et retourne son chemin local
  static Future<String> exportTicketsWord(
      String token, String eventId, String filter) async {
    final response = await http.get(
      Uri.parse('$baseUrl/events/$eventId/export?filter=$filter'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      // Sauvegarde le fichier dans le dossier temporaire du téléphone
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/tickets-$eventId.docx');
      await file.writeAsBytes(response.bodyBytes);
      return file.path;
    }
    throw Exception('Erreur export Word');
  }

  // Scan d'un ticket QR à l'entrée
  static Future<Map<String, dynamic>> scanTicket(
      String token, String uuid) async {
    final response = await http.post(
      Uri.parse('$baseUrl/scan?uuid=${Uri.encodeComponent(uuid)}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Erreur lors du scan');
  }

  // Récuperer tous les évènements actifs
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

}