import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final loginRes = await http.post(
    Uri.parse('http://situkang-api-20260616.eastasia.azurecontainer.io:7860/v1/auth/login'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'email': 'fardan.idnsolo@gmail.com',
      'password': '00000000Aa'
    })
  );
  
  if (loginRes.statusCode != 200) return;
  final token = jsonDecode(loginRes.body)['data']['access_token'];
  final headers = {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'};
  const workerId = '9d8ec210-8509-4fff-9748-e8de4550dbd7';
  
  final res = await http.get(Uri.parse('http://situkang-api-20260616.eastasia.azurecontainer.io:7860/v1/users/$workerId'), headers: headers);
  print('Status: ${res.statusCode}');
  print('Body: ${res.body}');
}
