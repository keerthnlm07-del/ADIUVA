import 'package:equatable/equatable.dart';

/// Domain entity representing an imported or scanned multi-page document/storybook
class DocumentBook extends Equatable {
  final String fileName;
  final List<String> pages;
  final int currentPageIndex;
  final String? summary;
  final String? filePath;

  const DocumentBook({
    required this.fileName,
    required this.pages,
    this.currentPageIndex = 0,
    this.summary,
    this.filePath,
  });

  int get totalPages => pages.length;

  String get currentPageText =>
      (pages.isNotEmpty && currentPageIndex >= 0 && currentPageIndex < pages.length)
          ? pages[currentPageIndex]
          : '';

  bool get hasNextPage => currentPageIndex < pages.length - 1;
  bool get hasPreviousPage => currentPageIndex > 0;
  bool get isMultiPage => pages.length > 1;

  DocumentBook copyWith({
    String? fileName,
    List<String>? pages,
    int? currentPageIndex,
    String? summary,
    String? filePath,
  }) {
    return DocumentBook(
      fileName: fileName ?? this.fileName,
      pages: pages ?? this.pages,
      currentPageIndex: currentPageIndex ?? this.currentPageIndex,
      summary: summary ?? this.summary,
      filePath: filePath ?? this.filePath,
    );
  }

  @override
  List<Object?> get props => [
        fileName,
        pages,
        currentPageIndex,
        summary,
        filePath,
      ];
}
