import 'package:equatable/equatable.dart';

/// Entity representing an Indian Sign Language (ISL) phrase mapping.
class SignLanguagePhrase extends Equatable {
  final String id;
  final String displayText;
  final List<String> aliases;
  final String animationName;
  final String? assetPath;

  const SignLanguagePhrase({
    required this.id,
    required this.displayText,
    required this.aliases,
    required this.animationName,
    this.assetPath,
  });

  @override
  List<Object?> get props => [id, displayText, aliases, animationName, assetPath];
}
