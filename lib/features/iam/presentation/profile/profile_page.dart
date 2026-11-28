import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pozzo/core/service_locator.dart';
import 'package:pozzo/core/widgets/pozzo_buttons.dart';
import 'package:pozzo/core/widgets/pozzo_components.dart';
import 'package:pozzo/core/widgets/pozzo_text_field.dart';
import 'package:pozzo/features/iam/domain/profile.dart';
import 'package:pozzo/features/iam/presentation/profile/change_phone_page.dart';
import 'package:pozzo/features/iam/presentation/profile/profile_view_model.dart';
import 'package:pozzo/features/iam/presentation/profile/theme_page.dart';
import 'package:url_launcher/url_launcher.dart';

/// Landing page with the Terms and Conditions and the Privacy Policy.
const String landingUrl = 'https://kerolabs.github.io/pozzo-landing-page/';

/// I1: "Perfil", the fourth tab.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ProfileViewModel viewModel = getIt<ProfileViewModel>();

  @override
  void initState() {
    super.initState();
    viewModel.load();
  }

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }

  Future<void> _open(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (context) => page));
    viewModel.load();
  }

  Future<void> _openLegal(String page) async {
    final opened = await launchUrl(Uri.parse('$landingUrl$page'), mode: LaunchMode.externalApplication);
    if (!mounted) return;
    if (!opened) showMessage(context, 'No pudimos abrir el navegador.');
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source, maxWidth: 1080, maxHeight: 1080, imageQuality: 85);
    if (picked == null) return;
    await viewModel.changePhoto(await picked.readAsBytes());
  }

  void _photoOptions(Profile profile) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Foto de perfil', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                'Tu grupo te reconoce más fácil. Se guarda recortada en cuadrado.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              _ProfileRow(
                icon: Icons.image_outlined,
                title: 'Elegir de la galería',
                onTap: () {
                  Navigator.pop(context);
                  _pickPhoto(ImageSource.gallery);
                },
              ),
              _ProfileRow(
                icon: Icons.photo_camera_outlined,
                title: 'Tomar foto',
                onTap: () {
                  Navigator.pop(context);
                  _pickPhoto(ImageSource.camera);
                },
              ),
              if (profile.photoUrl != null)
                _ProfileRow(
                  icon: Icons.delete_outline,
                  title: 'Quitar foto',
                  onTap: () {
                    Navigator.pop(context);
                    viewModel.removePhoto();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _edit({
    required String title,
    required String label,
    required String current,
    required String Function(String) sanitize,
    required Future<void> Function(String) onSave,
    String? supportingText,
    TextInputType? keyboardType,
    bool allowEmpty = true,
  }) async {
    final value = await showDialog<String>(
      context: context,
      builder: (context) => _EditDialog(
        title: title,
        label: label,
        current: current,
        sanitize: sanitize,
        supportingText: supportingText,
        keyboardType: keyboardType,
        allowEmpty: allowEmpty,
      ),
    );
    if (value != null) await onSave(value);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: viewModel,
          builder: (context, child) {
            final state = viewModel.state;
            final profile = state.profile;
            if (profile == null) {
              return LoadingOrError(loading: state.isLoading, error: state.errorMessage, onRetry: viewModel.load);
            }
            return RefreshIndicator(
              onRefresh: viewModel.load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Center(
                    child: _ProfilePhoto(
                      name: profile.displayName,
                      photoUrl: profile.photoUrl,
                      isUploading: state.isUploadingPhoto,
                      onTap: () => _photoOptions(profile),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(profile.displayName, textAlign: TextAlign.center, style: text.headlineSmall),
                  Text(
                    PhoneNumbers.display(profile.phoneNumber),
                    textAlign: TextAlign.center,
                    style: text.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 24),
                  Text('Mis datos', style: text.titleLarge),
                  _ProfileRow(
                    icon: Icons.person_outline,
                    title: 'Nombre',
                    subtitle: profile.displayName,
                    trailing: Icons.edit_outlined,
                    onTap: () => _edit(
                      title: 'Tu nombre',
                      label: 'Nombre que ve tu grupo',
                      current: profile.displayName,
                      allowEmpty: false,
                      sanitize: (value) => value.length > 80 ? value.substring(0, 80) : value,
                      onSave: viewModel.rename,
                    ),
                  ),
                  _ProfileRow(
                    icon: Icons.phone_android_outlined,
                    title: 'Número de celular',
                    subtitle: PhoneNumbers.display(profile.phoneNumber),
                    trailing: Icons.edit_outlined,
                    onTap: () => _open(const ChangePhonePage()),
                  ),
                  _ProfileRow(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Número de Yape o Plin',
                    subtitle: profile.walletNumber != null
                        ? PhoneNumbers.grouped(profile.walletNumber!)
                        : 'Tu celular, ${PhoneNumbers.display(profile.phoneNumber)}. Tócalo si usas otro',
                    trailing: Icons.edit_outlined,
                    onTap: () => _edit(
                      title: 'Número de Yape o Plin',
                      label: 'Celular donde recibes transferencias',
                      // Without a number of its own, the account's phone is proposed: most people use the same one.
                      current: profile.walletNumber ?? PhoneNumbers.local(profile.phoneNumber),
                      supportingText: 'Se propone como destino de los aportes cuando creas una junta.',
                      keyboardType: TextInputType.phone,
                      sanitize: PhoneNumbers.clean,
                      onSave: viewModel.saveWalletNumber,
                    ),
                  ),
                  _ProfileRow(
                    icon: Icons.email_outlined,
                    title: 'Correo de respaldo',
                    subtitle: profile.backupEmail ?? 'Agrégalo para recuperar tu cuenta si pierdes tu número',
                    trailing: Icons.edit_outlined,
                    onTap: () => _edit(
                      title: 'Correo de respaldo',
                      label: 'Correo',
                      current: profile.backupEmail ?? '',
                      supportingText: 'Sirve para recuperar tu cuenta si pierdes tu número. Solo lo ves tú.',
                      keyboardType: TextInputType.emailAddress,
                      sanitize: (value) => value.trim(),
                      onSave: viewModel.saveBackupEmail,
                    ),
                  ),
                  Divider(color: colors.outlineVariant),
                  const SizedBox(height: 16),
                  Text('Preferencias', style: text.titleLarge),
                  _ProfileRow(
                    icon: Icons.dark_mode_outlined,
                    title: 'Tema visual',
                    subtitle: ThemePreference.of(profile.theme).label,
                    onTap: () => _open(const ThemePage()),
                  ),
                  _ProfileRow(
                    icon: Icons.policy_outlined,
                    title: 'Términos y Condiciones',
                    onTap: () => _openLegal('terms.html'),
                  ),
                  _ProfileRow(
                    icon: Icons.shield_outlined,
                    title: 'Política de privacidad',
                    onTap: () => _openLegal('privacy.html'),
                  ),
                  ErrorText(state.errorMessage),
                  const SizedBox(height: 24),
                  PozzoOutlinedButton(text: 'Cerrar sesión', icon: Icons.logout, onPressed: viewModel.closeSession),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ProfilePhoto extends StatelessWidget {
  const _ProfilePhoto({required this.name, required this.photoUrl, required this.isUploading, required this.onTap});

  final String name;
  final String? photoUrl;
  final bool isUploading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: isUploading ? null : onTap,
      child: SizedBox(
        width: 96,
        height: 96,
        child: Stack(
          children: [
            InitialsAvatar(
              name: name,
              size: 96,
              background: colors.primaryContainer,
              foreground: colors.onPrimaryContainer,
              photoUrl: photoUrl,
            ),
            if (isUploading) const Center(child: CircularProgressIndicator()),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: colors.secondaryContainer,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.surface, width: 2),
                ),
                child: Icon(Icons.photo_camera_outlined, size: 18, color: colors.onSecondaryContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.trailing = Icons.chevron_right,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final IconData trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: colors.onSurfaceVariant),
      title: Text(title, style: Theme.of(context).textTheme.titleMedium),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: Icon(trailing, color: colors.onSurfaceVariant),
      onTap: onTap,
    );
  }
}

class _EditDialog extends StatefulWidget {
  const _EditDialog({
    required this.title,
    required this.label,
    required this.current,
    required this.sanitize,
    required this.allowEmpty,
    this.supportingText,
    this.keyboardType,
  });

  final String title;
  final String label;
  final String current;
  final String Function(String) sanitize;
  final bool allowEmpty;
  final String? supportingText;
  final TextInputType? keyboardType;

  @override
  State<_EditDialog> createState() => _EditDialogState();
}

class _EditDialogState extends State<_EditDialog> {
  late String value = widget.current;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: PozzoTextField(
        label: widget.label,
        value: value,
        autofocus: true,
        onChanged: (text) => setState(() => value = widget.sanitize(text)),
        supportingText: widget.supportingText,
        keyboardType: widget.keyboardType,
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        TextButton(
          onPressed: widget.allowEmpty || value.trim().isNotEmpty ? () => Navigator.pop(context, value) : null,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
