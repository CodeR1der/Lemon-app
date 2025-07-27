import 'dart:io';
import 'dart:typed_data';
import 'dart:developer';

import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

enum FileType {
  image,
  video,
  audio,
  document,
  other,
}

class FileService {
  static final FileService _instance = FileService._internal();
  factory FileService() => _instance;
  FileService._internal();

  final SupabaseClient _client = Supabase.instance.client;
  final _uuid = Uuid();

  // Определение типа файла по расширению
  FileType getFileType(String fileName) {
    final extension = path.extension(fileName).toLowerCase();
    
    switch (extension) {
      case '.jpg':
      case '.jpeg':
      case '.png':
      case '.gif':
      case '.bmp':
      case '.webp':
        return FileType.image;
      case '.mp4':
      case '.avi':
      case '.mov':
      case '.wmv':
      case '.flv':
      case '.webm':
      case '.mkv':
        return FileType.video;
      case '.mp3':
      case '.wav':
      case '.aac':
      case '.m4a':
      case '.ogg':
      case '.flac':
        return FileType.audio;
      case '.pdf':
      case '.doc':
      case '.docx':
      case '.xls':
      case '.xlsx':
      case '.ppt':
      case '.pptx':
      case '.txt':
      case '.rtf':
        return FileType.document;
      default:
        return FileType.other;
    }
  }

