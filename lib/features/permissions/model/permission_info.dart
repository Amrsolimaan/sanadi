class PermissionInfo {
  final String title;
  final String description;
  final String icon;
  final List<String> benefits;
  final bool isRequired;

  const PermissionInfo({
    required this.title,
    required this.description,
    required this.icon,
    required this.benefits,
    this.isRequired = false,
  });
}
