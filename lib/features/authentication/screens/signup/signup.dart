import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:helmet_app/common/sizes.dart';
import 'package:helmet_app/common/styles/spacing_styles.dart';
import 'package:helmet_app/common/text.dart';
import 'package:helmet_app/features/authentication/screens/login/login.dart';

import '../../controllers/auth_controller.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool isLoading = false;

  final AuthController authController = AuthController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: SelectionContainer.disabled(
          child: Padding(
            padding: TSpacingStyles.paddingWithAppBarHeight,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(
                TTexts.signupTitle,
                style: GoogleFonts.pacifico(
                  fontSize: 45,
                  color: Colors.white,
                ),
      
              ),

              const SizedBox(height: TSizes.spaceBtwSections + 20),

              Row(
                children: [
                  Expanded(child: _inputField("Firstname", Icons.person)),
                  const SizedBox(width: 10),
                  Expanded(child: _inputField("Lastname", Icons.person)),
                ],
              ),

              const SizedBox(height: TSizes.spaceBtwItems),

              _inputField("Email", Icons.email, controller: emailController),
              const SizedBox(height: 16),

              _inputField("Password", Icons.lock, obscure: true, controller: passwordController),
              const SizedBox(height: 16),

              _inputField("Confirm Password", Icons.lock, obscure: true, controller: confirmPasswordController),

              const SizedBox(height: TSizes.spaceBtwSections + 10),

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
                                onPressed: isLoading
                                    ? null
                                    : () async {
                                        if (emailController.text.isEmpty ||
                                            passwordController.text.isEmpty ||
                                            confirmPasswordController.text.isEmpty) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text("Fill all fields")),
                                          );
                                          return;
                                        }

                                        if (passwordController.text != confirmPasswordController.text) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text("Passwords do not match")),
                                          );
                                          return;
                                        }

                                        setState(() => isLoading = true);

                                        final error = await authController.signUp(
                                          emailController.text.trim(),
                                          passwordController.text.trim(),
                                        );

                                        setState(() => isLoading = false);

                                        if (!mounted) return;

                                        if (error != null) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text(error)),
                                          );
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text("Check your email to verify your account"),
                                            ),
                                          );
                                          Navigator.pop(context);
                                        }
                                      },
                                child: isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                      )
                                    : const Text(
                                        "Register",
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

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Already have an account? ",
                    style: TextStyle(color: Colors.white70),
                  ),
                  TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        "Login",
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
                child: Text(
                  "or",
                  style: TextStyle(color: Colors.white54),
                ),
              ),

              const SizedBox(height: TSizes.spaceBtwSections),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: 
                [
                  _socialIcon(Icons.g_mobiledata),
                  _socialIcon(Icons.facebook),
                  _socialIcon(Icons.apple),
                  _socialIcon(Icons.flutter_dash),
                ],
              ),

              const SizedBox(height: TSizes.spaceBtwSections+10),

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
      ),
    );
  }

  Widget _inputField(String hint, IconData icon,
      {bool obscure = false, TextEditingController? controller}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.white54),
        filled: true,
        fillColor: Colors.transparent,
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.white),
        ),
      ),
    );
  }
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