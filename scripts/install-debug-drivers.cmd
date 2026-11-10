@echo off
setlocal
set "LIBERNT_DRIVER_DIR=%SystemRoot%\System32\drivers"
set "LIBERNT_PAYLOAD=%SystemRoot%\Temp"
set "LIBERNT_NDIS_TEST_LOG=ndis-reset-unit.txt"
if /I "%~1"=="install-wifi" goto install_wifi
if /I "%~1"=="rollback-wifi" goto rollback_wifi
if /I "%~1"=="install-tray" goto install_tray
if /I "%~1"=="rollback-tray" goto rollback_tray
if /I "%~1"=="install-oid" goto install_oid
if /I "%~1"=="rollback-oid" goto rollback_oid
if /I "%~1"=="install-reset" goto install_reset
if /I "%~1"=="rollback-reset" goto rollback_reset
echo        install-debug-drivers.cmd install-wifi
echo        install-debug-drivers.cmd rollback-wifi [installed Windows directory]
echo        install-debug-drivers.cmd install-tray
echo        install-debug-drivers.cmd rollback-tray [installed Windows directory]
echo        install-debug-drivers.cmd install-oid
echo        install-debug-drivers.cmd rollback-oid [installed Windows directory]
echo        install-debug-drivers.cmd install-reset
echo        install-debug-drivers.cmd rollback-reset [installed Windows directory]
exit /b 2

:install_tray
if /I not "%PROCESSOR_ARCHITECTURE%"=="AMD64" goto wrong_target
if not exist "%SystemRoot%\System32\lntdrv.exe" goto wrong_target
if not exist "%LIBERNT_PAYLOAD%\explorer.exe" goto missing_payload
if not exist "%LIBERNT_PAYLOAD%\stobject.dll" goto missing_payload
if not exist "%LIBERNT_PAYLOAD%\tray_lifetime.exe" goto missing_payload
if exist "%SystemRoot%\explorer.exe.libernt-tray-backup" goto existing_backup
if exist "%SystemRoot%\explorer.exe.libernt-tray-rejected" goto existing_backup
if exist "%SystemRoot%\System32\stobject.dll.libernt-tray-backup" goto existing_backup
if exist "%SystemRoot%\System32\stobject.dll.libernt-tray-rejected" goto existing_backup
"%LIBERNT_PAYLOAD%\tray_lifetime.exe" > "%LIBERNT_PAYLOAD%\tray-lifetime-unit.txt" 2>&1
if errorlevel 1 goto failed_tray_test
ren "%SystemRoot%\explorer.exe" explorer.exe.libernt-tray-backup
if errorlevel 1 goto tray_install_failed
ren "%SystemRoot%\System32\stobject.dll" stobject.dll.libernt-tray-backup
if errorlevel 1 goto tray_rollback_partial
copy /Y "%LIBERNT_PAYLOAD%\explorer.exe" "%SystemRoot%\explorer.exe"
if errorlevel 1 goto tray_rollback_partial
"%SystemRoot%\System32\fc.exe" /b "%LIBERNT_PAYLOAD%\explorer.exe" "%SystemRoot%\explorer.exe" > nul
if errorlevel 1 goto tray_rollback_partial
copy /Y "%LIBERNT_PAYLOAD%\stobject.dll" "%SystemRoot%\System32\stobject.dll"
if errorlevel 1 goto tray_rollback_partial
"%SystemRoot%\System32\fc.exe" /b "%LIBERNT_PAYLOAD%\stobject.dll" "%SystemRoot%\System32\stobject.dll" > nul
if errorlevel 1 goto tray_rollback_partial
echo INSTALLED: AMD64 tray icon ownership and power polling fix.
echo Reboot to load both updated files. Keep the Ethernet debug cable connected.
echo Rollback: install-debug-drivers.cmd rollback-tray
exit /b 0

:rollback_tray
set "LIBERNT_TRAY_ROOT=%SystemRoot%"
if not "%~2"=="" set "LIBERNT_TRAY_ROOT=%~2"
call :restore_tray_file "%LIBERNT_TRAY_ROOT%" explorer.exe
if errorlevel 1 goto recovery_required
call :restore_tray_file "%LIBERNT_TRAY_ROOT%\System32" stobject.dll
if errorlevel 1 goto recovery_required
echo RESTORED: previous Explorer and stobject files. Reboot to load them.
exit /b 0

:tray_rollback_partial
call :restore_tray_file "%SystemRoot%" explorer.exe
if errorlevel 1 goto recovery_required
call :restore_tray_file "%SystemRoot%\System32" stobject.dll
if errorlevel 1 goto recovery_required
echo INSTALL FAILED: previous Explorer and stobject files restored.
exit /b 1

:restore_tray_file
if not exist "%~1\%~2.libernt-tray-backup" exit /b 0
if not exist "%~1\%~2" goto restore_tray_backup
if exist "%~1\%~2.libernt-tray-rejected" exit /b 1
ren "%~1\%~2" "%~2.libernt-tray-rejected"
if errorlevel 1 exit /b 1
:restore_tray_backup
ren "%~1\%~2.libernt-tray-backup" "%~2"
exit /b %ERRORLEVEL%

