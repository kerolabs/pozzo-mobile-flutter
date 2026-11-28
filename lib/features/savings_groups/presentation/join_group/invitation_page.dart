import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:pozzo/core/widgets/pozzo_buttons.dart';
import 'package:pozzo/core/widgets/pozzo_components.dart';
import 'package:pozzo/features/savings_groups/domain/savings_group.dart';
import 'package:pozzo/features/savings_groups/presentation/group_detail/group_detail_page.dart';

/// G3: "¡Tu junta está lista!", the code and the link to share. From the detail it only shows them
/// again and goes back.
class InvitationPage extends StatelessWidget {
  const InvitationPage({
    super.key,
    required this.group,
    required this.invitation,
    this.fromDetail = false,
  });

  final SavingsGroup group;
  final Invitation invitation;
  final bool fromDetail;

  Future<void> _copy(BuildContext context, String label, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) showMessage(context, '$label copiado');
  }
  Future<void> _shareInvitation(
    BuildContext context, String message) async {
    try {
      final box = context.findRenderObject() as RenderBox?;

      await SharePlus.instance.share(
        ShareParams(
          text: message,
          title: 'Compartir invitación',
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } catch (_) {
      if (context.mounted) {
        showMessage(context, 'No se pudo compartir la invitación.');
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final link = invitation.link;
    final shortLink = link.replaceFirst(RegExp(r'^https?://'), '');
    final message =
        'Únete a mi junta "${group.name}" en Pozzo. Abre $link o ingresa el código ${invitation.code}.';
    return Scaffold(
      appBar: fromDetail ? AppBar(title: const Text('Invitación')) : null,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 24,
                ),
                children: [
                  const Center(
                    child: ResultBadge(icon: Icons.celebration_outlined),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '¡Tu junta está lista!',
                    textAlign: TextAlign.center,
                    style: text.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Comparte el código o el enlace para que tu grupo se una.',
                    textAlign: TextAlign.center,
                    style: text.bodyLarge?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Código de invitación',
                            style: text.titleSmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  invitation.code,
                                  style: text.displayMedium,
                                ),
                              ),
                              IconButton(
                                tooltip: 'Copiar código',
                                onPressed: () =>
                                    _copy(context, 'Código', invitation.code),
                                icon: Icon(
                                  Icons.content_copy_outlined,
                                  color: colors.primary,
                                ),
                              ),
                            ],
                          ),
                          Divider(height: 24, color: colors.outlineVariant),
                          Row(
                            children: [
                              Icon(Icons.link, color: colors.onSurfaceVariant),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(shortLink, style: text.bodyLarge),
                              ),
                              IconButton(
                                tooltip: 'Copiar enlace',
                                onPressed: () => _copy(context, 'Enlace', link),
                                icon: Icon(
                                  Icons.content_copy_outlined,
                                  color: colors.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Los integrantes se unen sin que tengas que registrarlos uno por uno.',
                    style: text.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            BottomActions(
              children: [
                PozzoPrimaryButton(
                  text: 'Compartir invitación',
                  icon: Icons.share_outlined,
                  onPressed: () => _shareInvitation(context, message),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    if (fromDetail) {
                      Navigator.pop(context);
                    } else {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              GroupDetailPage(groupId: group.id),
                        ),
                      );
                    }
                  },
                  child: Text(
                    fromDetail ? 'Volver a la junta' : 'Ir a mi junta',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
