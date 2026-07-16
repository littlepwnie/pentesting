# Mailbox_Migration_Assistant.ps1
# Automated mailbox content migration utility

$MigrationConfig = @{
    SourceServer = "ex-srv.telecore.ad"
    ServiceAccount = "tel_ops1@telecore.ad"
    ServicePassword = "T3l@Net#2"  
    TargetMailbox = "administrator@telecore.ad"
    LogPath = "C:\Logs\Migration\"
}

Write-Host "[INFO] Starting Mailbox Migration Assistant" -ForegroundColor Cyan
Write-Host "[INFO] Version 2.3.1" -ForegroundColor Gray
Write-Host "[INFO] Initialized at: $(Get-Date)" -ForegroundColor Gray
Write-Host ""

# Display configuration
Write-Host "[CONFIG] Migration Configuration:" -ForegroundColor Yellow
Write-Host "  Server: $($MigrationConfig.SourceServer)" -ForegroundColor Gray
Write-Host "  Service Account: $($MigrationConfig.ServiceAccount)" -ForegroundColor Gray
Write-Host "  Service Password: $($MigrationConfig.ServicePassword)" -ForegroundColor Gray
Write-Host "  Target Mailbox: $($MigrationConfig.TargetMailbox)" -ForegroundColor Gray
Write-Host ""

try {
    # Attempt to create PSCredential (exposes credentials in error handling)
    Write-Host "[ACTION] Creating authentication context..." -ForegroundColor Yellow
    $securePassword = ConvertTo-SecureString $MigrationConfig.ServicePassword -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential($MigrationConfig.ServiceAccount, $securePassword)
    
    Write-Host "[SUCCESS] Credentials validated for: $($MigrationConfig.ServiceAccount)" -ForegroundColor Green
    
    # Mailbox operations
    Write-Host "[ACTION] Connecting to Exchange server..." -ForegroundColor Yellow
    $session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri "http://$($MigrationConfig.SourceServer)/PowerShell/" -Credential $credential
    Import-PSSession $session -DisableNameChecking
    
    Write-Host "[SUCCESS] Connected to: $($MigrationConfig.SourceServer)" -ForegroundColor Green
    
    # Check mailbox access
    Write-Host "[ACTION] Verifying target mailbox access..." -ForegroundColor Yellow
    $mailboxStats = Get-MailboxStatistics -Identity $MigrationConfig.TargetMailbox -ErrorAction Stop
    
    Write-Host "[SUCCESS] Mailbox accessible:" -ForegroundColor Green
    Write-Host "  - Display Name: $($mailboxStats.DisplayName)" -ForegroundColor Gray
    Write-Host "  - Total Items: $($mailboxStats.ItemCount)" -ForegroundColor Gray
    Write-Host "  - Storage Used: $([math]::Round($mailboxStats.TotalItemSize.Value.ToMB(), 2)) MB" -ForegroundColor Gray
    
      $logContent = @"
Mailbox Migration Log
=====================
Timestamp: $(Get-Date)
Service Account: $($MigrationConfig.ServiceAccount)
Service Password: $($MigrationConfig.ServicePassword)  # [!] CREDENTIALS LOGGED IN PLAIN TEXT [!]
Target Mailbox: $($MigrationConfig.TargetMailbox)
Status: ACCESS_GRANTED
"@

    $logContent | Out-File -FilePath "C:\Temp\migration_debug.log" -Force
    Write-Host "[INFO] Debug log created: C:\Temp\migration_debug.log" -ForegroundColor Cyan
    
}
catch {
    # Error handling that exposes credentials in debug info
    Write-Host "[ERROR] Migration failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "[DEBUG] Failed with credentials: $($MigrationConfig.ServiceAccount)/$($MigrationConfig.ServicePassword)" -ForegroundColor Red
}

Write-Host ""
Write-Host "[INFO] Migration process completed" -ForegroundColor Cyan
Write-Host "[INFO] Check C:\Temp\migration_debug.log for details" -ForegroundColor Gray
