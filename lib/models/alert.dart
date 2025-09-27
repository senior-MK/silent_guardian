// lib/models/alert.dart

class AlertTypes {
  static const guardianLock = 'guardian_lock';
  static const escalation = 'escalation';
  static const panic = 'panic';
  static const redAlert = 'red_alert';
  static const lowBattery = 'low_battery';
}

class AlertModel {
  final int? id;
  final String type; // 'panic','countdown','decoy','battery'
  final int timestamp; // epoch ms
  final double? latitude;
  final double? longitude;
  final bool synced; // for offline-first sync
  final String? meta; // optional extra JSON/text

  AlertModel({
    this.id,
    required this.type,
    required this.timestamp,
    this.latitude,
    this.longitude,
    this.synced = false,
    this.meta,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type,
    'timestamp': timestamp,
    'latitude': latitude,
    'longitude': longitude,
    'synced': synced ? 1 : 0,
    'meta': meta,
  };

  factory AlertModel.fromMap(Map<String, dynamic> m) => AlertModel(
    id: m['id'] as int?,
    type: m['type'] as String,
    timestamp: m['timestamp'] as int,
    latitude: m['latitude'] == null ? null : (m['latitude'] as num).toDouble(),
    longitude: m['longitude'] == null
        ? null
        : (m['longitude'] as num).toDouble(),
    synced: (m['synced'] as int) == 1,
    meta: m['meta'] as String?,
  );

  // --- NEW: JSON helpers (for syncing/export) ---
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'timestamp': timestamp,
    'latitude': latitude,
    'longitude': longitude,
    'synced': synced,
    'meta': meta,
  };

  factory AlertModel.fromJson(Map<String, dynamic> json) => AlertModel(
    id: json['id'] as int?,
    type: json['type'] as String,
    timestamp: json['timestamp'] as int,
    latitude: json['latitude'] == null
        ? null
        : (json['latitude'] as num).toDouble(),
    longitude: json['longitude'] == null
        ? null
        : (json['longitude'] as num).toDouble(),
    synced: json['synced'] as bool? ?? false,
    meta: json['meta'] as String?,
  );

  @override
  String toString() {
    return 'AlertModel(id:$id, type:$type, ts:${DateTime.fromMillisecondsSinceEpoch(timestamp)}, '
        'lat:$latitude, lng:$longitude, synced:$synced, meta:$meta)';
  }
}
