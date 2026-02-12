import 'package:cloud_firestore/cloud_firestore.dart';

/// Call status enum
enum CallStatus {
  ringing,
  answered,
  ended,
  missed,
  declined,
}

extension CallStatusExtension on CallStatus {
  String get value {
    switch (this) {
      case CallStatus.ringing:
        return 'ringing';
      case CallStatus.answered:
        return 'answered';
      case CallStatus.ended:
        return 'ended';
      case CallStatus.missed:
        return 'missed';
      case CallStatus.declined:
        return 'declined';
    }
  }

  static CallStatus fromString(String? value) {
    switch (value) {
      case 'ringing':
        return CallStatus.ringing;
      case 'answered':
        return CallStatus.answered;
      case 'ended':
        return CallStatus.ended;
      case 'missed':
        return CallStatus.missed;
      case 'declined':
        return CallStatus.declined;
      default:
        return CallStatus.ringing;
    }
  }
}

/// Call model for Firestore
class CallModel {
  final String id;
  final String callerId;
  final String callerName;
  final String? callerPhoto;
  final String doctorId;
  final String doctorName;
  final String? doctorPhoto;
  final CallStatus status;
  final DateTime startedAt;
  final DateTime? answeredAt;
  final DateTime? endedAt;
  final int duration; // in seconds

  CallModel({
    required this.id,
    required this.callerId,
    required this.callerName,
    this.callerPhoto,
    required this.doctorId,
    required this.doctorName,
    this.doctorPhoto,
    required this.status,
    required this.startedAt,
    this.answeredAt,
    this.endedAt,
    this.duration = 0,
  });

  /// Create from Firestore document
  factory CallModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CallModel(
      id: doc.id,
      callerId: data['callerId'] ?? '',
      callerName: data['callerName'] ?? '',
      callerPhoto: data['callerPhoto'],
      doctorId: data['doctorId'] ?? '',
      doctorName: data['doctorName'] ?? '',
      doctorPhoto: data['doctorPhoto'],
      status: CallStatusExtension.fromString(data['status']),
      startedAt: (data['startedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      answeredAt: (data['answeredAt'] as Timestamp?)?.toDate(),
      endedAt: (data['endedAt'] as Timestamp?)?.toDate(),
      duration: data['duration'] ?? 0,
    );
  }

  /// Create from map (for Realtime Database)
  factory CallModel.fromMap(String id, Map<String, dynamic> data) {
    return CallModel(
      id: id,
      callerId: data['callerId'] ?? '',
      callerName: data['callerName'] ?? '',
      callerPhoto: data['callerPhoto'],
      doctorId: data['doctorId'] ?? '',
      doctorName: data['doctorName'] ?? '',
      doctorPhoto: data['doctorPhoto'],
      status: CallStatusExtension.fromString(data['status']),
      startedAt: data['startedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['startedAt'])
          : DateTime.now(),
      answeredAt: data['answeredAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['answeredAt'])
          : null,
      endedAt: data['endedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['endedAt'])
          : null,
      duration: data['duration'] ?? 0,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'callerId': callerId,
      'callerName': callerName,
      'callerPhoto': callerPhoto,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'doctorPhoto': doctorPhoto,
      'status': status.value,
      'startedAt': Timestamp.fromDate(startedAt),
      'answeredAt': answeredAt != null ? Timestamp.fromDate(answeredAt!) : null,
      'endedAt': endedAt != null ? Timestamp.fromDate(endedAt!) : null,
      'duration': duration,
    };
  }

  /// Convert to map (for Realtime Database)
  Map<String, dynamic> toMap() {
    return {
      'callerId': callerId,
      'callerName': callerName,
      'callerPhoto': callerPhoto,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'doctorPhoto': doctorPhoto,
      'status': status.value,
      'startedAt': startedAt.millisecondsSinceEpoch,
      'answeredAt': answeredAt?.millisecondsSinceEpoch,
      'endedAt': endedAt?.millisecondsSinceEpoch,
      'duration': duration,
    };
  }

  /// Create a copy with updated fields
  CallModel copyWith({
    String? id,
    String? callerId,
    String? callerName,
    String? callerPhoto,
    String? doctorId,
    String? doctorName,
    String? doctorPhoto,
    CallStatus? status,
    DateTime? startedAt,
    DateTime? answeredAt,
    DateTime? endedAt,
    int? duration,
  }) {
    return CallModel(
      id: id ?? this.id,
      callerId: callerId ?? this.callerId,
      callerName: callerName ?? this.callerName,
      callerPhoto: callerPhoto ?? this.callerPhoto,
      doctorId: doctorId ?? this.doctorId,
      doctorName: doctorName ?? this.doctorName,
      doctorPhoto: doctorPhoto ?? this.doctorPhoto,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      answeredAt: answeredAt ?? this.answeredAt,
      endedAt: endedAt ?? this.endedAt,
      duration: duration ?? this.duration,
    );
  }

  /// Check if this user is the caller
  bool isCaller(String userId) => callerId == userId;

  /// Check if this user is the doctor
  bool isDoctor(String userId) => doctorId == userId;

  /// Get the other party's name (for display)
  String getOtherPartyName(String currentUserId) {
    return isCaller(currentUserId) ? doctorName : callerName;
  }

  /// Get the other party's photo (for display)
  String? getOtherPartyPhoto(String currentUserId) {
    return isCaller(currentUserId) ? doctorPhoto : callerPhoto;
  }

  /// Get formatted duration string
  String get formattedDuration {
    if (duration == 0) return '--:--';
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Check if call is active (ringing or answered)
  bool get isActive => status == CallStatus.ringing || status == CallStatus.answered;

  /// Check if call has ended
  bool get hasEnded =>
      status == CallStatus.ended ||
      status == CallStatus.missed ||
      status == CallStatus.declined;
}

/// ICE Candidate model for WebRTC signaling
class IceCandidate {
  final String candidate;
  final String? sdpMid;
  final int? sdpMLineIndex;

  IceCandidate({
    required this.candidate,
    this.sdpMid,
    this.sdpMLineIndex,
  });

  factory IceCandidate.fromMap(Map<String, dynamic> data) {
    return IceCandidate(
      candidate: data['candidate'] ?? '',
      sdpMid: data['sdpMid'],
      sdpMLineIndex: data['sdpMLineIndex'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'candidate': candidate,
      'sdpMid': sdpMid,
      'sdpMLineIndex': sdpMLineIndex,
    };
  }
}

/// Session Description model for WebRTC signaling
class SessionDescription {
  final String type; // 'offer' or 'answer'
  final String sdp;

  SessionDescription({
    required this.type,
    required this.sdp,
  });

  factory SessionDescription.fromMap(Map<String, dynamic> data) {
    return SessionDescription(
      type: data['type'] ?? '',
      sdp: data['sdp'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'sdp': sdp,
    };
  }
}

/// TURN credentials from Xirsys
class TurnCredentials {
  final String username;
  final String credential;
  final List<String> urls;

  TurnCredentials({
    required this.username,
    required this.credential,
    required this.urls,
  });

  factory TurnCredentials.fromMap(Map<String, dynamic> data) {
    return TurnCredentials(
      username: data['username'] ?? '',
      credential: data['credential'] ?? '',
      urls: List<String>.from(data['urls'] ?? []),
    );
  }
}
