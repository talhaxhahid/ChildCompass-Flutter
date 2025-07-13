import 'dart:ui';
import 'package:childcompass/core/api_constants.dart';
import 'package:flutter/material.dart';
import 'package:jiffy/jiffy.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:childcompass/screeens/child/child_dashboard.dart';


class ChildTaskscreen extends StatefulWidget {
  @override
  State<ChildTaskscreen> createState() => _ChildTaskscreenState();
}

class _ChildTaskscreenState extends State<ChildTaskscreen> with TickerProviderStateMixin {
  int selectedTab = 0;
  var isLoading=false;
  final List<String> tabs = ['My Tasks', 'Parents Task', 'Completed Tasks'];

  List<Map<String, dynamic>> myTasks = [];

  final TextEditingController taskTitleController = TextEditingController();
  final TextEditingController timelineController = TextEditingController();
  Jiffy? selectedDateTime;
  Box? tasksBox;

  @override
  void initState() {
    super.initState();
    _initHive();
    checkHiveData();
  }

  void checkHiveData() async {
    var box = await Hive.openBox('tasksBox');
    var tasks = box.get('tasks');
    print("Retrieved from Hive: $tasks");
  }


  Future<void> fetchParentTasks() async {
    print("🔄 Starting to fetch parent tasks...");
    isLoading=true;
    final prefs = await SharedPreferences.getInstance();
    final connectionString = prefs.getString('connectionString');

    if (connectionString == null || connectionString.isEmpty) return;

    try {
      final url = ApiConstants.fetchTask+connectionString;
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> fetchedTasks = json.decode(response.body);

        setState(() {
          isLoading=false;
          // Create map of existing completed parent tasks
          final completedTasks = {
            for (var task in myTasks.where((t) => t['from'] == 'parent' && t['completed'] == true))
              task['_id']: task
          };

          // Merge with new tasks
          final newParentTasks = fetchedTasks.map((task) {
            return {
              '_id': task['_id'],
              'title': task['title'],
              'priority': task['priority'],
              'timeline': Jiffy.parse(task['datetime']).format(pattern: 'do MMM yyyy - h:mm a'),
              'datetime': DateTime.parse(task['datetime']),
              'from': 'parent',
              'completed': completedTasks[task['_id']]?['completed'] ?? false,
              'connectionString': task['connectionString'] ?? connectionString,
            };
          }).toList();

          // Update task list
          myTasks.removeWhere((task) => task['from'] == 'parent');
          myTasks.addAll(newParentTasks);
          _saveTasksToHive();

        });
      }
    } catch (e) {
      print("‼️ Exception in fetchParentTasks: $e");
    }
  }

  void _initHive() async {
    tasksBox = await Hive.openBox('tasksBox');
    _loadTasksFromHive(); // Separate the loading logic
    await fetchParentTasks();
  }

  Future<void> _loadTasksFromHive() async {
    try {
      final storedData = tasksBox?.get('myTasks') ?? [];
      final storedTasks = List<Map<String, dynamic>>.from(
          (storedData as List).map((x) {
            final task = Map<String, dynamic>.from(x);
            // Convert stored strings back to proper types
            if (task['datetime'] is String) {
              task['datetime'] = DateTime.parse(task['datetime']);
            }
            task['completed'] = task['completed'] == true; // Ensure boolean
            return task;
          })
      );

      print('📦 Loaded ${storedTasks.length} tasks from Hive');
      setState(() => myTasks = storedTasks);
    } catch (e) {
      print('⚠️ Error loading tasks: $e');
      setState(() => myTasks = []);
    }
  }

  Future<void> _saveTasksToHive() async {
    try {
      final tasksToSave = myTasks.map((task) => {
        ...task,
        'datetime': task['datetime'].toString(), // Convert DateTime to string
        'completed': task['completed'] == true, // Ensure boolean
      }).toList();

      await tasksBox?.put('myTasks', tasksToSave);
      print('💾 Saved ${tasksToSave.length} tasks to Hive');
    } catch (e) {
      print('⚠️ Error saving tasks: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 10, left: 16, right: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          // Your other widgets like CircleAvatar, notifications, etc.
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 20),

                  // Tabs
                  ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                      child: Container(
                        decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFF2D3748),  // Dark grey (matches app bar)
                                Color(0xFF319795),  // Deep teal
                              ],
                            ),
                          border: Border.all(color: Color(0xFF373E4E), width: 1),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              spreadRadius: 2,
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Row(
                          children: List.generate(tabs.length, (index) {
                            bool isSelected = selectedTab == index;
                            var words = tabs[index].split(' ');
                            String firstWord = words[0];
                            String secondWord = words.length > 1 ? words[1] : '';

                            return Expanded(
                              child: GestureDetector(
                                  onTap: () async {
                                    print("👉 Tab $index selected");
                                    setState(() => selectedTab = index);
                                    if (index == 1 ) {
                                      await fetchParentTasks();
                                    }
                                  },
                                child: AnimatedContainer(
                                  duration: Duration(milliseconds: 300),
                                  padding: EdgeInsets.symmetric(vertical: 11),
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.white : Colors.transparent,
                                    borderRadius: BorderRadius.circular(25),
                                    boxShadow: isSelected
                                        ? [BoxShadow(color: Color(0xFF373E4E), blurRadius: 8, spreadRadius: 2)]
                                        : [],
                                  ),
                                  alignment: Alignment.center,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        firstWord,
                                        style: TextStyle(
                                          color: isSelected ? Color(0xFF373E4E) : Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                            fontFamily: "Quantico"
                                        ),
                                      ),
                                      if (secondWord.isNotEmpty)
                                        Text(
                                          secondWord,
                                          style: TextStyle(
                                            color: isSelected ? Color(0xFF373E4E) : Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                            fontFamily: "Quantico"
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),

                  // Task List
                  Expanded(
                    child:(selectedTab == 1 && isLoading)? Center(child: CircularProgressIndicator()):myTasks.isEmpty
                        ? Center(child: Text("No tasks available"))
                        : ListView.builder(
                      itemCount: myTasks.where((task) {
                        bool show = false;
                        if (selectedTab == 0) show = !(task['completed'] ?? false) && task['from'] == 'self';
                        if (selectedTab == 1) show = task['from'] == 'parent' && !(task['completed'] ?? false);
                        if (selectedTab == 2) show = task['completed'] == true; // This is where we filter for completed tasks

                        if (show) {
                          print("Showing task: ${task['title']} (from: ${task['from']}, completed: ${task['completed']})");
                        }
                        return show;
                      }).length,
                        itemBuilder: (context, index) {
                          final filteredTasks = myTasks.where((task) {
                            if (selectedTab == 0) return !(task['completed'] ?? false) && task['from'] == 'self';
                            if (selectedTab == 1) return task['from'] == 'parent' && !(task['completed'] ?? false);
                            if (selectedTab == 2) return task['completed'] == true; // Show all completed tasks
                            return false;
                          }).toList();

                          if (index >= filteredTasks.length) return SizedBox();

                          final task = filteredTasks[index];
                          return _buildTaskCard(task);
                        },
                    ),
                  ),
                ],
              ),
            ),

            // Add Task Button positioned at the bottom-right
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 16.0, bottom: 16.0), // You can increase `right` to move it more left
                child: GestureDetector(
                  onTap: _showTaskForm,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Color(0xFF373E4E),
                        borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(Icons.add, color: Colors.white, size: 30),
                  ),
                ),
              ),
            ),


          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    final timeline = task['timeline']?.toString() ?? 'No date set';
    bool isParentTask = task['from'] == 'parent';

    return Card(
      color: isParentTask ? Colors.grey[200] : Colors.white,
      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {}, // Optional: Add tap functionality
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Checkbox
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(4),
                      onTap: () async {
                        final newCompletedState = !(task['completed'] ?? false);
                        if (isParentTask) {
                          await _markParentTaskAsCompleted(task, newCompletedState);
                        } else {
                          setState(() {
                            task['completed'] = newCompletedState;
                            _saveTasksToHive();
                          });
                        }
                      },
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: task['completed'] ? Colors.green : Colors.transparent,
                          border: Border.all(
                            color: task['completed'] ? Colors.green : Colors.grey,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: task['completed']
                            ? Icon(Icons.check, size: 16, color: Colors.white)
                            : null,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title with flexible width
                        Text(
                          task['title'],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            fontFamily: "Quantico",
                            decoration: task['completed']
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                          maxLines: 5,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        // Priority and timeline row
                        Row(
                          children: [
                            if (isParentTask && task['priority'] != null)
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _getPriorityColor(task['priority']),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  task['priority'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontFamily: "Quantico",
                                  ),
                                ),
                              ),
                            if (isParentTask && task['priority'] != null)
                              SizedBox(width: 8),
                            Flexible(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.calendar_today, size: 16, color: Color(0xFF373E4E)),
                                  SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      timeline,
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF373E4E),
                                          fontFamily: "Quantico"
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!isParentTask && !task['completed'])
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, size: 20),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 18),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 18, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'edit') {
                          selectedDateTime = task['datetime'];
                          _showTaskForm(isEditing: true, task: task);
                        } else if (value == 'delete') {
                          setState(() {
                            myTasks.remove(task);
                            _saveTasksToHive();
                          });
                        }
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

