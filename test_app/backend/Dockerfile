# ---- Build stage ----
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy the project file first and restore separately — this lets Docker cache
# the (slow) NuGet restore layer, so later code-only changes rebuild fast.
COPY backend.csproj ./
RUN dotnet restore

# Now copy the rest of the source and publish a release build.
COPY . ./
RUN dotnet publish -c Release -o /app/publish --no-restore

# ---- Runtime stage ----
# Use the smaller ASP.NET runtime image (not the full SDK) for the final image —
# no build tools needed at runtime, which keeps the image lean for SWR/CCE.
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime
WORKDIR /app

COPY --from=build /app/publish .

EXPOSE 8080

# Run as a non-root user — standard practice, and worth having in place before
# this is reviewed for a payments-adjacent test workload.
RUN useradd -m appuser
USER appuser

ENTRYPOINT ["dotnet", "backend.dll"]