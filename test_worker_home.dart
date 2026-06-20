import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const baseUrl = 'http://situkang-api-20260616.eastasia.azurecontainer.io:7860/v1';
  
  final loginRes = await http.post(
    Uri.parse('$baseUrl/auth/login'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'email': 'fardan.idnsolo@gmail.com',
      'password': '00000000Aa'
    })
  );

  print('Login status: ${loginRes.statusCode}');
  print('Login body: ${loginRes.body}');
  if (loginRes.statusCode != 200) return;
  
  final loginData = jsonDecode(loginRes.body);
  final token = loginData['data']['access_token'];

  final res = await http.get(
    Uri.parse('$baseUrl/worker/home'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token'
    },
  );

  print('Worker Home status: ${res.statusCode}');
  print('Worker Home body: ${res.body}');

  final resOrders = await http.get(
    Uri.parse('$baseUrl/worker/orders'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token'
    },
  );

  print('Worker Orders status: ${resOrders.statusCode}');
  print('Worker Orders body: ${resOrders.body}');
}
