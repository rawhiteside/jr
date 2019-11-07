@echo off
set EGYPTC="C:\eGenesis\A Tale in the Desert\egyptc"
del /F %EGYPTC%\%1
type nul > %EGYPTC%\%1
attrib +R %EGYPTC%\%1
