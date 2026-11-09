import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/adiuva_colors.dart';
import '../../../../core/theme/adiuva_spacing.dart';
import '../../../../core/widgets/accessibility_scaffold.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/adiuva_card.dart';
import '../provider/notes_provider.dart';

/// Accessible Memory Notes Page for Cognitive Assistance
class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _addNote(NotesProvider provider) {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (content.isEmpty && title.isEmpty) return;

    provider.addNote(title, content);
    _titleController.clear();
    _contentController.clear();
    AccessibilityScaffold.announce('Note saved.');
  }

  void _showEditNoteDialog(BuildContext context, NotesProvider provider, NoteItem note) {
    final titleEditCtrl = TextEditingController(text: note.title);
    final contentEditCtrl = TextEditingController(text: note.content);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(
              label: 'Note Title',
              controller: titleEditCtrl,
            ),
            AdiuvaSpacing.gapSm,
            CustomTextField(
              label: 'Note Content',
              controller: contentEditCtrl,
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.editNote(note.id, titleEditCtrl.text, contentEditCtrl.text);
              Navigator.of(ctx).pop();
              AccessibilityScaffold.announce('Note updated');
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AccessibilityScaffold(
      pageTitle: 'Memory Notes',
      appBar: const CustomAppBar(
        title: 'Notes & Memory',
        showBackButton: true,
      ),
      body: Consumer<NotesProvider>(
        builder: (context, provider, child) {
          final notesList = provider.filteredNotes;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AdiuvaSpacing.gapLg,
              CustomTextField(
                label: 'Search Notes',
                hintText: 'Filter notes by keyword...',
                controller: _searchController,
                onChanged: (val) => provider.setSearchQuery(val),
              ),
              AdiuvaSpacing.gapMd,
              CustomTextField(
                label: 'Note Title (Optional)',
                hintText: 'e.g., Spare Key Location',
                controller: _titleController,
              ),
              AdiuvaSpacing.gapSm,
              CustomTextField(
                label: 'Write or dictate a note',
                hintText: 'Type an important memory or instruction...',
                controller: _contentController,
                maxLines: 3,
              ),
              AdiuvaSpacing.gapSm,
              CustomButton.primary(
                label: 'Save Note',
                leadingIcon: Icons.save_rounded,
                onPressed: () => _addNote(provider),
              ),
              AdiuvaSpacing.gapXl,
              Text(
                'Saved Notes (${notesList.length})',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              AdiuvaSpacing.gapSm,
              Expanded(
                child: notesList.isEmpty
                    ? Center(
                        child: Text(
                          provider.searchQuery.isEmpty
                              ? 'No notes saved yet.'
                              : 'No notes match "${provider.searchQuery}".',
                          style: theme.textTheme.bodyMedium,
                        ),
                      )
                    : ListView.builder(
                        itemCount: notesList.length,
                        padding: const EdgeInsets.only(bottom: 80),
                        itemBuilder: (context, index) {
                          final note = notesList[index];
                          final dateStr =
                              '${note.updatedAt.day}/${note.updatedAt.month}/${note.updatedAt.year}';

                          return Padding(
                            padding: const EdgeInsets.only(bottom: AdiuvaSpacing.sm),
                            child: AdiuvaCard(
                              padding: AdiuvaSpacing.paddingMd,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          note.title,
                                          style: theme.textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.primary,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        dateStr,
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, size: 20),
                                        onPressed: () => _showEditNoteDialog(context, provider, note),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline_rounded,
                                            size: 20, color: AdiuvaColors.error),
                                        onPressed: () {
                                          provider.deleteNote(note.id);
                                          AccessibilityScaffold.announce('Note deleted.');
                                        },
                                      ),
                                    ],
                                  ),
                                  AdiuvaSpacing.gapXs,
                                  SelectableText(
                                    note.content,
                                    style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
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
        },
      ),
    );
  }
}
