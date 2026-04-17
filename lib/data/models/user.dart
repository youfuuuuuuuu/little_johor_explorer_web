class User {
  final String id;
  final String email;
  final String displayName;
  final String role;
  final String? avatarUrl;

  User({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    this.avatarUrl,
  });
}

class ChildProfile extends User {
  final String name;
  final String parentId;
  final int totalReadingTime;

  ChildProfile({
    required super.id,
    required super.email,
    required this.name,
    required this.parentId,
    super.avatarUrl,
    this.totalReadingTime = 0,
  }) : super(
          displayName: name,
          role: 'child',
        );
}

class ParentProfile extends User {
  final List<ChildProfile> children;

  ParentProfile({
    required super.id,
    required super.email,
    required super.displayName,
    required super.role,
    super.avatarUrl,
    required this.children,
  });
}
