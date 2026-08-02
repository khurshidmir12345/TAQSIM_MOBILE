import 'package:flutter_test/flutter_test.dart';
import 'package:taqseem/features/shell/domain/shell_tab.dart';
import 'package:taqseem/features/shell/domain/shell_tab_utils.dart';

void main() {
  group('reconcileShellTabIndex', () {
    test('preserves statistics tab when orders disappears', () {
      const previous = [
        ShellTab.home,
        ShellTab.expenses,
        ShellTab.statistics,
        ShellTab.orders,
      ];
      const next = [ShellTab.home, ShellTab.expenses, ShellTab.statistics];

      expect(
        reconcileShellTabIndex(
          previousTabs: previous,
          previousIndex: 2,
          nextTabs: next,
          selectedIdentity: ShellTab.statistics,
        ),
        2,
      );
    });

    test('maps selected identity when index shifts', () {
      const previous = [
        ShellTab.home,
        ShellTab.expenses,
        ShellTab.statistics,
        ShellTab.orders,
      ];
      const next = [ShellTab.home, ShellTab.statistics, ShellTab.orders];

      expect(
        reconcileShellTabIndex(
          previousTabs: previous,
          previousIndex: 3,
          nextTabs: next,
          selectedIdentity: ShellTab.orders,
        ),
        2,
      );
    });

    test('falls back to home when selected tab removed', () {
      const previous = [ShellTab.home, ShellTab.expenses, ShellTab.orders];
      const next = [ShellTab.home, ShellTab.expenses];

      expect(
        reconcileShellTabIndex(
          previousTabs: previous,
          previousIndex: 2,
          nextTabs: next,
          selectedIdentity: ShellTab.orders,
        ),
        0,
      );
    });
  });
}
