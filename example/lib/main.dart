import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'janus_manager.dart';
import 'screens/home_screen.dart';
import 'appsflyer_service.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();
  AppsflyerService().initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => JanusManager(),
      child: MaterialApp(
        title: 'Janus SDK Flutter Example',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        themeMode: ThemeMode.system,
        home: const HomeScreen(),
      ),
    );
  }
}
