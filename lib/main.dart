import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hisseinehub/widgets/grid.dart';
import 'authentification/login.dart';
import 'authentification/signup.dart';
import 'contenu/planning.dart';
import 'widgets/navbar.dart';
import 'widgets/sidebar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://msuxgpxlpmyaiujopjhs.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1zdXhncHhscG15YWl1am9wamhzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDc0ODkxMjAsImV4cCI6MjA2MzA2NTEyMH0.8X2rPa3EE3cQvAIKcMBjd_sdlCfxhc4pQIRpUJqCmrk',
  );

  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.quicksandTextTheme(),
      ),
      initialRoute: '/',
        routes: {
          '/': (context) => const HomePage(),
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignUpScreen(),
        }

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

    // Tu pourras ajouter d'autres écrans ici :
    // else if (label == "Finance") ...
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      body: Stack(
        children: [
          // 👇 Contenu principal (grille des modules)
          Positioned.fill(
            left: 70,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: ModulesScreen(),
              ),
            ),
          ),


          // 👇 Sidebar (superposée)
          Positioned(
            top: 0,
            left: 0,
            bottom: 0,
            child: Material(
              elevation: 8,
              color: Colors.transparent,
              child: SideBar(
                isExpanded: isSidebarExpanded,
                onToggle: toggleSidebar,
                selectedLabel: selectedItemLabel,
                onItemSelected: onItemSelected,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
