@echo off
rem NC2HPGL.EXEを使用する場合はこのファイルは必要ない

rem GNU sortがWindowsのsort.exeより先に見つかるようにする
set Path=c:\cygwin\bin;%Path%;

rem del p_out.bat
rem print
cd \usr\local\CygHPGL

if "%1" == "" goto convert

copy %1 \usr\local\CygHPGL\nc
gawk -f nc2hplib.awk -f uif.awk

:convert
rem	jgawk --memory --file=convert.awk
	gawk -f nc2hplib.awk -f convert.awk

rem call p_out.bat
