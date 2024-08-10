import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

late Future<Database> openDB;
late SharedPreferences prefs;

Future<void> saveToken(String token) async {
  await prefs.setString('token', token);
}

Future<String?> getToken() async {
  final token = prefs.getString('token');
  print('DB Token: $token');
  return token;
}

Future<void> connectDb() async {
  prefs = await SharedPreferences.getInstance();
}
