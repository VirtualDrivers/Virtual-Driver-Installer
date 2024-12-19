#define MyAppName "Virtual Display Driver"
#define MyAppShortName "Virtual Display"
#define MyAppPublisher "VirtualDisplay"
#define MyAppVersion "1.0.0"
#define MyAppSupportURL "https://github.com/itsmikethetech/Virtual-Display-Driver/issues"
#define MyAppURL "https://vdd.mikethetech.com"
#define InstallPath "C:\VirtualDisplayDriver"

[Setup]
//no network storage installs
AllowUNCPath=False
AlwaysShowGroupOnReadyPage=yes
AppendDefaultDirName=False
AppId={{85ECF661-C369-443D-846B-285CFB698447}
AppName={#MyAppName}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppSupportURL}
AppUpdatesURL={#MyAppURL}
AppVersion={#MyAppVersion}
AppComments=Provides Virtual Displays, Viewer, Control Application, and PowerShell scripts
AppContact=Contact us on at discord.mikethetech.com
AppCopyright=Copyright (C) 2022-2024 MikeTheTech
ArchitecturesInstallIn64BitMode=x64compatible
ArchitecturesAllowed=x64compatible
BackColor=$2ca1b2
BackColor2=$0c8192
Compression=lzma2/ultra
DefaultDirName={#InstallPath}
DefaultGroupName=VDDbyMTT
LicenseFile=.\LICENSE
OutputBaseFilename={#MyAppName}-v{#MyAppVersion}-setup-x64
OutputDir=.\output
PrivilegesRequired=admin
SetupIconFile=dependencies\{#MyAppName}.ico
SolidCompression=yes
UninstallDisplayIcon={uninstallexe}   
UninstallDisplayName={#MyAppName}
UsePreviousAppDir=no
WizardStyle=modern
FlatComponentsList=yes
ShowTasksTreeLines=True
AllowRootDirectory=True

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Dirs]
Name: "{app}\scripts"; Permissions: everyone-full
Name: "{app}\Companion"; Permissions: everyone-full
Name: "{app}\scripts\onoff_at_loginout"; Permissions: everyone-full
Name: "{localappdata}\VDDInstaller"; Permissions: everyone-full

[Files]
Source: "input\MttVDD.dll"; DestDir: "{app}"; Flags: ignoreversion; Components: VDD
Source: "input\MttVDD.inf"; DestDir: "{app}"; Flags: ignoreversion; Components: VDD
Source: "input\mttvdd.cat"; DestDir: "{app}"; Flags: ignoreversion; Components: VDD
Source: "input\vdd_settings.xml"; DestDir: "{app}"; Flags: ignoreversion; Components: VDD
Source: "dependencies\nefconw.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "dependencies\getlist.bat"; Flags: dontcopy
Source: "dependencies\gpulist.txt"; Flags: dontcopy
Source: "dependencies\install.bat"; DestDir: "{app}"; Flags: ignoreversion
Source: "dependencies\uninstall.bat"; DestDir: "{app}"; Flags: ignoreversion
Source: "dependencies\fixxml.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "LICENSE_nefcon.txt"; Flags: dontcopy
Source: "LICENSE_VDD.txt"; Flags: dontcopy
Source: "input\Companion\VDDSysTray.exe"; DestDir: "{app}\Companion"; Components: CompanionApp
Source: "input\scripts\changeres-VDD.ps1"; DestDir: "{app}\scripts"; Components: Scripts\ChangeVDDreslution
Source: "input\scripts\refreshrate-VDD.ps1"; DestDir: "{app}\scripts"; Components: Scripts\ChangeVDDrefreshrate
Source: "input\scripts\rotate-VDD.ps1"; DestDir: "{app}\scripts"; Components: Scripts\RotateVDD
Source: "input\scripts\scale-VDD.ps1"; DestDir: "{app}\scripts"; Components: Scripts\ScaleVDD
Source: "input\scripts\primary-VDD.ps1"; DestDir: "{app}\scripts"; Components: Scripts\MakeVDDPrimary
Source: "input\scripts\winp-VDD.ps1"; DestDir: "{app}\scripts"; Components: Scripts\WinPasScript
Source: "input\scripts\toggle-VDD.ps1"; DestDir: "{app}\scripts"; Components: Scripts\ToggleVDDpower
Source: "input\scripts\onoff_at_loginout\enable_at_logon_disable_at_logoff.reg"; DestDir: "{app}\scripts\onoff_at_loginout"; Components: Scripts\EnLiDiLo
Source: "input\scripts\onoff_at_loginout\psscripts.ini"; DestDir: "{app}\scripts\onoff_at_loginout"; Components: Scripts\EnLiDiLo
Source: "input\scripts\onoff_at_loginout\vdd_e-li_d-lo.cmd"; DestDir: "{app}\scripts\onoff_at_loginout"; Components: Scripts\EnLiDiLo

[Types]
Name: "basic"; Description: "Basic install with driver and companion app"; 
Name: "full"; Description: "Complete installation with all components"
Name: "custom"; Description: "Customize which components to install"; Flags: iscustom
Name: "compact"; Description: "Compact installation with only the driver"


[Components]
Name: "VDD"; Description: "Core functionality of the {#MyAppName}."; Types: full custom compact basic; Flags: fixed
Name: "CompanionApp"; Description: "System tray application to control the {#MyAppName}."; Types: full custom basic
Name: "Scripts"; Description: "Install modules required for all scripts."; Types: full custom 
Name: "Scripts\ChangeVDDreslution"; Description: "Change the {#MyAppShortName}'s resolution via command line."; Types: full custom 
Name: "Scripts\ChangeVDDrefreshrate"; Description: "Adjust the {#MyAppShortName}'s refresh rate via command line."; Types: full custom 
Name: "Scripts\RotateVDD"; Description: "Rotate the {#MyAppShortName} via command line."; Types: full custom 
Name: "Scripts\ScaleVDD"; Description: "Scale the {#MyAppShortName} via command line."; Types: full custom 
Name: "Scripts\MakeVDDPrimary"; Description: "PowerShell script to set {#MyAppShortName} as the primary display."; Types: full custom 
Name: "Scripts\WinPasScript"; Description: "Script to trigger Win+P via command lin.e"; Types: full custom 
Name: "Scripts\ToggleVDDpower"; Description: "Script to toggle {#MyAppShortName}'s power on or off."; Types: full custom 
Name: "Scripts\EnLiDiLo"; Description: "Automate enabling the {#MyAppName} on login and disabling on logout"; Types: full custom 

[Icons]
Name: "{group}\Companion"; Filename: "{app}\Companion\VDDSysTray.exe"; WorkingDir: "{app}"
Name: "{group}\Visit Homepage"; Filename: "{#MyAppURL}"
Name: "{group}\Uninstall"; Filename: "{uninstallexe}"

[Code]
var
  LicenseAcceptedRadioButtons: array of TRadioButton;
  Page: TWizardPage;
  MonitorsEdit: TEdit;
  MonitorsLabel: TLabel;
  GPUSelectionPage: TWizardPage;
  GPUComboBox: TComboBox;
  GPUList: TStringList;
  SelectedGPU: string;
  CurrentPageID: Integer; 
  
procedure CheckLicenseAccepted(Sender: TObject);
begin
  WizardForm.NextButton.Enabled :=
    LicenseAcceptedRadioButtons[TComponent(Sender).Tag].Checked;
end;

procedure LicensePageActivate(Sender: TWizardPage);
begin
  CheckLicenseAccepted(LicenseAcceptedRadioButtons[Sender.Tag]);
end;

function CloneLicenseRadioButton(
  Page: TWizardPage; Source: TRadioButton): TRadioButton;
begin
  Result := TRadioButton.Create(WizardForm);
  Result.Parent := Page.Surface;
  Result.Caption := Source.Caption;
  Result.Left := Source.Left;
  Result.Top := Source.Top;
  Result.Width := Source.Width;
  Result.Height := Source.Height;
  Result.Anchors := Source.Anchors;
  Result.OnClick := @CheckLicenseAccepted;
  Result.Tag := Page.Tag;
end;

var
  LicenseAfterPage: Integer;

procedure AddLicensePage(LicenseFileName: string);
var
  Idx: Integer;
  Page: TOutputMsgMemoWizardPage;
  LicenseFilePath: string;
  RadioButton: TRadioButton;
begin
  Idx := GetArrayLength(LicenseAcceptedRadioButtons);
  SetArrayLength(LicenseAcceptedRadioButtons, Idx + 1);
  Page := CreateOutputMsgMemoPage(LicenseAfterPage, SetupMessage(msgWizardLicense),SetupMessage(msgLicenseLabel), SetupMessage(msgLicenseLabel3), '');
  Page.Tag := Idx;
  Page.RichEditViewer.Height := WizardForm.LicenseMemo.Height;
  Page.OnActivate := @LicensePageActivate;
  ExtractTemporaryFile(LicenseFileName);
  LicenseFilePath := ExpandConstant('{tmp}\' + LicenseFileName);
  Page.RichEditViewer.Lines.LoadFromFile(LicenseFilePath);
  DeleteFile(LicenseFilePath);
  RadioButton := CloneLicenseRadioButton(Page, WizardForm.LicenseAcceptedRadio);
  LicenseAcceptedRadioButtons[Idx] := RadioButton;
  RadioButton := CloneLicenseRadioButton(Page, WizardForm.LicenseNotAcceptedRadio);
  RadioButton.Checked := True;
  LicenseAfterPage := Page.ID;
end;

procedure EnsureFilesAndDirectoryExist();
var
  Src, Dest: String;
begin
  ExtractTemporaryFile('getlist.bat');
  ExtractTemporaryFile('gpulist.txt');
  if not DirExists(ExpandConstant('{localappdata}\VDDInstaller')) then
    CreateDir(ExpandConstant('{localappdata}\VDDInstaller'));
  Src := ExpandConstant('{tmp}\lfn.exe');
  Dest := ExpandConstant('{localappdata}\VDDInstaller\lfn.exe');
  if not FileExists(Dest) then
    FileCopy(Src, Dest, False);
  Src := ExpandConstant('{tmp}\getlist.bat');
  Dest := ExpandConstant('{localappdata}\VDDInstaller\getlist.bat');
  if not FileExists(Dest) then
    FileCopy(Src, Dest, False);
  Src := ExpandConstant('{tmp}\gpulist.txt');
  Dest := ExpandConstant('{localappdata}\VDDInstaller\gpulist.txt');
  if not FileExists(Dest) then
    FileCopy(Src, Dest, False);
end;

procedure RunGetListAndPopulateGPUComboBox;
var
  I, ResultCode: Integer;
  ListPath: String;
begin
  GPUComboBox.Items.Add('Best GPU (Auto)'); 
  
  EnsureFilesAndDirectoryExist();
  ListPath := ExpandConstant('{localappdata}\VDDInstaller\gpulist.txt');
  if not FileExists(ExpandConstant('{localappdata}\VDDInstaller\getlist.bat')) then
  begin
    MsgBox('Error: getlist.bat not found.', mbError, MB_OK);
    Exit;
  end;
  if Exec(ExpandConstant('{localappdata}\VDDInstaller\getlist.bat'), '', '', SW_HIDE, ewWaitUntilTerminated, ResultCode) then
  begin
    if FileExists(ListPath) then
    begin
      GPUList := TStringList.Create;
      try
        GPUList.LoadFromFile(ListPath);
        for I := 0 to GPUList.Count -1 do
          GPUComboBox.Items.Add(GPUList[I]);
      finally
          GPUList.Free;
      end;
    end;
  end;
  GPUComboBox.ItemIndex := 0;
end;

function NextButtonClick(CurPageID: Integer): Boolean;
begin
  if CurrentPageID = GPUSelectionPage.ID then
  begin
    if GPUComboBox.ItemIndex <> -1 then
      SelectedGPU := GPUComboBox.Items[GPUComboBox.ItemIndex]
    else
      SelectedGPU := 'Default';
  end;
  Result := TRUE;
end;

procedure InitializeWizard();
begin
  LicenseAfterPage := wpLicense;
  AddLicensePage('LICENSE_nefcon.txt');
  AddLicensePage('LICENSE_VDD.txt');
  GPUSelectionPage := CreateCustomPage(LicenseAfterPage, 'Select Primary GPU', 'Choose a GPU to bind to Virtual Display or leave it for automatic selection');
  GPUComboBox := TComboBox.Create(WizardForm);
  GPUComboBox.Parent := GPUSelectionPage.Surface;
  GPUComboBox.Left := ScaleX(10);
  GPUComboBox.Top := ScaleY(20);
  GPUComboBox.Width := ScaleX(200);
  RunGetListAndPopulateGPUComboBox;
  Page := CreateCustomPage(GPUSelectionPage.ID, '{#MyAppName} Configuration', 'Choose how many {#MyAppShortName}s you want to add to your system.');
  MonitorsLabel := TLabel.Create(Page);
  MonitorsLabel.Parent := Page.Surface;
  MonitorsLabel.Caption := 'Choose how many {#MyAppShortName}s you want to add to your system.'#13#10'A maximum of four (4) displays is recommended.';
  MonitorsLabel.Left := 10;
  MonitorsLabel.Top := 10;
  MonitorsLabel.Width := Page.SurfaceWidth - 20;
  MonitorsLabel.AutoSize := True;
  MonitorsLabel.WordWrap := True;
  MonitorsEdit := TEdit.Create(Page);
  MonitorsEdit.Parent := Page.Surface;
  MonitorsEdit.Left := 10;
  MonitorsEdit.Top := MonitorsLabel.Top + MonitorsLabel.Height + 10;
  MonitorsEdit.Width := Page.SurfaceWidth - 20;
  MonitorsEdit.Text := '1';
end;

function GetSelectedGPU(Param: string): string;
begin
  Result := SelectedGPU;
end;

function GetVDCount(Param: string): string;
begin
  Result := MonitorsEdit.Text;
end;

function MergePar(Param: string): string;
begin
  Result := Format('%s "%s" "%s"', [
    ExpandConstant('{code:GetVDCount}'),
    ExpandConstant('{code:GetSelectedGPU}'),
    ExpandConstant('{app}')
  ]);
end;

var 
  isSilent: Boolean;

function InitializeSetup(): Boolean;
var
  j: Integer;
begin
  Result := True;
  IsSilent := False;
  for j := 1 to ParamCount do
  begin
    if (CompareText(ParamStr(j), '/verysilent') = 0) or 
       (CompareText(ParamStr(j), '/silent') = 0) then
    begin
      IsSilent := True;
      Break;
    end;
  end;
end;

procedure CurPageChanged(CurPageID: Integer);
var
  I: Integer;
begin
  // Automatically accept licenses if running in silent mode
  if IsSilent then
  begin
    for I := 0 to GetArrayLength(LicenseAcceptedRadioButtons) - 1 do
    begin
      LicenseAcceptedRadioButtons[I].Checked := True;
    end;
  end;
  CurrentPageID := CurPageID; 
end;

[Registry]
Root: HKLM; Subkey: "SOFTWARE\MikeTheTech"; Flags: uninsdeletekeyifempty
Root: HKLM; Subkey: "SOFTWARE\MikeTheTech\VirtualDisplayDriver"; Flags: uninsdeletekeyifempty
Root: HKLM; Subkey: "SOFTWARE\MikeTheTech\VirtualDisplayDriver"; ValueType: string; ValueName: "VDDPATH"; ValueData: "{app}"; Flags: uninsdeletevalue

[Run]
Filename: "{app}\install.bat"; Parameters: "{code:MergePar}"; WorkingDir: "{app}"; Flags: runascurrentuser runhidden waituntilterminated
Filename: "{app}\Companion\VDDSysTray.exe"; Description: "Launch Companion App"; Flags: nowait postinstall skipifsilent; Components: CompanionApp

[UninstallRun]
Filename: "{app}\uninstall.bat"; Flags: runhidden
