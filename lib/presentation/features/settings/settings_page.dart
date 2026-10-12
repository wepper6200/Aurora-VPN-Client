import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../application/settings/settings_controller.dart';
import '../../../core/l10n.dart';
import '../../../core/platform.dart';
import '../../../domain/logs/log_entry.dart';
import '../../../domain/settings/app_settings.dart';
import '../../router/app_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/tokens.dart';
import '../../widgets/app_card.dart';
import '../../widgets/decorations.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/form_section.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/settings_tile.dart';
import 'settings_dialogs.dart';

final _packageInfoProvider = FutureProvider<PackageInfo>((ref) => PackageInfo.fromPlatform());

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final s = ref.watch(settingsProvider);
    final ctrl = ref.read(settingsProvider.notifier);
    final platform = ref.watch(appPlatformProvider);
    final version = ref.watch(_packageInfoProvider).value;

    Widget switchTile({
      required IconData icon,
      required String title,
      String? subtitle,
      required bool value,
      required ValueChanged<bool> onChanged,
      Color? color,
    }) {
      return SettingsTile(
        icon: icon,
        iconColor: color,
        title: title,
        subtitle: subtitle,
        onTap: () => onChanged(!value),
        trailing: Switch(value: value, onChanged: onChanged),
      );
    }

    final dnsLabel = switch (s.dnsProtocol) {
      DnsProtocol.doh => 'DoH',
      DnsProtocol.dot => 'DoT',
      DnsProtocol.udp => 'UDP',
    };

    return PageScaffold(
      title: l10n.settingsTitle,
      slivers: [
        PagePadding(
          child: SliverList.list(
            children: [
              SectionHeader(l10n.settingsAppearance.toUpperCase()),
              AppCard(
                child: Column(
                  children: [
                    FormSegmented<ThemePreference>(
                      label: l10n.settingsTheme,
                      value: s.theme,
                      onChanged: ctrl.setTheme,
                      options: {
                        ThemePreference.system: l10n.themeSystem,
                        ThemePreference.light: l10n.themeLight,
                        ThemePreference.dark: l10n.themeDark,
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    FormSegmented<LanguagePreference>(
                      label: l10n.settingsLanguage,
                      value: s.language,
                      onChanged: ctrl.setLanguage,
                      options: {
                        LanguagePreference.system: l10n.languageSystem,
                        LanguagePreference.en: l10n.languageEnglish,
                        LanguagePreference.ru: l10n.languageRussian,
                      },
                    ),
                  ],
                ),
              ),

              SectionHeader(l10n.settingsConnection.toUpperCase()),
              SettingsGroup(
                children: [
                  switchTile(
                    icon: LucideIcons.zap,
                    title: l10n.settingsAutoConnect,
                    subtitle: l10n.settingsAutoConnectSub,
                    value: s.autoConnect,
                    onChanged: (v) => ctrl.update((s) => s.copyWith(autoConnect: v)),
                  ),
                  if (platform.isDesktop)
                    switchTile(
                      icon: LucideIcons.power,
                      color: c.info,
                      title: l10n.settingsLaunchAtStartup,
                      subtitle: l10n.settingsLaunchAtStartupSub,
                      value: s.launchAtStartup,
                      onChanged: (v) => ctrl.update((s) => s.copyWith(launchAtStartup: v)),
                    ),
                  if (platform.isDesktop)
                    switchTile(
                      icon: LucideIcons.shieldOff,
                      color: c.danger,
                      title: l10n.settingsKillSwitch,
                      subtitle: l10n.settingsKillSwitchWindowsSub,
                      value: s.killSwitch,
                      onChanged: (v) => ctrl.update((s) => s.copyWith(killSwitch: v)),
                    )
                  else
                    SettingsTile(
                      icon: LucideIcons.shieldOff,
                      iconColor: c.danger,
                      title: l10n.settingsKillSwitch,
                      subtitle: l10n.settingsKillSwitchAndroidSub,
                      // Stage 6: opens the system "Always-on VPN" screen.
                      onTap: () {},
                      trailing: Icon(LucideIcons.externalLink, size: 18, color: c.textTertiary),
                    ),
                ],
              ),
              if (platform.isDesktop) ...[
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FormSegmented<WindowsTunnelMode>(
                        label: l10n.settingsWindowsMode,
                        value: s.windowsMode,
                        onChanged: (v) => ctrl.update((s) => s.copyWith(windowsMode: v)),
                        options: {
                          WindowsTunnelMode.systemProxy: l10n.modeProxy,
                          WindowsTunnelMode.tun: l10n.modeTun,
                        },
                      ),
                      AnimatedSize(
                        duration: AppDurations.medium,
                        child: s.windowsMode == WindowsTunnelMode.tun
                            ? Padding(
                                padding: const EdgeInsets.only(top: AppSpacing.md),
                                child: Row(
                                  children: [
                                    Icon(LucideIcons.shieldAlert, size: 16, color: c.warning),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: Text(
                                        l10n.modeTunHint,
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : const SizedBox(width: double.infinity),
                      ),
                    ],
                  ),
                ),
              ],

              SectionHeader(l10n.settingsNetwork.toUpperCase()),
              SettingsGroup(
                children: [
                  SettingsTile(
                    icon: LucideIcons.globeLock,
                    title: l10n.settingsDns,
                    subtitle: '$dnsLabel · ${s.dnsServer}',
                    onTap: () async {
                      final r = await showDnsDialog(context, s.dnsProtocol, s.dnsServer);
                      if (r != null) {
                        await ctrl.update(
                          (s) => s.copyWith(dnsProtocol: r.protocol, dnsServer: r.server),
                        );
                      }
                    },
                  ),
                  SettingsTile(
                    icon: LucideIcons.ruler,
                    iconColor: c.accentEnd,
                    title: l10n.settingsMtu,
                    subtitle: '${s.mtu}',
                    onTap: () async {
                      final v = await showMtuDialog(context, s.mtu);
                      if (v != null) await ctrl.update((s) => s.copyWith(mtu: v));
                    },
                  ),
                  switchTile(
                    icon: LucideIcons.network,
                    color: c.info,
                    title: l10n.settingsIpv6,
                    subtitle: l10n.settingsIpv6Sub,
                    value: s.ipv6,
                    onChanged: (v) => ctrl.update((s) => s.copyWith(ipv6: v)),
                  ),
                ],
              ),

              SectionHeader(l10n.settingsSubscriptions.toUpperCase()),
              SettingsGroup(
                children: [
                  switchTile(
                    icon: LucideIcons.refreshCw,
                    title: l10n.settingsAutoUpdate,
                    subtitle: l10n.settingsAutoUpdateSub,
                    value: s.autoUpdateSubscriptions,
                    onChanged: (v) => ctrl.update((s) => s.copyWith(autoUpdateSubscriptions: v)),
                  ),
                ],
              ),

              SectionHeader(l10n.logsTitle.toUpperCase()),
              SettingsGroup(
                children: [
                  SettingsTile(
                    icon: LucideIcons.scrollText,
                    iconColor: c.warning,
                    title: l10n.settingsLogging,
                    subtitle: s.logLevel.name.toUpperCase(),
                    onTap: () async {
                      final v = await pickOption<LogLevel>(
                        context,
                        title: l10n.settingsLogging,
                        current: s.logLevel,
                        options: {for (final l in LogLevel.values) l: l.name.toUpperCase()},
                      );
                      if (v != null) await ctrl.update((s) => s.copyWith(logLevel: v));
                    },
                  ),
                ],
              ),

              SectionHeader(l10n.settingsPrivacy.toUpperCase()),
              AppCard(
                variant: AppCardVariant.elevated,
                child: Row(
                  children: [
                    IconBadge(icon: LucideIcons.eyeOff, color: c.success),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(l10n.privacyNote, style: Theme.of(context).textTheme.bodyMedium),
                    ),
                  ],
                ),
              ),

              SectionHeader(l10n.settingsAbout.toUpperCase()),
              SettingsGroup(
                children: [
                  SettingsTile(
                    icon: LucideIcons.info,
                    title: l10n.settingsVersion,
                    subtitle: version == null ? '…' : '${version.version} (${version.buildNumber})',
                  ),
                  SettingsTile(
                    icon: LucideIcons.scale,
                    iconColor: c.info,
                    title: l10n.settingsLicenses,
                    subtitle: l10n.settingsLicensesSub,
                    onTap: () => showLicensePage(
                      context: context,
                      applicationName: l10n.appTitle,
                      applicationVersion: version?.version,
                    ),
                  ),
                  SettingsTile(
                    icon: LucideIcons.swatchBook,
                    title: l10n.settingsDesignSystem,
                    subtitle: l10n.settingsDesignSystemSubtitle,
                    iconColor: c.accentEnd,
                    onTap: () => context.go(AppRoutes.designSystem),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
