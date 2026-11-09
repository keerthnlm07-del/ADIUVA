import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/adiuva_colors.dart';
import '../../../../core/theme/adiuva_spacing.dart';
import '../../../../core/widgets/accessibility_scaffold.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/adiuva_card.dart';
import '../provider/todo_provider.dart';

/// Accessible Daily Tasks List Page for Cognitive Assistance
class TodoListPage extends StatefulWidget {
  const TodoListPage({super.key});

  @override
  State<TodoListPage> createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> with SingleTickerProviderStateMixin {
  final TextEditingController _taskController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _taskController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _showEditDialog(BuildContext context, TaskItem task) {
    final editController = TextEditingController(text: task.title);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Task'),
        content: CustomTextField(
          label: 'Task Title',
          controller: editController,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (editController.text.trim().isNotEmpty) {
                context.read<TodoProvider>().editTask(task.id, editController.text);
                Navigator.of(ctx).pop();
                AccessibilityScaffold.announce('Task updated');
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AccessibilityScaffold(
      pageTitle: 'Daily Tasks',
      appBar: const CustomAppBar(
        title: 'Daily Tasks',
        showBackButton: true,
      ),
      body: Consumer<TodoProvider>(
        builder: (context, provider, child) {
          final today = provider.todayTasks;
          final upcoming = provider.upcomingTasks;
          final completed = provider.completedTasks;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AdiuvaSpacing.gapLg,
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'New Task',
                      hintText: 'e.g., Water the plants',
                      controller: _taskController,
                      onSubmitted: (val) {
                        if (val.trim().isNotEmpty) {
                          provider.addTask(val);
                          _taskController.clear();
                          AccessibilityScaffold.announce('Task added: $val');
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: AdiuvaSpacing.sm),
                  IconButton.filled(
                    iconSize: 28,
                    onPressed: () {
                      final val = _taskController.text.trim();
                      if (val.isNotEmpty) {
                        provider.addTask(val);
                        _taskController.clear();
                        AccessibilityScaffold.announce('Task added: $val');
                      }
                    },
                    icon: const Icon(Icons.add_rounded),
                  ),
                ],
              ),
              AdiuvaSpacing.gapMd,
              TabBar(
                controller: _tabController,
                tabs: [
                  Tab(text: 'Today (${today.length})'),
                  Tab(text: 'Upcoming (${upcoming.length})'),
                  Tab(text: 'Completed (${completed.length})'),
                ],
              ),
              AdiuvaSpacing.gapMd,
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTaskList(context, provider, today, 'No tasks for today.'),
                    _buildTaskList(context, provider, upcoming, 'No upcoming tasks.'),
                    _buildTaskList(context, provider, completed, 'No completed tasks.'),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTaskList(BuildContext context, TodoProvider provider, List<TaskItem> list, String emptyMessage) {
    final theme = Theme.of(context);
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: AdiuvaSpacing.paddingLg,
          child: Text(emptyMessage, style: theme.textTheme.bodyLarge),
        ),
      );
    }

    return ListView.builder(
      itemCount: list.length,
      padding: const EdgeInsets.only(bottom: 80),
      itemBuilder: (context, index) {
        final task = list[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AdiuvaSpacing.sm),
          child: AdiuvaCard(
            padding: AdiuvaSpacing.paddingMd,
            child: Row(
              children: [
                Checkbox(
                  value: task.isCompleted,
                  onChanged: (_) {
                    provider.toggleTask(task.id);
                    AccessibilityScaffold.announce(
                      task.isCompleted ? 'Marked task active' : 'Marked task completed',
                    );
                  },
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => _showEditDialog(context, task),
                    child: Text(
                      task.title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                        color: task.isCompleted ? theme.colorScheme.onSurfaceVariant : null,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _showEditDialog(context, task),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: AdiuvaColors.error),
                  onPressed: () {
                    provider.deleteTask(task.id);
                    AccessibilityScaffold.announce('Task deleted');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
