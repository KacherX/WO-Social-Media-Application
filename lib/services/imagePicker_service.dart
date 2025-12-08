import 'dart:io';

import 'package:image_picker/image_picker.dart';

class imagePicker_service {
  final ImagePicker _imagePicker = ImagePicker();

  Future<File?> takePhoto() async {
    try {
      final pickedFile =
          await _imagePicker.pickImage(source: ImageSource.camera);

      if (pickedFile != null) {
        return File(pickedFile.path);
      } else {
        return null;
      }
    } catch (e) {
      print("Error capturing photo: $e");
      return null;
    }
  }

  Future<File?> takePhotoFromGallery() async {
    try {
      final pickedFile =
          await _imagePicker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        return File(pickedFile.path);
      } else {
        return null;
      }
    } catch (e) {
      print("Error capturing photo: $e");
      return null;
    }
  }
}
