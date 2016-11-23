. "c:\scripts\Resources\LoadSqlPs.ps1"

try
{
    Import-Module -DisableNameChecking SqlPs
}
catch [exception]
{
    LoadSqlPs
}

. "c:\scripts\Resources\DatabaseConfig 2.0.ps1"

function GetLastSaturday
{
    $Date = (Get-Date -Hour 0 -Minute 00 -Second 00)
    
    $i = 0
    while($i -eq 0)
    {
        $Date = $Date.AddDays(-1)
        
        if($Date.DayOfWeek -eq "Saturday")
        {
            $i++
        }
    }
    
    return $Date
}

$LastBackupDate = GetLastSaturday

$Dirs = @()

foreach($Company in $Global:Companies)
{
    $Dirs += $Company.DB
}

Foreach($Dir in $Dirs)
{
    Get-ChildItem -Recurse f:\Backup\Databases\$Dir | Where-Object {$_.Mode -NotMatch "d"} | Where-Object {$_.LastWriteTime -lt $LastBackupDate} | Remove-Item
}
