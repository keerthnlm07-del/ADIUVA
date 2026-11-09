import 'dart:async';
import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';

/// Representation of an actionable UI control triggerable by both touch and voice
class VoiceAction extends Equatable {
  final String id;
  final String label;
  final String screenContext;
  final List<String> aliases;
  final List<String> contextualAliases;
  final FutureOr<void> Function(BuildContext context)? actionHandler;

  const VoiceAction({
    required this.id,
    required this.label,
    required this.screenContext,
    required this.aliases,
    this.contextualAliases = const [],
    this.actionHandler,
  });

  @override
  List<Object?> get props => [id, label, screenContext, aliases, contextualAliases];
}

/// Result model produced when a voice transcript matches a registered VoiceAction
class VoiceActionMatch extends Equatable {
  final VoiceAction action;
  final String transcript;
  final String matchedAlias;

  const VoiceActionMatch({
    required this.action,
    required this.transcript,
    required this.matchedAlias,
  });

  @override
  List<Object?> get props => [action, transcript, matchedAlias];
}
