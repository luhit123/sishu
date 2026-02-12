import 'package:cloud_firestore/cloud_firestore.dart';

/// Target audience for notifications
enum NotificationTarget {
  all,      // All users
  doctors,  // Doctors only
  parents,  // Parents/regular users only
}

/// Type of notification content
enum NotificationType {
  general,       // Custom notification from admin
  newTip,        // New parenting tip added
  newDisease,    // New disease info added
  announcement,  // General announcement
}

/// Model for admin-sent notifications
class AdminNotification {
  final String id;
  final String title;
  final String body;
  final String? imageUrl;
  final NotificationTarget target;
  final NotificationType type;
  final String? referenceId;    // ID of tip/disease if applicable
  final String? referenceType;  // 'tip' or 'disease'
  final int sentCount;          // Number of users notified
  final String sentBy;          // Admin UID who sent it
  final String sentByName;      // Admin name
  final DateTime sentAt;
  final Map<String, dynamic>? extraData;

  AdminNotification({
    required this.id,
    required this.title,
    required this.body,
    this.imageUrl,
    required this.target,
    required this.type,
    this.referenceId,
    this.referenceType,
    this.sentCount = 0,
    required this.sentBy,
    required this.sentByName,
    required this.sentAt,
    this.extraData,
  });

  factory AdminNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdminNotification(
      id: doc.id,
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      imageUrl: data['imageUrl'],
      target: NotificationTarget.values.firstWhere(
        (e) => e.name == data['target'],
        orElse: () => NotificationTarget.all,
      ),
      type: NotificationType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => NotificationType.general,
      ),
      referenceId: data['referenceId'],
      referenceType: data['referenceType'],
      sentCount: data['sentCount'] ?? 0,
      sentBy: data['sentBy'] ?? '',
      sentByName: data['sentByName'] ?? '',
      sentAt: (data['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      extraData: data['extraData'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'body': body,
      'imageUrl': imageUrl,
      'target': target.name,
      'type': type.name,
      'referenceId': referenceId,
      'referenceType': referenceType,
      'sentCount': sentCount,
      'sentBy': sentBy,
      'sentByName': sentByName,
      'sentAt': Timestamp.fromDate(sentAt),
      'extraData': extraData,
    };
  }

  AdminNotification copyWith({
    String? id,
    String? title,
    String? body,
    String? imageUrl,
    NotificationTarget? target,
    NotificationType? type,
    String? referenceId,
    String? referenceType,
    int? sentCount,
    String? sentBy,
    String? sentByName,
    DateTime? sentAt,
    Map<String, dynamic>? extraData,
  }) {
    return AdminNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      imageUrl: imageUrl ?? this.imageUrl,
      target: target ?? this.target,
      type: type ?? this.type,
      referenceId: referenceId ?? this.referenceId,
      referenceType: referenceType ?? this.referenceType,
      sentCount: sentCount ?? this.sentCount,
      sentBy: sentBy ?? this.sentBy,
      sentByName: sentByName ?? this.sentByName,
      sentAt: sentAt ?? this.sentAt,
      extraData: extraData ?? this.extraData,
    );
  }

  String get targetLabel {
    switch (target) {
      case NotificationTarget.all:
        return 'All Users';
      case NotificationTarget.doctors:
        return 'Doctors Only';
      case NotificationTarget.parents:
        return 'Parents Only';
    }
  }

  String get typeLabel {
    switch (type) {
      case NotificationType.general:
        return 'General';
      case NotificationType.newTip:
        return 'New Tip';
      case NotificationType.newDisease:
        return 'New Disease Info';
      case NotificationType.announcement:
        return 'Announcement';
    }
  }
}
