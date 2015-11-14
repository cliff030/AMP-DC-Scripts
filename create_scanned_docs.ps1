#. "C:\scripts\Resources\LoadSqlPs.ps1"
. "C:\scripts\Resources\DatabaseConfig.ps1"

$ErrorActionPreference="SilentlyContinue"
Stop-Transcript | out-null
$ErrorActionPreference = "Continue"

Start-Transcript -path "c:\scripts\Resources\Document Imaging\errors.txt"

Import-Module “sqlps” -DisableNameChecking

function GetLastRunDate()
{
    $Sql = "SELECT TOP 1 RunDate FROM Custom_ScannedDocsLog WHERE Success = 1 ORDER BY RunDate DESC"
    
    $Result = Invoke-Sqlcmd -Query $Sql -ServerInstance $global:DSN -Database $global:Company."DB" -SuppressProviderContextWarning
        
    if($Result -ne $null -and $Result[0].GetType().Name -eq "DateTime")
    {
        return $Result[0]
    }
    else
    {
        return ( Get-Date -Date "1970-01-01 00:00:00" )
    }
}

function SetLastRunDate($Date)
{
    if($Date.GetType().Name -ne "DateTime")
    {
        throw "$Date is not a valid DateTime object."
    }
    
    $Sql = "SELECT * FROM Custom_ScannedDocsLog WHERE Success = 1"
    
    $Result = Invoke-Sqlcmd -Query $Sql -ServerInstance $global:DSN -Database $global:Company."DB" -SuppressProviderContextWarning
    
    if($Result -eq $null)
    {
        $Sql = "INSERT INTO Custom_ScannedDocsLog VALUES ('" + $Date.ToString() + "', 1)"
    }
    else
    {
        $Sql = "UPDATE Custom_ScannedDocsLog SET RunDate = '" + $Date.ToString() + "' WHERE Success = 1"
    }
    
    
    Invoke-Sqlcmd -Query $Sql -ServerInstance $global:DSN -Database $global:Company."DB" -SuppressProviderContextWarning
}

function SetFilePath($Company,$Type) {
    $FilePath = "\\AMP\" + $Company."Name" + "\"
    
    if($Company."Name" -eq "Select Financial") {
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

function CreateDirectory($Company,$Type,$ID) {
    try 
    {
        $FilePath = SetFilePath $Company $Type
        $FilePath = $FilePath + $ID
    
        if( (Test-Path -LiteralPath "FileSystem::$FilePath") -eq $false) 
        {            
            New-Item "FileSystem::$FilePath" -Type Directory | Out-Null
        }
    } 
    catch [System.Exception] 
    {
        throw $_
    }
}

foreach($local:Company in $global:Companies) {
    if($local:Company."Active" -eq $true)
    {
        try
        {
            SetCompany $local:Company
            
            $LastRunDate = GetLastRunDate
            
            $ClientsSQL = "SELECT DISTINCT ClientID FROM Clients WHERE DateEntered >= '" + $LastRunDate + "' ORDER BY ClientID"
            $LeadsSQL = "SELECT DISTINCT ClientID FROM LeadClient WHERE DateEntered >= '" + $LastRunDate + "' ORDER BY ClientID"
            $CreditorsSQL = "SELECT DISTINCT CreditorID FROM Creditors WHERE CreditorAdded >= '" + $LastRunDate + "' ORDER BY CreditorID"
            $IssuesSQL = "SELECT DISTINCT IssueID FROM Issues WHERE Status<>'Completed' AND Status<>'Closed' AND CreatedDate >= '" + $LastRunDate + "' ORDER BY IssueID"

            $SqlStatements = @{"Clients"=$ClientsSQL;"Leads"=$LeadsSQL;"Creditors"=$CreditorsSQL;"Issues"=$IssuesSQL}           
            
            
            foreach($Sql in $SqlStatements.GetEnumerator()) 
            {            
                if($global:Company."Name" -eq "Select Financial" -and ( $Sql."Name" -eq "Creditors" -or $Sql."Name" -eq "Issues" ) ) 
                {
                    continue
                } 
                else 
                {        
                    Invoke-Sqlcmd -Query $Sql."Value" -ServerInstance $global:DSN -Database $global:Company."DB" -SuppressProviderContextWarning | ForEach-Object {
                        CreateDirectory $global:Company $Sql."Name" $_[0]
                    }
                }
            }
            
            $LastRunDate = ( Get-Date )
            
            SetLastRunDate $LastRunDate
        } 
        catch [System.Exception]
        {
            Write-Host $_.Exception.ToString()
        }
    }

    
}

Stop-Transcript | out-null