import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:habit_hero/controller/habit_hero_controller.dart';
import 'package:habit_hero/model/habit_hero_model.dart';
import 'package:habit_hero/view/quote_view.dart';

import 'package:table_calendar/table_calendar.dart';

class CalendarView extends StatefulWidget {
  const CalendarView({super.key});

  @override
  _CalendarViewState createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  final HabitHeroController _controller = HabitHeroController();
  final String _defaultTitle = '';
  final TextEditingController _valueController = TextEditingController();
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _selectedDay = DateTime.now();
  DateTime _constDay = DateTime.now();

  Map<DateTime, List<int>> _dayEntries = {};

  @override
  void initState() {
    super.initState();
    _fetchDayEntries();
    _checkAndShowCongratulationDialog();
  }

  Future<void> _checkAndShowCongratulationDialog() async {
    String userUid = FirebaseAuth.instance.currentUser!.uid;
    List<Habit> habits = await _controller.fetchHabitEntries(userUid);

    if (habits.isNotEmpty) {
      Habit firstHabit = habits.first;
      DateTime durationDate = DateTime.parse(firstHabit.duration);
      DateTime today = DateTime.now();

      if (today.year == durationDate.year &&
          today.month == durationDate.month &&
          today.day == durationDate.day) {
        _showCongratulationDialog(firstHabit.streak);
      }
    }
  }

