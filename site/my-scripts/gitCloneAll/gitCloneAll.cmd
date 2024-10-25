@echo off
setlocal enabledelayedexpansion

if "%~1"=="" (
    echo Usage: gitCloneAll.bat ^<USER_NAME^> ^<LOCAL_DIRECTORY^> ^<AUTHENTICATION_GITHUB_TOKEN^>
    echo Example: gitCloneAll.bat victor-porcar "C:\path\to\my_repository" ghp_MpcYKKKdlqFQirdH15JcH3hwia45B4265DzQ
    exit /b 1
)

set "name=%~1"
set "dir=%~2"
set "GITHUB_TOKEN=%~3"

if not exist "!dir!" (
    mkdir "!dir!"
) else (
    if not exist "!dir!\*" (
        echo !dir! already exists but is not a directory 1>&2
        exit /b -1
    )
)

cd "!dir!" || exit

echo Working directory: %cd%

for /f "tokens=*" %%A in ('curl -s "https://api.github.com/user/repos" --header "Authorization: Bearer !GITHUB_TOKEN!"') do (
    set "line=%%A"
    echo !line! | findstr /C:"clone_url" >nul
    if !errorlevel! == 0 (
        set "url=!line:~22,-2!"  REM Extract URL from line
        set "url=https://!GITHUB_TOKEN!@!url!"
        git clone "!url!"
    )
)

exit /b 0