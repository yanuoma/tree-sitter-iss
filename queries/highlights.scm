; Highlighting for Inno Setup (.iss)
;
; The keyword lists are extracted from Inno Setup's own IDE styler,
; Projects/Src/IDE.ScintStylerInnoSetup.pas in jrsoftware/issrc, so they track
; what the compiler accepts rather than a hand-maintained guess.
;
; Value keywords are matched only inside the parameter or directive that
; actually accepts them. Matching bare (word) nodes everywhere looks fine on a
; terse script but miscolours ordinary prose: an English [Messages] value is
; full of words like "or", "no", "files" and "system".
(comment) @comment

; ---------------------------------------------------------------- sections
(section_header
  name: (section_name) @type)

(section_header
  [
    "["
    "]"
  ] @punctuation.bracket)

; ----------------------------------------------------------------- entries
(directive_entry
  name: (directive_name) @property)

(parameter
  name: (parameter_name) @property)

; A localized key such as `english.WelcomeLabel` in [CustomMessages].
(directive_name
  language: (language_name) @module)

(directive_name
  key: (directive_key) @property)

; Section parameter names, e.g. Source, DestDir, Flags, ValueType.
((parameter_name) @attribute
  (#any-of? @attribute
    "AfterInstall" "AppUserModelID" "AppUserModelToastActivatorCLSID" "Attribs" "BeforeInstall"
    "Check" "Comment" "Components" "CopyMode" "Description" "DestDir" "DestName"
    "DownloadISSigSource" "DownloadPassword" "DownloadUserName" "Excludes" "ExternalSize"
    "ExtractArchivePassword" "ExtraDiskSpaceRequired" "Filename" "Flags" "FontInstall" "Group"
    "GroupDescription" "Hash" "HotKey" "IconFilename" "IconIndex" "InfoAfterFile" "InfoBeforeFile"
    "ISSigAllowedKeys" "Key" "KeyFile" "KeyID" "Languages" "LicenseFile" "MessagesFile" "MinVersion"
    "Name" "OnLog" "OnlyBelowVersion" "Parameters" "Permissions" "PublicX" "PublicY" "Root"
    "RunOnceId" "RuntimeID" "Section" "Source" "StatusMsg" "String" "StrongAssemblyName" "Subkey"
    "Tasks" "Type" "Types" "ValueData" "ValueName" "ValueType" "Verb" "WorkingDir"))

