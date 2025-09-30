// lib/models/emergency_contact.dart

class EmergencyContact {
  final int? id; // Auto-increment PK from DB
  final String uuid; // Stable unique ID for cross-device sync
  final String name;
  final String phone; // E.164 preferred
  final List<String> channels; // ["sms", "call", "whatsapp"]
  final bool priority; // true if first-tier contact
  final bool notifyAllOnRed; // included in full-red escalation
  final String? notes;
  final int createdAt; // epoch millis
  final int updatedAt; // epoch millis

  EmergencyContact({
    this.id,
    required this.uuid,
    required this.name,
    required this.phone,
    required this.channels,
    this.priority = false,
    this.notifyAllOnRed = false,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Convert to DB row map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uuid': uuid,
      'name': name,
      'phone': phone,
      'channels': channels.join(','), // CSV for storage
      'priority': priority ? 1 : 0,
      'notify_all_on_red': notifyAllOnRed ? 1 : 0,
      'notes': notes,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  /// Build model from DB row map
  factory EmergencyContact.fromMap(Map<String, dynamic> map) {
    return EmergencyContact(
      id: map['id'] as int?,
      uuid: map['uuid'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String,
      channels: (map['channels'] as String? ?? '')
          .split(',')
          .where((s) => s.isNotEmpty)
          .toList(),
      priority: (map['priority'] ?? 0) == 1,
      notifyAllOnRed: (map['notify_all_on_red'] ?? 0) == 1,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
    );
  }

  /// Create a modified copy of this contact
  EmergencyContact copyWith({
    int? id,
    String? uuid,
    String? name,
    String? phone,
    List<String>? channels,
    bool? priority,
    bool? notifyAllOnRed,
    String? notes,
    int? createdAt,
    int? updatedAt,
  }) {
    return EmergencyContact(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      channels: channels ?? this.channels,
      priority: priority ?? this.priority,
      notifyAllOnRed: notifyAllOnRed ?? this.notifyAllOnRed,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
