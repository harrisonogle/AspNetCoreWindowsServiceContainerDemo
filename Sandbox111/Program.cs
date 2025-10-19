using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using System.Security.Principal;

var builder = Host.CreateDefaultBuilder(args);

var app = builder.Build();

using (WindowsIdentity identity = WindowsIdentity.GetCurrent())
{
    string username = identity.Name;

    WindowsPrincipal principal = new WindowsPrincipal(identity);
    bool isAdmin = principal.IsInRole(WindowsBuiltInRole.Administrator);

    app.Services.GetRequiredService<ILogger<Program>>()
        .LogInformation("Current user is '{username}'. Running as administrator: {isAdmin}", username, isAdmin);
}

app.Run();
