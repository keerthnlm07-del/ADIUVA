import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/adiuva_colors.dart';
import '../../../../core/theme/adiuva_spacing.dart';
import '../../../../core/widgets/accessibility_scaffold.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/adiuva_card.dart';
import '../provider/reminder_provider.dart';

/// Accessible Reminders, Medication & Calendar Page
class RemindersPage extends StatefulWidget {
  const RemindersPage({super.key});

  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedCalendarDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic> && args.containsKey('tab')) {
      final initialTab = args['tab'] as int;
      if (initialTab >= 0 && initialTab < 3) {
        _tabController.index = initialTab;
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddDialog(BuildContext context, ReminderType type) {
    final titleController = TextEditingController();
    final medNameController = TextEditingController();
    final dosageController = TextEditingController();
    TimeOfDay selectedTime = TimeOfDay.now();
    String recurrence = 'Daily';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(type == ReminderType.medication ? 'Add Medication' : 'Add Reminder'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomTextField(
                    label: type == ReminderType.medication ? 'Reminder Title' : 'Title',
                    hintText: type == ReminderType.medication ? 'e.g., Morning Blood Pressure Pill' : 'e.g., Drink Water',
                    controller: titleController,
                  ),
                  if (type == ReminderType.medication) ...[
                    AdiuvaSpacing.gapSm,
                    CustomTextField(
                      label: 'Medicine Name',
                      hintText: 'e.g., Amlodipine',
                      controller: medNameController,
                    ),
                    AdiuvaSpacing.gapSm,
                    CustomTextField(
                      label: 'Dosage',
                      hintText: 'e.g., 5mg or 1 Pill',
                      controller: dosageController,
                    ),
                  ],
                  AdiuvaSpacing.gapSm,
                  Row(
                    children: [
                      Text('Time: ${selectedTime.format(context)}'),
                      const Spacer(),
                      TextButton(
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: selectedTime,
                          );
                          if (picked != null) {
                            setDialogState(() {
                              selectedTime = picked;
                            });
                          }
                        },
                        child: const Text('Pick Time'),
                      ),
                    ],
                  ),
                  DropdownButton<String>(
                    value: recurrence,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'Once', child: Text('Once')),
                      DropdownMenuItem(value: 'Daily', child: Text('Daily')),
                      DropdownMenuItem(value: 'Weekly', child: Text('Weekly')),
                      DropdownMenuItem(value: 'Monthly', child: Text('Monthly')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          recurrence = val;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final title = titleController.text.trim();
                  if (title.isEmpty) return;

                  final now = DateTime.now();
                  final dt = DateTime(
                    now.year,
                    now.month,
                    now.day,
                    selectedTime.hour,
                    selectedTime.minute,
                  );

                  context.read<ReminderProvider>().addReminder(
                    title: title,
                    type: type,
                    dateTime: dt,
                    recurrence: recurrence,
                    medicineName: medNameController.text.trim(),
                    dosage: dosageController.text.trim(),
                  );

                  Navigator.of(ctx).pop();
                  AccessibilityScaffold.announce('Item added successfully');
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AccessibilityScaffold(
      pageTitle: 'Reminders & Calendar',
      appBar: const CustomAppBar(
        title: 'Reminders & Calendar',
        showBackButton: true,
      ),
      body: Consumer<ReminderProvider>(
        builder: (context, provider, child) {
          final generalList = provider.generalReminders;
          final medicationList = provider.medicationReminders;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AdiuvaSpacing.gapLg,
              TabBar(
                controller: _tabController,
                tabs: [
                  Tab(text: 'Reminders (${generalList.length})'),
                  Tab(text: 'Medication (${medicationList.length})'),
                  const Tab(text: 'Calendar'),
                ],
              ),
              AdiuvaSpacing.gapMd,
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildGeneralTab(context, provider, generalList),
                    _buildMedicationTab(context, provider, medicationList),
                    _buildCalendarTab(context, provider),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGeneralTab(BuildContext context, ReminderProvider provider, List<ReminderItem> list) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: CustomButton.primary(
            label: 'Add Reminder',
            leadingIcon: Icons.add_rounded,
            onPressed: () => _showAddDialog(context, ReminderType.general),
          ),
        ),
        AdiuvaSpacing.gapMd,
        Expanded(
          child: list.isEmpty
              ? Center(child: Text('No general reminders set.', style: theme.textTheme.bodyLarge))
              : ListView.builder(
                  itemCount: list.length,
                  padding: const EdgeInsets.only(bottom: 80),
                  itemBuilder: (context, index) {
                    final r = list[index];
                    final timeStr = TimeOfDay.fromDateTime(r.dateTime).format(context);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: AdiuvaSpacing.sm),
                      child: AdiuvaCard(
                        padding: AdiuvaSpacing.paddingMd,
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: r.isEnabled
                                  ? AdiuvaColors.primaryTeal.withValues(alpha: 0.15)
                                  : theme.colorScheme.surfaceContainerHighest,
                              child: Icon(
                                Icons.notifications_active_rounded,
                                color: r.isEnabled ? AdiuvaColors.primaryTeal : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: AdiuvaSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    r.title,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      decoration: r.isEnabled ? null : TextDecoration.lineThrough,
                                    ),
                                  ),
                                  Text(
                                    '$timeStr • ${r.recurrence}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: r.isEnabled,
                              onChanged: (_) => provider.toggleEnable(r.id),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: AdiuvaColors.error),
                              onPressed: () => provider.deleteReminder(r.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildMedicationTab(BuildContext context, ReminderProvider provider, List<ReminderItem> list) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: CustomButton.primary(
            label: 'Add Medication',
            leadingIcon: Icons.medication_rounded,
            onPressed: () => _showAddDialog(context, ReminderType.medication),
          ),
        ),
        AdiuvaSpacing.gapMd,
        Expanded(
          child: list.isEmpty
              ? Center(child: Text('No medication schedules added.', style: theme.textTheme.bodyLarge))
              : ListView.builder(
                  itemCount: list.length,
                  padding: const EdgeInsets.only(bottom: 80),
                  itemBuilder: (context, index) {
                    final r = list[index];
                    final timeStr = TimeOfDay.fromDateTime(r.dateTime).format(context);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: AdiuvaSpacing.sm),
                      child: AdiuvaCard(
                        padding: AdiuvaSpacing.paddingMd,
                        child: Row(
                          children: [
                            Checkbox(
                              value: r.isTaken,
                              onChanged: (_) {
                                provider.toggleMedicationTaken(r.id);
                                AccessibilityScaffold.announce(
                                  r.isTaken ? 'Medication marked as pending' : 'Medication marked as taken',
                                );
                              },
                            ),
                            CircleAvatar(
                              backgroundColor: Colors.orange.withValues(alpha: 0.15),
                              child: const Icon(Icons.medication_rounded, color: Colors.orange),
                            ),
                            const SizedBox(width: AdiuvaSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    r.title,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      decoration: r.isTaken ? TextDecoration.lineThrough : null,
                                    ),
                                  ),
                                  Text(
                                    '${r.medicineName ?? ''} ${r.dosage ?? ''} • $timeStr (${r.recurrence})',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: AdiuvaColors.error),
                              onPressed: () => provider.deleteReminder(r.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCalendarTab(BuildContext context, ReminderProvider provider) {
    final theme = Theme.of(context);
    final dateReminders = provider.getRemindersForDate(_selectedCalendarDate);

    return SingleChildScrollView(
      child: Column(
        children: [
          CalendarDatePicker(
            initialDate: _selectedCalendarDate,
            firstDate: DateTime(2025, 1, 1),
            lastDate: DateTime(2030, 12, 31),
            onDateChanged: (date) {
              setState(() {
                _selectedCalendarDate = date;
              });
            },
          ),
          AdiuvaSpacing.gapMd,
          Text(
            'Schedule for ${_selectedCalendarDate.day}/${_selectedCalendarDate.month}/${_selectedCalendarDate.year}',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          AdiuvaSpacing.gapSm,
          if (dateReminders.isEmpty)
            Padding(
              padding: AdiuvaSpacing.paddingMd,
              child: Text('No events scheduled for this date.', style: theme.textTheme.bodyMedium),
            )
          else
            ...dateReminders.map((r) {
              final timeStr = TimeOfDay.fromDateTime(r.dateTime).format(context);
              final isMed = r.type == ReminderType.medication;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: AdiuvaCard(
                  padding: AdiuvaSpacing.paddingMd,
                  child: ListTile(
                    leading: Icon(
                      isMed ? Icons.medication_rounded : Icons.event_rounded,
                      color: isMed ? Colors.orange : AdiuvaColors.primaryTeal,
                    ),
                    title: Text(r.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('$timeStr • ${isMed ? (r.medicineName ?? '') : r.recurrence}'),
                  ),
                ),
              );
            }),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
