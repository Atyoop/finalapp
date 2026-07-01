import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat_history.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';
import '../providers/language_provider.dart';
import '../providers/user_provider.dart';
import '../services/chatbot_service.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  bool _showChat = false;

  @override
  Widget build(BuildContext context) {
    final isAr = context.watch<LanguageProvider>().currentLanguage == 'ar';
    return _showChat
        ? _ChatConversation(onBack: () => setState(() => _showChat = false))
        : _buildIntro(isAr);
  }

  Widget _buildIntro(bool isAr) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: AppColors.textDark),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              // Mascot / Bot avatar
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2C6E72), Color(0xFF3A9EA5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(36),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryTeal.withValues(alpha: 0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.smart_toy_rounded,
                  color: Colors.white,
                  size: 56,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                context.l10n.t('mighty'),
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                context.l10n.t('mightyPrompt'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textGrey,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 36),

              // Quick action cards
              _QuickActionCard(
                icon: Icons.warning_amber_rounded,
                title: isAr ? "التداخلات الدوائية" : "Drug Interactions",
                subtitle: isAr
                    ? "تحقق مما إذا كانت أدويتك آمنة معاً"
                    : "Check if your drugs are safe together",
                color: const Color(0xFFFFF3E0),
                iconColor: const Color(0xFFFF9800),
              ),
              const SizedBox(height: 12),
              _QuickActionCard(
                icon: Icons.medication_rounded,
                title: isAr ? "معلومات الدواء" : "Drug Information",
                subtitle: isAr
                    ? "اسأل عن دواء معين"
                    : "Ask about a specific medication",
                color: const Color(0xFFE3F2FD),
                iconColor: const Color(0xFF2196F3),
              ),
              const SizedBox(height: 12),
              _QuickActionCard(
                icon: Icons.health_and_safety_rounded,
                title: isAr ? "الآثار الجانبية" : "Side Effects",
                subtitle: isAr
                    ? "تعرف على الآثار الجانبية المحتملة"
                    : "Learn about possible side effects",
                color: const Color(0xFFE8F5E9),
                iconColor: const Color(0xFF4CAF50),
              ),

              const Spacer(flex: 2),

              // Get Started button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => setState(() => _showChat = true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 4,
                    shadowColor: AppColors.primaryTeal.withValues(alpha: 0.3),
                  ),
                  child: Text(
                    isAr ? "بدء المحادثة" : "Start Chat",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Quick Action Card ---
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color iconColor;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isAr =
        Provider.of<LanguageProvider>(context, listen: false).currentLanguage ==
        'ar';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: AppColors.textGrey),
                ),
              ],
            ),
          ),
          Icon(
            isAr ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
            color: AppColors.textGrey.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }
}

// --- Chat Conversation View ---
class _ChatConversation extends StatefulWidget {
  final VoidCallback onBack;
  const _ChatConversation({required this.onBack});

  @override
  State<_ChatConversation> createState() => _ChatConversationState();
}