; [Setup] section directives. @attribute mirrors the parameter-name treatment;
; @property.builtin is not a widely defined highlight group.
((directive_name) @attribute
  (#any-of? @attribute
    "AllowCancelDuringInstall" "AllowNetworkDrive" "AllowNoIcons" "AllowRootDirectory"
    "AllowUNCPath" "AlwaysRestart" "AlwaysShowComponentsList" "AlwaysShowDirOnReadyPage"
    "AlwaysShowGroupOnReadyPage" "AlwaysUsePersonalGroup" "AppComments" "AppContact" "AppCopyright"
    "AppendDefaultDirName" "AppendDefaultGroupName" "AppId" "AppModifyPath" "AppMutex" "AppName"
    "AppPublisher" "AppPublisherURL" "AppReadmeFile" "AppSupportPhone" "AppSupportURL"
    "AppUpdatesURL" "AppVerName" "AppVersion" "ArchitecturesAllowed"
    "ArchitecturesInstallIn64BitMode" "ArchiveExtraction" "ASLRCompatible" "BackColor" "BackColor2"
    "BackColorDirection" "BackSolid" "ChangesAssociations" "ChangesEnvironment" "CloseApplications"
    "CloseApplicationsFilter" "CloseApplicationsFilterExcludes" "Compression" "CompressionThreads"
    "CreateAppDir" "CreateUninstallRegKey" "DefaultDialogFontName" "DefaultDirName"
    "DefaultGroupName" "DefaultUserInfoName" "DefaultUserInfoOrg" "DefaultUserInfoSerial"
    "DEPCompatible" "DirExistsWarning" "DisableDirPage" "DisableFinishedPage"
    "DisablePrecompiledFileVerifications" "DisableProgramGroupPage" "DisableReadyMemo"
    "DisableReadyPage" "DisableStartupPrompt" "DisableWelcomePage" "DiskClusterSize" "DiskSliceSize"
    "DiskSpanning" "DontMergeDuplicateFiles" "EnableDirDoesntExistWarning" "Encryption"
    "EncryptionKeyDerivation" "ExtraDiskSpaceRequired" "FlatComponentsList" "InfoAfterFile"
    "InfoBeforeFile" "InternalCompressLevel" "LanguageDetectionMethod" "LicenseFile" "LZMAAlgorithm"
    "LZMABlockSize" "LZMADictionarySize" "LZMAMatchFinder" "LZMANumBlockThreads" "LZMANumFastBytes"
    "LZMAUseSeparateProcess" "MergeDuplicateFiles" "MessagesFile" "MinVersion"
    "MissingMessagesWarning" "MissingRunOnceIdsWarning" "NotRecognizedMessagesWarning"
    "OnlyBelowVersion" "Output" "OutputBaseFilename" "OutputDir" "OutputManifestFile" "Password"
    "PrivilegesRequired" "PrivilegesRequiredOverridesAllowed" "RedirectionGuard" "ReserveBytes"
    "RestartApplications" "RestartIfNeededByRun" "SetupArchitecture" "SetupIconFile" "SetupLogging"
    "SetupMutex" "ShowComponentSizes" "ShowLanguageDialog" "ShowTasksTreeLines"
    "ShowUndisplayableLanguages" "SignedUninstaller" "SignedUninstallerDir" "SignTool"
    "SignToolMinimumTimeBetween" "SignToolRetryCount" "SignToolRetryDelay" "SignToolRunMinimized"
    "SlicesPerDisk" "SolidCompression" "SourceDir" "TerminalServicesAware" "TimeStampRounding"
    "TimeStampsInUTC" "TouchDate" "TouchTime" "Uninstallable" "UninstallDisplayIcon"
    "UninstallDisplayName" "UninstallDisplaySize" "UninstallFilesDir" "UninstallIconFile"
    "UninstallLogging" "UninstallLogMode" "UninstallRestartComputer" "UninstallStyle"
    "UpdateUninstallLogAppName" "UsedUserAreasWarning" "UsePreviousAppDir" "UsePreviousGroup"
    "UsePreviousLanguage" "UsePreviousPrivileges" "UsePreviousSetupType" "UsePreviousTasks"
    "UsePreviousUserInfo" "UserInfoPage" "UseSetupLdr" "VersionInfoCompany" "VersionInfoCopyright"
    "VersionInfoDescription" "VersionInfoOriginalFileName" "VersionInfoProductName"
    "VersionInfoProductTextVersion" "VersionInfoProductVersion" "VersionInfoTextVersion"
    "VersionInfoVersion" "WindowResizable" "WindowShowCaption" "WindowStartMaximized"
    "WindowVisible" "WizardBackColor" "WizardBackColorDynamicDark" "WizardBackImageFile"
    "WizardBackImageFileDynamicDark" "WizardBackImageOpacity" "WizardImageAlphaFormat"
    "WizardImageBackColor" "WizardImageBackColorDynamicDark" "WizardImageFile"
    "WizardImageFileDynamicDark" "WizardImageOpacity" "WizardImageStretch" "WizardKeepAspectRatio"
    "WizardResizable" "WizardSizePercent" "WizardSmallImageBackColor"
    "WizardSmallImageBackColorDynamicDark" "WizardSmallImageFile" "WizardSmallImageFileDynamicDark"
    "WizardStyle" "WizardStyleFile" "WizardStyleFileDynamicDark"))

