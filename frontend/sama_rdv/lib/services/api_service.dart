import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
class ApiService {
 static Future<String?> get token async => (await SharedPreferences.getInstance()).getString('access');
 static Future<Map<String,String>> headers({bool auth=false}) async {
  final h=<String,String>{'Content-Type':'application/json'};
  if(auth){final t=await token;if(t!=null)h['Authorization']='Bearer $t';}
  return h;
 }
 
static dynamic decode(http.Response r) {
  dynamic data;

  try {
    data = jsonDecode(r.body.isEmpty ? '{}' : r.body);
  } catch (_) {
    final preview = r.body.length > 250
        ? r.body.substring(0, 250)
        : r.body;

    throw Exception(
      'Le serveur a renvoyé une réponse non JSON '
      '(HTTP ${r.statusCode}). Vérifiez les routes Django. '
      'Réponse : $preview',
    );
  }

  if (r.statusCode < 200 || r.statusCode >= 300) {
    if (data is Map && data['detail'] != null) {
      throw Exception(data['detail'].toString());
    }

    throw Exception('Erreur HTTP ${r.statusCode} : $data');
  }

  return data;
}

 static Future<void> register(String username,String first,String last,String email,String password) async {
  final r=await http.post(Uri.parse('${ApiConfig.baseUrl}/auth/register/'),headers:await headers(),
   body:jsonEncode({'username':username,'first_name':first,'last_name':last,'email':email,'password':password}));
  decode(r);
 }
 static Future<void> login(String username,String password) async {
  final r=await http.post(Uri.parse('${ApiConfig.baseUrl}/auth/token/'),headers:await headers(),
   body:jsonEncode({'username':username,'password':password}));
  final d=decode(r) as Map<String,dynamic>;
  final p=await SharedPreferences.getInstance(); await p.setString('access',d['access']); await p.setString('refresh',d['refresh']);
 }
 static Future<void> logout() async {final p=await SharedPreferences.getInstance();await p.remove('access');await p.remove('refresh');}
 static Future<List<dynamic>> doctors({String search=''}) async {
  final uri=Uri.parse('${ApiConfig.baseUrl}/doctors/').replace(queryParameters:search.isEmpty?null:{'search':search});
  return decode(await http.get(uri,headers:await headers())) as List<dynamic>;
 }
 static Future<List<dynamic>> appointments() async => decode(await http.get(Uri.parse('${ApiConfig.baseUrl}/appointments/'),headers:await headers(auth:true))) as List<dynamic>;
 static Future<void> book(int doctor,String date,String time,String reason,{int? hospital}) async {
  final body=<String,dynamic>{'doctor':doctor,'appointment_date':date,'appointment_time':time,'reason':reason};
  if(hospital!=null) body['hospital']=hospital;
  decode(await http.post(Uri.parse('${ApiConfig.baseUrl}/appointments/'),headers:await headers(auth:true),
   body:jsonEncode(body)));
 }
 static Future<Map<String,dynamic>> profile() async =>
   decode(await http.get(Uri.parse('${ApiConfig.baseUrl}/profile/'),headers:await headers(auth:true))) as Map<String,dynamic>;
 static Future<void> updateProfilePhoto(String photoUrl) async {
  decode(await http.patch(Uri.parse('${ApiConfig.baseUrl}/profile/'),headers:await headers(auth:true),
   body:jsonEncode({'photo_url':photoUrl})));
 }
 static Future<void> cancel(int id) async {
  decode(await http.post(Uri.parse('${ApiConfig.baseUrl}/appointments/$id/cancel/'),headers:await headers(auth:true),body:'{}'));
 }
}
