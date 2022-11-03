@echo off

:: please set this variable properly for your environment

set "BOOKMARK2MD_HOME=D:\VICTOR-MASTER\FSD\MY_PROJECTS\GitHub\Bookmark2md"
set "BOOKMARK_EXPORTED_FROM_BROWSER_DIRECTORY=D:\VICTOR-MASTER\Bookmarks"

:: ======================================================


set "PARENT_PATH=%~dp0"
set "BOOKMARK_FOLDER_NAME=IT"
set "GENERATED_FOLDER=%PARENT_PATH%generated"
set "MARKDOWN_FILE_NAME=generated_MD_FSD.md"
set "HTML_PRETTY_FILE_NAME=generated_HTML_FSD.html"
set "RAW_IMPORTABLE_HTML_FILE=bookmarksFSD.html"

:: ======================================================


for /f %%i in ('dir %BOOKMARK_EXPORTED_FROM_BROWSER_DIRECTORY%  /b/a-d/od/t:c') do set LATEST_BOOKMARK_EXPORTED_FILE=%%i

set "LATEST_BOOKMARK_EXPORTED_FILE_COMPLETE_PATH=%BOOKMARK_EXPORTED_FROM_BROWSER_DIRECTORY%\%LATEST_BOOKMARK_EXPORTED_FILE%"

call %BOOKMARK2MD_HOME%\bookmark2md.cmd "%LATEST_BOOKMARK_EXPORTED_FILE_COMPLETE_PATH%" "%BOOKMARK_FOLDER_NAME%" "%GENERATED_FOLDER%" "%MARKDOWN_FILE_NAME%"  "%HTML_PRETTY_FILE_NAME%"   "%RAW_IMPORTABLE_HTML_FILE%"
