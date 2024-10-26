@echo off
setlocal enabledelayedexpansion

if "%~1"=="" (
    echo Usage: gitCloneOrPullAll.cmd ^<USER_NAME^> ^<LOCAL_DIRECTORY^> ^<AUTHENTICATION_GITHUB_TOKEN^>
    echo Example: gitCloneOrPullAll.cmd victor-porcar "C:\path\to\my_repository" ghp_MpcYKKKdlqFQirdH15JcH3hwia45B4265DzQ
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

cd /d "!dir!" || exit /b

for /f "tokens=*" %%A in ('curl -s "https://api.github.com/user/repos" --header "Authorization: Bearer !GITHUB_TOKEN!"') do (
    set "line=%%A"
    echo !line! | findstr /C:\^"full_name\^": >nul
    if !errorlevel! == 0 (

		for /f "tokens=2 delims=//" %%a in (' echo !line!') do (
			set "repositoryNameUnfiltered=%%a"
			set "repositoryName=!repositoryNameUnfiltered:~0,-2!"  REM Extract URL from line
		)
 
		set "expectedLocalDirectory=./!repositoryName!"  

		if not exist "!expectedLocalDirectory!" (
			echo "Current Directory is !dir! and the following directory !expectedLocalDirectory! does not exist, which means a clone has to be done" 
			set "url=https://!GITHUB_TOKEN!@github.com/!name!/!repositoryName!"
			git clone "!url!"
		) else (
			echo "Current Directory is !dir! and the following directory !expectedLocalDirectory! does not exist, which means a pull has to be done" 
			cd "./!repositoryName!" || exit /b
		    git pull
		    cd ..
		)
    )
)

rem exit /b 0