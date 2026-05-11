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

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../services/api_service.dart';
import '../../services/current_elder.dart';

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

  // أدوات تسجيل صوت المستخدم وتشغيل رد المساعد
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isRecording = false;
  String _assistantSpokenText = '';

  @override
  void initState() {
    super.initState();

    debugPrint('[VoiceAssistant] initState called');

    _state = widget.initialState;

    debugPrint('[VoiceAssistant] initial state = $_state');

    _initAnimations();
    _startAnimationsForState(_state);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('[VoiceAssistant] postFrameCallback: starting recording');
      _startRecording();
    });
  }

  void _initAnimations() {
    debugPrint('[VoiceAssistant] _initAnimations called');

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

    debugPrint('[VoiceAssistant] _initAnimations completed');
  }

  void _startAnimationsForState(VoiceAssistantState state) {
    debugPrint('[VoiceAssistant] _startAnimationsForState called: $state');

    _pulseController.stop();
    _waveController.stop();

    switch (state) {
      case VoiceAssistantState.listening:
        debugPrint('[VoiceAssistant] animation mode: listening pulse');
        _pulseController.repeat(reverse: true);
        break;
      case VoiceAssistantState.processing:
        debugPrint('[VoiceAssistant] animation mode: processing waveform');
        _waveController.repeat();
        break;
      case VoiceAssistantState.responding:
        debugPrint('[VoiceAssistant] animation mode: responding pulse');
        _pulseController.repeat(reverse: true);
        break;
    }
  }

  @override
  void dispose() {
    debugPrint('[VoiceAssistant] dispose called');
    debugPrint('[VoiceAssistant] _isRecording on dispose = $_isRecording');
    debugPrint('[VoiceAssistant] current state on dispose = $_state');

    _recorder.dispose();
    _audioPlayer.dispose();
    _pulseController.dispose();
    _waveController.dispose();

    debugPrint('[VoiceAssistant] dispose completed');

    super.dispose();
  }

  // -------------------------------------------------------------------------
  // واجهة عامة: تغيير الحالة من الخارج
  // TODO(api): استدعِ هذه الدالة عند تلقّي استجابة من FastAPI
  // -------------------------------------------------------------------------
  void changeState(VoiceAssistantState newState) {
    debugPrint('[VoiceAssistant] changeState called: $_state -> $newState');

    if (!mounted) {
      debugPrint('[VoiceAssistant] changeState ignored: widget is not mounted');
      return;
    }

    setState(() => _state = newState);
    _startAnimationsForState(newState);

    debugPrint('[VoiceAssistant] changeState done: current state = $_state');
  }

  Future<void> _startRecording() async {
    debugPrint('[VoiceAssistant] _startRecording called');
    debugPrint('[VoiceAssistant] _isRecording before start = $_isRecording');
    debugPrint('[VoiceAssistant] current state before start = $_state');

    if (_isRecording) {
      debugPrint('[VoiceAssistant] _startRecording stopped: already recording');
      return;
    }

    final hasPermission = await _recorder.hasPermission();
    debugPrint('[VoiceAssistant] microphone permission = $hasPermission');

    if (!hasPermission) {
      debugPrint('[VoiceAssistant] no microphone permission');
      _showMessage('لم يتم السماح باستخدام الميكروفون.');
      return;
    }

    final tempDir = await getTemporaryDirectory();
    debugPrint('[VoiceAssistant] temp directory = ${tempDir.path}');

    final filePath =
        '${tempDir.path}/assistant_input_${DateTime.now().millisecondsSinceEpoch}.m4a';

    debugPrint('[VoiceAssistant] recording file path = $filePath');

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
      ),
      path: filePath,
    );

    debugPrint('[VoiceAssistant] recorder.start completed');

    if (!mounted) {
      debugPrint(
          '[VoiceAssistant] after recorder.start: widget is not mounted');
      return;
    }

    setState(() {
      _isRecording = true;
      _assistantSpokenText = '';
      _state = VoiceAssistantState.listening;
    });

    debugPrint('[VoiceAssistant] recording started successfully');
    debugPrint('[VoiceAssistant] _isRecording after start = $_isRecording');
    debugPrint('[VoiceAssistant] current state after start = $_state');

    _startAnimationsForState(VoiceAssistantState.listening);
  }

  Future<void> _stopRecordingAndSend() async {
    debugPrint('[VoiceAssistant] _stopRecordingAndSend called');
    debugPrint('[VoiceAssistant] _isRecording before stop = $_isRecording');
    debugPrint('[VoiceAssistant] current state before stop = $_state');

    if (!_isRecording) {
      debugPrint(
          '[VoiceAssistant] _stopRecordingAndSend stopped: not recording');
      return;
    }

    final path = await _recorder.stop();

    debugPrint('[VoiceAssistant] recorder.stop completed');
    debugPrint('[VoiceAssistant] stopped recording path = $path');

    if (!mounted) {
      debugPrint('[VoiceAssistant] after recorder.stop: widget is not mounted');
      return;
    }

    setState(() {
      _isRecording = false;
      _state = VoiceAssistantState.processing;
    });

    debugPrint('[VoiceAssistant] state changed to processing');
    debugPrint('[VoiceAssistant] _isRecording after stop = $_isRecording');

    _startAnimationsForState(VoiceAssistantState.processing);

    if (path == null) {
      debugPrint('[VoiceAssistant] path is null after stopping recorder');
      _showMessage('لم يتم تسجيل صوت واضح.');
      await _startRecording();
      return;
    }

    final recordedFile = File(path);
    final fileExists = await recordedFile.exists();
    final fileSize = fileExists ? await recordedFile.length() : 0;

    debugPrint('[VoiceAssistant] recorded file exists = $fileExists');
    debugPrint('[VoiceAssistant] recorded file size = $fileSize bytes');

    try {
      debugPrint('[VoiceAssistant] sending recorded audio to assistant');

      final response = await _sendAudioToAssistant(recordedFile);

      debugPrint('[VoiceAssistant] assistant response received');
      debugPrint(
          '[VoiceAssistant] assistant response keys = ${response.keys.toList()}');
      debugPrint('[VoiceAssistant] spoken_text = ${response['spoken_text']}');
      debugPrint('[VoiceAssistant] audio_format = ${response['audio_format']}');
      debugPrint(
        '[VoiceAssistant] audio_base64 length = ${response['audio_base64']?.toString().length ?? 0}',
      );

      if (!mounted) {
        debugPrint(
            '[VoiceAssistant] after assistant response: widget is not mounted');
        return;
      }

      setState(() {
        _assistantSpokenText = response['spoken_text']?.toString() ?? '';
        _state = VoiceAssistantState.responding;
      });

      debugPrint('[VoiceAssistant] state changed to responding');

      _startAnimationsForState(VoiceAssistantState.responding);

      await _playBase64Audio(
        audioBase64: response['audio_base64']?.toString() ?? '',
        audioFormat: response['audio_format']?.toString() ?? 'mp3',
      );

      debugPrint('[VoiceAssistant] playBase64Audio completed');

      if (!mounted) {
        debugPrint(
            '[VoiceAssistant] after audio playback: widget is not mounted');
        return;
      }

      setState(() {
        _state = VoiceAssistantState.listening;
      });

      debugPrint('[VoiceAssistant] state returned to listening');

      _startAnimationsForState(VoiceAssistantState.listening);
      await _startRecording();
    } catch (e, stackTrace) {
      debugPrint('[VoiceAssistant] error in _stopRecordingAndSend = $e');
      debugPrint('[VoiceAssistant] stackTrace = $stackTrace');

      if (!mounted) {
        debugPrint('[VoiceAssistant] catch block: widget is not mounted');
        return;
      }

      _showMessage('حدث خطأ أثناء تشغيل المساعد. حاول مرة أخرى.');

      setState(() {
        _state = VoiceAssistantState.listening;
      });

      debugPrint('[VoiceAssistant] after error: state returned to listening');

      _startAnimationsForState(VoiceAssistantState.listening);
      await _startRecording();
    }
  }

  Future<Map<String, dynamic>> _sendAudioToAssistant(File audioFile) async {
    debugPrint('[VoiceAssistant] _sendAudioToAssistant called');
    debugPrint('[VoiceAssistant] audio file path = ${audioFile.path}');

    final exists = await audioFile.exists();
    final size = exists ? await audioFile.length() : 0;

    debugPrint('[VoiceAssistant] audio file exists before send = $exists');
    debugPrint('[VoiceAssistant] audio file size before send = $size bytes');

    final elderId = currentElder?.id;

    debugPrint('[VoiceAssistant] currentElder = $currentElder');
    debugPrint('[VoiceAssistant] current elder id = $elderId');

    if (elderId == null) {
      debugPrint('[VoiceAssistant] ERROR: Current elder id is missing');
      throw Exception('Current elder id is missing.');
    }

    final uri = Uri.parse('${ApiService.baseUrl}/assistant/respond-audio');

    debugPrint('[VoiceAssistant] ApiService.baseUrl = ${ApiService.baseUrl}');
    debugPrint('[VoiceAssistant] assistant audio uri = $uri');

    final request = http.MultipartRequest('POST', uri);
    request.fields['elder_id'] = elderId.toString();

    debugPrint('[VoiceAssistant] multipart fields = ${request.fields}');

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        audioFile.path,
      ),
    );

    debugPrint(
        '[VoiceAssistant] multipart files count = ${request.files.length}');
    debugPrint(
        '[VoiceAssistant] multipart file field = ${request.files.first.field}');
    debugPrint(
        '[VoiceAssistant] multipart file filename = ${request.files.first.filename}');
    debugPrint('[VoiceAssistant] sending HTTP request now');

    final streamedResponse = await request.send();

    debugPrint(
        '[VoiceAssistant] streamed response status = ${streamedResponse.statusCode}');

    final response = await http.Response.fromStream(streamedResponse);

    debugPrint(
        '[VoiceAssistant] HTTP response status = ${response.statusCode}');
    debugPrint('[VoiceAssistant] HTTP response body = ${response.body}');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      debugPrint('[VoiceAssistant] assistant request failed');
      throw Exception('Assistant request failed: ${response.body}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;

    debugPrint('[VoiceAssistant] decoded response successfully');
    debugPrint('[VoiceAssistant] decoded keys = ${decoded.keys.toList()}');

    return decoded;
  }

  Future<void> _playBase64Audio({
    required String audioBase64,
    required String audioFormat,
  }) async {
    debugPrint('[VoiceAssistant] _playBase64Audio called');
    debugPrint('[VoiceAssistant] audioBase64 length = ${audioBase64.length}');
    debugPrint('[VoiceAssistant] audioFormat = $audioFormat');

    if (audioBase64.isEmpty) {
      debugPrint('[VoiceAssistant] audioBase64 is empty, skipping playback');
      return;
    }

    final bytes = base64Decode(audioBase64);
    debugPrint('[VoiceAssistant] decoded audio bytes length = ${bytes.length}');

    final tempDir = await getTemporaryDirectory();

    final file = File(
      '${tempDir.path}/assistant_response_${DateTime.now().millisecondsSinceEpoch}.$audioFormat',
    );

    debugPrint('[VoiceAssistant] response audio file path = ${file.path}');

    await file.writeAsBytes(bytes, flush: true);

    final fileExists = await file.exists();
    final fileSize = fileExists ? await file.length() : 0;

    debugPrint('[VoiceAssistant] response audio file exists = $fileExists');
    debugPrint('[VoiceAssistant] response audio file size = $fileSize bytes');

    await _audioPlayer.stop();
    debugPrint('[VoiceAssistant] audio player stopped before playback');

    final completer = Completer<void>();

    late StreamSubscription<void> completeSubscription;
    late StreamSubscription<PlayerState> stateSubscription;

    completeSubscription = _audioPlayer.onPlayerComplete.listen((_) {
      debugPrint('[VoiceAssistant] audio playback completed event received');

      if (!completer.isCompleted) {
        completer.complete();
      }
    });

    stateSubscription = _audioPlayer.onPlayerStateChanged.listen((state) {
      debugPrint('[VoiceAssistant] audio player state changed = $state');

      if (state == PlayerState.stopped && !completer.isCompleted) {
        debugPrint('[VoiceAssistant] audio playback stopped event received');
        completer.complete();
      }
    });

    await _audioPlayer.play(DeviceFileSource(file.path));
    debugPrint('[VoiceAssistant] audio player started playback');

    await completer.future;

    await completeSubscription.cancel();
    await stateSubscription.cancel();

    debugPrint(
        '[VoiceAssistant] _playBase64Audio completed after real playback end');
  }

  Future<void> _handleMicTap() async {
    debugPrint('[VoiceAssistant] _handleMicTap called');
    debugPrint('[VoiceAssistant] current state on mic tap = $_state');
    debugPrint('[VoiceAssistant] _isRecording on mic tap = $_isRecording');

    if (_state == VoiceAssistantState.processing) {
      debugPrint('[VoiceAssistant] mic tap ignored: currently processing');
      return;
    }

    if (_state == VoiceAssistantState.listening) {
      debugPrint(
          '[VoiceAssistant] mic tap while listening: stopping and sending');
      await _stopRecordingAndSend();
      return;
    }

    if (_state == VoiceAssistantState.responding) {
      debugPrint(
          '[VoiceAssistant] mic tap while responding: stop audio and start recording');
      await _audioPlayer.stop();
      await _startRecording();
    }
  }

  Future<void> _handleClose() async {
    debugPrint('[VoiceAssistant] _handleClose called');
    debugPrint('[VoiceAssistant] _isRecording on close = $_isRecording');
    debugPrint('[VoiceAssistant] current state on close = $_state');

    if (_isRecording) {
      debugPrint('[VoiceAssistant] stopping recorder before closing');
      await _recorder.stop();
      _isRecording = false;
      debugPrint('[VoiceAssistant] recorder stopped on close');
    }

    debugPrint('[VoiceAssistant] stopping audio player before closing');
    await _audioPlayer.stop();

    if (!mounted) {
      debugPrint('[VoiceAssistant] close stopped: widget is not mounted');
      return;
    }

    if (widget.onClose != null) {
      debugPrint('[VoiceAssistant] calling widget.onClose');
      widget.onClose!();
    } else {
      debugPrint('[VoiceAssistant] Navigator.maybePop');
      Navigator.maybePop(context);
    }
  }

  void _showMessage(String message) {
    debugPrint('[VoiceAssistant] _showMessage called: $message');

    if (!mounted) {
      debugPrint('[VoiceAssistant] showMessage ignored: widget is not mounted');
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
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
                onClose: () {
                  _handleClose();
                },
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
          const SizedBox(height: 20),
          // ---- زر "اضغط هنا عند الانتهاء" — يظهر في حالة الاستماع فقط ----
          if (_state == VoiceAssistantState.listening)
            _StopListeningPill(onTap: _handleMicTap),
          const SizedBox(height: 24),
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
    return GestureDetector(
      onTap: () {
        _handleMicTap();
      },
      child: SizedBox(
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
            // الدائرة الرئيسية — مع مؤشر "اضغط" في حالة الاستماع
            Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                color: _state == VoiceAssistantState.responding
                    ? Colors.white
                    : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: _state == VoiceAssistantState.listening
                      ? _AppColors.primary
                      : _AppColors.primary,
                  width: _state == VoiceAssistantState.listening ? 5 : 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _state == VoiceAssistantState.listening
                        ? _AppColors.primary.withOpacity(0.30)
                        : Colors.black.withOpacity(0.10),
                    blurRadius:
                        _state == VoiceAssistantState.listening ? 20 : 15,
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
        subtitle = 'تحدث الآن، ثم اضغط المايك عند الانتهاء';
        break;
      case VoiceAssistantState.processing:
        title = 'جارٍ معالجة طلبك';
        subtitle = 'انتظر قليلًا...';
        break;
      case VoiceAssistantState.responding:
        title = 'جاري الرد';
        subtitle = _assistantSpokenText.isNotEmpty
            ? _assistantSpokenText
            : 'يتم الآن تشغيل الرد الصوتي';
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
// مكوّن: زر "اضغط هنا عند الانتهاء" — Pill واضح وقابل للنقر
// يظهر أسفل دائرة المايكروفون مباشرةً في حالة الاستماع فقط
// ---------------------------------------------------------------------------
class _StopListeningPill extends StatelessWidget {
  final VoidCallback onTap;

  const _StopListeningPill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        decoration: BoxDecoration(
          color: _AppColors.primary,
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: _AppColors.primary.withOpacity(0.35),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(
              Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 26,
            ),
            SizedBox(width: 10),
            Text(
              'اضغط هنا عند الانتهاء',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
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
