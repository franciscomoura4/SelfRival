import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router.dart';

void main() {
  // Essential for loading native plugins like Maps/Sensors before UI draws
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const ProviderScope(child: SelfRivalApp()));
}

class SelfRivalApp extends ConsumerWidget {
  const SelfRivalApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the router provider so it reacts to login/logout state changes
    final goRouter = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'SelfRival',
      debugShowCheckedModeBanner: false, // Hides the annoying debug banner
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF23A2D9),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      routerConfig: goRouter,
    );
  }
}