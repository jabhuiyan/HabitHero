import 'package:cloud_firestore/cloud_firestore.dart';

class Habit {
  String id; // entry id
  String name; // habit
  int frequency; // how many times habit is to be practised daily
  String duration; // end date of the habit practise
  bool completed; // to check if habit is completed
  int streak;

  Habit({
    required this.id,
    required this.name,
    required this.frequency,
    required this.duration,
    this.completed = false,
    required this.streak,
  });

  // method to convert Habit data to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'frequency': frequency,
      'duration': duration,
      'completed': completed,
      'streak': streak,
    };
  }

  // named constructor to create a Habit object from Firestore data
  factory Habit.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Habit(
      id: doc.id,
      name: data['name'],
      frequency: data['frequency'],
      duration: data['duration'],
      completed: data['completed'],
      streak: data['streak'],
    );
  }

  // copyWith method
  Habit copyWith({
    String? id,
    String? name,
    int? frequency,
    String? duration,
    bool? completed,
    int? streak,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      frequency: frequency ?? this.frequency,
      duration: duration ?? this.duration,
      completed: completed ?? this.completed,
      streak: streak ?? this.streak,
    );
  }
}
