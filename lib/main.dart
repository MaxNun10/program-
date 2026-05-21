import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/lesson_provider.dart';
import 'providers/word_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/lessons/lesson_detail_screen.dart';
import 'screens/lessons/lesson_quiz_screen.dart';
import 'screens/lessons/lessons_screen.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => WordProvider()),
        ChangeNotifierProvider(create: (_) => LessonProvider()),
      ],
      child: MaterialApp(
        title: 'Language Learning App',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF58CC02),
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF7FBF4),
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
            backgroundColor: Color(0xFFF7FBF4),
            foregroundColor: Color(0xFF25351F),
          ),
          cardTheme: CardThemeData(
            color: Colors.white,
            elevation: 2,
            shadowColor: Colors.black12,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF58CC02),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Color(0xFF58CC02),
            foregroundColor: Colors.white,
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            selectedItemColor: Color(0xFF58CC02),
            unselectedItemColor: Color(0xFF8B9A86),
            type: BottomNavigationBarType.fixed,
          ),
        ),
        home: const SplashScreen(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignupScreen(),
          '/home': (context) => const HomeScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/lessons') {
            return MaterialPageRoute(builder: (_) => const LessonsScreen());
          }
          final uri = Uri.parse(settings.name!);
          if (uri.pathSegments.length == 2 && uri.pathSegments[0] == 'lesson') {
            final id = uri.pathSegments[1];
            return MaterialPageRoute(
              builder: (_) => const LessonDetailScreen(),
              settings: RouteSettings(arguments: id),
            );
          }
          if (uri.pathSegments.length == 3 &&
              uri.pathSegments[0] == 'lesson' &&
              uri.pathSegments[2] == 'quiz') {
            final id = uri.pathSegments[1];
            return MaterialPageRoute(
              builder: (_) => const LessonQuizScreen(),
              settings: RouteSettings(arguments: id),
            );
          }
          return null;
        },
      ),
    );
  }
}
