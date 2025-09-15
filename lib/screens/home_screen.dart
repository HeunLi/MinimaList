import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../models/tag.dart';
import '../widgets/task_item.dart';
import '../widgets/progress_indicator.dart';
import '../widgets/app_drawer.dart';
import '../screens/add_task_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  bool _showCompleted = true;
  bool _isSearching = false;
  late AnimationController _searchAnimationController;
  late Animation<double> _searchAnimation;
  String _currentSearchValue = '';

  @override
  void initState() {
    super.initState();
    _searchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _searchAnimation = CurvedAnimation(
      parent: _searchAnimationController,
      curve: Curves.easeInOut,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().loadTasks();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchAnimationController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
    });

    if (_isSearching) {
      // Restore the search value when opening
      _searchController.text = _currentSearchValue;
      _searchAnimationController.forward();
    } else {
      // Save the current search value before closing
      _currentSearchValue = _searchController.text;
      _searchAnimationController.reverse();
    }
  }

  void _clearSearch() {
    setState(() {
      _currentSearchValue = '';
      _searchController.clear();
    });
    context.read<TaskProvider>().setSearchQuery(null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          // Main content
          Consumer<TaskProvider>(
            builder: (context, taskProvider, child) {
              if (taskProvider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              final hasAnyTasksInDatabase = taskProvider.allTasks.isNotEmpty;
              final incompleteTasks = taskProvider.incompleteTasks;
              final completedTasks = taskProvider.completedTasks;
              final hasFilteredTasks =
                  incompleteTasks.isNotEmpty || completedTasks.isNotEmpty;

              return CustomScrollView(
                slivers: [
                  // Clean App Bar
                  SliverAppBar.large(
                    title: const Text(
                      'MinimaList',
                      style: TextStyle(
                        fontWeight: FontWeight.w300,
                        letterSpacing: 1.2,
                      ),
                    ),
                    actions: [
                      // Search button - only show if there are tasks
                      if (hasAnyTasksInDatabase)
                        IconButton(
                          icon: Icon(
                            _currentSearchValue.isNotEmpty
                                ? Icons.search
                                : Icons.search,
                            color: _currentSearchValue.isNotEmpty
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                          tooltip: 'Search Tasks',
                          onPressed: _toggleSearch,
                        ),
                    ],
                  ),

                  // Progress Indicator
                  if (hasFilteredTasks)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: TaskProgressIndicator(
                          totalTasks:
                              incompleteTasks.length + completedTasks.length,
                          completedTasks: completedTasks.length,
                        ),
                      ),
                    ),

                  // Active search indicator
                  if (_currentSearchValue.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primaryContainer
                                .withOpacity(0.5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.search,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Searching for: "$_currentSearchValue"',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 16),
                                onPressed: _clearSearch,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Active Filters Display
                  if (taskProvider.filterPriority != null ||
                      (taskProvider.filterTags != null && taskProvider.filterTags!.isNotEmpty))
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
                            if (taskProvider.filterTags != null && taskProvider.filterTags!.isNotEmpty)
                              ...taskProvider.filterTags!.map((tagId) {
                                final tag = taskProvider.tags.firstWhere((t) => t.id == tagId, orElse: () => Tag(id: tagId, name: 'Unknown', createdAt: DateTime.now()));
                                return Chip(
                                  label: Text(tag.name),
                                  onDeleted: () {
                                    final newTags = List<String>.from(taskProvider.filterTags!)..remove(tagId);
                                    taskProvider.setTagFilter(newTags.isEmpty ? null : newTags);
                                  },
                                );
                              }),
                          ],
                        ),
                      ),
                    ),

                  // Empty States
                  if (!hasAnyTasksInDatabase)
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.task_alt,
                                size: 80,
                                color: Theme.of(context).colorScheme.outline),
                            const SizedBox(height: 24),
                            Text('No tasks yet',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant)),
                            const SizedBox(height: 8),
                            Text('Tap the + button to add your first task',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .outline)),
                          ],
                        ),
                      ),
                    ),

                  if (hasAnyTasksInDatabase && !hasFilteredTasks)
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off,
                                size: 80,
                                color: Theme.of(context).colorScheme.outline),
                            const SizedBox(height: 24),
                            Text('No tasks found',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant)),
                            const SizedBox(height: 8),
                            Text(
                                _currentSearchValue.isNotEmpty
                                    ? 'Try a different search term'
                                    : 'Try adjusting your filters',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .outline)),
                            const SizedBox(height: 16),
                            if (_currentSearchValue.isNotEmpty ||
                                taskProvider.filterPriority != null ||
                                (taskProvider.filterTags != null && taskProvider.filterTags!.isNotEmpty))
                              TextButton.icon(
                                onPressed: () {
                                  _clearSearch();
                                  taskProvider.clearFilters();
                                },
                                icon: const Icon(Icons.clear_all),
                                label: const Text('Clear Search & Filters'),
                              ),
                          ],
                        ),
                      ),
                    ),

                  // Task Lists
                  if (hasFilteredTasks) ...[
                    if (incompleteTasks.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                          child: Row(
                            children: [
                              Text('To Do',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w600)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    borderRadius: BorderRadius.circular(12)),
                                child: Text('${incompleteTasks.length}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onPrimary,
                                            fontWeight: FontWeight.w600)),
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
                    if (completedTasks.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                          child: Row(
                            children: [
                              Text('Completed',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w600)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                    color:
                                        Theme.of(context).colorScheme.outline,
                                    borderRadius: BorderRadius.circular(12)),
                                child: Text('${completedTasks.length}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onInverseSurface,
                                            fontWeight: FontWeight.w600)),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: Icon(
                                    _showCompleted
                                        ? Icons.expand_less
                                        : Icons.expand_more,
                                    size: 20),
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
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ],
              );
            },
          ),

          // Floating Search Overlay
          AnimatedBuilder(
            animation: _searchAnimation,
            builder: (context, child) {
              return Visibility(
                visible: _searchAnimation.value > 0,
                child: Stack(
                  children: [
                    // Dimmed background
                    GestureDetector(
                      onTap: _toggleSearch,
                      child: Container(
                        color: Colors.black
                            .withOpacity(0.5 * _searchAnimation.value),
                      ),
                    ),

                    // Search bar
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 20,
                      left: 16,
                      right: 16,
                      child: Transform.translate(
                        offset: Offset(0, -50 * (1 - _searchAnimation.value)),
                        child: Opacity(
                          opacity: _searchAnimation.value,
                          child: Material(
                            elevation: 8,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outline
                                      .withOpacity(0.2),
                                ),
                              ),
                              child: StatefulBuilder(
                                builder: (context, setSearchState) {
                                  return TextField(
                                    controller: _searchController,
                                    autofocus: _isSearching,
                                    decoration: InputDecoration(
                                      hintText: 'Search tasks...',
                                      prefixIcon: const Icon(Icons.search),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                            _searchController.text.isNotEmpty
                                                ? Icons.clear
                                                : Icons.close),
                                        onPressed: () {
                                          if (_searchController
                                              .text.isNotEmpty) {
                                            // Clear the search text
                                            _searchController.clear();
                                            _currentSearchValue = '';
                                            context
                                                .read<TaskProvider>()
                                                .setSearchQuery(null);
                                            setSearchState(() {});
                                          } else {
                                            // Close the search overlay
                                            _toggleSearch();
                                          }
                                        },
                                      ),
                                      border: InputBorder.none,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 16),
                                    ),
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
                                    onChanged: (query) {
                                      _currentSearchValue = query;
                                      context
                                          .read<TaskProvider>()
                                          .setSearchQuery(
                                              query.isEmpty ? null : query);
                                      setSearchState(
                                          () {}); // Update the clear button visibility
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddTask(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
      ),
    );
  }


  void _navigateToAddTask(BuildContext context) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => const AddTaskScreen()),
    );
    if (result == true && mounted) {
      context.read<TaskProvider>().loadTasks();
    }
  }
}
