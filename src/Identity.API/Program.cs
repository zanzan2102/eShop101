using System.Security.Cryptography.X509Certificates;

var builder = WebApplication.CreateBuilder(args);

builder.AddServiceDefaults();

builder.Services.AddControllersWithViews();

// NOTE: Changed from AddNpgsqlDbContext (Aspire extension) to direct UseNpgsql
// to use external Neon.tech database connection string from appsettings.Development.json
builder.Services.AddDbContext<ApplicationDbContext>(options =>
{
    options.UseNpgsql(builder.Configuration.GetConnectionString("identitydb"));
});
builder.EnrichNpgsqlDbContext<ApplicationDbContext>();

// Apply database migration automatically. Note that this approach is not
// recommended for production scenarios. Consider generating SQL scripts from
// migrations instead.
builder.Services.AddMigration<ApplicationDbContext, UsersSeed>();

builder.Services.AddIdentity<ApplicationUser, IdentityRole>()
        .AddEntityFrameworkStores<ApplicationDbContext>()
        .AddDefaultTokenProviders();

var identityServerBuilder = builder.Services.AddIdentityServer(options =>
{
    //options.IssuerUri = "null";
    options.Authentication.CookieLifetime = TimeSpan.FromHours(4);

    options.Events.RaiseErrorEvents = true;
    options.Events.RaiseInformationEvents = true;
    options.Events.RaiseFailureEvents = true;
    options.Events.RaiseSuccessEvents = true;

    // Only disable key management in Development
    // In production, you should enable key management and store keys securely
    options.KeyManagement.Enabled = builder.Environment.IsProduction();
})
.AddInMemoryIdentityResources(Config.GetResources())
.AddInMemoryApiScopes(Config.GetApiScopes())
.AddInMemoryApiResources(Config.GetApis())
.AddInMemoryClients(Config.GetClients(builder.Configuration))
.AddAspNetIdentity<ApplicationUser>();

// Configure signing credentials based on environment
if (builder.Environment.IsDevelopment())
{
    // Use developer signing credential in Development
    identityServerBuilder.AddDeveloperSigningCredential();
}
else
{
    // Production: Use certificate from configuration or environment variable
    var certificatePath = builder.Configuration["IdentityServer:Certificate:Path"];
    var certificatePassword = builder.Configuration["IdentityServer:Certificate:Password"];
    
    if (!string.IsNullOrEmpty(certificatePath) && File.Exists(certificatePath))
    {
        // Load certificate from file
#pragma warning disable SYSLIB0057 // Type or member is obsolete
        var certificate = new X509Certificate2(certificatePath, certificatePassword);
#pragma warning restore SYSLIB0057
        identityServerBuilder.AddSigningCredential(certificate);
    }
    else
    {
        // Fallback: Try to load from environment variable (for containerized deployments)
        var certBase64 = Environment.GetEnvironmentVariable("IDENTITY_SERVER_CERTIFICATE_BASE64");
        var certPassword = Environment.GetEnvironmentVariable("IDENTITY_SERVER_CERTIFICATE_PASSWORD");
        
        if (!string.IsNullOrEmpty(certBase64))
        {
            var certBytes = Convert.FromBase64String(certBase64);
#pragma warning disable SYSLIB0057 // Type or member is obsolete
            var certificate = new X509Certificate2(certBytes, certPassword);
#pragma warning restore SYSLIB0057
            identityServerBuilder.AddSigningCredential(certificate);
        }
        else
        {
            // Last resort: Use developer credential (NOT RECOMMENDED FOR PRODUCTION)
            // TODO: Replace with proper certificate management
            // Logging will be done after app is built
            identityServerBuilder.AddDeveloperSigningCredential();
        }
    }
}

builder.Services.AddTransient<IProfileService, ProfileService>();
builder.Services.AddTransient<ILoginService<ApplicationUser>, EFLoginService>();
builder.Services.AddTransient<IRedirectService, RedirectService>();

var app = builder.Build();

// Log warning if using developer credential in production
if (app.Environment.IsProduction())
{
    var logger = app.Services.GetRequiredService<ILogger<Program>>();
    var certificatePath = app.Configuration["IdentityServer:Certificate:Path"];
    var certBase64 = Environment.GetEnvironmentVariable("IDENTITY_SERVER_CERTIFICATE_BASE64");
    
    if (string.IsNullOrEmpty(certificatePath) && string.IsNullOrEmpty(certBase64))
    {
        logger.LogWarning("WARNING: Using developer signing credential in Production. This should be replaced with a proper certificate.");
    }
}

app.MapDefaultEndpoints();

app.UseStaticFiles();

// This cookie policy fixes login issues with Chrome 80+ using HTTP
app.UseCookiePolicy(new CookiePolicyOptions { MinimumSameSitePolicy = SameSiteMode.Lax });
app.UseRouting();
app.UseIdentityServer();
app.UseAuthorization();

app.MapDefaultControllerRoute();

app.Run();
