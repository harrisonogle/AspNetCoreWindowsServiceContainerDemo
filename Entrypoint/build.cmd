@ECHO OFF
setlocal enabledelayedexpansion

PUSHD "%~dp0"
cd ..

docker.exe build ^
    -f ".\Entrypoint\Dockerfile" ^
    --force-rm ^
    -t entrypoint:dev ^
    --build-arg "BUILD_CONFIGURATION=Debug" ^
    .

POPD