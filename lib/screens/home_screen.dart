import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../models/tag.dart';
import '../widgets/task_item.dart';
import '../widgets/app_drawer.dart';
import '../widgets/floating_progress_widget.dart';
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

                  // Clear search button
                  if (_currentSearchValue.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: _clearSearch,
                            icon: const Icon(Icons.clear, size: 18),
                            label: const Text('Clear search'),
                            style: TextButton.styleFrom(
                              foregroundColor:
                                  Theme.of(context).colorScheme.primary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Active Filters Display
                  if (taskProvider.filterPriority != null ||
                      (taskProvider.filterTags != null &&
                          taskProvider.filterTags!.isNotEmpty))
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
                            if (taskProvider.filterTags != null &&
                                taskProvider.filterTags!.isNotEmpty)
                              ...taskProvider.filterTags!.map((tagId) {
                                final tag = taskProvider.tags.firstWhere(
                                    (t) => t.id == tagId,
                                    orElse: () => Tag(
                                        id: tagId,
                                        name: 'Unknown',
                                        createdAt: DateTime.now()));
                                return Chip(
                                  label: Text(tag.name),
                                  onDeleted: () {
                                    final newTags = List<String>.from(
                                        taskProvider.filterTags!)
                                      ..remove(tagId);
                                    taskProvider.setTagFilter(
                                        newTags.isEmpty ? null : newTags);
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
                                (taskProvider.filterTags != null &&
                                    taskProvider.filterTags!.isNotEmpty))
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

                    // Search bar with suggestions
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 20,
                      left: 16,
                      right: 16,
                      child: Transform.translate(
                        offset: Offset(0, -50 * (1 - _searchAnimation.value)),
                        child: Opacity(
                          opacity: _searchAnimation.value,
                          child: Consumer<TaskProvider>(
                            builder: (context, taskProvider, child) {
                              final availableTags = taskProvider.tags;
                              final filteredTags = availableTags
                                  .where((tag) => tag.name
                                      .toLowerCase()
                                      .contains(
                                          _searchController.text.toLowerCase()))
                                  .toList();

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Search Input
                                  Material(
                                    elevation: 8,
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surface,
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
                                              hintText:
                                                  'Search tasks or tags...',
                                              prefixIcon:
                                                  const Icon(Icons.search),
                                              suffixIcon: IconButton(
                                                icon: Icon(_searchController
                                                        .text.isNotEmpty
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
                                                      horizontal: 16,
                                                      vertical: 16),
                                            ),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge,
                                            onChanged: (query) {
                                              _currentSearchValue = query;
                                              context
                                                  .read<TaskProvider>()
                                                  .setSearchQuery(query.isEmpty
                                                      ? null
                                                      : query);
                                              setSearchState(
                                                  () {}); // Update suggestions
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ),

                                  // Tag Suggestions
                                  if (_searchController.text.isNotEmpty &&
                                      filteredTags.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Material(
                                      elevation: 4,
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        constraints: const BoxConstraints(
                                            maxHeight: 200),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .surface,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .outline
                                                .withOpacity(0.2),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.all(12),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.local_offer,
                                                    size: 16,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .primary,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    'Filter by tags',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .labelMedium
                                                        ?.copyWith(
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .primary,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Flexible(
                                              child: ListView.builder(
                                                shrinkWrap: true,
                                                padding: const EdgeInsets.only(
                                                    bottom: 8),
                                                itemCount: filteredTags.length,
                                                itemBuilder: (context, index) {
                                                  final tag =
                                                      filteredTags[index];
                                                  final isSelected =
                                                      taskProvider.filterTags
                                                              ?.contains(
                                                                  tag.id) ??
                                                          false;

                                                  return InkWell(
                                                    onTap: () {
                                                      _selectTagFilter(
                                                          tag, taskProvider);
                                                    },
                                                    child: Padding(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 12,
                                                          vertical: 8),
                                                      child: Row(
                                                        children: [
                                                          Container(
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                              horizontal: 8,
                                                              vertical: 4,
                                                            ),
                                                            decoration:
                                                                BoxDecoration(
                                                              color: tag.color !=
                                                                      null
                                                                  ? Color(int.parse(tag
                                                                          .color!))
                                                                      .withOpacity(
                                                                          0.2)
                                                                  : Theme.of(
                                                                          context)
                                                                      .colorScheme
                                                                      .tertiaryContainer
                                                                      .withOpacity(
                                                                          0.5),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          12),
                                                              border:
                                                                  Border.all(
                                                                color: tag.color !=
                                                                        null
                                                                    ? Color(int
                                                                        .parse(tag
                                                                            .color!))
                                                                    : Theme.of(
                                                                            context)
                                                                        .colorScheme
                                                                        .tertiary,
                                                                width: 1,
                                                              ),
                                                            ),
                                                            child: Text(
                                                              tag.name,
                                                              style: Theme.of(
                                                                      context)
                                                                  .textTheme
                                                                  .labelSmall
                                                                  ?.copyWith(
                                                                    color: tag.color !=
                                                                            null
                                                                        ? Color(int.parse(tag
                                                                            .color!))
                                                                        : Theme.of(context)
                                                                            .colorScheme
                                                                            .onTertiaryContainer,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                  ),
                                                            ),
                                                          ),
                                                          const Spacer(),
                                                          if (isSelected)
                                                            Icon(
                                                              Icons
                                                                  .check_circle,
                                                              size: 18,
                                                              color: Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .primary,
                                                            ),
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Floating progress widget
          Positioned(
            bottom: 80,
            right: 16,
            child: const FloatingProgressWidget(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddTask(context),
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  void _selectTagFilter(Tag tag, TaskProvider taskProvider) {
    final currentFilters = taskProvider.filterTags ?? [];
    List<String> newFilters;

    if (currentFilters.contains(tag.id)) {
      // Remove tag filter
      newFilters = currentFilters.where((id) => id != tag.id).toList();
    } else {
      // Add tag filter
      newFilters = [...currentFilters, tag.id];
    }

    taskProvider.setTagFilter(newFilters.isEmpty ? null : newFilters);

    // Clear text search when using tag filter
    _searchController.clear();
    _currentSearchValue = '';
    taskProvider.setSearchQuery(null);

    // Close search overlay
    _toggleSearch();
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
