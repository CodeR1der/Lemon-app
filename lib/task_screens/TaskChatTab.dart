import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:task_tracker/models/chat_message.dart';
import 'package:task_tracker/services/user_service.dart';
import 'package:uuid/uuid.dart';

import '../services/employee_operations.dart';

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
        _messages.assignAll(response
            .map((json) => ChatMessage.fromJson(json))
            .toList());
      }
    } catch (e) {
      Get.snackbar('Ошибка', 'Не удалось загрузить сообщения: $e');
    }
  }

  void _subscribeToChatUpdates() {
    _chatChannel = Supabase.instance.client.channel('chat_channel_${widget.taskId}');

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
        });
      }
    } catch (e) {
      Get.snackbar('Ошибка', 'Не удалось отправить сообщение: $e');
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _selectedFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickFile() async {
    final pickedFile = await _picker.pickMedia();
    if (pickedFile != null) {
      setState(() {
        _selectedFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadFile(File file) async {
    try {
      final fileExt = file.path.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      await Supabase.instance.client.storage
          .from('chatfiles')
          .uploadBinary(
        fileName,
        await file.readAsBytes(),
        fileOptions: const FileOptions(contentType: 'image/jpeg'),
      );
      final publicUrl = Supabase.instance.client.storage
          .from('chatfiles')
          .getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      Get.snackbar('Ошибка', 'Не удалось загрузить файл: $e');
      return null;
    }
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
                final isCurrentUser = message.userId == UserService.to.currentUser!.userId;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  child: Column(
                    crossAxisAlignment:
                    isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      // Display the name above the message
                      FutureBuilder<Map<String, String?>>(
                        future: UserService.to.getUserData(message.userId),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Text(
                              'Загрузка...',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            );
                          }
                          final userData = snapshot.data ?? {'name': 'Неизвестный', 'avatar_url': null};
                          final name = userData['name'] ?? 'Неизвестный';
                          return Text(
                            name,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          );
                        },
                      ),
                      const SizedBox(height: 4),
                      // Display message with avatar
                      Row(
                        mainAxisAlignment:
                        isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (!isCurrentUser) ...[
                            // Avatar on the left for other users
                            FutureBuilder<Map<String, String?>>(
                              future: UserService.to.getUserData(message.userId),
                              builder: (context, snapshot) {
                                final avatarUrl = snapshot.data?['avatar_url'];
                                return CircleAvatar(
                                  radius: 16,
                                  backgroundImage:
                                  avatarUrl != null ? NetworkImage(EmployeeService().getAvatarUrl(avatarUrl)) : null,
                                  child: avatarUrl == null
                                      ? const Icon(Icons.person, size: 16)
                                      : null,
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Container(
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.7,
                              ),
                              padding: const EdgeInsets.all(12.0),
                              decoration: BoxDecoration(
                                color: isCurrentUser ? Colors.blue[100] : Colors.grey[200],
                                borderRadius: BorderRadius.circular(12.0),
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
                                  if (message.fileUrl.isNotEmpty)
                                    Column(
                                      crossAxisAlignment: isCurrentUser
                                          ? CrossAxisAlignment.end
                                          : CrossAxisAlignment.start,
                                      children: message.fileUrl.map((url) {
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 8.0),
                                          child: Image.network(
                                            url,
                                            width: 200,
                                            height: 200,
                                            fit: BoxFit.cover,
                                          ),
                                        );
                                      }).toList(),
                                    ),
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
                              ),
                            ),
                          ),
                          if (isCurrentUser) ...[
                            const SizedBox(width: 8),
                            // Avatar on the right for current user
                            FutureBuilder<Map<String, String?>>(
                              future: UserService.to.getUserData(message.userId),
                              builder: (context, snapshot) {
                                final avatarUrl = snapshot.data?['avatar_url'];
                                return CircleAvatar(
                                  radius: 16,
                                  backgroundImage:
                                  avatarUrl != null ? NetworkImage(EmployeeService().getAvatarUrl(avatarUrl)) : null,
                                  child: avatarUrl == null
                                      ? const Icon(Icons.person, size: 16)
                                      : null,
                                );
                              },
                            ),
                          ],
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
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              if (_selectedFile != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Icon(Icons.attach_file, color: Colors.grey[600]),
                ),
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Написать сообщение...',
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
                icon: const Icon(Icons.camera_alt),
                onPressed: _pickImage,
              ),
              IconButton(
                icon: const Icon(Icons.attach_file),
                onPressed: _pickFile,
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: () => _sendMessage(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}