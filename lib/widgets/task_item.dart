import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../screens/edit_task_screen.dart';

class TaskItem extends StatelessWidget {
  final Task task;

  const TaskItem({
    super.key,
    required this.task,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Dismissible(
        key: ValueKey(
            '${task.id}_${task.isCompleted}'), // Include completion state in key
        direction: DismissDirection.horizontal,

        // Right swipe (start to end) - Toggle completion
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            // Toggle completion
            _toggleCompletion(context);
            return false; // Don't actually dismiss
          } else if (direction == DismissDirection.endToStart) {
            // Show delete confirmation
            return await _showDeleteConfirmation(context);
          }
          return false;
        },

        onDismissed: (direction) {
          if (direction == DismissDirection.endToStart) {
            // Delete task
            context.read<TaskProvider>().deleteTask(task.id);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Task deleted')),
            );
          }
        },

        // Background for swipe gestures
        background: Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: task.isCompleted
                ? Theme.of(context).colorScheme.secondary
                : Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                task.isCompleted ? Icons.undo : Icons.check,
                color: task.isCompleted
                    ? Theme.of(context).colorScheme.onSecondary
                    : Theme.of(context).colorScheme.onPrimary,
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(
                task.isCompleted ? 'Undo' : 'Done!',
                style: TextStyle(
                  color: task.isCompleted
                      ? Theme.of(context).colorScheme.onSecondary
                      : Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        // Background for left swipe (delete)
        secondaryBackground: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.error,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Delete',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onError,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.delete,
                color: Theme.of(context).colorScheme.onError,
                size: 28,
              ),
            ],
          ),
        ),

        child: Card(
          elevation: 0,
          color: task.isCompleted
              ? Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3)
              : Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: task.isCompleted
                  ? Theme.of(context).colorScheme.outline.withOpacity(0.2)
                  : Theme.of(context).colorScheme.outline.withOpacity(0.4),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Checkbox
                GestureDetector(
                  onTap: () => _toggleCompletion(context),
                  child: _buildCheckbox(context),
                ),
                const SizedBox(width: 12),

                // Task Content - Tappable area for editing
                Expanded(
                  child: GestureDetector(
                    onTap: () => _editTask(context),
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title and Priority
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                task.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      decoration: task.isCompleted
                                          ? TextDecoration.lineThrough
                                          : TextDecoration.none,
                                      color: task.isCompleted
                                          ? Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                      fontWeight: FontWeight.w500,
                                    ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            _buildPriorityIndicator(context),
                          ],
                        ),

                        // Description
                        if (task.description != null &&
                            task.description!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            task.description!,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: task.isCompleted
                                      ? Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant
                                          .withOpacity(0.7)
                                      : Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                  decoration: task.isCompleted
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],

                        // Meta Information
                        if (task.dueDate != null || task.category != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              // Due Date
                              if (task.dueDate != null) ...[
                                Icon(
                                  Icons.schedule,
                                  size: 14,
                                  color: _getDueDateColor(context),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatDueDate(task.dueDate!),
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: _getDueDateColor(context),
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                              ],

                              // Category
                              if (task.category != null) ...[
                                if (task.dueDate != null) ...[
                                  const SizedBox(width: 12),
                                  Container(
                                    width: 4,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color:
                                          Theme.of(context).colorScheme.outline,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                ],
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primaryContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    task.category!,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimaryContainer,
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckbox(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: task.isCompleted
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline,
          width: 2,
        ),
        color: task.isCompleted
            ? Theme.of(context).colorScheme.primary
            : Colors.transparent,
      ),
      child: task.isCompleted
          ? Icon(
              Icons.check,
              size: 16,
              color: Theme.of(context).colorScheme.onPrimary,
            )
          : null,
    );
  }

  Widget _buildPriorityIndicator(BuildContext context) {
    if (task.priority == TaskPriority.medium) return const SizedBox.shrink();

    Color priorityColor;
    switch (task.priority) {
      case TaskPriority.high:
        priorityColor = Theme.of(context).colorScheme.error;
        break;
      case TaskPriority.low:
        priorityColor = Theme.of(context).colorScheme.tertiary;
        break;
      case TaskPriority.medium:
        return const SizedBox.shrink();
    }

    return Container(
      width: 8,
      height: 8,
      margin: const EdgeInsets.only(left: 8, top: 4),
      decoration: BoxDecoration(
        color: priorityColor,
        shape: BoxShape.circle,
      ),
    );
  }

  Color _getDueDateColor(BuildContext context) {
    if (task.isCompleted) {
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
      return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }

  String _formatDueDate(DateTime dueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final taskDate = DateTime(dueDate.year, dueDate.month, dueDate.day);

    if (taskDate == today) {
      return 'Today';
    } else if (taskDate == tomorrow) {
      return 'Tomorrow';
    } else if (taskDate.isBefore(today)) {
      final daysDiff = today.difference(taskDate).inDays;
      return '$daysDiff day${daysDiff > 1 ? 's' : ''} overdue';
    } else {
      return DateFormat('MMM d').format(dueDate);
    }
  }

  void _toggleCompletion(BuildContext context) {
    context.read<TaskProvider>().toggleTaskCompletion(task.id);

    // Show feedback snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          task.isCompleted ? 'Task marked incomplete' : 'Task completed!',
        ),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<bool> _showDeleteConfirmation(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Delete Task'),
              content: Text('Are you sure you want to delete "${task.title}"?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  void _editTask(BuildContext context) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => EditTaskScreen(task: task),
      ),
    );

    if (result == true) {
      if (context.mounted) {
        context.read<TaskProvider>().loadTasks();
      }
    }
  }
}
