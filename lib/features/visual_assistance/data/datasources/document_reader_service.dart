import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:firebase_ai/firebase_ai.dart';
import '../../domain/entities/document_reader_entity.dart';
import 'ml_kit_ocr_service.dart';

/// Datasource service for importing, extracting, and summarizing documents & storybooks
class DocumentReaderService {
  final MlKitOcrService _ocrService;
  GenerativeModel? _generativeModel;

  DocumentReaderService({MlKitOcrService? ocrService})
      : _ocrService = ocrService ?? MlKitOcrService() {
    _initGenerativeModel();
  }

  void _initGenerativeModel() {
    if (_generativeModel != null) return;
    try {
      _generativeModel = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-3.8-flash',
      );
      debugPrint('[DOCUMENT_READER] Gemini AI model initialized.');
    } catch (e) {
      debugPrint('[DOCUMENT_READER] Gemini AI init error: $e');
    }
  }

  /// Pick a file (PDF, JPG, JPEG, PNG) from device storage and extract its text page-by-page
  Future<DocumentBook?> pickAndExtractDocument() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (file == null || file.path == null) {
        debugPrint('[DOCUMENT_READER] File picker cancelled or empty.');
        return null;
      }

      final String filePath = file.path!;
      final String fileName = file.name;
      final String extension = filePath.split('.').last.toLowerCase();

      debugPrint('[DOCUMENT_READER] Selected file: $fileName (ext: $extension)');

      if (extension == 'pdf') {
        return await _extractPdfDocument(filePath, fileName);
      } else if (['jpg', 'jpeg', 'png'].contains(extension)) {
        return await _extractImageDocument(filePath, fileName);
      } else {
        throw Exception('Unsupported file type: $extension');
      }
    } catch (e) {
      debugPrint('[DOCUMENT_READER] Error picking/extracting document: $e');
      rethrow;
    }
  }

  /// Extract text page-by-page from a PDF file using Syncfusion PDF TextExtractor
  Future<DocumentBook> _extractPdfDocument(String filePath, String fileName) async {
    final File pdfFile = File(filePath);
    if (!await pdfFile.exists()) {
      throw Exception('PDF file not found at path: $filePath');
    }

    final Uint8List bytes = await pdfFile.readAsBytes();
    final PdfDocument document = PdfDocument(inputBytes: bytes);

    try {
      final int pageCount = document.pages.count;
      debugPrint('[DOCUMENT_READER] PDF loaded with $pageCount pages.');

      if (pageCount == 0) {
        return DocumentBook(
          fileName: fileName,
          pages: const ['The selected PDF document contains no pages.'],
          filePath: filePath,
        );
      }

      final PdfTextExtractor textExtractor = PdfTextExtractor(document);
      final List<String> extractedPages = [];

      for (int i = 0; i < pageCount; i++) {
        String pageText = textExtractor.extractText(
          startPageIndex: i,
          endPageIndex: i,
        );
        pageText = _cleanText(pageText);

        if (pageText.isEmpty) {
          pageText = '[Page ${i + 1} has no selectable text. It may contain scanned images.]';
        }

        extractedPages.add(pageText);
      }

      return DocumentBook(
        fileName: fileName,
        pages: extractedPages,
        currentPageIndex: 0,
        filePath: filePath,
      );
    } finally {
      document.dispose();
    }
  }

  /// Extract text from a single image file using ML Kit OCR
  Future<DocumentBook> _extractImageDocument(String filePath, String fileName) async {
    final String extractedText = await _ocrService.extractText(filePath);
    final String cleanText = _cleanText(extractedText);

    final String finalPageText = cleanText.isNotEmpty
        ? cleanText
        : 'No readable text was detected in this image.';

    return DocumentBook(
      fileName: fileName,
      pages: [finalPageText],
      currentPageIndex: 0,
      filePath: filePath,
    );
  }

  /// Generate a 2-3 sentence AI summary of the active document using Gemini AI
  Future<String> summarizeDocument(DocumentBook document) async {
    _initGenerativeModel();

    if (_generativeModel == null) {
      return 'Summary is unavailable because Gemini AI model could not be initialized.';
    }

    if (document.pages.isEmpty) {
      return 'Cannot summarize an empty document.';
    }

    // Combine document pages up to a reasonable limit (~4000 characters) for prompt size efficiency
    final StringBuffer textBuffer = StringBuffer();
    for (int i = 0; i < document.pages.length; i++) {
      textBuffer.writeln('Page ${i + 1}:');
      textBuffer.writeln(document.pages[i]);
      if (textBuffer.length > 4000) break;
    }

    final String sampleText = textBuffer.toString().trim();

    try {
      const String promptText =
          'Provide a 2 to 3 sentence clear, natural, and accessible summary of this story/document for a blind or visually impaired listener. '
          'Do NOT use complex markup, bullet points, or technical jargon. Speak naturally:';

      final response = await _generativeModel!.generateContent([
        Content.text('$promptText\n\nDocument Text:\n$sampleText'),
      ]).timeout(const Duration(seconds: 30));

      final String? summaryText = response.text?.trim();
      if (summaryText == null || summaryText.isEmpty) {
        return 'Could not generate story summary at this time.';
      }

      return summaryText;
    } catch (e) {
      debugPrint('[DOCUMENT_READER] Gemini summary error: $e');
      return 'Failed to generate story summary. Please try again.';
    }
  }

  /// Helper to clean extracted text for natural TTS reading
  String _cleanText(String rawText) {
    if (rawText.isEmpty) return '';
    return rawText
        .replaceAll(RegExp(r'\r\n|\r'), '\n')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }
}
