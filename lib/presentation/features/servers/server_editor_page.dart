import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../application/servers/servers_controller.dart';
import '../../../core/ids.dart';
import '../../../core/l10n.dart';
import '../../../domain/servers/server_profile.dart';
import '../../theme/tokens.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/form_section.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/settings_tile.dart';

/// Manual server form. Fields adapt to the protocol, transport and security.
///
/// Stage 2 persists the common fields; stage 3 maps every field onto the full
/// outbound model.
class ServerEditorPage extends ConsumerStatefulWidget {
  const ServerEditorPage({super.key, this.id});

  /// `null` creates a new server.
  final String? id;

  @override
  ConsumerState<ServerEditorPage> createState() => _ServerEditorPageState();
}

class _ServerEditorPageState extends ConsumerState<ServerEditorPage> {
  static const _v2rayTransports = ['tcp', 'ws', 'grpc', 'h2', 'httpupgrade'];
  static const _ssMethods = [
    '2022-blake3-aes-128-gcm',
    '2022-blake3-aes-256-gcm',
    '2022-blake3-chacha20-poly1305',
    'aes-128-gcm',
    'aes-256-gcm',
    'chacha20-ietf-poly1305',
  ];
  static const _fingerprints = ['chrome', 'firefox', 'safari', 'edge', 'ios', 'android', 'random'];

  final _form = GlobalKey<FormState>();
  final _fields = <String, TextEditingController>{};
  ServerProfile? _existing;

  late ProxyProtocol _protocol;
  late String _transport;
  late String _security;
  String _method = _ssMethods.first;
  String _fingerprint = _fingerprints.first;
  String _flow = '';
  bool _insecure = false;

  TextEditingController _c(String key) => _fields.putIfAbsent(key, TextEditingController.new);

  @override
  void initState() {
    super.initState();
    final servers = ref.read(serversProvider).value ?? const [];
    _existing = widget.id == null ? null : servers.where((s) => s.id == widget.id).firstOrNull;
    final e = _existing;
    _protocol = e?.protocol ?? ProxyProtocol.vless;
    _transport = e?.transport ?? 'tcp';
    _security = e?.security ?? 'tls';
    if (e != null) {
      _c('name').text = e.name;
      _c('host').text = e.host;
      _c('port').text = '${e.port}';
    } else {
      _c('port').text = '443';
    }
  }

  @override
  void dispose() {
    for (final c in _fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _hasV2rayTransport =>
      const {ProxyProtocol.vless, ProxyProtocol.vmess, ProxyProtocol.trojan}.contains(_protocol);

  bool get _hasTls =>
      _protocol != ProxyProtocol.shadowsocks && _protocol != ProxyProtocol.wireguard;

  /// QUIC-based protocols always use TLS.
  bool get _tlsForced => _protocol == ProxyProtocol.hysteria2 || _protocol == ProxyProtocol.tuic;

  void _setProtocol(ProxyProtocol p) => setState(() {
    _protocol = p;
    if (!_hasV2rayTransport) _transport = p == ProxyProtocol.wireguard ? 'udp' : 'quic';
    if (_hasV2rayTransport && !_v2rayTransports.contains(_transport)) _transport = 'tcp';
    if (_tlsForced) _security = 'tls';
    if (!_hasTls) _security = 'none';
    if (_security == 'reality' && p != ProxyProtocol.vless) _security = 'tls';
  });

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final host = _c('host').text.trim();
    final name = _c('name').text.trim();
    await ref
        .read(serverActionsProvider)
        .save(
          ServerProfile(
            id: _existing?.id ?? newId(),
            subscriptionId: _existing?.subscriptionId,
            name: name.isEmpty ? host : name,
            protocol: _protocol,
            host: host,
            port: int.parse(_c('port').text.trim()),
            transport: _transport,
            security: _security,
            favorite: _existing?.favorite ?? false,
          ),
        );
    if (mounted) context.pop();
  }

  Widget _text(
    String key,
    String label, {
    IconData? icon,
    bool required = false,
    bool obscure = false,
    TextInputType? keyboard,
    String? hint,
    String? Function(String)? validate,
  }) {
    final l10n = context.l10n;
    return TextFormField(
      controller: _c(key),
      obscureText: obscure,
      keyboardType: keyboard,
      autocorrect: false,
      enableSuggestions: false,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon == null ? null : Icon(icon, size: 18),
      ),
      validator: (v) {
        final s = v?.trim() ?? '';
        if (required && s.isEmpty) return l10n.editorRequired;
        return validate?.call(s);
      },
    );
  }

