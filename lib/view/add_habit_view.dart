import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:habit_hero/controller/authgate.dart';
import 'package:habit_hero/controller/habit_hero_controller.dart';
import 'package:habit_hero/model/habit_hero_model.dart';
import 'package:habit_hero/view/calendar_view.dart';

class AddHabitView extends StatefulWidget {
  final String? entryID; // var to store each habit with unique id

  const AddHabitView({super.key, this.entryID});

  @override
  _AddHabitViewState createState() => _AddHabitViewState();
}

class _AddHabitViewState extends State<AddHabitView> {
  // necessary controllers
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final HabitHeroController controller = HabitHeroController();

  final TextEditingController habitNameController = TextEditingController();
  final TextEditingController frequencyController = TextEditingController();
  final TextEditingController durationController = TextEditingController();
  final TextEditingController streakController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  void _saveHabitEntry() async {
    final String userID = _auth.currentUser!.uid;
    final String habit = habitNameController.text;
    final String duration = durationController.text;
    final int frequency = int.tryParse(frequencyController.text) ?? 0;
    final int streak = int.tryParse(streakController.text) ?? 0;

    // check for invalid input
    if (duration.isEmpty || habit.isEmpty || frequency < 1 || frequency > 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid input. Please check the values.'),
        ),
      );
      return;
    }

    // save the habit entry
    try {
      controller.addHabitEntry(
          Habit(
            id: 'habits',
            name: habit,
            frequency: frequency,
            duration: duration,
            streak: streak,
          ),
          userID);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Habit entry saved successfully.'),
        ),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CalendarView()),
      );
      ; // navigate back once entry has been added
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving entry: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'What habit do you want to build?',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 31, 86, 111),
      ),
      body: Stack(
        children: [
          // takes in the inputs
          Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextFormField(
                    controller: habitNameController,
                    decoration: const InputDecoration(
                        labelText: 'Habit (120 characters or less)'),
                    maxLength: 120,
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  TextFormField(
                    controller: frequencyController,
                    decoration: const InputDecoration(
                        labelText: 'How often do you want to practice?'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  TextFormField(
                    controller: durationController,
                    decoration: const InputDecoration(
                        labelText: 'Select End date for habit'),
                    readOnly: true,
                    onTap: () async {
                      final DateTime? selectedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(
                            DateTime.now().year), // start from current year
                        lastDate: DateTime(2101),
                      );
                      if (selectedDate != null) {
                        // separate the Date from the DateTime
                        durationController.text =
                            selectedDate.toLocal().toString().split(' ')[0];
                      }
                    },
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: _saveHabitEntry,
                        child: const Text('Save'),
                        style: ElevatedButton.styleFrom(
                          primary: const Color.fromARGB(
                              255, 31, 86, 111), // Background color
                          onPrimary:
                              Colors.white, // Text color (foreground color)
                        ),
                      ),
                      const SizedBox(
                        width: 15,
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          await FirebaseAuth.instance
                              .signOut(); // Sign out the current user
                          // ignore: use_build_context_synchronously
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const AuthGate()),
                            (Route<dynamic> route) => false,
                          ); // Navigate back to AuthGate and remove all previous routes
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: const Color.fromARGB(255, 31, 86,
                              111), // Text color (foreground color)
                        ),
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                ],
              )),
        ],
      ),
    );
  }
}
