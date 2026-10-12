import 'package:flutter/material.dart';

import '../../../core/l10n.dart';
import '../../../domain/settings/app_settings.dart';
import '../../theme/tokens.dart';

/// Well-known public resolvers offered as one-tap presets.
const _dnsPresets = <String, Map<DnsProtocol, String>>{
  'Cloudflare': {
    DnsProtocol.doh: 'https://1.1.1.1/dns-query',
    DnsProtocol.dot: 'tls://1.1.1.1',
    DnsProtocol.udp: '1.1.1.1',
  },
  'Google': {
    DnsProtocol.doh: 'https://dns.google/dns-query',
    DnsProtocol.dot: 'tls://dns.google',
    DnsProtocol.udp: '8.8.8.8',
  },
  'Quad9': {
    DnsProtocol.doh: 'https://dns.quad9.net/dns-query',
    DnsProtocol.dot: 'tls://dns.quad9.net',
    DnsProtocol.udp: '9.9.9.9',
  },
  'AdGuard': {
    DnsProtocol.doh: 'https://dns.adguard-dns.com/dns-query',
    DnsProtocol.dot: 'tls://dns.adguard-dns.com',
    DnsProtocol.udp: '94.140.14.14',
  },
};

typedef DnsChoice = ({DnsProtocol protocol, String server});

Future<DnsChoice?> showDnsDialog(BuildContext context, DnsProtocol protocol, String server) {
  return showDialog<DnsChoice>(
    context: context,
    builder: (_) => _DnsDialog(protocol: protocol, server: server),
  );
}

class _DnsDialog extends StatefulWidget {
  const _DnsDialog({required this.protocol, required this.server});

  final DnsProtocol protocol;
  final String server;

  @override
  State<_DnsDialog> createState() => _DnsDialogState();
}

class _DnsDialogState extends State<_DnsDialog> {
  late DnsProtocol _protocol = widget.protocol;
  late final _server = TextEditingController(text: widget.server);

  @override
  void dispose() {
    _server.dispose();
    super.dispose();
  }

  String? _presetFor(String server) {
    for (final e in _dnsPresets.entries) {
      if (e.value.containsValue(server)) return e.key;
    }
    return null;
  }

  void _setProtocol(DnsProtocol p) {
    // Keep the chosen preset when switching protocol.
    final preset = _presetFor(_server.text.trim());
    setState(() {
      _protocol = p;
      if (preset != null) _server.text = _dnsPresets[preset]![p]!;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final preset = _presetFor(_server.text.trim());
    return AlertDialog(
      title: Text(l10n.settingsDns),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<DnsProtocol>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: DnsProtocol.doh, label: Text('DoH')),
                ButtonSegment(value: DnsProtocol.dot, label: Text('DoT')),
                ButtonSegment(value: DnsProtocol.udp, label: Text('UDP')),
              ],
              selected: {_protocol},
              onSelectionChanged: (s) => _setProtocol(s.first),
            ),
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final name in _dnsPresets.keys)
                  ChoiceChip(
                    label: Text(name),
                    selected: preset == name,
                    onSelected: (_) =>
                        setState(() => _server.text = _dnsPresets[name]![_protocol]!),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _server,
              autocorrect: false,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(labelText: l10n.settingsDns),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancel)),
        TextButton(
          onPressed: _server.text.trim().isEmpty
              ? null
              : () => Navigator.of(context).pop((protocol: _protocol, server: _server.text.trim())),
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

Future<int?> showMtuDialog(BuildContext context, int current) => showDialog<int>(
  context: context,
  builder: (_) => _MtuDialog(current: current),
);

class _MtuDialog extends StatefulWidget {
  const _MtuDialog({required this.current});

  final int current;

  @override
  State<_MtuDialog> createState() => _MtuDialogState();
}

class _MtuDialogState extends State<_MtuDialog> {
  late final _controller = TextEditingController(text: '${widget.current}');
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.settingsMtu),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(helperText: l10n.settingsMtuHint),
          validator: (v) {
            final n = int.tryParse(v?.trim() ?? '');
            return n == null || n < 1280 || n > 9000 ? l10n.settingsMtuHint : null;
          },
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancel)),
        TextButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop(int.parse(_controller.text.trim()));
            }
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
