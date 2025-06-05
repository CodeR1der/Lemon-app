
import 'package:supabase_flutter/supabase_flutter.dart';

class CompanyService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<String?> getCompanyCode(String companyId) async {
    try {
      final response = await _client
          .from('company')
          .select('code')
          .eq('id', companyId)
          .single();
      return response['code'].toString();
    } on PostgrestException catch (error) {
      print('Ошибка при получении кода: ${error.message}');
      return null;
    }
  }
}