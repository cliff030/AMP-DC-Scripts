$BackupHost = '\\BACKUP'
$BackupUser = 'administrator'
$BackupPassword = '6^i[fFY%UQ=}<6b.'
$BackupDomain = 'AMP'

$Servers = @( 'CSOFT-TS', 'CSOFT-WEB', 'AMP-DC' )
$Workstations = @( 'ALMA', 'ASHLEE', 'STA103' )

$BackupLogFile = 'C:\Windows\Logs\amp_backup.log'
$ErrorLogFile = 'C:\Windows\Logs\amp_backup-err.log'

function WriteLog($Str,$LogFile) {
    $CurrentDate = Get-Date
    
    $LogDate = $CurrentDate.ToString("yyyy-MM-dd hh:mm:ss")

    $LogDate + ": " + $Str | Out-File -Append $LogFile
}

function GetBackupType {
    $CurrentDate = Get-Date
    
    #$CurrentDate = [System.DateTime]"2013-01-01 00:00:00" # monthly
    #$CurrentDate = [System.DateTime]"2015-02-01 00:00:00" # both
    
    if( $CurrentDate.Day -eq 1 -and $CurrentDate.DayOfWeek -eq 'Sunday' ) {
        return "both"
    } elseif( $CurrentDate.Day -eq 1 ) {
        return "monthly"
    } elseif( $CurrentDate.DayOfWeek -eq 'Sunday' ) {
        return "weekly"
    } else {
        return "skip"
    }
}

function BackupServers( $Type ) {
    if( $Type -ne "weekly" -and $Type -ne "monthly" ) {
        Throw "Invalid Backup Type"
    }

    $Directory = 'daily'
    
    foreach( $Server in $Servers ) {
        $BackupSource = $BackupHost + "\" + $Server + "-BACKUP\" + $Directory
        $BackupDestination = $BackupHost + "\" + $Server + "-BACKUP\" + $Type
        
        
            
        robocopy $BackupSource $BackupDestination /COPYALL /LOG+:$BackupLogFile /B /E /R:1 /DCOPY:T /MIR /Z | Out-Null
    }
}

$BackupType = $args[0]
#GetBackupType

if( $BackupType -eq 'skip' ) {
    exit 0
}

try {
    if( $BackupType -eq 'both' ) {
        BackupServers 'weekly'
        BackupServers 'monthly'
    } else {
        BackupServers $BackupType
    }
} catch [Exception] {
    WriteLog $_.Exception.Message $ErrorLogFile
}
