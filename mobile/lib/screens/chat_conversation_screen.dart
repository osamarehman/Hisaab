import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';

import '../constants/suggested_questions.dart';
import '../l10n/app_localizations.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../widgets/ledger/ledger.dart';
import '../widgets/typing_indicator.dart';

class _SendMessageIntent extends Intent {
  const _SendMessageIntent();
}

class ChatConversationScreen extends StatefulWidget {
  /// Null means this is a brand-new chat — it will be created on first send.
  final String? chatId;

  /// Sent as the first message of a new chat (e.g. a Home note).
  final String? initialQuestion;

  const ChatConversationScreen({
    super.key,
    required this.chatId,
    this.initialQuestion,
  });

  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  /// Tracks the real chat ID once the chat has been created.
  String? _chatId;

  ChatProvider? _chatProvider;
  bool _listenerAdded = false;
  bool _isSendInFlight = false;

  @override
  void initState() {
    super.initState();
    _chatId = widget.chatId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _chatProvider = Provider.of<ChatProvider>(context, listen: false);
      _chatProvider!.addListener(_onChatChanged);
      _listenerAdded = true;
      if (_chatId == null) {
        _chatProvider!.clearCurrentChat();
        final question = widget.initialQuestion;
        if (question != null && question.trim().isNotEmpty) {
          _sendSuggestedQuestion(question);
        }
      }
    });
    if (_chatId != null) {
      _loadChat();
    }
  }

  @override
  void dispose() {
    if (_listenerAdded && _chatProvider != null) {
      _chatProvider!.removeListener(_onChatChanged);
      _chatProvider = null;
      _listenerAdded = false;
    }
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onChatChanged() {
    if (!mounted) return;
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    if (chatProvider.isWaitingForResponse || chatProvider.isSendingMessage || chatProvider.isPolling) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrollToBottom();
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendSuggestedQuestion(String question) async {
    if (!mounted) return;
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    if (chatProvider.isSendingMessage || chatProvider.isWaitingForResponse) return;
    _messageController.text = question;
    await _sendMessage();
  }

  Future<void> _loadChat({bool forceRefresh = false}) async {
    if (_chatId == null) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    // Skip fetch if the provider already has this chat loaded (e.g. just created).
    if (!forceRefresh && chatProvider.currentChat?.id == _chatId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
      return;
    }

    final accessToken = await authProvider.getValidAccessToken();
    if (accessToken == null) {
      await authProvider.logout();
      return;
    }

    await chatProvider.fetchChat(
      accessToken: accessToken,
      chatId: _chatId!,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_isSendInFlight) return;
    final content = _messageController.text.trim();
    if (content.isEmpty) return;
    setState(() => _isSendInFlight = true);

    final l = AppLocalizations.of(context);

    try {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    final accessToken = await authProvider.getValidAccessToken();
    if (accessToken == null) {
      await authProvider.logout();
      return;
    }

    _messageController.clear();

    if (_chatId == null) {
      // First message in a new chat — create the chat with it.
      final chat = await chatProvider.createChat(
        accessToken: accessToken,
        title: Chat.generateTitle(content),
        initialMessage: content,
      );
      if (!mounted) return;
      if (chat == null) {
        // Restore the message so the user doesn't lose it.
        _messageController.text = content;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(chatProvider.errorMessage ?? l.chatConversationStartFailed),
          ),
        );
        return;
      }
      setState(() => _chatId = chat.id);
    } else {
      final shouldUpdateTitle =
          chatProvider.currentChat?.hasDefaultTitle == true;

      final delivered = await chatProvider.sendMessage(
        accessToken: accessToken,
        chatId: _chatId!,
        content: content,
      );

      if (delivered && shouldUpdateTitle) {
        await chatProvider.updateChatTitle(
          accessToken: accessToken,
          chatId: _chatId!,
          title: Chat.generateTitle(content),
        );
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
    } finally {
      if (mounted) setState(() => _isSendInFlight = false);
    }
  }

  Future<void> _editTitle() async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final currentTitle = chatProvider.currentChat?.title ?? '';

    final newTitle = await showDialog<String>(
      context: context,
      builder: (context) {
        final dl = AppLocalizations.of(context);
        final controller = TextEditingController(text: currentTitle);
        return AlertDialog(
          title: Text(dl.chatConversationEditTitle),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: dl.chatConversationTitleLabel,
              border: const OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(dl.commonCancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: Text(dl.commonSave),
            ),
          ],
        );
      },
    );

    if (newTitle != null &&
        newTitle.isNotEmpty &&
        newTitle != currentTitle &&
        mounted) {
      if (_chatId == null) return;
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final accessToken = await authProvider.getValidAccessToken();
      if (accessToken != null) {
        await chatProvider.updateChatTitle(
          accessToken: accessToken,
          chatId: _chatId!,
          title: newTitle,
        );
      }
    }
  }

  String _formatTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  bool _busy(ChatProvider p) =>
      _isSendInFlight ||
      p.isSendingMessage ||
      p.isWaitingForResponse ||
      p.isPolling;

  @override
  Widget build(BuildContext context) {
    final c = LedgerColors.of(context);
    final l = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: c.paper,
      body: SafeArea(
        bottom: false,
        child: Consumer<ChatProvider>(
          builder: (context, chatProvider, _) {
            return Column(
              children: [
                LedgerBackHeader(label: l.navAssistant),
                _titleBar(l, c, chatProvider),
                Expanded(child: _body(l, c, chatProvider)),
                _composer(l, c, chatProvider),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _titleBar(AppLocalizations l, LedgerColors c, ChatProvider p) {
    final title = p.currentChat?.title ?? l.chatConversationNewTitle;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 8, 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.ink)),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: _chatId != null ? _editTitle : null,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44),
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: LedgerText.display(color: c.ink),
                      ),
                    ),
                    if (_chatId != null) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.edit_outlined, size: 16, color: c.muted),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (widget.chatId != null)
            IconButton(
              icon: Icon(Icons.refresh, color: c.ink),
              onPressed: () => _loadChat(forceRefresh: true),
              tooltip: l.chatConversationRefreshTooltip,
            ),
        ],
      ),
    );
  }

  Widget _body(AppLocalizations l, LedgerColors c, ChatProvider p) {
    if (p.isLoading && p.currentChat == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (p.errorMessage != null && p.currentChat == null && _chatId != null) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(l.chatConversationLoadError,
              style: LedgerText.display(color: c.ink)),
          const SizedBox(height: 8),
          Text(p.errorMessage!,
              style: LedgerText.body(size: 15, color: c.muted)),
          const SizedBox(height: 20),
          OutlineInkButton(label: l.commonTryAgain, onPressed: _loadChat),
        ],
      );
    }

    final allMessages = p.currentChat?.messages ?? [];
    // While waiting, hide the partial assistant reply; the typing indicator
    // shows instead until polling sees stable content.
    final messages = p.isWaitingForResponse
        ? allMessages
            .where((m) => !(m.isAssistant && m == allMessages.lastOrNull))
            .toList()
        : allMessages;

    if (messages.isEmpty &&
        !p.isLoading &&
        !p.isSendingMessage &&
        !p.isWaitingForResponse) {
      final firstName = context.watch<AuthProvider>().user?.firstName;
      return _EmptyState(
        firstName: firstName,
        onQuestionTap: _sendSuggestedQuestion,
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      itemCount: messages.length + (p.isWaitingForResponse ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == messages.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TypingIndicator(),
            ),
          );
        }
        return _MessageBlock(
          message: messages[index],
          formatTime: _formatTime,
        );
      },
    );
  }

  Widget _composer(AppLocalizations l, LedgerColors c, ChatProvider p) {
    final busy = _busy(p);
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        12 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: c.sheet,
        border: Border(top: BorderSide(color: c.ink)),
      ),
      child: Shortcuts(
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.enter): _SendMessageIntent(),
        },
        child: Actions(
          actions: <Type, Action<Intent>>{
            _SendMessageIntent: CallbackAction<_SendMessageIntent>(
              onInvoke: (_) {
                if (!_busy(p)) _sendMessage();
                return null;
              },
            ),
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: ledgerInputDecoration(
                    context,
                    hint: l.chatConversationMessageHint,
                  ),
                  style: LedgerText.body(color: c.ink),
                  minLines: 1,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  autofocus: _chatId == null && widget.initialQuestion == null,
                ),
              ),
              const SizedBox(width: 8),
              Semantics(
                button: true,
                enabled: !busy,
                label: l.assistantSend,
                excludeSemantics: true,
                child: Material(
                  color: busy ? c.track : c.ink,
                  borderRadius: BorderRadius.circular(2),
                  child: InkWell(
                    key: const ValueKey('assistant-send'),
                    onTap: busy ? null : _sendMessage,
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: Icon(Icons.arrow_upward,
                          color: busy ? c.muted : c.onInk),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "get_transactions" → "transactions", for the quiet tool-call line.
String toolCallSubject(String functionName) => functionName
    .replaceFirst(RegExp(r'^(get|search|list|fetch)_'), '')
    .replaceAll('_', ' ');

/// User messages: ink block on the right. Assistant: plain markdown on paper
/// with a hairline underneath.
class _MessageBlock extends StatelessWidget {
  final Message message;
  final String Function(DateTime) formatTime;

  const _MessageBlock({
    required this.message,
    required this.formatTime,
  });

  MarkdownStyleSheet _markdownStyle(BuildContext context, LedgerColors c) {
    final body = LedgerText.body(size: 15, color: c.ink).copyWith(height: 1.45);
    return MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
      p: body,
      strong: body.copyWith(fontWeight: FontWeight.w600),
      em: body.copyWith(fontStyle: FontStyle.italic),
      listBullet: body,
      tableBody: body,
      tableHead: body.copyWith(fontWeight: FontWeight.w600),
      h1: LedgerText.display(size: 20, color: c.ink),
      h2: LedgerText.display(size: 18, color: c.ink),
      h3: LedgerText.body(color: c.ink, weight: FontWeight.w600),
      code: LedgerText.figures(size: 13, color: c.ink),
      codeblockDecoration: BoxDecoration(
        color: c.sheet,
        border: Border.all(color: c.hairline),
        borderRadius: BorderRadius.circular(2),
      ),
      blockquoteDecoration: BoxDecoration(
        border: Border(left: BorderSide(color: c.hairline, width: 2)),
      ),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.hairline)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = LedgerColors.of(context);
    final l = AppLocalizations.of(context);
    final time = Text(
      formatTime(message.createdAt),
      style: LedgerText.figures(size: 11, color: c.muted),
    );

    if (message.isUser) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.8,
              ),
              child: SelectionArea(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: c.ink,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    message.content,
                    style: LedgerText.body(size: 15, color: c.onInk),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            time,
          ],
        ),
      );
    }

    final tools = message.toolCalls ?? const [];
    final subjects = {for (final t in tools) toolCallSubject(t.functionName)};
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.hairline)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final subject in subjects)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                l.assistantLookedUp(subject),
                style: LedgerText.figures(size: 12, color: c.muted),
              ),
            ),
          SelectionArea(
            child: MarkdownBody(
              data: message.content,
              selectable: false,
              softLineBreak: true,
              styleSheet: _markdownStyle(context, c),
              sizedImageBuilder: (config) {
                // Block remote images to prevent unsolicited network requests.
                if (config.uri.scheme == 'http' ||
                    config.uri.scheme == 'https') {
                  return const SizedBox.shrink();
                }
                return Image.asset(config.uri.toString());
              },
            ),
          ),
          const SizedBox(height: 6),
          time,
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String? firstName;
  final void Function(String) onQuestionTap;

  const _EmptyState({
    required this.firstName,
    required this.onQuestionTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = LedgerColors.of(context);
    final l = AppLocalizations.of(context);
    final name = (firstName ?? '').trim();
    final greeting = name.isNotEmpty
        ? l.chatConversationGreetingWithName(name)
        : l.chatConversationGreetingNoName;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
      children: [
        Text(
          greeting,
          style: LedgerText.display(
              size: 26, weight: FontWeight.w700, color: c.ink),
        ),
        const SizedBox(height: 28),
        LedgerCapsHeader(label: l.assistantTryAsking),
        for (final q in suggestedQuestions(context))
          InkWell(
            onTap: () => onQuestionTap(q),
            child: Container(
              constraints: const BoxConstraints(minHeight: 52),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: c.hairline)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(q, style: LedgerText.body(color: c.ink)),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 18, color: c.moneyIn),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
