import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';

class AttachmentService {
  static final AttachmentService _instance = AttachmentService._internal();
  factory AttachmentService() => _instance;
  AttachmentService._internal();

  final ImagePicker _imagePicker = ImagePicker();

  /// Kameradan fotoğraf çek
  Future<String?> takePhoto() async {
    try {
      // İzin kontrolü
      final cameraStatus = await Permission.camera.request();
      if (!cameraStatus.isGranted) {
        return null;
      }

      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (photo == null) return null;

      // Dosyayı uygulama dizinine kaydet
      final savedPath = await _saveFile(File(photo.path));
      return savedPath;
    } catch (e) {
      print('Fotoğraf çekme hatası: $e');
      return null;
    }
  }

  /// Galeriden fotoğraf seç
  Future<String?> pickImage() async {
    try {
      // İzin kontrolü
      if (Platform.isAndroid) {
        final storageStatus = await Permission.storage.request();
        if (!storageStatus.isGranted) {
          final photosStatus = await Permission.photos.request();
          if (!photosStatus.isGranted) {
            return null;
          }
        }
      } else if (Platform.isIOS) {
        final photosStatus = await Permission.photos.request();
        if (!photosStatus.isGranted) {
          return null;
        }
      }

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image == null) return null;

      // Dosyayı uygulama dizinine kaydet
      final savedPath = await _saveFile(File(image.path));
      return savedPath;
    } catch (e) {
      print('Fotoğraf seçme hatası: $e');
      return null;
    }
  }

  /// Birden fazla fotoğraf seç
  Future<List<String>> pickMultipleImages() async {
    try {
      // İzin kontrolü
      if (Platform.isAndroid) {
        final storageStatus = await Permission.storage.request();
        if (!storageStatus.isGranted) {
          final photosStatus = await Permission.photos.request();
          if (!photosStatus.isGranted) {
            return [];
          }
        }
      } else if (Platform.isIOS) {
        final photosStatus = await Permission.photos.request();
        if (!photosStatus.isGranted) {
          return [];
        }
      }

      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (images.isEmpty) return [];

      // Dosyaları uygulama dizinine kaydet
      final List<String> savedPaths = [];
      for (final image in images) {
        final savedPath = await _saveFile(File(image.path));
        if (savedPath != null) {
          savedPaths.add(savedPath);
        }
      }
      return savedPaths;
    } catch (e) {
      print('Çoklu fotoğraf seçme hatası: $e');
      return [];
    }
  }

  /// Dosya seç
  Future<String?> pickFile() async {
    try {
      // İzin kontrolü
      if (Platform.isAndroid) {
        final storageStatus = await Permission.storage.request();
        if (!storageStatus.isGranted) {
          return null;
        }
      }

      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return null;

      final file = File(result.files.single.path!);
      
      // Dosya boyutu kontrolü (max 10MB)
      final fileSize = await file.length();
      if (fileSize > 10 * 1024 * 1024) {
        throw Exception('Dosya boyutu 10MB\'dan büyük olamaz');
      }

      // Dosyayı uygulama dizinine kaydet
      final savedPath = await _saveFile(file);
      return savedPath;
    } catch (e) {
      print('Dosya seçme hatası: $e');
      return null;
    }
  }

  /// Birden fazla dosya seç
  Future<List<String>> pickMultipleFiles() async {
    try {
      // İzin kontrolü
      if (Platform.isAndroid) {
        final storageStatus = await Permission.storage.request();
        if (!storageStatus.isGranted) {
          return [];
        }
      }

      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: true,
      );

      if (result == null || result.files.isEmpty) return [];

      final List<String> savedPaths = [];
      for (final fileInfo in result.files) {
        if (fileInfo.path == null) continue;

        final file = File(fileInfo.path!);
        
        // Dosya boyutu kontrolü (max 10MB)
        final fileSize = await file.length();
        if (fileSize > 10 * 1024 * 1024) {
          print('Dosya boyutu 10MB\'dan büyük: ${fileInfo.name}');
          continue;
        }

        final savedPath = await _saveFile(file);
        if (savedPath != null) {
          savedPaths.add(savedPath);
        }
      }
      return savedPaths;
    } catch (e) {
      print('Çoklu dosya seçme hatası: $e');
      return [];
    }
  }

  /// Dosyayı uygulama dizinine kaydet
  Future<String?> _saveFile(File file) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final attachmentsDir = Directory('${appDir.path}/attachments');
      
      if (!await attachmentsDir.exists()) {
        await attachmentsDir.create(recursive: true);
      }

      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';
      final savedFile = File('${attachmentsDir.path}/$fileName');
      
      await file.copy(savedFile.path);
      return savedFile.path;
    } catch (e) {
      print('Dosya kaydetme hatası: $e');
      return null;
    }
  }

  /// Dosyayı sil
  Future<bool> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Dosya silme hatası: $e');
      return false;
    }
  }

  /// Birden fazla dosyayı sil
  Future<void> deleteFiles(List<String> filePaths) async {
    for (final filePath in filePaths) {
      await deleteFile(filePath);
    }
  }

  /// Dosya boyutunu al
  Future<int> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      print('Dosya boyutu alma hatası: $e');
      return 0;
    }
  }

  /// Dosya türünü al
  String getFileType(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    
    if (['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'].contains(extension)) {
      return 'image';
    } else if (['.mp4', '.avi', '.mov', '.mkv'].contains(extension)) {
      return 'video';
    } else if (['.mp3', '.wav', '.m4a', '.aac'].contains(extension)) {
      return 'audio';
    } else if (['.pdf'].contains(extension)) {
      return 'pdf';
    } else if (['.doc', '.docx'].contains(extension)) {
      return 'document';
    } else if (['.xls', '.xlsx'].contains(extension)) {
      return 'spreadsheet';
    } else if (['.txt'].contains(extension)) {
      return 'text';
    } else {
      return 'file';
    }
  }

  /// Dosya adını al
  String getFileName(String filePath) {
    return path.basename(filePath);
  }
}

