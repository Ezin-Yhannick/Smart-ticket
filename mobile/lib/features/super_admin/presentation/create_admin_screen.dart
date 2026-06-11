import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../shared/models/event_model.dart';

class CreateAdminScreen extends ConsumerStatefulWidget {
  const CreateAdminScreen({super.key});

  @override
  ConsumerState<CreateAdminScreen> createState() =>
      _CreateAdminScreenState();
}

class _CreateAdminScreenState
    extends ConsumerState<CreateAdminScreen> {

  final _formKey      = GlobalKey<FormState>();
  final _nameCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _maxTicketsCtrl = TextEditingController();

  bool _obscurePassword = true;
  final Set<EventType> _allowedTypes = {};
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _maxTicketsCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_allowedTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sélectionnez au moins un type d\'événement'),
          backgroundColor: AppColors.statusSuspended,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final token = ref.read(authStateProvider).token!;
      await ApiService.createAdmin(
        token: token,
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Administrateur ${_nameCtrl.text} créé avec succès !'),
            backgroundColor: AppColors.statusActive,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
        context.go('/super-admin/admins');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
            Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvel administrateur',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/super-admin/admins'),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              _SectionLabel(
                icon: Icons.person_outline_rounded,
                title: 'Informations personnelles',
              ),
              const SizedBox(height: 12),

              _FieldLabel('Nom complet'),
              TextFormField(
                controller: _nameCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'Ex: ASSOUMA Kamal',
                  prefixIcon: Icon(Icons.person_outline_rounded,
                      color: AppColors.textTertiary, size: 20),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Champ requis';
                  if (v.trim().length < 3) return 'Nom trop court';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _FieldLabel('Adresse email'),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Ex: k.assouma@epac.bj',
                  prefixIcon: Icon(Icons.mail_outline_rounded,
                      color: AppColors.textTertiary, size: 20),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Champ requis';
                  if (!v.contains('@') || !v.contains('.')) {
                    return 'Email invalide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              _SectionLabel(
                icon: Icons.lock_outline_rounded,
                title: 'Mot de passe temporaire',
              ),
              const SizedBox(height: 12),

              _FieldLabel('Mot de passe'),
              TextFormField(
                controller: _passwordCtrl,
                obscureText: _obscurePassword,
                style: const TextStyle(color: AppColors.textPrimary),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Minimum 8 caractères',
                  prefixIcon: const Icon(Icons.lock_outline_rounded,
                      color: AppColors.textTertiary, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.textTertiary, size: 20,
                    ),
                    onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Champ requis';
                  if (v.length < 8) return 'Minimum 8 caractères';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              _PasswordStrengthIndicator(
                  password: _passwordCtrl.text),
              const SizedBox(height: 24),

              _SectionLabel(
                icon: Icons.verified_user_outlined,
                title: 'Types d\'événements autorisés',
              ),
              const SizedBox(height: 4),
              const Text(
                'Sélectionnez les types d\'événements que cet admin '
                    'aura le droit de créer.',
                style: AppTextStyles.adminSubtitle,
              ),
              const SizedBox(height: 12),

              ...EventType.values.map((type) {
                final isSelected = _allowedTypes.contains(type);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GestureDetector(
                    onTap: () => setState(() {
                      if (isSelected) {
                        _allowedTypes.remove(type);
                      } else {
                        _allowedTypes.add(type);
                      }
                    }),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withOpacity(0.1)
                            : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary.withOpacity(0.5)
                              : Colors.transparent,
                          width: 1,
                        ),
                      ),
                      child: Row(children: [
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withOpacity(0.2)
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _typeIcon(type),
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textTertiary,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(type.label,
                              style: TextStyle(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              )),
                        ),
                        Container(
                          width: 22, height: 22,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textTertiary,
                              width: 1.5,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(Icons.check_rounded,
                              color: Colors.white, size: 14)
                              : null,
                        ),
                      ]),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),

              _SectionLabel(
                icon: Icons.tune_rounded,
                title: 'Limite de tickets (optionnel)',
              ),
              const SizedBox(height: 4),
              const Text(
                'Nombre maximum de tickets par événement. '
                    'Laissez vide pour aucune limite.',
                style: AppTextStyles.adminSubtitle,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _maxTicketsCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly
                ],
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Ex: 1000 (laisser vide = illimité)',
                  prefixIcon: Icon(
                      Icons.confirmation_number_outlined,
                      color: AppColors.textTertiary, size: 20),
                  suffixText: 'tickets max',
                  suffixStyle: TextStyle(
                      color: AppColors.textTertiary, fontSize: 13),
                ),
                validator: (v) {
                  if (v != null && v.isNotEmpty) {
                    final n = int.tryParse(v);
                    if (n == null || n <= 0) return 'Nombre invalide';
                    if (n > 100000) return 'Maximum 100 000 tickets';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.iconBlueBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(children: [
                  Icon(Icons.info_outline_rounded,
                      color: AppColors.iconBlue, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'L\'administrateur pourra se connecter '
                          'immédiatement avec ces identifiants.',
                      style: TextStyle(
                          color: AppColors.iconBlue, fontSize: 12),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                      : const Text('Créer l\'administrateur'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionLabel({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, color: AppColors.textSecondary, size: 18),
    const SizedBox(width: 8),
    Text(title, style: AppTextStyles.sectionTitle),
  ]);
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(
        fontSize: 13, fontWeight: FontWeight.w500,
        color: AppColors.textSecondary)),
  );
}

class _PasswordStrengthIndicator extends StatelessWidget {
  final String password;
  const _PasswordStrengthIndicator({required this.password});

  int get _strength {
    if (password.isEmpty) return 0;
    int score = 0;
    if (password.length >= 8) score++;
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[!@#$%^&*]'))) score++;
    return score;
  }

  String get _label {
    switch (_strength) {
      case 1: return 'Faible';
      case 2: return 'Moyen';
      case 3: return 'Fort';
      case 4: return 'Très fort';
      default: return '';
    }
  }

  Color get _color {
    switch (_strength) {
      case 1: return AppColors.statusSuspended;
      case 2: return AppColors.statusPending;
      case 3: return AppColors.statusActive;
      case 4: return AppColors.primary;
      default: return AppColors.surfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: List.generate(4, (i) => Expanded(
        child: Container(
          margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
          height: 4,
          decoration: BoxDecoration(
            color: i < _strength
                ? _color
                : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ))),
      const SizedBox(height: 4),
      Text(_label, style: TextStyle(
          color: _color, fontSize: 11,
          fontWeight: FontWeight.w500)),
    ]);
  }
}

IconData _typeIcon(EventType type) {
  switch (type) {
    case EventType.concert:  return Icons.music_note_outlined;
    case EventType.foire:    return Icons.storefront_outlined;
    case EventType.marche:   return Icons.shopping_basket_outlined;
    case EventType.festival: return Icons.celebration_outlined;
    case EventType.autre:    return Icons.event_outlined;
  }
}