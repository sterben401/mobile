import 'package:shared_preferences/shared_preferences.dart';

import 'Service/line.dart';

class User {
  static bool isSignedIn = false;
  static String firstName = "";
  static String lastName = "";
  static String email = "";
  static String phone = "";
  static String description = "";
  static String password = "";
  static String token = "";



static Future seturole(bool urole) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    await pref.setBool("urole-in", urole);
  }

  static Future<bool?> geturole() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    return pref.getBool("urole-in");
  }


  static Future<void> setSignIn(bool value) async {
    isSignedIn = value;
  }

  static Future<bool?> getsignin() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    return pref.getBool("Sign-in");
  }

  static Future setsigin(bool signin) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    await pref.setBool("Sign-in", signin);
  }

  static Future<String> setEmail(String email) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    await pref.setString("Email", email);
    return email;
  }

  static Future<String?> getEmail() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    {}
    return pref.getString("Email");
  }

  static saveSettings(String ip, String port) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('ip', ip);
    await prefs.setString('port', port);
    // คุณสามารถเพิ่มโค้ดเพิ่มเติมตามที่คุณต้องการ
  }

  static Future<Map<String, String?>> getSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? ip = prefs.getString('ip');
    String? port = prefs.getString('port');
    return {'ip': ip, 'port': port};
  }

  static Future<void> addLineNotifyToken(String token, String email) async {
   //print("checkUpdate55");
    final prefs = await SharedPreferences.getInstance();

    // Get the existing list of tokens and emails
    List<String> tokens = prefs.getStringList('lineNotifyTokens') ?? [];
    List<String> emails = prefs.getStringList('lineNotifyEmails') ?? [];

    tokens.add(token);
    emails.add(email);
    // Save the updated list
    //print("checkUpdate1");

    await prefs.setStringList('lineNotifyTokens', tokens);
    //print("checkUpdate");
    await prefs.setStringList('lineNotifyEmails', emails);
        //print("checkUpdate999");
   //checkAndSendLineNotification();
  }

static Future<List<String>> getLineNotifyTokens() async {
  final prefs = await SharedPreferences.getInstance();
  List<String> tokens = prefs.getStringList('lineNotifyTokens') ?? [];
  //print('Fetched tokens: $tokens'); // ตรวจสอบข้อมูลที่ดึงมา
      //checkAndSendLineNotification();
      //print(token);


  return tokens;
}


  static Future<void> removeLineNotifyToken(String token, String email) async {
    final prefs = await SharedPreferences.getInstance();

    // Get the existing list of tokens and emails
    List<String> tokens = prefs.getStringList('lineNotifyTokens') ?? [];
    List<String> emails = prefs.getStringList('lineNotifyEmails') ?? [];

    tokens.remove(token);
    emails.remove(email);

    // Save the updated list
    await prefs.setStringList('lineNotifyTokens', tokens);
    await prefs.setStringList('lineNotifyEmails', emails);
  }

  static Future<void> checkLoginStatus() async {
    String? email = await getEmail();
    if (email != null) {
      print("อีเมลที่ล็อกอินอยู่: $email");
      // ดำเนินการต่อไปกับข้อมูลที่ได้จากการล็อกอิน
    } else {
      print("ไม่มีข้อมูลอีเมลใน shared preferences");
      // ดำเนินการให้ผู้ใช้ล็อกอินใหม่
    }
  }
static Future resetSharedPreferences() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('lineNotifyTokens');
  await prefs.remove('lineNotifyEmails');
}

 static Future<void> clearSpecificKeys() async { // ลบข้อมูล
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('lineNotifyTokens');
  await prefs.remove('lineNotifyEmails');
  print('Specific keys removed from SharedPreferences.');
}

  static Future<void> fetchAndPrintSettings() async {
    // ดึงข้อมูลการตั้งค่าจาก SharedPreferences
    Map<String, String?> settings = await User.getSettings();

    // แสดงผลข้อมูล IP และ Port
    String? ip = settings['ip'];
    String? port = settings['port'];

    print('IP Address: $ip');
    print('Port: $port');
  }
}