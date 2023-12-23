import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:habit_hero/model/habit_hero_model.dart';

// methods to perform Habit Hero tasks
class HabitHeroController {
  // necessary controllers
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Habit> habits = []; // stores user's habits
  int totalPoints = 0; // can be used for gamify points

  // method that adds a habit to the database
  Future<void> addHabitEntry(Habit entry, String userUid) async {
    await _firestore.collection('users').doc(userUid).collection('habits').add({
      'name': entry.name,
      'frequency': entry.frequency,
      'duration': entry.duration,
      'completed': entry.completed,
      'streak': 0,
    });
  }

  // method that returns all the habits from database in a list
  Future<List<Habit>> fetchHabitEntries(String userUid) async {
    QuerySnapshot habitSnapshot = await _firestore
        .collection('users')
        .doc(userUid)
        .collection('habits')
        .get();

    habits = habitSnapshot.docs.map((doc) => Habit.fromFirestore(doc)).toList();

    return habits;
  }

  // method that removes a habit from the database
  Future<void> removeHabitEntry(String entryId) async {
    await _firestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .collection('habits')
        .doc(entryId)
        .delete();
  }

  // update habit entry
  Future<void> updateHabitEntry(String entryId, Habit updatedHabit) async {
    try {
      final userUid = _auth.currentUser!.uid;
      final habitRef = _firestore
          .collection('users')
          .doc(userUid)
          .collection('habits')
          .doc(entryId);

      await habitRef.update(updatedHabit.toMap());

      // Update the local list of habits with the updated habit
      final habitIndex = habits.indexWhere((habit) => habit.id == entryId);
      if (habitIndex != -1) {
        habits[habitIndex] = updatedHabit;
      }
    } catch (e) {
      // Handle any errors that occur during the update
      print('Error updating habit entry: $e');
      throw e; // You can choose to re-throw the error or handle it as needed
    }
  }

  Future<void> addDayEntry(String habitId, DateTime date, int value) async {
    String userUid = _auth.currentUser!.uid;

    try {
      await _firestore
          .collection('users')
          .doc(userUid)
          .collection('habits')
          .doc(habitId)
          .collection('dayEntries')
          .add({
        'date': Timestamp.fromDate(date), // Storing the date
        'value': value, // Storing the integer value
      });
    } catch (e) {
      print('Error adding day entry: $e');
      throw e;
    }
  }

  Future<bool> hasHabitEntries(String userId) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('habits')
        .limit(1) // We just want to check if at least one exists
        .get();

    return querySnapshot.docs.isNotEmpty;
  }

  Future<int> checkAndUpdateStreak(String userId, Habit habit) async {
    try {
      // Fetch the earliest entry in the dayEntries collection
      QuerySnapshot entrySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('habits')
          .doc(habit.id)
          .collection('dayEntries')
          .orderBy('date', descending: false)
          .limit(1)
          .get();

      if (entrySnapshot.docs.isEmpty) {
        // No entries found, return current streak
        return habit.streak;
      }

      // Get the earliest date of entry
      DateTime startDate =
          (entrySnapshot.docs.first.data() as Map<String, dynamic>)['date']
              .toDate();
      DateTime today = DateTime.now();
      DateTime endDateOfFrequencyPeriod =
          today.subtract(Duration(days: habit.frequency));

      // Check if current date is within first 'frequency' days of the habit start date
      if (today.isBefore(startDate.add(Duration(days: habit.frequency)))) {
        return habit.streak; // Do not reset the streak
      }

      // Check for entries within the 'frequency' days before the current date
      QuerySnapshot frequencySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('habits')
          .doc(habit.id)
          .collection('dayEntries')
          .where('date',
              isGreaterThanOrEqualTo:
                  Timestamp.fromDate(endDateOfFrequencyPeriod))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(today))
          .get();

      if (frequencySnapshot.docs.isEmpty) {
        // If no entries found in the last 'frequency' days, reset streak
        await updateHabitEntry(
            habit.id,
            Habit(
              id: habit.id,
              name: habit.name,
              frequency: habit.frequency,
              duration: habit.duration,
              completed: habit.completed,
              streak: 0, // reset streak to 0
            ));
        return 0;
      } else {
        // Return the current streak value
        return habit.streak;
      }
    } catch (e) {
      print('Error checking and updating streak: $e');
      return habit.streak; // Return current streak in case of error
    }
  }

  Future<int> getCurrentStreak(String userId) async {
    try {
      QuerySnapshot habitSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('habits')
          .limit(1) // Limit to the first habit
          .get();

      if (habitSnapshot.docs.isNotEmpty) {
        Habit habit = Habit.fromFirestore(habitSnapshot.docs.first);
        print("Fetched streak: ${habit.streak} for habit: ${habit.name}");
        return habit.streak;
      } else {
        print("No habits found for user: $userId");
        return 0;
      }
    } catch (e) {
      print('Error getting current streak for user: $userId, Error: $e');
      return 0;
    }
  }
}
