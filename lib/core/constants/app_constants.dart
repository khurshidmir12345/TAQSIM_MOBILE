abstract final class AppConstants {
  static const String appName = 'Taqsim';

  static const String baseUrl = 'http://localhost:8086/api';

  // Android emulator uchun: 10.0.2.2
  // iOS simulator uchun: localhost
  // Real qurilma uchun: kompyuter IP (masalan 192.168.x.x:8086)
  static const String baseUrlAndroidEmulator = 'http://10.0.2.2:8086/api';
  static const String baseUrlIosSimulator = 'http://localhost:8086/api';
}
