import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:MyBookTrace/config/router.dart';
import 'package:MyBookTrace/services/database_service.dart';

// Providers
import 'package:MyBookTrace/providers/book_provider.dart';
import 'package:MyBookTrace/providers/reading_session_provider.dart';
import 'package:MyBookTrace/providers/challenge_provider.dart';

void main() async {
  // Asegurar que Flutter esté inicializado
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configurar orientación de la aplicación
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Inicializar la base de datos
  await DatabaseService().database;
  
  runApp(const MyBookTrace());
}

class MyBookTrace extends StatelessWidget {
  const MyBookTrace({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Inicializar los providers principales
        ChangeNotifierProvider(create: (_) => BookProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => ChallengeProvider()..init()),
        // Inicializar el ReadingSessionProvider y conectarlo con los demás
        ChangeNotifierProxyProvider2<BookProvider, ChallengeProvider, ReadingSessionProvider>(
          create: (_) => ReadingSessionProvider(),
          update: (_, bookProvider, challengeProvider, sessionProvider) {
            // Inicializar si es la primera vez
            sessionProvider ??= ReadingSessionProvider();
            // Establecer las referencias a los otros providers
            sessionProvider.setBookProvider(bookProvider);
            sessionProvider.setChallengeProvider(challengeProvider);
            // Inicializar si aún no se ha hecho
            if (!sessionProvider.isInitialized) {
              sessionProvider.initialize();
            }
            return sessionProvider;
          },
        ),
      ],
      child: MaterialApp.router(
        title: 'MyBookTrace',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.indigo,
            brightness: Brightness.light,
          ),
          fontFamily: 'Roboto',
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF3F51B5),
            brightness: Brightness.dark,
          ),
          fontFamily: 'Roboto',
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
        ),
        themeMode: ThemeMode.system,
        routerConfig: appRouter,
      ),
    );
  }
}
