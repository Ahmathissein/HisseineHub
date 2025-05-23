import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hisseinehub/widgets/AppLayout.dart';
import 'package:hisseinehub/widgets/HomeModuleScreen.dart';
import 'authentification/login.dart';
import 'authentification/signup.dart';
import 'contenu/documents/docs.dart';
import 'contenu/media/Media.dart';
import 'contenu/journal/journal.dart';
import 'contenu/planning/planning.dart';
import 'authentification/profil.dart';
import 'contenu/projet/projects_screen.dart';
import 'widgets/navbar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;



Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR'); // C’est ici qu’on initialise les locales
  await Supabase.initialize(
    url: 'https://msuxgpxlpmyaiujopjhs.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1zdXhncHhscG15YWl1am9wamhzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDc0ODkxMjAsImV4cCI6MjA2MzA2NTEyMH0.8X2rPa3EE3cQvAIKcMBjd_sdlCfxhc4pQIRpUJqCmrk',
    authOptions: const FlutterAuthClientOptions(
      autoRefreshToken: true,
    ),
  );

  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('fr', 'FR'),
      supportedLocales: const [
        Locale('fr', 'FR'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        quill.FlutterQuillLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        textTheme: GoogleFonts.quicksandTextTheme(),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/profil': (context) => const ProfilScreen(),
        '/planning': (context) => const PlanningScreen(),
        '/journal': (context) => const JournalScreen(),
        '/projects' : (context) => const ProjectsScreen(),
        '/media' : (context) => const MediaScreen(),
        '/documents' : (context) => const SuiviAdministratifPage(),

      },
    );


  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isSidebarExpanded = false;
  String? selectedItemLabel;

  void toggleSidebar() {
    setState(() {
      isSidebarExpanded = !isSidebarExpanded;
    });
  }

  void onItemSelected(String label) {
    setState(() {
      selectedItemLabel = label;
    });

    if (label == "Planning") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PlanningScreen()),
      );
    }
    if (label == "Journal") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const JournalScreen()),
      );
    }
    if (label == "Projects") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProjectsScreen()),
      );
    }

    if (label == "Media") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MediaScreen()),
      );
    }
    if (label == "Documents") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SuiviAdministratifPage()),
      );
    }

    // Tu pourras ajouter d'autres écrans ici :
    // else if (label == "Finance") ...
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      selectedItemLabel: selectedItemLabel,
      child: const HomeModulesScreen(),
    );
  }

}
