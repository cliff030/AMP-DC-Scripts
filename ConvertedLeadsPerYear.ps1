. "c:\scripts\resources\DatabaseConfig.ps1"

$URI = "http://AMP-DC/ReportServer/ReportExecution2005.asmx?wsdl"
$format = "PDF"
$deviceinfo = ""            
$extension = ""            
$mimeType = ""            
$encoding = "UTF-8"            
$warnings = $null            
$streamIDs = $null

$Databases = ("CSDATA9","CSDATA9_INC")

$CurDate = Get-Date

$DaysInCurMonth = [datetime]::DaysInMonth($CurDate.Year, $CurDate.Month)

if($CurDate.Day -ne $DaysInCurMonth)
{
    exit
}

function EmailReport($ReportName,$ReportFile,$ReportDate) {
    $Sender = New-Object Net.Mail.MailAddress("reports@ampaccount.com","AMP Reports")
    $Recipient = New-Object Net.Mail.MailAddress("boudreau.bruce@gmail.com","Bruce Boudreau")
    $CC = New-Object Net.Mail.MailAddress("chris@ampaccount.com","Chris Brundage")
    
    $Subject = "$ReportName " + $ReportDate.ToString("MMMM yyyy")
    
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


foreach($Database in $Databases) {
    try
    {
        SelectCompany $Database
        
        $ReportPath = GetReportPath
        
        $ReportName = $ReportPath + "Custom_ConvertedLeadsPerYear"
    
        $ReportObject = New-WebServiceProxy -Uri $URI -UseDefaultCredential -namespace "ReportExecution2005"  

        $rsExec = New-Object ReportExecution2005.ReportExecutionService            
        $rsExec.Credentials = [System.Net.CredentialCache]::DefaultCredentials             
                
        #Set ExecutionParameters            
        $execInfo = @($ReportName, $null)             
                
        #Load the selected report.            
        $rsExec.GetType().GetMethod("LoadReport").Invoke($rsExec, $execInfo) | out-null       

        #Report Parameters
        $ParamCurDate = new-object ReportExecution2005.ParameterValue
        $ParamCurDate.Name = "CurDate"
        $ParamCurDate.Value = $CurDate.ToString("MM/dd/yyyy")


        $Parameters = [ReportExecution2005.ParameterValue[]] ($ParamCurDate)

        #Set ExecutionParameters            
        $ExecParams = $rsExec.SetExecutionParameters($Parameters, "en-us");             
                
        $Render = $rsExec.Render($format, $deviceInfo,[ref] $extension, [ref] $mimeType,[ref] $encoding, [ref] $warnings, [ref] $streamIDs)             
        
        $ReportFile = "$env:TEMP\" + $Company."DB" + "ConvertedLeadsPerYear-" + $CurDate.ToString("yyyy.MM.dd") + ".pdf"
        
        $fileStream = New-Object System.IO.FileStream($ReporTfile, [System.IO.FileMode]::OpenOrCreate)
        $fileStream.Write($render, 0, $render.Length)
        $fileStream.Close()
        
        $ReportName = $Company."Name" + " - Converted Leads Monthly Comparison"
        
        EmailReport $ReportName $ReportFile $CurDate
    }
    catch [System.Exception]
    {
        Write-Host $_.Exception.ToString()
    }
}
