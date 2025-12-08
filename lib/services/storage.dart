import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class Storage {
  final FirebaseStorage _firebaseStorage = FirebaseStorage.instance;

  Future<String?> uploadProfilePhoto(
      {required String userId, required File file}) async {
    try {
      Reference ref =
          _firebaseStorage.ref().child('users/$userId/profile_photo.jpg');
      UploadTask uploadTask = ref.putFile(file);

      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading profile photo: $e');
      return null;
    }
  }

  Future<void> deleteProfilePhoto({required String userId}) async {
    try {
      Reference ref =
          _firebaseStorage.ref().child('users/$userId/profile_photo.jpg');
      await ref.delete();
    } catch (e) {
      print('Error deleting profile photo: $e');
    }
  }

  Future<String?> uploadProfileCoverPhoto(
      {required String userId, required File file}) async {
    try {
      Reference ref =
          _firebaseStorage.ref().child('users/$userId/profile_cover_photo.jpg');
      UploadTask uploadTask = ref.putFile(file);

      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading profile cover photo: $e');
      return null;
    }
  }

  Future<void> deleteProfileCoverPhoto({required String userId}) async {
    try {
      Reference ref =
          _firebaseStorage.ref().child('users/$userId/profile_cover_photo.jpg');
      await ref.delete();
    } catch (e) {
      print('Error deleting profile cover photo: $e');
    }
  }

  Future<String?> uploadPost(
      {required String userId,
      required String postId,
      required File file}) async {
    try {
      Reference ref =
          _firebaseStorage.ref().child('users/$userId/posts/$postId');
      UploadTask uploadTask = ref.putFile(file);

      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading post: $e');
      return null;
    }
  }

  Future<void> deletePost(
      {required String userId, required String postId}) async {
    try {
      Reference ref =
          _firebaseStorage.ref().child('users/$userId/posts/$postId');
      await ref.delete();
    } catch (e) {
      print('Error deleting file: $e');
    }
  }
}
