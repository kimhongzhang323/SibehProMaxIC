import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

class ApiService {
  static const String _backendUrl = 'http://127.0.0.1:8000';
  static const String _secretKey = 'my-secret-key-123'; // Matches backend

  Map<String, String> _getSecurityHeaders(String method, String path, String body) {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final stringToSign = '$method:$path:$timestamp:$body';
    final hmacSha256 = Hmac(sha256, utf8.encode(_secretKey));
    final digest = hmacSha256.convert(utf8.encode(stringToSign));
    return {
      'X-Timestamp': timestamp,
      'X-Signature': digest.toString(),
      'Content-Type': 'application/json',
    };
  }

  Future<Map<String, dynamic>> chat(String message, {String language = 'english'}) async {
    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': message, 'language': language}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      return {'response': 'Unable to connect to server.', 'type': 'text'};
    }
  }

  Future<Map<String, dynamic>> uploadFile(String filePath, {String? message}) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$_backendUrl/chat/upload'));
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
      if (message != null) {
        request.fields['message'] = message;
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Upload Error: ${response.statusCode}');
      }
    } catch (e) {
      return {'response': 'Upload failed: $e', 'type': 'text'};
    }
  }

  Future<Map<String, dynamic>> getDigitalId() async {
    try {
      final uri = Uri.parse('$_backendUrl/user/id');
      final headers = _getSecurityHeaders('GET', uri.path, '');
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {}
    return {"name": "Tan Ah Kow", "id_number": "900101-14-1234", "country": "Malaysia", "qr_data": "did:my:900101141234:verify", "valid_until": "2030-12-31"};
  }

  Future<Map<String, dynamic>> processPayment(String taskId, int stepId, String amount) async {
    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/chat/payment'),
        body: {
          'task_id': taskId,
          'step_id': stepId.toString(),
          'amount': amount,
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Payment Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Payment failed: $e');
    }
  }

  Future<Map<String, dynamic>> generateProof(String attribute) async {
    try {
      final uri = Uri.parse('$_backendUrl/security/generate_proof');
      final body = jsonEncode({'attribute': attribute});
      final headers = _getSecurityHeaders('POST', uri.path, body);
      final response = await http.post(uri, headers: headers, body: body);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      // return error
    }
    return {'result': false, 'timestamp': ''};
  }

  Future<bool> checkRevocationStatus() async {
    try {
      final uri = Uri.parse('$_backendUrl/security/status');
      final headers = _getSecurityHeaders('GET', uri.path, '');
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == 'revoked';
      }
    } catch (e) {
      return false; 
    }
    return false;
  }
}
