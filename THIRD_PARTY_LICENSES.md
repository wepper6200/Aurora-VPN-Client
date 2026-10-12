# Third-party licenses

Aurora VPN is distributed under **GPL-3.0-or-later** because it links and
bundles sing-box. Components that ship with the app:

| Component | Use | License |
|---|---|---|
| [sing-box](https://github.com/SagerNet/sing-box) | VPN core (Android `libbox`, Windows `sing-box.exe`) | GPL-3.0-or-later **with additional terms** (see below) |
| [Xray-core](https://github.com/XTLS/Xray-core) | Second core for XHTTP / Xray JSON (Android: in `libbox`, Windows: `xray.exe`) | MPL-2.0 (`core/LICENSE.xray`) |
| [Wintun](https://www.wintun.net/) | Windows TUN driver (`wintun.dll`) | Prebuilt binaries license by WireGuard LLC — redistributable, unmodified |
| [sing-geoip](https://github.com/SagerNet/sing-geoip) / [sing-geosite](https://github.com/SagerNet/sing-geosite) | Bundled `.srs` rule sets | GPL-3.0 (data from MaxMind GeoLite2 / v2fly domain-list-community) |
| [Flutter](https://flutter.dev) and Dart packages | UI framework and libraries | BSD-3-Clause, MIT, Apache-2.0 (full list in the app: Settings → Licenses) |
| [Manrope](https://github.com/sharanda/manrope) | UI font | SIL Open Font License 1.1 (`assets/fonts/OFL-Manrope.txt`) |
| [JetBrains Mono](https://github.com/JetBrains/JetBrainsMono) | Log font | SIL Open Font License 1.1 (`assets/fonts/OFL-JetBrainsMono.txt`) |
| [Lucide](https://lucide.dev) icons | Icons | ISC |

Portions of the Android VPN glue (default-network tracking, local DNS
resolver) follow the approach of
[sing-box-for-android](https://github.com/SagerNet/sing-box-for-android) and
[shadowsocks-android](https://github.com/shadowsocks/shadowsocks-android)
(both GPL-3.0).

## sing-box additional terms

sing-box is GPL-3.0-or-later with one additional term (GPLv3 section 7):

> In addition, no derivative work may use the name or imply association with
> this application without prior consent.

Aurora VPN therefore uses its own name and branding and mentions sing-box only
as an attributed component. The full text ships next to `sing-box.exe`
(`core/LICENSE.sing-box`) and is available at
<https://github.com/SagerNet/sing-box/blob/main/LICENSE>.

The Flutter/Dart dependency notices are generated at build time and shown in
**Settings → Licenses** inside the app.
