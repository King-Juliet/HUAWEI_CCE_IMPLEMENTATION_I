using Npgsql;

var builder = WebApplication.CreateBuilder(args);

// Allow the frontend (running on a different origin/container) to call this API.
var frontendOrigin = builder.Configuration["FRONTEND_ORIGIN"] ?? "http://localhost:3000";

builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        policy.WithOrigins(frontendOrigin)
              .AllowAnyHeader()
              .AllowAnyMethod();
    });
});

// ---------------------------------------------------------------------------
// Database connection — built entirely from environment variables.
// Nothing here is hardcoded. In CCE, these env vars get populated from a
// Kubernetes Secret (ideally sourced from Huawei CSMS, per the earlier
// discussion), not typed into a config file or committed anywhere.
// ---------------------------------------------------------------------------
var dbHost     = Environment.GetEnvironmentVariable("DB_HOST")
                  ?? throw new InvalidOperationException("DB_HOST environment variable is not set.");
var dbPort     = Environment.GetEnvironmentVariable("DB_PORT") ?? "5432";
var dbName     = Environment.GetEnvironmentVariable("DB_NAME")
                  ?? throw new InvalidOperationException("DB_NAME environment variable is not set.");
var dbUser     = Environment.GetEnvironmentVariable("DB_USER")
                  ?? throw new InvalidOperationException("DB_USER environment variable is not set.");
var dbPassword = Environment.GetEnvironmentVariable("DB_PASSWORD")
                  ?? throw new InvalidOperationException("DB_PASSWORD environment variable is not set.");

// Whether the connection itself must use SSL/TLS. Default to "true" since
// Huawei RDS traffic should be encrypted in transit — override only for
// local Docker testing against a throwaway Postgres container.
var dbSslMode = Environment.GetEnvironmentVariable("DB_SSL_MODE") ?? "Require";

var connectionStringBuilder = new NpgsqlConnectionStringBuilder
{
    Host     = dbHost,
    Port     = int.Parse(dbPort),
    Database = dbName,
    Username = dbUser,
    Password = dbPassword,
    SslMode  = Enum.Parse<SslMode>(dbSslMode, ignoreCase: true),
};

// Failing fast at startup (rather than on first request) makes a bad
// connection string obvious immediately in the pod logs, instead of only
// surfacing when the first user hits the endpoint.
var dataSource = NpgsqlDataSource.Create(connectionStringBuilder.ConnectionString);

var app = builder.Build();

app.UseCors();

app.MapGet("/health", () => Results.Ok(new { status = "healthy" }));

app.MapGet("/", () => Results.Ok(new { message = "IMTO test backend is running" }));

app.MapGet("/api/greeting", () =>
{
    var podName = Environment.GetEnvironmentVariable("HOSTNAME") ?? "unknown-host";
    return Results.Ok(new
    {
        message = "Hello from the C# backend",
        servedBy = podName,
        timestampUtc = DateTime.UtcNow
    });
});

// Confirms the app can actually reach the database and run a real query —
// doesn't touch any table, just asks Postgres to identify itself.
app.MapGet("/api/db-check", async () =>
{
    try
    {
        await using var connection = await dataSource.OpenConnectionAsync();
        await using var command = new NpgsqlCommand("SELECT version();", connection);
        var version = (string?)await command.ExecuteScalarAsync();

        return Results.Ok(new
        {
            connected = true,
            postgresVersion = version
        });
    }
    catch (Exception ex)
    {
        // Returning the exception message helps you debug the CCE/RDS network
        // path during testing. Strip this down before this pattern is reused
        // for anything closer to the real IMTO service.
        return Results.Problem(
            title: "Database connection failed",
            detail: ex.Message,
            statusCode: 500);
    }
});

// A slightly more meaningful test than db-check alone: creates a table if it
// doesn't exist, inserts one row per call, and returns the running count —
// proves both read and write access, not just connectivity.
app.MapGet("/api/visits", async () =>
{
    await using var connection = await dataSource.OpenConnectionAsync();

    await using (var createCmd = new NpgsqlCommand(
        "CREATE TABLE IF NOT EXISTS visits (id SERIAL PRIMARY KEY, visited_at TIMESTAMPTZ NOT NULL DEFAULT now());",
        connection))
    {
        await createCmd.ExecuteNonQueryAsync();
    }

    await using (var insertCmd = new NpgsqlCommand(
        "INSERT INTO visits DEFAULT VALUES;", connection))
    {
        await insertCmd.ExecuteNonQueryAsync();
    }

    await using var countCmd = new NpgsqlCommand("SELECT COUNT(*) FROM visits;", connection);
    var count = (long)(await countCmd.ExecuteScalarAsync() ?? 0L);

    return Results.Ok(new { totalVisits = count });
});

app.Run("http://0.0.0.0:8080");