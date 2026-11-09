/// Entity representing a selectable 3D Humanoid Avatar Character for Indian Sign Language
class IslAvatarCharacter {
  final String id;
  final String name;
  final String shortName;
  final String gender;
  final String description;
  final String assetPath;

  const IslAvatarCharacter({
    required this.id,
    required this.name,
    required this.shortName,
    required this.gender,
    required this.description,
    required this.assetPath,
  });

  static const IslAvatarCharacter male = IslAvatarCharacter(
    id: 'male',
    name: 'Aarav (Male Avatar)',
    shortName: 'Aarav',
    gender: 'Male',
    description: 'Casual blue shirt & beige trousers',
    assetPath: 'assets/sign_language/avatar/adiuva_avatar_male.glb',
  );

  static const IslAvatarCharacter female = IslAvatarCharacter(
    id: 'female',
    name: 'Ananya (Female Avatar)',
    shortName: 'Ananya',
    gender: 'Female',
    description: 'White embroidered kurta & blue dupatta',
    assetPath: 'assets/sign_language/avatar/adiuva_avatar_female.glb',
  );

  static const List<IslAvatarCharacter> all = [male, female];

  static IslAvatarCharacter fromId(String? id) {
    if (id == 'female') return female;
    return male;
  }
}
