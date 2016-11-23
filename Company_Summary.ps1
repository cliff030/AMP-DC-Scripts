. "c:\scripts\resources\DatabaseConfig.ps1"

$URI = "http://AMP-DC/ReportServer/ReportExecution2005.asmx?wsdl"
$format = "pdf"
$deviceinfo = ""            
$extention = ""            
$mimeType = ""            
$encoding = "UTF-8"            
$warnings = $null            
$streamIDs = $null

$EndDate = Get-Date
$StartDate = [datetime]([string]$EndDate.Year + "-" + [string]$EndDate.Month + "-01")

if($EndDate.DayOfWeek -eq "Saturday" -or $EndDate.DayOfWeek -eq "Sunday") {
    exit
}

function EmailReport($ReportName,$ReportFile,$ReportDate) {
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
    $Msg.CC.Add( (New-Object Net.Mail.MailAddress("almaw@ampaccount.com","Alma Wiseman")) )
    
    $Msg.Subject = $Subject
    $Msg.Body = "See attached."
    $Msg.Attachments.Add($Report)
    
    $Smtp.Send($Msg)
    $Report.Dispose()
}


foreach($Company in $global:Companies) {
    if($Company."Active" -eq $true) {
        SelectCompany $Company."DB"
    
        $ReportPath = GetReportPath
    
        $ReportName = $ReportPath + "CompanySummary"
        
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
        
        $ReportFile = "$env:TEMP\" + $Company."DB" + "_CompanySummary-" + $StartDate.ToString("yyyy.MM.dd") + ".pdf"
        
        $fileStream = New-Object System.IO.FileStream($ReporTfile, [System.IO.FileMode]::OpenOrCreate)
        $fileStream.Write($render, 0, $render.Length)
        $fileStream.Close()
        
        $ReportName = $Company."Name" + " - Company Summary"
        
        EmailReport $ReportName $ReportFile $EndDate
    }
}
