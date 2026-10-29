import 'package:flutter/material.dart';

import 'app_scope.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/setup_screen.dart';
import 'state/app_state.dart';

class OctopApp extends StatefulWidget {
  const OctopApp({super.key, required this.state});

  final AppState state;

  @override
  State<OctopApp> createState() => _OctopAppState();
}

class _OctopAppState extends State<OctopApp> {
  @override
  void initState() {
    super.initState();
    widget.state.load();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: widget.state,
      child: MaterialApp(
        title: 'Octop-Auto',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1F6FEB),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFF6F7F9),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1F6FEB),
            brightness: Brightness.dark,
          ),
        ),
        themeMode: ThemeMode.system,
        home: AnimatedBuilder(
          animation: widget.state,
          builder: (context, _) {
            final state = widget.state;
            if (!state.ready) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (!state.baseUrlConfirmed) return const SetupScreen();
            if (!state.isAuthenticated) return const LoginScreen();
            return const MainScreen();
          },
        ),
      ),
    );
  }
}
