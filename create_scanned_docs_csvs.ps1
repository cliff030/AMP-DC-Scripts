function LoadSqlPs {
    #
	# Add the SQL Server Provider.
	#
	if ( (Get-PSSnapin -Name SqlServerCmdletSnapin100 -ErrorAction SilentlyContinue) -eq $null ) {
	    $ErrorActionPreference = "Stop"
	
	    $sqlpsreg="HKLM:\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.SqlServer.Management.PowerShell.sqlps"
	
	    if (Get-ChildItem $sqlpsreg -ErrorAction "SilentlyContinue") {
	        throw "SQL Server Provider for Windows PowerShell is not installed."
	    }
	    else {
	        $item = Get-ItemProperty $sqlpsreg
	        $sqlpsPath = [System.IO.Path]::GetDirectoryName($item.Path)
	    }
	
	
	    #
	    # Set mandatory variables for the SQL Server provider
	    #
	    Set-Variable -scope Global -name SqlServerMaximumChildItems -Value 0
	    Set-Variable -scope Global -name SqlServerConnectionTimeout -Value 30
	    Set-Variable -scope Global -name SqlServerIncludeSystemObjects -Value $false
	    Set-Variable -scope Global -name SqlServerMaximumTabCompletion -Value 1000
	
	    #
	    # Load the snapins, type data, format data
	    #
	    Push-Location
	    cd $sqlpsPath
	    Add-PSSnapin SqlServerCmdletSnapin100
	    Add-PSSnapin SqlServerProviderSnapin100
	    Update-TypeData -PrependPath SQLProvider.Types.ps1xml 
	    update-FormatData -prependpath SQLProvider.Format.ps1xml 
	    Pop-Location
	}
}

LoadSqlPs

$client_sql = "SELECT DISTINCT ClientID FROM Clients ORDER BY ClientID"
$lead_sql = "SELECT DISTINCT ClientID FROM LeadClient ORDER BY ClientID"
$creditor_sql = "SELECT DISTINCT CreditorID FROM Creditors ORDER BY CreditorID"
$issue_sql = "SELECT DISTINCT IssueID FROM Issues WHERE Status<>'Completed' AND Status<>'Closed' ORDER BY IssueID"

for($j=0;$j -lt 2;$j++) {
    if($j -eq 0) {
        cd SQLSERVER:\SQL\AMP-DC\DEFAULT\Databases\CSDATA8
    } elseif($j -eq 1) {
        cd SQLSERVER:\SQL\AMP-DC\DEFAULT\Databases\CSDATA8_INC
    }
    
    for($i=0;$i -le 3;$i++) {
        if($i -eq 0) {
            $sql = $client_sql
            
            if($j -eq 0){
                $csv_file="C:\scripts\Resources\Document Imaging\select_clients.csv"
            } elseif($j -eq 1) {
                $csv_file="C:\scripts\Resources\Document Imaging\liberty_clients.csv"
            }
        } elseif($i -eq 1) {
            $sql = $lead_sql
            
            if($j -eq 0){
                $csv_file="C:\scripts\Resources\Document Imaging\select_leads.csv"
            } elseif($j -eq 1) {
                $csv_file="C:\scripts\Resources\Document Imaging\liberty_leads.csv"
            }
        } elseif($i -eq 2 ) {
            $sql = $creditor_sql
            
            if($j -eq 0){
                $csv_file="C:\scripts\Resources\Document Imaging\select_creditors.csv"
            } elseif($j -eq 1) {
                $csv_file="C:\scripts\Resources\Document Imaging\liberty_creditors.csv"
            }
        } elseif($i -eq 3) {
            $sql = $issue_sql
            
            if($j -eq 0){
                $csv_file="C:\scripts\Resources\Document Imaging\select_issues.csv"
            } elseif($j -eq 1) {
                $csv_file="C:\scripts\Resources\Document Imaging\liberty_issues.csv"
            }
        }
	Invoke-Sqlcmd $sql | Out-String | %{$_ -replace "[a-z][A-Z]*",""} | %{$_ -replace "\-*",""} | %{$_ -replace " ",""} | Out-File -Encoding "UTF8" $csv_file
    }
}

perl C:\Scripts\create_scanned_docs_directories.pl
