@echo off
REM Ask the user for their UPN
SET /P UserName=Enter your Email Address: 

windows365.exe "ms-avd:connect?resourceid=<ObjectId>&username=%UserName%&usemultimon=true"
