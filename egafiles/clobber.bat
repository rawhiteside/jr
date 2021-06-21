@echo off
REM The single argument to this is the name of the file to clobber in
REM the egyptc directory.
REM 
REM    clobber egac07a0671c5c23dcd5ab488970e4b525f742d54a1.ega
REM
REM The named file gets replaced with a zero-length readonly file.
REM 
REM Make sure the egyptc directory define is correct for your install.
REM 
set EGYPTC="C:\Program Files (x86)\Desert Nomad Studios\A Tale In The Desert\egyptc"
if exist %EGYPTC%\%1 del /F %EGYPTC%\%1
type nul > %EGYPTC%\%1
attrib +R %EGYPTC%\%1
