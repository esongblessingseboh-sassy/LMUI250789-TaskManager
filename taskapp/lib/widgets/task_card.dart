import 'package:flutter/material.dart';
import '../models/task.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;

  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
  });

  Color getPriorityColor() {
    switch (task.priority) {
      case 'High':
        return Colors.red;
      case 'Medium':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  IconData getCategoryIcon() {
    switch (task.category) {
      case 'Work':
        return Icons.work;
      case 'Personal':
        return Icons.person;
      case 'Shopping':
        return Icons.shopping_bag;
      case 'Health':
        return Icons.favorite;
      default:
        return Icons.task;
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isOverdue =
        task.dueDate.isBefore(DateTime.now()) && !task.isCompleted;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: getPriorityColor(),
          child: Icon(
            getCategoryIcon(),
            color: Colors.white,
          ),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration:
                task.isCompleted ? TextDecoration.lineThrough : null,
            color: isOverdue ? Colors.red : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '${task.category} • ${task.priority}',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${task.dueDate.day}/${task.dueDate.month}/${task.dueDate.year}',
              style: TextStyle(
                color: isOverdue ? Colors.red : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}