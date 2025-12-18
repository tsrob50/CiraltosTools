@echo off

REM Create an input box to ask for UPN
@echo off
SET tempfile="%TEMP%\input.tmp"

REM Create a VBScript file on the fly to show an InputBox
echo Dim input, fso, ts > %tempfile%.vbs
echo input = InputBox("Please enter UPN/Email Address:", "User Input") >> %tempfile%.vbs
echo Set fso = CreateObject("Scripting.FileSystemObject") >> %tempfile%.vbs
echo Set ts = fso.CreateTextFile(%tempfile%, True) >> %tempfile%.vbs
echo ts.Write input >> %tempfile%.vbs
echo ts.Close >> %tempfile%.vbs

REM Run the VBScript
cscript //nologo %tempfile%.vbs

REM Read the input from the temporary file into a batch variable
FOR /F "usebackq tokens=*" %%i IN (%tempfile%) DO SET UserName=%%i

REM Clean up the temporary files
DEL %tempfile%.vbs
DEL %tempfile%

REM Run the windows365.exe command with the provided UPN
REM Update the ObjectID

windows365.exe "ms-avd:connect?resourceid=<ObjectId>&username=%UserName%&usemultimon=true"

REM exit the script
exit
