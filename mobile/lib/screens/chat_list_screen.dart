import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/chat.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../widgets/ledger/ledger.dart';
import 'chat_conversation_screen.dart';

/// Assistant tab: ask a new question or reopen an earlier one. Asks for AI
/// consent first when it is off for the account.
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => ChatListScreenState();
}

class ChatListScreenState extends State<ChatListScreen> {
  /// Question waiting for the user to turn AI on (e.g. from a Home note).
  String? _pending;
  bool _enabling = false;
  String? _enableError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => reload());
  }

  Future<void> reload() async {
    final auth = context.read<AuthProvider>();
    final chats = context.read<ChatProvider>();
    if (!auth.aiEnabled) return;
    final accessToken = await auth.getValidAccessToken();
    if (accessToken == null) {
      await auth.logout();
      return;
    }
    await chats.fetchChats(accessToken: accessToken);
  }

  /// Opens a new conversation that starts with [question].
  void ask(String question) {
    if (context.read<AuthProvider>().aiEnabled) {
      _open(null, initialQuestion: question);
    } else {
      setState(() => _pending = question);
    }
  }

  Future<void> _enableAi() async {
    final l = AppLocalizations.of(context);
    final auth = context.read<AuthProvider>();
    setState(() {
      _enabling = true;
      _enableError = null;
    });
    final enabled = await auth.enableAi();
    if (!mounted) return;
    setState(() {
      _enabling = false;
      _enableError =
          enabled ? null : (auth.errorMessage ?? l.navEnableAiChatFailed);
    });
    if (!enabled) return;
    final pending = _pending;
    _pending = null;
    if (pending != null) {
      _open(null, initialQuestion: pending);
    } else {
      reload();
    }
  }

  Future<void> _open(String? chatId, {String? initialQuestion}) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatConversationScreen(
          chatId: chatId,
          initialQuestion: initialQuestion,
        ),
      ),
    );
    if (mounted) reload();
  }

  Future<bool> _confirmDelete(Chat chat) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(l.chatListDeleteTitle),
          content: Text(l.chatListDeleteSingleContent(chat.title)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l.commonCancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l.commonDelete),
            ),
          ],
        );
      },
    );
    return confirmed == true;
  }

  /// Deletes before the row animates away, so a failed delete keeps it.
  Future<bool> _delete(Chat chat) async {
    if (!await _confirmDelete(chat) || !mounted) return false;
    final auth = context.read<AuthProvider>();
    final chats = context.read<ChatProvider>();
    final accessToken = await auth.getValidAccessToken();
    if (accessToken == null) return false;
    return chats.deleteChat(accessToken: accessToken, chatId: chat.id);
  }

  String _when(AppLocalizations l, DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return l.chatListJustNow;
    if (diff.inHours < 1) return l.chatListMinutesAgo(diff.inMinutes);
    if (diff.inDays < 1) return l.chatListHoursAgo(diff.inHours);
    if (diff.inDays < 7) return l.chatListDaysAgo(diff.inDays);
    return DateFormat('d MMM yyyy', 'en_US').format(dateTime.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = LedgerColors.of(context);
    final aiEnabled = context.watch<AuthProvider>().aiEnabled;
    final provider = context.watch<ChatProvider>();

    return Scaffold(
      backgroundColor: c.paper,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: reload,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            children: [
              Text(l.navAssistant, style: LedgerText.title(color: c.ink)),
              const SizedBox(height: 10),
              Text(l.assistantIntro,
                  style: LedgerText.body(size: 15, color: c.muted)),
              const SizedBox(height: 24),
              if (!aiEnabled)
                _consent(l, c)
              else ...[
                InkButton(
                  key: const ValueKey('assistant-ask'),
                  label: l.chatListNewChat,
                  onPressed: () => _open(null),
                ),
                const SizedBox(height: 32),
                LedgerCapsHeader(label: l.assistantEarlier),
                ..._history(l, c, provider),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _consent(AppLocalizations l, LedgerColors c) {
    return LedgerPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.navEnableAiChatTitle, style: LedgerText.display(color: c.ink)),
          const SizedBox(height: 8),
          Text(l.navEnableAiChatContent,
              style: LedgerText.body(size: 15, color: c.muted)),
          if (_pending != null) ...[
            const SizedBox(height: 12),
            Text(_pending!,
                style: LedgerText.body(
                    size: 15, color: c.ink, weight: FontWeight.w500)),
          ],
          if (_enableError != null) ...[
            const SizedBox(height: 12),
            Text(_enableError!,
                style: LedgerText.body(size: 14, color: c.danger)),
          ],
          const SizedBox(height: 16),
          InkButton(
            key: const ValueKey('assistant-enable-ai'),
            label: l.navEnableAiChatConfirm,
            busy: _enabling,
            onPressed: _enableAi,
          ),
        ],
      ),
    );
  }

  List<Widget> _history(
    AppLocalizations l,
    LedgerColors c,
    ChatProvider provider,
  ) {
    TextStyle note() => LedgerText.body(size: 15, color: c.muted);
    if (provider.isLoading && provider.chats.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.only(top: 32),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (provider.errorMessage != null && provider.chats.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Text(l.chatListError, style: note()),
        ),
        const SizedBox(height: 12),
        OutlineInkButton(label: l.commonTryAgain, onPressed: reload),
      ];
    }
    if (provider.chats.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Text(l.chatListEmptySubtitle, style: note()),
        ),
      ];
    }
    return [
      for (final chat in provider.chats)
        Dismissible(
          key: ValueKey(chat.id),
          direction: DismissDirection.endToStart,
          background: Container(
            color: c.danger,
            alignment: AlignmentDirectional.centerEnd,
            padding: const EdgeInsetsDirectional.only(end: 16),
            child: Icon(Icons.delete_outline, color: c.onInk),
          ),
          confirmDismiss: (_) => _delete(chat),
          child: InkWell(
            onTap: () => _open(chat.id),
            child: Container(
              constraints: const BoxConstraints(minHeight: 56),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: c.hairline)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          chat.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: LedgerText.body(color: c.ink),
                        ),
                        if (chat.lastMessageAt != null) ...[
                          const SizedBox(height: 2),
                          Text(_when(l, chat.lastMessageAt!),
                              style: LedgerText.body(size: 13, color: c.muted)),
                        ],
                      ],
                    ),
                  ),
                  if (chat.messageCount != null) ...[
                    const SizedBox(width: 12),
                    Text('${chat.messageCount}',
                        style: LedgerText.figures(size: 13, color: c.muted)),
                  ],
                  Icon(Icons.chevron_right, size: 20, color: c.muted),
                ],
              ),
            ),
          ),
        ),
    ];
  }
}
