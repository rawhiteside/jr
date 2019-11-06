@echo off
set EGYPTC="C:\eGenesis\A Tale in the Desert\egyptc"
type nul > %1
copy %1 %EGYPTC%
attrib +R %EGYPTC%\%1
