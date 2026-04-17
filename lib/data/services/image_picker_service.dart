import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerService {
  final FirebaseStorage _storage = FirebaseStorage.instanceFor(
      bucket: "little-johor-explorer-db.firebasestorage.app");
  final ImagePicker _picker = ImagePicker();

  Future<String?> pickAndUploadImage({required String folderName}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 70,
      );

      if (image == null) return null;

      final Uint8List bytes = await image.readAsBytes();
      final String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
      final String destination = '$folderName/$fileName';

      Reference ref = _storage.ref().child(destination);

      UploadTask uploadTask = ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Upload Error: $e");
      return null;
    }
  }
}
