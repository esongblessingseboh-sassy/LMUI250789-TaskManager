import 'package:flutter/material.dart';

import '../models/task.dart';

class TaskDetailScreen extends StatefulWidget {
  final Task task;
  final ValueChanged<Task> onUpdate;
  final VoidCallback onDelete;

  const TaskDetailScreen({
    super.key,
    required this.task,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late Task taskCopy;

  @override
  void initState() {
    super.initState();
    taskCopy = widget.task;
  }

  String formatFullDate(DateTime date) {
    return '${date.day.toString().padLeft(2, "0")}/${date.month.toString().padLeft(2, "0")}/${date.year}';
  }

  void toggleCompletion() {
    setState(() {
      taskCopy.isCompleted = !taskCopy.isCompleted;
    });
    widget.onUpdate(taskCopy);
  }

  Future<void> showEditTaskSheet() async {
    final titleController = TextEditingController(text: taskCopy.title);
    final descriptionController = TextEditingController(text: taskCopy.description);
    String selectedCategory = taskCopy.category;
    String selectedPriority = taskCopy.priority;
    DateTime selectedDate = taskCopy.dueDate;
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
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
                        'Edit Task',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(labelText: 'Task Title', border: OutlineInputBorder()),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: descriptionController,
                        decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                        maxLines: 2,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a description';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: selectedCategory,
                              decoration: const InputDecoration(labelText: 'Category'),
                              items: ['Work', 'Personal', 'Shopping', 'Health']
                                  .map((category) => DropdownMenuItem(value: category, child: Text(category)))
                                  .toList(),
                              onChanged: (value) => setModalState(() => selectedCategory = value ?? selectedCategory),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: selectedPriority,
                              decoration: const InputDecoration(labelText: 'Priority'),
                              items: ['High', 'Medium', 'Low']
                                  .map((priority) => DropdownMenuItem(value: priority, child: Text(priority)))
                                  .toList(),
                              onChanged: (value) => setModalState(() => selectedPriority = value ?? selectedPriority),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ListTile(
                        title: Text('Due Date: ${formatFullDate(selectedDate)}'),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setModalState(() => selectedDate = picked);
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                        onPressed: () {
                          if (formKey.currentState?.validate() == true) {
                            setState(() {
                              taskCopy.title = titleController.text;
                              taskCopy.description = descriptionController.text;
                              taskCopy.category = selectedCategory;
                              taskCopy.priority = selectedPriority;
                              taskCopy.dueDate = selectedDate;
                            });
                            widget.onUpdate(taskCopy);
                            Navigator.pop(context);
                          }
                        },
                        child: const Text('Save Changes'),
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

  Future<bool> confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete task?'),
          content: const Text('This action cannot be undone.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
          ],
        );
      },
    );

    if (confirmed == true) {
      widget.onDelete();
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final overdue = taskCopy.dueDate.isBefore(DateTime.now()) && !taskCopy.isCompleted;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
        actions: [
          IconButton(
            icon: Icon(taskCopy.isCompleted ? Icons.check_box : Icons.check_box_outline_blank),
            onPressed: toggleCompletion,
            tooltip: taskCopy.isCompleted ? 'Mark incomplete' : 'Mark complete',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final deleted = await confirmDelete();
              if (deleted && mounted) {
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              taskCopy.title,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                decoration: taskCopy.isCompleted ? TextDecoration.lineThrough : null,
                color: overdue ? Colors.red : null,
              ),
            ),
            const SizedBox(height: 10),
            Chip(
              backgroundColor: Colors.teal.shade50,
              label: Text('${taskCopy.category} • ${taskCopy.priority}'),
            ),
            const SizedBox(height: 20),
            Text('Description', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(taskCopy.description, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            Text('Due Date', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(formatFullDate(taskCopy.dueDate), style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            Row(
              children: [
                const Text('Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(width: 10),
                Text(
                  taskCopy.isCompleted ? 'Completed' : 'Pending',
                  style: TextStyle(
                    fontSize: 16,
                    color: taskCopy.isCompleted ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
            if (overdue) ...[
              const SizedBox(height: 20),
              const Text(
                'Overdue task - please update the due date or complete it soon.',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: showEditTaskSheet,
        label: const Text('Edit Task'),
        icon: const Icon(Icons.edit),
      ),
    );
  }
}
