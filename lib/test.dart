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
    return Scaffold(
      backgroundColor: Colors.black, // Ensure consistent background
      appBar: AppBar(
        title: Text("Workout Calendar"),
        backgroundColor: Colors.black,
      ),
      body: Column(
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
                          child: ListView(
                            padding: EdgeInsets.all(16),
                            children: [
                              Text(
                                _workoutDetails[0]['workoutName'] ?? "",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              for (var exercise in _workoutDetails)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4.0,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "${exercise['name']} x${exercise['sets']}",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      for (
                                        int i = 0;
                                        i < exercise['reps'].length;
                                        i++
                                      )
                                        Text(
                                          "  ${i + 1}. ${exercise['reps'][i]}x${exercise['weights'][i]}",
                                          style: TextStyle(
                                            color: Colors.white70,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                            ],
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
      ),
    );
  }
}

class GymLogScreen extends StatefulWidget {
  @override
  _GymLogScreenState createState() => _GymLogScreenState();
}

class _GymLogScreenState extends State<GymLogScreen> {
  final TextEditingController _workoutNameController = TextEditingController();
  List<Exercise> exercises = [];
  bool isTemplate = true;
  List<String> savedTemplates = [];
  String? selectedTemplate;

  @override
  void initState() {
    super.initState();
    _loadSavedTemplates();
  }

  void _addExercise() {
    setState(() {
      exercises.add(
        Exercise(onUpdate: _checkTemplateStatus, onRemove: _removeExercise),
      );
    });
  }

  void _removeExercise(Exercise exercise) {
    setState(() {
      exercises.remove(exercise);
      _checkTemplateStatus();
    });
  }

  void _checkTemplateStatus() {
    setState(() {
      isTemplate = exercises.any((e) => e.hasEmptyFields());
    });
  }

  Future<void> _saveWorkout({bool asTemplate = false}) async {
    final prefs = await SharedPreferences.getInstance();
    DateTime today = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd').format(today);

    List<Map<String, dynamic>> workoutData =
        exercises.map((e) => e.toJson()).toList();

    if (asTemplate) {
      String templateName = _workoutNameController.text.trim();
      if (templateName.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please enter a template name.")),
        );
        return;
      }

      await prefs.setString("template_$templateName", jsonEncode(workoutData));
      await _loadSavedTemplates();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Template '$templateName' saved!")),
      );
    } else {
      await prefs.setString(formattedDate, jsonEncode(workoutData));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Workout saved for $formattedDate!")),
      );
    }
  }

  Future<void> _loadTemplate(String templateName) async {
    final prefs = await SharedPreferences.getInstance();
    String? storedTemplate = prefs.getString("template_$templateName");

    if (storedTemplate != null) {
      List<dynamic> templateData = jsonDecode(storedTemplate);
      setState(() {
        exercises =
            templateData
                .map(
                  (e) => Exercise.fromJson(
                    e,
                    _checkTemplateStatus,
                    _removeExercise,
                  ),
                )
                .toList();
      });
    }
  }

  Future<void> _deleteTemplate() async {
    if (selectedTemplate == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("template_$selectedTemplate");

    await _loadSavedTemplates();
    setState(() {
      selectedTemplate = null;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Template deleted!")));
  }

  Future<void> _loadSavedTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    setState(() {
      savedTemplates =
          keys
              .where((key) => key.startsWith("template_"))
              .map((e) => e.substring(9))
              .toList();
    });
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.add, color: Colors.white, size: 28),
                onPressed: _addExercise,
              ),
              DropdownButton<String>(
                value: selectedTemplate,
                hint: Text("Load", style: TextStyle(color: Colors.redAccent)),
                items:
                    savedTemplates
                        .map(
                          (template) => DropdownMenuItem(
                            value: template,
                            child: Text(
                              template,
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        )
                        .toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      selectedTemplate = newValue;
                    });
                    _loadTemplate(newValue);
                  }
                },
              ),
              IconButton(
                icon: Icon(Icons.save, color: Colors.greenAccent),
                onPressed: () => _saveWorkout(asTemplate: false),
              ),
              IconButton(
                icon: Icon(Icons.file_upload, color: Colors.orangeAccent),
                onPressed: () => _saveWorkout(asTemplate: true),
              ),
              if (selectedTemplate != null)
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: _deleteTemplate,
                ),
            ],
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
  bool isDropset = false;
  bool isExpanded = true;
  final VoidCallback onUpdate;
  final Function(Exercise) onRemove;

  Exercise({required this.onUpdate, required this.onRemove});

  void updateSets(String value) {
    int sets = int.tryParse(value) ?? 0;
    repsControllers = List.generate(sets, (_) => TextEditingController());
    weightControllers = List.generate(sets, (_) => TextEditingController());
    onUpdate();
  }

  bool hasEmptyFields() {
    return nameController.text.isEmpty ||
        setsController.text.isEmpty ||
        repsControllers.any((c) => c.text.isEmpty) ||
        weightControllers.any((c) => c.text.isEmpty);
  }

  Map<String, dynamic> toJson() {
    return {
      'name': nameController.text,
      'sets': setsController.text,
      'reps': repsControllers.map((c) => c.text).toList(),
      'weights': weightControllers.map((c) => c.text).toList(),
    };
  }

  factory Exercise.fromJson(
    Map<String, dynamic> json,
    VoidCallback onUpdate,
    Function(Exercise) onRemove,
  ) {
    Exercise exercise = Exercise(onUpdate: onUpdate, onRemove: onRemove);
    exercise.nameController.text = json['name'];
    exercise.setsController.text = json['sets'];
    exercise.repsControllers =
        (json['reps'] as List)
            .map((rep) => TextEditingController(text: rep))
            .toList();
    exercise.weightControllers =
        (json['weights'] as List)
            .map((weight) => TextEditingController(text: weight))
            .toList();
    return exercise;
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    isExpanded = !isExpanded;
                    onUpdate();
                  },
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () => onRemove(this),
                ),
              ],
            ),
            if (isExpanded) ...[
              SizedBox(height: 6),
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
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildTextField(repsControllers[i], "Reps"),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          "x",
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      ),
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

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _weightController.text = prefs.getString("weight") ?? "";
    });
  }

  Future<void> _saveMetrics() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("weight", _weightController.text);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Weight saved!")));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Body Weight",
            style: TextStyle(color: Colors.white, fontSize: 24),
          ),
          SizedBox(height: 20),
          TextField(
            controller: _weightController,
            style: TextStyle(color: Colors.white),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: "Weight (kg/lbs)",
              labelStyle: TextStyle(color: Colors.white54),
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.grey[800],
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saveMetrics,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent,
            ),
            child: Text(
              "Save Weight",
              style: TextStyle(color: Colors.black, fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }
}
