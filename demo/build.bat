@echo off
set PROJECTNAME="DevSound"

rem	Build ROM
echo Assembling...
rgbasm -i ../ -o %PROJECTNAME%.obj -p 255 Main.asm
if errorlevel 1 goto :BuildError
rgbasm -DGBS -i ../ -o %PROJECTNAME%_GBS.obj -p 255 Main.asm
if errorlevel 1 goto :BuildError
echo Linking...
rgblink -p 255 -o %PROJECTNAME%.gbc -n %PROJECTNAME%.sym %PROJECTNAME%.obj
if errorlevel 1 goto :BuildError
rgblink -p 255 -o %PROJECTNAME%_GBS.gbc %PROJECTNAME%_GBS.obj
if errorlevel 1 goto :BuildError
echo Fixing...
rgbfix -v -p 255 %PROJECTNAME%.gbc
echo Cleaning up...
del %PROJECTNAME%.obj
echo Build complete.
rem Build GBS file
echo Building GBS file...
py makegbs.py
if errorlevel 1 goto :GBSMakeError
echo GBS file built.
del /f %PROJECTNAME%_GBS.obj %PROJECTNAME%_GBS.gbc
goto :end

:BuildError
set PROJECTNAME=
echo Build failed, aborting...
goto:eof

:GBSMakeError
set PROJECTNAME=
echo GBS build failed, aborting...
goto:eof

:end
rem unset vars
set PROJECTNAME=
echo ** Build finished with no errors **
