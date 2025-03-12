import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
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

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [
    GymLogScreen(),
    CalendarScreen(),
    BodyMetricsScreen(), // Added new page
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
            icon: Icon(Icons.monitor_weight),
            label: "Metrics",
          ),
        ],
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
  DateTime _selectedDay = DateTime.now();
  List<dynamic> _workoutDetails = [];

  @override
  void initState() {
    super.initState();
    _loadWorkout(_selectedDay);
  }

  Future<void> _loadWorkout(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    String formattedDate = DateFormat('yyyy-MM-dd').format(date);
    String? storedWorkout = prefs.getString(formattedDate);

    setState(() {
      _selectedDay = date;
      _workoutDetails = storedWorkout != null ? jsonDecode(storedWorkout) : [];
    });
  }

  Future<void> _removeWorkout() async {
    final prefs = await SharedPreferences.getInstance();
    String formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDay);
    await prefs.remove(formattedDate);

    setState(() {
      _workoutDetails = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _selectedDay,
          calendarFormat: _calendarFormat,
          onFormatChanged: (format) {
            setState(() {
              _calendarFormat = format;
            });
          },
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            _loadWorkout(selectedDay);
          },
        ),
        Expanded(
          child:
              _workoutDetails.isEmpty
                  ? Center(
                    child: Text(
                      "No workout logged on this day",
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                  : Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: _workoutDetails.length,
                          itemBuilder: (context, index) {
                            final exercise = _workoutDetails[index];
                            return ListTile(
                              title: Text(
                                "${exercise['name']} (${exercise['workoutName']})",
                                style: TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                "Sets: ${exercise['sets']}, Reps: ${exercise['reps'].join(', ')}, Weights: ${exercise['weights'].join(', ')}",
                                style: TextStyle(color: Colors.white70),
                              ),
                            );
                          },
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _removeWorkout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                        ),
                        child: Text(
                          "Remove Workout",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
        ),
      ],
    );
  }
}

class _GymLogScreenState extends State<GymLogScreen> {
  final TextEditingController _dayNameController = TextEditingController();
  final TextEditingController _workoutNameController = TextEditingController();
  List<Exercise> exercises = [];

  void _addExercise() {
    setState(() {
      exercises.add(
        Exercise(onUpdate: () => setState(() {}), onRemove: _removeExercise),
      );
    });
  }

  void _removeExercise(Exercise exercise) {
    setState(() {
      exercises.remove(exercise);
    });
  }

  Future<void> _saveWorkout() async {
    final prefs = await SharedPreferences.getInstance();
    DateTime today = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd').format(today);

    List<Map<String, dynamic>> workoutData =
        exercises.map((e) {
          var json = e.toJson();
          json['workoutName'] = _workoutNameController.text;
          return json;
        }).toList();

    await prefs.setString(formattedDate, jsonEncode(workoutData));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Workout saved for $formattedDate!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _workoutNameController,
            style: TextStyle(color: Colors.white, fontSize: 24),
            decoration: InputDecoration(
              hintText: "Workout Name",
              hintStyle: TextStyle(color: Colors.white54),
              border: InputBorder.none,
            ),
          ),
          SizedBox(height: 10),
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

class GymLogScreen extends StatefulWidget {
  @override
  _GymLogScreenState createState() => _GymLogScreenState();
}

class Exercise {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController setsController = TextEditingController();
  List<TextEditingController> repsControllers = [];
  List<TextEditingController> weightControllers = [];
  bool isDropset = false;
  final VoidCallback onUpdate;
  final Function(Exercise) onRemove;

  Exercise({required this.onUpdate, required this.onRemove});

  void updateSets(String value) {
    int sets = int.tryParse(value) ?? 0;
    repsControllers = List.generate(sets, (_) => TextEditingController());
    weightControllers = List.generate(sets, (_) => TextEditingController());
    onUpdate();
  }

  Map<String, dynamic> toJson() {
    return {
      'name': nameController.text,
      'sets': setsController.text,
      'reps': repsControllers.map((c) => c.text).toList(),
      'weights': weightControllers.map((c) => c.text).toList(),
      'dropset': isDropset,
    };
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
                  icon: Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () => onRemove(this),
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
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey[800],
              ),
              onChanged: updateSets,
            ),
            for (int i = 0; i < repsControllers.length; i++)
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(repsControllers[i], "Reps/Failure"),
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
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.grey[800],
      ),
    );
  }
}

class BodyMetricsScreen extends StatefulWidget {
  @override
  _BodyMetricsScreenState createState() => _BodyMetricsScreenState();
}

class _BodyMetricsScreenState extends State<BodyMetricsScreen> {
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _bodyFatController = TextEditingController();
  final TextEditingController _waistController = TextEditingController();
  final TextEditingController _chestController = TextEditingController();
  final TextEditingController _armsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _weightController.text = prefs.getString("weight") ?? "";
      _bodyFatController.text = prefs.getString("bodyFat") ?? "";
      _waistController.text = prefs.getString("waist") ?? "";
      _chestController.text = prefs.getString("chest") ?? "";
      _armsController.text = prefs.getString("arms") ?? "";
    });
  }

  Future<void> _saveMetrics() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("weight", _weightController.text);
    await prefs.setString("bodyFat", _bodyFatController.text);
    await prefs.setString("waist", _waistController.text);
    await prefs.setString("chest", _chestController.text);
    await prefs.setString("arms", _armsController.text);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Metrics saved!")));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Body Metrics",
            style: TextStyle(color: Colors.white, fontSize: 24),
          ),
          SizedBox(height: 20),
          _buildMetricField("Weight (kg/lbs)", _weightController),
          _buildMetricField("Body Fat (%)", _bodyFatController),
          _buildMetricField("Waist (cm/inches)", _waistController),
          _buildMetricField("Chest (cm/inches)", _chestController),
          _buildMetricField("Arms (cm/inches)", _armsController),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saveMetrics,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent,
            ),
            child: Text(
              "Save Metrics",
              style: TextStyle(color: Colors.black, fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        style: TextStyle(color: Colors.white),
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white54),
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Colors.grey[800],
        ),
      ),
    );
  }
}
