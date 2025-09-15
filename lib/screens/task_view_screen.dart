import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../screens/edit_task_screen.dart';

class TaskViewScreen extends StatelessWidget {
  final Task task;

  const TaskViewScreen({
    super.key,
    required this.task,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Task',
            onPressed: () => _editTask(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task Title
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Completion status
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: task.isCompleted
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.secondary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              task.isCompleted
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              size: 16,
                              color: task.isCompleted
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(context).colorScheme.onSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              task.isCompleted ? 'Completed' : 'In Progress',
                              style: TextStyle(
                                color: task.isCompleted
                                    ? Theme.of(context).colorScheme.onPrimary
                                    : Theme.of(context).colorScheme.onSecondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Priority indicator
                      _buildPriorityBadge(context),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    task.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Due Date Section
            if (task.dueDate != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getDueDateColor(context).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getDueDateColor(context).withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 16,
                          color: _getDueDateColor(context),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Due Date',
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: _getDueDateColor(context),
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat('EEEE, MMM d, yyyy').format(task.dueDate!),
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    Text(
                      _formatDueDateStatus(task.dueDate!),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: _getDueDateColor(context),
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),

            if (task.dueDate != null && task.tags.isNotEmpty)
              const SizedBox(height: 20),

            // Tags Section
            if (task.tags.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .tertiaryContainer
                      .withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.tertiaryContainer,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.local_offer,
                          size: 16,
                          color: Theme.of(context)
                              .colorScheme
                              .onTertiaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Tags',
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onTertiaryContainer,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: task.tags.map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: tag.color != null
                                ? Color(int.parse(tag.color!)).withOpacity(0.2)
                                : Theme.of(context)
                                    .colorScheme
                                    .tertiaryContainer,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: tag.color != null
                                  ? Color(int.parse(tag.color!))
                                  : Theme.of(context)
                                      .colorScheme
                                      .tertiary,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            tag.name,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: tag.color != null
                                      ? Color(int.parse(tag.color!))
                                      : Theme.of(context)
                                          .colorScheme
                                          .onTertiaryContainer,
                                ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // Task Details/Notes Section
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 300),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceVariant
                          .withOpacity(0.3),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.notes,
                          size: 20,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Task Details',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: task.description != null &&
                            task.description!.isNotEmpty
                        ? Text(
                            task.description!,
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      height: 1.6,
                                      decoration: task.isCompleted
                                          ? TextDecoration.lineThrough
                                          : TextDecoration.none,
                                    ),
                          )
                        : Text(
                            'No additional details provided for this task.',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                  fontStyle: FontStyle.italic,
                                ),
                          ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Task Metadata
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceVariant
                    .withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Task Information',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Created ${DateFormat('MMM d, yyyy \'at\' h:mm a').format(task.createdAt)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),

      // Floating action button to edit
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editTask(context),
        icon: const Icon(Icons.edit),
        label: const Text('Edit Task'),
      ),
    );
  }

  Widget _buildPriorityBadge(BuildContext context) {
    Color priorityColor;
    String priorityText;
    IconData priorityIcon;

    switch (task.priority) {
      case TaskPriority.high:
        priorityColor = Theme.of(context).colorScheme.error;
        priorityText = 'High Priority';
        priorityIcon = Icons.priority_high;
        break;
      case TaskPriority.medium:
        priorityColor = Theme.of(context).colorScheme.tertiary;
        priorityText = 'Medium Priority';
        priorityIcon = Icons.remove;
        break;
      case TaskPriority.low:
        priorityColor = Theme.of(context).colorScheme.outline;
        priorityText = 'Low Priority';
        priorityIcon = Icons.keyboard_arrow_down;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: priorityColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: priorityColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            priorityIcon,
            size: 16,
            color: priorityColor,
          ),
          const SizedBox(width: 4),
          Text(
            priorityText,
            style: TextStyle(
              color: priorityColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Color _getDueDateColor(BuildContext context) {
    if (task.isCompleted || task.dueDate == null) {
      return Theme.of(context).colorScheme.onSurfaceVariant;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDate =
        DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);

    if (dueDate.isBefore(today)) {
      return Theme.of(context).colorScheme.error;
    } else if (dueDate == today) {
      return Theme.of(context).colorScheme.tertiary;
    } else {
      return Theme.of(context).colorScheme.primary;
    }
  }

  String _formatDueDateStatus(DateTime dueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final taskDate = DateTime(dueDate.year, dueDate.month, dueDate.day);

    if (taskDate == today) {
      return 'Due Today';
    } else if (taskDate == tomorrow) {
      return 'Due Tomorrow';
    } else if (taskDate.isBefore(today)) {
      final daysDiff = today.difference(taskDate).inDays;
      return '$daysDiff day${daysDiff > 1 ? 's' : ''} overdue';
    } else {
      final daysDiff = taskDate.difference(today).inDays;
      return '$daysDiff day${daysDiff > 1 ? 's' : ''} remaining';
    }
  }

  void _editTask(BuildContext context) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => EditTaskScreen(task: task),
      ),
    );

    if (result == true) {
      if (context.mounted) {
        // Pop back to task list and refresh
        Navigator.of(context).pop(true);
        context.read<TaskProvider>().loadTasks();
      }
    }
  }
}
