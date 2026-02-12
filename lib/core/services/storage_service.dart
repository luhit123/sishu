import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;

/// Service for uploading files to Firebase Storage
class StorageService {
  static StorageService? _instance;
  static FirebaseStorage? _storage;

  factory StorageService() {
    _instance ??= StorageService._internal();
    return _instance!;
  }

  StorageService._internal();

  FirebaseStorage get _storageInstance {
    _storage ??= FirebaseStorage.instance;
    return _storage!;
  }

  /// Upload an image from URL to Firebase Storage and return the permanent download URL
  /// This is used to convert temporary DALL-E URLs to permanent Firebase Storage URLs
  Future<String> uploadImageFromUrl({
    required String imageUrl,
    required String folder,
    String? fileName,
  }) async {
    try {
      // Download the image from the URL
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) {
        throw StorageException('Failed to download image: ${response.statusCode}');
      }

      final Uint8List imageBytes = response.bodyBytes;

      // Generate a unique filename if not provided
      final String name = fileName ?? 'img_${DateTime.now().millisecondsSinceEpoch}';
      final String path = '$folder/$name.png';

      // Upload to Firebase Storage
      final ref = _storageInstance.ref().child(path);
      final uploadTask = ref.putData(
        imageBytes,
        SettableMetadata(contentType: 'image/png'),
      );

      // Wait for upload to complete
      final snapshot = await uploadTask;

      // Get the permanent download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      if (e is StorageException) rethrow;
      throw StorageException('Failed to upload image: ${e.toString()}');
    }
  }

  /// Upload image bytes directly to Firebase Storage
  Future<String> uploadImageBytes({
    required Uint8List bytes,
    required String folder,
    String? fileName,
    String contentType = 'image/jpeg',
  }) async {
    try {
      final String name = fileName ?? 'img_${DateTime.now().millisecondsSinceEpoch}';
      final String extension = contentType == 'image/png' ? 'png' : 'jpg';
      final String path = '$folder/$name.$extension';

      final ref = _storageInstance.ref().child(path);
      final uploadTask = ref.putData(
        bytes,
        SettableMetadata(contentType: contentType),
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw StorageException('Failed to upload image: ${e.toString()}');
    }
  }

  /// Delete an image from Firebase Storage
  Future<void> deleteImage(String imageUrl) async {
    try {
      // Extract the path from the Firebase Storage URL
      final ref = _storageInstance.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      // Ignore errors when deleting (file might not exist)
    }
  }
}

/// Custom exception for storage errors
class StorageException implements Exception {
  final String message;
  StorageException(this.message);

  @override
  String toString() => message;
}
