import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:helmet_app/common/sizes.dart';
import 'package:helmet_app/common/styles/spacing_styles.dart';
import 'package:helmet_app/common/text.dart';
import 'package:helmet_app/features/authentication/screens/signup/signup.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: TSpacingStyles.paddingWithAppBarHeight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: TSizes.appBarHeight),

                // Logo Text
                Text(
                  TTexts.loginTitle,
                  style: GoogleFonts.pacifico(
                    fontSize: 72,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: TSizes.spaceBtwSections + 40.0),

                // Email Field
                TextFormField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Email or username",
                    hintStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.black,
                    prefixIcon: const Icon(Icons.email, color: Colors.white54),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Colors.white24),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),

                const SizedBox(height: TSizes.spaceBtwItems),

                // Password Field
                TextFormField(
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Password",
                    hintStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.black,
                    prefixIcon: const Icon(Icons.lock, color: Colors.white54),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Colors.white24),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),

                const SizedBox(height: TSizes.spaceBtwSections),

                Builder(
                  builder: (context) {
                    final isPressed = ValueNotifier<bool>(false);

                    return ValueListenableBuilder<bool>(
                      valueListenable: isPressed,
                      builder: (context, value, child) {
                        return GestureDetector(
                          onTapDown: (_) => isPressed.value = true,
                          onTapUp: (_) => isPressed.value = false,
                          onTapCancel: () => isPressed.value = false,
                          onTap: () {},
                          child: AnimatedScale(
                            scale: value ? 1.05 : 1.0,
                            duration: const Duration(milliseconds: 90),
                            curve: Curves.easeInOut,
                            child: SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: value ? Colors.grey[200] : Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: () {},
                                child: const Text(
                                  "Sign in",
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),

                const SizedBox(height: TSizes.spaceBtwItems),

                Align(
                  alignment: Alignment.center,
                  child: Text(
                    "Forgot Password?",
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),

                const SizedBox(height: TSizes.spaceBtwItems),

                // Sign Up
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? ", style: TextStyle(color: Colors.white70)),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignUpScreen(),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        "Sign Up",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: TSizes.spaceBtwSections),

                const Center(
                  child: Text("or", style: TextStyle(color: Colors.white54)),
                ),

                const SizedBox(height: TSizes.spaceBtwSections),

                // Social Icons Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    
                    _socialIcon(Icons.g_mobiledata),
                    _socialIcon(Icons.facebook),
                    _socialIcon(Icons.apple),
                    _socialIcon(Icons.flutter_dash),
                  ],
                ),

                const SizedBox(height: TSizes.spaceBtwItems + 12),

                  // Signature
                Center(
                  child: Text(
                    TTexts.signatureTitle,
                    style: const TextStyle(color: Colors.white24, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _socialIcon(IconData icon) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          debugPrint('$icon pressed');
        },
        borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
        child: Container(
          padding: const EdgeInsets.all(TSizes.iconSm + 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
          ),
          child: icon == Icons.g_mobiledata
              ? Image.asset(
                  'assets/icons/google.png',
                  height: TSizes.iconMd,
                  width: TSizes.iconMd,
                )
              : Icon(icon, color: Colors.black, size: TSizes.iconMd),
        ),
      ),
    );
  }
}