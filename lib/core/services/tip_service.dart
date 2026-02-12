import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/parenting_tip.dart';

/// Service for managing parenting tips in Firestore
class TipService {
  // Singleton instance
  static TipService? _instance;
  static FirebaseFirestore? _firestore;

  factory TipService() {
    _instance ??= TipService._internal();
    return _instance!;
  }

  TipService._internal();

  FirebaseFirestore get _firestoreInstance {
    _firestore ??= FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'sishu',
    );
    return _firestore!;
  }

  CollectionReference<Map<String, dynamic>> get _tipsCollection =>
      _firestoreInstance.collection('parenting_tips');

  // ============================================================================
  // CREATE OPERATIONS
  // ============================================================================

  /// Add a new parenting tip
  Future<String> addTip(ParentingTip tip) async {
    final docRef = await _tipsCollection.add(tip.toFirestore());
    return docRef.id;
  }

  // ============================================================================
  // READ OPERATIONS
  // ============================================================================

  /// Get all active tips
  Future<List<ParentingTip>> getActiveTips() async {
    final querySnapshot = await _tipsCollection
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .get();
    return querySnapshot.docs.map((doc) => ParentingTip.fromFirestore(doc)).toList();
  }

  /// Get all tips (for admin)
  Future<List<ParentingTip>> getAllTips() async {
    final querySnapshot = await _tipsCollection
        .orderBy('createdAt', descending: true)
        .get();
    return querySnapshot.docs.map((doc) => ParentingTip.fromFirestore(doc)).toList();
  }

  /// Get featured tips for marquee display
  Future<List<ParentingTip>> getFeaturedTips({int limit = 10}) async {
    final querySnapshot = await _tipsCollection
        .where('isActive', isEqualTo: true)
        .where('isFeatured', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    // If no featured tips, get latest tips
    if (querySnapshot.docs.isEmpty) {
      final latestSnapshot = await _tipsCollection
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      return latestSnapshot.docs.map((doc) => ParentingTip.fromFirestore(doc)).toList();
    }

    return querySnapshot.docs.map((doc) => ParentingTip.fromFirestore(doc)).toList();
  }

  /// Get tips by category
  Future<List<ParentingTip>> getTipsByCategory(TipCategory category) async {
    final querySnapshot = await _tipsCollection
        .where('isActive', isEqualTo: true)
        .where('category', isEqualTo: category.value)
        .orderBy('createdAt', descending: true)
        .get();
    return querySnapshot.docs.map((doc) => ParentingTip.fromFirestore(doc)).toList();
  }

  /// Get tips by age group
  Future<List<ParentingTip>> getTipsByAgeGroup(AgeGroup ageGroup) async {
    final querySnapshot = await _tipsCollection
        .where('isActive', isEqualTo: true)
        .where('ageGroup', isEqualTo: ageGroup.value)
        .orderBy('createdAt', descending: true)
        .get();
    return querySnapshot.docs.map((doc) => ParentingTip.fromFirestore(doc)).toList();
  }

  /// Get a single tip by ID
  Future<ParentingTip?> getTip(String id) async {
    final docSnapshot = await _tipsCollection.doc(id).get();
    if (!docSnapshot.exists) return null;
    return ParentingTip.fromFirestore(docSnapshot);
  }

  /// Search tips by title or content
  Future<List<ParentingTip>> searchTips(String query) async {
    // Note: Firestore doesn't support full-text search, so we fetch all and filter
    // For production, consider Algolia or similar
    final allTips = await getActiveTips();
    final lowerQuery = query.toLowerCase();
    return allTips.where((tip) {
      return tip.title.toLowerCase().contains(lowerQuery) ||
          tip.content.toLowerCase().contains(lowerQuery) ||
          tip.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
    }).toList();
  }

  // ============================================================================
  // STREAM OPERATIONS (Real-time updates)
  // ============================================================================

  /// Stream of active tips for real-time updates
  Stream<List<ParentingTip>> activeTipsStream() {
    return _tipsCollection
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ParentingTip.fromFirestore(doc)).toList());
  }

  /// Stream of featured tips for marquee
  Stream<List<ParentingTip>> featuredTipsStream({int limit = 10}) {
    return _tipsCollection
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ParentingTip.fromFirestore(doc)).toList());
  }

  /// Stream of all tips for admin
  Stream<List<ParentingTip>> allTipsStream() {
    return _tipsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ParentingTip.fromFirestore(doc)).toList());
  }

  // ============================================================================
  // UPDATE OPERATIONS
  // ============================================================================

  /// Update a tip
  Future<void> updateTip(String id, Map<String, dynamic> updates) async {
    updates['updatedAt'] = FieldValue.serverTimestamp();
    await _tipsCollection.doc(id).update(updates);
  }

  /// Toggle tip active status
  Future<void> toggleTipActive(String id, bool isActive) async {
    await _tipsCollection.doc(id).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Toggle tip featured status
  Future<void> toggleTipFeatured(String id, bool isFeatured) async {
    await _tipsCollection.doc(id).update({
      'isFeatured': isFeatured,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Increment view count
  Future<void> incrementViewCount(String id) async {
    await _tipsCollection.doc(id).update({
      'viewCount': FieldValue.increment(1),
    });
  }

  // ============================================================================
  // DELETE OPERATIONS
  // ============================================================================

  /// Delete a tip permanently
  Future<void> deleteTip(String id) async {
    await _tipsCollection.doc(id).delete();
  }

  // ============================================================================
  // STATS
  // ============================================================================

  /// Get tip statistics
  Future<Map<String, int>> getTipStats() async {
    final allTips = await getAllTips();
    return {
      'total': allTips.length,
      'active': allTips.where((t) => t.isActive).length,
      'featured': allTips.where((t) => t.isFeatured).length,
      'inactive': allTips.where((t) => !t.isActive).length,
    };
  }
}
