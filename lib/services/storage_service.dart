import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

import '../app_theme.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  // Pick image from camera or gallery.
  Future<XFile?> pickImage({bool fromCamera = false}) async {
    final XFile? picked = await _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 720,
      maxHeight: 720,
      imageQuality: 55,
    );
    return picked;
  }

  // Upload event image to Firebase Storage.
  Future<String> uploadEventImage(XFile imageFile, String postId) async {
    return _uploadToFirebaseStorage(
      imageFile: imageFile,
      path: '${AppConstants.eventImagesPath}/$postId.jpg',
    );
  }

  // Upload profile image to Firebase Storage.
  Future<String> uploadProfileImage(XFile imageFile, String userId) async {
    return _uploadToFirebaseStorage(
      imageFile: imageFile,
      path: '${AppConstants.profileImagesPath}/$userId.jpg',
    );
  }

  Future<String> _uploadToFirebaseStorage({
    required XFile imageFile,
    required String path,
  }) async {
    final bytes = await imageFile.readAsBytes();
    final ref = _storage.ref().child(path);

    final uploadTask = await ref
        .putData(
          bytes,
          SettableMetadata(contentType: 'image/jpeg'),
        )
        .timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw TimeoutException('Image upload timed out.'),
        );

    return uploadTask.ref.getDownloadURL().timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw TimeoutException('Image URL timed out.'),
        );
  }

  // Free fallback for demos when Firebase Storage is not enabled.
  // Firestore documents have a 1 MB limit, so this only accepts small images.
  Future<String> imageAsFirestoreDataUrl(XFile imageFile) async {
    final bytes = await imageFile.readAsBytes();
    if (bytes.length > 700 * 1024) {
      throw Exception(
        'Image is too large for free demo upload. Choose a smaller image.',
      );
    }

    return 'data:image/jpeg;base64,${base64Encode(bytes)}';
  }

  // Delete image from Firebase Storage.
  Future<void> deleteImage(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (_) {
      // Ignore if the file was already removed or the URL is external.
    }
  }

  // Show image source picker dialog
  Future<XFile?> showImageSourcePicker(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Select Image Source',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    if (source == null) return null;
    return pickImage(fromCamera: source == ImageSource.camera);
  }
}
