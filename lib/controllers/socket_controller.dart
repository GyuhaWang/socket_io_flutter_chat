import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart';
import 'package:socketchat/models/events.dart';
import 'package:socketchat/models/subscription_models.dart';

const String kLocalhost = 'http://localhost:3000';

String enumToString(_enum) {
  return _enum.toString().split(".").last;
}

class NotConnected implements Exception {}

class NotSubscribed implements Exception {}

enum INEvent {
  newUserToChatRoom,
  userLeftChatRoom,
  updateChat,
  typing,
  stopTyping,
}

enum OUTEvent {
  subscribe,
  unsubscribe,
  newMessage,
  typing,
  stopTyping,
}

typedef DynamicCallback = void Function(dynamic data);

class SocketState {
  // 소켓 연결 여부
  final bool connected;
  // 방 참가 여부
  final Subscription? subscription;
  final List<ChatEvent>? events;

  SocketState({
    this.connected = false,
    this.subscription,
    this.events,
  });

  SocketState copyWith({
    bool? connected,
    Subscription? subscription,
    List<ChatEvent>? events,
  }) {
    return SocketState(
      connected: connected ?? this.connected,
      subscription: subscription ?? this.subscription,
      events: events ?? this.events,
    );
  }
}

class SocketController extends StateNotifier<SocketState> {
  Socket? _socket;
  StreamController<List<ChatEvent>>? _newMessagesController;
  List<ChatEvent>? _events;

  SocketController() : super(SocketState());

  Stream<List<ChatEvent>>? get watchEvents =>
      _newMessagesController?.stream.asBroadcastStream();
  // socket 생성
  void init({String? url}) {
    print('socketController init이 실행됩니다.');
    _socket ??= io(
      url ?? _localhost,
      OptionBuilder().setTransports(['websocket']).disableAutoConnect().build(),
    );
    _newMessagesController ??= StreamController<List<ChatEvent>>.broadcast();
    _events = [];
  }

  // socket 연결
  Socket connect(
      {DynamicCallback? onConnectionError, VoidCallback? connected}) {
    // assertion 으로 init 디버깅 확인
    assert(_socket != null, "Did you forget to call `init()` first?");

    final _socketS = _socket!.connect();
    // socket 연결을 리턴
    _socket!.onConnect((_) {
      // 상태 연결로 변경
      state = state.copyWith(connected: true);
      // 연결이 완료되면 이벤트 리스너 생성
      _initListeners();
      // callback이 있다면 실행
      connected?.call();
      log("socket에 연결되었습니다:$_socket,$state");
    });
    // 에러가 있다면 에러 리턴
    _socket!.onConnectError((data) =>
        {print('socket 연결에 실패하였습니다:$data'), onConnectionError?.call(data)});
    return _socketS;
  }

  Socket disconnect({VoidCallback? disconnected}) {
    final _socketS = _socket!.disconnect();
    _socket!.onDisconnect((_) {
      disconnected?.call();
      state = state.copyWith(connected: false);
      log("Disconnected");
    });
    return _socketS;
  }

  void _initListeners() {
    // 소켓이 연결되어있는지 확인
    _connectedAssetion();
    final _socket = this._socket!;

    // 방 참가
    _socket.on(enumToString(INEvent.newUserToChatRoom), (data) {
      final _user = ChatUser.fromMap(data, chatUserEvent: ChatUserEvent.joined);
      _newUserEvent(_user);
    });

    _socket.on(enumToString(INEvent.userLeftChatRoom), (data) {
      final _user = ChatUser.fromMap(data, chatUserEvent: ChatUserEvent.left);
      _newUserEvent(_user);
    });

    _socket.on(enumToString(INEvent.updateChat), (response) {
      final _message = Message.fromJson(response);
      _addNewMessage(_message);
    });

    _socket.on(enumToString(INEvent.typing), (_) {
      _addTypingEvent(UserStartedTyping());
    });

    _socket.on(enumToString(INEvent.stopTyping), (_) {
      _addTypingEvent(UserStoppedTyping());
    });
  }

  void _connectedAssetion() {
    assert(this._socket != null, "Did you forget to call `init()` first?");
    if (state.connected == false) throw NotConnected();
  }

  /// 방 참가를 위한 구독
  void subscribe(Subscription subscription, {VoidCallback? onSubscribe}) {
    _connectedAssetion();
    final _socket = this._socket!;
    // subscribe 리스너 , roomName, userName 전달
    _socket.emit(
      enumToString(OUTEvent.subscribe),
      subscription.toMap(),
    );
    // 구독 상태 변경
    state = state.copyWith(subscription: subscription);
    onSubscribe?.call();
    log("Subscribed to ${subscription.roomName}");
  }

  ///방 나가기
  void unsubscribe({VoidCallback? onUnsubscribe}) {
    _connectedAssetion();
    if (state.subscription == null) return;

    final _socket = this._socket!;
    // stop typing 설정, 방 나가기
    _socket
      ..emit(
        enumToString(OUTEvent.stopTyping),
        state.subscription!.roomName,
      )
      ..emit(
        enumToString(OUTEvent.unsubscribe),
        state.subscription!.toMap(),
      );

    final _roomName = state.subscription!.roomName;

    onUnsubscribe?.call();
    state = state.copyWith(subscription: null);
    _events?.clear();
    log("UnSubscribed from $_roomName");
  }

  /// 메세지 보내기
  void sendMessage(Message message) {
    _connectedAssetion();
    if (state.subscription == null) throw NotSubscribed();
    final _socket = this._socket!;

    final _message = message.copyWith(
      userName: state.subscription!.userName,
      roomName: state.subscription!.roomName,
    );

    _socket
      ..emit(
        enumToString(OUTEvent.stopTyping),
        state.subscription!.roomName,
      )
      ..emit(
        enumToString(OUTEvent.newMessage),
        _message.toMap(),
      );

    _addNewMessage(_message);
  }

  void typing() {
    _connectedAssetion();
    if (state.subscription == null) throw NotSubscribed();
    final _socket = this._socket!;
    // 누가 작성중인지는 안보내줘도 되는건가??
    _socket.emit(enumToString(OUTEvent.typing), state.subscription!.roomName);
  }

  void stopTyping() {
    _connectedAssetion();
    if (state.subscription == null) throw NotSubscribed();
    final _socket = this._socket!;
    _socket.emit(
        enumToString(OUTEvent.stopTyping), state.subscription!.roomName);
  }

  void _addNewMessage(Message message) {
    _addEvent(message);
  }

  void _newUserEvent(ChatUser user) {
    _addEvent(user);
  }

  void _addTypingEvent(UserTyping event) {
    _events!.removeWhere((e) => e is UserTyping);
    _events = <ChatEvent>[event, ..._events!];
    _newMessagesController?.sink.add(_events!);
  }

  /// Add new event to the stream sink
  void _addEvent(event) {
    _events = <ChatEvent>[event, ..._events!];
    // 컨트롤러에 메시지 추가
    _newMessagesController?.sink.add(_events!);
  }

  String get _localhost {
    final _uri = Uri.parse(kLocalhost);

    if (Platform.isIOS) return kLocalhost;

    // Android local url
    return '${_uri.scheme}://10.0.2.2:${_uri.port}';
  }
}

final socketControllerProvider =
    StateNotifierProvider<SocketController, SocketState>((ref) {
  print('socketControllerProvider가 실행중입니다');
  return SocketController();
});
