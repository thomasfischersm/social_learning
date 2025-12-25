import 'package:firebase_storage/firebase_storage.dart';

class StorageFunctions {
  static Future<String> getDownloadUrl(String storagePath) async {
    Reference storageRef = FirebaseStorage.instance.ref(storagePath);
    return storageRef.getDownloadURL();
  }
}
