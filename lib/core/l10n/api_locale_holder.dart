/// Joriy ilova tili kodi (API `Accept-Language` va [S.apiClientString] uchun).
/// [LocaleNotifier] har safar locale yuklanganda yoki o‘zgarganda yangilaydi.
class ApiLocaleHolder {
  ApiLocaleHolder._();

  static String code = 'uz';

  static void setCode(String value) {
    code = value;
  }
}
