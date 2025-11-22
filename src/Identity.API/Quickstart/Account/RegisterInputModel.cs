namespace IdentityServerHost.Quickstart.UI;

public class RegisterInputModel
{
    [Required]
    [EmailAddress]
    [Display(Name = "Email")]
    public string Email { get; set; }

    [Required]
    [StringLength(100, ErrorMessage = "The {0} must be at least {2} and at max {1} characters long.", MinimumLength = 6)]
    [DataType(DataType.Password)]
    [Display(Name = "Password")]
    public string Password { get; set; }

    [DataType(DataType.Password)]
    [Display(Name = "Confirm password")]
    [Compare("Password", ErrorMessage = "The password and confirmation password do not match.")]
    public string ConfirmPassword { get; set; }

    [Required]
    [Display(Name = "First Name")]
    public string Name { get; set; }

    // Các trường sau không bắt buộc vì không hiển thị trong form đăng ký
    [Display(Name = "Last Name")]
    public string LastName { get; set; } = string.Empty;

    [Display(Name = "Street")]
    public string Street { get; set; } = string.Empty;

    [Display(Name = "City")]
    public string City { get; set; } = string.Empty;

    [Display(Name = "State")]
    public string State { get; set; } = string.Empty;

    [Display(Name = "Country")]
    public string Country { get; set; } = string.Empty;

    [Display(Name = "Zip Code")]
    public string ZipCode { get; set; } = string.Empty;

    [Display(Name = "Card Holder Name")]
    public string CardHolderName { get; set; } = string.Empty;

    [Display(Name = "Card Number")]
    public string CardNumber { get; set; } = string.Empty;

    [Display(Name = "Security Number")]
    public string SecurityNumber { get; set; } = string.Empty;

    [RegularExpression(@"(0[1-9]|1[0-2])\/[0-9]{2}", ErrorMessage = "Expiration should match a valid MM/YY value")]
    [Display(Name = "Expiration (MM/YY)")]
    public string Expiration { get; set; } = string.Empty;

    [Display(Name = "Card Type")]
    public int CardType { get; set; } = 1;

    public string ReturnUrl { get; set; }
}

