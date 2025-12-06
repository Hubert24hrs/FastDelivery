import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadProfilePhoto(String userId, File file) async {
    final ref = _storage.ref().child('users/$userId/profile_photo.jpg');
    final uploadTask = ref.putFile(file);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  Future<String> uploadDocument(String userId, String docType, File file) async {
    final ref = _storage.ref().child('users/$userId/documents/$docType.jpg');
    final uploadTask = ref.putFile(file);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }
}

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});
