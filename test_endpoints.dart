import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('Logging in...');
  final loginRes = await http.post(
    Uri.parse('https://xryz-gcw-situkang.hf.space/v1/auth/login'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'email': 'fardan.idnsolo@gmail.com',
      'password': '00000000Aa'
    })
  );
  
  if (loginRes.statusCode != 200) {
    print('Login failed'); return;
  }
  final token = jsonDecode(loginRes.body)['data']['access_token'];
  final headers = {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'};
  
  final workerId = '9d8ec210-8509-4fff-9748-e8de4550dbd7';
  
  final endpointsToTest = [
    '/workers/$workerId',
    '/worker/$workerId',
    '/worker/profile/$workerId',
    '/workers/profile/$workerId',
    '/worker/profile?worker_id=$workerId',
    '/workers/detail/$workerId',
  ];
  
  for (final ep in endpointsToTest) {
    print('\nTesting $ep...');
    final res = await http.get(Uri.parse('https://xryz-gcw-situkang.hf.space/v1$ep'), headers: headers);
    print('Status: ${res.statusCode}');
    if (res.statusCode == 200) {
      print('SUCCESS! Body: ${res.body.substring(0, 50)}...');
    } else {
      print('Body: ${res.body}');
    }
  }
}
