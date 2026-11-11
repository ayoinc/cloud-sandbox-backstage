FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /build
COPY src ./src
RUN dotnet publish src/App/App.csproj --configuration Release --output /out

# Built by the pipeline with --target test: runs the unit tests.
FROM build AS test
COPY tests ./tests
RUN dotnet test tests/App.Tests/App.Tests.csproj

FROM mcr.microsoft.com/dotnet/aspnet:10.0
WORKDIR /app
COPY --from=build /out ./

ENV PORT=8080

USER 10001:10001

EXPOSE 8080

ENTRYPOINT ["dotnet", "App.dll"]
