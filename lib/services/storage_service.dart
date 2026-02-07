import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Uploads image bytes to Firebase Storage and returns the download URL.
  Future<String> uploadVerificationImage({
    required String userId,
    required String imageType,
    required Uint8List bytes,
  }) async {
    final ref = _storage
        .ref()
        .child('verification_images')
        .child(userId)
        .child('${imageType}_${DateTime.now().millisecondsSinceEpoch}.jpg');

    final metadata = SettableMetadata(contentType: 'image/jpeg');
    await ref.putData(bytes, metadata);
    return ref.getDownloadURL();
  }

  /// Deletes all verification images for a user.
  Future<void> deleteVerificationImages(String userId) async {
    try {
      final ref = _storage.ref().child('verification_images').child(userId);
      final result = await ref.listAll();
      for (final item in result.items) {
        await item.delete();
      }
    } catch (_) {
      // Folder may not exist yet — that's fine.
    }
  }
}
