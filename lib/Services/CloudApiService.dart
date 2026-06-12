import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:gcloud/storage.dart';
import 'package:mime/mime.dart';

class CloudApiService {
  final String _jsonCredentials;

  // Ensure these match your Google Cloud Console exactly
  final String _bucketName = "bai_ph";
  final String _projectId = "heartai-caare";

  CloudApiService(this._jsonCredentials);

  Future<String?> save(String name, List<int> bytes,
      {Map<String, String>? metadata}) async {
    // 1. Create Credentials object
    final credentials = auth.ServiceAccountCredentials.fromJson(_jsonCredentials);

    // 2. Use specific Storage Scopes
    final client = await auth.clientViaServiceAccount(
        credentials,
        ['https://www.googleapis.com/auth/devstorage.full_control']
    );

    try {
      final storage = Storage(client, _projectId);

      // Verify bucket exists/is accessible
      final bucket = storage.bucket(_bucketName);

      final type = lookupMimeType(name) ?? 'image/jpeg';

      // 3. Build custom metadata: always include timestamp; merge caller-supplied keys on top.
      final custom = <String, String>{
        'timestamp': DateTime.now().toIso8601String(),
        if (metadata != null) ...metadata,
      };

      // 4. Upload with Metadata
      // Use bucket.writeBytes which returns the ObjectInfo on success
      await bucket.writeBytes(
        name,
        bytes,
        metadata: ObjectMetadata(
          contentType: type,
          custom: custom,
        ),
      );

      // 4. Return the public URL
      // Note: This URL only works if the bucket/file has 'allUsers' Reader permission
      return "https://storage.googleapis.com/$_bucketName/$name";

    } catch (e) {
      // THIS IS THE LINE YOU MUST CHECK IN YOUR DEBUG CONSOLE
      print("DEBUG: GCS Upload Error Detail: $e");
      return null;
    } finally {
      client.close();
    }
  }
}

// class CloudApiService {
//   final auth.ServiceAccountCredentials _credentials;
//   late auth.AutoRefreshingAuthClient _client;
//
//   CloudApiService(String json)
//     : _credentials = auth.ServiceAccountCredentials.fromJson(json);
//
//   Future<String?> save(String name, Uint8List imgBytes) async {
//     // Create a client
//     _client = await auth.clientViaServiceAccount(_credentials, Storage.SCOPES);
//     print('_client $name $imgBytes');
//     // Instantiate objects to cloud storage
//     var storage = Storage(_client, 'heartai-caare');
//     var bucket = storage.bucket(
//       'projects/heartai-caare/buckets/bai_image_upload',
//     );
//     // Save to bucket
//     final timestamp = DateTime.now().millisecondsSinceEpoch;
//     final type = lookupMimeType(name);
//     return await bucket.writeBytes(
//       name,
//       imgBytes,
//       metadata: ObjectMetadata(
//         contentType: type,
//         custom: {'timestamp': '$timestamp'},
//       ),
//     );
//   }
// }
