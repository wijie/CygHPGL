@echo off
rem NC2HPGL.EXE���g�p����ꍇ�͂��̃t�@�C���͕K�v�Ȃ�

rem GNU sort��Windows��sort.exe����Ɍ�����悤�ɂ���
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
