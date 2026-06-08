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

  final res = await http.put(
    Uri.parse('$baseUrl/worker/profile'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token'
    },
    body: jsonEncode({
      'specialization': 'Perbaikan AC',
      'base_price': 50000,
      'price_unit': 'per jam'
    })
  );

  print('Response code: ${res.statusCode}');
  print('Response body: ${res.body}');
}
