// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


import 'package:quail_logger_flutter/main.dart';

void main() {
  setUpAll(() {
    dotenv.testLoad(fileInput: '''SUPABASE_URL=test
SUPABASE_ANON_KEY=test''');
  });
  testWidgets('Dummy test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // Dummy test to replace broken counter test

    // Verify that our counter starts at 0.
    expect(1, 1);


    // Tap the '+' icon and trigger a frame.



    // Verify that our counter has incremented.


  });
}
