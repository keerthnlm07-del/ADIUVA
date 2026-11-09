import 'package:equatable/equatable.dart';

/// Reference Card entity for static alphabet or digit demonstration
class IslReferenceCard extends Equatable {
  final String label;
  final String title;
  final String assetPath;
  final String category; // 'Alphabet' or 'Digit'

  const IslReferenceCard({
    required this.label,
    required this.title,
    required this.assetPath,
    required this.category,
  });

  @override
  List<Object?> get props => [label, assetPath, category];
}

/// Registry of Static Reference Demonstrations for Alphabet (A–Z) and Digits (0–9)
class IslReferenceRegistry {
  IslReferenceRegistry._();

  static const List<IslReferenceCard> alphabet = [
    IslReferenceCard(label: 'A', title: 'Letter A', assetPath: 'assets/sign_language/alphabet/A_test.jpg', category: 'Alphabet'),
    IslReferenceCard(label: 'B', title: 'Letter B', assetPath: 'assets/sign_language/alphabet/B_test.jpg', category: 'Alphabet'),
    IslReferenceCard(label: 'C', title: 'Letter C', assetPath: 'assets/sign_language/alphabet/C_test.jpg', category: 'Alphabet'),
    IslReferenceCard(label: 'D', title: 'Letter D', assetPath: 'assets/sign_language/alphabet/D_test.jpg', category: 'Alphabet'),
    IslReferenceCard(label: 'E', title: 'Letter E', assetPath: 'assets/sign_language/alphabet/E_test.jpg', category: 'Alphabet'),
    IslReferenceCard(label: 'F', title: 'Letter F', assetPath: 'assets/sign_language/alphabet/F_test.jpg', category: 'Alphabet'),
    IslReferenceCard(label: 'G', title: 'Letter G', assetPath: 'assets/sign_language/alphabet/G_test.jpg', category: 'Alphabet'),
    IslReferenceCard(label: 'H', title: 'Letter H', assetPath: 'assets/sign_language/alphabet/H_test.jpg', category: 'Alphabet'),
    IslReferenceCard(label: 'I', title: 'Letter I', assetPath: 'assets/sign_language/alphabet/I_test.jpg', category: 'Alphabet'),
    IslReferenceCard(label: 'J', title: 'Letter J', assetPath: 'assets/sign_language/alphabet/J_test.jpg', category: 'Alphabet'),
    IslReferenceCard(label: 'K', title: 'Letter K', assetPath: 'assets/sign_language/alphabet/K_test.jpg', category: 'Alphabet'),
    IslReferenceCard(label: 'L', title: 'Letter L', assetPath: 'assets/sign_language/alphabet/L_test.jpg', category: 'Alphabet'),
    IslReferenceCard(label: 'M', title: 'Letter M', assetPath: 'assets/sign_language/alphabet/M_test.jpg', category: 'Alphabet'),
    IslReferenceCard(label: 'N', title: 'Letter N', assetPath: 'assets/sign_language/alphabet/N_test.jpg', category: 'Alphabet'),
    IslReferenceCard(label: 'O', title: 'Letter O', assetPath: 'assets/sign_language/alphabet/O_test.jpg', category: 'Alphabet'),
    IslReferenceCard(label: 'P', title: 'Letter P', assetPath: 'assets/sign_language/alphabet/P_test.jpg', category: 'Alphabet'),
    IslReferenceCard(label: 'Q', title: 'Letter Q', assetPath: 'assets/sign_language/alphabet/Q_test.jpg', category: 'Alphabet'),
    IslReferenceCard(label: 'R', title: 'Letter R', assetPath: 'assets/sign_language/alphabet/R_test.jpg', category: 'Alphabet'),
    IslReferenceCard(label: 'S', title: 'Letter S', assetPath: 'assets/sign_language/alphabet/S_test.jpg', category: 'Alphabet'),
    IslReferenceCard(label: 'T', title: 'Letter T', assetPath: 'assets/sign_language/alphabet/T_test.jpg', category: 'Alphabet'),
    IslReferenceCard(label: 'U', title: 'Letter U', assetPath: 'assets/sign_language/alphabet/U_test.jpg', category: 'Alphabet'),
    IslReferenceCard(label: 'V', title: 'Letter V', assetPath: 'assets/sign_language/alphabet/V_test.jpg', category: 'Alphabet'),
    IslReferenceCard(label: 'W', title: 'Letter W', assetPath: 'assets/sign_language/alphabet/W_test.jpg', category: 'Alphabet'),
    IslReferenceCard(label: 'X', title: 'Letter X', assetPath: 'assets/sign_language/alphabet/X_test.jpg', category: 'Alphabet'),
    IslReferenceCard(label: 'Y', title: 'Letter Y', assetPath: 'assets/sign_language/alphabet/Y_test.jpg', category: 'Alphabet'),
    IslReferenceCard(label: 'Z', title: 'Letter Z', assetPath: 'assets/sign_language/alphabet/Z_test.jpg', category: 'Alphabet'),
  ];

  static const List<IslReferenceCard> digits = [
    IslReferenceCard(label: '0', title: 'Digit 0', assetPath: 'assets/sign_language/digits/0.jpg', category: 'Digit'),
    IslReferenceCard(label: '1', title: 'Digit 1', assetPath: 'assets/sign_language/digits/1.jpg', category: 'Digit'),
    IslReferenceCard(label: '2', title: 'Digit 2', assetPath: 'assets/sign_language/digits/2.jpg', category: 'Digit'),
    IslReferenceCard(label: '3', title: 'Digit 3', assetPath: 'assets/sign_language/digits/3.jpg', category: 'Digit'),
    IslReferenceCard(label: '4', title: 'Digit 4', assetPath: 'assets/sign_language/digits/4.jpg', category: 'Digit'),
    IslReferenceCard(label: '5', title: 'Digit 5', assetPath: 'assets/sign_language/digits/5.jpg', category: 'Digit'),
    IslReferenceCard(label: '6', title: 'Digit 6', assetPath: 'assets/sign_language/digits/6.jpg', category: 'Digit'),
    IslReferenceCard(label: '7', title: 'Digit 7', assetPath: 'assets/sign_language/digits/7.jpg', category: 'Digit'),
    IslReferenceCard(label: '8', title: 'Digit 8', assetPath: 'assets/sign_language/digits/8.jpg', category: 'Digit'),
    IslReferenceCard(label: '9', title: 'Digit 9', assetPath: 'assets/sign_language/digits/9.jpg', category: 'Digit'),
  ];
}
