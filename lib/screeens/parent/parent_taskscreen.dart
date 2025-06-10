import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jiffy/jiffy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api_constants.dart';
import 'package:childcompass/provider/parent_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ParentTaskScreen extends ConsumerStatefulWidget {
  @override
  _ParentTaskScreenState createState() => _ParentTaskScreenState();
}

class _ParentTaskScreenState extends ConsumerState<ParentTaskScreen> {
  final List<Map<String, dynamic>> _tasks = [];
  final _titleController = TextEditingController();
  final _priorityController = TextEditingController();
  final _timelineController = TextEditingController();

  int _selectedTab = 0;
  final List<String> _tabs = ['All\nTasks', 'Pending\nTasks', 'Completed\nTasks'];
  Jiffy? _selectedDateTime;

  @override
  void initState() {
    super.initState();
    fetchCurrentChildTasks().then((loadedTasks) {
      setState(() {
        _tasks.addAll(loadedTasks);
      });
    });
  }

  Future<dynamic> _addTask() async {
    final String? parentEmail = ref.read(parentEmailProvider);
    final String? targetChildID = ref.read(currentChildProvider);

    if (parentEmail == null || targetChildID == null) {
      print("❌ Missing email or child ID");
      return null;
    }

    if (_selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select a date and time')));
      return null;
    }

    // Ensure UTC and proper ISO format
    final datetimeInUTC = _selectedDateTime!.dateTime.toUtc().toIso8601String();
    print("Formatted datetime for API: $datetimeInUTC");

    final url = Uri.parse(ApiConstants.addTask);
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'title': _titleController.text,
          'datetime': datetimeInUTC,
          'priority': _priorityController.text,
          'targetChildID': targetChildID,
          'parentEmail': parentEmail,
        }),
      );

      print("API Response: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        print("Saved task data from backend: ${responseData['task']}");

        // Create complete task object with all fields
        final newTask = Map<String, dynamic>.from({
          ...responseData['task'],
          'timeline': _selectedDateTime!.format(pattern: 'do MMM yyyy - h:mm a'),
        });

        setState(() => _tasks.add(newTask));
        return newTask;
      } else {
        throw Exception('Failed with status ${response.statusCode}');
      }
    } catch (e) {
      print("Error saving task: $e");
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save task: ${e.toString()}')));
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> fetchCurrentChildTasks() async {
    final String? parentEmail = ref.read(parentEmailProvider);
    final String? connectionString = ref.read(currentChildProvider); // Using connectionString instead of childId

    print('🔑 Parent: $parentEmail');
    print('👶 Current Child: $connectionString');


    if (parentEmail == null || connectionString == null) {
      print("❌ Parent email or child connection string is null");
      return [];
    }

    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.fetchTaskParent}$parentEmail/$connectionString'),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final tasks = List<Map<String, dynamic>>.from(data['tasks'] ?? []);

        return tasks.map((task) {
          DateTime? datetime;
          String? formattedDate;

          if (task['datetime'] != null) {
            try {
              datetime = DateTime.parse(task['datetime']);
              formattedDate = Jiffy.parseFromDateTime(datetime).format(pattern: 'do MMM yyyy - h:mm a');
            } catch (e) {
              print('⚠️ Error parsing datetime for task ${task['_id']}: $e');
            }
          }

          return {
            ...task,
            'timeline': formattedDate ?? 'Not scheduled',
          };
        }).toList();
      } else {
        print("❌ Failed to fetch tasks: ${response.statusCode} - ${response.body}");
        return [];
      }
    } catch (e) {
      print('⚠️ Exception in fetchCurrentChildTasks: $e');
      return [];
    }
  }


  Future<void> fetchIncompleteParentTasks() async {
    print("🔍 Fetching incomplete parent tasks...");
    final String? connectionString = ref.read(currentChildProvider);

    if (connectionString == null || connectionString.isEmpty) return;

    try {
      final url = '${ApiConstants.fetchTask}incomplete-tasks?connectionString=$connectionString';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> fetchedTasks = json.decode(response.body);

        setState(() {
          // Filter only incomplete tasks from parent
          final incompleteParentTasks = fetchedTasks.where((task) {
            return task['from'] == 'parent' && task['completed'] == false;
          }).map((task) {
            return {
              '_id': task['_id'],
              'title': task['title'],
              'priority': task['priority'],
              'timeline': Jiffy.parse(task['datetime']).format(pattern: 'do MMM yyyy - h:mm a'),
              'datetime': DateTime.parse(task['datetime']),
              'from': 'parent',
              'completed': false,
              'connectionString': task['connectionString'] ?? connectionString,
            };
          }).toList();

          // Replace only incomplete parent tasks
          _tasks.removeWhere((task) => task['from'] == 'parent' && task['completed'] == false);
          _tasks.addAll(incompleteParentTasks);
        });

        print("✅ Incomplete parent tasks fetched and updated.");
      } else {
        throw Exception('Failed to fetch tasks: ${response.statusCode}');
      }
    } catch (e) {
      print("‼️ Exception in fetchIncompleteParentTasks: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching incomplete tasks: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> fetchCompletedParentTasks() async {
    print("🔍 Fetching completed parent tasks...");
    final String? connectionString = ref.read(currentChildProvider);

    if (connectionString == null || connectionString.isEmpty) return;

    try {
      final url = '${ApiConstants.fetchTask}completed-tasks?connectionString=$connectionString';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> fetchedTasks = json.decode(response.body);

        setState(() {
          // Filter only completed tasks from parent
          final completedParentTasks = fetchedTasks.where((task) {
            return task['from'] == 'parent' && task['completed'] == true;
          }).map((task) {
            return {
              '_id': task['_id'],
              'title': task['title'],
              'priority': task['priority'],
              'timeline': Jiffy.parse(task['datetime']).format(pattern: 'do MMM yyyy - h:mm a'),
              'datetime': DateTime.parse(task['datetime']),
              'from': 'parent',
              'completed': true,
              'connectionString': task['connectionString'] ?? connectionString,
            };
          }).toList();

          // Replace only completed parent tasks
          _tasks.removeWhere((task) => task['from'] == 'parent' && task['completed'] == true);
          _tasks.addAll(completedParentTasks);

        });

        print("✅ Completed parent tasks fetched and updated.");
      } else {
        throw Exception('Failed to fetch tasks: ${response.statusCode}');
      }
    } catch (e) {
      print("‼️ Exception in fetchCompletedParentTasks: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching completed tasks: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  void _clearFormFields() {
    _titleController.clear();
    _priorityController.clear();
    _timelineController.clear();
    setState(() {
      _selectedDateTime = null;
    });
  }


  void _showAddTaskForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
              16, 24, 16, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Wrap(
            runSpacing: 20,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Text(
                "Add New Task",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  fontFamily: "Quantico"
                ),
                textAlign: TextAlign.center,
              ),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              GestureDetector(
                onTap: _selectDateAndTime,
                child: AbsorbPointer(
                  child: TextField(
                    controller: _timelineController,
                    decoration: InputDecoration(
                      labelText: 'Select Date & Time',
                      suffixIcon: Icon(Icons.calendar_today_outlined),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
              DropdownButtonFormField<String>(
                value: _priorityController.text.isEmpty ? null : _priorityController.text,
                decoration: InputDecoration(
                  labelText: 'Priority',
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: ['Low', 'Medium', 'High']
                    .map((priority) => DropdownMenuItem(
                  value: priority,
                  child: Text(priority),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _priorityController.text = value!;
                  });
                },
              ),
              SizedBox(height: 10),
              ElevatedButton.icon(
                icon: Icon(Icons.save_rounded),
                label: Text('Save Task'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF373E4E),
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 55),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () async {
                  try {
                    final task = await _addTask();
                    if (task != null) {
                      // Clear fields only after successful save
                      _clearFormFields();
                      // Close the bottom sheet
                      if (mounted) Navigator.of(context).pop();
                    }
                  } catch (e) {
                    // Error is already handled in _addTask
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }


  void _editTask(int index) {
    _titleController.text = _tasks[index]['title'];
    try {
      _selectedDateTime = Jiffy.parse(_tasks[index]['datetime']);
      print("Original datetime from API: ${_tasks[index]['datetime']}");
      print("Parsed datetime: ${_selectedDateTime?.format()}");
    } catch (e) {
      // Fallback to current date if parsing fails
      _selectedDateTime = Jiffy.now();
      print("Error parsing datetime: $e");
    }
    _priorityController.text = _tasks[index]['priority'];
    _timelineController.text = _tasks[index]['timeline'];

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text('Edit Task'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                    controller: _titleController,
                    decoration: InputDecoration(labelText: 'Title')),
                SizedBox(height: 12),
                GestureDetector(
                  onTap: _selectDateAndTime,
                  child: AbsorbPointer(
                    child: TextField(
                      controller: _timelineController,
                      decoration: InputDecoration(
                        labelText: 'Date & Time',
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _priorityController.text.isEmpty
                      ? null
                      : _priorityController.text,
                  decoration: InputDecoration(labelText: 'Priority'),
                  items: ['Low', 'Medium', 'High']
                      .map((priority) => DropdownMenuItem(
                    value: priority,
                    child: Text(priority),
                  ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _priorityController.text = value!;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _tasks[index] = {
                    'title': _titleController.text,
                    'timeline': _selectedDateTime!.format(pattern: 'do MMM yyyy - h:mm a'),
                    'datetime': _selectedDateTime?.dateTime.toIso8601String(),
                    'priority': _priorityController.text,
                  };

                });
                Navigator.of(context).pop();
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _deleteTask(int index) {
    setState(() {
      _tasks.removeAt(index);
    });
  }
  List<Map<String, dynamic>> _filteredTasks() {
    if (_selectedTab == 0) return _tasks;
    if (_selectedTab == 1) {
      // Fetch incomplete tasks when the 'Pending Tasks' tab is selected
      fetchIncompleteParentTasks();
      return _tasks.where((task) => task['completed'] == false).toList();
    }
    if (_selectedTab == 2) {
      // Fetch completed tasks when the 'Completed Tasks' tab is selected
      fetchCompletedParentTasks();
      return _tasks.where((task) => task['completed'] == true).toList();
    }
    return _tasks;
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Create Task', style: TextStyle(color: Colors.white, fontFamily: "Quantico")),
        elevation: 0,
        backgroundColor: Color(0xFF373E4E),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(30),
              ),
              child: Stack(
                children: [
                  AnimatedAlign(
                    alignment: _selectedTab == 0
                        ? Alignment.centerLeft
                        : _selectedTab == 1
                        ? Alignment.center
                        : Alignment.centerRight,
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: Container(
                      width: MediaQuery.of(context).size.width / 3 - 22,
                      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF2D3748), // Dark grey (matches app bar)
                            Color(0xFF319795), // Deep teal
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blueAccent.withOpacity(0.3),
                            blurRadius: 10,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: List.generate(_tabs.length, (index) {
                      final isSelected = _selectedTab == index;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedTab = index;
                            });
                          },
                          child: Container(
                            alignment: Alignment.center,
                            child: Text(
                              _tabs[index].split(' ').join('\n'),
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black87,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                height: 1.2,
                                fontFamily: "Quantico",
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: _tasks.isEmpty
                  ? Center(child: Text("No tasks yet. Tap + to add one.", style: TextStyle(color: Color(0xFF718096))))
                  : ListView.builder(
                itemCount: _filteredTasks().length,
                itemBuilder: (context, index) {
                  final task = _filteredTasks()[index];
                  return Container(
                    margin: EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Color(0xFFF5F7FA), // White card BG
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFFE2E8F0).withOpacity(0.3), // Subtle grey shadow
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      title: Text(
                        task['title'],
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A202C),
                            fontFamily: "Quantico" // Dark grey primary text
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 4),
                          // When displaying the time in ListTile:
                          Text(
                            "Scheduled: ${task['timeline']}",
                            style: TextStyle(
                              color: Color(0xFF718096),
                              fontFamily: 'Quantico', // Add your font family here
                            ),
                          ),
                          Text(
                            "Priority: ${task['priority']}",
                            style: TextStyle(
                              color: Color(0xFF718096),
                              fontFamily: 'Quantico', // Add your font family here
                            ),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Edit Button
                          Container(
                            decoration: BoxDecoration(
                              color: Color(0xFFE2E8F0), // Light grey BG
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              icon: Icon(Icons.edit, color: Color(0xFF4A5568)), // Dark grey icon
                              onPressed: () => _editTask(_tasks.indexOf(task)),
                            ),
                          ),
                          SizedBox(width: 8),
                          // Delete Button
                          Container(
                            decoration: BoxDecoration(
                              color: Color(0xFFFED7D7), // Light red BG
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              icon: Icon(Icons.delete, color: Color(0xFFE53E3E)), // Red icon
                              onPressed: () => _deleteTask(_tasks.indexOf(task)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskForm,
        child: Icon(Icons.add, color: Colors.white),
        backgroundColor: Color(0xFF373E4E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }


  Future<void> _selectDateAndTime() async {
    final DateTime now = DateTime.now();
    final DateTime initialDate = _selectedDateTime?.dateTime ?? now;

    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (date != null) {
      final TimeOfDay initialTime = _selectedDateTime != null
          ? TimeOfDay.fromDateTime(_selectedDateTime!.dateTime)
          : TimeOfDay.now();

      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: initialTime,
      );

      if (time != null) {
        setState(() {
          _selectedDateTime = Jiffy.parseFromDateTime(DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          ));
          _timelineController.text =
              _selectedDateTime!.format(pattern: 'do MMM yyyy - h:mm a');
        });
      }
    }
  }



}