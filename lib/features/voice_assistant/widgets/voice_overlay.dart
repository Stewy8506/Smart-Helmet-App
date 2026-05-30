import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../voice_assistant_service.dart';
import '../command_parser.dart';
import '../intent_router.dart';

class VoiceOverlay extends StatefulWidget {
  const VoiceOverlay({super.key});

  @override
  State<VoiceOverlay> createState() => _VoiceOverlayState();
}

class _VoiceOverlayState extends State<VoiceOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late IntentRouter _router;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _router = IntentRouter(VoiceAssistantService.instance);
    VoiceAssistantService.instance.state.addListener(_onStateChange);
  }

  void _onStateChange() async {
    if (!mounted) return;
    final state = VoiceAssistantService.instance.state.value;

    if (state == VoiceState.processing) {
      final rawText = VoiceAssistantService.instance.recognizedText.value;
      if (rawText.isNotEmpty) {
        final intent = CommandParser.parse(rawText);
        // Execute the intent
        await _router.execute(intent, context);
      } else {
        VoiceAssistantService.instance.speak("I didn't catch that");
      }
    } else if (state == VoiceState.idle) {
      // Auto-dismiss when back to idle
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }
    setState(() {});
  }

  @override
  void dispose() {
    VoiceAssistantService.instance.state.removeListener(_onStateChange);
    _pulseController.dispose();
    super.dispose();
  }

  Widget _buildHintChip(String text) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(40)),
      ),
      child: Center(
        child: Text(
          text,
          style: GoogleFonts.montserrat(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          VoiceAssistantService.instance.stopListening();
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        },
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black.withAlpha(220),
          child: AnimatedBuilder(
            animation: VoiceAssistantService.instance.state,
            builder: (context, child) {
              final state = VoiceAssistantService.instance.state.value;

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Mic icon with pulse
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      final isListening = state == VoiceState.listening;
                      final isProcessing = state == VoiceState.processing;
                      final isSpeaking = state == VoiceState.speaking;
                      final isError = state == VoiceState.error;

                      final scale = isListening ? 1.0 + (_pulseController.value * 0.2) : 1.0;

                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isError ? Colors.red.withAlpha(50) : Colors.white.withAlpha(20),
                            boxShadow: [
                              if (isListening)
                                BoxShadow(
                                  color: Colors.redAccent.withAlpha(80),
                                  blurRadius: 40,
                                  spreadRadius: 20 * _pulseController.value,
                                ),
                            ],
                          ),
                          child: Center(
                            child: isProcessing
                                ? const SizedBox(
                                    width: 40,
                                    height: 40,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                                  )
                                : Icon(
                                    isListening ? Icons.mic : (isSpeaking ? Icons.volume_up : (isError ? Icons.error_outline : Icons.mic_none)),
                                    color: isListening ? Colors.redAccent : Colors.white,
                                    size: 40,
                                  ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 40),

                  // Real-time transcription or state feedback
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: ValueListenableBuilder<String>(
                      valueListenable: VoiceAssistantService.instance.recognizedText,
                      builder: (context, text, child) {
                        String displayText = text;
                        if (state == VoiceState.processing) displayText = "Processing...";
                        if (state == VoiceState.error) displayText = "Error occurred";
                        if (state == VoiceState.listening && text.isEmpty) displayText = "Listening...";

                        return Text(
                          displayText,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w400,
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 40),
                  
                  if (state == VoiceState.listening)
                    AnimatedOpacity(
                      opacity: 1.0,
                      duration: const Duration(milliseconds: 300),
                      child: SizedBox(
                        height: 40,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          children: [
                            _buildHintChip("Navigate to..."),
                            _buildHintChip("Call [name]"),
                            _buildHintChip("Play music"),
                            _buildHintChip("Battery status"),
                            _buildHintChip("What's my speed?"),
                          ],
                        ),
                      ),
                    ),
                    
                  if (state == VoiceState.listening)
                    const SizedBox(height: 40),

                  // Hint text
                  Text(
                    "Tap anywhere to cancel",
                    style: GoogleFonts.montserrat(
                      color: Colors.white38,
                      fontSize: 14,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
