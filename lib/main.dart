import 'package:agora_rtm/agora_rtm.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  bool _isLogin = false;
  bool _isListenChannel = false;

  final _userNameController = TextEditingController();
  final _channelNameController = TextEditingController();
  final _channelMessageController = TextEditingController();

  late RtmClient rtmClient;

  var userId = 'JamieLiu';
  var appId = 'Your own appid with RTM service';
  var channelName = 'lsq123';

  final _infoStrings = <String>[];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    rtmClient.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(
            title: const Text('RTM 2.x'),
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
          ),
          body: Container(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                _buildLogin(),
                _buildListenChannel(),
                _buildSendChannelMessage(),
                _buildInfoList(),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              _refreshLogs();
            },
            child: const Icon(Icons.refresh),
          )),
    );
  }

  void _createClient() async {}

  Widget _buildLogin() {
    return Row(children: <Widget>[
      _isLogin
          ? Expanded(
              child: Text(
              'userId: ${_userNameController.text}',
            ))
          : Flexible(
              child: TextField(
                  controller: _userNameController,
                  decoration: const InputDecoration(hintText: 'uid'))),
      IconButton(
        icon: Icon(_isLogin ? Icons.logout_outlined : Icons.login_sharp),
        onPressed: (_isLogin ? _toggleLogout : _toggleInitandLogin),
      )
    ]);
  }

  Widget _buildListenChannel() {
    if (!_isLogin) {
      return Container();
    }
    return Row(children: <Widget>[
      !_isListenChannel
          ? Expanded(
              child: TextField(
                  controller: _channelNameController,
                  decoration:
                      const InputDecoration(hintText: 'Input channel id')))
          : Expanded(
              child: Text(
              'Channel: $channelName',
            )),
      IconButton(
        onPressed: _isListenChannel
            ? _togglelUnsubscribeChannel
            : _togglelSubscribeChannel,
        icon: Icon(_isListenChannel
            ? Icons.group_off_outlined
            : Icons.group_add_outlined),
      )
    ]);
  }

  Widget _buildSendChannelMessage() {
    if (!_isLogin || !_isListenChannel) {
      return Container();
    }
    return Row(children: <Widget>[
      Expanded(
          child: TextField(
              controller: _channelMessageController,
              decoration:
                  const InputDecoration(hintText: 'Input channel message'))),
      IconButton(
        onPressed: _sendChannelMessage,
        icon: const Icon(Icons.send),
      )
    ]);
  }

  Widget _buildInfoList() {
    return Flexible(
      child: ListView.builder(
        itemBuilder: (context, i) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 5.0), // 设置上下间距
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blue, width: 2.0), // 设置边框颜色和宽度
              borderRadius: BorderRadius.circular(8.0), // 可选：设置圆角
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(5.0),
              title: Text(_infoStrings[i]),
            ),
          );
        },
        itemCount: _infoStrings.length,
      ),
    );
  }

  void _toggleInitandLogin() async {
    WidgetsFlutterBinding.ensureInitialized();
    userId = _userNameController.text;
    //create rtm instance
    try {
      // create rtm client
      final (status, client) = await RTM(appId, userId,
          config: const RtmConfig(
              logConfig: RtmLogConfig(level: RtmLogLevel.info)));
      if (status.error == true) {
        _log(
            '${status.operation} failed due to ${status.reason}, error code: ${status.errorCode}');
      } else {
        rtmClient = client;
        _log('Initialize success!');
      }
      // add events listner
    } catch (e) {
      _log('Initialize falid!:$e');
    }

    // Paste the following code snippet below "add event listener" comment
    rtmClient.addListener(
        // add message event handler
        message: (event) {
      _log(
          'recieved a message from channel: ${event.channelName}, channel type : ${event.channelType}');
      _log(
          'message content: ${utf8.decode(event.message!)}, custome type: ${event.customType}');
    },
        // add link state event handler
        linkState: (event) {
      _log(
          'link state changed from ${event.previousState} to ${event.currentState}');
      _log('reason: ${event.reason}, due to operation ${event.operation}');
    });
    // Paste the following code snippet below "login rtm service" comment
    try {
      // login rtm service
      var (status, response) = await rtmClient.login(appId);
      if (status.error == true) {
        _log(
            '${status.operation} failed due to ${status.reason}, error code: ${status.errorCode}, response: $response');
      } else {
        _log('login RTM success!');
        setState(() {
          _isLogin = true;
        });
      }
    } catch (e) {
      _log('Failed to login: $e');
    }
  }

  void _toggleLogout() async {
    var (status, response) = await rtmClient.logout();
    if (status.error == true) {
      _log(status.reason);
    } else {
      _log(response.toString());
      setState(() {
        _isLogin = false;
      });
    }
  }

  void _togglelSubscribeChannel() async {
    // Paste the following code snippet below "subscribe to a channel" comment
    try {
      // subscribe to 'getting-started' channel
      channelName = _channelNameController.text;
      var (status, response) = await rtmClient.subscribe(channelName);
      if (status.error == true) {
        _log(
            '${status.operation} failed due to ${status.reason}, error code: ${status.errorCode}, response: $response');
      } else {
        _log('subscribe channel: $channelName success!');
        _channelNameController.clear();
        setState(() {
          _isListenChannel = true;
        });
      }
    } catch (e) {
      _log('Failed to subscribe channel: $e');
    }
  }

  void _togglelUnsubscribeChannel() async {
    try {
      var (status, response) = await rtmClient.unsubscribe(channelName);
      if (status.error == true) {
        _log(
            '${status.operation} failed due to ${status.reason}, error code: ${status.errorCode}, response: $response');
      } else {
        _log('Unsubscribe channel: $channelName success!');
        setState(() {
          _isListenChannel = false;
        });
      }
    } catch (e) {
      _log('Failed to Unsubscribe channel: $e');
    }
  }

  void _sendChannelMessage() async {
    // Paste the following code snippet below "Publish a message" comment
// Send a message every second for 100 seconds

    try {
      var (status, response) = await rtmClient.publish(
        channelName,
        _channelMessageController.text,
        channelType: RtmChannelType.message,
        customType: 'PlainText',
      );
      if (status.error == true) {
        _log(
            '${status.operation} failed due to ${status.reason}, error code: ${status.errorCode}, response: $response');
      } else {
        _log(
            '${status.operation} send success! Message: ${_channelMessageController.text}');
        _channelMessageController.clear();
      }
    } catch (e) {
      _log('Failed to publish message: $e');
    }
  }

  void _log(String info) {
    debugPrint(info);
    setState(() {
      _infoStrings.insert(0, info);
    });
  }

  void _refreshLogs() {
    setState(() {
      _infoStrings.clear();
    });
  }
}
