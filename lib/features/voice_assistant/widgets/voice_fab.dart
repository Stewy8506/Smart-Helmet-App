import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import '../voice_assistant_service.dart';
import 'voice_overlay.dart';

class VoiceFAB extends StatefulWidget {
  const VoiceFAB({super.key});

  @override
  State<VoiceFAB> createState() => _VoiceFABState();
}

class _VoiceFABState extends State<VoiceFAB> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    VoiceAssistantService.instance.state.addListener(_onStateChange);
  }

  void _onStateChange() {
    if (!mounted) return;
    final state = VoiceAssistantService.instance.state.value;
    
    if (state == VoiceState.listening) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      _pulseController.stop();
      _pulseController.value = 0.0;
    }
    setState(() {});
  }

  @override
  void dispose() {
    VoiceAssistantService.instance.state.removeListener(_onStateChange);
    _pulseController.dispose();
    super.dispose();
  }

  void _onTap() {
    final service = VoiceAssistantService.instance;
    if (service.state.value == VoiceState.listening || service.state.value == VoiceState.processing || service.state.value == VoiceState.speaking) {
      service.stopListening();
    } else {
      service.startListening();
      showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: "VoiceOverlay",
        pageBuilder: (context, animation, secondaryAnimation) {
          return const VoiceOverlay();
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = VoiceAssistantService.instance.state.value;
    final isListening = state == VoiceState.listening;
    final isProcessing = state == VoiceState.processing;
    final isSpeaking = state == VoiceState.speaking;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: _onTap,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final scale = isListening ? _scaleAnimation.value : (_isPressed ? 0.95 : 1.0);
          
          return Transform.scale(
            scale: scale,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: isListening ? Colors.redAccent.withAlpha(80) : Colors.white.withAlpha(_isPressed ? 25 : 0),
                    blurRadius: isListening ? 20 : (_isPressed ? 12 : 15),
                    spreadRadius: isListening ? 10 * _pulseController.value : (_isPressed ? 8 : 1),
                  ),
                ],
              ),
              child: LiquidGlass(
                shape: LiquidRoundedRectangle(borderRadius: 24),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: Center(
                    child: isProcessing 
                      ? const SizedBox(
                          width: 20, 
                          height: 20, 
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        )
                      : Icon(
                          isListening ? Icons.mic : (isSpeaking ? Icons.volume_up : Icons.mic_none),
                          color: isListening ? Colors.redAccent : Colors.white,
                          size: 24,
                        ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
