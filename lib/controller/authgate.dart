import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:habit_hero/controller/habit_hero_controller.dart';
import 'package:habit_hero/view/add_habit_view.dart';
import 'package:habit_hero/view/calendar_view.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final HabitHeroController _controller = HabitHeroController();

  Future<bool> createUserDocument(User user) async {
    final userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
    final userDoc = await userRef.get();
    if (!userDoc.exists) {
      await userRef.set({
        'email': user.email,
      });
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: ButtonStyle(
            padding: MaterialStateProperty.all<EdgeInsets>(
              const EdgeInsets.all(15),
            ),
            backgroundColor: MaterialStateProperty.all<Color>(
                const Color.fromRGBO(18, 70, 133, 1)),
            foregroundColor: MaterialStateProperty.all<Color>(
                const Color.fromARGB(255, 255, 255, 255)),
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: const Color.fromARGB(255, 230, 244, 247),
        body: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData) {
              return SignInView();
            } else {
              final user = snapshot.data;
              return FutureBuilder<bool>(
                future: _controller.hasHabitEntries(user!.uid),
                builder: (context, habitSnapshot) {
                  if (habitSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (habitSnapshot.data == true) {
                    // User has habit entries
                    return const CalendarView();
                  } else {
                    // User does not have habit entries or error occurred
                    return const AddHabitView();
                  }
                },
              );
            }
          },
        ),
      ),
    );
  }

  Widget SignInView() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color.fromRGBO(18, 70, 133, 1),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Habit-Hero',
                style: TextStyle(
                  fontSize: 35,
                  color: Color.fromRGBO(18, 70, 133, 1),
                ),
              ),
            ),
            const SizedBox(
              height: 25,
            ),
            Container(
              decoration: const BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey,
                    blurRadius: 50,
                  ),
                ],
              ),
              child: SizedBox(
                width: 300,
                height: 470,
                child: SignInScreen(
                  providers: [
                    EmailAuthProvider(),
                    GoogleProvider(
                        clientId:
                            "721304936218-0fr50eougn4ss233mgrpe4glnucfsae6.apps.googleusercontent.com"),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
