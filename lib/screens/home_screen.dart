import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../widgets/task_item.dart';
import '../widgets/progress_indicator.dart';
import '../screens/add_task_screen.dart';
import '../models/task.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showCompleted = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().loadTasks();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, child) {
          if (taskProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final incompleteTasks = taskProvider.incompleteTasks;
          final completedTasks = taskProvider.completedTasks;
          final hasAnyTasks = taskProvider.tasks.isNotEmpty;

          return CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar.large(
                title: const Text(
                  'MinimaList',
                  style: TextStyle(
                    fontWeight: FontWeight.w300,
                    letterSpacing: 1.2,
                  ),
                ),
                actions: [
                  if (hasAnyTasks)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.filter_list),
                      onSelected: (value) =>
                          _handleFilterSelection(value, taskProvider),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'all',
                          child: Text('All Tasks'),
                        ),
                        const PopupMenuItem(
                          value: 'high',
                          child: Text('High Priority'),
                        ),
                        const PopupMenuItem(
                          value: 'medium',
                          child: Text('Medium Priority'),
                        ),
                        const PopupMenuItem(
                          value: 'low',
                          child: Text('Low Priority'),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: 'clear',
                          child: Text('Clear Filters'),
                        ),
                      ],
                    ),
                ],
              ),

              // Progress Indicator
              if (hasAnyTasks)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TaskProgressIndicator(
                      totalTasks: taskProvider.tasks.length,
                      completedTasks: completedTasks.length,
                    ),
                  ),
                ),

              // Search Bar
              if (hasAnyTasks)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: SearchBar(
                      controller: _searchController,
                      hintText: 'Search tasks...',
                      leading: const Icon(Icons.search),
                      trailing: [
                        if (_searchController.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              taskProvider.setSearchQuery(null);
                            },
                          ),
                      ],
                      onChanged: (query) {
                        taskProvider
                            .setSearchQuery(query.isEmpty ? null : query);
                      },
                    ),
                  ),
                ),

              // Active Filters Display
              if (taskProvider.filterPriority != null ||
                  taskProvider.filterCategory != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Wrap(
                      spacing: 8.0,
                      children: [
                        if (taskProvider.filterPriority != null)
                          Chip(
                            label: Text(
                                '${taskProvider.filterPriority!.displayName} Priority'),
                            onDeleted: () =>
                                taskProvider.setPriorityFilter(null),
                          ),
                        if (taskProvider.filterCategory != null)
                          Chip(
                            label: Text(taskProvider.filterCategory!),
                            onDeleted: () =>
                                taskProvider.setCategoryFilter(null),
                          ),
                      ],
                    ),
                  ),
                ),

              // Empty State
              if (!hasAnyTasks)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.task_alt,
                          size: 80,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'No tasks yet',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap the + button to add your first task',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Task Lists
              if (hasAnyTasks) ...[
                // Incomplete Tasks Section
                if (incompleteTasks.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                      child: Row(
                        children: [
                          Text(
                            'To Do',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${incompleteTasks.length}',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.onPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          TaskItem(task: incompleteTasks[index]),
                      childCount: incompleteTasks.length,
                    ),
                  ),
                ],

                // Completed Tasks Section
                if (completedTasks.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                      child: Row(
                        children: [
                          Text(
                            'Completed',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.outline,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${completedTasks.length}',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onInverseSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: Icon(
                              _showCompleted
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _showCompleted = !_showCompleted;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_showCompleted)
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                            TaskItem(task: completedTasks[index]),
                        childCount: completedTasks.length,
                      ),
                    ),
                ],

                // Bottom Padding
                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
              ],
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddTask(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
      ),
    );
  }

  void _handleFilterSelection(String value, TaskProvider taskProvider) {
    switch (value) {
      case 'all':
        taskProvider.clearFilters();
        break;
      case 'high':
        taskProvider.setPriorityFilter(TaskPriority.high);
        break;
      case 'medium':
        taskProvider.setPriorityFilter(TaskPriority.medium);
        break;
      case 'low':
        taskProvider.setPriorityFilter(TaskPriority.low);
        break;
      case 'clear':
        taskProvider.clearFilters();
        break;
    }
  }

  void _navigateToAddTask(BuildContext context) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const AddTaskScreen(),
      ),
    );

    if (result == true) {
      // Task was added, refresh if needed
      if (mounted) {
        context.read<TaskProvider>().loadTasks();
      }
    }
  }
}
