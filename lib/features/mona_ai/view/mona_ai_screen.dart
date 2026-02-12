import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/gpt_service.dart';
import '../../../core/services/voice_service.dart';
import '../../../core/models/app_language.dart';

/// MonaAI Screen - Instant AI-powered parenting assistant
class MonaAIScreen extends StatefulWidget {
  const MonaAIScreen({super.key});

  @override
  State<MonaAIScreen> createState() => _MonaAIScreenState();
}

class _MonaAIScreenState extends State<MonaAIScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GPTService _gptService = GPTService();
  final VoiceService _voiceService = VoiceService();
  final List<ChatMessage> _messages = [];
  final List<Map<String, String>> _conversationHistory = [];
  bool _isTyping = false;
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _voiceEnabled = true; // Auto-speak responses
  AppLanguage _selectedLanguage = AppLanguage.english;
  bool _hasInputText = false;
  final Map<AppLanguage, List<String>> _promptTextCache = {};
  bool _isPromptTranslationLoading = false;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(() {
      final hasText = _messageController.text.trim().isNotEmpty;
      if (_hasInputText != hasText && mounted) {
        setState(() => _hasInputText = hasText);
      }
    });
    // Add welcome message
    _messages.add(ChatMessage(
      text:
          "Hi! I'm Mona, your AI parenting assistant 👋\n\nI can help you with:\n• Baby health questions\n• Nutrition advice\n• Sleep tips\n• Development milestones\n• And much more!\n\nHow can I help you today?",
      isUser: false,
      timestamp: DateTime.now(),
    ));

    _promptTextCache[AppLanguage.english] = _QuickSuggestions.baseSuggestions
        .map((item) => item['text'] as String)
        .toList(growable: false);
    _loadCachedPromptTranslations();
  }

  Future<void> _loadCachedPromptTranslations() async {
    final prefs = await SharedPreferences.getInstance();
    for (final language in AppLanguage.values) {
      if (language == AppLanguage.english) continue;
      final raw = prefs.getString('mona_quick_prompts_${language.code}');
      if (raw == null || raw.isEmpty) continue;
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List &&
            decoded.length == _QuickSuggestions.baseSuggestions.length) {
          final texts =
              decoded.map((e) => e.toString()).toList(growable: false);
          if (texts.every((text) => text.trim().isNotEmpty)) {
            _promptTextCache[language] = texts;
          }
        }
      } catch (_) {}
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _saveCachedPromptTranslations(
    AppLanguage language,
    List<String> prompts,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'mona_quick_prompts_${language.code}',
      jsonEncode(prompts),
    );
  }

  List<Map<String, dynamic>> _localizedQuickSuggestions() {
    final base = _QuickSuggestions.baseSuggestions;
    final localized = _promptTextCache[_selectedLanguage];
    if (localized == null || localized.length != base.length) {
      return base;
    }
    return List.generate(base.length, (index) {
      return {
        'icon': base[index]['icon'],
        'text': localized[index],
      };
    });
  }

  Future<void> _ensureQuickPromptsForLanguage(AppLanguage language) async {
    if (language == AppLanguage.english) return;
    if (_promptTextCache.containsKey(language)) return;
    if (!_gptService.hasApiKey) return;

    setState(() => _isPromptTranslationLoading = true);
    try {
      final source = _QuickSuggestions.baseSuggestions
          .map((item) => item['text'] as String)
          .toList(growable: false);
      final translated = await _gptService.translateQuickPrompts(
        phrases: source,
        language: language,
      );
      if (!mounted) return;
      setState(() {
        _promptTextCache[language] = translated;
      });
      await _saveCachedPromptTranslations(language, translated);
    } catch (_) {
      // Keep English prompts if translation fails.
    } finally {
      if (mounted) {
        setState(() => _isPromptTranslationLoading = false);
      }
    }
  }

  void _resetConversation() {
    setState(() {
      _messages
        ..clear()
        ..add(
          ChatMessage(
            text:
                "Hi! I'm Mona, your AI parenting assistant 👋\n\nI can help you with:\n• Baby health questions\n• Nutrition advice\n• Sleep tips\n• Development milestones\n• And much more!\n\nHow can I help you today?",
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      _conversationHistory.clear();
      _isTyping = false;
      _messageController.clear();
    });
  }

  void _showChatActions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading:
                  const Icon(Icons.refresh_rounded, color: AppColors.primary),
              title: const Text('Start new chat'),
              onTap: () {
                Navigator.pop(context);
                _resetConversation();
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.volume_up_rounded,
                color: AppColors.secondary,
              ),
              title: Text(_voiceEnabled
                  ? 'Disable voice responses'
                  : 'Enable voice responses'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _voiceEnabled = !_voiceEnabled);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = _messageController.text.trim();
    setState(() {
      _messages.add(ChatMessage(
        text: userMessage,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isTyping = true;
    });
    _messageController.clear();

    // Scroll to bottom
    _scrollToBottom();

    // Get AI response
    try {
      String response;
      if (_gptService.hasApiKey) {
        // Use GPT-4o for real response
        response = await _gptService.chat(
          userMessage: userMessage,
          conversationHistory: _conversationHistory,
          language: _selectedLanguage,
        );
        // Add to conversation history for context
        _conversationHistory.add({'role': 'user', 'content': userMessage});
        _conversationHistory.add({'role': 'assistant', 'content': response});
        // Keep only last 10 messages for context
        if (_conversationHistory.length > 20) {
          _conversationHistory.removeRange(0, 2);
        }
      } else {
        // Fallback to demo responses
        response = _getFallbackResponse(userMessage);
      }

      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add(ChatMessage(
            text: response,
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });
        _scrollToBottom();

        // Auto-speak the response instantly if voice is enabled
        if (_voiceEnabled && _voiceService.hasApiKey) {
          _speakResponse(response); // Don't await - speak instantly
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add(ChatMessage(
            text:
                "I'm having trouble connecting right now. Please try again in a moment. 🙏",
            isUser: false,
            timestamp: DateTime.now(),
            isError: true,
          ));
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _getFallbackResponse(String question) {
    // Fallback demo responses when API key is not configured
    final lowerQuestion = question.toLowerCase();
    if (lowerQuestion.contains('fever') ||
        lowerQuestion.contains('temperature')) {
      return "For babies, a temperature above 100.4°F (38°C) is considered a fever. Here's what you can do:\n\n• Keep your baby hydrated\n• Dress in light clothing\n• Use a lukewarm sponge bath\n• Consult a doctor if fever persists\n\n⚠️ For babies under 3 months with fever, please consult a pediatrician immediately.";
    } else if (lowerQuestion.contains('sleep') ||
        lowerQuestion.contains('night')) {
      return "Sleep is crucial for your baby's development! Here are some tips:\n\n• Establish a bedtime routine\n• Keep the room dark and quiet\n• Put baby down drowsy but awake\n• Maintain consistent sleep times\n\nAt 6 months, babies typically need 14-15 hours of sleep including naps. 💤";
    } else if (lowerQuestion.contains('food') ||
        lowerQuestion.contains('eat') ||
        lowerQuestion.contains('feed')) {
      return "Great question about nutrition! 🍎\n\nAt 6 months, you can start introducing:\n• Single-grain cereals\n• Pureed fruits (banana, apple)\n• Pureed vegetables (carrots, sweet potato)\n\nRemember: One new food at a time, wait 3-4 days before introducing another to watch for allergies.";
    } else {
      return "That's a great question! While I'm here to provide general guidance, for specific medical concerns, I always recommend consulting with your pediatrician.\n\nIs there anything specific about your baby's health, nutrition, or development I can help with? 😊";
    }
  }

  void _showLanguageSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.translate_rounded, color: AppColors.primary),
                const SizedBox(width: 12),
                const Text(
                  'Select Language',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Mona will respond in your selected language',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: AppLanguage.values.length,
                itemBuilder: (context, index) {
                  final lang = AppLanguage.values[index];
                  final isSelected = _selectedLanguage == lang;
                  return ListTile(
                    onTap: () {
                      setState(() => _selectedLanguage = lang);
                      Navigator.pop(context);
                      _ensureQuickPromptsForLanguage(lang);
                      // Add language change message
                      if (lang != AppLanguage.english) {
                        _messages.add(ChatMessage(
                          text:
                              "Language changed to ${lang.nativeName}. I'll now respond in ${lang.englishName}! 🌐",
                          isUser: false,
                          timestamp: DateTime.now(),
                        ));
                        _scrollToBottom();
                      }
                    },
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          lang.nativeName.substring(0, 1),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      lang.englishName,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      lang.nativeName,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check_circle_rounded,
                            color: AppColors.primary)
                        : null,
                  );
                },
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Future<void> _startVoiceInput() async {
    // Request microphone permission
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microphone permission required for voice input'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    try {
      setState(() => _isListening = true);
      await _voiceService.startListening(
        onResult: (text) {
          setState(() {
            _isListening = false;
            _messageController.text = text;
          });
          // Auto-send the message
          if (text.isNotEmpty) {
            _sendMessage();
          }
        },
        language: _selectedLanguage,
      );
    } catch (e) {
      setState(() => _isListening = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Voice input error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _stopVoiceInput() async {
    await _voiceService.stopListening();
    setState(() => _isListening = false);
  }

  void _speakResponse(String text) {
    if (!_voiceService.hasApiKey) return;

    setState(() => _isSpeaking = true);

    // Start speaking immediately without blocking
    _voiceService.speak(text, language: _selectedLanguage).then((_) {
      if (mounted) {
        setState(() => _isSpeaking = false);
      }
    }).catchError((e) {
      if (mounted) {
        setState(() => _isSpeaking = false);
      }
    });
  }

  Future<void> _stopSpeaking() async {
    await _voiceService.stopSpeaking();
    setState(() => _isSpeaking = false);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _voiceService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFF3FBF8),
                    Color(0xFFF4F9FF),
                    Color(0xFFF7F8FF),
                  ],
                ),
              ),
            ),
          ),
          const Positioned(
            top: -120,
            right: -70,
            child: _AiBackdropBlob(
              size: 220,
              colors: [Color(0xFFD9F4EC), Color(0xFFE0EDFF)],
            ),
          ),
          const Positioned(
            bottom: -140,
            left: -80,
            child: _AiBackdropBlob(
              size: 260,
              colors: [Color(0xFFE7DEFB), Color(0xFFF9E6ED)],
            ),
          ),
          Column(
            children: [
              // Chat messages
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(14, 18, 14, 18),
                  itemCount: _messages.length + (_isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (_isTyping && index == _messages.length) {
                      return _TypingIndicator();
                    }
                    return _ChatBubble(message: _messages[index]);
                  },
                ),
              ),

              // Quick suggestions
              if (_messages.length <= 2)
                _QuickSuggestions(
                  suggestions: _localizedQuickSuggestions(),
                  isLoadingTranslations: _isPromptTranslationLoading,
                  onTap: (text) {
                    _messageController.text = text;
                    _sendMessage();
                  },
                ),

              // Input area
              _MessageInput(
                controller: _messageController,
                onSend: _sendMessage,
                onVoiceStart: _startVoiceInput,
                onVoiceStop: _stopVoiceInput,
                onToggleVoice: () {
                  if (_isSpeaking) {
                    _stopSpeaking();
                  } else {
                    setState(() => _voiceEnabled = !_voiceEnabled);
                  }
                },
                isListening: _isListening,
                isSpeaking: _isSpeaking,
                voiceEnabled: _voiceEnabled,
                hasVoiceApi: _voiceService.hasApiKey,
                canSend: _hasInputText,
              ),
            ],
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.surface.withValues(alpha: 0.96),
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon:
            const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
      ),
      title: Row(
        children: [
          // Mona Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/images/mona_avatar.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'MonaAI',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Online • Instant help',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      actions: [
        // Language selector button
        GestureDetector(
          onTap: _showLanguageSelector,
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.translate_rounded,
                    size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  _selectedLanguage.code.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
        IconButton(
          onPressed: _showChatActions,
          icon: const Icon(Icons.more_vert_rounded,
              color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _AiBackdropBlob extends StatelessWidget {
  final double size;
  final List<Color> colors;

  const _AiBackdropBlob({required this.size, required this.colors});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: colors
                .map((c) => c.withValues(alpha: 0.8))
                .toList(growable: false),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// CHAT MESSAGE MODEL
// ============================================================================

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isError;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isError = false,
  });
}

// ============================================================================
// CHAT BUBBLE
// ============================================================================

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final timeLabel =
        '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.76,
            ),
            child: Column(
              crossAxisAlignment: message.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: message.isUser
                        ? const LinearGradient(
                            colors: [Color(0xFF2C9C77), Color(0xFF1F6C57)],
                          )
                        : null,
                    color: message.isUser ? null : AppColors.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(message.isUser ? 18 : 6),
                      bottomRight: Radius.circular(message.isUser ? 6 : 18),
                    ),
                    border: message.isUser
                        ? null
                        : Border.all(
                            color: AppColors.primary.withValues(alpha: 0.12),
                          ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (message.isUser ? AppColors.primary : Colors.black)
                                .withValues(alpha: 0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      fontSize: 15,
                      color:
                          message.isUser ? Colors.white : AppColors.textPrimary,
                      height: 1.42,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timeLabel,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textHint.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded,
                  color: Colors.white, size: 12),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// TYPING INDICATOR
// ============================================================================

class _TypingIndicator extends StatefulWidget {
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 16,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: AppColors.primary.withValues(alpha: 0.14)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.07),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Row(
                      children: List.generate(3, (index) {
                        final delay = index * 0.2;
                        final value = ((_controller.value + delay) % 1.0);
                        final opacity = 0.3 +
                            (0.7 * (value < 0.5 ? value * 2 : 2 - value * 2));
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: opacity),
                            shape: BoxShape.circle,
                          ),
                        );
                      }),
                    );
                  },
                ),
                const SizedBox(width: 10),
                const Text(
                  'Mona is thinking...',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// QUICK SUGGESTIONS
// ============================================================================

class _QuickSuggestions extends StatelessWidget {
  final List<Map<String, dynamic>> suggestions;
  final bool isLoadingTranslations;
  final Function(String) onTap;

  const _QuickSuggestions({
    required this.suggestions,
    required this.onTap,
    this.isLoadingTranslations = false,
  });

  static const List<Map<String, dynamic>> baseSuggestions = [
    {'icon': Icons.thermostat_rounded, 'text': 'My baby has a fever'},
    {'icon': Icons.nightlight_rounded, 'text': 'Sleep tips for baby'},
    {'icon': Icons.restaurant_rounded, 'text': 'What foods to introduce?'},
    {'icon': Icons.child_care_rounded, 'text': 'Developmental milestones'},
    {'icon': Icons.vaccines_rounded, 'text': 'Which vaccine is due next?'},
    {'icon': Icons.coronavirus_rounded, 'text': 'Cold and cough home care'},
    {
      'icon': Icons.medication_liquid_rounded,
      'text': 'Safe fever medicine dose?'
    },
    {
      'icon': Icons.sentiment_dissatisfied_rounded,
      'text': 'Baby crying at night'
    },
    {'icon': Icons.opacity_rounded, 'text': 'Is my baby dehydrated?'},
    {
      'icon': Icons.baby_changing_station_rounded,
      'text': 'Green stool is normal?'
    },
    {'icon': Icons.mood_bad_rounded, 'text': 'Teething pain relief tips'},
    {'icon': Icons.no_meals_rounded, 'text': 'My baby is not eating well'},
    {'icon': Icons.local_hospital_rounded, 'text': 'When to go to emergency?'},
    {'icon': Icons.healing_rounded, 'text': 'My baby has loose motions'},
    {'icon': Icons.sick_rounded, 'text': 'Baby vomiting after feeding'},
    {'icon': Icons.bedtime_rounded, 'text': 'How many naps are normal?'},
    {'icon': Icons.bed_rounded, 'text': 'Baby wakes every hour at night'},
    {
      'icon': Icons.water_drop_rounded,
      'text': 'How much water should baby drink?'
    },
    {
      'icon': Icons.local_drink_rounded,
      'text': 'Breastfeeding frequency by age'
    },
    {
      'icon': Icons.baby_changing_station_rounded,
      'text': 'Constipation in babies what to do'
    },
    {'icon': Icons.warning_amber_rounded, 'text': 'Rash on baby skin causes?'},
    {'icon': Icons.air_rounded, 'text': 'Blocked nose home remedies'},
    {'icon': Icons.monitor_weight_rounded, 'text': 'Baby weight gain is low'},
    {'icon': Icons.height_rounded, 'text': 'Baby height growth concern'},
    {'icon': Icons.egg_alt_rounded, 'text': 'Egg and allergen introduction'},
    {'icon': Icons.no_food_rounded, 'text': 'Baby refusing solid foods'},
    {'icon': Icons.medication_rounded, 'text': 'Can I give paracetamol now?'},
    {'icon': Icons.wb_sunny_rounded, 'text': 'Safe sun exposure for baby'},
    {'icon': Icons.child_friendly_rounded, 'text': 'When does teething start?'},
    {
      'icon': Icons.face_retouching_natural_rounded,
      'text': 'Oral thrush signs in baby'
    },
    {'icon': Icons.music_note_rounded, 'text': 'How to calm a fussy baby?'},
    {
      'icon': Icons.psychology_alt_rounded,
      'text': 'Is speech delay a concern?'
    },
    {
      'icon': Icons.accessibility_new_rounded,
      'text': 'When should baby start walking?'
    },
    {
      'icon': Icons.child_friendly_rounded,
      'text': 'Newborn not latching properly'
    },
    {'icon': Icons.bedtime_rounded, 'text': 'Newborn day-night confusion'},
    {'icon': Icons.vaccines_rounded, 'text': '2 month vaccine side effects'},
    {
      'icon': Icons.monitor_weight_rounded,
      'text': 'Poor weight gain in infant'
    },
    {'icon': Icons.food_bank_rounded, 'text': 'Best first foods at 6 months'},
    {
      'icon': Icons.local_drink_rounded,
      'text': 'How to wean from breastfeeding'
    },
    {'icon': Icons.no_meals_rounded, 'text': 'Toddler picky eating solutions'},
    {'icon': Icons.nightlight_rounded, 'text': 'Toddler bedtime routine ideas'},
    {
      'icon': Icons.sports_handball_rounded,
      'text': 'Toddler hitting and biting behavior'
    },
    {
      'icon': Icons.record_voice_over_rounded,
      'text': '2 year old speech not clear'
    },
    {'icon': Icons.school_rounded, 'text': 'School-age child frequent colds'},
    {'icon': Icons.psychology_rounded, 'text': 'Child anxiety before school'},
    {'icon': Icons.menu_book_rounded, 'text': 'Improving focus for studies'},
    {
      'icon': Icons.screen_lock_portrait_rounded,
      'text': 'Safe screen time by age'
    },
    {'icon': Icons.sports_soccer_rounded, 'text': 'Sports nutrition for kids'},
    {
      'icon': Icons.self_improvement_rounded,
      'text': 'Teen sleep schedule problems'
    },
    {
      'icon': Icons.psychology_alt_rounded,
      'text': 'Teen stress and mood swings'
    },
    {'icon': Icons.face_rounded, 'text': 'Teen acne care basics'},
    {'icon': Icons.monitor_heart_rounded, 'text': 'When to do health checkups'},
    {
      'icon': Icons.family_restroom_rounded,
      'text': 'Sibling jealousy handling tips'
    },
  ];

  void _showAllPrompts(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          child: Column(
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'All one-tap prompts',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: suggestions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final suggestion = suggestions[index];
                    return _PromptTile(
                      icon: suggestion['icon'] as IconData,
                      text: suggestion['text'] as String,
                      onTap: () {
                        Navigator.pop(context);
                        onTap(suggestion['text'] as String);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Try one-tap prompts',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => _showAllPrompts(context),
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'View all',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          if (isLoadingTranslations)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'Updating prompts for selected language...',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textHint,
                ),
              ),
            ),
          const SizedBox(height: 8),
          SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: suggestions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final suggestion = suggestions[index];
                return SizedBox(
                  width: 192,
                  child: _PromptTile(
                    icon: suggestion['icon'] as IconData,
                    text: suggestion['text'] as String,
                    onTap: () => onTap(suggestion['text'] as String),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PromptTile extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const _PromptTile({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFFFFF), Color(0xFFF2F8FF)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.09),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 18,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// MESSAGE INPUT WITH VOICE
// ============================================================================

class _MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onVoiceStart;
  final VoidCallback onVoiceStop;
  final VoidCallback onToggleVoice;
  final bool isListening;
  final bool isSpeaking;
  final bool voiceEnabled;
  final bool hasVoiceApi;
  final bool canSend;

  const _MessageInput({
    required this.controller,
    required this.onSend,
    required this.onVoiceStart,
    required this.onVoiceStop,
    required this.onToggleVoice,
    required this.isListening,
    required this.isSpeaking,
    required this.voiceEnabled,
    required this.hasVoiceApi,
    required this.canSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          14, 10, 14, MediaQuery.of(context).padding.bottom + 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(color: AppColors.primary.withValues(alpha: 0.14)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isListening || isSpeaking)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isListening
                    ? AppColors.error.withValues(alpha: 0.12)
                    : AppColors.secondary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isListening ? Icons.mic_rounded : Icons.volume_up_rounded,
                    size: 16,
                    color: isListening ? AppColors.error : AppColors.secondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isListening ? 'Listening now...' : 'Reading response...',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color:
                          isListening ? AppColors.error : AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              GestureDetector(
                onTap: hasVoiceApi ? onToggleVoice : null,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: hasVoiceApi && voiceEnabled
                        ? AppColors.primary.withValues(alpha: 0.14)
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    hasVoiceApi
                        ? (voiceEnabled
                            ? Icons.volume_up_rounded
                            : Icons.volume_off_rounded)
                        : Icons.add_rounded,
                    color: hasVoiceApi && voiceEnabled
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.12),
                    ),
                  ),
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText:
                          'Ask Mona about health, sleep, food, milestones...',
                      hintStyle: TextStyle(
                        color: AppColors.textHint,
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => canSend ? onSend() : null,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: isListening ? onVoiceStop : onVoiceStart,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isListening
                        ? AppColors.error
                        : AppColors.secondary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isListening ? Icons.stop_rounded : Icons.mic_rounded,
                    color: isListening ? Colors.white : AppColors.secondary,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: canSend
                      ? const LinearGradient(
                          colors: [Color(0xFF2C9C77), Color(0xFF1E6B55)],
                        )
                      : null,
                  color: canSend ? null : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: canSend
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.32),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : [],
                ),
                child: IconButton(
                  onPressed: canSend ? onSend : null,
                  icon: Icon(
                    Icons.arrow_upward_rounded,
                    color: canSend ? Colors.white : AppColors.textHint,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
