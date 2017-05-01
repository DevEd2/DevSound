@echo off
rem	Build script for DevSound

rem	Build ROM
echo Assembling...
rgbasm -o DevSound.obj -p 255 Main.asm
if errorlevel 1 goto :BuildError
echo Linking...
rgblink -p 255 -o DevSound.gb -n DevSound.sym DevSound.obj
echo Fixing...
rgbfix -v -p 255 DevSound.gb
echo Build complete.
goto MakeGBS

rem Clean up files
del DevSound.obj

rem Make GBS file
:MakeGBS
echo Building GBS file...
py makegbs.py
if errorlevel 1 goto :GBSMakeError
echo GBS file built.
goto:eof

:BuildError
echo Build failed, aborting...
goto:eof

:GBSMakeError
echo GBS build failed, aborting...
