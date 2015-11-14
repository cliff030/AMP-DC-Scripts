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

$Dirs = @("CSDATA8", "CSDATA8_INC", "CSDATA8_FFN", "CSDATA8_KAR")

Foreach($Dir in $Dirs)
{
    Get-ChildItem -Recurse f:\Backup\Databases\$Dir | Where-Object {$_.Mode -NotMatch "d"} | Where-Object {$_.LastWriteTime -lt $LastBackupDate} | Remove-Item
}