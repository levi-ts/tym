import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

void main() {
  runApp(GymLogApp());
}

class GymLogApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.redAccent,
        appBarTheme: AppBarTheme(backgroundColor: Colors.black),
        textTheme: TextTheme(bodyLarge: TextStyle(color: Colors.white)),
      ),
      home: MainScreen(),
    );
  }
}

class WorkoutStorage {
  static Map<DateTime, List<Exercise>> savedWorkouts = {};
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [
    GymLogScreen(),
    CalendarScreen(),
    TrackingScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: Colors.redAccent,
        unselectedItemColor: Colors.white54,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: "Workout",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: "Calendar",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.track_changes),
            label: "Tracking",
          ),
        ],
      ),
    );
  }
}

class GymLogScreen extends StatefulWidget {
  @override
  _GymLogScreenState createState() => _GymLogScreenState();
}

class _GymLogScreenState extends State<GymLogScreen> {
  final TextEditingController _dayNameController = TextEditingController();
  List<Exercise> exercises = [];
  bool isExpanded = false;
  Map<DateTime, List<Exercise>> savedWorkouts = {};

  void _addExercise() {
    setState(() {
      exercises.add(
        Exercise(
          onUpdate: () => setState(() {}),
          onRemove: (exercise) {
            setState(() {
              exercises.remove(exercise);
            });
          },
        ),
      );
      isExpanded = true;
    });
  }

  void _saveWorkout() {
    setState(() {
      DateTime today = DateTime.now();
      WorkoutStorage.savedWorkouts[today] = List.from(exercises);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Workout saved for ${DateFormat('yyyy-MM-dd').format(DateTime.now())}!",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    String weekday = DateFormat('EEEE').format(DateTime.now());

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: TextField(
                  controller: _dayNameController,
                  style: TextStyle(color: Colors.white, fontSize: 24),
                  decoration: InputDecoration(
                    hintText: "Day Name",
                    hintStyle: TextStyle(color: Colors.white54),
                    border: InputBorder.none,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    date,
                    style: TextStyle(color: Colors.redAccent, fontSize: 18),
                  ),
                  Text(
                    weekday,
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _addExercise,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: CircleBorder(),
              padding: EdgeInsets.all(14),
            ),
            child: Icon(Icons.add, color: Colors.white, size: 28),
          ),
          SizedBox(height: 10),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children:
                    exercises
                        .map((exercise) => exercise.buildWidget())
                        .toList(),
              ),
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saveWorkout,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent,
            ),
            child: Text(
              "Save Workout",
              style: TextStyle(color: Colors.black, fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class Exercise {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController setsController = TextEditingController();
  List<TextEditingController> repsControllers = [];
  List<TextEditingController> weightControllers = [];
  bool isDropset;
  final VoidCallback onUpdate;
  final Function(Exercise) onRemove; // Callback to remove an exercise

  Exercise({
    this.isDropset = false,
    required this.onUpdate,
    required this.onRemove,
  });

  void updateSets(String value) {
    int sets = int.tryParse(value) ?? 0;
    repsControllers = List.generate(sets, (_) => TextEditingController());
    weightControllers = List.generate(sets, (_) => TextEditingController());
    onUpdate();
  }

  Widget buildWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: nameController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Exercise Name",
                      hintStyle: TextStyle(color: Colors.white54),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete,
                    color: Colors.redAccent,
                  ), // Remove button
                  onPressed: () => onRemove(this), // Call the remove function
                ),
              ],
            ),
            TextField(
              controller: setsController,
              keyboardType: TextInputType.number,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Sets",
                hintStyle: TextStyle(color: Colors.white54),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[800],
              ),
              onChanged: updateSets,
            ),
            for (int i = 0; i < repsControllers.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        repsControllers[i],
                        "Reps/Failure",
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(
                        weightControllers[i],
                        "Weight (kg/lbs)",
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Dropset", style: TextStyle(color: Colors.white)),
                Switch(
                  value: isDropset,
                  onChanged: (value) {
                    isDropset = value;
                    onUpdate();
                  },
                  activeColor: Colors.redAccent,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.text,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white54),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.grey[800],
      ),
    );
  }
}

class CalendarScreen extends StatefulWidget {
  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Workout Calendar")),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            eventLoader:
                (day) =>
                    WorkoutStorage.savedWorkouts.containsKey(day) ? [day] : [],
          ),
          SizedBox(height: 20),
          Text(
            _selectedDay == null
                ? "Select a date"
                : "Workouts for ${DateFormat('yyyy-MM-dd').format(_selectedDay!)}",
            style: TextStyle(color: Colors.redAccent, fontSize: 18),
          ),
          Expanded(
            child: ListView(
              children:
                  (_selectedDay != null &&
                          WorkoutStorage.savedWorkouts.containsKey(
                            _selectedDay,
                          ))
                      ? WorkoutStorage.savedWorkouts[_selectedDay]!
                          .map(
                            (exercise) => ListTile(
                              title: Text(
                                exercise
                                    .nameController
                                    .text, // Show exercise name
                                style: TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                "Sets: ${exercise.setsController.text}",
                                style: TextStyle(color: Colors.white70),
                              ),
                              leading: Icon(
                                Icons.fitness_center,
                                color: Colors.redAccent,
                              ),
                            ),
                          )
                          .toList()
                      : [
                        Text(
                          "No workouts found.",
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
            ),
          ),
        ],
      ),
    );
  }
}

class TrackingScreen extends StatefulWidget {
  @override
  _TrackingScreenState createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final TextEditingController sizeController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  List<CustomMetric> customMetrics = [];

  void _addCustomMetric() {
    setState(() {
      customMetrics.add(CustomMetric());
    });
  }

  void _saveTrackingData() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Tracking data saved!")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Track Your Progress")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Body Measurements",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 10),
            _buildTextField(sizeController, "Size (cm/inches)"),
            SizedBox(height: 10),
            _buildTextField(weightController, "Weight (kg/lbs)"),
            SizedBox(height: 20),
            Text(
              "Custom Metrics",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            ...customMetrics.map((metric) => metric.buildWidget()).toList(),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _addCustomMetric,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
              ),
              child: Text(
                "Add Custom Metric",
                style: TextStyle(color: Colors.white),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveTrackingData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent,
              ),
              child: Text(
                "Save Data",
                style: TextStyle(color: Colors.black, fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white54),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.grey[800],
      ),
    );
  }
}

class CustomMetric {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController valueController = TextEditingController();

  Widget buildWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: nameController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Metric Name (e.g., Body Fat %)",
                hintStyle: TextStyle(color: Colors.white54),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[800],
              ),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: valueController,
              keyboardType: TextInputType.number,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Value",
                hintStyle: TextStyle(color: Colors.white54),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
