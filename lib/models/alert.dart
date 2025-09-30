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

  // --- NEW fields aligned with DB ---
  final String? escalationPolicy; // escalation_policy column
  final String? targetContacts; // target_contacts column (CSV)
  final bool isDecoy; // is_decoy column
  final String? escalationState; // escalation_state column

  AlertModel({
    this.id,
    required this.type,
    required this.timestamp,
    this.latitude,
    this.longitude,
    this.synced = false,
    this.meta,
    this.escalationPolicy,
    this.targetContacts,
    this.isDecoy = false,
    this.escalationState,
  });

  // --- SQLite map helpers ---
  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type,
    'timestamp': timestamp,
    'latitude': latitude,
    'longitude': longitude,
    'synced': synced ? 1 : 0,
    'meta': meta,
    'escalation_policy': escalationPolicy,
    'target_contacts': targetContacts,
    'is_decoy': isDecoy ? 1 : 0,
    'escalation_state': escalationState,
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
    escalationPolicy: m['escalation_policy'] as String?,
    targetContacts: m['target_contacts'] as String?,
    isDecoy: (m['is_decoy'] as int?) == 1,
    escalationState: m['escalation_state'] as String?,
  );

  // --- JSON helpers (for syncing/export) ---
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'timestamp': timestamp,
    'latitude': latitude,
    'longitude': longitude,
    'synced': synced,
    'meta': meta,
    'escalation_policy': escalationPolicy,
    'target_contacts': targetContacts,
    'is_decoy': isDecoy,
    'escalation_state': escalationState,
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
    escalationPolicy: json['escalation_policy'] as String?,
    targetContacts: json['target_contacts'] as String?,
    isDecoy: json['is_decoy'] as bool? ?? false,
    escalationState: json['escalation_state'] as String?,
  );

  // --- Convenience: copyWith ---
  AlertModel copyWith({
    int? id,
    String? type,
    int? timestamp,
    double? latitude,
    double? longitude,
    bool? synced,
    String? meta,
    String? escalationPolicy,
    String? targetContacts,
    bool? isDecoy,
    String? escalationState,
  }) {
    return AlertModel(
      id: id ?? this.id,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      synced: synced ?? this.synced,
      meta: meta ?? this.meta,
      escalationPolicy: escalationPolicy ?? this.escalationPolicy,
      targetContacts: targetContacts ?? this.targetContacts,
      isDecoy: isDecoy ?? this.isDecoy,
      escalationState: escalationState ?? this.escalationState,
    );
  }

  @override
  String toString() {
    return 'AlertModel(id:$id, type:$type, ts:${DateTime.fromMillisecondsSinceEpoch(timestamp)}, '
        'lat:$latitude, lng:$longitude, synced:$synced, meta:$meta, '
        'escalationPolicy:$escalationPolicy, contacts:$targetContacts, '
        'isDecoy:$isDecoy, escalationState:$escalationState)';
  }
}
