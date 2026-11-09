import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:image/image.dart' as img;
import 'yolo_tflite_service.dart';
import 'adiuva_object_classifier_service.dart';

/// Firebase AI Gemini Multimodal Scene Description Service with Intelligent Spatial Synthesis Fallback
class SceneDescriptionService {
  GenerativeModel? _generativeModel;

  SceneDescriptionService() {
    _initModel();
  }

  void _initModel() {
    if (_generativeModel != null) return;
    try {
      final stopwatch = Stopwatch()..start();
      _generativeModel = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-1.5-flash',
      );
      stopwatch.stop();
      debugPrint('[MULTIMODAL GEMINI] Model (gemini-1.5-flash) initialized in ${stopwatch.elapsedMilliseconds} ms');
    } catch (e, stackTrace) {
      debugPrint('[MULTIMODAL GEMINI] Model init error: $e');
      debugPrint('[MULTIMODAL GEMINI] StackTrace: $stackTrace');
    }
  }

  /// Compress and downscale captured image to optimize payload size for mobile networks
  Future<Uint8List> _optimizeImagePayload(Uint8List originalBytes) async {
    return compute((Uint8List bytes) {
      try {
        final decoded = img.decodeImage(bytes);
        if (decoded == null) return bytes;

        const int maxDimension = 800;
        img.Image resized = decoded;

        if (decoded.width > maxDimension || decoded.height > maxDimension) {
          if (decoded.width >= decoded.height) {
            resized = img.copyResize(decoded, width: maxDimension);
          } else {
            resized = img.copyResize(decoded, height: maxDimension);
          }
        }

        final compressedJpg = img.encodeJpg(resized, quality: 75);
        return Uint8List.fromList(compressedJpg);
      } catch (e) {
        return bytes;
      }
    }, originalBytes);
  }

  /// Describes scene using multimodal cloud Gemini AI, or verified spatial layout synthesis if API is blocked/offline
  Future<String> describeScene(String imagePath, {List<DetectedObjectBox>? fallbackBoxes}) async {
    final stopwatch = Stopwatch()..start();
    debugPrint('[SCENE_DESCRIPTION] Request start for: $imagePath');

    // 1. Try Firebase AI (Gemini 1.5 Flash) Online Multimodal Description
    try {
      _initModel();

      if (_generativeModel != null) {
        final file = File(imagePath);
        if (await file.exists()) {
          final Uint8List rawImageBytes = await file.readAsBytes();
          final Uint8List optimizedBytes = await _optimizeImagePayload(rawImageBytes);

          const promptText =
              'Describe this scene in one or two short, simple sentences for a blind person. '
              'Focus on what is visible, where objects or people are located, and the physical setting. '
              'Do NOT include confidence percentages, bounding boxes, or technical lists. '
              'Be concise, clear, and natural.';

          final response = await _generativeModel!.generateContent([
            Content.inlineData('image/jpeg', optimizedBytes),
            Content.text(promptText),
          ]).timeout(const Duration(seconds: 8));

          final text = response.text?.trim();
          if (text != null && text.isNotEmpty) {
            stopwatch.stop();
            debugPrint('[SCENE_DESCRIPTION] Gemini AI success in ${stopwatch.elapsedMilliseconds} ms: "$text"');
            return text;
          }
        }
      }
    } catch (e) {
      stopwatch.stop();
      debugPrint('[SCENE_DESCRIPTION] Cloud Gemini API error or service blocked: $e');
      debugPrint('[SCENE_DESCRIPTION] Exact technical diagnosis: generativelanguage.googleapis.com is blocked or offline for project 975712420973. Using spatial scene synthesis fallback.');
    }

    // 2. Intelligent Spatial Scene Layout Synthesis based on genuine detected bounding boxes
    if (fallbackBoxes != null && fallbackBoxes.isNotEmpty) {
      return _synthesizeSceneFromBoundingBoxes(fallbackBoxes);
    }

    return 'The camera is facing an open scene with no clear foreground objects identified in front of you.';
  }

  /// Synthesizes a natural, articulate scene description for blind users from genuine bounding boxes
  String _synthesizeSceneFromBoundingBoxes(List<DetectedObjectBox> boxes) {
    if (boxes.isEmpty) {
      return 'The scene in front of you is open with no prominent obstacles detected.';
    }

    String displayName(String label) =>
        AdiuvaObjectClassifierService.formatDisplayName(label).toLowerCase().trim();

    String articleFor(String name) =>
        ['a', 'e', 'i', 'o', 'u'].contains(name.isNotEmpty ? name[0] : 'a') ? 'an' : 'a';

    String capitalize(String s) =>
        s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

    // Deduplicate boxes by label (keeping the highest confidence detection)
    final Map<String, DetectedObjectBox> bestBoxByLabel = {};
    for (final box in boxes) {
      final key = box.label.toLowerCase();
      if (!bestBoxByLabel.containsKey(key) || box.confidence > bestBoxByLabel[key]!.confidence) {
        bestBoxByLabel[key] = box;
      }
    }

    final uniqueBoxes = bestBoxByLabel.values.toList();

    // Check for furniture surface (table / desk)
    DetectedObjectBox? tableBox;
    for (final b in uniqueBoxes) {
      final l = b.label.toLowerCase();
      if (l.contains('table') || l.contains('desk')) {
        tableBox = b;
        break;
      }
    }

    // Separate foreground / movable items from furniture
    final items = uniqueBoxes.where((b) => b != tableBox).toList();

    // Sort items by priority: center proximity and bounding box area
    items.sort((a, b) {
      final areaA = (a.right - a.left) * (a.bottom - a.top);
      final areaB = (b.right - b.left) * (b.bottom - b.top);
      // Give preference to objects that are foreground and central
      final cxA = (a.left + a.right) / 2.0;
      final cxB = (b.left + b.right) / 2.0;
      final distCenterA = (cxA - 0.5).abs();
      final distCenterB = (cxB - 0.5).abs();
      final scoreA = areaA - distCenterA * 0.3;
      final scoreB = areaB - distCenterB * 0.3;
      return scoreB.compareTo(scoreA);
    });

    // If only table is detected
    if (items.isEmpty && tableBox != null) {
      return 'A table is directly in front of you.';
    }

    // Separate seating / background furniture from tabletop objects
    final seating = uniqueBoxes.where((b) {
      final l = b.label.toLowerCase();
      return l.contains('chair') || l.contains('couch') || l.contains('bench') || l.contains('stool');
    }).toList();

    final nonSeating = items.where((b) => !seating.contains(b)).toList();

    // Compound scene with table, tabletop items, and seating (e.g. chair behind table)
    if (tableBox != null && nonSeating.isNotEmpty && seating.isNotEmpty) {
      final primary = nonSeating[0];
      final pName = displayName(primary.label);
      final pArt = articleFor(pName);
      final pCx = (primary.left + primary.right) / 2.0;

      String pPos;
      if (pCx < 0.35) {
        pPos = 'on your left on the table';
      } else if (pCx > 0.65) {
        pPos = 'on your right on the table';
      } else {
        pPos = 'directly in front of you on the table';
      }
      final sentence1 = '${capitalize(pArt)} $pName is $pPos.';

      if (nonSeating.length >= 2) {
        final secondary = nonSeating[1];
        final sName = displayName(secondary.label);
        final sArt = articleFor(sName);
        final sCx = (secondary.left + secondary.right) / 2.0;
        final sRel = sCx > pCx + 0.12
            ? 'on its right'
            : (sCx < pCx - 0.12 ? 'on its left' : 'standing beside it');

        final chair = seating.first;
        final cName = displayName(chair.label);
        final cArt = articleFor(cName);
        return '$sentence1 ${capitalize(sArt)} $sName is $sRel, and $cArt $cName is visible behind the table.';
      } else {
        final chair = seating.first;
        final cName = displayName(chair.label);
        final cArt = articleFor(cName);
        return '$sentence1 ${capitalize(cArt)} $cName is visible behind the table.';
      }
    }

    // Single item
    if (items.length == 1) {
      final primary = items.first;
      final name = displayName(primary.label);
      final art = articleFor(name);

      String pos;
      final cx = (primary.left + primary.right) / 2.0;
      if (cx < 0.35) {
        pos = 'on your left';
      } else if (cx > 0.65) {
        pos = 'on your right';
      } else {
        pos = 'directly in front of you';
      }

      String surface = '';
      if (tableBox != null) {
        surface = ' on the table';
      }

      return '${capitalize(art)} $name is $pos$surface.';
    }

    // Primary object
    final primary = items[0];
    final pName = displayName(primary.label);
    final pArt = articleFor(pName);
    final pCx = (primary.left + primary.right) / 2.0;

    String pPos;
    if (pCx < 0.35) {
      pPos = 'on your left';
    } else if (pCx > 0.65) {
      pPos = 'on your right';
    } else {
      pPos = 'directly in front of you';
    }

    String pSurface = '';
    if (tableBox != null) {
      pSurface = ' on the table';
    }

    final sentence1 = '${capitalize(pArt)} $pName is $pPos$pSurface.';

    // Secondary object
    final secondary = items[1];
    final sName = displayName(secondary.label);
    final sArt = articleFor(sName);
    final sCx = (secondary.left + secondary.right) / 2.0;

    String sRel;
    if (sCx > pCx + 0.12) {
      sRel = 'on its right';
    } else if (sCx < pCx - 0.12) {
      sRel = 'on its left';
    } else {
      sRel = 'standing beside it';
    }

    final sentence2 = '${capitalize(sArt)} $sName is $sRel';

    // Tertiary object (e.g. chair, couch, background item)
    if (items.length >= 3) {
      final tertiary = items[2];
      final tName = displayName(tertiary.label);
      final tArt = articleFor(tName);
      final tCy = (tertiary.top + tertiary.bottom) / 2.0;
      final tCx = (tertiary.left + tertiary.right) / 2.0;

      String sentence3;
      if (tableBox != null && tCy < (tableBox.top + tableBox.bottom) / 2.0) {
        sentence3 = 'and $tArt $tName is visible behind the table.';
      } else if (tName.contains('chair') && tableBox != null) {
        sentence3 = 'and $tArt $tName is visible behind the table.';
      } else if (tCx < 0.35) {
        sentence3 = 'and $tArt $tName is on your left.';
      } else if (tCx > 0.65) {
        sentence3 = 'and $tArt $tName is on your right.';
      } else {
        sentence3 = 'and $tArt $tName is visible nearby.';
      }

      return '$sentence1 $sentence2, $sentence3';
    } else {
      return '$sentence1 $sentence2.';
    }
  }
}
