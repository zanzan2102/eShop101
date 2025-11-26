using eShop.Catalog.API.Services;

public static class Extensions
{
    public static void AddApplicationServices(this IHostApplicationBuilder builder)
    {
        // Avoid loading full database config and migrations if startup
        // is being invoked from build-time OpenAPI generation
        if (builder.Environment.IsBuild())
        {
            builder.Services.AddDbContext<CatalogContext>();
            return;
        }

        // NOTE: Changed from AddNpgsqlDbContext (Aspire extension) to direct UseNpgsql
        // to use external Neon.tech database connection string from appsettings.Development.json
        builder.Services.AddDbContext<CatalogContext>(options =>
        {
            options.UseNpgsql(builder.Configuration.GetConnectionString("catalogdb"), npgsqlOptions =>
            {
                npgsqlOptions.UseVector();
            });
        });
        builder.EnrichNpgsqlDbContext<CatalogContext>();

        // Enable seeding if UseCustomizationData is true in configuration
        // Set CatalogOptions:UseCustomizationData to true to enable seeding
        var useCustomizationData = builder.Configuration.GetValue<bool>("CatalogOptions:UseCustomizationData", false);
        if (useCustomizationData)
        {
            builder.Services.AddMigration<CatalogContext, CatalogContextSeed>();
        }
        else
        {
            builder.Services.AddMigration<CatalogContext>();
        }

        // Add the integration services that consume the DbContext
        builder.Services.AddTransient<IIntegrationEventLogService, IntegrationEventLogService<CatalogContext>>();

        builder.Services.AddTransient<ICatalogIntegrationEventService, CatalogIntegrationEventService>();

        builder.AddRabbitMqEventBus("eventbus")
               .AddSubscription<OrderStatusChangedToAwaitingValidationIntegrationEvent, OrderStatusChangedToAwaitingValidationIntegrationEventHandler>()
               .AddSubscription<OrderStatusChangedToPaidIntegrationEvent, OrderStatusChangedToPaidIntegrationEventHandler>();

        builder.Services.AddOptions<CatalogOptions>()
            .BindConfiguration(nameof(CatalogOptions));

        if (builder.Configuration["OllamaEnabled"] is string ollamaEnabled && bool.Parse(ollamaEnabled))
        {
            builder.AddOllamaApiClient("embedding")
                .AddEmbeddingGenerator();
        }
        else if (!string.IsNullOrWhiteSpace(builder.Configuration.GetConnectionString("textEmbeddingModel")))
        {
            builder.AddOpenAIClientFromConfiguration("textEmbeddingModel")
                .AddEmbeddingGenerator();
        }

        builder.Services.AddScoped<ICatalogAI, CatalogAI>();
    }
}
