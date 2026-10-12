import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart';

import 'platform.dart';

/// What device-limited subscription panels (Remnawave and compatible) expect:
/// a stable per-device id plus OS and model.
///
/// The id is random and generated once per install — not a hardware serial,
/// IMEI or account id — and is only sent to subscription URLs the user added.
class DeviceIdentity {
  const DeviceIdentity({
    required this.hwid,
    required this.os,
    required this.osVersion,
    required this.model,
  });

  final String hwid;
  final String os;
  final String osVersion;
  final String model;

  Map<String, String> get headers => {
    'x-hwid': hwid,
    'x-device-os': os,
    'x-ver-os': osVersion,
    'x-device-model': model,
  };

  static String newHwid() {
    final rnd = Random.secure();
    return List.generate(16, (_) => rnd.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  }

  static Future<DeviceIdentity> load(AppPlatform platform, String hwid) async {
    switch (platform) {
      case AppPlatform.android:
        final info = await const MethodChannel('aurora/vpn')
            .invokeMapMethod<String, String>('deviceInfo')
            .catchError((_) => <String, String>{});
        return DeviceIdentity(
          hwid: hwid,
          os: 'Android',
          osVersion: info?['osVersion'] ?? '',
          model: info?['model'] ?? 'Android',
        );
      case AppPlatform.windows:
        // "Windows 10 Pro" 10.0 (Build 26300) → 10.0.26300
        final v = RegExp(r'(\d+\.\d+).*?Build (\d+)').firstMatch(Platform.operatingSystemVersion);
        return DeviceIdentity(
          hwid: hwid,
          os: 'Windows',
          osVersion: v == null ? Platform.operatingSystemVersion : '${v[1]}.${v[2]}',
          model: 'PC',
        );
      case AppPlatform.other:
        return DeviceIdentity(hwid: hwid, os: Platform.operatingSystem, osVersion: '', model: '');
    }
  }
}
