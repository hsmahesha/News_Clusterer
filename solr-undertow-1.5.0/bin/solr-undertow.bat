@if "%DEBUG%" == "" @echo off
@rem ##########################################################################
@rem
@rem  solr-undertow startup script for Windows
@rem
@rem ##########################################################################

@rem Set local scope for the variables with windows NT shell
if "%OS%"=="Windows_NT" setlocal

@rem Add default JVM options here. You can also use JAVA_OPTS and SOLR_UNDERTOW_OPTS to pass JVM options to this script.
set DEFAULT_JVM_OPTS="-Dfile.encoding=UTF-8"

set DIRNAME=%~dp0
if "%DIRNAME%" == "" set DIRNAME=.
set APP_BASE_NAME=%~n0
set APP_HOME=%DIRNAME%..

@rem Find java.exe
if defined JAVA_HOME goto findJavaFromJavaHome

set JAVA_EXE=java.exe
%JAVA_EXE% -version >NUL 2>&1
if "%ERRORLEVEL%" == "0" goto init

echo.
echo ERROR: JAVA_HOME is not set and no 'java' command could be found in your PATH.
echo.
echo Please set the JAVA_HOME variable in your environment to match the
echo location of your Java installation.

goto fail

:findJavaFromJavaHome
set JAVA_HOME=%JAVA_HOME:"=%
set JAVA_EXE=%JAVA_HOME%/bin/java.exe

if exist "%JAVA_EXE%" goto init

echo.
echo ERROR: JAVA_HOME is set to an invalid directory: %JAVA_HOME%
echo.
echo Please set the JAVA_HOME variable in your environment to match the
echo location of your Java installation.

goto fail

:init
@rem Get command-line arguments, handling Windowz variants

if not "%OS%" == "Windows_NT" goto win9xME_args
if "%@eval[2+2]" == "4" goto 4NT_args

:win9xME_args
@rem Slurp the command line arguments.
set CMD_LINE_ARGS=
set _SKIP=2

:win9xME_args_slurp
if "x%~1" == "x" goto execute

set CMD_LINE_ARGS=%*
goto execute

:4NT_args
@rem Get arguments from the 4NT Shell from JP Software
set CMD_LINE_ARGS=%$

:execute
@rem Setup the command line

set CLASSPATH=%APP_HOME%\lib\solr-undertow-1.5.0.jar;%APP_HOME%\lib\jackson-annotations-2.6.2.jar;%APP_HOME%\lib\undertow-servlet-1.3.0.Final.jar;%APP_HOME%\lib\klutter-core-jdk7-0.7.2.jar;%APP_HOME%\lib\klutter-config-typesafe-jdk7-0.7.2.jar;%APP_HOME%\lib\jackson-module-kotlin-2.6.2-3.jar;%APP_HOME%\lib\config-1.2.1.jar;%APP_HOME%\lib\kotlin-reflect-0.14.451.jar;%APP_HOME%\lib\kotlin-stdlib-0.14.451.jar;%APP_HOME%\lib\injekt-api-1.7.1.jar;%APP_HOME%\lib\slf4j-api-1.7.12.jar;%APP_HOME%\lib\logback-classic-1.1.3.jar;%APP_HOME%\lib\logback-access-1.1.3.jar;%APP_HOME%\lib\jcl-over-slf4j-1.7.12.jar;%APP_HOME%\lib\jackson-core-2.6.2.jar;%APP_HOME%\lib\jul-to-slf4j-1.7.12.jar;%APP_HOME%\lib\log4j-over-slf4j-1.7.12.jar;%APP_HOME%\lib\undertow-core-1.3.0.Final.jar;%APP_HOME%\lib\jboss-servlet-api_3.1_spec-1.0.0.Final.jar;%APP_HOME%\lib\jboss-annotations-api_1.2_spec-1.0.0.Final.jar;%APP_HOME%\lib\klutter-core-jdk6-0.7.2.jar;%APP_HOME%\lib\klutter-json-jackson-jdk6-0.7.2.jar;%APP_HOME%\lib\klutter-config-typesafe-jdk6-0.7.2.jar;%APP_HOME%\lib\kotlin-runtime-0.14.451.jar;%APP_HOME%\lib\logback-core-1.1.3.jar;%APP_HOME%\lib\jboss-logging-3.2.1.Final.jar;%APP_HOME%\lib\xnio-api-3.3.2.Final.jar;%APP_HOME%\lib\xnio-nio-3.3.2.Final.jar;%APP_HOME%\lib\injekt-core-1.7.1.jar;%APP_HOME%\lib\jackson-databind-2.6.2.jar

@rem Execute solr-undertow
"%JAVA_EXE%" %DEFAULT_JVM_OPTS% %JAVA_OPTS% %SOLR_UNDERTOW_OPTS%  -classpath "%CLASSPATH%" org.bremeld.solr.undertow.UndertowPackage %CMD_LINE_ARGS%

:end
@rem End local scope for the variables with windows NT shell
if "%ERRORLEVEL%"=="0" goto mainEnd

:fail
rem Set variable SOLR_UNDERTOW_EXIT_CONSOLE if you need the _script_ return code instead of
rem the _cmd.exe /c_ return code!
if  not "" == "%SOLR_UNDERTOW_EXIT_CONSOLE%" exit 1
exit /b 1

:mainEnd
if "%OS%"=="Windows_NT" endlocal

:omega
