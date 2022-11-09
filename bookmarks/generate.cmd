@echo off

set "THIS_FOLDER=%~dp0"

:: ======================================================

set "BOOKMARK2MD_HOME=D:\VICTOR-MASTER\FSD\MY_PROJECTS\GitHub\Bookmark2md"
set "BOOKMARK_EXPORTED_FROM_BROWSER_DIRECTORY=D:\VICTOR-MASTER\Bookmarks\RawBookmarks"
set "BOOKMARK_FOLDER_NAME=IT"

:: ======================================================

:: CALCULATE PARAMETERS FOR bookmark2md


set "GENERATED_FOLDER=%THIS_FOLDER%generated"
set "MARKDOWN_FILE_NAME=generated_MD_%BOOKMARK_FOLDER_NAME%.md"
set "HTML_PRETTY_FILE_NAME=generated_PRETTY_HTML_%BOOKMARK_FOLDER_NAME%.html"
set "RAW_IMPORTABLE_HTML_FILE=bookmarks%BOOKMARK_FOLDER_NAME%.html"

:: =========================================================================================


for /f %%i in ('dir %BOOKMARK_EXPORTED_FROM_BROWSER_DIRECTORY%  /b/a-d/od/t:c') do set LATEST_BOOKMARK_EXPORTED_FILE=%%i

set "LATEST_BOOKMARK_EXPORTED_FILE_COMPLETE_PATH=%BOOKMARK_EXPORTED_FROM_BROWSER_DIRECTORY%\%LATEST_BOOKMARK_EXPORTED_FILE%"

call %BOOKMARK2MD_HOME%\bookmark2md.cmd "%LATEST_BOOKMARK_EXPORTED_FILE_COMPLETE_PATH%"  "%GENERATED_FOLDER%" "%MARKDOWN_FILE_NAME%"  "%HTML_PRETTY_FILE_NAME%"   "%RAW_IMPORTABLE_HTML_FILE%" "%BOOKMARK_FOLDER_NAME%"