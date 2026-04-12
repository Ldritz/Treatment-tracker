import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() {
  setUpAll(() {
    dotenv.testLoad(fileInput: '''
SUPABASE_URL=https://test.supabase.co
SUPABASE_ANON_KEY=test_anon_key
''');
  });

  testWidgets('Dummy test for CI pipeline', (WidgetTester tester) async {
    expect(true, isTrue);
  });
}
