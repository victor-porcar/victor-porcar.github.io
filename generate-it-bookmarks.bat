@echo off
setlocal

REM Generates the IT bookmarks page of this site from the current Chrome bookmarks, using Bookmark2html
REM Asks for confirmation first; it waits for a key at the very end, so the result can be read
REM Works from any directory: Bookmark2html is located through GITHUB-VICTOR-PORCAR

REM Bookmark folder to export
set "FOLDER=IT"

REM Candidate Chrome bookmarks files separated by ";": the first one that exists is used.
REM Recent Chrome versions keep the account bookmarks in AccountBookmarks, older ones in Bookmarks
set "CHROME_PROFILE=%LOCALAPPDATA%\Google\Chrome\User Data\Profile 4"
set "BOOKMARKS_FILE=%CHROME_PROFILE%\AccountBookmarks;%CHROME_PROFILE%\Bookmarks"

REM Generated page, inside this repository
set "OUTPUT_FILE=%~dp0site\my-it-bookmarks\index.html"

REM No backup of the Chrome bookmarks file: 0 backups to keep makes Bookmark2html ignore the directory
set "BACKUP_DIR=C:\TEMP"
set "BACKUPS_TO_KEEP=0"

REM Every exit goes through :finish, so the final key press is asked for errors too
set "EXIT_CODE=1"

if not defined GITHUB-VICTOR-PORCAR (
    echo X  The GITHUB-VICTOR-PORCAR environment variable is not defined
    goto finish
)

set "BOOKMARK2HTML_JAR=%GITHUB-VICTOR-PORCAR%\Bookmark2html\target\bookmark2html.jar"

if not exist "%BOOKMARK2HTML_JAR%" (
    echo X  bookmark2html.jar not found at: %BOOKMARK2HTML_JAR%
    echo    Build it with "mvn clean package" in %GITHUB-VICTOR-PORCAR%\Bookmark2html
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

:finish
echo.
echo Press any key to finish...
pause >nul
exit /b %EXIT_CODE%
