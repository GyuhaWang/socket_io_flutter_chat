import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:socketchat/controllers/socket_controller.dart';
import 'package:socketchat/models/subscription_models.dart';
import 'package:socketchat/variables.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final TextEditingController _userNameEditingController;
  late final TextEditingController _roomEditingController;
  @override
  void initState() {
    print('페이지 initState');
    _userNameEditingController = TextEditingController();
    _roomEditingController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('이 부분은 레이아웃 이후에 실행됩니다');

      final socketController = ref.read(socketControllerProvider.notifier);
      socketController
        ..init(url: ipAddress)
        ..connect();
    });
    super.initState();
  }

  @override
  void dispose() {
    _userNameEditingController.dispose();
    _roomEditingController.dispose();
    WidgetsBinding.instance?.addPostFrameCallback(
        (_) => ref.read(socketControllerProvider.notifier).dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final socketController = ref.read(socketControllerProvider.notifier);
    return Scaffold(
      backgroundColor: Colors.indigo[50],
      appBar: AppBar(
        backgroundColor: Colors.indigo[50],
        title: const Text(
          "Socket IO 채팅방",
          style: TextStyle(fontSize: 14),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 12, right: 12, bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _userNameEditingController,
                decoration: InputDecoration(
                  hintText: "닉네임을 입력해주세요",
                  labelText: '닉네임',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25.0),
                    borderSide: BorderSide(),
                  ),
                ),
              ),
              const SizedBox(
                height: 40,
              ),
              TextFormField(
                controller: _roomEditingController,
                decoration: InputDecoration(
                  hintText: "방 이름을 입력해주세요",
                  labelText: '방 이름',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25.0),
                    borderSide: BorderSide(),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 30),
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo[100]),
                    onPressed: () {
                      var subscription = Subscription(
                        roomName: _roomEditingController.text,
                        userName: _userNameEditingController.text,
                      );

                      socketController.subscribe(
                        subscription,
                        onSubscribe: () {
                          context.go('/chat');
                        },
                      );
                    },
                    child: const Text(
                      "입장하기",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