; --------------------------------------------------- scoped value keywords
; `Flags: ignoreversion recursesubdirs`
((parameter
  name: (parameter_name) @_param
  value: (parameter_value
    (word) @keyword))
  (#any-of? @_param "Flags" "flags")
  (#any-of? @keyword
    "32bit" "64bit" "allowunsafefiles" "checkablealone" "checkedonce" "closeonexit"
    "comparetimestamp" "confirmoverwrite" "createallsubdirs" "createkeyifdoesntexist"
    "createonlyiffileexists" "createvalueifdoesntexist" "deleteafterinstall" "deletekey"
    "deletevalue" "disablenouninstallwarning" "dontcloseonexit" "dontcopy" "dontcreatekey"
    "dontinheritcheck" "dontlogparameters" "dontverifychecksum" "download"
    "excludefromshowinnewinstall" "exclusive" "external" "extractarchive" "fixed" "fontisnttruetype"
    "gacinstall" "hidewizard" "ignoreversion" "iscustom" "isreadme" "issigverify" "logoutput"
    "nocompression" "noencryption" "noerror" "noregerror" "notimestamp" "nowait"
    "onlyifdestfileexists" "onlyifdoesntexist" "overwritereadonly" "postinstall"
    "preservestringtype" "preventpinning" "promptifolder" "recursesubdirs" "regserver" "regtypelib"
    "replacesameversion" "restart" "restartreplace" "runascurrentuser" "runasoriginaluser"
    "runhidden" "runmaximized" "runminimized" "setntfscompression" "sharedfile" "shellexec" "sign"
    "signcheck" "signonce" "skipifdoesntexist" "skipifnotsilent" "skipifsilent"
    "skipifsourcedoesntexist" "solidbreak" "sortfilesbyextension" "sortfilesbyname" "touch"
    "unchecked" "uninsalwaysuninstall" "uninsclearvalue" "uninsdeleteentry" "uninsdeletekey"
    "uninsdeletekeyifempty" "uninsdeletesection" "uninsdeletesectionifempty" "uninsdeletevalue"
    "uninsneveruninstall" "uninsnosharedfileprompt" "uninsremovereadonly" "uninsrestartdelete"
    "unsetntfscompression" "useapppaths" "waituntilidle" "waituntilterminated"))

; `Type: filesandordirs` in [InstallDelete]/[UninstallDelete], and
; `ValueType: dword` in [Registry].
((parameter
  name: (parameter_name) @_param
  value: (parameter_value
    (word) @type.builtin))
  (#any-of? @_param "Type" "type" "ValueType" "valuetype")
  (#any-of? @type.builtin
    "binary" "dirifempty" "dword" "expandsz" "files" "filesandordirs" "multisz" "none" "qword"
    "string" "Binary" "DirIfEmpty" "DWord" "ExpandSz" "Files" "FilesAndOrDirs" "MultiSz" "None"
    "QWord" "String"))

; `Root: HKLM` in [Registry].
((parameter
  name: (parameter_name) @_param
  value: (parameter_value
    (word) @constant.builtin))
  (#any-of? @_param "Root" "root")
  (#any-of? @constant.builtin
    "HKA" "HKA32" "HKA64" "HKCC" "HKCC32" "HKCC64" "HKCR" "HKCR32" "HKCR64" "HKCU" "HKCU32" "HKCU64"
    "HKLM" "HKLM32" "HKLM64" "HKU" "HKU32" "HKU64" "hka" "hkcc" "hkcr" "hkcu" "hklm" "hku"))

; Boolean-valued [Setup] directives, e.g. `Uninstallable=yes`.
((directive_entry
  name: (directive_name) @_dir
  value: (value
    (word) @boolean))
  (#any-of? @boolean "yes" "no" "auto" "Yes" "No" "Auto" "YES" "NO")
  (#any-of? @_dir
    "AllowCancelDuringInstall" "AllowNetworkDrive" "AllowNoIcons" "AllowRootDirectory"
    "AllowUNCPath" "AlwaysRestart" "AlwaysShowComponentsList" "AlwaysShowDirOnReadyPage"
    "AlwaysShowGroupOnReadyPage" "AlwaysUsePersonalGroup" "AppendDefaultDirName"
    "AppendDefaultGroupName" "ASLRCompatible" "ChangesAssociations" "ChangesEnvironment"
    "CreateAppDir" "CreateUninstallRegKey" "DEPCompatible" "DirExistsWarning" "DisableDirPage"
    "DisableFinishedPage" "DisableProgramGroupPage" "DisableReadyMemo" "DisableReadyPage"
    "DisableStartupPrompt" "DisableWelcomePage" "DiskSpanning" "DontMergeDuplicateFiles"
    "EnableDirDoesntExistWarning" "FlatComponentsList" "MergeDuplicateFiles"
    "MissingMessagesWarning" "MissingRunOnceIdsWarning" "NotRecognizedMessagesWarning" "Output"
    "RedirectionGuard" "RestartApplications" "RestartIfNeededByRun" "SetupLogging"
    "ShowComponentSizes" "ShowLanguageDialog" "ShowTasksTreeLines" "SignedUninstaller"
    "SignToolRunMinimized" "SolidCompression" "TerminalServicesAware" "TimeStampsInUTC"
    "Uninstallable" "UninstallLogging" "UninstallRestartComputer" "UpdateUninstallLogAppName"
    "UsedUserAreasWarning" "UsePreviousAppDir" "UsePreviousGroup" "UsePreviousLanguage"
    "UsePreviousPrivileges" "UsePreviousSetupType" "UsePreviousTasks" "UsePreviousUserInfo"
    "UserInfoPage" "WizardImageStretch" "WizardKeepAspectRatio"))

; [Setup] directives with a fixed set of values, e.g. `WizardStyle=modern`,
; `PrivilegesRequired=admin`, `Compression=lzma2/max`.
((directive_entry
  name: (directive_name) @_dir
  value: (value
    (word) @constant.builtin))
  (#any-of? @_dir
    "ArchitecturesAllowed" "ArchitecturesInstallIn64BitMode" "ArchiveExtraction" "CloseApplications"
    "Compression" "DisablePrecompiledFileVerifications" "Encryption" "LanguageDetectionMethod"
    "LZMAAlgorithm" "LZMAMatchFinder" "LZMAUseSeparateProcess" "PrivilegesRequired"
    "PrivilegesRequiredOverridesAllowed" "SetupArchitecture" "UninstallLogMode" "UseSetupLdr"
    "WizardImageAlphaFormat" "WizardStyle")
  (#any-of? @constant.builtin
    "admin" "append" "auto" "basic" "bt" "BT" "bt2" "bt3" "bt4" "bzip" "classic" "commandline"
    "dark" "defined" "dialog" "dynamic" "enhanced" "excludelightbuttons" "excludelightcontrols"
    "fast" "force" "full" "hc" "HC" "hc4" "hidebevels" "includetitlebar" "is7z" "isbunzip" "islzma"
    "isunzlib" "light" "locale" "lowest" "lzma" "lzma2" "max" "modern" "new" "none" "normal"
    "overwrite" "polar" "premultiplied" "setup" "setupcustomstyle" "setupldr" "slate" "stellar"
    "uilanguage" "ultra" "ultra64" "windows11" "x64" "x86" "zip" "zircon"))

; Architecture identifiers and the operators of an architecture expression.
((directive_entry
  name: (directive_name) @_dir
  value: (value
    (word) @constant.builtin))
  (#any-of? @_dir
    "ArchitecturesAllowed" "ArchitecturesInstallIn64BitMode" "architecturesallowed"
    "architecturesinstallin64bitmode")
  (#any-of? @constant.builtin
    "arm32compatible" "arm64" "win64" "x64" "x64compatible" "x64os" "x86" "x86compatible" "x86os"
    "ia64"))

((directive_entry
  name: (directive_name) @_dir
  value: (value
    (word) @keyword.operator))
  (#any-of? @_dir
    "ArchitecturesAllowed" "ArchitecturesInstallIn64BitMode" "architecturesallowed"
    "architecturesinstallin64bitmode")
  (#any-of? @keyword.operator "and" "not" "or"))

; Expression operators in Check/Components/Tasks/Languages parameters.
((parameter
  name: (parameter_name) @_param
  value: (parameter_value
    (word) @keyword.operator))
  (#any-of? @_param "Check" "Components" "Tasks" "Languages")
  (#any-of? @keyword.operator "and" "not" "or"))

; Other enumerated parameter values.
((parameter
  name: (parameter_name) @_param
  value: (parameter_value
    (word) @constant.builtin))
  (#any-of? @_param "Attribs" "attribs" "Permissions" "permissions" "CopyMode" "copymode")
  (#any-of? @constant.builtin
    "readonly" "hidden" "system" "notcontentindexed" "full" "modify" "readexec" "users" "authusers"
    "everyone" "admins" "powerusers" "nobody" "restricted" "normal" "onlyifdoesntexist"
    "alwaysoverwrite" "alwaysskipifsameorolder"))

; ---------------------------------------------------------------- literals
(string) @string

(string_content) @string

(escaped_quote) @string.escape

(escaped_brace) @string.escape

(number) @number

(message_placeholder) @character.special

; -------------------------------------------------------- setup constants
; Constants nest, e.g. `{cm:UninstallProgram,{cm:MyAppName}}`, so they are
; matched whole.
(constant) @constant

; Known directory and information constants such as {app} or {sys}.
((constant) @constant.builtin
  (#any-of? @constant.builtin
    "{app}" "{autoappdata}" "{autocf}" "{autocf32}" "{autocf64}" "{autodesktop}" "{autodocs}"
    "{autofonts}" "{autopf}" "{autopf32}" "{autopf64}" "{autoprograms}" "{autostartmenu}"
    "{autostartup}" "{autotemplates}" "{break}" "{cf}" "{cf32}" "{cf64}" "{cmd}" "{commonappdata}"
    "{commoncf}" "{commoncf32}" "{commoncf64}" "{commondesktop}" "{commondocs}" "{commonfonts}"
    "{commonpf}" "{commonpf32}" "{commonpf64}" "{commonprograms}" "{commonstartmenu}"
    "{commonstartup}" "{commontemplates}" "{computername}" "{dao}" "{dotnet11}" "{dotnet20}"
    "{dotnet2032}" "{dotnet2064}" "{dotnet40}" "{dotnet4032}" "{dotnet4064}" "{group}" "{groupname}"
    "{language}" "{localappdata}" "{log}" "{olddata}" "{pf}" "{pf32}" "{pf64}" "{sd}" "{src}"
    "{srcexe}" "{sys}" "{sysnative}" "{sysuserinfoname}" "{sysuserinfoorg}" "{syswow64}" "{tmp}"
    "{uninstallexe}" "{userappdata}" "{usercf}" "{usercf32}" "{usercf64}" "{userdesktop}"
    "{userdocs}" "{userfavorites}" "{userfonts}" "{userinfoname}" "{userinfoorg}" "{userinfoserial}"
    "{username}" "{userpf}" "{userpf32}" "{userpf64}" "{userprograms}" "{usersavedgames}"
    "{usersendto}" "{userstartmenu}" "{userstartup}" "{usertemplates}" "{win}" "{wizardhwnd}"))

; Constants taking a parameter: {code:Fn}, {param:X|d}, {reg:...}, {cm:...}.
; Predicate regexes are compiled by whatever engine the host embeds, so this
; stays inside a conservative subset that they agree on.
((constant) @function.macro
  (#match? @function.macro "^\\{(cm|code|drive|ini|param|reg):"))

; {%NAME} and {%NAME|default} read an environment variable. A node rather
; than a regex: a leading `%` is a metacharacter in some host regex engines,
; so `^\{%` is not portable as a predicate.
(env_constant) @variable.builtin

; ------------------------------------------------------------ preprocessor
(preproc_directive
  directive: (preproc_keyword) @keyword.directive)

; `{#Macro}` compile-time expansion.
(preproc_inline) @constant.macro

; --------------------------------------------------------------- operators
[
  "="
  ":"
] @operator

"." @punctuation.delimiter

";" @punctuation.delimiter

; ------------------------------------------------- preprocessor arguments
; ISPP directive arguments are a small expression language.
(preproc_argument
  (preproc_identifier) @variable)

(preproc_string) @string

(preproc_operator) @operator

(punctuation) @punctuation.bracket

; Free text of an #error directive. Scoped to the argument field: the same
; node name is also used for leftover punctuation inside an expression, which
; should not be coloured as a string.
(preproc_directive
  argument: (preproc_text) @string)

; ISPP built-in constants and predefined variables.
((preproc_identifier) @constant.builtin
  (#any-of? @constant.builtin
    "COMPANY_NAME" "faAnyFile" "faArchive" "faDirectory" "faHidden" "False" "faReadOnly" "faSymLink"
    "faSysFile" "faVolumeID" "FILE_DESCRIPTION" "FILE_VERSION" "FIND_AND" "FIND_BEGINS"
    "FIND_CASESENSITIVE" "FIND_CONTAINS" "FIND_ENDS" "FIND_MATCH" "FIND_NOT" "FIND_OR"
    "FIND_SENSITIVE" "FIND_TRIM" "HKCC" "HKCC32" "HKCC64" "HKCR" "HKCR32" "HKCR64" "HKCU" "HKCU32"
    "HKCU64" "HKEY_CLASSES_ROOT" "HKEY_CLASSES_ROOT_32" "HKEY_CLASSES_ROOT_64" "HKEY_CURRENT_CONFIG"
    "HKEY_CURRENT_CONFIG_32" "HKEY_CURRENT_CONFIG_64" "HKEY_CURRENT_USER" "HKEY_CURRENT_USER_32"
    "HKEY_CURRENT_USER_64" "HKEY_LOCAL_MACHINE" "HKEY_LOCAL_MACHINE_32" "HKEY_LOCAL_MACHINE_64"
    "HKEY_USERS" "HKEY_USERS_32" "HKEY_USERS_64" "HKLM" "HKLM32" "HKLM64" "HKU" "HKU32" "HKU64"
    "INTERNAL_NAME" "LEGAL_COPYRIGHT" "MaxInt" "MinInt" "NewLine" "No" "NULL" "ORIGINAL_FILENAME"
    "PREPROCVER" "PRODUCT_NAME" "PRODUCT_VERSION" "SW_HIDE" "SW_MAX" "SW_MAXIMIZE" "SW_MINIMIZE"
    "SW_NORMAL" "SW_RESTORE" "SW_SHOW" "SW_SHOWDEFAULT" "SW_SHOWMAXIMIZED" "SW_SHOWMINIMIZED"
    "SW_SHOWMINNOACTIVE" "SW_SHOWNA" "SW_SHOWNOACTIVATE" "SW_SHOWNORMAL" "Tab" "True" "TYPE_ARRAY"
    "TYPE_ERROR" "TYPE_FUNC" "TYPE_INTEGER" "TYPE_MACRO" "TYPE_NULL" "TYPE_STRING" "Ver" "Yes"))

((preproc_identifier) @variable.builtin
  (#any-of? @variable.builtin
    "__COUNTER__" "__DIR__" "__FILENAME__" "__INCLUDE__" "__LINE__" "__PATHFILENAME__"
    "CompilerPath" "SourcePath" "SysPath"))

; ISPP declaration type keywords.
((preproc_identifier) @type.builtin
  (#any-of? @type.builtin "int" "str" "func" "any" "void" "Local" "local"))

; An identifier immediately followed by "(" is a call, not a variable.
((preproc_argument
  (preproc_identifier) @function.call
  .
  (punctuation) @_open)
  (#eq? @_open "("))

; The macro being defined or tested reads better as a definition.
((preproc_directive
  directive: (preproc_keyword) @_kw
  argument: (preproc_argument
    .
    (preproc_identifier) @constant.macro))
  (#any-of? @_kw
    "#define" "#undef" "#dim" "#redim" "#ifdef" "#ifndef" "#sub" "#for" "#DEFINE" "#UNDEF" "#DIM"
    "#REDIM" "#IFDEF" "#IFNDEF" "#SUB" "#FOR")
  (#not-any-of? @constant.macro "public" "private" "protected"))

; #pragma sub-directives, e.g. `#pragma option -e+`.
((preproc_directive
  directive: (preproc_keyword) @_kw
  argument: (preproc_argument
    .
    (preproc_identifier) @keyword.directive))
  (#any-of? @_kw "#pragma" "#PRAGMA")
  (#any-of? @keyword.directive
    "error" "include" "inlineend" "inlinestart" "message" "option" "parseroption" "spansymbol"
    "verboselevel" "warning"))
