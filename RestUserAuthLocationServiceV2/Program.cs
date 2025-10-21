using NReco.Logging.File;
using RestUserAuthLocationServiceV2;
using System.Diagnostics;
using System.Security.Cryptography.X509Certificates;
using System.Security.Principal;

string logPath;

try
{
    logPath = Path.Join(AppContext.BaseDirectory, "rualsv2.log");
    File.AppendAllLines(logPath, [$"[{DateTimeOffset.UtcNow.ToString("O")}] Created log file."]);
}
catch (Exception ex)
{
    using (EventLog eventLog = new EventLog("Application"))
    {
        eventLog.Source = "Application";
        eventLog.WriteEntry($"Exception writing to log file. {ex}", EventLogEntryType.Information, 101, 1);
    }
    throw;
}

try
{
    var builder = WebApplication.CreateBuilder(args);

    builder.Services.AddWindowsService(static options => options.ServiceName = "RUALSv2");
    builder.Services.AddHostedService<HeartbeatHostedService>();

    builder.Logging.AddFile(logPath);

    var app = builder.Build();

    app.MapGet("/", static () => "Hello World!");
    app.MapGet("/user", static () =>
    {
        using (WindowsIdentity identity = WindowsIdentity.GetCurrent())
        {
            WindowsPrincipal principal = new WindowsPrincipal(identity);
            bool isAdmin = principal.IsInRole(WindowsBuiltInRole.Administrator);

            return new
            {
                Message = "Displaying current Windows user.",
                identity.Name,
                Owner = identity.Owner?.Value,
                identity.IsGuest,
                identity.IsSystem,
                IsAdmin = isAdmin,
            };
        }
    });
    app.MapGet("/cert", static () =>
    {
        using var store = new X509Store(StoreName.My, StoreLocation.LocalMachine);
        store.Open(OpenFlags.ReadOnly);
        foreach (X509Certificate2 certificate in store.Certificates)
        {
            if (certificate.Subject?.Contains("Intune") is true)
            {
                return Results.Text(certificate.ToString(), "text/plain", statusCode: 200);
            }
        }
        store.Close();
        return Results.NotFound("Certificate not found.");
    });

    app.Run();
}
catch (Exception ex)
{
    File.AppendAllLines(logPath, [$"Exception: {ex}"]);
}
