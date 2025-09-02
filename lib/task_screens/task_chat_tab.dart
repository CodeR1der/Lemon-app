import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:task_tracker/models/chat_message.dart';
import 'package:task_tracker/services/employee_operations.dart';
import 'package:task_tracker/services/user_service.dart';
import 'package:uuid/uuid.dart';

class ChatTab extends StatefulWidget {
  final String taskId;

  const ChatTab({super.key, required this.taskId});

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> {
  final RxList<ChatMessage> _messages = <ChatMessage>[].obs;
  final TextEditingController _messageController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  RealtimeChannel? _chatChannel;
  File? _selectedFile;
  String? _selectedFileName;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _subscribeToChatUpdates();
  }

  Future<void> _loadMessages() async {
    try {
      final response = await Supabase.instance.client
          .from('chat_messages')
          .select()
          .eq('task_id', widget.taskId)
          .order('created_at', ascending: true);
      if (response.isNotEmpty) {
        _messages.assignAll(
            response.map((json) => ChatMessage.fromJson(json)).toList());
      }
    } catch (e) {
      Get.snackbar('Ошибка', 'Не удалось загрузить сообщения');
    }
  }

  void _subscribeToChatUpdates() {
    _chatChannel =
        Supabase.instance.client.channel('chat_channel_${widget.taskId}');

    Supabase.instance.client
        .channel('chat_channel_${widget.taskId}')
        .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'chat_messages',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'task_id',
        value: widget.taskId,
      ),
      callback: (payload) {
        final newData = payload.newRecord;
        final newMessage = ChatMessage.fromJson(newData);
        _messages.add(newMessage);
      },
    )
        .subscribe((status, [error]) {
      if (status == 'SUBSCRIBED') {
        print('Successfully subscribed to chat_channel_${widget.taskId}');
      } else if (error != null) {
        print('Error subscribing: $error');
      }
    });
  }

  Future<void> _sendMessage() async {
    final user = UserService.to.currentUser!;
    final message = _messageController.text.trim();
    if (message.isEmpty && _selectedFile == null) return;

    try {
      List<String> fileUrls = [];
      if (_selectedFile != null) {
        final fileUrl = await _uploadFile(_selectedFile!);
        if (fileUrl != null) fileUrls.add(fileUrl);
      }

      final newMessage = ChatMessage(
        id: const Uuid().v4(),
        taskId: widget.taskId,
        userId: user.userId,
        message: message.isNotEmpty ? message : null,
        fileUrl: fileUrls,
        fileName: _selectedFileName,
        createdAt: DateTime.now(),
      );

      final response = await Supabase.instance.client
          .from('chat_messages')
          .insert(newMessage.toJson())
          .select()
          .single();
      if (response.isNotEmpty) {
        _messageController.clear();
        setState(() {
          _selectedFile = null;
          _selectedFileName = null;
        });
      }
    } catch (e) {
      Get.snackbar('Ошибка', 'Не удалось отправить сообщение');
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedFile = File(pickedFile.path);
        _selectedFileName = pickedFile.name;
      });
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.any,
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _selectedFileName = result.files.single.name;
      });
    }
  }

  Future<String?> _uploadFile(File file) async {
    try {
      final fileExt = file.path.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      await Supabase.instance.client.storage.from('chatfiles').uploadBinary(
        fileName,
        await file.readAsBytes(),
        fileOptions: FileOptions(
          contentType: _getMimeType(file.path),
        ),
      );
      final publicUrl = Supabase.instance.client.storage
          .from('chatfiles')
          .getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      Get.snackbar('Ошибка', 'Не удалось загрузить файл');
      return null;
    }
  }

  String _getMimeType(String path) {
    final ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'zip':
        return 'application/zip';
      default:
        return 'application/octet-stream';
    }
  }

  void _removeAttachment() {
    setState(() {
      _selectedFile = null;
      _selectedFileName = null;
    });
  }

  Widget _buildFilePreview() {
    if (_selectedFile == null) return const SizedBox();

    final fileExtension = _selectedFileName?.split('.').last.toLowerCase() ?? '';
    final isImage = ['jpg', 'jpeg', 'png', 'gif'].contains(fileExtension);

    return Container(
      padding: const EdgeInsets.all(8.0),
      margin: const EdgeInsets.only(bottom: 8.0),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        children: [
          if (isImage)
            Image.file(
              _selectedFile!,
              width: 40,
              height: 40,
              fit: BoxFit.cover,
            )
          else
            Icon(
              _getFileIcon(fileExtension),
              size: 40,
              color: Colors.blue,
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _selectedFileName ?? 'Файл',
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: _removeAttachment,
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon(String extension) {
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'zip':
      case 'rar':
        return Icons.archive;
      default:
        return Icons.insert_drive_file;
    }
  }

  Widget _buildMessageAttachment(ChatMessage message) {
    if (message.fileUrl.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: message.userId == UserService.to.currentUser!.userId
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: message.fileUrl.map((url) {
        final fileExtension = url.split('.').last.toLowerCase();
        final isImage = ['jpg', 'jpeg', 'png', 'gif'].contains(fileExtension);

        if (isImage) {
          return GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => Dialog(
                  child: Image.network(url),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(top: 8),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.5,
                maxHeight: 200,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  url,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: 150,
                      height: 150,
                      color: Colors.grey[200],
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 150,
                      height: 150,
                      color: Colors.grey[200],
                      child: const Icon(Icons.error),
                    );
                  },
                ),
              ),
            ),
          );
        } else {
          return GestureDetector(
            onTap: () {
              Get.snackbar('Файл', 'Открытие файла: ${message.fileName ?? url}');
            },
            child: Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getFileIcon(fileExtension),
                    color: Colors.blue,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.3,
                    ),
                    child: Text(
                      message.fileName ?? 'Файл',
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      }).toList(),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    if (_chatChannel != null) {
      Supabase.instance.client.removeChannel(_chatChannel!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Obx(
                () => ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isCurrentUser =
                    message.userId == UserService.to.currentUser!.userId;

                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: isCurrentUser
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: isCurrentUser
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isCurrentUser)
                            FutureBuilder<Map<String, String?>>(
                              future:
                              UserService.to.getUserData(message.userId),
                              builder: (context, snapshot) {
                                final avatarUrl = snapshot.data?['avatar_url'];
                                return Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  child: CircleAvatar(
                                    radius: 16,
                                    backgroundImage: avatarUrl != null
                                        ? NetworkImage(
                                        EmployeeService().getAvatarUrl(avatarUrl))
                                        : null,
                                    child: avatarUrl == null
                                        ? const Icon(Icons.person, size: 16)
                                        : null,
                                  ),
                                );
                              },
                            ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: isCurrentUser
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                // ФИО и время в одной строке
                                FutureBuilder<Map<String, String?>>(
                                  future: UserService.to.getUserData(message.userId),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return Row(
                                        mainAxisAlignment: isCurrentUser
                                            ? MainAxisAlignment.end
                                            : MainAxisAlignment.start,
                                        children: const [
                                          Text(
                                            'Загрузка...',
                                            style: TextStyle(
                                                fontSize: 12, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      );
                                    }
                                    final userData = snapshot.data ??
                                        {'name': 'Неизвестный', 'avatar_url': null};
                                    final name = userData['name'] ?? 'Неизвестный';
                                    return Row(
                                      mainAxisAlignment: isCurrentUser
                                          ? MainAxisAlignment.end
                                          : MainAxisAlignment.start,
                                      crossAxisAlignment: CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        Text(
                                          name,
                                          style: const TextStyle(
                                              fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(width: 6), // Отступ 6 пикселей
                                        Text(
                                          message.createdAt
                                              .toLocal()
                                              .toString()
                                              .split(' ')[1]
                                              .substring(0, 5),
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(height: 4),
                                // Сообщение
                                Container(
                                  constraints: BoxConstraints(
                                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                                  ),
                                  padding: const EdgeInsets.all(12.0),
                                  decoration: BoxDecoration(
                                    color: isCurrentUser
                                        ? Colors.blue[100]
                                        : Colors.grey[200],
                                    borderRadius: BorderRadius.only(
                                      topLeft: isCurrentUser
                                          ? const Radius.circular(12.0)
                                          : const Radius.circular(0),
                                      topRight: isCurrentUser
                                          ? const Radius.circular(0)
                                          : const Radius.circular(12.0),
                                      bottomLeft: const Radius.circular(12.0),
                                      bottomRight: const Radius.circular(12.0),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: isCurrentUser
                                        ? CrossAxisAlignment.end
                                        : CrossAxisAlignment.start,
                                    children: [
                                      if (message.message != null)
                                        Text(
                                          message.message!,
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      _buildMessageAttachment(message),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isCurrentUser)
                            FutureBuilder<Map<String, String?>>(
                              future:
                              UserService.to.getUserData(message.userId),
                              builder: (context, snapshot) {
                                final avatarUrl = snapshot.data?['avatar_url'];
                                return Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  child: CircleAvatar(
                                    radius: 16,
                                    backgroundImage: avatarUrl != null
                                        ? NetworkImage(
                                        EmployeeService().getAvatarUrl(avatarUrl))
                                        : null,
                                    child: avatarUrl == null
                                        ? const Icon(Icons.person, size: 16)
                                        : null,
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(
            left: 8.0,
            right: 8.0,
            top: 8.0,
            bottom: 8.0 + MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            children: [
              _buildFilePreview(),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Iconsax.add_copy),
                    onPressed: _pickFile,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Написать сообщение',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24.0),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[200],
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10.0,
                          horizontal: 16.0,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Iconsax.camera),
                    onPressed: _pickImage,
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}