# See https://aka.ms/customizecontainer to learn how to customize your debug container and how Visual Studio uses this Dockerfile to build your images for faster debugging.

# Depending on the operating system of the host machines(s) that will build or run the containers, the image specified in the FROM statement may need to be changed.
# For more information, please see https://aka.ms/containercompat

# This stage is used when running from VS in fast mode (Default for Debug configuration)
FROM mcr.microsoft.com/dotnet/aspnet:8.0-windowsservercore-ltsc2025 AS base
WORKDIR /app

# This stage is used to build the service project
FROM mcr.microsoft.com/dotnet/sdk:8.0-windowsservercore-ltsc2025 AS build
ARG BUILD_CONFIGURATION=Release
WORKDIR /src
COPY ["Sandbox111/Sandbox111.csproj", "Sandbox111/"]
COPY ["RestUserAuthLocationServiceV2/RestUserAuthLocationServiceV2.csproj", "RestUserAuthLocationServiceV2/"]
COPY dirs.proj .
COPY global.json .
COPY Directory.Build.props .
RUN dotnet restore "./dirs.proj"
COPY . .
RUN dotnet build "./dirs.proj" -c %BUILD_CONFIGURATION%

# This stage is used to publish the service project to be copied to the final stage
FROM build AS publish
ARG BUILD_CONFIGURATION=Release
#RUN dotnet publish "./dirs.proj" -c %BUILD_CONFIGURATION% /p:UseAppHost=false
RUN dotnet publish "./dirs.proj" -c %BUILD_CONFIGURATION%

# This stage is used in production or when running from VS in regular mode (Default when not using the Debug configuration)
FROM base AS final
WORKDIR /app
COPY --from=publish /src/artifacts/publish .
ARG BUILD_CONFIGURATION=Release
ENV BUILD_CONFIGURATION=${BUILD_CONFIGURATION}
ENTRYPOINT ["dotnet", "Sandbox111/out/Sandbox111.dll"]