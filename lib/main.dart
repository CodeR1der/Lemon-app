import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:task_tracker/widgets/navigation_panel.dart';
import 'screens/home_page.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Supabase.initialize(
    url: 'https://xusyxtgdmtpupmroemzb.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh1c3l4dGdkbXRwdXBtcm9lbXpiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzI0NDU2NTgsImV4cCI6MjA0ODAyMTY1OH0.Z7gU-A_s6ymY7-vTW4ObeHurvtbSIt4kWe-9EXF5j9M',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        textTheme: TextTheme(
          bodyMedium: GoogleFonts.roboto(fontSize: 15, color: Colors.black),
          bodySmall: GoogleFonts.roboto(fontSize: 14, color: Colors.black),
          bodyLarge: GoogleFonts.roboto(fontSize: 16, color: Colors.black),
          titleMedium: GoogleFonts.roboto(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold),
        ),
      ),
      debugShowCheckedModeBanner: false,
      routes: {
        '/home': (context) => const HomeScreen(),
      },
      home: const BottomNavigationMenu(),
    );
  }
}
