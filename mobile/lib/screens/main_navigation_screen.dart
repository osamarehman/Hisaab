import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../widgets/ledger/ledger.dart';
import 'accounts_screen.dart';
import 'dashboard_screen.dart';
import 'statements_screen.dart';
import 'transaction_form_screen.dart';
import 'transactions_list_screen.dart';

/// Household shell: Home, Activity, Add (centre), Statements, Accounts.
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  // Index into the IndexedStack; the Add button is not a page.
  int _page = 0;
  final _dashboardKey = GlobalKey<DashboardScreenState>();
  final _activityKey = GlobalKey<TransactionsListScreenState>();

  late final List<Widget> _pages = [
    DashboardScreen(
      key: _dashboardKey,
      onOpenActivity: _openActivity,
      onOpenAccounts: () => _select(3),
    ),
    TransactionsListScreen(key: _activityKey),
    const StatementsScreen(),
    const AccountsScreen(),
  ];

  void _select(int page) {
    if (page == _page) return;
    setState(() => _page = page);
    if (page == 0) _dashboardKey.currentState?.reload();
    if (page == 1) _activityKey.currentState?.reload();
  }

  void _openActivity(DateTime month, String? categoryId) {
    _activityKey.currentState?.showMonth(month, categoryId: categoryId);
    setState(() => _page = 1);
  }

  Future<void> _addExpense() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const TransactionFormScreen(),
      ),
    );
    if (saved == true && mounted) {
      _dashboardKey.currentState?.reload();
      _activityKey.currentState?.reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: IndexedStack(index: _page, children: _pages),
      bottomNavigationBar: _LedgerNavBar(
        selected: _page,
        onSelect: _select,
        onAdd: _addExpense,
        items: [
          _NavItem(Icons.home_outlined, l.navHome),
          _NavItem(Icons.notes, l.navActivity),
          _NavItem(Icons.description_outlined, l.navStatements),
          _NavItem(Icons.credit_card_outlined, l.navAccounts),
        ],
        addLabel: l.navAddExpense,
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.icon, this.label);
  final IconData icon;
  final String label;
}

class _LedgerNavBar extends StatelessWidget {
  const _LedgerNavBar({
    required this.selected,
    required this.onSelect,
    required this.onAdd,
    required this.items,
    required this.addLabel,
  });

  final int selected;
  final ValueChanged<int> onSelect;
  final VoidCallback onAdd;
  final List<_NavItem> items;
  final String addLabel;

  @override
  Widget build(BuildContext context) {
    final c = LedgerColors.of(context);

    Widget tab(int page) {
      final item = items[page];
      final active = page == selected;
      return Expanded(
        child: Semantics(
          selected: active,
          button: true,
          child: InkWell(
            onTap: () => onSelect(page),
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: active ? c.moneyIn : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item.icon, size: 22, color: active ? c.ink : c.muted),
                  const SizedBox(height: 3),
                  Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                      color: active ? c.ink : c.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: c.sheet,
        border: Border(top: BorderSide(color: c.ink)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              tab(0),
              tab(1),
              Expanded(
                child: Center(
                  child: Semantics(
                    button: true,
                    label: addLabel,
                    excludeSemantics: true,
                    child: Material(
                      color: c.moneyIn,
                      borderRadius: BorderRadius.circular(2),
                      child: InkWell(
                        key: const ValueKey('nav-add'),
                        onTap: onAdd,
                        child: const SizedBox(
                          width: 48,
                          height: 48,
                          child: Icon(Icons.add, color: Colors.white, size: 26),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              tab(2),
              tab(3),
            ],
          ),
        ),
      ),
    );
  }
}
