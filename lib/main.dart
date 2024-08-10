import 'dart:async';
import 'dart:convert';
import 'package:bousmaha_academy/db.dart';
import 'package:bousmaha_academy/webview_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'firebase_options.dart' show DefaultFirebaseOptions;
// import 'package:sqflite/sqflite.dart';
import 'package:http/http.dart' as http;

Timer setTimeout(callback, [int duration = 1000]) {
  return Timer(Duration(milliseconds: duration), callback);
}

void clearTimeout(Timer t) => t.cancel();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );
  FirebaseMessaging.instance.onTokenRefresh.listen((fcmToken) async {
    print("new token: $fcmToken");
    await saveToken(fcmToken);
    controller.runJavaScript("onTokenReceived('$fcmToken')");
  }).onError((Object err) => print("Error Getting Refresh Token : $err"));
  FirebaseMessaging.onMessage.listen(_notificationHandler);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await connectDb();
  runApp(const MyApp());
}

Future<void> saveTokentoStorage() async {
  final token = await FirebaseMessaging.instance.getToken();
  if (token == null) {
    print("[FIREBASE MESSAGING]: TOKEN NULL");
  } else {
    await saveToken(token);
    controller.runJavaScript("onTokenReceived('$token')");
    print("[FIREBASE MESSAGING]: TOKEN SAVED TO STORAGE : $token");
  }
}

Future<void> setupInteractedMessage() async {
  // Get any messages which caused the application to open from a terminated state.
  RemoteMessage? initialMessage =
      await FirebaseMessaging.instance.getInitialMessage();
  print('[setupInteractedMessage],$initialMessage');

  // If the message data contains a "page" key, navigate to it
  if (initialMessage != null) {
    _handleMessage(initialMessage);
  }

  // Handle any interaction when the app is in the bg via a stream listener
  FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
}

void _handleMessage(RemoteMessage message) {
  print('[MESSAGE OPENED APP]');
  print(message.data);
  final page = message.data['page'];
  if (page != null) {
    print('navigating to \'$page\' ...');
    // Navigator.pushNamed(context, page);
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    requestNotificationPermission();

    setupInteractedMessage();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bousmaha Academy',
      debugShowCheckedModeBanner: false,
      home: FutureBuilder(
        future: Future.wait([saveTokentoStorage(), setupInteractedMessage()]),
        builder: (context, snapshot) {
          return const Scaffold(
            body: SafeArea(
              child: WebViewPage(),
              // child: Center(child: Text("Hello there"))),
            ),
          );
        },
      ),
    );
  }
}

requestNotificationPermission() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  print('User granted permission: ${settings.authorizationStatus}');
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore, make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp();

  print("Handling a background message: ${message.messageId}");
}

_notificationHandler(RemoteMessage message) {
  print('Message Data: "${message.notification?.android}"');
  // if (message.data.isEmpty) return;

  final clickAction = message.notification?.android?.clickAction;
  if (clickAction == "FLUTTER_NOTIFICATION_CLICK") {
    // final page = message.data["page"];
    // MainController.callback?.call(page);
    // print("Navigating to $page");
    // controller.runJavaScript("navigate_to('page');");
  }

  if (message.notification != null) {
    print('Message notification: "${message.notification!.title}"');
  }
}

class MainController {
  // MainController();
  static Function? callback;
  static void registerNotificationCallback(void Function(dynamic args) cb) {
    callback = cb;
  }
}
