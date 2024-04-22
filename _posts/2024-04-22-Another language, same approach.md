---
layout: post
comments: true
title: "Another language, same approach"
categories: article
tags: [socket, dart, networking, IO]
excerpt_separator: <!--more-->
comments_id: 104

author:
- kyryl horbushko
- Kyiv
- 🇺🇦 Ukraine 🇺🇦
---

Exchange and process data - is an essential part of any modern application. U can't achieve results without data. Sometimes data can be produced or obtained from remote sources.
<!--more-->

Often we want to have a kind of "real-time" communication with the source. To achieve this we may want to use [sockets](https://en.wikipedia.org/wiki/Network_socket). And [Flutter](https://flutter.dev) is not the exception.

> some time ago I wrote [article]({% post_url 2022-01-09-sockets %}) about sockets on iOS and macOS.

A good moment here, is that even if u change platform - approach is almoust same. Let's look at sockets on Flutter.

## Sockets in Flutter

[Dart](https://dart.dev) is a very handy and easy-to-learn language, and the Flutter platform provides us with a lot of ready-baked solutions. One of them is [IO lib](https://api.dart.dev/stable/3.3.4/dart-io/dart-io-library.html) which helps us to use HTTP, sockets, stream, and other communications channels.

As mentioned in the documentation:

> This library allows you to work with files, directories, sockets, processes, HTTP servers clients, and more. Many operations related to input and output are asynchronous and are handled using Futures or Streams, both of which are defined in the dart:async library.

So, this is a perfect match for a socket-based connection. 
We want to use [Socket](https://api.dart.dev/stable/3.3.4/dart-io/Socket-class.html) type for this operations:

> Do not mismatch [WebSocket](https://api.dart.dev/stable/3.3.4/dart-io/WebSocket-class.html) and [Socket](https://api.dart.dev/stable/3.3.4/dart-io/Socket-class.html) based connections.


```dart
Socket.connect(
        BTEndpoint.BT_SERVER_IP, BTEndpoint.BT_SERVER_PORT)
    .then((Socket sock) {
  _socket = sock;
  _socket.listen(
  _dataHandler,
      onError: _errorHandler, 
      onDone: _doneHandler, 
      cancelOnError: false
      );
      
}).catchError((Object e) {
  print("Socket - unable to connect due to $e");
});
```

That's the base connection. 

To send a message:

```dart
final raw = utf8.encode(request);
_socket.add(raw);
```

And when u done:

```dart
_socket.close();
_socket.destroy();
```

Create, use, cleanup. Done.

Combining all together:

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

enum ConnectionStatus {
  unknown,
  connected,
  disconnected,
}

class ApiClient {
  // store and propagate outside connection state
  final _connectionMonitorController = StreamController<ConnectionStatus>();

  // internal use for
  // create some specific type for response - BTResponse in this case
  final _communicatinController = StreamController<BTResponse>.broadcast();
  
  late Socket _socket;
  BTRequest? _lastRequest;

  Stream<ConnectionStatus> get status async* {
    await Future<void>.delayed(const Duration(seconds: 1));
    yield ConnectionStatus.unknown;
    yield* _connectionMonitorController.stream;
  }

  void dispose() {
    _socket.destroy();
    _connectionMonitorController.close();
  }

  void connect() {
    Socket.connect(
            BTEndpoint.BT_SERVER_IP, BTEndpoint.BT_SERVER_PORT)
        .then((Socket sock) {
      _socket = sock;
      _socket.listen(
      _dataHandler,
          onError: _errorHandler, 
          onDone: _doneHandler, 
          cancelOnError: false);
      _connectionMonitorController.add(ConnectionStatus.connected);
    }).catchError((Object e) {
      print("Socket - unable to connect due to $e");
      _connectionMonitorController.addError(e);
      _connectionMonitorController.add(ConnectionStatus.disconnected);
    });
  }

  void _dataHandler(data) {
    final message = String.fromCharCodes(data).trim();
    print('Socket response - $message');

    final response = BTResponse(data, _lastRequest);
    _lastRequest = null;
    _communicatinController.add(response);
  }

  void _errorHandler(error, StackTrace trace) {
    print('Socket error - $error, $trace');
    _communicatinController.addError(error, trace);
  }

  void _doneHandler() {
    _socket.destroy();
    
    _connectionMonitorController.add(ConnectionStatus.disconnected);
  }

  Future<BTResponse> sendCommand(BTRequest request) async {
    this._lastRequest = request;
    final raw = utf8.encode(request.commandRawValue);
    _socket.add(raw);
    print('Socket request - ${request.commandRawValue}');

    final response = await _communicatinController.stream
      .firstWhere((element) => element.id == request.id)
      .timeout(
        Duration(seconds: 1), 
        onTimeout: () {
          final timeoutResponse = BTResponse.timeout(request);
          return timeoutResponse;
      })
      .onError((error, stackTrace) {
        return BTCommunicationError(request, error, stackTrace);
      });

    return response;
  }

  void disconnect() {
    _socket.close();
    _socket.destroy();

    _connectionMonitorController.add(ConnectionStatus.disconnected);
  }
}
```

Few lines of code allow us to have a real-time connection. 

## Conclusion

If u compare the iOS platform and how this can be done in Swift with the current implementation for Flutter in dart - u can see, that everything is the same, the difference is just a language, so syntax.

Learn once, use everywhere. 

## Resources

- [Network socket](https://en.wikipedia.org/wiki/Network_socket)
- [IO lib](https://api.dart.dev/stable/3.3.4/dart-io/dart-io-library.html)
- [Dart](https://dart.dev)