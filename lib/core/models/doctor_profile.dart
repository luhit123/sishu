import 'package:cloud_firestore/cloud_firestore.dart';

/// Doctor profile details
class DoctorProfile {
  final String? uid; // Doctor's UID (document ID)
  final String name;
  final String email;
  final String? specialty;
  final String? degree;
  final String? registrationNumber;
  final String? state;
  final String? district;
  final String? clinicName;
  final String? clinicAddress;
  final String? photoUrl;
  final String? phone;
  final int? experienceYears;
  final List<String>? languages;
  final bool isVerified;
  // Availability flags - doctor can enable both
  final bool acceptingBookings;
  final bool acceptingInstantCalls;
  final DateTime? statusUpdatedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  DoctorProfile({
    this.uid,
    required this.name,
    required this.email,
    this.specialty,
    this.degree,
    this.registrationNumber,
    this.state,
    this.district,
    this.clinicName,
    this.clinicAddress,
    this.photoUrl,
    this.phone,
    this.experienceYears,
    this.languages,
    this.isVerified = false,
    this.acceptingBookings = false,
    this.acceptingInstantCalls = false,
    this.statusUpdatedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Check if doctor is available (accepting either bookings or instant calls)
  bool get isAvailable => acceptingBookings || acceptingInstantCalls;

  /// Check if doctor is offline
  bool get isOffline => !acceptingBookings && !acceptingInstantCalls;

  /// Create from Firestore document
  factory DoctorProfile.fromFirestore(Map<String, dynamic> data, {String? docId}) {
    return DoctorProfile(
      uid: docId,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      specialty: data['specialty'],
      degree: data['degree'],
      registrationNumber: data['registrationNumber'],
      state: data['state'],
      district: data['district'],
      clinicName: data['clinicName'],
      clinicAddress: data['clinicAddress'],
      photoUrl: data['photoUrl'],
      phone: data['phone'],
      experienceYears: data['experienceYears'],
      languages: data['languages'] != null
          ? List<String>.from(data['languages'])
          : null,
      isVerified: data['isVerified'] ?? false,
      acceptingBookings: data['acceptingBookings'] ?? false,
      acceptingInstantCalls: data['acceptingInstantCalls'] ?? false,
      statusUpdatedAt: (data['statusUpdatedAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'specialty': specialty,
      'degree': degree,
      'registrationNumber': registrationNumber,
      'state': state,
      'district': district,
      'clinicName': clinicName,
      'clinicAddress': clinicAddress,
      'photoUrl': photoUrl,
      'phone': phone,
      'experienceYears': experienceYears,
      'languages': languages,
      'isVerified': isVerified,
      'acceptingBookings': acceptingBookings,
      'acceptingInstantCalls': acceptingInstantCalls,
      'statusUpdatedAt': statusUpdatedAt != null ? Timestamp.fromDate(statusUpdatedAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create a copy with updated fields
  DoctorProfile copyWith({
    String? uid,
    String? name,
    String? email,
    String? specialty,
    String? degree,
    String? registrationNumber,
    String? state,
    String? district,
    String? clinicName,
    String? clinicAddress,
    String? photoUrl,
    String? phone,
    int? experienceYears,
    List<String>? languages,
    bool? isVerified,
    bool? acceptingBookings,
    bool? acceptingInstantCalls,
    DateTime? statusUpdatedAt,
    DateTime? updatedAt,
  }) {
    return DoctorProfile(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      specialty: specialty ?? this.specialty,
      degree: degree ?? this.degree,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      state: state ?? this.state,
      district: district ?? this.district,
      clinicName: clinicName ?? this.clinicName,
      clinicAddress: clinicAddress ?? this.clinicAddress,
      photoUrl: photoUrl ?? this.photoUrl,
      phone: phone ?? this.phone,
      experienceYears: experienceYears ?? this.experienceYears,
      languages: languages ?? this.languages,
      isVerified: isVerified ?? this.isVerified,
      acceptingBookings: acceptingBookings ?? this.acceptingBookings,
      acceptingInstantCalls: acceptingInstantCalls ?? this.acceptingInstantCalls,
      statusUpdatedAt: statusUpdatedAt ?? this.statusUpdatedAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Common medical specialties in India
class DoctorSpecialties {
  static const List<String> list = [
    'General Physician',
    'Pediatrician',
    'Gynecologist',
    'Dermatologist',
    'Orthopedic',
    'Cardiologist',
    'Neurologist',
    'ENT Specialist',
    'Ophthalmologist',
    'Psychiatrist',
    'Dentist',
    'Ayurveda',
    'Homeopathy',
    'Physiotherapist',
    'Nutritionist',
    'Other',
  ];
}

/// Indian states list
class IndianStates {
  static const List<String> list = [
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chhattisgarh',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
    'Delhi',
    'Jammu & Kashmir',
    'Ladakh',
  ];
}