:failed_tray_test
echo ABORTED: tray source test failed. Read %LIBERNT_PAYLOAD%\tray-lifetime-unit.txt.
exit /b 1
:tray_install_failed
echo ABORTED: could not rename Explorer. No system file replaced.
exit /b 1

:install_oid
if /I not "%PROCESSOR_ARCHITECTURE%"=="AMD64" goto wrong_target
if not exist "%SystemRoot%\System32\lntdrv.exe" goto wrong_target
if not exist "%LIBERNT_PAYLOAD%\ndis.sys" goto missing_payload
if not exist "%LIBERNT_PAYLOAD%\ndis_oid.exe" goto missing_payload
if exist "%LIBERNT_DRIVER_DIR%\ndis.sys.libernt-oid-backup" goto existing_backup
if exist "%LIBERNT_DRIVER_DIR%\ndis.sys.libernt-oid-rejected" goto existing_backup
if not exist "%LIBERNT_PAYLOAD%\ndis_reset.exe" goto missing_payload
"%LIBERNT_PAYLOAD%\ndis_reset.exe" > "%LIBERNT_PAYLOAD%\ndis-reset-unit.txt" 2>&1
if errorlevel 1 goto failed_test
set "LIBERNT_NDIS_TEST_LOG=ndis-oid-unit.txt"
"%LIBERNT_PAYLOAD%\ndis_oid.exe" > "%LIBERNT_PAYLOAD%\ndis-oid-unit.txt" 2>&1
if errorlevel 1 goto failed_test
ren "%LIBERNT_DRIVER_DIR%\ndis.sys" ndis.sys.libernt-oid-backup
if errorlevel 1 goto install_failed
copy /Y "%LIBERNT_PAYLOAD%\ndis.sys" "%LIBERNT_DRIVER_DIR%\ndis.sys"
if errorlevel 1 goto oid_rollback_partial
"%SystemRoot%\System32\fc.exe" /b "%LIBERNT_PAYLOAD%\ndis.sys" "%LIBERNT_DRIVER_DIR%\ndis.sys" > nul
if errorlevel 1 goto oid_rollback_partial
echo INSTALLED: AMD64 NDIS ordinary OID serialization fix.
echo Reboot to load the new driver. Keep the Ethernet debug cable connected.
echo Rollback: install-debug-drivers.cmd rollback-oid
exit /b 0

:rollback_oid
if not "%~2"=="" set "LIBERNT_DRIVER_DIR=%~2\System32\drivers"
call :restore_oid
if errorlevel 1 goto recovery_required
echo RESTORED: previous NDIS driver backup. Reboot to load it.
exit /b 0

:oid_rollback_partial
call :restore_oid
if errorlevel 1 goto recovery_required
echo INSTALL FAILED: previous NDIS driver restored.
exit /b 1

:restore_oid
if not exist "%LIBERNT_DRIVER_DIR%\ndis.sys.libernt-oid-backup" exit /b 0
if not exist "%LIBERNT_DRIVER_DIR%\ndis.sys" goto restore_oid_backup
if exist "%LIBERNT_DRIVER_DIR%\ndis.sys.libernt-oid-rejected" exit /b 1
ren "%LIBERNT_DRIVER_DIR%\ndis.sys" ndis.sys.libernt-oid-rejected
if errorlevel 1 exit /b 1
:restore_oid_backup
ren "%LIBERNT_DRIVER_DIR%\ndis.sys.libernt-oid-backup" ndis.sys
exit /b %ERRORLEVEL%

:install_reset
if /I not "%PROCESSOR_ARCHITECTURE%"=="AMD64" goto wrong_target
if not exist "%SystemRoot%\System32\lntdrv.exe" goto wrong_target
if not exist "%LIBERNT_PAYLOAD%\ndis.sys" goto missing_payload
if not exist "%LIBERNT_PAYLOAD%\ndis_reset.exe" goto missing_payload
if exist "%LIBERNT_DRIVER_DIR%\ndis.sys.libernt-reset-backup" goto existing_backup
if exist "%LIBERNT_DRIVER_DIR%\ndis.sys.libernt-reset-rejected" goto existing_backup
"%LIBERNT_PAYLOAD%\ndis_reset.exe" > "%LIBERNT_PAYLOAD%\ndis-reset-unit.txt" 2>&1
if errorlevel 1 goto failed_test
ren "%LIBERNT_DRIVER_DIR%\ndis.sys" ndis.sys.libernt-reset-backup
if errorlevel 1 goto install_failed
copy /Y "%LIBERNT_PAYLOAD%\ndis.sys" "%LIBERNT_DRIVER_DIR%\ndis.sys"
if errorlevel 1 goto reset_rollback_partial
"%SystemRoot%\System32\fc.exe" /b "%LIBERNT_PAYLOAD%\ndis.sys" "%LIBERNT_DRIVER_DIR%\ndis.sys" > nul
if errorlevel 1 goto reset_rollback_partial
echo INSTALLED: AMD64 NDIS reset completion fix.
echo Reboot to load the new driver. Keep the Ethernet debug cable connected.
echo Rollback: install-debug-drivers.cmd rollback-reset
exit /b 0

