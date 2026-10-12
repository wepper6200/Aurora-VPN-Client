; Inno Setup 6 script for the Windows installer.
; Built by scripts/build_windows.ps1 (-Installer), which passes the version:
;   ISCC.exe /DAppVersion=0.1.0 installer\aurora_vpn.iss

#ifndef AppVersion
  #define AppVersion "0.0.0"
#endif
#define AppName "Aurora VPN"
#define AppExe "aurora_vpn.exe"
#define SourceDir "..\build\windows\x64\runner\Release"

[Setup]
AppId={{8C610689-F82A-49C6-B8D2-294690A5F40F}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
AppPublisher=Aurora VPN contributors
AppPublisherURL=https://github.com/wepper6200/Aurora-VPN-Client
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
; Per-user by default (no UAC prompt); the dialog offers an all-users install.
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0
; The app holds this mutex (windows/runner/main.cpp); setup asks to quit it
; from the tray first so the system proxy is restored and core files unlock.
AppMutex=Local\AuroraVPN.SingleInstance
CloseApplications=yes
SetupIconFile=..\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#AppExe}
UninstallDisplayName={#AppName}
LicenseFile=..\LICENSE
OutputDir=..\dist
OutputBaseFilename=AuroraVPN-{#AppVersion}-windows-x64-setup
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "en"; MessagesFile: "compiler:Default.isl"
Name: "ru"; MessagesFile: "compiler:Languages\Russian.isl"

[CustomMessages]
en.LinksTask=Open vless://, vmess://, trojan://, ss://, hysteria2://, tuic:// and happ:// links with {#AppName}
ru.LinksTask=Открывать ссылки vless://, vmess://, trojan://, ss://, hysteria2://, tuic:// и happ:// в {#AppName}

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
Name: "links"; Description: "{cm:LinksTask}"

[Files]
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#AppName}"; Filename: "{app}\{#AppExe}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExe}"; Tasks: desktopicon

[Registry]
; URL protocols (deep links). HKA = HKCU for per-user, HKLM for all users.
Root: HKA; Subkey: "Software\Classes\vless"; ValueType: string; ValueName: ""; ValueData: "URL:vless link"; Flags: uninsdeletekey; Tasks: links
Root: HKA; Subkey: "Software\Classes\vless"; ValueType: string; ValueName: "URL Protocol"; ValueData: ""; Tasks: links
Root: HKA; Subkey: "Software\Classes\vless\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: """{app}\{#AppExe}"",0"; Tasks: links
Root: HKA; Subkey: "Software\Classes\vless\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\{#AppExe}"" ""%1"""; Tasks: links
Root: HKA; Subkey: "Software\Classes\vmess"; ValueType: string; ValueName: ""; ValueData: "URL:vmess link"; Flags: uninsdeletekey; Tasks: links
Root: HKA; Subkey: "Software\Classes\vmess"; ValueType: string; ValueName: "URL Protocol"; ValueData: ""; Tasks: links
Root: HKA; Subkey: "Software\Classes\vmess\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: """{app}\{#AppExe}"",0"; Tasks: links
Root: HKA; Subkey: "Software\Classes\vmess\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\{#AppExe}"" ""%1"""; Tasks: links
Root: HKA; Subkey: "Software\Classes\trojan"; ValueType: string; ValueName: ""; ValueData: "URL:trojan link"; Flags: uninsdeletekey; Tasks: links
Root: HKA; Subkey: "Software\Classes\trojan"; ValueType: string; ValueName: "URL Protocol"; ValueData: ""; Tasks: links
Root: HKA; Subkey: "Software\Classes\trojan\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: """{app}\{#AppExe}"",0"; Tasks: links
Root: HKA; Subkey: "Software\Classes\trojan\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\{#AppExe}"" ""%1"""; Tasks: links
Root: HKA; Subkey: "Software\Classes\ss"; ValueType: string; ValueName: ""; ValueData: "URL:ss link"; Flags: uninsdeletekey; Tasks: links
Root: HKA; Subkey: "Software\Classes\ss"; ValueType: string; ValueName: "URL Protocol"; ValueData: ""; Tasks: links
Root: HKA; Subkey: "Software\Classes\ss\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: """{app}\{#AppExe}"",0"; Tasks: links
Root: HKA; Subkey: "Software\Classes\ss\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\{#AppExe}"" ""%1"""; Tasks: links
Root: HKA; Subkey: "Software\Classes\hysteria2"; ValueType: string; ValueName: ""; ValueData: "URL:hysteria2 link"; Flags: uninsdeletekey; Tasks: links
Root: HKA; Subkey: "Software\Classes\hysteria2"; ValueType: string; ValueName: "URL Protocol"; ValueData: ""; Tasks: links
Root: HKA; Subkey: "Software\Classes\hysteria2\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: """{app}\{#AppExe}"",0"; Tasks: links
Root: HKA; Subkey: "Software\Classes\hysteria2\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\{#AppExe}"" ""%1"""; Tasks: links
Root: HKA; Subkey: "Software\Classes\hy2"; ValueType: string; ValueName: ""; ValueData: "URL:hy2 link"; Flags: uninsdeletekey; Tasks: links
Root: HKA; Subkey: "Software\Classes\hy2"; ValueType: string; ValueName: "URL Protocol"; ValueData: ""; Tasks: links
Root: HKA; Subkey: "Software\Classes\hy2\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: """{app}\{#AppExe}"",0"; Tasks: links
Root: HKA; Subkey: "Software\Classes\hy2\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\{#AppExe}"" ""%1"""; Tasks: links
Root: HKA; Subkey: "Software\Classes\tuic"; ValueType: string; ValueName: ""; ValueData: "URL:tuic link"; Flags: uninsdeletekey; Tasks: links
Root: HKA; Subkey: "Software\Classes\tuic"; ValueType: string; ValueName: "URL Protocol"; ValueData: ""; Tasks: links
Root: HKA; Subkey: "Software\Classes\tuic\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: """{app}\{#AppExe}"",0"; Tasks: links
Root: HKA; Subkey: "Software\Classes\tuic\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\{#AppExe}"" ""%1"""; Tasks: links
Root: HKA; Subkey: "Software\Classes\happ"; ValueType: string; ValueName: ""; ValueData: "URL:happ link"; Flags: uninsdeletekey; Tasks: links
Root: HKA; Subkey: "Software\Classes\happ"; ValueType: string; ValueName: "URL Protocol"; ValueData: ""; Tasks: links
Root: HKA; Subkey: "Software\Classes\happ\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: """{app}\{#AppExe}"",0"; Tasks: links
Root: HKA; Subkey: "Software\Classes\happ\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\{#AppExe}"" ""%1"""; Tasks: links
; The app writes this autostart value itself (Settings); remove it on uninstall.
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; ValueType: none; ValueName: "AuroraVPN"; Flags: uninsdeletevalue dontcreatekey

[Run]
Filename: "{app}\{#AppExe}"; Description: "{cm:LaunchProgram,{#AppName}}"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
; Runtime files (generated configs, PID file, core cache). Settings and the
; encrypted server database stay unless the user removes them.
Type: filesandordirs; Name: "{localappdata}\AuroraVPN\run"
