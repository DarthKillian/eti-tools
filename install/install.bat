@echo off

powershell -command "iwr 'https://github.com/DarthKillian/eti-tools/releases/latest/download/netpro.zip' -OutFile '%temp%\netpro.zip'; Expand-Archive '%temp%\netpro.zip' -DestinationPath 'C:\ProgramData\netpro' -Force; & copy 'C:\ProgramData\netpro\netpro.bat' '%userprofile%\Desktop';"

echo Download and install completed. Press any key to launch netpro and exit the installer...

pause
%userprofile%\Desktop\netpro.bat