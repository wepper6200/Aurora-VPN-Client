import 'dart:ffi';
import 'dart:io';

/// Per-user WinINet proxy (what browsers and most apps follow).
///
/// Managed here instead of sing-box's `set_system_proxy`: on Windows the core
/// is stopped with TerminateProcess, which gives it no chance to restore the
/// setting, and a proxy left pointing at a dead port cuts the user off.
abstract interface class SystemProxy {
  Future<void> enable(String host, int port);
  Future<void> disable();

  /// The proxy currently configured, e.g. `127.0.0.1:2080`, or null.
  Future<String?> current();
}

class WindowsSystemProxy implements SystemProxy {
  const WindowsSystemProxy();

  static const _key = r'HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings';

  /// Loopback and private ranges (172.16.0.0/12 spelled out: a `172.2*`
  /// wildcard would also catch public addresses such as 172.217.x.x).
  static final _bypass = [
    'localhost',
    '127.*',
    '10.*',
    for (var i = 16; i <= 31; i++) '172.$i.*',
    '192.168.*',
    '<local>',
  ].join(';');

  @override
  Future<void> enable(String host, int port) async {
    await _reg(['add', _key, '/v', 'ProxyServer', '/t', 'REG_SZ', '/d', '$host:$port', '/f']);
    await _reg(['add', _key, '/v', 'ProxyOverride', '/t', 'REG_SZ', '/d', _bypass, '/f']);
    await _reg(['add', _key, '/v', 'ProxyEnable', '/t', 'REG_DWORD', '/d', '1', '/f']);
    _notify();
  }

  @override
  Future<void> disable() async {
    await _reg(['add', _key, '/v', 'ProxyEnable', '/t', 'REG_DWORD', '/d', '0', '/f']);
    _notify();
  }

  @override
  Future<String?> current() async {
    final enabled = await Process.run('reg', ['query', _key, '/v', 'ProxyEnable']);
    if (!'${enabled.stdout}'.contains('0x1')) return null;
    final server = await Process.run('reg', ['query', _key, '/v', 'ProxyServer']);
    final m = RegExp(r'ProxyServer\s+REG_SZ\s+(\S+)').firstMatch('${server.stdout}');
    return m?.group(1);
  }

  static Future<void> _reg(List<String> args) async {
    final r = await Process.run('reg', args);
    if (r.exitCode != 0) throw ProcessException('reg', args, '${r.stderr}', r.exitCode);
  }

  /// INTERNET_OPTION_SETTINGS_CHANGED + INTERNET_OPTION_REFRESH so running
  /// apps pick the change up immediately.
  static void _notify() {
    try {
      final wininet = DynamicLibrary.open('wininet.dll');
      final setOption = wininet
          .lookupFunction<
            Int32 Function(IntPtr, Uint32, Pointer<Void>, Uint32),
            int Function(int, int, Pointer<Void>, int)
          >('InternetSetOptionW');
      setOption(0, 39, nullptr, 0);
      setOption(0, 37, nullptr, 0);
    } catch (_) {
      // Settings still apply to new connections.
    }
  }
}
