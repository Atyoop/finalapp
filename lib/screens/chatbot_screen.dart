import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';
import '../providers/language_provider.dart';

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
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final List<Map<String, dynamic>> _messages;

  @override
  void initState() {
    super.initState();
    final isAr =
        Provider.of<LanguageProvider>(context, listen: false).currentLanguage ==
        'ar';
    _messages = [
      {
        'text': isAr
            ? "مرحباً! 👋 أنا مايتي، مساعدك الذكي لسلامة الأدوية. كيف يمكنني مساعدتك اليوم؟"
            : "Hello! 👋 I'm Mighty, your drug safety assistant. How can I help you today?",
        'isBot': true,
      },
    ];
  }

  void _sendMessage() {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    final isAr =
        Provider.of<LanguageProvider>(context, listen: false).currentLanguage ==
        'ar';

    setState(() {
      _messages.add({'text': text, 'isBot': false});
      _msgController.clear();
    });

    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });

    // Simulate bot reply
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        _messages.add({'text': _getBotReply(text, isAr), 'isBot': true});
      });
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    });
  }

  String _getBotReply(String userMsg, bool isAr) {
    final msg = userMsg.toLowerCase();
    final isInteraction =
        msg.contains('interaction') ||
        msg.contains('mix') ||
        msg.contains('تفاعل') ||
        msg.contains('خلط') ||
        msg.contains('مع بعض');
    final isSideEffect =
        msg.contains('side effect') ||
        msg.contains('sideeffect') ||
        msg.contains('جانبي') ||
        msg.contains('عرض') ||
        msg.contains('أعراض');
    final isDosage =
        msg.contains('dosage') ||
        msg.contains('dose') ||
        msg.contains('جرعة') ||
        msg.contains('كمية') ||
        msg.contains('طريقة');
    final isGreeting =
        msg.contains('hello') ||
        msg.contains('hi') ||
        msg.contains('مرحبا') ||
        msg.contains('أهلا') ||
        msg.contains('سلام');

    if (isInteraction) {
      return isAr
          ? "⚠️ التداخلات الدوائية قد تكون خطيرة. يرجى إخباري بالدواءين اللذين ترغب في فحصهما، وسأبحث عن أي تداخلات معروفة بينهما."
          : "⚠️ Drug interactions can be dangerous. Please tell me the two medications you'd like to check, and I'll look up any known interactions.";
    } else if (isSideEffect) {
      return isAr
          ? "تختلف الآثار الجانبية حسب كل دواء. ما هو الدواء الذي ترغب في معرفة آثاره الجانبية؟ يمكنني تزويدك بالآثار الجانبية الشائعة والنادرة."
          : "Side effects vary by medication. Which drug would you like to know about? I can provide common and rare side effects.";
    } else if (isDosage) {
      return isAr
          ? "💊 تعتمد الجرعة على عوامل كثيرة بما في ذلك العمر والوزن والحالة الصحية. يرجى استشارة طبيبك للحصول على جرعة مخصصة لك. عن أي دواء تسأل؟"
          : "💊 Dosage depends on many factors including age, weight, and condition. Please consult your doctor for personalized dosage. Which drug are you asking about?";
    } else if (isGreeting) {
      return isAr
          ? "أهلاً بك! كيف يمكنني مساعدتك في شؤون أدويتك اليوم؟"
          : "Hi there! How can I assist you with your medications today?";
    } else {
      return isAr
          ? "شكراً لسؤالك! يمكنني مساعدتك في فحص التداخلات الدوائية، والآثار الجانبية، ومعلومات الأدوية العامة. هل يمكنك تحديد ما تود معرفته بدقة؟"
          : "Thanks for your question! I can help with drug interactions, side effects, and general medication info. Could you be more specific about what you'd like to know?";
    }
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
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
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
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isBot = msg['isBot'] as bool;
                return _MessageBubble(text: msg['text'], isBot: isBot);
              },
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
                      onTap: _sendMessage,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primaryTeal,
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
              child: Text(
                text,
                style: TextStyle(
                  color: isBot ? AppColors.textDark : Colors.white,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