  Widget _dropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String> onChanged, {
    String Function(String)? display,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final i in items) DropdownMenuItem(value: i, child: Text(display?.call(i) ?? i)),
      ],
      onChanged: (v) => v == null ? null : setState(() => onChanged(v)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = _protocol;

    final credentials = <Widget>[
      if (p == ProxyProtocol.vless || p == ProxyProtocol.vmess || p == ProxyProtocol.tuic)
        _text('uuid', l10n.editorUuid, icon: LucideIcons.keyRound, required: true),
      if (p == ProxyProtocol.trojan ||
          p == ProxyProtocol.shadowsocks ||
          p == ProxyProtocol.hysteria2 ||
          p == ProxyProtocol.tuic)
        _text(
          'password',
          l10n.editorPassword,
          icon: LucideIcons.lock,
          required: true,
          obscure: true,
        ),
      if (p == ProxyProtocol.shadowsocks)
        _dropdown(l10n.editorMethod, _method, _ssMethods, (v) => _method = v),
      if (p == ProxyProtocol.vless)
        _dropdown(
          l10n.editorFlow,
          _flow,
          const ['', 'xtls-rprx-vision'],
          (v) => _flow = v,
          display: (v) => v.isEmpty ? '—' : v,
        ),
      if (p == ProxyProtocol.wireguard) ...[
        _text(
          'privateKey',
          l10n.editorPrivateKey,
          icon: LucideIcons.keyRound,
          required: true,
          obscure: true,
        ),
        _text('peerPublicKey', l10n.editorPeerPublicKey, icon: LucideIcons.key, required: true),
        _text('localAddress', l10n.editorLocalAddress, hint: '10.0.0.2/32', required: true),
      ],
    ];

    return PageScaffold(
      opaque: true,
      title: _existing == null ? l10n.editorNewTitle : l10n.editorEditTitle,
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
                      _text('name', l10n.editorName, icon: LucideIcons.tag),
                      DropdownButtonFormField<ProxyProtocol>(
                        initialValue: _protocol,
                        isExpanded: true,
                        decoration: InputDecoration(labelText: l10n.editorProtocol),
                        items: [
                          for (final v in ProxyProtocol.values)
                            DropdownMenuItem(value: v, child: Text(v.label)),
                        ],
                        onChanged: (v) => v == null ? null : _setProtocol(v),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: _text(
                              'host',
                              l10n.editorAddress,
                              icon: LucideIcons.server,
                              required: true,
                              keyboard: TextInputType.url,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            flex: 2,
                            child: _text(
                              'port',
                              l10n.editorPort,
                              required: true,
                              keyboard: TextInputType.number,
                              validate: (s) {
                                final n = int.tryParse(s);
                                return n == null || n < 1 || n > 65535
                                    ? l10n.editorInvalidPort
                                    : null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  FormSection(title: l10n.editorCredentials, children: credentials),
                  if (_hasV2rayTransport)
                    FormSection(
                      title: l10n.editorTransport,
                      children: [
                        _dropdown(
                          l10n.editorTransport,
                          _transport,
                          _v2rayTransports,
                          (v) => _transport = v,
                          display: (v) => v.toUpperCase(),
                        ),
                        if (_transport == 'ws' ||
                            _transport == 'h2' ||
                            _transport == 'httpupgrade') ...[
                          _text('path', l10n.editorPath, hint: '/'),
                          _text('hostHeader', l10n.editorHost),
                        ],
                        if (_transport == 'grpc') _text('serviceName', l10n.editorServiceName),
                      ],
                    ),
                  if (_hasTls)
                    FormSection(
                      title: l10n.editorSecurity,
                      children: [
                        if (!_tlsForced)
                          FormSegmented<String>(
                            label: l10n.editorSecurity,
                            value: _security,
                            options: {
                              'none': l10n.editorSecurityNone,
                              'tls': 'TLS',
                              if (p == ProxyProtocol.vless) 'reality': 'Reality',
                            },
                            onChanged: (v) => setState(() => _security = v),
                          ),
                        if (_security != 'none') ...[
                          _text('sni', l10n.editorSni, icon: LucideIcons.globe),
                          _dropdown(
                            l10n.editorFingerprint,
                            _fingerprint,
                            _fingerprints,
                            (v) => _fingerprint = v,
                          ),
                        ],
                        if (_security == 'reality') ...[
                          _text('publicKey', l10n.editorPublicKey, required: true),
                          _text('shortId', l10n.editorShortId),
                        ],
                        if (_security == 'tls')
                          SettingsTile(
                            icon: LucideIcons.shieldAlert,
                            title: l10n.editorAllowInsecure,
                            padding: EdgeInsets.zero,
                            trailing: Switch(
                              value: _insecure,
                              onChanged: (v) => setState(() => _insecure = v),
                            ),
                          ),
                      ],
                    ),
                  const SizedBox(height: AppSpacing.xxl),
                  GradientButton(
                    label: l10n.save,
                    icon: LucideIcons.check,
                    expand: true,
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
