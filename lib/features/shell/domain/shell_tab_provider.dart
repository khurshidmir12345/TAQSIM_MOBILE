import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Pastki navigatsiya va `Asosiy`dan `Tizim`ga o‘tish uchun umumiy indeks.
class ShellTabIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int index) => state = index;
}

final shellTabIndexProvider =
    NotifierProvider<ShellTabIndexNotifier, int>(ShellTabIndexNotifier.new);
