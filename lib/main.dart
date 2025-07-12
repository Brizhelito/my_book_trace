import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:my_book_trace/config/router.dart';
import 'package:my_book_trace/services/database_service.dart';

// Providers
import 'package:my_book_trace/providers/book_provider.dart';
import 'package:my_book_trace/providers/reading_session_provider.dart';
import 'package:my_book_trace/providers/challenge_provider.dart';

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
        ChangeNotifierProvider(create: (_) => BookProvider()),
        ChangeNotifierProvider(create: (_) => ReadingSessionProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => ChallengeProvider()..init()),
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
            seedColor: Colors.indigo,
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
