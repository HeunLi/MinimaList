import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../models/tag.dart';
import '../services/database_service.dart';

class TaskProvider extends ChangeNotifier {
  List<Task> _tasks = [];
  List<Tag> _tags = [];
  bool _isLoading = false;
  String? _searchQuery;
  TaskPriority? _filterPriority;
  List<String>? _filterTags;

  // NEW: Getter for raw tasks from database (unfiltered)
  List<Task> get allTasks => List.from(_tasks);

  // EXISTING: Getter for filtered tasks (used for display)
  List<Task> get tasks {
    List<Task> filteredTasks = List.from(_tasks);

    // Apply search filter
    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      final searchLower = _searchQuery!.toLowerCase();
      filteredTasks = filteredTasks
          .where((task) =>
              task.title.toLowerCase().contains(searchLower) ||
              (task.description?.toLowerCase().contains(searchLower) ?? false) ||
              task.tags.any((tag) => tag.name.toLowerCase().contains(searchLower)))
          .toList();
    }

    // Apply priority filter
    if (_filterPriority != null) {
      filteredTasks = filteredTasks
          .where((task) => task.priority == _filterPriority)
          .toList();
    }


    // Apply tag filter
    if (_filterTags != null && _filterTags!.isNotEmpty) {
      filteredTasks = filteredTasks
          .where((task) => _filterTags!.any((tagId) =>
              task.tags.any((tag) => tag.id == tagId)))
          .toList();
    }

    return filteredTasks;
  }

  List<Task> get completedTasks =>
      tasks.where((task) => task.isCompleted).toList();
  List<Task> get incompleteTasks =>
      tasks.where((task) => !task.isCompleted).toList();

  bool get isLoading => _isLoading;
  String? get searchQuery => _searchQuery;
  TaskPriority? get filterPriority => _filterPriority;
  List<String>? get filterTags => _filterTags;
  List<Tag> get tags => List.from(_tags);

  int get completionPercentage {
    if (_tasks.isEmpty) return 0;
    return (completedTasks.length / _tasks.length * 100).round();
  }


  Future<void> loadTasks() async {
    _isLoading = true;
    notifyListeners();

    try {
      _tasks = await DatabaseService.getAllTasks();
      _tags = await DatabaseService.getAllTags();
    } catch (e) {
      debugPrint('Error loading tasks: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Note: Individual task notifications removed - now using simple daily reminders

  Future<void> addTask({
    required String title,
    String? description,
    DateTime? dueDate,
    TaskPriority priority = TaskPriority.medium,
    List<Tag> tags = const [],
  }) async {
    const uuid = Uuid();
    final task = Task(
      id: uuid.v4(),
      title: title,
      description: description,
      createdAt: DateTime.now(),
      dueDate: dueDate,
      priority: priority,
      tags: tags,
    );

    try {
      await DatabaseService.insertTask(task);
      _tasks.add(task);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding task: $e');
      rethrow;
    }
  }

  Future<void> updateTask(Task updatedTask) async {
    try {
      await DatabaseService.updateTask(updatedTask);
      final index = _tasks.indexWhere((task) => task.id == updatedTask.id);
      if (index != -1) {
        _tasks[index] = updatedTask;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating task: $e');
      rethrow;
    }
  }

  Future<void> toggleTaskCompletion(String taskId) async {
    final task = _tasks.firstWhere((task) => task.id == taskId);
    final updatedTask = task.copyWith(isCompleted: !task.isCompleted);
    await updateTask(updatedTask);
  }

  Future<void> deleteTask(String taskId) async {
    try {
      await DatabaseService.deleteTask(taskId);
      _tasks.removeWhere((task) => task.id == taskId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting task: $e');
      rethrow;
    }
  }

  void setSearchQuery(String? query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setPriorityFilter(TaskPriority? priority) {
    _filterPriority = priority;
    notifyListeners();
  }


  void setTagFilter(List<String>? tagIds) {
    _filterTags = tagIds;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = null;
    _filterPriority = null;
    _filterTags = null;
    notifyListeners();
  }

  // Tag management methods
  Future<void> addTag(String name, {String? color}) async {
    const uuid = Uuid();
    final tag = Tag(
      id: uuid.v4(),
      name: name,
      color: color,
      createdAt: DateTime.now(),
    );

    try {
      await DatabaseService.insertTag(tag);
      _tags.add(tag);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding tag: $e');
      rethrow;
    }
  }

  Future<Tag?> getOrCreateTag(String name, {String? color}) async {
    // Check if tag already exists
    Tag? existingTag = _tags.where((tag) => tag.name.toLowerCase() == name.toLowerCase()).firstOrNull;

    if (existingTag != null) {
      return existingTag;
    }

    // Check database in case it wasn't loaded
    existingTag = await DatabaseService.getTagByName(name);
    if (existingTag != null) {
      // Add to local list if not already there
      if (!_tags.any((tag) => tag.id == existingTag!.id)) {
        _tags.add(existingTag);
      }
      return existingTag;
    }

    // Create new tag
    const uuid = Uuid();
    final newTag = Tag(
      id: uuid.v4(),
      name: name,
      color: color,
      createdAt: DateTime.now(),
    );

    try {
      await DatabaseService.insertTag(newTag);
      _tags.add(newTag);
      notifyListeners();
      return newTag;
    } catch (e) {
      debugPrint('Error creating tag: $e');
      rethrow;
    }
  }

  Future<void> updateTag(Tag updatedTag) async {
    try {
      await DatabaseService.updateTag(updatedTag);
      final index = _tags.indexWhere((tag) => tag.id == updatedTag.id);
      if (index != -1) {
        _tags[index] = updatedTag;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating tag: $e');
      rethrow;
    }
  }

  Future<void> deleteTag(String tagId) async {
    try {
      await DatabaseService.deleteTag(tagId);
      _tags.removeWhere((tag) => tag.id == tagId);

      // Remove tag from all tasks
      for (int i = 0; i < _tasks.length; i++) {
        final task = _tasks[i];
        final updatedTags = task.tags.where((tag) => tag.id != tagId).toList();
        if (updatedTags.length != task.tags.length) {
          final updatedTask = task.copyWith(tags: updatedTags);
          await updateTask(updatedTask);
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting tag: $e');
      rethrow;
    }
  }
}
