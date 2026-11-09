import 'package:flutter_test/flutter_test.dart';
import 'package:adiuva/features/visual_assistance/domain/entities/document_reader_entity.dart';

void main() {
  group('DocumentBook Domain Entity Tests', () {
    test('Calculates totalPages and currentPageText correctly', () {
      const doc = DocumentBook(
        fileName: 'storybook.pdf',
        pages: ['Once upon a time...', 'Chapter 1: The Forest', 'The End.'],
        currentPageIndex: 0,
      );

      expect(doc.totalPages, equals(3));
      expect(doc.currentPageText, equals('Once upon a time...'));
      expect(doc.hasNextPage, isTrue);
      expect(doc.hasPreviousPage, isFalse);
      expect(doc.isMultiPage, isTrue);
    });

    test('Navigates pages and evaluates page boundaries correctly', () {
      const doc = DocumentBook(
        fileName: 'guide.pdf',
        pages: ['Page 1 content', 'Page 2 content'],
        currentPageIndex: 1,
      );

      expect(doc.currentPageText, equals('Page 2 content'));
      expect(doc.hasNextPage, isFalse);
      expect(doc.hasPreviousPage, isTrue);
    });

    test('copyWith updates fields correctly', () {
      const doc = DocumentBook(
        fileName: 'notes.pdf',
        pages: ['Page 1', 'Page 2'],
        currentPageIndex: 0,
      );

      final updated = doc.copyWith(currentPageIndex: 1, summary: 'A short story.');

      expect(updated.currentPageIndex, equals(1));
      expect(updated.summary, equals('A short story.'));
      expect(updated.fileName, equals('notes.pdf'));
    });
  });
}
