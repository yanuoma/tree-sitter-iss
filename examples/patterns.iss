; A self-contained fixture that exercises every highlight pattern.
;
; The 70-script validation corpus is other projects' code and is deliberately
; not vendored (see .gitignore), so tests that depend on it cannot run on a
; fresh clone or in CI. This file is written from scratch for that purpose:
; it is committed, so `every_highlight_pattern_matches_something` is meaningful
; everywhere rather than silently degrading to a weaker assertion.
;
; Keep it in sync when adding a highlight pattern.

// An ISPP-style comment.

#define MyAppName "My Program"
#define MyAppVersion "1.5.3"
#define SingleQuoted 'Some Prose Here'
#define Multiply(int A, int B) A * B
#define public SharedMacro 1
#dim Items[3]
#undef SingleQuoted
#pragma option -e+
#pragma message "building"
#if Len(MyAppName) >= 2 && (1 + 2 - 3) != 0
  #define Extra GetEnv("PATH")
#elif defined(Other)
  #define Extra CompilerPath
#else
  #define Extra __FILE__
#endif
#ifdef Extra
  #expr SaveToFile("out.txt")
#endif
#if TypeOf(MyAppName) == TYPE_STRING
  #expr Exec("cmd.exe", "/C dir", , , SW_HIDE)
  #define RegVal ReadReg(HKEY_LOCAL_MACHINE, "Software\Test", "Value", "")
  #define Found Find(0, "needle", FIND_CONTAINS)
  #define Attrs FindFirst("*.txt", faAnyFile)
#endif
#error This message is free text, not an expression
#include "included.iss"

[Setup]
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppId={{8A4F1C22-9B3D-4E7A-8F21-5C6D7E8F9A0B}
Uninstallable=yes
AllowNoIcons=no
UsePreviousAppDir=auto
WizardStyle=modern
PrivilegesRequired=admin
Compression=lzma2
InternalCompressLevel=max
LZMAMatchFinder=BT
UninstallLogMode=append
LanguageDetectionMethod=uilanguage
WizardImageAlphaFormat=premultiplied
SetupArchitecture=x64
ArchitecturesAllowed=x64compatible or arm64
ArchitecturesInstallIn64BitMode=x64compatible
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
OutputBaseFilename=setup-{#MyAppVersion}
OutputDir=D:\
SourceDir={%TEMP|C:\Temp}
UninstallDisplayIcon={app}\MyProg.exe
VersionInfoVersion=1.5.3.0
LicenseFile=license.txt
AppPublisherURL=https://example.com/path

[LangOptions]
LanguageName=English
LanguageID=$0409

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Messages]
SetupAppTitle=Setup
WelcomeLabel2=This will install %1 on your computer.

[CustomMessages]
english.CreateDesktopIcon=Create a &desktop icon
english.MyAppVerName=My Program %1
german.CreateDesktopIcon=&Desktop-Symbol erstellen

[Types]
Name: "full"; Description: "Full installation"
Name: "custom"; Description: "Custom"; Flags: iscustom

[Components]
Name: "main"; Description: "Main files"; Types: full custom; Flags: fixed
Name: "help"; Description: "Help"; Types: full

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; Flags: unchecked

[Dirs]
Name: "{app}\data"; Attribs: readonly hidden; Flags: uninsalwaysuninstall

[Files]
Source: "MyProg.exe"; DestDir: "{app}"; Flags: ignoreversion 32bit
Source: "MyProg64.exe"; DestDir: "{app}"; Flags: ignoreversion 64bit solidbreak
Source: "readme.txt"; DestDir: "{app}"; Flags: isreadme; Components: main
Source: "a ""quoted"" name.dll"; DestDir: "{app}\{{literal"; Permissions: users-modify
Source: "opt.dat"; DestDir: "{app}"; CopyMode: alwaysoverwrite; Check: not IsAdminInstallMode
Source: "x.dat"; DestDir: "{app}"; Excludes: "*.tmp"; ExternalSize: 1024

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\MyProg.exe"; IconIndex: 0
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\MyProg.exe"; Tasks: desktopicon
Name: "{group}\{cm:UninstallProgram,{cm:MyAppName}}"; Filename: "{uninstallexe}"

[INI]
Filename: "{app}\my.ini"; Section: "Settings"; Key: "Path"; String: "{app}"; Flags: uninsdeleteentry

[Registry]
Root: HKA; Subkey: "Software\My Program"; ValueType: string; ValueName: "Path"; ValueData: "{app}"; Flags: uninsdeletekey
Root: HKLM; Subkey: "Software\My Program"; ValueType: dword; ValueName: "Count"; ValueData: "1"
Root: HKCU; Subkey: "Software\My Program"; ValueType: expandsz; ValueName: "Env"; ValueData: "%SystemRoot%\system32"
Root: HKCR; Subkey: "MyProg\shell\open\command"; ValueType: string; ValueData: """{app}\MyProg.exe"" ""%1"""

[InstallDelete]
Type: filesandordirs; Name: "{app}\old"
Type: files; Name: "{app}\stale.txt"

[UninstallDelete]
Type: dirifempty; Name: "{app}"

[Run]
Filename: "{app}\MyProg.exe"; Description: "Launch"; Flags: nowait postinstall skipifsilent
Filename: "{cmd}"; Parameters: "/C echo %PATH%"; Flags: runhidden

[UninstallRun]
Filename: "{app}\cleanup.exe"; RunOnceId: "cleanup"; Flags: waituntilterminated

[Code]
var
  Page: TWizardPage;

function InitializeSetup(): Boolean;
begin
  { A Pascal brace comment; the '[Setup]' text here must not end this block. }
  MsgBox('Starting', mbInformation, MB_OK);
  Result := True;
end;
