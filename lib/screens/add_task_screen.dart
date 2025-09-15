import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';
import '../models/tag.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagController = TextEditingController();

  DateTime? _selectedDueDate;
  TaskPriority _selectedPriority = TaskPriority.medium;
  List<Tag> _selectedTags = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Task'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveTask,
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title Field
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.4),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Task Title',
                    hintText: 'What needs to be done?',
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.task_alt),
                  ),
                  style: Theme.of(context).textTheme.bodyLarge,
                  textCapitalization: TextCapitalization.sentences,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a task title';
                    }
                    return null;
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Description Field
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.4),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    hintText: 'Add more details...',
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.notes),
                  ),
                  style: Theme.of(context).textTheme.bodyMedium,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 3,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Priority Selection
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.4),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.flag),
                        const SizedBox(width: 12),
                        Text(
                          'Priority',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<TaskPriority>(
                      segments: const [
                        ButtonSegment(
                          value: TaskPriority.low,
                          label: Text('Low'),
                          icon: Icon(Icons.keyboard_arrow_down),
                        ),
                        ButtonSegment(
                          value: TaskPriority.medium,
                          label: Text('Med'),
                          icon: Icon(Icons.remove),
                        ),
                        ButtonSegment(
                          value: TaskPriority.high,
                          label: Text('High'),
                          icon: Icon(Icons.keyboard_arrow_up),
                        ),
                      ],
                      selected: {_selectedPriority},
                      onSelectionChanged: (priorities) {
                        setState(() {
                          _selectedPriority = priorities.first;
                        });
                      },
                      showSelectedIcon: false,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Due Date Selection
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.4),
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _selectDueDate,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Due Date',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedDueDate != null
                                  ? DateFormat('EEEE, MMM d, yyyy')
                                      .format(_selectedDueDate!)
                                  : 'No due date set',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: _selectedDueDate != null
                                        ? Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      if (_selectedDueDate != null)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _selectedDueDate = null;
                            });
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Tags Section
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.4),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Consumer<TaskProvider>(
                  builder: (context, taskProvider, child) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.local_offer),
                            const SizedBox(width: 12),
                            Text(
                              'Tags',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Tag input field
                        TextFormField(
                          controller: _tagController,
                          decoration: const InputDecoration(
                            hintText: 'Add a tag and press Enter',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          onFieldSubmitted: _addTag,
                          textInputAction: TextInputAction.done,
                        ),

                        const SizedBox(height: 12),

                        // Selected tags
                        if (_selectedTags.isNotEmpty) ...[
                          Text(
                            'Selected tags:',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: _selectedTags.map((tag) {
                              return Chip(
                                label: Text(tag.name),
                                backgroundColor: tag.color != null
                                    ? Color(int.parse(tag.color!))
                                    : Theme.of(context).colorScheme.secondaryContainer,
                                onDeleted: () => _removeTag(tag),
                                deleteIcon: const Icon(Icons.close, size: 18),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Existing tags
                        if (taskProvider.tags.isNotEmpty) ...[
                          Text(
                            'Available tags:',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: taskProvider.tags
                                .where((tag) => !_selectedTags.any((selected) => selected.id == tag.id))
                                .map((tag) {
                              return ActionChip(
                                label: Text(tag.name),
                                backgroundColor: tag.color != null
                                    ? Color(int.parse(tag.color!))
                                    : Theme.of(context).colorScheme.secondaryContainer,
                                onPressed: () => _selectTag(tag),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Save Button (Alternative to App Bar)
            FilledButton.icon(
              onPressed: _isLoading ? null : _saveTask,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.add_task),
              label: Text(_isLoading ? 'Saving...' : 'Add Task'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: Theme.of(context).textTheme.titleMedium,
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedDueDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Select due date',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDueDate) {
      setState(() {
        _selectedDueDate = picked;
      });
    }
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final taskProvider = context.read<TaskProvider>();

      await taskProvider.addTask(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        dueDate: _selectedDueDate,
        priority: _selectedPriority,
        tags: _selectedTags,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Task "${_titleController.text.trim()}" added successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding task: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _addTag(String tagName) async {
    if (tagName.trim().isEmpty) return;

    final taskProvider = context.read<TaskProvider>();
    try {
      final tag = await taskProvider.getOrCreateTag(tagName.trim());
      if (tag != null && !_selectedTags.any((selected) => selected.id == tag.id)) {
        setState(() {
          _selectedTags.add(tag);
          _tagController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding tag: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _selectTag(Tag tag) {
    setState(() {
      _selectedTags.add(tag);
    });
  }

  void _removeTag(Tag tag) {
    setState(() {
      _selectedTags.removeWhere((selected) => selected.id == tag.id);
    });
  }
}
