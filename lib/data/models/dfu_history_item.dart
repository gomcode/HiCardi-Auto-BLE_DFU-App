class DfuHistoryItem {
  final String deviceId;
  final String deviceName;
  final String zipFileName;
  final bool isSuccess;
  final DateTime timestamp;
  final String? errorMessage;

  const DfuHistoryItem({
    required this.deviceId,
    required this.deviceName,
    required this.zipFileName,
    required this.isSuccess,
    required this.timestamp,
    this.errorMessage,
  });

  Map<String, dynamic> toJson() => {
    'deviceId': deviceId,
    'deviceName': deviceName,
    'zipFileName': zipFileName,
    'isSuccess': isSuccess,
    'timestamp': timestamp.toIso8601String(),
    'errorMessage': errorMessage,
  };

  factory DfuHistoryItem.fromJson(Map<String, dynamic> json) => DfuHistoryItem(
    deviceId: json['deviceId'] as String,
    deviceName: json['deviceName'] as String,
    zipFileName: json['zipFileName'] as String,
    isSuccess: json['isSuccess'] as bool,
    timestamp: DateTime.parse(json['timestamp'] as String),
    errorMessage: json['errorMessage'] as String?,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DfuHistoryItem &&
          runtimeType == other.runtimeType &&
          deviceId == other.deviceId &&
          timestamp == other.timestamp;

  @override
  int get hashCode => deviceId.hashCode ^ timestamp.hashCode;
}