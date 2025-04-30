// main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:tracer/features/auth/presentation/login_screen.dart';
import 'package:tracer/features/home/presentation/home_screen.dart';
import 'app_router.dart';
import 'app_theme.dart';
import 'shared/services/auth_service.dart';
import 'shared/services/document_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => DocumentService()),
      ],
      child: TracerApp(),
    ),
  );
}

class TracerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return MaterialApp(
      title: 'Tracer - Document Scanner',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      onGenerateRoute: AppRouter.generateRoute,
      home: authService.isAuthenticated ? HomeScreen() : LoginScreen(),
    );
  }
}
