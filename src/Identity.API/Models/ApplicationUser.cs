namespace eShop.Identity.API.Models
{
    // Add profile data for application users by adding properties to the ApplicationUser class
    public class ApplicationUser : IdentityUser
    {
        // Form đăng ký chỉ yêu cầu Email, Name, Password
        // Chỉ giữ lại Name vì có trong form đăng ký
        [Required]
        public string Name { get; set; }
    }
}
