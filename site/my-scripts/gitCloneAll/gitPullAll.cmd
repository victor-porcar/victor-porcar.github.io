@echo off
setlocal enabledelayedexpansion

if "%~1"=="" (
    echo Usage: gitPullAll.cmd ^<USER_NAME^> ^<LOCAL_DIRECTORY^> ^<AUTHENTICATION_GITHUB_TOKEN^>
    echo Example: gitPullAll.cmd victor-porcar "C:\path\to\my_repository" ghp_MpcYKKKdlqFQirdH15JcH3hwia45B4265DzQ
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

cd "!dir!" || exit /b

for /f "tokens=*" %%A in ('curl -s "https://api.github.com/user/repos" --header "Authorization: Bearer !GITHUB_TOKEN!"') do (
    set "line=%%A"
    echo !line! | findstr /C:\^"full_name\^": >nul
    if !errorlevel! == 0 (

		for /f "tokens=2 delims=//" %%a in (' echo !line!') do (
			set "repositoryName=%%a"
		)
		
        set "repositoryNameFiltered=!repositoryName:~0,-2!"  REM Extract URL from line

	    echo "Pull from repo: !repositoryNameFiltered!" 
		cd "./!repositoryNameFiltered!" || exit /b
		git pull
		cd ..
    )
)

exit /b 0