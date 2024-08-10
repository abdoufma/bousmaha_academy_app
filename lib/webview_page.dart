import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'main.dart' show MainController;
import 'package:webview_flutter/webview_flutter.dart';
// import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:file_picker/file_picker.dart';
// import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart' show WebKitWebViewController;

// late WebViewController controller;
// String baseUrl = "http://192.168.217.11:3000";
// String baseUrl = "http://192.168.1.104:3000/login";
// String baseUrl = "https://partialprerendering.com";
// String baseUrl = "https://bousmahaacademy.com";
String baseUrl = "https://ecom.appifire.io";
late WebViewController controller;
late WebViewCookieManager cookieManager;
initFilePicker() async {
  if (Platform.isAndroid) {
    // final androidController = (controller.platform as AndroidWebViewController);
    // await androidController.setOnShowFileSelector(_androidFilePicker);
    // final iosController = (controller.platform as WebKitWebViewController);
    // await iosController.setOnConsoleMessage((consoleMessage) { })
  }

  MainController.registerNotificationCallback((dynamic target) {
    print("TARGET: $target");
    controller.loadRequest(Uri.parse('$baseUrl$target'));
  });
}

// Future<List<String>> _androidFilePicker(FileSelectorParams params) async {
//   try {
//     final picker = FilePicker.platform;
//     if (params.mode == FileSelectorMode.openMultiple) {
//       final attachments = await picker.pickFiles(allowMultiple: true);
//       if (attachments == null) return [];

//       return attachments.files
//           .where((element) => element.path != null)
//           .map((e) => File(e.path!).uri.toString())
//           .toList();
//     } else {
//       final attachment = await picker.pickFiles();
//       if (attachment == null) return [];
//       File file = File(attachment.files.single.path!);
//       return [file.uri.toString()];
//     }
//   } catch (e) {
//     return [];
//   }
// }

_sendFCMTokenToJS() async {
  final token = await FirebaseMessaging.instance.getToken();
  print("---------------[TOKEN SENT]---------------");
  controller.runJavaScript("onTokenReceived('$token')");
}

class WebViewPage extends StatefulWidget {
  const WebViewPage({super.key});

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late bool isLoading;
  late bool isOnline;
  late bool connectionErr;

  @override
  void initState() {
    // final cookie = WebViewCookie(
    //     domain: "google.com",
    //     name: "next-auth.session-tokecdcdcn",
    //     value:
    //         "eyJhbGciOiJkaXIiLCJlbmMiOiJBMjU2R0NNIn0..LykQwrpufaabjPFC.m1dImZUXgs_CgYuCQRfo6UNXxW8lX0qSvlM_dspKGi_7gowaMxilFZemhQaEUIuZQ4uIOisJOO--hp142neYAPcWALaRFcuoYEDQ2LXCKeGICVNtdeBq-XLDiA3WRgYLU-5qNzbE2vmpVFnRnCChKaP2wQ8t0pQzDKH_wTS3hmPK_Z_37axCC05SHeMeN5RohYQlAHz1J3OejA4MeHoO3yHZ6UEcWasG2VdGjoRj--omW-efjoXZSQbSYZi2hZriMHq9F1VnRYRj4CuqdSLyffUqR13tKxzHN2is83G_bKd9zKKJu2FVC0r_a9iiPxcoDgSpeP6JH5D6t0nmI2g-d4C8AKoq7-FrQKUtl2F6a713m9xVY73jVCG1ryRVVFU-CIQXNu49vuD7bZlW-RwndT2GJqzGxTXlLTScnXLLPz4h_N-VRqhPtwH_t4ZN91VVUcDcac7syGXlh3ivDuAnrCQgZJZx70DZNZ_OjeSZtj1KC3sSE_aECDHkPG0_BHYd6chwl6TujVAz1AnVE6Lh-Pkn1CArcjY2-H3P4SUqY5gWYB_zPHD7T_FEkU-MSvTJV_MrTvmWFdINoHE67wyfB39-OBR_B3hxAfd_9OCSE8BtNusZMNlGvIXoAQLre01gl2IUJ2E.UpdbwYEXBh6dfUF91MfufA; Path=/; Expires=Wed, 19 Mar 2025 14:49:11 GMT");
    // cookieManager = WebViewCookieManager()..setCookie(cookie);
    super.initState();
    isLoading = true;
    isOnline = true;
    connectionErr = false;
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Color.fromARGB(255, 255, 255, 255))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {/* Update loading bar */},
          onPageStarted: (String url) {},
          onPageFinished: (String url) {
            print("----- PAGE FINISHED LOADING (URL: $url) -----");
            setState(() => isLoading = false);
            if (url.contains(baseUrl)) {
              Timer(const Duration(seconds: 1), _sendFCMTokenToJS);
            }
          },
          onWebResourceError: (WebResourceError error) {
            print("------------ [WEB RESOURCE ERROR] ------------");
            print(error.errorType);
            print(error.errorCode);
            print(error.description);

            setState(() => isLoading = false);
            setState(() => connectionErr = true);
            if (error.errorType == WebResourceErrorType.timeout ||
                error.errorType == WebResourceErrorType.failedSslHandshake) {
              controller.loadFlutterAsset('assets/error.html');
            }
          },
          onNavigationRequest: (NavigationRequest req) {
            if (connectionErr) {
              controller.loadFlutterAsset('assets/error.html');
            }
            if (isOnline) {
              if (req.url.contains('youtube'))
                return NavigationDecision.prevent;
              print("isLoading , $isLoading");
              return NavigationDecision.navigate;
            }

            setState(() => isLoading = false);
            return NavigationDecision.prevent;
          },
        ),
      )
      ..enableZoom(false)
      ..addJavaScriptChannel("Flutter",
          onMessageReceived: (msg) => {_handleJSMessage(msg, controller)})
      ..loadRequest(Uri.parse(baseUrl));
    // _sendFCMTokenToJS();
  }

  void _updateIsOnline(bool online) {
    setState(() {
      isOnline = online;
      connectionErr = false;
    });
    print("isOnline ,$isOnline");
  }

  @override
  Widget build(BuildContext context) {
    initFilePicker();
    return PopScope(
        canPop: false,
        onPopInvoked: (bool didPop) async {
          controller.runJavaScript("back()");
          // try {
          //   controller.goBack();
          // } catch (e) {
          //   print("Error changing url");
          //   debugPrint(e.toString());
          // }
        },
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : WebViewWidget(controller: controller)
        // ),
        );
  }
}

