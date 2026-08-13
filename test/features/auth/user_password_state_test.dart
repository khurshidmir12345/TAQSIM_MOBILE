import 'package:flutter_test/flutter_test.dart';

import 'package:taqseem/features/auth/domain/models/user_model.dart';

/// Parol o'rnatish ekrani ikki maydonga qarab qaror qiladi:
///  - `hasPassword`      — Google/Telegram orqali kirganda parol yo'q;
///  - `mustSetPassword`  — SMS kodi bilan kirib parolni hali qo'ymagan.
void main() {
  UserModel parse(Map<String, dynamic> extra) =>
      UserModel.fromJson({'id': 'u1', ...extra});

  group('UserModel parol holati', () {
    test('serverdan kelgan qiymatlar o‘qiladi', () {
      final u = parse(const {'has_password': false, 'must_set_password': true});

      expect(u.hasPassword, isFalse);
      expect(u.mustSetPassword, isTrue);
    });

    test('eski server javobida maydonlar bo‘lmasa xatti-harakat o‘zgarmaydi', () {
      // Maydonlarsiz: parol bor deb hisoblanadi va majburiy o'rnatish yo'q —
      // ya'ni avvalgi holat saqlanadi.
      final u = parse(const {});

      expect(u.hasPassword, isTrue);
      expect(u.mustSetPassword, isFalse);
    });

    test('oddiy foydalanuvchi: parol bor, o‘rnatish majburiy emas', () {
      final u = parse(const {'has_password': true, 'must_set_password': false});

      expect(u.hasPassword, isTrue);
      expect(u.mustSetPassword, isFalse);
    });

    test('kod bilan kirgan foydalanuvchida parol bor, lekin o‘rnatish kutilmoqda', () {
      // Parolni unutgan odam: parol bazada bor, lekin u bilmaydi — shuning
      // uchun eski parol so'ralmasligi kerak.
      final u = parse(const {'has_password': true, 'must_set_password': true});

      expect(u.hasPassword, isTrue);
      expect(u.mustSetPassword, isTrue);
    });
  });
}
