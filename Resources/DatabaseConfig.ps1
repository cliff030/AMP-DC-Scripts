$global:DSN = "tcp:AMP-DC,1433"

$global:Companies = (
    (New-Object PSObject -Property @{
        "Name"="Select Financial";
        "DB"="CSDATA8";
        "MenuOption"="1";
        "Active"=$true;
    }),
    (New-Object PSObject -Property @{
        "Name"="Liberty Financial";
        "DB"="CSDATA8_INC";
        "MenuOption"="2";
        "Active"=$true;
    }),
    (New-Object PsObject -Property @{
        "Name"="First Financial";
        "DB"="CSDATA8_FFN";
        "MenuOption"="3";
        "Active"=$true;
    }),
    (New-Object PsObject -Property @{
        "Name"="Karma Capital";
        "DB"="CSDATA8_KAR";
        "MenuOption"="4";
        "Active"=$true;
    })
)

$global:DB = $null
$global:Company = $null

function CheckCompany($CompanyToCheck)
{
    foreach($local:Company in $global:Companies)
    {
        if($local:Company."DB" -eq $CompanyToCheck."DB")
        {
            return $true
        }
    }
    
    return $false
}

function SetCompany($Company)
{
    if( (CheckCompany $Company) -eq $false)
    {
        throw "Invalid Comapny"
    }
    
    Set-Variable -Scope Global -Name Company -Value $Company
    Set-Variable -Scope Global -Name DB -Value $Company."DB"
}

function GetReportPath()
{
    if($global:Company -eq $null)
    {
        throw "Cannot call GetReportPath without setting a Company first."
    }
    
    $ReportPath = "/CREDITSOFT/" + $global:Company."DB".ToLower() + "_Reports/"
    
    return $ReportPath
}

# Prompts the user to pick which company/database is to be used.
# Once the user selects a valid options the global variables $DB and $Company will be set by the SetCompany function.
# Currently, the only options are Select Financial (CSDATA8) and Liberty Financial (CSDATA8_INC)
function SelectCompany($DatabaseName = $null)
{
    if($DatabaseName -eq $null)
    {
        $k = 0    
        while($k -eq 0)
        {
            $OptionList = "Database options:`n"
            foreach($Company in $Companies)
            {
                if($Company."Active" -eq $true)
                {
                    $OptionList += $Company."MenuOption" + ". " + $Company."Name" + "`n"
                }
            }
        
            Write-Host $OptionList
            $Selection = Read-host "Select your database"
            
            $match = $false
            for($i = 0; $i -lt $Companies.Length; $i++)
            {
                if($Companies[$i]."MenuOption" -eq $Selection)
                {
                    $match = $true
                    break
                }
            }
            
            if($match -eq $true)
            {
                $k++
                SetCompany $Companies[$i]
            }
            else
            {
                Write-Host "Invalid selection!"
            }
        }
    }
    else
    {
        $success = $false
    
        foreach($Company in $Companies)
        {
            if($Company."DB" -eq $DatabaseName)
            {
                SetCompany $Company
                $success = $true
            }
        }
        
        if($success -eq $false)
        {
            SelectCompany $null
        }
    }
}