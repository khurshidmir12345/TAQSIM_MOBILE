import 'shell_tab.dart';

/// Ruxsatlar o‘zgarganda indeksni tab identifikatoriga bog‘lab qayta hisoblaydi.
int reconcileShellTabIndex({
  required List<ShellTab> previousTabs,
  required int previousIndex,
  required List<ShellTab> nextTabs,
  ShellTab? selectedIdentity,
}) {
  if (nextTabs.isEmpty) return 0;

  final identity =
      selectedIdentity ??
      (previousIndex >= 0 && previousIndex < previousTabs.length
          ? previousTabs[previousIndex]
          : ShellTab.home);

  final mapped = nextTabs.indexOf(identity);
  if (mapped >= 0) return mapped;

  final homeIndex = nextTabs.indexOf(ShellTab.home);
  return homeIndex >= 0 ? homeIndex : 0;
}