// Helper function to get priority color
  Color _getPriorityColor(String priority) {
    switch (priority?.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<void> _markParentTaskAsCompleted(Map<String, dynamic> task, bool completed) async {
    try {
      print('⏳ Starting to mark task ${task['_id']} as completed: $completed');

      // First try to get connectionString from task, then fallback to SharedPreferences
      String? connectionString = task['connectionString'];
      if (connectionString == null || connectionString.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        connectionString = prefs.getString('connectionString');
        print('ℹ️ Falling back to SharedPreferences connection string: $connectionString');
      }

      if (connectionString == null || connectionString.isEmpty) {
        throw Exception('No connection string available in task or SharedPreferences');
      }

      final url = Uri.parse('${ApiConstants.completeTask}${task['_id']}');
      final headers = {'Content-Type': 'application/json'};
      final body = json.encode({
        'completed': completed,
        'connectionString': connectionString,
      });

      print('🌐 Sending PATCH request to: $url');
      print('📦 Request body: $body');

      final response = await http.patch(url, headers: headers, body: body)
          .timeout(Duration(seconds: 10));

      print('✅ Response status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        setState(() {
          final taskIndex = myTasks.indexWhere((t) => t['_id'] == task['_id']);
          if (taskIndex != -1) {
            myTasks[taskIndex]['completed'] = responseData['completed'] ?? completed;
            _saveTasksToHive();
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Task marked as ${completed ? 'completed' : 'incomplete'}'),
            backgroundColor: Colors.green,
          ),
        );

        if (selectedTab == 2) {
          await fetchParentTasks();
        }
      } else {
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('‼️ Error in _markParentTaskAsCompleted: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update task: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  void _showTaskForm({bool isEditing = false, Map<String, dynamic>? task}) {
    if (isEditing && task != null) {
      taskTitleController.text = task['title'];
      selectedDateTime = task['datetime'];
      timelineController.text = selectedDateTime!.format(pattern: 'do MMM yyyy - h:mm a');
    } else {
      taskTitleController.clear();
      timelineController.clear();
      selectedDateTime = null;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 16,
            left: 16,
            right: 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isEditing ? 'Edit Task' : 'Add New Task',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF373E4E),
                    fontFamily: "Quantico"
                  ),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: taskTitleController,
                  decoration: InputDecoration(
                    labelText: 'Task Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 10),
                GestureDetector(
                  onTap: _selectDateAndTime,
                  child: AbsorbPointer(
                    child: TextField(
                      controller: timelineController,
                      decoration: InputDecoration(
                        labelText: 'Select Date & Time',
                        suffixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    if (taskTitleController.text.isNotEmpty && selectedDateTime != null) {
                      setState(() {
                        if (isEditing) {
                          task!['title'] = taskTitleController.text;
                          task['timeline'] = selectedDateTime!.format(pattern: 'do MMM yyyy - h:mm a');
                          task['datetime'] = selectedDateTime;
                        } else {
                          myTasks.add({
                            'title': taskTitleController.text,
                            'timeline': selectedDateTime!.format(pattern: 'do MMM yyyy - h:mm a'),
                            'datetime': selectedDateTime,
                            'from': 'self',
                            'completed': false,
                          });
                        }
                        _saveTasksToHive();
                      });
                      Navigator.pop(context);
                    }
                  },
                  icon: Icon(Icons.save),
                  label: Text(isEditing ? 'Update Task' : 'Save Task'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF373E4E),
                    foregroundColor: Colors.white,
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }


  Future<void> _selectDateAndTime() async {
    final TimeOfDay initialTime = selectedDateTime != null
        ? TimeOfDay.fromDateTime(selectedDateTime!.dateTime)
        : TimeOfDay.now();

    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (time != null) {
      setState(() {
        // Create a new DateTime with today's date but the selected time
        final now = DateTime.now();
        selectedDateTime = Jiffy.parseFromDateTime(DateTime(
          now.year,
          now.month,
          now.day,
          time.hour,
          time.minute,
        ));
        timelineController.text = selectedDateTime!.format(pattern: 'h:mm a');
      });
    }
  }
}
