import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const baseUrl = 'https://xryz-gcw-situkang.hf.space/v1';
  
  final loginRes = await http.post(
    Uri.parse('$baseUrl/auth/login'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'email': 'muhfardanhafidz@gmail.com',
      'password': '00000000Aa'
    })
  );

  final loginData = jsonDecode(loginRes.body);
  final token = loginData['data']['access_token'];

  final res = await http.get(
    Uri.parse('$baseUrl/worker/home'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token'
    },
  );

  print('Response code: ${res.statusCode}');
  print('Response body: ${res.body}');
}