  void _showCongratulationDialog(int streak) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Theme(
          data: ThemeData(
              dialogBackgroundColor: const Color.fromARGB(255, 31, 86, 111)),
          child: AlertDialog(
            title: const Text(
              'Congratulations!',
              style: TextStyle(color: Colors.white), // Title text color
            ),
            content: SingleChildScrollView(
              child: ListBody(
                children: [
                  Text(
                    'You have reached your goal! You have maintained a $streak day consecutive streak',
                    style: const TextStyle(
                        color: Colors.white), // Content text color
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text(
                  'OK',
                  style: TextStyle(color: Colors.white), // Button text color
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _fetchDayEntries() async {
    String userUid = FirebaseAuth.instance.currentUser!.uid;
    List<Habit> habits = await _controller.fetchHabitEntries(userUid);

    String habitId = habits.first.id;

    FirebaseFirestore.instance
        .collection('users')
        .doc(userUid)
        .collection('habits')
        .doc(habitId)
        .collection('dayEntries')
        .get()
        .then((QuerySnapshot querySnapshot) {
      Map<DateTime, List<int>> newEntries = {};
      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        DateTime date = (data['date'] as Timestamp).toDate();
        date = DateTime(date.year, date.month, date.day);
        int value = data['value'];
        if (newEntries[date] == null) {
          newEntries[date] = [];
        }
        newEntries[date]!.add(value);
      }

      setState(() {
        _dayEntries = newEntries;
      });
    });
  }

  Future<String> _getHabitName() async {
    try {
      String userUid = FirebaseAuth.instance.currentUser!.uid;
      List<Habit> habits = await _controller.fetchHabitEntries(userUid);

      return habits.isNotEmpty ? habits.first.name : _defaultTitle;
    } catch (e) {
      return _defaultTitle;
    }
  }

  void dialogBox() async {
    _constDay = DateTime(_constDay.year, _constDay.month, _constDay.day);
    print("baal amar ${_dayEntries[_constDay]?.length ?? 0}");
    if ((_dayEntries[_constDay]?.length ?? 0) >= 1) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Theme(
            data: ThemeData(
                dialogBackgroundColor: const Color.fromARGB(255, 31, 86, 111)),
            child: const AlertDialog(
              title: Text(
                'Error Message',
                style: TextStyle(color: Colors.white),
              ),
              content: SingleChildScrollView(
                child: ListBody(
                  children: [
                    Text(
                      'You cannot enter more than one entry in a day!',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Theme(
            data: ThemeData(
              dialogBackgroundColor: const Color.fromARGB(255, 31, 86, 111),
            ),
            child: AlertDialog(
              title: const Text(
                'Record Habit Progress',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Enter today\'s habit value',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  TextField(
                    controller: _valueController,
                    cursorColor: Colors.white,
                    decoration: const InputDecoration(
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      labelText: 'Value',
                      labelStyle: TextStyle(
                        color: Colors.white,
                      ),
                      floatingLabelStyle: TextStyle(color: Colors.white),
                    ),
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  onPressed: () {
                    _incrementStreak();
                    _addDayEntry();
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  onPressed: () {
                    _valueController.clear();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          );
        },
      );
    }
  }

  void _addDayEntry() async {
    print("Attempting to add day entry...");
    if (_valueController.text.isNotEmpty) {
      try {
        int value = int.parse(_valueController.text);
        String userUid = FirebaseAuth.instance.currentUser!.uid;
        print("User UID: $userUid, Value: $value");

        List<Habit> habits = await _controller.fetchHabitEntries(userUid);
        print("Habits fetched: ${habits.length}");

        if (habits.isNotEmpty) {
          String habitId = habits.first.id;
          DateTime today = DateTime.now();
          print("Adding entry for Habit ID: $habitId, Date: $today");

          await _controller.addDayEntry(habitId, today, value);
          _fetchDayEntries();
          print("Day entry added successfully");

          _valueController.clear();
          setState(() {});
        }
      } catch (e) {
        print('Error adding day entry: $e');
      }
    } else {
      print("Value field is empty");
    }
  }

  void _incrementStreak() async {
    try {
      String userUid = FirebaseAuth.instance.currentUser!.uid;

      // Fetch the user's habits
      List<Habit> habits = await _controller.fetchHabitEntries(userUid);

      // Check if there is at least one habit
      if (habits.isNotEmpty) {
        Habit habitToIncrement = habits.first;

        if (!habitToIncrement.completed) {
          // Increment the streak
          habitToIncrement.streak += 1;

          // Update the habit entry in the database
          await _controller.updateHabitEntry(
              habitToIncrement.id, habitToIncrement);

          // Refresh the UI if necessary
          setState(() {
            // You may want to update the UI here to reflect the updated streak
          });
        }
      }
    } catch (e) {
      // Handle any errors that may occur during the increment
      print('Error incrementing streak: $e');
      // You can show an error message to the user if needed
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Rocket Icon
              const Icon(
                Icons.rocket_launch,
                color: Colors.white,
              ),
              const SizedBox(width: 8), // Space between icon and streak number

              // FutureBuilder to get the streak value
              FutureBuilder<int>(
                future: _controller
                    .getCurrentStreak(FirebaseAuth.instance.currentUser!.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator(
                      color: Colors.white,
                    );
                  } else if (snapshot.hasData) {
                    return Text(
                      '${snapshot.data}', // Streak number
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    );
                  } else {
                    return const Text(
                      '0', // Default value in case of error or no data
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    );
                  }
                },
              ),
              const SizedBox(
                  width: 16), // Space between streak number and title

              // Title (Habit Name)
              Expanded(
                child: FutureBuilder<String>(
                  future: _getHabitName(),
                  builder:
                      (BuildContext context, AsyncSnapshot<String> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Text('Loading...',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold));
                    } else if (snapshot.hasError) {
                      return const Text('Error',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold));
                    } else {
                      return Text(snapshot.data ?? _defaultTitle,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold));
                    }
                  },
                ),
              ),
            ],
          ),
          centerTitle: true,
          backgroundColor:
              const Color.fromARGB(255, 31, 86, 111), // AppBar background color

          // Logout Button
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: () {
                FirebaseAuth.instance.signOut();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
            IconButton(
              icon: const Icon(
                Icons.format_quote,
                color: Colors.white,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MotivationalQuotePage(),
                  ),
                );
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: TableCalendar(
                rowHeight: 45,
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
                focusedDay: _focusedDay,
                firstDay: DateTime.utc(2010, 10, 16),
                lastDay: DateTime.utc(2030, 3, 14),
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: ((selectedDay, focusedDay) {
                  DateTime normalizedSelectedDay = DateTime(
                      selectedDay.year, selectedDay.month, selectedDay.day);
                  DateTime normalizedFocusedDay = DateTime(
                      focusedDay.year, focusedDay.month, focusedDay.day);
                  setState(() {
                    _selectedDay = normalizedSelectedDay;
                    _focusedDay = normalizedFocusedDay;
                  });
                }),
                eventLoader: (day) {
                  return _dayEntries[day] ?? [];
                },
                onFormatChanged: (format) {
                  if (_calendarFormat != format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  }
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
                calendarStyle: const CalendarStyle(
                  // Here you define the selected day style
                  selectedDecoration: BoxDecoration(
                    color: Color.fromARGB(
                        255, 31, 86, 111), // Your selected day color
                    shape: BoxShape.circle,
                  ),
                  // You can also define other styles like today's style
                  todayDecoration: BoxDecoration(
                    color: Color.fromARGB(255, 40, 139,
                        185), // Color for today (if different from selected)
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _dayEntries[_selectedDay]?.length ?? 0,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 10, right: 10),
                    child: Container(
                      margin: const EdgeInsets.all(7.0),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 31, 86, 111),
                        borderRadius: BorderRadius.circular(5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5), // Shadow color
                            spreadRadius: 2,
                            blurRadius: 7,
                            offset: const Offset(
                                0, 2), // Changes position of shadow
                          ),
                        ],
                      ),
                      child: ListTile(
                        title: Text(
                          'Value: ${_dayEntries[_selectedDay]![index]}',
                          style: const TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ), // Replace with your actual content
        floatingActionButton: FloatingActionButton(
          backgroundColor: const Color.fromARGB(255, 31, 86, 111),
          onPressed: dialogBox,
          child: const Icon(
            Icons.add,
            color: Colors.white,
          ),
        ));
  }
}
