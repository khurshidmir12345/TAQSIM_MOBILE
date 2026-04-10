/// `assets/svg/app_images/` — raster (PNG/JPEG) rasmlar.
/// Ilova ichidagi branding va dizayn uchun bitta manba.
abstract final class AppRasterAssets {
  static const String _dir = 'assets/svg/app_images';

  /// Brend logosi — ilova ichida har joyda shu ishlatiladi (512×512 compressed).
  /// Keyinchalik logoni o'zgartirish uchun faqat shu faylni almashtiring.
  static const String brandLogo = '$_dir/brand_logo.png';

  /// Ilova banneri (kirish / promo).
  static const String appBanner = '$_dir/app_banner.png';

  /// Telefon bosh ekrani ikonkasi manbasi — `pubspec` → `flutter_launcher_icons` (1024×1024 kvadrat).
  static const String appIcon = '$_dir/app_icon.png';

  /// Eski logo — retro-moslik (yangi kod `brandLogo` ishlatsin).
  static const String taqsimLogo = brandLogo;

  /// Eski nom; yangi banner bilan bir xil fayl (retro-moslik).
  static const String geminiHero = appBanner;

  static const String sample20260405 = '$_dir/sample_20260405.jpg';
  static const String sample20260407_111713 = '$_dir/sample_20260407_111713.jpg';
  static const String sample20260407_111739 = '$_dir/sample_20260407_111739.jpg';
  static const String sample20260407_111746 = '$_dir/sample_20260407_111746.jpg';

  /// Ko‘rinish sahifasida ro‘yxat — yangi rasm qo‘shsangiz shu yerga ham qo‘shing.
  static const List<String> previewPaths = [
    appIcon,
    appBanner,
    taqsimLogo,
    sample20260405,
    sample20260407_111713,
    sample20260407_111739,
    sample20260407_111746,
  ];
}
