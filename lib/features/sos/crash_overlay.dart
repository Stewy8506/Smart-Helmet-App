import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import 'package:helmet_app/features/sos/sos_service.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';

class CrashOverlay extends StatefulWidget {
  const CrashOverlay({super.key});

  @override
  State<CrashOverlay> createState() => _CrashOverlayState();
}

class _CrashOverlayState extends State<CrashOverlay> with SingleTickerProviderStateMixin {
  int _countdown = 15;
  Timer? _timer;
  late AnimationController _pulseController;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..repeat(reverse: true);
    _colorAnimation = ColorTween(begin: Colors.red[900], end: Colors.red[500]).animate(_pulseController);

    _startSOSSequence();
  }

  void _startSOSSequence() async {
    bool? hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      Vibration.vibrate(pattern: [500, 1000, 500, 1000, 500, 1000, 500, 1000, 500, 1000, 500, 1000, 500, 1000]);
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 1) {
        setState(() {
          _countdown--;
        });
      } else {
        _timer?.cancel();
        _sendSOS();
      }
    });
  }

  void _sendSOS() async {
    setState(() {
      _countdown = 0;
    });
    await SosService.instance.sendSosMessages();
    if (mounted) {
      Navigator.pop(context, true); 
    }
  }

  void _cancelSOS() {
    _timer?.cancel();
    _pulseController.stop();
    Vibration.cancel();
    Navigator.pop(context, false); 
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    Vibration.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedBuilder(
        animation: _colorAnimation,
        builder: (context, child) {
          return Container(
            color: _colorAnimation.value,
            width: double.infinity,
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 100, color: Colors.white),
                  const SizedBox(height: 20),
                  Text(
                    "CRASH DETECTED",
                    style: GoogleFonts.montserrat(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Sending SOS in:",
                    style: TextStyle(color: Colors.white70, fontSize: 18),
                  ),
                  const SizedBox(height: 40),
                  
                  // Countdown Ring
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 150,
                        height: 150,
                        child: CircularProgressIndicator(
                          value: _countdown / 15.0,
                          strokeWidth: 10,
                          color: Colors.white,
                          backgroundColor: Colors.white24,
                        ),
                      ),
                      Text(
                        _countdown == 0 ? "..." : "$_countdown",
                        style: GoogleFonts.montserrat(
                          fontSize: 64,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 60),

                  // Cancel Button
                  GestureDetector(
                    onTap: _cancelSOS,
                    child: Container(
                      width: 200,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(35),
                        border: Border.all(color: Colors.white54, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          "CANCEL",
                          style: GoogleFonts.montserrat(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
