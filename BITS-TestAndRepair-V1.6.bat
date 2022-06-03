@echo off
mode con: cols=170 lines=44
color 3
setlocal EnableDelayedExpansion

::##########################################################
:::           _    _    _                _    _          __
:::          /_\  | |_ | |  __ _  _ __  | |_ (_)  ___   / /   ___    __ _
:::         //_\\ | __|| | / _` || '_ \ | __|| | / __| / /   / _ \  / _` |
:::        /  _  \| |_ | || (_| || | | || |_ | || (__ / /___| (_) || (_| |
:::        \_/ \_/ \__||_| \__,_||_| |_| \__||_| \___|\____/ \___/  \__, |
:::                                                                 |___/ 
::
set "_DOWNLOAD_DIR=%USERPROFILE%\Downloads"
::
set _JOB_NAME=BITS-TESTS
::
:: Exemple de test de telechargement avec authentification
:: https://install.atlanticlog.org/install/script/sh/arbo_client/installWindows/viaPowerShell/installOnlyCygwinViaPowerShell.bat
:: user = AtlanticLog / pwd = atlog17
::
::##########################################################


::##########################################################
set _VER=1.6
Title (G)emarcur - Gestion du service BITS (%~nx0)
::##########################################################

::##########################################################
:ADMIN_RIGHTS
::##########################################################

Reg query "HKU\S-1-5-19\Environment" >nul 2>&1

if !ERRORLEVEL! NEQ 0 (
	goto :get_admin_rights
) else (
	goto :admin_rights_ok
)

::----------------------------
:get_admin_rights

set "_TEMP=%USERPROFILE%"
set _PARAM = %*:"=""
(
	echo Set UAC = CreateObject^("Shell.Application"^)
	echo UAC.ShellExecute "cmd.exe", "/c ""%~S0"" %_PARAM%", "", "runas", 1

) > "%_TEMP%\getadmin.vbs"

wscript /NOLOGO "%_TEMP%\getadmin.vbs"
del /F "%_TEMP%\getadmin.vbs" >nul 2>&1
exit /B

::----------------------------
:admin_rights_ok

::##########################################################
:INIT_VAR
::##########################################################

set __FILE_SIZE.1=1
set __FILE_SIZE.10=10
set __FILE_SIZE.100=100
set __PORT.80=80
set __PORT.443=443
set __PORT.8080=8080

::##########################################################
:MAIN
::##########################################################
cls
for /F "delims=: tokens=*" %%T in ('findstr /B ::: "%~f0"') do (echo %%T)
echo.
echo         #################      Script Version !_VER!      ################
echo         #################   SUPPORT : 05 46 66 06 61   ################
echo.

echo  Gestion de "BITS" : Service de Telechargement Intelligent en Arriere-plan
echo.
echo   [1] Tester un telechargement depuis bouygues.testdebit.info ^(Defaut^)
echo   [2] Telecharger un fichier en saisissant son URL
echo   [3] Reinitialiser le service "BITS"
echo.
echo   [Q] Quitter le script
echo.

set /p _BITS_MENU="> Votre choix ? "
if not defined _BITS_MENU set _BITS_MENU=1

if /I !_BITS_MENU! EQU Q exit /B 0

if /I !_BITS_MENU! EQU 1 goto :BOUYGUES_TESTDEBIT

if /I !_BITS_MENU! EQU 2 goto :INPUT_URL

if /I !_BITS_MENU! EQU 3 (
	call :RepairBitsAdmin
	echo.&pause
)

goto :MAIN

::##########################################################
:BOUYGUES_TESTDEBIT
::##########################################################

set _FILE_SIZE=
set _PORT=
set _USERNAME=
set _PASSWORD=

echo.&set /P _FILE_SIZE="> Veuillez saisir la TAILLE du fichier a telecharger (Mo) : 1 (defaut), 10, 100 ? "
if not defined __FILE_SIZE.%_FILE_SIZE% set _FILE_SIZE=!__FILE_SIZE.1!
echo   La TAILLE retenue est : !_FILE_SIZE! Mo

set "_FILE_NAME=!_FILE_SIZE!M.zip"

::=========================================================

echo.&set /P _PORT="> Veuillez saisir le PORT : 80 (defaut), 443, 8080 ? "
if not defined __PORT.%_PORT% set _PORT=80
echo   Le PORT retenu est : !_PORT!

if !_PORT! EQU 443 (
	set _URL_DOWNLOAD=https://ipv4.bouygues.testdebit.info/!_FILE_SIZE!M/!_FILE_NAME!
) else (
	if !_PORT! EQU 8080 (
		set _URL_DOWNLOAD=https://ipv4.bouygues.testdebit.info:8080/!_FILE_SIZE!M/!_FILE_NAME!
	) else (
		set _URL_DOWNLOAD=http://ipv4.bouygues.testdebit.info/!_FILE_SIZE!M/!_FILE_NAME!
	)
)

goto :next_settings

::##########################################################
:INPUT_URL
::##########################################################

echo.&set /p _URL_DOWNLOAD="> Veuillez saisir l'URL du fichier a telecharger ? "
if not defined _URL_DOWNLOAD (
	goto :INPUT_URL
) else (
	set /p _FILE_NAME="> Veuillez saisir le NOM LOCAL du fichier a telecharger ? "
	if not defined _FILE_NAME set _FILE_NAME=TEST
)
echo   L'URL retenu est : !_URL_DOWNLOAD!
echo   Le NOM LOCAL du fichier retenu est : !_FILE_NAME!

::=========================================================

echo.&set /P _USERNAME="> Veuillez saisir un NOM D'UTILISATEUR pour la connexion : si aucun, appuyez sur [Entree] ? "
if not defined _USERNAME (
	echo  AUTHENTIFICATION retenue : AUCUNE
	goto :next_settings
)
::--------------
:input_password
::--------------
set /P _PASSWORD="> Veuillez saisir le MOT DE PASSE pour !_USERNAME! ? "
if not defined _PASSWORD goto :input_password

echo   AUTHENTIFICATION retenue : !_USERNAME! / !_PASSWORD!

::##########################################################
:next_settings
::##########################################################

echo.&set /P _TIMED_OUT="> Veuillez saisir le delai depasse en secondes (TIMED OUT), defaut = 15 ? "
if not defined _TIMED_OUT set /A _TIMED_OUT=15
echo   Le delai retenu pour TIMED OUT est : !_TIMED_OUT! s

::=========================================================

if not exist "!_DOWNLOAD_DIR!" md "!_DOWNLOAD_DIR!" >nul 2>&1
if exist "!_DOWNLOAD_DIR!\!_FILE_NAME!" del /F "!_DOWNLOAD_DIR!\!_FILE_NAME!" >nul 2>&1

::##########################################################
:DOWNLOAD_FILE_FROM_URL
::##########################################################

call :BITS-DOWNLOAD "!_JOB_NAME!" "!_URL_DOWNLOAD!" "!_DOWNLOAD_DIR!\!_FILE_NAME!" "!_TIMED_OUT!" "!_USERNAME!" "!_PASSWORD!"

if %ERRORLEVEL% EQU 0 (
	echo.&set /P _KEEP_FILE="> Voulez-vous conserver le fichier telecharge : !_DOWNLOAD_DIR!\!_FILE_NAME!, [O]ui / [N]on ? "
	if /I !_KEEP_FILE! NEQ O (
		del /F "!_DOWNLOAD_DIR!\!_FILE_NAME!" >nul 2>&1
	)
)
echo.
pause>nul|set /P "_DUMMY=> APPUYER SUR UNE TOUCHE POUR CONTINUER"
goto :MAIN

::##########################################################
:BITS-DOWNLOAD
::##########################################################
set FN_JOB_NAME=%~1
set FN_URL_DOWNLOAD=%~2
set FN_LOCAL_FILE=%~3
set FN_TIMED_OUT=%~4
set FN_USERNAME=%~5
set FN_PASSWORD=%~6

set FN_FREQUENCY=2 && rem frequence d'affichage des octets telecharges

echo.&echo  Telechargement de !FN_URL_DOWNLOAD!
echo  Veuillez patienter ...

bitsadmin /CANCEL "!FN_JOB_NAME!" >nul
bitsadmin /CREATE /DOWNLOAD "!FN_JOB_NAME!" >nul
bitsadmin /ADDFILE "!FN_JOB_NAME!" "!FN_URL_DOWNLOAD!" "!FN_LOCAL_FILE!" >nul
bitsadmin /SETNOPROGRESSTIMEOUT "!FN_JOB_NAME!" !FN_TIMED_OUT! >nul
bitsadmin /SETMINRETRYDELAY "!FN_JOB_NAME!" 5 >nul

if defined FN_USERNAME (
	bitsadmin /SETCREDENTIALS "!FN_JOB_NAME!" SERVER BASIC "!FN_USERNAME!" "!FN_PASSWORD!" >nul
)
bitsadmin /SETPROXYSETTINGS "!FN_JOB_NAME!" AUTODETECT >nul
bitsadmin /RESUME "!FN_JOB_NAME!" >nul

set FN_BYTES_TRANSFERRED=0
echo.
echo | set /p "_DUMMY=> Octet^(s^) transfere^(s^) : !FN_BYTES_TRANSFERRED! "

::---------------
:ProgressDL
::---------------

call :DisplayBytesTransferred

bitsadmin /INFO "!FN_JOB_NAME!" /VERBOSE | find "STATE: ERROR" >nul 2>&1 && goto :ManageErrorDL
bitsadmin /INFO "!FN_JOB_NAME!" /VERBOSE | find "STATE: TRANSIENT_ERROR" >nul 2>&1 &&  goto :ManageErrorDL
bitsadmin /INFO "!FN_JOB_NAME!" /VERBOSE | find "STATE: TRANSFERRED" >nul 2>&1 && goto :ManageSuccessDL

ping -n !FN_FREQUENCY! 127.0.0.1 >nul 2>&1

goto :ProgressDL

:ManageSuccessDL

call :DisplayBytesTransferred

echo.&echo.
echo  Telechargement effectue avec SUCCES
echo.
for /F "delims=" %%I in ('bitsadmin /GETCREATIONTIME "!FN_JOB_NAME!" ^| find ":"') do (echo  Debut du transfert : %%I)
for /F "delims=" %%I in ('bitsadmin /GETCOMPLETIONTIME "!FN_JOB_NAME!" ^| find ":"') do (echo  Fin du transfert   : %%I)

bitsadmin /COMPLETE "!FN_JOB_NAME!" >nul 2>&1

exit /B 0

:ManageErrorDL

echo.&echo.
for /F "tokens=2 delims=-" %%I in ('bitsadmin /GETERROR "!FN_JOB_NAME!" ^| find "ERROR CODE:"') do (
	echo  Telechargement echoue -%%I
)
bitsadmin /CANCEL "!FN_JOB_NAME!" >nul 2>&1

exit /B 1

:DisplayBytesTransferred

for /F %%I in ('bitsadmin /GETBYTESTRANSFERRED "!FN_JOB_NAME!" ^| find /V "BITS" ^| findstr /R "[0-9]"') do (
	if %%I GTR !FN_BYTES_TRANSFERRED! (
		set FN_BYTES_TRANSFERRED=%%I
		echo | set /p "_DUMMY=!FN_BYTES_TRANSFERRED! "
	)
)

exit /B 0

::##########################################################
:RepairBitsAdmin
::##########################################################

echo.
echo  ============= DEBUT DE LA REINITIALISATION DU SERVICE BITS =============
echo.
Sc config bits binpath="%SYSTEMROOT%\\system32\\svchost.exe –k netsvcs"
Sc config bits depend = RpcSs EventSystem
Sc config bits start=delayed-auto
Sc config bits type=interact
Sc config bits error=normal
Sc config bits obj=LocalSystem
Sc privs bits privileges=SeCreateGlobalPrivilege/SeImpersonatePrivilege/SeTcbPrivilege/SeAssignPrimaryTokenPrivilege/SeIncreateQuotaPrivilege
Sc sidtype bits type= unrestricted Sc failure bits reset= 86400 actions=restart/60000/restart/120000
sc stop bits
sc start bits
echo.
echo  ============== FIN DE LA REINITIALISATION DU SERVICE BITS ==============
echo.

exit /B 0