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
  bool _isSubscribeChannel = false;

  final _userNameController = TextEditingController();
  final _channelNameController = TextEditingController();
  final _channelMessageController = TextEditingController();
  final _appidController = TextEditingController();
  final _tokenController = TextEditingController();

  late RtmClient rtmClient;

  var userId = ''; //No need to change
  var appId = ''; //------- Need DIY ----------------
  var channelName = ''; //No need to change
  var token = ''; //No need to change

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
            title: const Text('RTM 2.x - Debug'),
            backgroundColor: Colors.amber,
            foregroundColor: Colors.white,
          ),
          body: Container(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                _buildInitAndLogin(),
                _buildSubscribeChannel(),
                _buildPublishChannelMessage(),
                _buildInfoList(),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            tooltip: 'Refresh',
            onPressed: () {
              _refreshLogs();
            },
            child: const Icon(Icons.refresh),
          )),
    );
  }

  Widget _buildInitAndLogin() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Row(children: <Widget>[
          _isLogin
              ? Expanded(
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('userId: $userId'),
                    Text('appID: $appId'),
                    Text('Token: $token'),
                  ],
                ))
              : Flexible(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextField(
                          controller: _userNameController,
                          decoration: const InputDecoration(
                              hintText: 'Input uid to login ~',
                              hintStyle: TextStyle(color: Colors.grey))),
                      TextField(
                          controller: _appidController,
                          decoration: const InputDecoration(
                              hintText: 'Input APPID to Init ~',
                              hintStyle: TextStyle(color: Colors.grey))),
                      TextField(
                          controller: _tokenController,
                          decoration: const InputDecoration(
                              hintText: 'Input Token to login ~',
                              hintStyle: TextStyle(color: Colors.grey))),
                    ],
                  ),
                ),
          IconButton(
            tooltip: 'Login',
            icon: Icon(
              _isLogin ? Icons.logout_rounded : Icons.login_rounded,
              color: _isLogin ? Colors.red : Colors.green,
            ),
            onPressed:
                (_isLogin ? _toggleLogoutAndRelease : _toggleInitandLogin),
          )
        ]),
      ),
    );
  }

  Widget _buildSubscribeChannel() {
    if (!_isLogin) {
      return Container();
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Row(children: <Widget>[
          !_isSubscribeChannel
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
            tooltip: 'Subscrbie',
            onPressed: _isSubscribeChannel
                ? _togglelUnsubscribeChannel
                : _togglelSubscribeChannel,
            icon: Icon(
              _isSubscribeChannel ? Icons.remove_circle : Icons.add_alert,
              color: _isSubscribeChannel ? Colors.red : Colors.green,
            ),
          )
        ]),
      ),
    );
  }

  Widget _buildPublishChannelMessage() {
    if (!_isLogin || !_isSubscribeChannel) {
      return Container();
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Row(children: <Widget>[
          Expanded(
              child: TextField(
                  controller: _channelMessageController,
                  decoration: const InputDecoration(
                      hintText: 'Input channel message',
                      hintStyle: TextStyle(color: Colors.grey)))),
          IconButton(
            tooltip: 'Publish',
            onPressed: _publishChannelMessage,
            icon: const Icon(
              Icons.send,
              color: Colors.blue,
            ),
          )
        ]),
      ),
    );
  }

  Widget _buildInfoList() {
    return Flexible(
      child: ListView.builder(
        itemBuilder: (context, i) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 5.0),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.orange, width: 2.0),
              borderRadius: BorderRadius.circular(8.0),
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
    appId = _appidController.text;
    token = _tokenController.text;
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
        _log('🎉 Initialize success! 🎉');
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
      var (status, response) =
          await rtmClient.login(token.isEmpty ? appId : token);
      if (status.error == true) {
        _log(
            '${status.operation} failed due to ${status.reason}, error code: ${status.errorCode}, response: $response');
      } else {
        _log('🎉 login RTM success! 🎉');
        setState(() {
          _isLogin = true;
        });
      }
    } catch (e) {
      _log('Failed to login: $e');
    }
  }
//----------------------------------------------------------------

  void _toggleLogoutAndRelease() async {
    var (status, response) = await rtmClient.logout();
    var releaseStatus = await rtmClient.release();

    if (status.error == true || releaseStatus.error == true) {
      _log(status.reason);
      _log(
          '${status.operation} failed due to ${status.reason}, error code: ${status.errorCode}, response: $response');
      _log(
          '${releaseStatus.operation} failed due to ${releaseStatus.reason}, error code: ${releaseStatus.errorCode}');
    } else {
      _log('👋🏻 Logout success! 👋🏻');
      _log('👋🏻 Release success! 👋🏻');
      setState(() {
        _isLogin = false;
        _isSubscribeChannel = false;
      });
    }
  }

  void _togglelSubscribeChannel() async {
    try {
      channelName = _channelNameController.text;
      var (status, response) = await rtmClient.subscribe(channelName);
      if (status.error == true) {
        _log(
            '${status.operation} failed due to ${status.reason}, error code: ${status.errorCode}, response: $response');
      } else {
        _log('🔔 subscribe channel: $channelName success! 🔔');
        _channelNameController.clear();
        setState(() {
          _isSubscribeChannel = true;
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
        _log('🚫 Unsubscribe channel: $channelName success! 🚫');
        setState(() {
          _isSubscribeChannel = false;
        });
      }
    } catch (e) {
      _log('Failed to Unsubscribe channel: $e');
    }
  }

  void _publishChannelMessage() async {
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
            '✉️ ${status.operation} send success! Message: ${_channelMessageController.text} ✉️');
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
