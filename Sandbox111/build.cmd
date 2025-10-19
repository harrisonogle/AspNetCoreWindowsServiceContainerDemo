@ECHO OFF
setlocal enabledelayedexpansion

PUSHD "%~dp0"
cd ..

docker.exe build ^
    -f ".\Sandbox111\Dockerfile" ^
    --force-rm ^
    -t sandbox111:dev ^
    --build-arg "BUILD_CONFIGURATION=Debug" ^
    .

POPD