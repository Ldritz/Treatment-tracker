import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  final client = SupabaseClient(dotenv.env['SUPABASE_URL'] ?? '', dotenv.env['SUPABASE_ANON_KEY'] ?? '');
  
  try {
    final res = await client.from('production_logs').select().limit(1);
    print('Production Log Res: $res');
  } catch(e) {
    print('Prod error: $e');
  }

  try {
    final res2 = await client.from('egg_logs').select().limit(1);
    print('Egg Log Res: $res2');
  } catch (e) {
    print('Egg error: $e');
  }
  
  exit(0);
}
