class AppSettings {
  final bool maintenanceMode;
  final String? featuredCollectionId;
  final String supportEmail;

  const AppSettings({
    this.maintenanceMode = false,
    this.featuredCollectionId,
    this.supportEmail = 'support@example.com',
  });

  Map<String, Object?> toMap() {
    return {
      'maintenanceMode': maintenanceMode,
      'featuredCollectionId': featuredCollectionId,
      'supportEmail': supportEmail,
    };
  }

  factory AppSettings.fromMap(Map<String, Object?> map) {
    return AppSettings(
      maintenanceMode: map['maintenanceMode'] as bool? ?? false,
      featuredCollectionId: map['featuredCollectionId'] as String?,
      supportEmail: map['supportEmail'] as String? ?? 'support@example.com',
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppSettings &&
        other.maintenanceMode == maintenanceMode &&
        other.featuredCollectionId == featuredCollectionId &&
        other.supportEmail == supportEmail;
  }

  @override
  int get hashCode {
    return Object.hash(maintenanceMode, featuredCollectionId, supportEmail);
  }
}
