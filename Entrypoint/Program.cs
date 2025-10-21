using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using System.Security.Cryptography.X509Certificates;
using System.Security.Principal;

var builder = Host.CreateDefaultBuilder(args);

var app = builder.Build();

var logger = app.Services.GetRequiredService<ILogger<Program>>();

using (WindowsIdentity identity = WindowsIdentity.GetCurrent())
{
    string username = identity.Name;

    WindowsPrincipal principal = new WindowsPrincipal(identity);
    bool isAdmin = principal.IsInRole(WindowsBuiltInRole.Administrator);

    logger.LogInformation("Current user is '{username}'. Running as administrator: {isAdmin}", username, isAdmin);
}

logger.LogInformation("Reading certifiate from file.");

// Pretend this is coming from a file mounted by AKS CSI driver.
// We'll load it into some user-configured store and make sure the
// non-admin ASP.NET Core app can access it.
X509Certificate2 certificate = X509CertificateLoader.LoadPkcs12FromFile(
    Path.Join(AppContext.BaseDirectory, "certificate.pfx"),
    string.Empty,
    X509KeyStorageFlags.MachineKeySet | X509KeyStorageFlags.PersistKeySet | X509KeyStorageFlags.Exportable);

logger.LogInformation($"Importing certificate with subject '{certificate.Subject}' and thumbprint '{certificate.Thumbprint}' into OS certificate store.");

using (var store = new X509Store(StoreName.My, StoreLocation.LocalMachine))
{
    store.Open(OpenFlags.ReadWrite);
    store.Add(certificate);
    store.Close();
}

app.Run();