  // Получение MIME типа для файла
  String getMimeType(String fileName) {
    final extension = path.extension(fileName).toLowerCase();
    
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.bmp':
        return 'image/bmp';
      case '.webp':
        return 'image/webp';
      case '.mp4':
        return 'video/mp4';
      case '.avi':
        return 'video/x-msvideo';
      case '.mov':
        return 'video/quicktime';
      case '.wmv':
        return 'video/x-ms-wmv';
      case '.flv':
        return 'video/x-flv';
      case '.webm':
        return 'video/webm';
      case '.mkv':
        return 'video/x-matroska';
      case '.mp3':
        return 'audio/mpeg';
      case '.wav':
        return 'audio/wav';
      case '.aac':
        return 'audio/aac';
      case '.m4a':
        return 'audio/mp4';
      case '.ogg':
        return 'audio/ogg';
      case '.flac':
        return 'audio/flac';
      case '.pdf':
        return 'application/pdf';
      case '.doc':
        return 'application/msword';
      case '.docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case '.xls':
        return 'application/vnd.ms-excel';
      case '.xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case '.ppt':
        return 'application/vnd.ms-powerpoint';
      case '.pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case '.txt':
        return 'text/plain';
      case '.rtf':
        return 'application/rtf';
      default:
        return 'application/octet-stream';
    }
  }

  // Генерация уникального имени файла
  String generateFileName(String originalFileName, String prefix) {
    final extension = path.extension(originalFileName);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final uuid = _uuid.v4();
    return '${prefix}_${timestamp}_$uuid$extension';
  }

  // Загрузка файла в Supabase Storage
  Future<String?> uploadFile(File file, String bucketName, {String? prefix}) async {
    try {
      final fileName = generateFileName(file.path, prefix ?? 'file');
      final mimeType = getMimeType(fileName);
      
      log('Загрузка файла: $fileName в bucket: $bucketName');
      
      await _client.storage.from(bucketName).upload(
        fileName,
        file,
        fileOptions: FileOptions(
          contentType: mimeType,
          cacheControl: '3600',
          upsert: false,
        ),
      );
      
      log('Файл успешно загружен: $fileName');
      return fileName;
    } on PostgrestException catch (error) {
      log('Ошибка загрузки файла в Supabase: ${error.message}');
      return null;
    } catch (e) {
      log('Неожиданная ошибка при загрузке файла: $e');
      return null;
    }
  }

  // Загрузка нескольких файлов
  Future<List<String>> uploadFiles(List<File> files, String bucketName, {String? prefix}) async {
    final uploadedFiles = <String>[];
    
    for (final file in files) {
      final fileName = await uploadFile(file, bucketName, prefix: prefix);
      if (fileName != null) {
        uploadedFiles.add(fileName);
      }
    }
    
    return uploadedFiles;
  }

  // Загрузка файла из строки пути
  Future<String?> uploadFileFromPath(String filePath, String bucketName, {String? prefix}) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        log('Файл не существует: $filePath');
        return null;
      }
      return await uploadFile(file, bucketName, prefix: prefix);
    } catch (e) {
      log('Ошибка при загрузке файла из пути: $e');
      return null;
    }
  }

  // Загрузка нескольких файлов из путей
  Future<List<String>> uploadFilesFromPaths(List<String> filePaths, String bucketName, {String? prefix}) async {
    final uploadedFiles = <String>[];
    
    for (final filePath in filePaths) {
      final fileName = await uploadFileFromPath(filePath, bucketName, prefix: prefix);
      if (fileName != null) {
        uploadedFiles.add(fileName);
      }
    }
    
    return uploadedFiles;
  }

  // Получение публичного URL файла
  String getPublicUrl(String fileName, String bucketName) {
    try {
      return _client.storage.from(bucketName).getPublicUrl(fileName);
    } catch (e) {
      log('Ошибка при получении публичного URL: $e');
      return '';
    }
  }

  // Скачивание файла
  Future<File?> downloadFile(String fileName, String bucketName, {String? localFileName}) async {
    try {
      final url = getPublicUrl(fileName, bucketName);
      if (url.isEmpty) return null;

      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        log('Ошибка при скачивании файла: ${response.statusCode}');
        return null;
      }

      final directory = await getTemporaryDirectory();
      final localName = localFileName ?? fileName;
      final localPath = path.join(directory.path, localName);
      
      final file = File(localPath);
      await file.writeAsBytes(response.bodyBytes);
      
      log('Файл успешно скачан: $localPath');
      return file;
    } catch (e) {
      log('Ошибка при скачивании файла: $e');
      return null;
    }
  }

  // Скачивание файла как Uint8List
  Future<Uint8List?> downloadFileAsBytes(String fileName, String bucketName) async {
    try {
      final url = getPublicUrl(fileName, bucketName);
      if (url.isEmpty) return null;

      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        log('Ошибка при скачивании файла: ${response.statusCode}');
        return null;
      }

      return response.bodyBytes;
    } catch (e) {
      log('Ошибка при скачивании файла как bytes: $e');
      return null;
    }
  }

  // Удаление файла
  Future<bool> deleteFile(String fileName, String bucketName) async {
    try {
      await _client.storage.from(bucketName).remove([fileName]);
      log('Файл успешно удален: $fileName');
      return true;
    } on PostgrestException catch (error) {
      log('Ошибка при удалении файла: ${error.message}');
      return false;
    } catch (e) {
      log('Неожиданная ошибка при удалении файла: $e');
      return false;
    }
  }

  // Удаление нескольких файлов
  Future<bool> deleteFiles(List<String> fileNames, String bucketName) async {
    try {
      await _client.storage.from(bucketName).remove(fileNames);
      log('Файлы успешно удалены: ${fileNames.length} файлов');
      return true;
    } on PostgrestException catch (error) {
      log('Ошибка при удалении файлов: ${error.message}');
      return false;
    } catch (e) {
      log('Неожиданная ошибка при удалении файлов: $e');
      return false;
    }
  }

  // Проверка существования файла
  Future<bool> fileExists(String fileName, String bucketName) async {
    try {
      final response = await _client.storage.from(bucketName).list(path: path.dirname(fileName));
      final files = response.map((file) => file.name).toList();
      return files.contains(path.basename(fileName));
    } catch (e) {
      log('Ошибка при проверке существования файла: $e');
      return false;
    }
  }

  // Получение размера файла
  Future<int?> getFileSize(String fileName, String bucketName) async {
    try {
      final response = await _client.storage.from(bucketName).list(path: path.dirname(fileName));
      final file = response.firstWhere((file) => file.name == path.basename(fileName));
      return file.metadata?['size'] as int?;
    } catch (e) {
      log('Ошибка при получении размера файла: $e');
      return null;
    }
  }

  // Форматирование размера файла
  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // Создание временного файла
  Future<File> createTempFile(String fileName) async {
    final directory = await getTemporaryDirectory();
    final tempPath = path.join(directory.path, fileName);
    return File(tempPath);
  }

  // Очистка временных файлов
  Future<void> clearTempFiles() async {
    try {
      final directory = await getTemporaryDirectory();
      final files = directory.listSync();
      
      for (final file in files) {
        if (file is File) {
          await file.delete();
        }
      }
      
      log('Временные файлы очищены');
    } catch (e) {
      log('Ошибка при очистке временных файлов: $e');
    }
  }

  // Проверка доступности сети
  Future<bool> isNetworkAvailable() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  // Валидация файла
  bool validateFile(File file, {int? maxSizeInBytes, List<String>? allowedExtensions}) {
    try {
      // Проверка размера файла
      if (maxSizeInBytes != null) {
        final fileSize = file.lengthSync();
        if (fileSize > maxSizeInBytes) {
          log('Файл слишком большой: ${formatFileSize(fileSize)}');
          return false;
        }
      }

      // Проверка расширения файла
      if (allowedExtensions != null) {
        final extension = path.extension(file.path).toLowerCase();
        if (!allowedExtensions.contains(extension)) {
          log('Неподдерживаемое расширение файла: $extension');
          return false;
        }
      }

      return true;
    } catch (e) {
      log('Ошибка при валидации файла: $e');
      return false;
    }
  }
} 