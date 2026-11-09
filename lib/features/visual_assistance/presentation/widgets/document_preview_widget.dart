import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../../../core/theme/adiuva_colors.dart';
import '../../../../core/theme/adiuva_spacing.dart';
import '../provider/visual_assistance_provider.dart';

/// Visual display widget for rendering PDF pages and Image documents on screen
class DocumentPreviewWidget extends StatefulWidget {
  final VisualAssistanceProvider provider;

  const DocumentPreviewWidget({
    super.key,
    required this.provider,
  });

  @override
  State<DocumentPreviewWidget> createState() => _DocumentPreviewWidgetState();
}

class _DocumentPreviewWidgetState extends State<DocumentPreviewWidget> {
  PdfViewerController? _pdfViewerController;
  int _lastSyncedPage = -1;

  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();
  }

  @override
  void didUpdateWidget(covariant DocumentPreviewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPdfViewerPage();
  }

  void _syncPdfViewerPage() {
    final doc = widget.provider.activeDocument;
    if (doc != null && _pdfViewerController != null) {
      final targetPage = doc.currentPageIndex + 1;
      if (_lastSyncedPage != targetPage && targetPage >= 1 && targetPage <= doc.totalPages) {
        _lastSyncedPage = targetPage;
        try {
          _pdfViewerController!.jumpToPage(targetPage);
        } catch (_) {}
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final doc = widget.provider.activeDocument;
    if (doc == null || doc.filePath == null) {
      return const SizedBox.shrink();
    }

    final String filePath = doc.filePath!;
    final String ext = filePath.split('.').last.toLowerCase();
    final bool isPdf = ext == 'pdf';

    return Container(
      color: Colors.black87,
      child: Stack(
        children: [
          // 1. Visual Document Render Body (PDF viewer or Image file)
          Positioned.fill(
            child: isPdf
                ? SfPdfViewer.file(
                    File(filePath),
                    controller: _pdfViewerController,
                    canShowScrollHead: false,
                    canShowScrollStatus: false,
                    canShowPaginationDialog: false,
                    onPageChanged: (PdfPageChangedDetails details) {
                      final newPageIndex = details.newPageNumber - 1;
                      if (_lastSyncedPage != details.newPageNumber) {
                        _lastSyncedPage = details.newPageNumber;
                        widget.provider.updateActiveDocumentPageIndex(newPageIndex);
                      }
                    },
                  )
                : Center(
                    child: SingleChildScrollView(
                      child: Image.file(
                        File(filePath),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
          ),

          // 2. Header Bar Overlay: Document Title & Page Counter
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AdiuvaSpacing.md,
                vertical: AdiuvaSpacing.sm,
              ),
              color: Colors.black.withValues(alpha: 0.8),
              child: SafeArea(
                bottom: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        doc.fileName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AdiuvaColors.primaryTeal,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Page ${doc.currentPageIndex + 1} of ${doc.totalPages}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pdfViewerController?.dispose();
    super.dispose();
  }
}
