internal static class Extensions
{
    public static void AddApplicationServices(this IHostApplicationBuilder builder)
    {
        builder.AddDefaultAuthentication();

        builder.AddRabbitMqEventBus("eventbus")
               .AddEventBusSubscriptions();

        // NOTE: Changed from AddNpgsqlDbContext (Aspire extension) to direct UseNpgsql
        // to use external Neon.tech database connection string from appsettings.Development.json
        builder.Services.AddDbContext<WebhooksContext>(options =>
        {
            options.UseNpgsql(builder.Configuration.GetConnectionString("webhooksdb"));
        });
        builder.EnrichNpgsqlDbContext<WebhooksContext>();

        builder.Services.AddMigration<WebhooksContext>();

        builder.Services.AddTransient<IGrantUrlTesterService, GrantUrlTesterService>();
        builder.Services.AddTransient<IWebhooksRetriever, WebhooksRetriever>();
        builder.Services.AddTransient<IWebhooksSender, WebhooksSender>();
    }

    private static void AddEventBusSubscriptions(this IEventBusBuilder eventBus)
    {
        eventBus.AddSubscription<ProductPriceChangedIntegrationEvent, ProductPriceChangedIntegrationEventHandler>();
        eventBus.AddSubscription<OrderStatusChangedToShippedIntegrationEvent, OrderStatusChangedToShippedIntegrationEventHandler>();
        eventBus.AddSubscription<OrderStatusChangedToPaidIntegrationEvent, OrderStatusChangedToPaidIntegrationEventHandler>();
    }
}
