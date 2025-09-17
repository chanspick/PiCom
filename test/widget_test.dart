import 'package:flutter_test/flutter_test.dart';
import 'package:picom/app.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';

// As of firebase_core_platform_interface 5.0.0, `MethodChannelFirebase` is private.
// This is a workaround to mock the Firebase initialization.
// See: https://github.com/firebase/flutterfire/issues/10434
setupFirebaseCoreMocks() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Mock Firebase.initializeApp()
  FirebasePlatform.instance = MockFirebasePlatform();
}

class MockFirebasePlatform extends FirebasePlatform {
  @override
  Future<FirebaseAppPlatform> initializeApp({
    String? name,
    FirebaseOptions? options,
  }) async {
    return MockFirebaseApp();
  }

  @override
  FirebaseAppPlatform app([String name = defaultFirebaseAppName]) {
    return MockFirebaseApp();
  }
}

class MockFirebaseApp extends FirebaseAppPlatform {
  MockFirebaseApp() : super('test_app', const FirebaseOptions(
    apiKey: 'test',
    appId: 'test',
    messagingSenderId: 'test',
    projectId: 'test',
  ));
}


void main() {
  setupFirebaseCoreMocks();

  setUpAll(() async {
    await Firebase.initializeApp();
  });

  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the app is rendered.
    expect(find.byType(MyApp), findsOneWidget);
  });
}