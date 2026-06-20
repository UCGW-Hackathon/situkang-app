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

  final loginData = jsonDecode(loginRes.body);
  final token = loginData['data']['access_token'];

  // Attempt Order with the REAL schema from api-spec.md
  final orderRes = await http.post(
    Uri.parse('$baseUrl/orders'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token'
    },
    body: jsonEncode({
      'worker_id': '123e4567-e89b-12d3-a456-426614174000',
      'service_id': '123e4567-e89b-12d3-a456-426614174001',
      'title': 'Perbaikan Pipa Bocor',
      'description': 'Pipa wastafel bocor',
      'location': {
        'latitude': -6.200000,
        'longitude': 106.816666,
        'address': 'Test Address',
        'address_detail': 'Dekat pintu'
      },
      'preferred_date': '2026-10-25',
      'preferred_time_start': '09:00',
      'preferred_time_end': '12:00',
      'urgency': 'normal',
      'photos': [],
      'notes': 'Test notes'
    })
  );

  print('Order response code: ${orderRes.statusCode}');
  print('Order response body: ${orderRes.body}');
}
