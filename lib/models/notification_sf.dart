import 'dart:convert';
import 'package:uuid/uuid.dart';

class NotificationSF {
  String id;
  String device;
  int value;
  DateTime createdAt;

  NotificationSF({
    String? id,
    required this.device,
    required this.value,
    DateTime? createdAt,
  }) : id =
           id ?? const Uuid().v1(),
       createdAt = createdAt ?? DateTime.now();

  factory NotificationSF.fromJson(Map<String, dynamic> json) {
    return NotificationSF(
      id: json['id'],
      device: json['device'],
      value: json['value'],
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'device': device,
      'value': value,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return jsonEncode(toJson());
  }

  static NotificationSF fromString(String jsonString) {
    Map<String, dynamic> json = jsonDecode(jsonString);
    return NotificationSF.fromJson(json);
  }
}
