// in lib/models/alert.dart (add inside class or as top-level)
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

  @override
  String toString() {
    return 'AlertModel(id:$id, type:$type, ts:${DateTime.fromMillisecondsSinceEpoch(timestamp)}, '
        'lat:$latitude, lng:$longitude, synced:$synced, meta:$meta)';
  }
}
