@ECHO OFF
setlocal enabledelayedexpansion

set CONTAINER_NAME=entrypoint

REM Check if the container exists (running or stopped)
docker ps -a --filter "name=%CONTAINER_NAME%" --format "{{.ID}}" > NUL 2>&1
if %errorlevel% equ 0 (
    for /f "delims=" %%i in ('docker ps -a --filter "name=%CONTAINER_NAME%" --format "{{.ID}}"') do (
        if not "%%i" == "" (
            echo Container "%CONTAINER_NAME%" exists.
            echo Stopping docker container.
            docker stop "%CONTAINER_NAME%"
            echo Removing docker container.
            docker rm "%CONTAINER_NAME%"
        )
    )
) else (
    echo Container "%CONTAINER_NAME%" does NOT exist.
)

echo Running docker container.
docker run -d -p 5000:8080 --name "%CONTAINER_NAME%" "%CONTAINER_NAME%:dev"