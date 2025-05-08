#define MyAppName "Virtual Display Driver"
#define MyAppShortName "Virtual Display"
#define MyAppPublisher "VirtualDisplay"
#define MyAppVersion "1.0.0"
#define MyAppSupportURL "https://github.com/VirtualDrivers/Virtual-Display-Driver/issues"
#define MyAppURL "https://vdd.mikethetech.com"
#define InstallPath "C:\VirtualDisplayDriver"
#define AppId "VirtualDisplayDriver"
#define RegKeyBase "SOFTWARE\MikeTheTech\VirtualDisplayDriver"
#define InstallerTempDir "{localappdata}\VDDInstaller"

[Setup]
//no network storage installs
AllowUNCPath=False
AlwaysShowGroupOnReadyPage=yes
AppendDefaultDirName=False
AppId={#AppId}
AppName={#MyAppName}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppSupportURL}
AppUpdatesURL={#MyAppURL}
AppVersion={#MyAppVersion}
AppComments=Provides Virtual Displays and Control Application
AppContact=Contact us on at discord.mikethetech.com
AppCopyright=Copyright (C) 2022-2024 MikeTheTech
ArchitecturesInstallIn64BitMode=x64compatible
ArchitecturesAllowed=x64compatible
BackColor=$2ca1b2
BackColor2=$0c8192
Compression=lzma2/ultra
DefaultDirName={#InstallPath}
DefaultGroupName=VDDbyMTT
LicenseFile=.\LICENSE.txt
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
DisableDirPage=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Dirs]
; These directories will be automatically created during installation
; with the specified permissions
Name: "{app}"; Permissions: everyone-full; Flags: uninsalwaysuninstall
Name: "{app}\ControlApp"; Permissions: everyone-full; Flags: uninsalwaysuninstall

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
Source: "input\ControlApp\VDDControl.exe"; DestDir: "{app}\ControlApp"; Components: ControlApp

[Types]
Name: "basic"; Description: "Basic install with driver and control app (recommended)"; 
Name: "full"; Description: "Complete installation with driver and control app"; 
Name: "custom"; Description: "Customize which components to install"; Flags: iscustom
Name: "compact"; Description: "Compact installation with only the driver (no control app)"


[Components]
Name: "VDD"; Description: "Core functionality of the {#MyAppName}."; Types: full custom basic compact; Flags: fixed
Name: "ControlApp"; Description: "Control application for managing virtual displays."; Types: full basic custom

[Icons]
Name: "{group}\VDD Control"; Filename: "{app}\ControlApp\VDDControl.exe"; WorkingDir: "{app}"; Components: ControlApp
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
  IsAlreadyInstalled: Boolean;
  ResultCode: Integer;

function IsAppAlreadyInstalled(): Boolean;
var
  InstalledBy: string;
begin
  Result := RegQueryStringValue(HKEY_LOCAL_MACHINE, '{#RegKeyBase}', 'InstalledBy', InstalledBy);
  if Result then
    Log('App is already installed by: ' + InstalledBy)
  else
    Log('App is not installed');
end;

function GetUninstallString(): string;
var
  UninstallString: string;
  RegPath: string;
begin
  RegPath := 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\' + '{#AppId}' + '_is1';

  if RegQueryStringValue(HKEY_LOCAL_MACHINE, RegPath, 'UninstallString', UninstallString) then
  begin
    UninstallString := Trim(UninstallString);
    if (Length(UninstallString) > 1) and (UninstallString[1] = '"') and (UninstallString[Length(UninstallString)] = '"') then
    begin
      UninstallString := Copy(UninstallString, 2, Length(UninstallString) - 2); 
    end;
    Result := UninstallString;
  end
  else
  begin
    Result := '';
  end;
end;


function AskToUninstall(): Boolean;
var
  MsgResult: Integer;
begin
  MsgResult := MsgBox('{#MyAppName} is already installed. Would you like to uninstall it?', mbConfirmation, MB_YESNO);
  Result := MsgResult = IDYES;
end;

function TriggerWindowsUninstall(): Boolean;
var
  UninstallString: string;
  ExecResult: Boolean;
begin
  Result := False; 
  UninstallString := GetUninstallString();

  if UninstallString <> '' then
  begin
    ExecResult := Exec(UninstallString, '', '', SW_SHOW, ewWaitUntilTerminated, ResultCode);
    if ExecResult and (ResultCode = 0) then
      Result := True; 
  end
  else
  begin
    MsgBox('Unable to locate uninstallation information in Windows registry.', mbError, MB_OK);
  end;
end;


procedure EnsureFilesAndDirectoryExist();
var
  Src, Dest, TempDir: String;
  FileCopyResult: Boolean;
begin
  // Extract necessary files to temp directory
  try
    ExtractTemporaryFile('getlist.bat');
  except
    Log('Warning: Failed to extract getlist.bat to temporary directory');
  end;
    
  try
    ExtractTemporaryFile('gpulist.txt');
  except
    Log('Warning: Failed to extract gpulist.txt to temporary directory');
  end;
  
  // Create installer temp directory if it doesn't exist
  TempDir := ExpandConstant('{#InstallerTempDir}');
  if not DirExists(TempDir) then
  begin
    if not CreateDir(TempDir) then
    begin
      Log('Error: Failed to create directory: ' + TempDir);
      MsgBox('Failed to create the required temporary directory. ' +
             'The installation may not complete successfully.', mbError, MB_OK);
      Exit;
    end;
  end;
  
  // Copy the getlist.bat file
  Src := ExpandConstant('{tmp}\getlist.bat');
  Dest := TempDir + '\getlist.bat';
  
  if FileExists(Src) then
  begin
    if not FileExists(Dest) or not CompareFileDateTime(Src, Dest, 0) then
    begin
      FileCopyResult := FileCopy(Src, Dest, True);
      if not FileCopyResult then
        Log('Error: Failed to copy ' + Src + ' to ' + Dest);
    end;
  end
  else
    Log('Error: Source file not found: ' + Src);
    
  // Copy the gpulist.txt file
  Src := ExpandConstant('{tmp}\gpulist.txt');
  Dest := TempDir + '\gpulist.txt';
  
  if FileExists(Src) then
  begin
    if not FileExists(Dest) or not CompareFileDateTime(Src, Dest, 0) then
    begin
      FileCopyResult := FileCopy(Src, Dest, True);
      if not FileCopyResult then
        Log('Error: Failed to copy ' + Src + ' to ' + Dest);
    end;
  end
  else
    Log('Error: Source file not found: ' + Src);
end;

procedure RunGetListAndPopulateGPUComboBox;
var
  I, ResultCode: Integer;
  ListPath, GetListPath, TempDir: String;
begin
  // Add default option
  GPUComboBox.Items.Add('Best GPU (Auto)'); 
  
  // Ensure necessary files are available
  EnsureFilesAndDirectoryExist();
  
  // Use defined constant for temp directory
  TempDir := ExpandConstant('{#InstallerTempDir}');
  GetListPath := TempDir + '\getlist.bat';
  ListPath := TempDir + '\gpulist.txt';
  
  // Verify getlist.bat exists
  if not FileExists(GetListPath) then
  begin
    Log('Error: getlist.bat not found at: ' + GetListPath);
    MsgBox('Error: GPU listing utility not found. You can still proceed with installation ' +
           'but GPU selection may not work properly.', mbError, MB_OK);
    GPUComboBox.ItemIndex := 0;
    Exit;
  end;
  
  // Execute getlist.bat to gather GPU information
  Log('Executing: ' + GetListPath);
  if Exec(GetListPath, '', '', SW_HIDE, ewWaitUntilTerminated, ResultCode) then
  begin
    Log('getlist.bat executed with result code: ' + IntToStr(ResultCode));
    
    if ResultCode <> 0 then
    begin
      Log('Warning: getlist.bat exited with non-zero code: ' + IntToStr(ResultCode));
    end;
    
    // Load GPU list if available
    if FileExists(ListPath) then
    begin
      GPUList := TStringList.Create;
      try
        try
          GPUList.LoadFromFile(ListPath);
          Log('Loaded ' + IntToStr(GPUList.Count) + ' GPUs from list');
          
          for I := 0 to GPUList.Count - 1 do
          begin
            if Trim(GPUList[I]) <> '' then
            begin
              GPUComboBox.Items.Add(GPUList[I]);
              Log('Added GPU: ' + GPUList[I]);
            end;
          end;
        except
          on E: Exception do
          begin
            Log('Error loading GPU list: ' + E.Message);
            MsgBox('Error loading GPU list. Default GPU selection will be used.', mbError, MB_OK);
          end;
        end;
      finally
        GPUList.Free;
      end;
    end
    else
    begin
      Log('Warning: GPU list file not found at: ' + ListPath);
      MsgBox('Could not find the GPU list. Default GPU selection will be used.', mbInformation, MB_OK);
    end;
  end
  else
  begin
    Log('Error: Failed to execute getlist.bat');
    MsgBox('Failed to detect GPUs. Default GPU selection will be used.', mbError, MB_OK);
  end;
  
  // Ensure a default selection is made
  GPUComboBox.ItemIndex := 0;
  
  Log('GPU initialization completed');
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
var
  LicenseAfterPage: Integer;

procedure InitializeWizard();
begin
  LicenseAfterPage := wpLicense;
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

function GetInstallDate(Param: string): string;
var
  Year, Month, Day: Word;
begin
  // Get current date
  DecodeDate(Date, Year, Month, Day);
  // Format as yyyy-mm-dd
  Result := Format('%.4d-%.2d-%.2d', [Year, Month, Day]);
end;

function MergePar(Param: string): string;
begin
  { 
    Properly quote parameters to handle paths with spaces.
    The third parameter (%3 in install.bat) is the installation path.
    
    Jocke's fix in install.bat:
    1. For PowerShell: powershell script gets path with special quoting "\"%AppPath%\""
    2. For nefconw.exe: Driver installation uses special quoting "\"%AppPath%\MttVDD.inf\""
    
    Both approaches ensure paths with spaces work correctly.
  }
  Result := Format('%s "%s" "%s"', [
    ExpandConstant('{code:GetVDCount}'),
    ExpandConstant('{code:GetSelectedGPU}'),
    ExpandConstant('{app}')
  ]);
end;

var 
  isSilent: Boolean;

function InitializeSetup(): Boolean;
begin
  Result := True;  

  if IsAppAlreadyInstalled() then
  begin
    if AskToUninstall() then
    begin
      if TriggerWindowsUninstall() then
      begin
        MsgBox('{#MyAppName} was successfully uninstalled. The setup will now restart.', mbInformation, MB_OK);
        Result := True; 
      end
      else
      begin
        MsgBox('Failed to uninstall {#MyAppName} using Windows uninstaller. Setup will now exit.', mbError, MB_OK);
        Result := False; 
      end;
    end
    else
    begin
      MsgBox('Setup was canceled because {#MyAppName} is already installed.', mbInformation, MB_OK);
      Result := False; 
    end;
  end;
end;

procedure CurPageChanged(CurPageID: Integer);
var
  I: Integer;
begin
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
Root: HKLM; Subkey: "{#RegKeyBase}"; Flags: uninsdeletekeyifempty
Root: HKLM; Subkey: "{#RegKeyBase}"; ValueType: string; ValueName: "VDDPATH"; ValueData: "{app}"; Flags: uninsdeletevalue
Root: HKLM; Subkey: "{#RegKeyBase}"; ValueType: string; ValueName: "InstalledBy"; ValueData: "Installer"; Flags: uninsdeletevalue
Root: HKLM; Subkey: "{#RegKeyBase}"; ValueType: string; ValueName: "InstallDate"; ValueData: "{code:GetInstallDate}"; Flags: uninsdeletevalue
Root: HKLM; Subkey: "{#RegKeyBase}"; ValueType: string; ValueName: "Version"; ValueData: "{#MyAppVersion}"; Flags: uninsdeletevalue


[Run]
Filename: "{app}\install.bat"; Parameters: "{code:MergePar}"; WorkingDir: "{app}"; Flags: runascurrentuser runhidden waituntilterminated
Filename: "{app}\ControlApp\VDDControl.exe"; Description: "Launch VDD Control"; Flags: nowait postinstall skipifsilent runascurrentuser; Components: ControlApp


[UninstallRun]
Filename: "{app}\uninstall.bat"; Parameters: "-installer"; Flags: runhidden