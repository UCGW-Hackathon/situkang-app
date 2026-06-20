import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const baseUrl = 'http://situkang-api-20260616.eastasia.azurecontainer.io:7860/v1';
  
  final loginRes = await http.post(
    Uri.parse('$baseUrl/auth/login'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'email': 'siti.rahayu@gmail.com',
      'password': 'Password123!'
    })
  );

  if (loginRes.statusCode != 200) {
    print('Login failed: ${loginRes.body}');
    return;
  }
  
  final loginData = jsonDecode(loginRes.body);
  final token = loginData['data']['access_token'];

  final res = await http.get(
    Uri.parse('$baseUrl/orders'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token'
    },
  );

  print('Orders status: ${res.statusCode}');
  print('Orders body: ${res.body}');
}
