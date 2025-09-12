import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

class TaskProvider extends ChangeNotifier {
  List<Task> _tasks = [];
  bool _isLoading = false;
  String? _searchQuery;
  TaskPriority? _filterPriority;
  String? _filterCategory;

  List<Task> get tasks {
    List<Task> filteredTasks = List.from(_tasks);

    // Apply search filter
    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      filteredTasks = filteredTasks
          .where((task) =>
              task.title.toLowerCase().contains(_searchQuery!.toLowerCase()) ||
              (task.description
                      ?.toLowerCase()
                      .contains(_searchQuery!.toLowerCase()) ??
                  false))
          .toList();
    }

    // Apply priority filter
    if (_filterPriority != null) {
      filteredTasks = filteredTasks
          .where((task) => task.priority == _filterPriority)
          .toList();
    }

    // Apply category filter
    if (_filterCategory != null) {
      filteredTasks = filteredTasks
          .where((task) => task.category == _filterCategory)
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
  String? get filterCategory => _filterCategory;

  int get completionPercentage {
    if (_tasks.isEmpty) return 0;
    return (completedTasks.length / _tasks.length * 100).round();
  }

  List<String> get categories {
    return _tasks
        .where((task) => task.category != null)
        .map((task) => task.category!)
        .toSet()
        .toList()
      ..sort();
  }

  Future<void> loadTasks() async {
    _isLoading = true;
    notifyListeners();

    try {
      _tasks = await DatabaseService.getAllTasks();

      // Schedule notifications for existing tasks with due dates
      await _scheduleNotificationsForExistingTasks();
    } catch (e) {
      debugPrint('Error loading tasks: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Schedule notifications for all existing tasks that have due dates
  Future<void> _scheduleNotificationsForExistingTasks() async {
    for (final task in _tasks) {
      if (task.dueDate != null && !task.isCompleted) {
        await NotificationService.scheduleTaskNotifications(task);
      }
    }
  }

  // Method to manually reschedule all notifications (useful for debugging)
  Future<void> rescheduleAllNotifications() async {
    for (final task in _tasks) {
      await NotificationService.cancelTaskNotifications(task.id);
      if (task.dueDate != null && !task.isCompleted) {
        await NotificationService.scheduleTaskNotifications(task);
      }
    }
    debugPrint(
        'Rescheduled notifications for ${_tasks.where((t) => t.dueDate != null && !t.isCompleted).length} tasks');
  }

  Future<void> addTask({
    required String title,
    String? description,
    DateTime? dueDate,
    TaskPriority priority = TaskPriority.medium,
    String? category,
  }) async {
    const uuid = Uuid();
    final task = Task(
      id: uuid.v4(),
      title: title,
      description: description,
      createdAt: DateTime.now(),
      dueDate: dueDate,
      priority: priority,
      category: category,
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
      await NotificationService.cancelTaskNotifications(taskId);
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

  void setCategoryFilter(String? category) {
    _filterCategory = category;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = null;
    _filterPriority = null;
    _filterCategory = null;
    notifyListeners();
  }
}
