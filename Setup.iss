#define MyAppName "Virtual Display Driver"
#define MyAppShortName "Virtual Display"
#define MyAppPublisher "VirtualDisplay"
#define MyAppVersion "1.0.0"
#define MyAppSupportURL "https://github.com/VirtualDrivers/Virtual-Display-Driver/issues"
#define MyAppURL "https://vdd.mikethetech.com"
#define InstallPath "C:\VirtualDisplayDriver"
#define AppId "VirtualDisplayDriver"

[Setup]
AppId={#AppId}
AppName={#MyAppName}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppSupportURL}
AppUpdatesURL={#MyAppURL}
AppVersion={#MyAppVersion}
AppComments=Virtual Display Driver License Agreement
AppContact=Contact us on at discord.mikethetech.com
AppCopyright=Copyright (C) 2022-2024 MikeTheTech
Compression=lzma2/ultra
DefaultDirName={#InstallPath}
LicenseFile=.\LICENSE.txt
OutputBaseFilename={#MyAppName}-v{#MyAppVersion}-setup-x64
OutputDir=.\output
SetupIconFile=dependencies\Virtual Display Driver.ico
SolidCompression=yes
WizardStyle=modern
DisableFinishedPage=no
DisableReadyPage=no
DisableWelcomePage=no
DisableDirPage=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Dirs]
Name: "{app}"; Permissions: everyone-full

[Files]
Source: "input\vdd_settings.xml"; DestDir: "{app}"; Flags: ignoreversion

[Code]
var
  KeepExistingSettings: Boolean;

function InitializeSetup(): Boolean;
var
  SettingsPath: string;
begin
  Result := True;
  SettingsPath := ExpandConstant('{#InstallPath}\vdd_settings.xml');
  
  if FileExists(SettingsPath) then
  begin
    if MsgBox('An existing vdd_settings.xml file was found in the installation directory.' + #13#10 + 
              'Do you want to keep your existing settings?' + #13#10#13#10 + 
              'Yes = Keep existing file (recommended)' + #13#10 + 
              'No = Overwrite with new default settings', 
              mbConfirmation, MB_YESNO or MB_DEFBUTTON1) = IDYES then
    begin
      KeepExistingSettings := True;
    end
    else
    begin
      KeepExistingSettings := False;
    end;
  end
  else
  begin
    KeepExistingSettings := False;
  end;
end;

function ShouldSkipFile(const FileName: string): Boolean;
begin
  // Skip installing vdd_settings.xml if user wants to keep existing
  if (ExtractFileName(FileName) = 'vdd_settings.xml') and KeepExistingSettings then
    Result := True
  else
    Result := False;
end;