var builder = WebApplication.CreateBuilder(args);

builder.Services.AddWindowsService(static options => options.ServiceName = "RUALSv2");

var app = builder.Build();

app.MapGet("/", () => "Hello World!");

app.Run();
