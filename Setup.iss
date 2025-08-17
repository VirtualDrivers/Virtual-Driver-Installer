#define MyAppName "Virtual Driver Control"
#define MyAppShortName "Virtual Display"
#define MyAppPublisher "VirtualDisplay"
#define MyAppVersion "25.8.14"
#define MyAppSupportURL "https://github.com/VirtualDrivers/Virtual-Display-Driver/issues"
#define MyAppURL "https://pyrosoft.pro/"
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
DisableFinishedPage=yes
DisableReadyPage=yes
DisableDirPage=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Dirs]
Name: "{#InstallPath}"; Permissions: everyone-full

[Files]
Source: "input\*"; DestDir: "{#InstallPath}"; Flags: ignoreversion recursesubdirs createallsubdirs confirmoverwrite

[Run]
Filename: "{#InstallPath}\Virtual Driver Control.exe"; Description: "Launch Virtual Driver Control"; Flags: nowait postinstall skipifsilent unchecked

[UninstallRun]
Filename: "{#InstallPath}\Driver Files\dependencies\uninstall.bat"; Parameters: "-installer"; WorkingDir: "{#InstallPath}\Driver Files\dependencies"; Flags: runhidden waituntilterminated

[Code]
var
  SettingsPage: TWizardPage;
  KeepSettingsRadio: TRadioButton;
  OverwriteSettingsRadio: TRadioButton;
  FinishedPage: TWizardPage;
  LaunchAppCheckBox: TCheckBox;
  KeepExistingSettings: Boolean;
  SettingsFileExists: Boolean;

procedure InitializeWizard;
begin
  // Check if settings file exists
  SettingsFileExists := FileExists(ExpandConstant('{#InstallPath}\vdd_settings.xml'));
  
  // Create settings preservation page only if settings file exists
  if SettingsFileExists then
  begin
    SettingsPage := CreateCustomPage(wpLicense, 'Existing Settings Found', 'Choose how to handle your existing settings');
    
    with TLabel.Create(SettingsPage) do
    begin
      Parent := SettingsPage.Surface;
      Caption := 'An existing vdd_settings.xml file was found in the installation directory.' + #13#10#13#10 +
                 'Please choose how you would like to handle your existing settings:';
      Left := 0;
      Top := 0;
      Width := SettingsPage.SurfaceWidth;
      Height := 50;
      WordWrap := True;
    end;
    
    KeepSettingsRadio := TRadioButton.Create(SettingsPage);
    with KeepSettingsRadio do
    begin
      Parent := SettingsPage.Surface;
      Caption := 'Keep my existing settings (recommended)';
      Left := 20;
      Top := 60;
      Width := SettingsPage.SurfaceWidth - 40;
      Height := 17;
      Checked := True;
    end;
    
    OverwriteSettingsRadio := TRadioButton.Create(SettingsPage);
    with OverwriteSettingsRadio do
    begin
      Parent := SettingsPage.Surface;
      Caption := 'Overwrite with new default settings';
      Left := 20;
      Top := 85;
      Width := SettingsPage.SurfaceWidth - 40;
      Height := 17;
    end;
  end;
  
  // Create custom finished page
  FinishedPage := CreateCustomPage(wpInstalling, 'Installation Complete', 'Virtual Display Driver has been successfully installed');
  
  with TLabel.Create(FinishedPage) do
  begin
    Parent := FinishedPage.Surface;
    Caption := 'Congratulations! Virtual Display Driver has been successfully installed.' + #13#10#13#10 +
               'The driver has been installed and is ready to use.';
    Left := 0;
    Top := 0;
    Width := FinishedPage.SurfaceWidth;
    Height := 60;
    WordWrap := True;
  end;
  
  LaunchAppCheckBox := TCheckBox.Create(FinishedPage);
  with LaunchAppCheckBox do
  begin
    Parent := FinishedPage.Surface;
    Caption := 'Launch Virtual Driver Control';
    Left := 0;
    Top := 80;
    Width := FinishedPage.SurfaceWidth;
    Height := 17;
    Checked := True;
  end;
