#$FilePath = "\\AMP\Liberty Financial\Scanned Documents\Clients\1234"

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True,Position=1)]
    [string]$ID,
    [Parameter(Mandatory=$True)]
    [string]$Type,
    [Parameter(Mandatory=$True)]
    [string]$Company
)

function SetFilePath($Company,$Type) {
    $FilePath = "\\AMP\" + $Company + "\"
    
    if($Company -eq "Select Financial") {
        $FilePath = $FilePath + "Reports\"
        
        switch($Type) {
            "Clients" {
                $FilePath = $FilePath + "Client"
            }
            "Leads" {
                $Filepath = $FilePath + "Lead"
            }
            default {
                throw "This type is not valid for this company."
            }
        }
    } else {
        $FilePath = $FilePath + "Scanned Documents\$Type\"
    }

    return $FilePath
}

$FilePath = SetFilePath $Company $Type
$FilePath = $FilePath + $ID

if( (Test-Path -LiteralPath "FileSystem::$FilePath") -eq $false) 
{
    New-Item "FileSystem::$FilePath" -Type Directory | Out-Null
}

explorer.exe $FilePath
