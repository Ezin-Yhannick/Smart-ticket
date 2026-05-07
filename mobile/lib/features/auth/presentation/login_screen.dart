// lib/features/auth/presentation/login_screen.dart
//
// L'écran de connexion. C'est la première page que voit l'utilisateur
// s'il n'est pas encore connecté.
//
// Ce que fait cet écran :
// 1. Affiche un champ email + mot de passe
// 2. Quand on appuie sur "Se connecter", appelle le backend
// 3. Si succès → le router redirige automatiquement selon le rôle
// 4. Si échec → affiche un message d'erreur

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../core/providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

// ConsumerStatefulWidget nous donne accès à :
// - setState() pour mettre à jour l'interface locale (ex: afficher un loader)
// - ref pour accéder aux providers Riverpod (ex: authStateProvider)
class _LoginScreenState extends ConsumerState<LoginScreen> {
  // Controllers : ils "lisent" ce que l'utilisateur tape dans les champs
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Clé du formulaire : permet de valider les champs (email valide, etc.)
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;       // affiche le spinner pendant l'appel API
  bool _obscurePassword = true;  // cache/affiche le mot de passe
  String? _errorMessage;         // message d'erreur à afficher

  @override
  void dispose() {
    // Toujours libérer les controllers quand l'écran est détruit
    // pour éviter les fuites mémoire
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Fonction appelée quand on appuie sur "Se connecter"
  Future<void> _handleLogin() async {
    // Valide le formulaire (vérifie que les champs ne sont pas vides)
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {

        final data = await ApiService.login(
        _emailController.text.trim(),
        _passwordController.text,);

        final role = _parseRole(data['role']);

        // Connecte l'utilisateur dans Riverpod
        ref.read(authStateProvider.notifier).login(
          token: data['token'],
          role: role,
          userId: data['userId'].toString(),
          userName: data['name'],
          userEmail: data['email'],
        );

    } catch (e) {
      setState(() {
        _errorMessage = 'Email ou mot de passe incorrect.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  UserRole _parseRole(String role) {
    switch (role) {
      case 'SUPER_ADMIN':
        return UserRole.superAdmin;
      case 'ADMIN':
        return UserRole.admin;
      case 'AGENT':
        return UserRole.agent;
      default:
        throw Exception('Rôle inconnu : $role');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Évite que le clavier pousse les widgets vers le haut
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),

                // --- Logo et titre ---
                Row(
                  children: [
                    // Icône de l'app
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.grid_view_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Text(
                      'Smart-Ticket',
                      style: AppTextStyles.appBarTitle,
                    ),
                  ],
                ),

                const SizedBox(height: 48),

                // --- Titre de l'écran ---
                const Text(
                  'Connexion',
                  style: AppTextStyles.screenTitle,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Entrez vos identifiants pour accéder à votre espace',
                  style: AppTextStyles.adminSubtitle,
                ),

                const SizedBox(height: 36),

                // --- Champ Email ---
                const Text(
                  'Adresse email',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'exemple@email.com',
                    prefixIcon: Icon(
                      Icons.mail_outline_rounded,
                      color: AppColors.textTertiary,
                      size: 20,
                    ),
                  ),
                  // Règle de validation : ne peut pas être vide
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre email';
                    }
                    if (!value.contains('@')) {
                      return 'Email invalide';
                    }
                    return null; // null = valide
                  },
                ),

                const SizedBox(height: 20),

                // --- Champ Mot de passe ---
                const Text(
                  'Mot de passe',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword, // cache les caractères si true
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    prefixIcon: const Icon(
                      Icons.lock_outline_rounded,
                      color: AppColors.textTertiary,
                      size: 20,
                    ),
                    // Bouton pour afficher/masquer le mot de passe
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.textTertiary,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre mot de passe';
                    }
                    if (value.length < 6) {
                      return 'Mot de passe trop court (min. 6 caractères)';
                    }
                    return null;
                  },
                ),

                // --- Message d'erreur ---
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.statusSuspendedBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: AppColors.statusSuspended,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: AppColors.statusSuspended,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // --- Bouton Se connecter ---
                SizedBox(
                  width: double.infinity, // prend toute la largeur
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    child: _isLoading
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : const Text('Se connecter'),
                  ),
                ),

                const SizedBox(height: 40),

                // --- Info version ---
                Center(
                  child: Text(
                    'Smart-Ticket v1.0 · MVP',
                    style: AppTextStyles.caption,
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}