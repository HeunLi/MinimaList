import 'package:flutter/material.dart';

class TaskProgressIndicator extends StatefulWidget {
  final int totalTasks;
  final int completedTasks;
  final bool showBorder;

  const TaskProgressIndicator({
    super.key,
    required this.totalTasks,
    required this.completedTasks,
    this.showBorder = true,
  });

  @override
  State<TaskProgressIndicator> createState() => _TaskProgressIndicatorState();
}

class _TaskProgressIndicatorState extends State<TaskProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;
  double _currentProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _currentProgress = widget.totalTasks == 0
        ? 0.0
        : (widget.completedTasks / widget.totalTasks).clamp(0.0, 1.0);
    _progressAnimation = Tween<double>(
      begin: _currentProgress,
      end: _currentProgress,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(TaskProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newProgress = widget.totalTasks == 0
        ? 0.0
        : (widget.completedTasks / widget.totalTasks).clamp(0.0, 1.0);

    if (newProgress != _currentProgress) {
      _progressAnimation = Tween<double>(
        begin: _currentProgress,
        end: newProgress,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

      _controller.reset();
      _controller.forward();
      _currentProgress = newProgress;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.totalTasks == 0) return const SizedBox.shrink();

    final percentage = (_currentProgress * 100).round().clamp(0, 100);
    final isCompleted = widget.completedTasks >= widget.totalTasks;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: widget.showBorder ? BoxDecoration(
        color: isCompleted
            ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5)
            : Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primaryContainer,
          width: 1,
        ),
      ) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.primaryContainer,
                    ),
                    child: Icon(
                      isCompleted ? Icons.celebration : Icons.trending_up,
                      color: isCompleted
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onPrimaryContainer,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isCompleted ? 'All Done!' : 'Progress',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isCompleted
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(context).colorScheme.primary,
                ),
                child: Text(
                  '$percentage%',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Animated Progress Bar
          Container(
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
            child: AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _progressAnimation.value,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${widget.completedTasks} of ${widget.totalTasks} tasks completed',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              if (isCompleted)
                Text(
                  'Perfect! 🎉',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