end;

function ShouldSkipPage(PageID: Integer): Boolean;
begin
  Result := False;
  
  // Skip settings page if no existing settings file
  if SettingsFileExists and Assigned(SettingsPage) and (PageID = SettingsPage.ID) then
    Result := False
  else if not SettingsFileExists and Assigned(SettingsPage) and (PageID = SettingsPage.ID) then
    Result := True;
end;

procedure CurStepChanged(CurStep: TSetupStep);
var
  SettingsBackupPath: string;
  InstallScriptPath: string;
  ResultCode: Integer;
begin
  if CurStep = ssInstall then
  begin
    // Backup existing settings if user wants to keep them
    if SettingsFileExists and KeepExistingSettings then
    begin
      SettingsBackupPath := ExpandConstant('{tmp}\vdd_settings.xml.backup');
      if FileExists(ExpandConstant('{#InstallPath}\vdd_settings.xml')) then
      begin
        FileCopy(ExpandConstant('{#InstallPath}\vdd_settings.xml'), SettingsBackupPath, False);
      end;
    end;
    
    // Create the directory if it doesn't exist (but don't delete everything)
    ForceDirectories(ExpandConstant('{#InstallPath}'));
  end
  else if CurStep = ssPostInstall then
  begin
    // Restore backed up settings if needed (but only if we're not overwriting)
    if SettingsFileExists and KeepExistingSettings then
    begin
      SettingsBackupPath := ExpandConstant('{tmp}\vdd_settings.xml.backup');
      if FileExists(SettingsBackupPath) then
      begin
        FileCopy(SettingsBackupPath, ExpandConstant('{#InstallPath}\vdd_settings.xml'), False);
        DeleteFile(SettingsBackupPath);
      end;
    end;
    
    // NOW run the WORKING driver installation script AFTER all files are copied
    InstallScriptPath := ExpandConstant('{#InstallPath}\Driver Files\dependencies\install-working.bat');
    if FileExists(InstallScriptPath) then
    begin
      if Exec(InstallScriptPath, '', ExpandConstant('{#InstallPath}\Driver Files\dependencies'), SW_SHOW, ewWaitUntilTerminated, ResultCode) then
      begin
        if ResultCode = 0 then
        begin
          // Driver installation succeeded
          Log('Driver installation completed successfully');
          MsgBox('Virtual Display Driver installed successfully!', mbInformation, MB_OK);
        end
        else
        begin
          // Driver installation failed
          MsgBox('Driver installation failed with error code: ' + IntToStr(ResultCode) + #13#10 + 
                 'The standalone install-working.bat script should work.' + #13#10 +
                 'Please run it manually from: ' + ExpandConstant('{#InstallPath}\Driver Files\dependencies\'), mbError, MB_OK);
        end;
      end
      else
      begin
        MsgBox('Failed to execute driver installation script', mbError, MB_OK);
      end;
    end
    else
    begin
      MsgBox('Driver installation script not found at: ' + InstallScriptPath + #13#10 +
             'Files may not have been copied correctly.', mbError, MB_OK);
    end;
  end;
end;

function NextButtonClick(CurPageID: Integer): Boolean;
var
  ResultCode: Integer;
begin
  Result := True;
  
  if SettingsFileExists and Assigned(SettingsPage) and (CurPageID = SettingsPage.ID) then
  begin
    KeepExistingSettings := KeepSettingsRadio.Checked;
  end
  else if Assigned(FinishedPage) and (CurPageID = FinishedPage.ID) then
  begin
    if LaunchAppCheckBox.Checked then
    begin
      Exec(ExpandConstant('{#InstallPath}\Virtual Driver Control.exe'), '', '', SW_SHOW, ewNoWait, ResultCode);
    end;
  end;
end;

procedure CurPageChanged(CurPageID: Integer);
begin
  if Assigned(FinishedPage) and (CurPageID = FinishedPage.ID) then
  begin
    WizardForm.NextButton.Caption := '&Finish';
    WizardForm.BackButton.Visible := False;
    WizardForm.CancelButton.Visible := False;
  end;
end;