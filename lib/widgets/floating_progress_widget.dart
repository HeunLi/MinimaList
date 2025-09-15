import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';

class FloatingProgressWidget extends StatefulWidget {
  const FloatingProgressWidget({super.key});

  @override
  State<FloatingProgressWidget> createState() => _FloatingProgressWidgetState();
}

class _FloatingProgressWidgetState extends State<FloatingProgressWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final totalTasks = taskProvider.allTasks.length;
        final completedTasks = taskProvider.allTasks.where((task) => task.isCompleted).length;

        if (totalTasks == 0) return const SizedBox.shrink();

        final percentage = ((completedTasks / totalTasks) * 100).round();
        final isCompleted = completedTasks >= totalTasks;
        final progressRatio = completedTasks / totalTasks;
        final brightness = progressRatio.clamp(0.0, 1.0);
        final minBrightness = 0.15; // Minimum brightness to show some color even at 0%

        return AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: GestureDetector(
                onTapDown: (_) => _animationController.forward(),
                onTapUp: (_) {
                  _animationController.reverse();
                  _showProgressDetails(context, totalTasks, completedTasks, percentage);
                },
                onTapCancel: () => _animationController.reverse(),
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isCompleted
                          ? [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context).colorScheme.primary.withOpacity(0.8),
                            ]
                          : [
                              Theme.of(context).colorScheme.primaryContainer.withOpacity(minBrightness + (brightness * 0.7)),
                              Theme.of(context).colorScheme.primaryContainer.withOpacity(minBrightness * 0.8 + (brightness * 0.6)),
                            ],
                    ),
                    boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1 + (brightness * 0.2)),
                          blurRadius: 6 + (brightness * 6),
                          offset: Offset(0, 2 + (brightness * 2)),
                          spreadRadius: brightness * 1,
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withOpacity(minBrightness + (brightness * 0.3)),
                      width: 1,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Circular progress indicator
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: CircularProgressIndicator(
                            value: completedTasks / totalTasks,
                            strokeWidth: 4,
                            strokeCap: StrokeCap.round,
                            backgroundColor: Colors.white.withOpacity(minBrightness + (brightness * 0.3)),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isCompleted
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.primary.withOpacity(0.4 + (brightness * 0.6)),
                            ),
                          ),
                        ),
                      ),
                      // Percentage text
                      Center(
                        child: Text(
                          '$percentage%',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isCompleted
                                ? Colors.white
                                : Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.5 + (brightness * 0.5)),
                            fontSize: 11,
                          ),
                        ),
                      ),
                      // Celebration icon when completed
                      if (isCompleted)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.9),
                            ),
                            child: Icon(
                              Icons.celebration,
                              size: 12,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showProgressDetails(BuildContext context, int totalTasks, int completedTasks, int percentage) {
    final isCompleted = completedTasks >= totalTasks;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 16,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.surface,
                  Theme.of(context).colorScheme.surface.withOpacity(0.95),
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with icon and title
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                        : Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isCompleted ? Icons.celebration : Icons.trending_up,
                          color: isCompleted
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.onPrimaryContainer,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isCompleted ? 'All Done!' : 'Progress Report',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isCompleted
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              isCompleted ? 'Congratulations! 🎉' : 'Keep it up!',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Progress stats
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '$completedTasks',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            Text(
                              'Completed',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '$totalTasks',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              'Total',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Progress bar with percentage
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progress',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$percentage%',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: completedTasks / totalTasks,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).colorScheme.primary,
                                Theme.of(context).colorScheme.primary.withOpacity(0.8),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Close button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}