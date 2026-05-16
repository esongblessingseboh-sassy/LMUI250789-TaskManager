import 'package:flutter/material.dart';

import '../models/task.dart';
import '../widgets/task_card.dart';
import 'task_detail_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  List<Task> tasks = [];
  String searchQuery = "";
  String selectedFilter = "All";
  bool showSearchField = false;

  final List<String> categories = ['Work', 'Personal', 'Shopping', 'Health'];
  final List<String> priorities = ['High', 'Medium', 'Low'];
  final List<String> filters = ['All', 'Pending', 'Completed'];

  // --- Filtering Logic ---
  List<Task> get filteredTasks {
    return tasks.where((task) {
      bool matchesFilter = selectedFilter == 'All' ||
          (selectedFilter == 'Completed' && task.isCompleted) ||
          (selectedFilter == 'Pending' && !task.isCompleted);
      bool matchesSearch = searchQuery.isEmpty ||
          task.title.toLowerCase().contains(searchQuery.toLowerCase());
      return matchesFilter && matchesSearch;
    }).toList();
  }

  int get totalTasks => tasks.length;
  int get completedTasks => tasks.where((task) => task.isCompleted).length;
  int get pendingTasks => tasks.where((task) => !task.isCompleted).length;
  double get completionRate => totalTasks == 0 ? 0.0 : completedTasks / totalTasks;

  String formatShortDate(DateTime date) {
    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${monthNames[date.month - 1]} ${date.day}';
  }

  String formatFullDate(DateTime date) {
    return '${date.day.toString().padLeft(2, "0")}/${date.month.toString().padLeft(2, "0")}/${date.year}';
  }

  // --- Sorting Logic ---
  void sortByDate() {
    setState(() {
      tasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    });
  }

  void sortByPriority() {
    Map<String, int> priorityOrder = {'High': 1, 'Medium': 2, 'Low': 3};
    setState(() {
      tasks.sort((a, b) => priorityOrder[a.priority]!.compareTo(priorityOrder[b.priority]!));
    });
  }

  void deleteTask(Task task) {
    setState(() {
      tasks.remove(task);
    });
  }

  void clearAllTasks() async {
    if (tasks.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete all tasks?'),
          content: const Text('This action cannot be undone.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
          ],
        );
      },
    );

    if (confirmed == true) {
      setState(() {
        tasks.clear();
      });
    }
  }

  void toggleSearch() {
    setState(() {
      showSearchField = !showSearchField;
      if (!showSearchField) {
        searchQuery = '';
      }
    });
  }

  void showAddTaskSheet({Task? existingTask}) {
    final titleController = TextEditingController(text: existingTask?.title ?? '');
    final descriptionController = TextEditingController(text: existingTask?.description ?? '');
    
    String selectedCategory = existingTask?.category ?? categories[0];
    String selectedPriority = existingTask?.priority ?? priorities[0];
    DateTime selectedDate = existingTask?.dueDate ?? DateTime.now();

    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder( // Allows local state updates within the sheet (like date/dropdowns)
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        existingTask == null ? 'Add Task' : 'Edit Task',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      
                      // Title Field
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(labelText: 'Task Title', border: OutlineInputBorder()),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Please enter a title';
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),

                      // Description Field
                      TextFormField(
                        controller: descriptionController,
                        decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                        maxLines: 2,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Please enter a description';
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),

                      // Category & Priority Row
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: selectedCategory,
                              decoration: const InputDecoration(labelText: 'Category'),
                              items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                              onChanged: (val) => setModalState(() => selectedCategory = val!),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: selectedPriority,
                              decoration: const InputDecoration(labelText: 'Priority'),
                              items: priorities.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                              onChanged: (val) => setModalState(() => selectedPriority = val!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Date Picker
                      ListTile(
                        title: Text("Due Date: ${formatFullDate(selectedDate)}"),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) setModalState(() => selectedDate = picked);
                        },
                      ),

                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            if (existingTask == null) {
                              final newTask = Task(
                                title: titleController.text,
                                description: descriptionController.text,
                                category: selectedCategory,
                                priority: selectedPriority,
                                dueDate: selectedDate,
                              );

                              setState(() {
                                tasks.add(newTask);
                              });
                            } else {
                              setState(() {
                                existingTask.title = titleController.text;
                                existingTask.description = descriptionController.text;
                                existingTask.category = selectedCategory;
                                existingTask.priority = selectedPriority;
                                existingTask.dueDate = selectedDate;
                              });
                            }

                            Navigator.pop(context);
                          }
                        },
                        child: Text(existingTask == null ? 'Create Task' : 'Update Task'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Task Manager"),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: toggleSearch),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              if (value == 'Date') {
                sortByDate();
              } else if (value == 'Priority') {
                sortByPriority();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'Date', child: Text('Sort by Due Date')),
              PopupMenuItem(value: 'Priority', child: Text('Sort by Priority')),
            ],
          ),
          IconButton(icon: const Icon(Icons.delete_sweep), onPressed: clearAllTasks),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            if (showSearchField)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search tasks...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => setState(() => searchQuery = value),
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: filters.map((filter) {
                final isActive = filter == selectedFilter;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isActive ? Colors.teal : Colors.grey.shade200,
                        foregroundColor: isActive ? Colors.white : Colors.black87,
                        elevation: isActive ? 2 : 0,
                      ),
                      onPressed: () => setState(() => selectedFilter = filter),
                      child: Text(filter),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Card(
              color: Colors.white,
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatItem('Total', totalTasks.toString()),
                        _buildStatItem('Completed', completedTasks.toString()),
                        _buildStatItem('Pending', pendingTasks.toString()),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: completionRate,
                      color: Colors.teal,
                      backgroundColor: Colors.teal.shade100,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(completionRate * 100).round()}% completed',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: filteredTasks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.task_alt, size: 72, color: Colors.teal),
                          const SizedBox(height: 16),
                          Text(
                            tasks.isEmpty
                                ? 'No tasks yet. Tap + to add your first task.'
                                : 'No tasks match this filter.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredTasks.length,
                      itemBuilder: (context, index) {
                        final task = filteredTasks[index];
                        return Dismissible(
                          key: ValueKey(task),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            padding: const EdgeInsets.only(right: 20),
                            alignment: Alignment.centerRight,
                            decoration: BoxDecoration(
                              color: Colors.red.shade400,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          onDismissed: (_) => deleteTask(task),
                          child: TaskCard(
                            task: task,
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TaskDetailScreen(
                                    task: task,
                                    onUpdate: (updatedTask) {
                                      setState(() {});
                                    },
                                    onDelete: () {
                                      deleteTask(task);
                                      Navigator.pop(context);
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddTaskSheet(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}