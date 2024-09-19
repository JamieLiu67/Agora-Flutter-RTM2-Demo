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

  var userId = 'JamieLiu'; //No need to change
  var appId =
      'Your own appid with RTM service'; //-------Need DIY ----------------
  var channelName = 'lsq123'; //No need to change

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
                _buildInitAndLogin(),
                _buildSubscribeChannel(),
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

  Widget _buildInitAndLogin() {
    return Row(children: <Widget>[
      _isLogin
          ? Expanded(
              child: Text(
              'userId: ${_userNameController.text}',
            ))
          : Flexible(
              child: TextField(
                  controller: _userNameController,
                  decoration: const InputDecoration(
                      hintText: 'Input uid to login ~',
                      hintStyle: TextStyle(color: Colors.grey))),
            ),
      IconButton(
        icon: Icon(
          _isLogin ? Icons.logout_outlined : Icons.login_sharp,
          color: _isLogin ? Colors.red : Colors.green, // 根据_isLogin设置颜色
        ),
        onPressed: (_isLogin ? _toggleLogout : _toggleInitandLogin),
      )
    ]);
  }

  Widget _buildSubscribeChannel() {
    if (!_isLogin) {
      return Container();
    }
    return Row(children: <Widget>[
      !_isListenChannel
          ? Expanded(
              child: TextField(
                  controller: _channelNameController,
                  decoration: const InputDecoration(
                      hintText: 'Input channel id',
                      hintStyle: TextStyle(color: Colors.grey))))
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
              decoration: const InputDecoration(
                  hintText: 'Input channel message',
                  hintStyle: TextStyle(color: Colors.grey)))),
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
//------------------------------Init part---------------------------
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
    } catch (e) {
      _log('Initialize falid!:$e');
    }

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
//-----------------------------------------------------------------

//-----------------------------Login part---------------------------
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
//----------------------------------------------------------------

  void _toggleLogout() async {
    var (status, response) = await rtmClient.logout();
    var releaseStatus = await rtmClient.release();

    if (status.error == true || releaseStatus.error == true) {
      _log(status.reason);
      _log(
          '${status.operation} failed due to ${status.reason}, error code: ${status.errorCode}, response: $response');
    } else {
      _log('Logout success!');
      _log('Release success!');
      setState(() {
        _isLogin = false;
        _isListenChannel = false;
      });
    }
  }

  void _togglelSubscribeChannel() async {
    try {
      // subscribe channel
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
