@echo off
net stop SQLSERVERAGENT
net stop MSSQLSERVER
net start MSSQLSERVER
net start SQLSERVERAGENT