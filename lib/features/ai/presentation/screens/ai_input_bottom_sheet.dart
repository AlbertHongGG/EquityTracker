import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/features/ai/presentation/controllers/ai_session_controller.dart';
import 'package:equity_tracker/features/ai/presentation/controllers/ai_config_controller.dart';
import 'package:equity_tracker/features/ai/usecases/process_expense_usecase.dart';
import 'package:equity_tracker/core/theme/app_colors.dart';
import 'package:equity_tracker/core/logging/presentation/screens/api_log_viewer_screen.dart';
import 'package:equity_tracker/features/transaction/data/transaction_model.dart';
import 'package:equity_tracker/features/ai/presentation/widgets/thinking_orb.dart';
import 'package:equity_tracker/core/voice/controllers/voice_controller.dart';
import 'package:go_router/go_router.dart';
import 'package:equity_tracker/core/notifications/providers/notification_providers.dart';
import 'dart:math' as math;

void showAiInputBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const AiInputBottomSheet(),
  );
}

class AiInputBottomSheet extends ConsumerStatefulWidget {
  const AiInputBottomSheet({super.key});

  @override
  ConsumerState<AiInputBottomSheet> createState() => _AiInputBottomSheetState();
}

class _AiInputBottomSheetState extends ConsumerState<AiInputBottomSheet> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ScrollController _textFieldScrollController = ScrollController();
  String _baseTypedText = '';

  @override
  void initState() {
    super.initState();
    // Initialize speech engine early
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(voiceControllerProvider.notifier).initialize();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutQuart,
        );
      }
    });
  }

  void _scrollTextFieldToRight() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_textFieldScrollController.hasClients) {
        _textFieldScrollController.animateTo(
          _textFieldScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSubmit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final sessionState = ref.read(aiSessionControllerProvider);

    if (sessionState.pendingAction == null) {
      ref.read(aiSessionControllerProvider.notifier).startSession(text);
    } else {
      ref.read(aiSessionControllerProvider.notifier).submitAnswer(text);
    }
    
    _controller.clear();
    _baseTypedText = '';
    ref.read(voiceControllerProvider.notifier).clearText();
  }

  void _handleMicToggle(bool isCurrentlyListening) {
    if (!isCurrentlyListening) {
      // 即將開始語音：將目前輸入框的字鎖定為 _baseTypedText
      _baseTypedText = _controller.text.trim();
    }
    ref.read(voiceControllerProvider.notifier).toggleListening();
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(aiSessionControllerProvider);
    final aiConfig = ref.watch(aiConfigControllerProvider);
    final voiceState = ref.watch(voiceControllerProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    ref.listen<AISessionState>(aiSessionControllerProvider, (_, __) => _scrollToBottom());
    
    ref.listen<VoiceState>(voiceControllerProvider, (previous, next) {
      if (next.recognizedText != previous?.recognizedText) {
        final newText = _baseTypedText.isEmpty 
            ? next.recognizedText 
            : (_baseTypedText + (next.recognizedText.isNotEmpty ? ' ${next.recognizedText}' : ''));
            
        if (_controller.text != newText) {
          _controller.text = newText;
          _controller.selection = TextSelection.fromPosition(
            TextPosition(offset: _controller.text.length)
          );
          _scrollTextFieldToRight();
        }
      }
      if (next.hasError && !(previous?.hasError ?? false)) {
        ref.read(inAppNotificationServiceProvider).showError('無法啟動語音辨識，請確認麥克風權限或系統是否支援。');
      }
    });

    final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;
    
    return Padding(
      padding: EdgeInsets.only(
        bottom: keyboardHeight,
      ),
      child: Container(
        height: math.max(0.0, (MediaQuery.sizeOf(context).height * 0.85) - keyboardHeight),
        decoration: BoxDecoration(
          color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 40,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(isDark),
            if (!aiConfig.isAIAgentEnabled)
              Expanded(child: _buildDisabledState(context, isDark))
            else ...[
              Expanded(
                child: Container(
                  color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.5),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    itemCount: sessionState.messages.length + 
                               (sessionState.isProcessing ? 1 : 0) + 
                               (sessionState.pendingAction != null ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index < sessionState.messages.length) {
                        return _buildChatBubble(sessionState.messages[index], isDark);
                      }
                      
                      int offset = sessionState.messages.length;
                      
                      if (sessionState.isProcessing) {
                        if (index == offset) {
                          return _buildThinkingBubble(sessionState, isDark);
                        }
                        offset++;
                      }
                      
                      if (sessionState.pendingAction != null) {
                        if (index == offset) {
                          return _buildActionCard(context, sessionState.pendingAction!, isDark);
                        }
                      }
                      
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),

              _buildInputArea(sessionState, voiceState, isDark),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDisabledState(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.power_off_rounded,
                size: 64,
                color: Theme.of(context).primaryColor.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'AI Feature Disabled',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'The AI Smart Accounting assistant is currently disabled. You can enable it in the configuration settings.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.black54,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.auto_awesome, color: Theme.of(context).primaryColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'AI 智慧記帳',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(Icons.terminal_rounded, color: isDark ? Colors.white54 : Colors.black54),
                tooltip: 'Developer Logs',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ApiLogViewerScreen()),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage message, bool isDark) {
    final isUser = message.type == ChatMessageType.user;
    final isError = message.type == ChatMessageType.error;
    final isSystem = message.type == ChatMessageType.system;

    if (isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              message.text,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: isError ? Colors.red.withValues(alpha: 0.1) : Theme.of(context).primaryColor.withValues(alpha: 0.1),
              child: Icon(
                isError ? Icons.error_outline : Icons.smart_toy_rounded, 
                size: 16, 
                color: isError ? Colors.red : Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser 
                    ? Theme.of(context).primaryColor 
                    : (isError 
                        ? Colors.red.withValues(alpha: 0.1) 
                        : (isDark ? AppColors.surfaceDark : Colors.white)),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
                boxShadow: isUser || isError ? [] : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: (message.payload != null && message.payload is List) 
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.text,
                          style: TextStyle(
                            fontSize: 15,
                            color: isUser 
                                ? Colors.white 
                                : (isError 
                                    ? Colors.red 
                                    : (isDark ? Colors.white : Colors.black87)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...((message.payload as List).map((dynamic item) {
                          if (item is! TransactionModel) return const SizedBox();
                          final tx = item;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  // Close bottom sheet if necessary, or just push. Let's close it first so it doesn't linger
                                  Navigator.of(context).pop();
                                  context.push('/add-transaction', extra: {'transaction': tx});
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isDark ? Colors.white12 : Colors.black12,
                                    ),
                                  ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.receipt_long, size: 16, color: Theme.of(context).primaryColor),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tx.title ?? '未命名',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        tx.note ?? '',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark ? Colors.white54 : Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '\$${tx.amount.toInt()}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Outfit',
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  })),
                      ],
                    )
                  : Text(
                      message.text,
                      style: TextStyle(
                        fontSize: 15,
                        color: isUser 
                            ? Colors.white 
                            : (isError 
                                ? Colors.red 
                                : (isDark ? Colors.white : Colors.black87)),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThinkingBubble(AISessionState sessionState, bool isDark) {
    if (!sessionState.isProcessing) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            child: Icon(Icons.smart_toy_outlined, size: 16, color: Theme.of(context).primaryColor),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                  bottomLeft: Radius.circular(4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ThinkingOrb(isDark: isDark, size: 24.0),
                      const SizedBox(width: 12),
                      Text(
                        'AI 思考中...',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                  if (sessionState.thinkingSteps.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ...sessionState.thinkingSteps.map((step) => Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.check_circle_outline, size: 12, color: isDark ? Colors.white54 : Colors.black54),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              step,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white54 : Colors.black54,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, UseCaseResult action, bool isDark) {
    if (action is RequireStoreSelectionResult) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.storefront_rounded, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    action.message,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            if (action.options.isNotEmpty) ...[
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: action.options.map((option) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ActionChip(
                        label: Text(option),
                        labelStyle: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                        backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        onPressed: () {
                          _controller.text = option;
                          _handleSubmit();
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      );
    } else if (action is RequireCorrectionResult) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.help_outline_rounded, color: Colors.orange),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                action.question,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox();
  }

  Widget _buildInputArea(AISessionState sessionState, VoiceState voiceState, bool isDark) {
    
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.black.withValues(alpha: 0.2) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? Colors.white12 : Colors.black12,
                  ),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        scrollController: _textFieldScrollController,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        decoration: InputDecoration(
                          hintText: voiceState.isListening 
                              ? '聆聽中...' 
                              : (sessionState.pendingAction != null ? '請輸入回答...' : '例如：午餐吃雞腿便當 100 元'),
                          hintStyle: TextStyle(
                            color: voiceState.isListening ? Theme.of(context).primaryColor : (isDark ? Colors.white30 : Colors.black38),
                          ),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _handleSubmit(),
                      ),
                    ),
                    if (voiceState.isListening)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: ThinkingOrb(isDark: isDark, size: 24),
                      ),
                    GestureDetector(
                      onLongPress: () {
                        if (!voiceState.isListening) {
                          _handleMicToggle(voiceState.isListening);
                        }
                      },
                      onLongPressUp: () {
                        ref.read(voiceControllerProvider.notifier).stopListening();
                      },
                      onTap: () {
                        _handleMicToggle(voiceState.isListening);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: voiceState.isListening ? Theme.of(context).primaryColor.withValues(alpha: 0.1) : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          voiceState.isListening ? Icons.mic : Icons.mic_none,
                          color: voiceState.isListening ? Theme.of(context).primaryColor : (isDark ? Colors.white54 : Colors.black54),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.send_rounded, color: Theme.of(context).primaryColor),
                      onPressed: _handleSubmit,
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
