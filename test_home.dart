import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final loginRes = await http.post(
    Uri.parse('https://xryz-gcw-situkang.hf.space/v1/auth/login'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'email': 'fardan.idnsolo@gmail.com',
      'password': '00000000Aa'
    })
  );
  
  if (loginRes.statusCode != 200) return;
  final token = jsonDecode(loginRes.body)['data']['access_token'];
  final headers = {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'};
  
  final res = await http.get(Uri.parse('https://xryz-gcw-situkang.hf.space/v1/home?latitude=-6.200&longitude=106.816'), headers: headers);
  if (res.statusCode == 200) {
    print(res.body);
  }
}
