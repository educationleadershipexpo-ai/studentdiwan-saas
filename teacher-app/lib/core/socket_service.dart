import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'constants.dart';
import 'api_client.dart';

class SocketService {
  static SocketService? _instance;
  IO.Socket? _socket;
  StreamController<Map<String, dynamic>>? _messageController;
  StreamController<Map<String, dynamic>>? _threadController;
  StreamController<Map<String, dynamic>>? _notificationController;
  Timer? _reconnectTimer;
  bool _isConnecting = false;
  String? _currentUserId;

  static SocketService get instance {
    _instance ??= SocketService._();
    return _instance!;
  }

  SocketService._() {
    _messageController = StreamController<Map<String, dynamic>>.broadcast();
    _threadController = StreamController<Map<String, dynamic>>.broadcast();
    _notificationController = StreamController<Map<String, dynamic>>.broadcast();
  }

  Stream<Map<String, dynamic>> get onNewMessage => _messageController!.stream;
  Stream<Map<String, dynamic>> get onThreadUpdate => _threadController!.stream;
  Stream<Map<String, dynamic>> get onNotification => _notificationController!.stream;

  bool get isConnected => _socket?.connected == true;

  Future<void> init() async {
    if (_socket?.connected == true) return;
    if (_isConnecting) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey);
    final userJson = prefs.getString(AppConstants.userKey);

    if (token == null || userJson == null) {
      debugPrint('[SocketService] No token/user found, skipping connection');
      return;
    }

    _isConnecting = true;
    _currentUserId = userJson;

    try {
      final baseUrl = AppConstants.baseUrl;
      debugPrint('[SocketService] Connecting to $baseUrl');

      _socket = IO.io(baseUrl, IO.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .enableAutoConnect()
          .setAuth({'token': token})
          .setReconnectionAttempts(5)
          .setReconnectionDelay(2000)
          .build());

      _socket!.onConnect((_) {
        debugPrint('[SocketService] Connected: ${_socket?.id}');
        _isConnecting = false;
        _joinUserRoom();
        _reconnectTimer?.cancel();
      });

      _socket!.onDisconnect((_) {
        debugPrint('[SocketService] Disconnected');
        _scheduleReconnect();
      });

      _socket!.onConnectError((data) {
        debugPrint('[SocketService] Connect error: $data');
        _isConnecting = false;
        _scheduleReconnect();
      });

      // Listen for new messages
      _socket!.on('chat_message', (data) {
        debugPrint('[SocketService] New message: $data');
        _messageController?.add(Map<String, dynamic>.from(data));
      });

      // Listen for thread updates (new thread created, thread updated)
      _socket!.on('chat_thread_update', (data) {
        debugPrint('[SocketService] Thread update: $data');
        _threadController?.add(Map<String, dynamic>.from(data));
      });

      // Listen for notifications
      _socket!.on('notification', (data) {
        debugPrint('[SocketService] Notification: $data');
        _notificationController?.add(Map<String, dynamic>.from(data));
      });

      // Listen for message read receipts
      _socket!.on('message_read', (data) {
        debugPrint('[SocketService] Message read: $data');
        _messageController?.add(Map<String, dynamic>.from(data)..['event'] = 'read_receipt');
      });

    } catch (e) {
      debugPrint('[SocketService] Init error: $e');
      _isConnecting = false;
      _scheduleReconnect();
    }
  }

  void _joinUserRoom() {
    if (_currentUserId != null) {
      _socket?.emit('join_user_room', _currentUserId);
      debugPrint('[SocketService] Joined user room: $_currentUserId');
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      debugPrint('[SocketService] Attempting reconnect...');
      init();
    });
  }

  // Emit events to server
  void sendMessage(Map<String, dynamic> messageData) {
    if (!isConnected) return;
    _socket?.emit('chat_message', messageData);
  }

  void joinThread(String threadId) {
    if (!isConnected) return;
    _socket?.emit('join_thread', threadId);
  }

  void leaveThread(String threadId) {
    if (!isConnected) return;
    _socket?.emit('leave_thread', threadId);
  }

  void markThreadRead(String threadId) {
    if (!isConnected) return;
    _socket?.emit('thread_read', {'threadId': threadId, 'userId': _currentUserId});
  }

  void typingStart(String threadId) {
    if (!isConnected) return;
    _socket?.emit('typing_start', {'threadId': threadId, 'userId': _currentUserId});
  }

  void typingStop(String threadId) {
    if (!isConnected) return;
    _socket?.emit('typing_stop', {'threadId': threadId, 'userId': _currentUserId});
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnecting = false;
  }

  void dispose() {
    disconnect();
    _messageController?.close();
    _threadController?.close();
    _notificationController?.close();
  }
}