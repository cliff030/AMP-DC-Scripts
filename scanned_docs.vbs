Set colArgs = WScript.Arguments.Named
ID = colArgs.Item("ID")
strType = colArgs.Item("Type")
Company = colArgs.Item("Company")

command = "powershell.exe & '\\amp\support\Creditsoft Scripts\Scanned Documents.ps1' -Company " & "'" & Company & "' -Type '" & strType & "' " & ID
set shell = CreateObject("WScript.Shell")
shell.Run command,0
