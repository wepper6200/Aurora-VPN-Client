import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../application/servers/servers_controller.dart';
import '../../../core/ids.dart';
import '../../../core/l10n.dart';
import '../../../domain/subscriptions/subscription.dart';
import '../../theme/tokens.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/form_section.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/settings_tile.dart';

class SubscriptionEditorPage extends ConsumerStatefulWidget {
  const SubscriptionEditorPage({super.key, this.id, this.initialUrl});

  /// `null` creates a new subscription.
  final String? id;
  final String? initialUrl;

  @override
  ConsumerState<SubscriptionEditorPage> createState() => _SubscriptionEditorPageState();
}

class _SubscriptionEditorPageState extends ConsumerState<SubscriptionEditorPage> {
  static const intervals = [1, 3, 6, 12, 24];

  final _form = GlobalKey<FormState>();
  late final TextEditingController _url;
  late final TextEditingController _name;
  late bool _autoUpdate;
  late int _hours;
  Subscription? _existing;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final subs = ref.read(subscriptionsProvider).value ?? const [];
    _existing = widget.id == null ? null : subs.where((s) => s.id == widget.id).firstOrNull;
    _url = TextEditingController(text: _existing?.url ?? widget.initialUrl ?? '');
    _name = TextEditingController(text: _existing?.name ?? '');
    _autoUpdate = _existing?.autoUpdate ?? true;
    _hours = _existing?.updateInterval.inHours ?? 12;
    if (!intervals.contains(_hours)) _hours = 12;
  }

  @override
  void dispose() {
    _url.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final text = (await Clipboard.getData(Clipboard.kTextPlain))?.text?.trim();
    if (text != null && text.isNotEmpty) _url.text = text;
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final url = _url.text.trim();
    final name = _name.text.trim().isEmpty ? Uri.parse(url).host : _name.text.trim();
    await ref
        .read(serverActionsProvider)
        .saveSubscription(
          Subscription(
            id: _existing?.id ?? newId(),
            name: name,
            url: url,
            updatedAt: _existing?.updatedAt,
            updateInterval: Duration(hours: _hours),
            autoUpdate: _autoUpdate,
            usage: _existing?.usage,
            supportUrl: _existing?.supportUrl,
          ),
        );
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PageScaffold(
      opaque: true,
      title: _existing == null ? l10n.subAddTitle : l10n.subEditTitle,
      leading: AppIconButton(icon: LucideIcons.arrowLeft, onPressed: () => context.pop()),
      slivers: [
        PagePadding(
          child: SliverToBoxAdapter(
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FormSection(
                    title: l10n.editorGeneral,
                    children: [
                      TextFormField(
                        controller: _url,
                        autofocus: _existing == null && widget.initialUrl == null,
                        keyboardType: TextInputType.url,
                        decoration: InputDecoration(
                          labelText: l10n.subUrlLabel,
                          hintText: 'https://',
                          prefixIcon: const Icon(LucideIcons.link, size: 18),
                          suffixIcon: IconButton(
                            tooltip: l10n.paste,
                            icon: const Icon(LucideIcons.clipboardPaste, size: 18),
                            onPressed: _paste,
                          ),
                        ),
                        validator: (v) {
                          final uri = Uri.tryParse(v?.trim() ?? '');
                          final ok =
                              uri != null &&
                              (uri.scheme == 'http' || uri.scheme == 'https') &&
                              uri.host.isNotEmpty;
                          return ok ? null : l10n.subInvalidUrl;
                        },
                      ),
                      TextFormField(
                        controller: _name,
                        decoration: InputDecoration(
                          labelText: l10n.subNameLabel,
                          prefixIcon: const Icon(LucideIcons.tag, size: 18),
                        ),
                      ),
                    ],
                  ),
                  FormSection(
                    title: l10n.subAutoUpdate,
                    children: [
                      SettingsTile(
                        icon: LucideIcons.refreshCw,
                        title: l10n.subAutoUpdate,
                        subtitle: l10n.subAutoUpdateSub,
                        padding: EdgeInsets.zero,
                        trailing: Switch(
                          value: _autoUpdate,
                          onChanged: (v) => setState(() => _autoUpdate = v),
                        ),
                      ),
                      AnimatedSize(
                        duration: AppDurations.medium,
                        curve: AppCurves.standard,
                        child: !_autoUpdate
                            ? const SizedBox(width: double.infinity)
                            : FormSegmented<int>(
                                label: l10n.subUpdateInterval,
                                value: _hours,
                                options: {for (final h in intervals) h: l10n.hoursShort(h)},
                                onChanged: (v) => setState(() => _hours = v),
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  GradientButton(
                    label: l10n.save,
                    icon: LucideIcons.check,
                    expand: true,
                    loading: _saving,
                    onPressed: _save,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
