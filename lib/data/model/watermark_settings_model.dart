class WatermarkSettingsModel {
  WatermarkSettingsModel({
    required this.featureAvailable,
    required this.packageAvailable,
    required this.watermarkEnabled,
    required this.watermarkOpacity,
    required this.watermarkSize,
    required this.watermarkStyle,
    required this.watermarkPosition,
    required this.watermarkRotation,
    this.watermarkImage,
  });

  factory WatermarkSettingsModel.fromMap(Map<String, dynamic> map) {
    return WatermarkSettingsModel(
      featureAvailable: map['feature_available'] as bool? ?? false,
      packageAvailable: map['package_available'] as bool? ?? false,
      watermarkEnabled: map['watermark_enabled'] as bool? ?? false,
      watermarkImage: map['watermark_image']?.toString(),
      watermarkOpacity: _toDouble(map['watermark_opacity']) ?? 40,
      watermarkSize: _toDouble(map['watermark_size']) ?? 42,
      watermarkStyle: map['watermark_style']?.toString() ?? 'single',
      watermarkPosition: map['watermark_position']?.toString() ?? 'center',
      watermarkRotation: _toDouble(map['watermark_rotation']) ?? 0,
    );
  }

  final bool featureAvailable;
  final bool packageAvailable;
  final bool watermarkEnabled;
  final String? watermarkImage;
  final double watermarkOpacity;
  final double watermarkSize;
  final String watermarkStyle;
  final String watermarkPosition;
  final double watermarkRotation;

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    return double.tryParse(value.toString());
  }

  WatermarkSettingsModel copyWith({
    bool? featureAvailable,
    bool? packageAvailable,
    bool? limitAvailable,
    bool? watermarkEnabled,
    String? watermarkImage,
    double? watermarkOpacity,
    double? watermarkSize,
    String? watermarkStyle,
    String? watermarkPosition,
    double? watermarkRotation,
  }) {
    return WatermarkSettingsModel(
      featureAvailable: featureAvailable ?? this.featureAvailable,
      packageAvailable: packageAvailable ?? this.packageAvailable,
      watermarkEnabled: watermarkEnabled ?? this.watermarkEnabled,
      watermarkImage: watermarkImage ?? this.watermarkImage,
      watermarkOpacity: watermarkOpacity ?? this.watermarkOpacity,
      watermarkSize: watermarkSize ?? this.watermarkSize,
      watermarkStyle: watermarkStyle ?? this.watermarkStyle,
      watermarkPosition: watermarkPosition ?? this.watermarkPosition,
      watermarkRotation: watermarkRotation ?? this.watermarkRotation,
    );
  }
}
