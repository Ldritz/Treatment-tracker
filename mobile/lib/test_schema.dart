import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as developer;

void main() async {
  final client = SupabaseClient('https://lpyxwxfmshuwwogalkfd.supabase.co', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxweXh3eGZtc2h1d3dvZ2Fsa2ZkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU4MDEzNDAsImV4cCI6MjA5MTM3NzM0MH0.pWDpmmWQDugls7-SDNI5gWUk-ImkdE6ksYxxrS7dwfU');
  
  try {
    final res = await client.from('production_logs').select().limit(1);
    developer.log('Production Log Res: $res');
  } catch(e) {
    developer.log('Prod error: $e', error: e);
  }

  try {
    final res2 = await client.from('egg_logs').select().limit(1);
    developer.log('Egg Log Res: $res2');
  } catch (e) {
    developer.log('Egg error: $e', error: e);
  }
  
  exit(0);
}
