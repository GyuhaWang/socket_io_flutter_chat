// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:flutter/scheduler.dart';
// import 'package:go_router/go_router.dart';
// import 'package:socketchat/utils/socket.dart';

// class ChatScreen extends StatefulWidget {
//   const ChatScreen({super.key});

//   @override
//   State<ChatScreen> createState() => _ChatScreenState();
// }

// class _ChatScreenState extends State<ChatScreen> {
//   final _socketResponse = StreamController<String>();
//   final chatList = <String>[];
//   final scrollController = ScrollController();

//   @override
//   void initState() {
//     print(SocketIOManager.instance.socket.connected);
//     SocketIOManager.instance.socket.on('chat message', (data) {
//       print('chat room data$data');
//     });
//     super.initState();
//   }

//   @override
//   void dispose() {
//     _socketResponse.close();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     // SchedulerBinding.instance.addPostFrameCallback((_) {
//     //   scrollController.animateTo(
//     //     0,
//     //     duration: const Duration(milliseconds: 100),
//     //     curve: Curves.linear,
//     //   );
//     // });
//     return Scaffold(
//         appBar: AppBar(
//           leading: IconButton(
//               onPressed: () => {context.pop()}, icon: Icon(Icons.arrow_back)),
//           title: Text('채팅방'),
//         ),
//         body: Container());
//   }
// }
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socketchat/Widget/chat_bubble.dart';
import 'package:socketchat/controllers/socket_controller.dart';
import 'package:socketchat/models/events.dart';
import 'package:go_router/go_router.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  late final SocketController? _socketController;
  late final TextEditingController _textEditingController;
  bool _isTextFieldHasContentYet = false;
  @override
  void initState() {
    _textEditingController = TextEditingController();
    _socketController = ref.read(socketControllerProvider.notifier);
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      _textEditingController.addListener(() {
        final _text = _textEditingController.text.trim();
        if (_text.isEmpty) {
          _socketController!.stopTyping();
          _isTextFieldHasContentYet = false;
        } else {
          if (_isTextFieldHasContentYet) return;
          _socketController!.typing();
          _isTextFieldHasContentYet = true;
        }
      });

      // 다시 build 이후를 호출하게함
      setState(() {});
    });
    super.initState();
  }

  @override
  void dispose() {
    // _socketController?.unsubscribe();
    _textEditingController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_textEditingController.text.isEmpty) return;
    final _message = Message(messageContent: _textEditingController.text);
    ref.read(socketControllerProvider.notifier)?.sendMessage(_message);
    _textEditingController.clear();
  }

  @override
  Widget build(BuildContext context) {
    SocketState socketState = ref.watch(socketControllerProvider);
    return PopScope(
        child: GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.indigo[50],
        appBar: AppBar(
          backgroundColor: Colors.indigo[50],
          shape: const Border(
            bottom: BorderSide(
              color: Colors.grey,
              width: 1,
            ),
          ),
          centerTitle: true,
          title: Text(socketState?.subscription?.roomName ?? "-"),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                _socketController!.unsubscribe();
                context.pop();
              },
            )
          ],
        ),
        body: SafeArea(
            child: Stack(
          children: [
            Positioned.fill(
                child: StreamBuilder<List<ChatEvent>>(
                    stream: _socketController?.watchEvents,
                    initialData: [],
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                            child: CircularProgressIndicator.adaptive());
                      }
                      final _events = snapshot.data!;
                      if (_events.isEmpty) {
                        return Center(
                            child: Text(
                                '${socketState?.subscription?.roomName ?? '_'}에 입장하였습니다.'));
                      }
                      return ListView.separated(
                        reverse: true,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 20.0).add(
                          const EdgeInsets.only(bottom: 70.0),
                        ),
                        itemCount: _events.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 5.0),
                        itemBuilder: (context, index) {
                          final _event = _events[index];
                          if (_event is Message) {
                            if (_event.userName ==
                                socketState?.subscription?.userName) {
                              return TextBubble(
                                  message: _event, type: BubbleType.sendBubble);
                            } else {
                              return TextBubble(
                                  message: _event,
                                  type: BubbleType.receiverBubble);
                            }
                          } else if (_event is ChatUser) {
                            if (_event.userEvent == ChatUserEvent.left) {
                              return Center(
                                  child: Text("${_event.userName}가 퇴장하였습니다."));
                            }

                            return Center(
                                child: Text("${_event.userName}가 입장하였습니다."));
                          } else if (_event is UserStartedTyping) {
                            return UserTypingBubble();
                          }
                          return const SizedBox();
                        },
                      );
                    })),
            Positioned.fill(
              top: null,
              bottom: 0,
              child: Container(
                color: Colors.white,
                child: Row(
                  children: [
                    SizedBox(width: 20),
                    Expanded(
                      child: TextField(
                        controller: _textEditingController,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    SizedBox(width: 10),
                    IconButton(
                      onPressed: () => _sendMessage(),
                      icon: Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            )
          ],
        )),
      ),
    ));
  }
}