void _handleJSMessage(
    JavaScriptMessage msg, WebViewController controller) async {
  print('[MESSAGE RECEIVED (STRING) ] ${msg.toString()}');
  print('[MESSAGE RECEIVED (CONTENT)] ${msg.message}');
  try {
    if (msg.message == "reloadClicked") {
      // Call your reload function here
      _handleReloadClicked(controller);
    }
    print('[MESSAGE RECEIVED (STRING) ] ${msg.toString()}');
    print('[MESSAGE RECEIVED (CONTENT)] ${msg.message}');

    final event = Map<String, String>.from(jsonDecode(msg.message));

    if (event["type"] == "go_back") {
      controller.goBack();
      // if (Platform.isAndroid) {
      //   SystemNavigator.pop();
      // } else if (Platform.isIOS) {
      //   exit(0);
      // }
    }

    if (event["type"] == "save_user_id") {
      // final userId = event["data"]!;
      // await saveUser("id", userId);
      print("loggedIn user id : ${event["data"]}");
      _sendFCMTokenToJS();
    }

    if (event["type"] == "reload") {
      controller.loadRequest(Uri.parse(baseUrl));
    }
  } catch (e) {
    print("Problem receiving message");
    print(e);
  }
}

void _handleReloadClicked(WebViewController controller) {
  // Check for internet connectivity before reloading
  Connectivity().checkConnectivity().then((ConnectivityResult result) {
    if (result != ConnectivityResult.none) {
      print(" internet connection established");

      controller.goBack();
    } else {
      // Handle offline scenario
      print("No internet connection, cannot reload");
      // You could display a user-friendly message here
    }
  });
}

class OfflinePage extends StatefulWidget {
  final void Function(bool) updateIsOnline;
  final WebViewController webViewController;

  const OfflinePage(
      {Key? key, required this.updateIsOnline, required this.webViewController})
      : super(key: key);

  @override
  State<OfflinePage> createState() => _OfflinePageState();
}

class _OfflinePageState extends State<OfflinePage> {
  // late bool connectivityResult;
  bool _isOnline = false;

  @override
  void initState() {
    super.initState();

    Connectivity().checkConnectivity().then((ConnectivityResult result) {
      setState(() {
        // connectivityResult = result != ConnectivityResult.none;
        widget.updateIsOnline(result != ConnectivityResult.none);
      });
    });
  }

  Future<void> _checkConnectivity() async {
    Connectivity().checkConnectivity().then((ConnectivityResult result) {
      setState(() async {
        _isOnline = result != ConnectivityResult.none;
        widget.updateIsOnline(result != ConnectivityResult.none);
        await widget.webViewController.reload();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/noInternet.png',
              width: 100,
              height: 100,
            ),
            const SizedBox(height: 20),
            const Text(
              'No Internet Connection',
              style: TextStyle(
                fontSize: 15,
                color: Color.fromARGB(255, 23, 83, 188),
                fontFamily: 'Montserrat',
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _checkConnectivity,
              child: const Text(
                'Check Connection',
                style: TextStyle(
                  fontSize: 13,
                  color: Color.fromARGB(255, 23, 83, 188),
                  fontFamily: 'Montserrat',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void handleHorizontalDrag(DragStartDetails deets, BoxConstraints constraints) {
  print("Drag start ${deets.localPosition}");
  if (deets.globalPosition.dy < constraints.maxHeight * .2) {
    print("within top 20%");
  }
}



// Future<void> saveUser(String key, String value) async {
//   final db = await openDB;
//   await db.update("user", {key: value});
// }

// Future<String?> getUser(String key) async {
//   final db = await openDB;
//   final result = await db.rawQuery("SELECT * FROM user");
//   if (result.isNotEmpty) {
//     final record = result[0];
//     return record[key] as String;
//   }
//   return null;
// }