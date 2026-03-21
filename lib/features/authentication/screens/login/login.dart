import 'package:flutter/material.dart';
import 'package:helmet_app/common/sizes.dart';
import 'package:helmet_app/common/styles/spacing_styles.dart';
import 'package:helmet_app/common/text.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: TSpacingStyles.paddingWithAppBarHeight,
          child: Column(
            children: [
              // Logo, title and subtitle
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image(
                    height: 150.0,
                    image: const AssetImage('assets/images/logo.png'),
                  ),
                  Text(TTexts.loginTitle, style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: TSizes.spaceBtwItems),
                  Text(TTexts.loginSubtitle, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
              ///Form
              Form(
                child: Column(
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(labelText: TTexts.email,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: TTexts.password,
                        border: OutlineInputBorder(),
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        )
      ),
    );
  }
}