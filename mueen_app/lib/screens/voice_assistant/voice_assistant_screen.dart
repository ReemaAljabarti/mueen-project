// ============================================================
// lib/screens/voice_assistant/voice_assistant_screen.dart
//
// شاشة المساعد الصوتي — تطبيق مُعين
// Voice Assistant Screen — Mu'een App
//
// الحالات المدعومة:
//   • listening   — يستمع الآن
//   • processing  — جارٍ معالجة طلبك
//   • responding  — جاري الرد
//
// التكامل المستقبلي (FastAPI + OpenAI):
//   • ابحث عن تعليقات "TODO(api):" لمعرفة نقاط التكامل
// ============================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// نظام الألوان — مستخرج من Figma
// ---------------------------------------------------------------------------
class _AppColors {
  static const Color background = Color(0xFFF5FBFC);
  static const Color primary = Color(0xFF15B4BE);
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF8A9AA0);
  static const Color cardBackground = Colors.white;
  static const Color closeButtonBackground = Colors.white;
}

// ---------------------------------------------------------------------------
// نظام الخطوط — مستخرج من Figma
// ---------------------------------------------------------------------------
class _AppTextStyles {
  static const String _fontFamily = 'Tajawal';

  static const TextStyle appTitle = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w400,
    color: _AppColors.textPrimary,
  );

  static const TextStyle stateTitle = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 36,
    fontWeight: FontWeight.w400,
    color: _AppColors.textPrimary,
  );

  static const TextStyle stateSubtitle = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w400,
    color: _AppColors.textSecondary,
  );

  static const TextStyle sectionHeader = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w400,
    color: _AppColors.textPrimary,
  );

  static const TextStyle suggestionLabel = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w400,
    color: _AppColors.textPrimary,
  );
}

// ---------------------------------------------------------------------------
// Enum: حالات المساعد الصوتي
// ---------------------------------------------------------------------------
enum VoiceAssistantState {
  /// المساعد يستمع للمستخدم (STT نشط)
  listening,

  /// المساعد يعالج الطلب (NLU + DB)
  processing,

  /// المساعد يشغّل الرد الصوتي (TTS نشط)
  responding,
}

// ---------------------------------------------------------------------------
// نموذج بيانات بطاقة الاقتراح
// ---------------------------------------------------------------------------
class SuggestionCard {
  final String label;
  final IconData icon;

  /// معرّف النية — يُستخدم مستقبلاً مع FastAPI/OpenAI
  final String intentId;

  const SuggestionCard({
    required this.label,
    required this.icon,
    required this.intentId,
  });
}

// ---------------------------------------------------------------------------
// بيانات الاقتراحات — قابلة للتعديل بسهولة
// ---------------------------------------------------------------------------
const List<SuggestionCard> _defaultSuggestions = [
  SuggestionCard(
    label: 'ما الجرعة القادمة؟',
    icon: Icons.access_time_rounded,
    intentId: 'next_dose',
  ),
  SuggestionCard(
    label: 'اقرأ التفاصيل',
    icon: Icons.menu_book_rounded,
    intentId: 'read_details',
  ),
  SuggestionCard(
    label: 'اعرض الأدوية',
    icon: Icons.medication_rounded,
    intentId: 'show_medications',
  ),
];

// ---------------------------------------------------------------------------
// الشاشة الرئيسية
// ---------------------------------------------------------------------------
class VoiceAssistantScreen extends StatefulWidget {
  /// الحالة الابتدائية عند فتح الشاشة
  final VoiceAssistantState initialState;

  /// قائمة الاقتراحات (قابلة للتخصيص)
  final List<SuggestionCard> suggestions;

  /// دالة رد النداء عند الضغط على اقتراح
  /// TODO(api): ربط هذه الدالة بـ FastAPI لإرسال النية
  final void Function(SuggestionCard suggestion)? onSuggestionTapped;

  /// دالة رد النداء عند الضغط على زر الإغلاق
  final VoidCallback? onClose;

