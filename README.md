# Aurora VPN

Cross-platform VPN client for **your own** subscriptions and configs, in the
spirit of Happ / v2rayNG. It ships **no servers**, no telemetry and no
analytics; subscriptions and configs never leave the device.

- **Platforms:** Android (APK) and Windows (installer / portable zip) from one
  Flutter codebase.
- **Core:** [sing-box](https://github.com/SagerNet/sing-box) 1.14 for TUN, DNS
  and routing, plus [Xray-core](https://github.com/XTLS/Xray-core) 26.3 for
  what sing-box lacks (XHTTP, raw Xray JSON outbounds).
  VLESS (Reality, Vision), VMess, Trojan, Shadowsocks (incl. 2022), Hysteria2,
  TUIC, WireGuard; transports tcp / ws / grpc / h2 / httpupgrade / xhttp.
- **Subscriptions:** URL, clipboard, QR (Android), deep links
  (`vless://`, `vmess://`, `trojan://`, `ss://`, `hysteria2://`, `tuic://`,
  `wireguard://`, `happ://add/…`); base64 / plain / sing-box JSON / Xray JSON /
  Clash YAML; `subscription-userinfo`, `profile-update-interval`,
  `profile-title`; optional HWID headers for device-limited panels.
- **Routing:** Global / Rules / Direct, LAN bypass, Russian sites direct
  (geoip/geosite), ad blocking, per-app split tunneling (Android).
- **Windows:** system proxy (no admin) or TUN (admin), tray with
  connect/disconnect, close to tray, single instance, autostart minimized.

Design log and per-stage decisions: [`docs/DECISIONS.md`](docs/DECISIONS.md).

## Install

Download from [Releases](https://github.com/wepper6200/Aurora-VPN-Client/releases)
or from the latest green [CI run](https://github.com/wepper6200/Aurora-VPN-Client/actions)
(artifacts `aurora-vpn-android`, `aurora-vpn-windows`).

- **Android:** `AuroraVPN-<ver>-android-arm64-v8a.apk` fits almost every
  phone; `-universal.apk` works everywhere (bigger).
- **Windows 10/11 x64:** `AuroraVPN-<ver>-windows-x64-setup.exe` (per-user
  install, no admin needed, registers `vless://`/`happ://`… links) or the
  portable zip: unpack anywhere and run `aurora_vpn.exe`; keep the `core`
  folder next to it. TUN mode asks to restart as administrator.

## Building

Toolchain: Flutter 3.47, JDK 17, Go 1.26 (libbox; pinned via `GOTOOLCHAIN`),
Android SDK + NDK 28.2. Windows builds additionally need Visual Studio 2022
with the "Desktop development with C++" workload, and Inno Setup 6 for the
installer.

```bash
# Android: libbox (gomobile, once), rule sets, per-ABI + universal APKs -> dist/
bash ./scripts/build_android.sh
```

```powershell
# Windows: core binaries, flutter build, portable zip (+ installer) -> dist/
./scripts/build_windows.ps1 -Installer
```

Core binaries and rule sets come from the official releases with pinned
SHA-256 (`scripts/core_versions.json`, `scripts/fetch_core.ps1`); they are
never committed. `scripts/build_libbox.ps1` is the Windows variant of
`build_libbox.sh`.

### CI and releases

`.github/workflows/build.yml` runs analyze + tests, then builds the Android
APKs and the Windows zip + installer on every push. Pushing a tag `v*`
(e.g. `git tag v0.1.0 && git push origin v0.1.0`) also creates a **draft**
GitHub release with all files attached; review and publish it by hand.
Bump `version:` in `pubspec.yaml` first.

### Release signing (Android)

Create `android/key.properties` (never commit it):

```properties
storeFile=app/release.jks
storePassword=…
keyAlias=…
keyPassword=…
```

Generate a key with
`keytool -genkeypair -v -keystore android/app/release.jks -keyalg RSA -keysize 4096 -validity 10000 -alias aurora`
and keep a backup: updates must be signed with the same key.
In CI, provide `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`,
`ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD` as repository secrets. Without
them, release builds are signed with the debug key (fine for testing only).

The Windows binaries are not code-signed, so SmartScreen may warn on first
run ("More info" → "Run anyway").

### Icons

App, window and tray icons are rendered from the in-app logo:
`flutter test tool/icons/render_icons_test.dart`.

## Tests

```bash
flutter test --exclude-tags golden,core,tool   # unit + widget
flutter test --tags golden                     # screen goldens (Windows rendering)
flutter test --tags core                       # configs vs. real sing-box/xray, Windows controller
```

## License

GPL-3.0-or-later — see [`LICENSE`](LICENSE). The app links sing-box, which is
GPLv3 with additional terms, and Xray-core (MPL-2.0); third-party notices are
in [`THIRD_PARTY_LICENSES.md`](THIRD_PARTY_LICENSES.md).