class _ChatConversationState extends State<_ChatConversation> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final List<Map<String, dynamic>> _messages;
  List<ChatConversationSummary> _conversations = const [];
  bool _isLoading = false;
  bool _historyLoading = true;
  bool _messagesLoading = false;
  String? _historyError;
  final Set<String> _deletingConversationIds = <String>{};
  String? _conversationId;

  @override
  void initState() {
    super.initState();
    final isAr =
        Provider.of<LanguageProvider>(context, listen: false).currentLanguage ==
        'ar';
    _messages = _initialMessages(isAr);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_loadConversations());
    });
  }

  List<Map<String, dynamic>> _initialMessages(bool isAr) {
    return [
      {
        'text': isAr
            ? "مرحباً! 👋 أنا مايتي، مساعدك الذكي لسلامة الأدوية. كيف يمكنني مساعدتك اليوم؟"
            : "Hello! 👋 I'm Mighty, your drug safety assistant. How can I help you today?",
        'isBot': true,
      },
    ];
  }

  String _requireToken() {
    final token = context.read<UserProvider>().token;
    if (token == null || token.isEmpty) {
      throw const ChatbotException('Authentication is required.');
    }
    return token;
  }

  Future<void> _loadConversations({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() {
        _historyLoading = true;
        _historyError = null;
      });
    }

    try {
      final conversations = await ChatbotService.getConversations(
        token: _requireToken(),
      );
      if (!mounted) return;
      setState(() {
        _conversations = conversations;
        _historyLoading = false;
        _historyError = null;
      });
    } on ChatbotException catch (error) {
      if (!mounted) return;
      setState(() {
        _historyLoading = false;
        _historyError = error.message;
      });
    }
  }

  Future<void> _openConversation(ChatConversationSummary conversation) async {
    if (_isLoading || _messagesLoading) return;
    final previousConversationId = _conversationId;
    Navigator.of(context).pop();
    setState(() {
      _messagesLoading = true;
      _conversationId = conversation.conversationId;
    });

    try {
      final messages = await ChatbotService.getMessages(
        token: _requireToken(),
        conversationId: conversation.conversationId,
      );
      if (!mounted || _conversationId != conversation.conversationId) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(
            messages.map(
              (message) => {
                'text': message.content,
                'isBot': message.isAssistant,
              },
            ),
          );
        _messagesLoading = false;
      });
      _scrollToBottom();
    } on ChatbotException catch (error) {
      if (!mounted) return;
      setState(() {
        _conversationId = previousConversationId;
        _messagesLoading = false;
      });
      _showSnackBar(error.message);
    }
  }

  void _startNewChat() {
    final isAr =
        Provider.of<LanguageProvider>(context, listen: false).currentLanguage ==
        'ar';
    setState(() {
      _conversationId = null;
      _messagesLoading = false;
      _msgController.clear();
      _messages
        ..clear()
        ..addAll(_initialMessages(isAr));
    });
    _scrollToBottom();
  }

  Future<void> _confirmDeleteConversation(
    ChatConversationSummary conversation,
  ) async {
    final isAr =
        Provider.of<LanguageProvider>(context, listen: false).currentLanguage ==
        'ar';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isAr ? 'حذف المحادثة؟' : 'Delete conversation?'),
        content: Text(
          isAr
              ? 'سيتم حذف هذه المحادثة من سجل Mighty.'
              : 'This conversation will be removed from Mighty history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(isAr ? 'إلغاء' : 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              isAr ? 'حذف' : 'Delete',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deletingConversationIds.add(conversation.conversationId));
    try {
      await ChatbotService.deleteConversation(
        token: _requireToken(),
        conversationId: conversation.conversationId,
      );
      if (!mounted) return;
      setState(() {
        _deletingConversationIds.remove(conversation.conversationId);
        _conversations = _conversations
            .where((item) => item.conversationId != conversation.conversationId)
            .toList(growable: false);
      });
      if (_conversationId == conversation.conversationId) {
        _startNewChat();
      }
    } on ChatbotException catch (error) {
      if (!mounted) return;
      setState(
        () => _deletingConversationIds.remove(conversation.conversationId),
      );
      _showSnackBar(error.message);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _openHistory(bool isAr) {
    unawaited(_loadConversations());
    if (isAr) {
      _scaffoldKey.currentState?.openDrawer();
    } else {
      _scaffoldKey.currentState?.openEndDrawer();
    }
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty || _isLoading || _messagesLoading) return;

    setState(() {
      _messages.add({'text': text, 'isBot': false});
      _msgController.clear();
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      final response = await ChatbotService.sendMessage(
        token: _requireToken(),
        message: text,
        conversationId: _conversationId,
      );
      if (!mounted) return;
      setState(() {
        _conversationId = response.conversationId;
        _messages.add({'text': response.answer, 'isBot': true});
        _isLoading = false;
      });
      unawaited(_loadConversations(showLoading: false));
    } on ChatbotException {
      if (!mounted) return;
      setState(() {
        _messages.add({'text': context.l10n.t('mightyError'), 'isBot': true});
        _isLoading = false;
      });
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAr =
        Provider.of<LanguageProvider>(context, listen: false).currentLanguage ==
        'ar';
    final historyDrawer = _ChatHistoryDrawer(
      conversations: _conversations,
      activeConversationId: _conversationId,
      isLoading: _historyLoading,
      error: _historyError,
      deletingConversationIds: _deletingConversationIds,
      isArabic: isAr,
      onRetry: _loadConversations,
      onSelect: _openConversation,
      onDelete: _confirmDeleteConversation,
      onNewChat: () {
        Navigator.of(context).pop();
        _startNewChat();
      },
    );
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.backgroundCream,
      drawer: isAr ? historyDrawer : null,
      endDrawer: isAr ? null : historyDrawer,
      appBar: AppBar(
        backgroundColor: AppColors.primaryTeal,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: widget.onBack,
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.t('mighty'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  isAr ? "نشط الآن" : "Online",
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: isAr ? 'محادثة جديدة' : 'New chat',
            onPressed: _isLoading || _messagesLoading ? null : _startNewChat,
            icon: const Icon(Icons.edit_square, color: Colors.white),
          ),
          IconButton(
            tooltip: isAr ? 'سجل المحادثات' : 'Chat history',
            onPressed: _isLoading || _messagesLoading
                ? null
                : () => _openHistory(isAr),
            icon: const Icon(Icons.history_rounded, color: Colors.white),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: _messagesLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryTeal,
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isBot = msg['isBot'] as bool;
                      return _MessageBubble(
                        text: msg['text'] as String,
                        isBot: isBot,
                      );
                    },
                  ),
          ),

          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryTeal,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    context.l10n.t('mightyLoading'),
                    style: TextStyle(color: AppColors.textGrey, fontSize: 12),
                  ),
                ],
              ),
            ),

          // Input bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.backgroundCream,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _msgController,
                        enabled: !_isLoading && !_messagesLoading,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: InputDecoration(
                          hintText: context.l10n.t('typeMessage'),
                          hintStyle: TextStyle(color: AppColors.textGrey),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Tooltip(
                    message: context.l10n.t('send'),
                    child: GestureDetector(
                      onTap: _isLoading || _messagesLoading
                          ? null
                          : _sendMessage,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _isLoading || _messagesLoading
                              ? AppColors.textGrey.withValues(alpha: 0.45)
                              : AppColors.primaryTeal,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Transform.scale(
                          scaleX: isAr ? -1 : 1,
                          child: const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Message Bubble ---
class _MessageBubble extends StatelessWidget {
  final String text;
  final bool isBot;

  const _MessageBubble({required this.text, required this.isBot});

  @override
  Widget build(BuildContext context) {
    final isArabicText = RegExp(r'[\u0600-\u06FF]').hasMatch(text);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isBot
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isBot) ...[
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.primaryTeal.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.smart_toy_rounded,
                color: AppColors.primaryTeal,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isBot ? Colors.white : AppColors.primaryTeal,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isBot ? 4 : 18),
                  bottomRight: Radius.circular(isBot ? 18 : 4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Directionality(
                    textDirection: isArabicText
                        ? TextDirection.rtl
                        : TextDirection.ltr,
                    child: Text(
                      _isolateLatinText(text),
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        color: isBot ? AppColors.textDark : Colors.white,
                        fontSize: 14,
                        height: 1.55,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _isolateLatinText(String value) {
    const leftToRightIsolate = '\u2066';
    const popDirectionalIsolate = '\u2069';
    final latinRun = RegExp(
      r'[A-Za-z][A-Za-z0-9.+/%-]*(?:[ \t]+[A-Za-z0-9][A-Za-z0-9.+/%-]*)*',
    );
    return value.replaceAllMapped(
      latinRun,
      (match) => '$leftToRightIsolate${match.group(0)}$popDirectionalIsolate',
    );
  }
}

class _ChatHistoryDrawer extends StatelessWidget {
  final List<ChatConversationSummary> conversations;
  final String? activeConversationId;
  final bool isLoading;
  final String? error;
  final Set<String> deletingConversationIds;
  final bool isArabic;
  final VoidCallback onRetry;
  final ValueChanged<ChatConversationSummary> onSelect;
  final ValueChanged<ChatConversationSummary> onDelete;
  final VoidCallback onNewChat;

  const _ChatHistoryDrawer({
    required this.conversations,
    required this.activeConversationId,
    required this.isLoading,
    required this.error,
    required this.deletingConversationIds,
    required this.isArabic,
    required this.onRetry,
    required this.onSelect,
    required this.onDelete,
    required this.onNewChat,
  });

  @override
  Widget build(BuildContext context) {
    final drawerWidth = MediaQuery.sizeOf(
      context,
    ).width.clamp(280.0, 390.0).toDouble();
    return Drawer(
      width: drawerWidth,
      backgroundColor: AppColors.backgroundCream,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 12, 10),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primaryTeal,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.forum_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isArabic ? 'محادثات Mighty' : 'Mighty chats',
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: isArabic ? 'إغلاق' : 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onNewChat,
                  icon: const Icon(Icons.add_rounded),
                  label: Text(isArabic ? 'محادثة جديدة' : 'New conversation'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryTeal,
                    side: const BorderSide(color: AppColors.primaryTeal),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Divider(color: Colors.grey.shade200, height: 1),
            Expanded(child: _buildContent(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.primaryTeal),
            const SizedBox(height: 14),
            Text(
              isArabic ? 'جارٍ تحميل المحادثات...' : 'Loading conversations...',
              style: TextStyle(color: AppColors.textGrey),
            ),
          ],
        ),
      );
    }

    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                color: AppColors.textGrey,
                size: 42,
              ),
              const SizedBox(height: 12),
              Text(
                isArabic
                    ? 'تعذر تحميل سجل المحادثات.'
                    : 'Could not load chat history.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(isArabic ? 'إعادة المحاولة' : 'Try again'),
              ),
            ],
          ),
        ),
      );
    }

    if (conversations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.chat_bubble_outline_rounded,
                color: AppColors.primaryTeal.withValues(alpha: 0.55),
                size: 48,
              ),
              const SizedBox(height: 14),
              Text(
                isArabic
                    ? 'لا توجد محادثات سابقة بعد.'
                    : 'No previous conversations yet.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textGrey),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primaryTeal,
      onRefresh: () async => onRetry(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 24),
        itemCount: conversations.length,
        separatorBuilder: (_, _) => const SizedBox(height: 6),
        itemBuilder: (context, index) {
          final conversation = conversations[index];
          final isActive = conversation.conversationId == activeConversationId;
          final isDeleting = deletingConversationIds.contains(
            conversation.conversationId,
          );
          return Material(
            color: isActive
                ? AppColors.primaryTeal.withValues(alpha: 0.10)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: isDeleting ? null : () => onSelect(conversation),
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 11, 4, 11),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            conversation.title.isEmpty
                                ? (isArabic ? 'محادثة Mighty' : 'Mighty chat')
                                : conversation.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.textDark,
                              fontSize: 14,
                              fontWeight: isActive
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                            ),
                          ),
                          if (conversation.lastMessage.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              conversation.lastMessage,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.textGrey,
                                fontSize: 12,
                                height: 1.3,
                              ),
                            ),
                          ],
                          const SizedBox(height: 6),
                          Text(
                            _formatDate(conversation.updatedAt),
                            style: TextStyle(
                              color: AppColors.textGrey.withValues(alpha: 0.8),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isDeleting)
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 17,
                          height: 17,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primaryTeal,
                          ),
                        ),
                      )
                    else
                      IconButton(
                        tooltip: isArabic ? 'حذف' : 'Delete',
                        onPressed: () => onDelete(conversation),
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.red.shade400,
                          size: 20,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    final year = local.year.toString().padLeft(4, '0');
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$year/$month/$day • $hour:$minute';
  }
}
