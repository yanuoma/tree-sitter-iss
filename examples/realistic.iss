; -- Realistic Inno Setup script exercising the tricky parts --
#define MyAppName "My Program"
#define MyAppVersion "1.5.3"
#define MyAppPublisher "Contoso, Inc."

[Setup]
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
OutputBaseFilename=setup-{#MyAppVersion}
Compression=lzma2/max
ArchitecturesInstallIn64BitMode=x64compatible
UninstallDisplayIcon={app}\MyProg.exe
LicenseFile=license.txt

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "german"; MessagesFile: "compiler:Languages\German.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "Additional icons:"; Flags: unchecked

[Files]
Source: "MyProg.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "MyProg.chm"; DestDir: "{app}"; Flags: ignoreversion
Source: "README.txt"; DestDir: "{app}"; Flags: isreadme
; a comment line in the middle of a section
Source: "quoted ""weird"" name.dll"; DestDir: "{app}"; Flags: ignoreversion
#ifdef INCLUDE_EXTRAS
Source: "extra.dll"; DestDir: "{app}"; Flags: ignoreversion
#endif

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\MyProg.exe"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\MyProg.exe"; Tasks: desktopicon

[Registry]
Root: HKA; Subkey: "Software\{#MyAppPublisher}\{#MyAppName}"; ValueType: string; ValueName: "Path"; ValueData: "{app}"; Flags: uninsdeletekey

[Run]
Filename: "{app}\MyProg.exe"; Description: "{cm:LaunchProgram}"; Flags: nowait postinstall skipifsilent

[CustomMessages]
english.CreateDesktopIcon=Create a &desktop icon
german.CreateDesktopIcon=&Desktop-Symbol erstellen

[Code]
var
  DownloadPage: TDownloadWizardPage;

function InitializeSetup(): Boolean;
begin
  { A Pascal brace comment - must not confuse the outer grammar }
  if not IsAdminInstallMode then
  begin
    MsgBox('Please run as administrator [not a section]', mbError, MB_OK);
    Result := False;
    Exit;
  end;
  Result := True;
end;

procedure InitializeWizard;
begin
  DownloadPage := CreateDownloadPage(SetupMessage(msgWizardPreparing), '', nil);
end;
