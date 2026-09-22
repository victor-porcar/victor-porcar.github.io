@echo off
setlocal

REM Generates the IT bookmarks page of this site from the current Chrome bookmarks, using Bookmark2html
REM Asks for confirmation first and, once generated, whether to commit and push the page
REM It waits for a key at the very end, so the result can be read
REM Works from any directory: Bookmark2html is located through GITHUB_VICTOR_PORCAR

REM Bookmark folder to export
set "FOLDER=IT"

REM Candidate Chrome bookmarks files separated by ";": the first one that exists is used.
REM Recent Chrome versions keep the account bookmarks in AccountBookmarks, older ones in Bookmarks
set "CHROME_PROFILE=%LOCALAPPDATA%\Google\Chrome\User Data\Profile 4"
set "BOOKMARKS_FILE=%CHROME_PROFILE%\AccountBookmarks;%CHROME_PROFILE%\Bookmarks"

REM This repository (the "." avoids a trailing backslash before a closing quote) and the
REM generated page inside it
set "REPO_DIR=%~dp0."
set "OUTPUT_NAME=bookmarks%FOLDER%.html"
set "OUTPUT_IN_REPO=site/my-it-bookmarks/%OUTPUT_NAME%"
set "OUTPUT_FILE=%~dp0site\my-it-bookmarks\%OUTPUT_NAME%"

REM Message of the commit made when the page is pushed
set "COMMIT_MESSAGE=Update IT bookmarks"

REM No backup of the Chrome bookmarks file: 0 backups to keep makes Bookmark2html ignore the directory
set "BACKUP_DIR=C:\TEMP"
set "BACKUPS_TO_KEEP=0"

REM Every exit goes through :finish, so the final key press is asked for errors too
set "EXIT_CODE=1"

if not defined GITHUB_VICTOR_PORCAR (
    echo X  The GITHUB_VICTOR_PORCAR environment variable is not defined
    goto finish
)

set "BOOKMARK2HTML_JAR=%GITHUB_VICTOR_PORCAR%\bookmark2html\dist\bookmark2html.jar"

if not exist "%BOOKMARK2HTML_JAR%" (
    echo X  bookmark2html.jar not found at: %BOOKMARK2HTML_JAR%
    echo    Pull it with "git pull" or build it with "mvn clean package" in %GITHUB_VICTOR_PORCAR%\bookmark2html
    goto finish
)

set "ANSWER="
set /p "ANSWER=Are you sure to generate IT bookmarks with the current Chrome Bookmarks [Yy]? "
if /i not "%ANSWER%"=="y" (
    echo Aborted: nothing was generated
    set "EXIT_CODE=0"
    goto finish
)

java -jar "%BOOKMARK2HTML_JAR%" "%BOOKMARKS_FILE%" "%OUTPUT_FILE%" "%FOLDER%" "%BACKUP_DIR%" "%BACKUPS_TO_KEEP%"
set "EXIT_CODE=%ERRORLEVEL%"
if not "%EXIT_CODE%"=="0" goto finish

echo.
set "ANSWER="
set /p "ANSWER=Do you want to commit and push the generated bookmark file [Yy]? "
if /i not "%ANSWER%"=="y" (
    echo Not committed: the generated file is only in the working copy
    goto finish
)
call :commit_and_push
set "EXIT_CODE=%ERRORLEVEL%"

:finish
echo.
echo Press any key to finish...
pause >nul
exit /b %EXIT_CODE%

REM Commits only the generated page (nothing else that may be modified in the repository)
REM and pushes it, after bringing the latest changes; returns 0 when done or nothing to do
:commit_and_push
where git >nul 2>&1 || (
    echo X  git not found
    exit /b 1
)
set "CHANGED="
for /f "delims=" %%L in ('git -C "%REPO_DIR%" status --porcelain -- "%OUTPUT_IN_REPO%"') do set "CHANGED=1"
if not defined CHANGED (
    echo The generated file is the same as the committed one: nothing to commit
    exit /b 0
)
git -C "%REPO_DIR%" pull --ff-only || (
    echo X  git pull failed: resolve it by hand, the generated file is left uncommitted
    exit /b 1
)
git -C "%REPO_DIR%" add -- "%OUTPUT_IN_REPO%" || exit /b 1
git -C "%REPO_DIR%" commit -m "%COMMIT_MESSAGE%" -- "%OUTPUT_IN_REPO%" || exit /b 1
git -C "%REPO_DIR%" push || (
    echo X  git push failed: the commit is done locally, push it by hand
    exit /b 1
)
echo OK Generated bookmark file committed and pushed
exit /b 0
