import 'package:flutter/material.dart';
import 'package:pozzo/core/service_locator.dart';
import 'package:pozzo/core/theme.dart';
import 'package:pozzo/features/iam/presentation/welcome_page.dart';

void main() {
  setupDependencies();
  runApp(const PozzoApp());
}

class PozzoApp extends StatelessWidget {
  const PozzoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pozzo',
      theme: PozzoTheme.light(),
      darkTheme: PozzoTheme.dark(),
      debugShowCheckedModeBanner: false,
      home: const WelcomePage(),
    );
  }
}
