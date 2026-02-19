import 'package:admin/constants.dart';
import 'package:admin/controllers/menu_app_controller.dart';
import 'package:admin/firebase_options.dart';
import 'package:admin/screens/auth/login.dart';
import 'package:admin/screens/main/main_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  try {
    await FirebaseFirestore.instance.clearPersistence();
  } catch (e) {
    print("Error clearing Firestore persistence: $e");
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Deaf Assist Admin',
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: primaryColor,
        scaffoldBackgroundColor: bgColor,
        colorScheme: ColorScheme.light(
          primary: primaryColor,
          secondary: primaryColor,
          surface: secondaryColor,
        ),
        textTheme: GoogleFonts.interTextTheme(
          ThemeData.light().textTheme,
        ).copyWith(
          headlineLarge: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: darkTextColor,
          ),
          headlineMedium: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: darkTextColor,
          ),
          titleLarge: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: darkTextColor,
          ),
          titleMedium: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: darkTextColor,
          ),
          bodyLarge: GoogleFonts.inter(fontSize: 16, color: bodyTextColor),
          bodyMedium: GoogleFonts.inter(fontSize: 14, color: bodyTextColor),
          bodySmall: GoogleFonts.inter(fontSize: 12, color: bodyTextColor),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: secondaryColor,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle:
                GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: bgColor,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryColor, width: 2),
          ),
          hintStyle: GoogleFonts.inter(color: bodyTextColor.withOpacity(0.5)),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: secondaryColor,
          elevation: 0,
          iconTheme: const IconThemeData(color: darkTextColor),
          titleTextStyle: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: darkTextColor,
          ),
        ),
        dividerTheme: const DividerThemeData(color: borderColor, thickness: 1),
        dataTableTheme: DataTableThemeData(
          headingTextStyle: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: bodyTextColor,
          ),
          dataTextStyle: GoogleFonts.inter(fontSize: 13, color: darkTextColor),
          headingRowColor: WidgetStateProperty.all(bgColor),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => MenuAppController()),
        ],
        child: LoginPage(),
      ),
    );
  }
}