  const VoiceAssistantScreen({
    Key? key,
    this.initialState = VoiceAssistantState.listening,
    this.suggestions = _defaultSuggestions,
    this.onSuggestionTapped,
    this.onClose,
  }) : super(key: key);

  @override
  State<VoiceAssistantScreen> createState() => _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends State<VoiceAssistantScreen>
    with TickerProviderStateMixin {
  late VoiceAssistantState _state;

  // متحكم الرسوم المتحركة للنبض
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // متحكم الرسوم المتحركة لموجات الصوت
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _state = widget.initialState;
    _initAnimations();
    _startAnimationsForState(_state);
  }

  void _initAnimations() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  void _startAnimationsForState(VoiceAssistantState state) {
    _pulseController.stop();
    _waveController.stop();

    switch (state) {
      case VoiceAssistantState.listening:
        _pulseController.repeat(reverse: true);
        break;
      case VoiceAssistantState.processing:
        _waveController.repeat();
        break;
      case VoiceAssistantState.responding:
        _pulseController.repeat(reverse: true);
        break;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // واجهة عامة: تغيير الحالة من الخارج
  // TODO(api): استدعِ هذه الدالة عند تلقّي استجابة من FastAPI
  // -------------------------------------------------------------------------
  void changeState(VoiceAssistantState newState) {
    if (!mounted) return;
    setState(() => _state = newState);
    _startAnimationsForState(newState);
  }

  // -------------------------------------------------------------------------
  // بناء الشاشة
  // -------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              _Header(
                onClose: widget.onClose ?? () => Navigator.maybePop(context),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: _buildBody(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Padding(
      key: ValueKey(_state),
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          const SizedBox(height: 48),
          _buildIconArea(),
          const SizedBox(height: 36),
          _buildTextContent(),
          const SizedBox(height: 40),
          if (_state == VoiceAssistantState.listening) ...[
            _buildSuggestionsSection(),
          ] else
            const Spacer(),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // منطقة الأيقونة المتحركة
  // -------------------------------------------------------------------------
  Widget _buildIconArea() {
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // الحلقة الخارجية
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (_, __) => Transform.scale(
              scale: _state != VoiceAssistantState.processing
                  ? _pulseAnimation.value
                  : 1.0,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _AppColors.primary.withOpacity(
                    _state == VoiceAssistantState.responding ? 0.10 : 0.25,
                  ),
                ),
              ),
            ),
          ),
          // الحلقة الوسطى
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (_, __) => Transform.scale(
              scale: _state != VoiceAssistantState.processing
                  ? _pulseAnimation.value * 0.9
                  : 1.0,
              child: Container(
                width: 165,
                height: 165,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _AppColors.primary.withOpacity(0.20),
                ),
              ),
            ),
          ),
          // الدائرة الرئيسية
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              color: _state == VoiceAssistantState.responding
                  ? Colors.white
                  : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: _AppColors.primary, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 15,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 6,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(child: _buildStateIcon()),
          ),
        ],
      ),
    );
  }

  Widget _buildStateIcon() {
    switch (_state) {
      case VoiceAssistantState.listening:
        return const Icon(
          Icons.mic_rounded,
          size: 64,
          color: _AppColors.primary,
        );

      case VoiceAssistantState.processing:
        return _WaveformIcon(controller: _waveController);

      case VoiceAssistantState.responding:
        return const Icon(
          Icons.volume_up_rounded,
          size: 64,
          color: _AppColors.primary,
        );
    }
  }

  // -------------------------------------------------------------------------
  // نص الحالة
  // -------------------------------------------------------------------------
  Widget _buildTextContent() {
    final String title;
    final String subtitle;

    switch (_state) {
      case VoiceAssistantState.listening:
        title = 'يستمع الآن';
        subtitle = 'تحدث الآن أو اطرح سؤالك';
        break;
      case VoiceAssistantState.processing:
        title = 'جارٍ معالجة طلبك';
        subtitle = 'يرجى الانتظار قليلًا';
        break;
      case VoiceAssistantState.responding:
        title = 'جاري الرد';
        subtitle = 'يتم الآن تشغيل الرد الصوتي';
        break;
    }

    return Column(
      children: [
        Text(
          title,
          style: _AppTextStyles.stateTitle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          style: _AppTextStyles.stateSubtitle,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // قسم الاقتراحات (حالة الاستماع فقط)
  // -------------------------------------------------------------------------
  Widget _buildSuggestionsSection() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('جرّب أن تقول', style: _AppTextStyles.sectionHeader),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              itemCount: widget.suggestions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final card = widget.suggestions[index];
                return _SuggestionCardWidget(
                  card: card,
                  onTap: () {
                    widget.onSuggestionTapped?.call(card);
                    // TODO(api): إرسال النية إلى FastAPI
                    // Example:
                    // VoiceApiService.sendIntent(card.intentId);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// مكوّن: شريط التطبيق العلوي
// ---------------------------------------------------------------------------
class _Header extends StatelessWidget {
  final VoidCallback onClose;

  const _Header({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: SizedBox(
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // زر الإغلاق في جهة اليسار دائماً
            Align(
              alignment: Alignment.centerLeft,
              child: _CloseButton(onTap: onClose),
            ),

            // اسم التطبيق في جهة اليمين دائماً
            Align(
              alignment: Alignment.centerRight,
              child: Text('معين', style: _AppTextStyles.appTitle),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// مكوّن: زر الإغلاق
// ---------------------------------------------------------------------------
class _CloseButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CloseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: _AppColors.closeButtonBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: const Icon(Icons.close, color: Colors.black, size: 20),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// مكوّن: أيقونة موجة الصوت (حالة المعالجة)
// ---------------------------------------------------------------------------
class _WaveformIcon extends StatelessWidget {
  final AnimationController controller;

  const _WaveformIcon({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(7, (index) {
            // حساب ارتفاع كل عمود بناءً على موجة جيبية
            final phase = controller.value * 2 * math.pi;
            final offset = index * (math.pi / 3.5);
            final rawHeight = math.sin(phase + offset);
            final barHeight = 12.0 + (rawHeight * 0.5 + 0.5) * 50.0;
            final opacity = 0.60 + (index / 7) * 0.35;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 7,
              height: barHeight,
              decoration: BoxDecoration(
                color: _AppColors.primary.withOpacity(opacity),
                borderRadius: BorderRadius.circular(10),
              ),
            );
          }),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// مكوّن: بطاقة الاقتراح
// ---------------------------------------------------------------------------
class _SuggestionCardWidget extends StatelessWidget {
  final SuggestionCard card;
  final VoidCallback onTap;

  const _SuggestionCardWidget({required this.card, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _AppColors.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(card.icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(card.label, style: _AppTextStyles.suggestionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// ملاحظات التكامل المستقبلي
// ===========================================================================
//
// 1. STT (Speech-to-Text) عبر FastAPI:
//    - عند بدء الاستماع: استدعِ VoiceApiService.startSTT()
//    - عند انتهاء التسجيل: أرسل الصوت إلى POST /api/v1/stt
//    - انتقل إلى حالة processing بعد إرسال الطلب
//
// 2. NLU (Intent Detection) عبر OpenAI:
//    - أرسل النص المُحوَّل إلى POST /api/v1/nlu
//    - استخدم intentId من SuggestionCard كمعرّف للنية
//
// 3. Database Retrieval:
//    - بناءً على النية، استدعِ GET /api/v1/medications أو /api/v1/doses
//
// 4. TTS (Text-to-Speech):
//    - أرسل الرد النصي إلى POST /api/v1/tts
//    - شغّل الصوت المُعاد وانتقل إلى حالة responding
//    - بعد انتهاء التشغيل: عُد إلى حالة listening
//
// ===========================================================================
