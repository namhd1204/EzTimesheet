import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class GoogleDriveService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveFileScope],
  );

  static const String _lastBackupKey = 'last_backup_date';
  static const String _backupFileName = 'eztimesheet_backup.json';

  /// Sign in with Google
  Future<GoogleSignInAccount?> signIn() async {
    try {
      return await _googleSignIn.signIn();
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      return null;
    }
  }

  /// Silently restore sign in session
  Future<GoogleSignInAccount?> signInSilently() async {
    try {
      final account = await _googleSignIn.signInSilently();
      if (account == null) {
        debugPrint(
            'Google Silent Sign-In returned null (User not authenticated)');
      } else {
        debugPrint('Google Silent Sign-In Success: ${account.email}');
      }
      return account;
    } catch (e) {
      debugPrint('Google Silent Sign-In Error: $e');
      return null;
    }
  }

  /// Check if automated backup is needed (once a day)
  Future<bool> isBackupNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final lastBackupStr = prefs.getString(_lastBackupKey);
    if (lastBackupStr == null) return true;

    final lastBackup = DateTime.parse(lastBackupStr);
    final now = DateTime.now();
    return now.difference(lastBackup).inDays >= 1;
  }

  /// Update last backup date
  Future<void> updateLastBackupDate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastBackupKey, DateTime.now().toIso8601String());
  }

  /// Upload backup content to Google Drive
  Future<bool> uploadBackup(String content) async {
    try {
      final account = await signInSilently() ?? await signIn();
      if (account == null) {
        debugPrint('Upload failed: No account');
        return false;
      }

      final authHeaders = await account.authHeaders;
      debugPrint('Auth Headers: $authHeaders');

      final authenticateClient = _GoogleAuthClient(authHeaders);
      final driveApi = drive.DriveApi(authenticateClient);

      // Search for existing backup file
      final fileList = await driveApi.files.list(
        q: "name = '$_backupFileName' and trashed = false",
        spaces: 'drive',
      );

      final drive.File fileMetadata = drive.File();
      fileMetadata.name = _backupFileName;

      final media = drive.Media(
        Stream.value(content.codeUnits),
        content.length,
      );

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        // Update existing file
        final fileId = fileList.files!.first.id!;
        await driveApi.files.update(fileMetadata, fileId, uploadMedia: media);
      } else {
        // Create new file
        await driveApi.files.create(fileMetadata, uploadMedia: media);
      }

      await updateLastBackupDate();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Download backup from Google Drive
  Future<String?> downloadBackup() async {
    try {
      final account = await signInSilently() ?? await signIn();
      if (account == null) {
        debugPrint('Download failed: No account');
        return null;
      }

      final authHeaders = await account.authHeaders;
      debugPrint('Auth Headers: $authHeaders');

      final authenticateClient = _GoogleAuthClient(authHeaders);
      final driveApi = drive.DriveApi(authenticateClient);

      final fileList = await driveApi.files.list(
        q: "name = '$_backupFileName' and trashed = false",
        spaces: 'drive',
      );

      if (fileList.files == null || fileList.files!.isEmpty) return null;

      final fileId = fileList.files!.first.id!;
      final media = await driveApi.files.get(fileId,
          downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;

      final List<int> data = [];
      await for (final chunk in media.stream) {
        data.addAll(chunk);
      }

      return String.fromCharCodes(data);
    } catch (e) {
      return null;
    }
  }
}

class _GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  _GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}
