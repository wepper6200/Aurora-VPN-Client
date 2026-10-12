# Aurora VPN

Cross-platform VPN client for **your own** subscriptions and configs, in the
spirit of Happ / v2rayNG. It ships **no servers**, no telemetry and no
analytics; subscriptions and configs never leave the device.

- **Platforms:** Android (APK) and Windows (installer / portable) from one
  Flutter codebase.
- **Core:** [sing-box](https://github.com/SagerNet/sing-box) 1.14 —
  VLESS (Reality, Vision), VMess, Trojan, Shadowsocks (incl. 2022),
  Hysteria2, TUIC, WireGuard; transports tcp / ws / grpc / h2 / httpupgrade.
- **Subscriptions:** URL, clipboard, QR (Android), deep links
  (`vless://`, `vmess://`, `trojan://`, `ss://`, `hysteria2://`, `tuic://`,
  `wireguard://`, `happ://add/…`); base64 / plain / sing-box JSON / Clash YAML;
  `subscription-userinfo`, `profile-update-interval`, `profile-title`.

> Work in progress — see [`docs/DECISIONS.md`](docs/DECISIONS.md) for the
> design log and current stage.

## Building

Toolchain: Flutter 3.47, JDK 17, Go (for libbox), Android SDK + NDK 28.2;
Windows builds additionally need Visual Studio 2022 with C++ tools.

```bash
# 1. Core binaries and rule sets (official releases, SHA-256 pinned)
pwsh ./scripts/fetch_core.ps1
# 2. Android core (gomobile)
bash ./scripts/build_libbox.sh          # or ./scripts/build_libbox.ps1 on Windows
# 3. Apps
flutter build apk --release --split-per-abi
flutter build windows --release
```

CI (`.github/workflows/build.yml`) builds both and uploads the artifacts.

### Release signing (Android)

Create `android/key.properties` (never commit it):

```properties
storeFile=app/release.jks
storePassword=…
keyAlias=…
keyPassword=…
```

Generate a key with
`keytool -genkeypair -v -keystore android/app/release.jks -keyalg RSA -keysize 4096 -validity 10000 -alias aurora`.
In CI, provide `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`,
`ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD` as repository secrets. Without
them, release builds are signed with the debug key (fine for testing only).

## Tests

```bash
flutter test --exclude-tags golden,core   # unit + widget
flutter test --tags golden                # screen goldens (Windows rendering)
flutter test --tags core                  # generated configs vs. `sing-box check`
```

## License

GPL-3.0-or-later — see [`LICENSE`](LICENSE). The app links sing-box, which is
GPLv3 with additional terms; third-party notices are in
[`THIRD_PARTY_LICENSES.md`](THIRD_PARTY_LICENSES.md).
