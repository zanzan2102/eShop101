using System.Text.Json.Serialization;
using eShop.OrderProcessor.Events;
using Npgsql;

namespace eShop.OrderProcessor.Extensions;

public static class Extensions
{
    public static void AddApplicationServices(this IHostApplicationBuilder builder)
    {
        builder.AddRabbitMqEventBus("eventbus")
               .ConfigureJsonOptions(options => options.TypeInfoResolverChain.Add(IntegrationEventContext.Default));

        // NOTE: Changed from AddNpgsqlDataSource (Aspire extension) to direct NpgsqlDataSource
        // to use external Neon.tech database connection string from appsettings.Development.json
        var connectionString = builder.Configuration.GetConnectionString("orderingdb");
        builder.Services.AddSingleton<NpgsqlDataSource>(sp =>
        {
            var dataSourceBuilder = new NpgsqlDataSourceBuilder(connectionString);
            return dataSourceBuilder.Build();
        });

        builder.Services.AddOptions<BackgroundTaskOptions>()
            .BindConfiguration(nameof(BackgroundTaskOptions));

        builder.Services.AddHostedService<GracePeriodManagerService>();
    }
}

[JsonSerializable(typeof(GracePeriodConfirmedIntegrationEvent))]
partial class IntegrationEventContext : JsonSerializerContext
{

}
