namespace RestUserAuthLocationServiceV2;

internal sealed class HeartbeatHostedService : BackgroundService
{
    private readonly ILogger _logger;

    public HeartbeatHostedService(ILogger<HeartbeatHostedService> logger)
    {
        ArgumentNullException.ThrowIfNull(logger);

        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        try
        {
            int i = 0;
            while (!stoppingToken.IsCancellationRequested)
            {
                _logger.LogInformation("heartbeat {i}", i++);
                await Task.Delay(TimeSpan.FromSeconds(30), stoppingToken);
            }
        }
        catch (OperationCanceledException)
        {
        }
    }
}
