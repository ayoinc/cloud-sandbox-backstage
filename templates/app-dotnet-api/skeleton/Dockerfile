FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

COPY global.json Directory.Build.props Directory.Packages.props ./
COPY src/Api/Api.csproj src/Api/
RUN dotnet restore src/Api/Api.csproj

COPY src/Api/ src/Api/
RUN dotnet publish src/Api/Api.csproj --configuration Release --no-restore --output /app

# Chiseled Ubuntu: no shell, no package manager, non-root by default. Health
# is checked by the orchestrator's HTTP probes.
FROM mcr.microsoft.com/dotnet/aspnet:10.0-noble-chiseled AS production
WORKDIR /app

ENV ASPNETCORE_HTTP_PORTS=${{ values.port }}

COPY --from=build /app ./

USER $APP_UID

EXPOSE ${{ values.port }}

ENTRYPOINT ["dotnet", "Api.dll"]
