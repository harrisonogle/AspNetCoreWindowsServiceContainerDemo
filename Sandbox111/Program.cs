// See https://aka.ms/new-console-template for more information
using Microsoft.Extensions.Hosting;

Console.WriteLine("Hello, World!");

var builder = Host.CreateDefaultBuilder(args);
var app = builder.Build();
app.Run();
