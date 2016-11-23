. "c:\scripts\resources\LoadSqlPs.ps1"

LoadSqlPs

. "c:\scripts\resources\DatabaseConfig 2.0.ps1"

$URI = "http://AMP-DC/ReportServer/ReportExecution2005.asmx?wsdl"
$format = "pdf"
$deviceinfo = ""            
$extention = ""            
$mimeType = ""            
$encoding = "UTF-8"            
$warnings = $null            
$streamIDs = $null

$Databases = ( "CSDATA9_INC", "CSDATA9_FFN" )
$Reports = ("ConvertedLeadsByDateRange", "NewLeadsByDateRange")

# Figure out the closest previous Monday to today
function GetStartDate {
    $StartDate = ( Get-Date )
       
    while( $StartDate.DayOfweek -ne "Monday") {
        $StartDate = $StartDate.AddDays(-1)
    }
    
    return $StartDate
}

function EmailReport($ReportName, $ReportFile, $ReportDate) {
    # Make the report title in the e-mail subject human readable
    if($ReportName -eq "ConvertedLeadsByDateRange" ) {
        $ReportName = "Converted Leads"
    } elseif($ReportName -eq "NewLeadsByDateRange") {
        $ReportName = "New Leads"
    }
    
    $ReportName = $global:Company."Name" + " $ReportName"

    $Sender = New-Object Net.Mail.MailAddress("reports@ampaccount.com","AMP Reports")
    $Recipient = New-Object Net.Mail.MailAddress("boudreau.bruce@gmail.com","Bruce Boudreau")
    $CC = New-Object Net.Mail.MailAddress("chris@ampaccount.com","Chris Brundage")
    
    $Subject = "$ReportName " + $ReportDate.ToString("MM/dd/yyyy")
    
    $SmtpHost = "mail.myampaccount.com"
    $Port = 587
    $Username = "reports@ampaccount.com"
    $Password = "W9GQrn1aO1IgOKZZ"
    
    $Report = New-Object Net.Mail.Attachment($ReportFile)
    $Msg = New-Object Net.Mail.MailMessage
    
    $Smtp = New-Object Net.Mail.SmtpClient($SmtpHost,$Port)
    $Smtp.Credentials = New-Object Net.NetworkCredential($Username,$Password)
    
    $Msg.From = $Sender
    $Msg.To.Add($Recipient)
    $Msg.CC.Add($CC)
    $Msg.Subject = $Subject
    $Msg.Body = "See attached."
    $Msg.Attachments.Add($Report)
    
    $Smtp.Send($Msg)
    $Report.Dispose()
}

$EndDate = ( Get-Date )

if($EndDate.DayOfWeek -eq "Saturday" -or $EndDate.DayOfWeek -eq "Sunday") {
    exit
}

$StartDate = GetStartDate



foreach($Database in $Databases)
{
    SelectCompany $Database
    
    $ReportPath = GetReportPath
    
    foreach($Report in $Reports) {
        $ReportName = $ReportPath + $Report
           
        $ReportObject = New-WebServiceProxy -Uri $URI -UseDefaultCredential -namespace "ReportExecution2005"  

        $rsExec = New-Object ReportExecution2005.ReportExecutionService            
        $rsExec.Credentials = [System.Net.CredentialCache]::DefaultCredentials             
                
        #Set ExecutionParameters            
        $execInfo = @($ReportName, $null)             
                
        #Load the selected report.            
        $rsExec.GetType().GetMethod("LoadReport").Invoke($rsExec, $execInfo) | out-null       

        #Report Parameters
        $ParamStartDate = new-object ReportExecution2005.ParameterValue
        $ParamStartDate.Name = "StartDate"
        $ParamStartDate.Value = $StartDate.ToString("MM/dd/yyyy")

        $ParamEndDate = new-object ReportExecution2005.ParameterValue
        $ParamEndDate.Name = "EndDate"
        $ParamEndDate.Value = $EndDate.ToString("MM/dd/yyyy")

        $Parameters = [ReportExecution2005.ParameterValue[]] ($ParamStartDate,$ParamEndDate)

        #Set ExecutionParameters            
        $ExecParams = $rsExec.SetExecutionParameters($Parameters, "en-us");             
                
        $Render = $rsExec.Render($format, $deviceInfo,[ref] $extention, [ref] $mimeType,[ref] $encoding, [ref] $warnings, [ref] $streamIDs)             
        
        $ReportFile = "$env:TEMP\" + $global:Company."Name" + "_" + $Report + "-" + $EndDate.ToString("yyyy.MM.dd") + ".pdf"
        
        $fileStream = New-Object System.IO.FileStream($ReporTfile, [System.IO.FileMode]::OpenOrCreate)
        $fileStream.Write($render, 0, $render.Length)
        $fileStream.Close()
        
        EmailReport $Report $ReportFile $EndDate
    }
}