:rollback_reset
if not "%~2"=="" set "LIBERNT_DRIVER_DIR=%~2\System32\drivers"
call :restore_reset
if errorlevel 1 goto recovery_required
echo RESTORED: previous NDIS driver backup. Reboot to load it.
exit /b 0

:reset_rollback_partial
call :restore_reset
if errorlevel 1 goto recovery_required
echo INSTALL FAILED: previous NDIS driver restored.
exit /b 1

:restore_reset
if not exist "%LIBERNT_DRIVER_DIR%\ndis.sys.libernt-reset-backup" exit /b 0
if not exist "%LIBERNT_DRIVER_DIR%\ndis.sys" goto restore_reset_backup
if exist "%LIBERNT_DRIVER_DIR%\ndis.sys.libernt-reset-rejected" exit /b 1
ren "%LIBERNT_DRIVER_DIR%\ndis.sys" ndis.sys.libernt-reset-rejected
if errorlevel 1 exit /b 1
:restore_reset_backup
ren "%LIBERNT_DRIVER_DIR%\ndis.sys.libernt-reset-backup" ndis.sys
exit /b %ERRORLEVEL%

:install_wifi
if /I not "%PROCESSOR_ARCHITECTURE%"=="AMD64" goto wrong_target
if not exist "%SystemRoot%\System32\lntdrv.exe" goto wrong_target
if not exist "%LIBERNT_PAYLOAD%\nwifi.sys" goto missing_payload
if not exist "%LIBERNT_PAYLOAD%\nwifi_rekey.exe" goto missing_payload
if exist "%LIBERNT_DRIVER_DIR%\nwifi.sys.libernt-backup" goto existing_backup
if exist "%LIBERNT_DRIVER_DIR%\nwifi.sys.libernt-rejected" goto existing_backup
"%LIBERNT_PAYLOAD%\nwifi_rekey.exe" > "%LIBERNT_PAYLOAD%\nwifi-rekey-unit.txt" 2>&1
if errorlevel 1 goto failed_wifi_test
ren "%LIBERNT_DRIVER_DIR%\nwifi.sys" nwifi.sys.libernt-backup
if errorlevel 1 goto wifi_install_failed
copy /Y "%LIBERNT_PAYLOAD%\nwifi.sys" "%LIBERNT_DRIVER_DIR%\nwifi.sys"
if errorlevel 1 goto wifi_rollback_partial
echo INSTALLED: AMD64 Wi-Fi association key-state fix.
echo Reboot to load the new driver. Keep the Ethernet debug cable connected.
echo Rollback: install-debug-drivers.cmd rollback-wifi
exit /b 0

:rollback_wifi
if not "%~2"=="" set "LIBERNT_DRIVER_DIR=%~2\System32\drivers"
call :restore_one nwifi.sys
if errorlevel 1 goto recovery_required
echo RESTORED: available original Wi-Fi driver backup. Reboot to load it.
exit /b 0

:wifi_rollback_partial
call :restore_one nwifi.sys
if errorlevel 1 goto recovery_required
echo INSTALL FAILED: original Wi-Fi driver restored.
exit /b 1

:failed_wifi_test
echo ABORTED: Wi-Fi unit test failed. Read %LIBERNT_PAYLOAD%\nwifi-rekey-unit.txt.
exit /b 1
:wifi_install_failed
echo ABORTED: could not rename the installed Wi-Fi driver. No driver replaced.
exit /b 1

:restore_one
if not exist "%LIBERNT_DRIVER_DIR%\%~1.libernt-backup" exit /b 0
if not exist "%LIBERNT_DRIVER_DIR%\%~1" goto restore_backup
if exist "%LIBERNT_DRIVER_DIR%\%~1.libernt-rejected" exit /b 1
ren "%LIBERNT_DRIVER_DIR%\%~1" "%~1.libernt-rejected"
if errorlevel 1 exit /b 1
:restore_backup
ren "%LIBERNT_DRIVER_DIR%\%~1.libernt-backup" "%~1"
exit /b %ERRORLEVEL%

:wrong_target
echo ABORTED: run install only on the AMD64 LiberNT test installation.
exit /b 1
:missing_payload
echo ABORTED: payload files are missing from %LIBERNT_PAYLOAD%.
exit /b 1
:existing_backup
echo ABORTED: existing backup or rejected driver files were preserved.
echo Complete the previous rollback before staging another attempt.
exit /b 1
:failed_test
echo ABORTED: NDIS unit test failed. Read %LIBERNT_PAYLOAD%\%LIBERNT_NDIS_TEST_LOG%.
exit /b 1
:install_failed
echo ABORTED: could not rename the installed NDIS driver. No driver replaced.
exit /b 1
:recovery_required
echo RECOVERY REQUIRED: a driver could not be restored in %LIBERNT_DRIVER_DIR%.
echo Keep the driver backup files and restore them before rebooting.
exit /b 1
