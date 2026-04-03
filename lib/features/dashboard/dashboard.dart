import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.3),
            radius: 0.5,
            colors: [
              Color.fromARGB(255, 45, 45, 45),
              Color.fromARGB(255, 15, 15, 15),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Title
              const Text(
                "THIS IS\nYOUR\nNEXUS",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.1,
                ),
              ),

              const SizedBox(height: 20),

              // Helmet Image
              Center(
                child: Image.asset(
                  "assets/images/helmet.png",
                  height: 220,
                ),
              ),

              const SizedBox(height: 20),

              // Battery Circle
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 150,
                    height: 150,
                    child: CircularProgressIndicator(
                      value: 0.72,
                      strokeWidth: 10,
                      backgroundColor: Colors.grey.shade800,
                      valueColor: const AlwaysStoppedAnimation(Colors.green),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.battery_full, color: Colors.white),
                      SizedBox(height: 4),
                      Text(
                        "72%",
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  )
                ],
              ),

              const SizedBox(height: 10),

              const Text(
                "1:40 Hours",
                style: TextStyle(color: Colors.white70),
              ),

              const SizedBox(height: 30),

              // Stats Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: const [
                  _StatItem(
                    icon: Icons.favorite_border,
                    label: "120/200",
                    sub: "Kilometers",
                  ),
                  _StatItem(
                    icon: Icons.favorite,
                    label: "1200/2000",
                    sub: "Calories",
                  ),
                ],
              ),

              const Spacer(),

              // Bottom Nav
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(21),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: const [
                    Icon(Icons.directions_bike, color: Colors.white),
                    Icon(Icons.person_outline, color: Colors.white54),
                    Icon(Icons.explore_outlined, color: Colors.white54),
                    Icon(Icons.bar_chart, color: Colors.white54),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          sub,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }
}
