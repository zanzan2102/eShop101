namespace IdentityServerHost.Quickstart.UI;

public class RegisterViewModel : RegisterInputModel
{
    public bool AllowRememberLogin { get; set; } = true;
    public bool EnableLocalLogin { get; set; } = true;
}

