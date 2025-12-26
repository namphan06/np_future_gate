import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/services/supabase_service.dart';
import 'core/services/fcm_service.dart';
import 'core/repositories/auth_repository.dart';
import 'screens/splash/splash_screen.dart';
import 'widgets/chat_floating_overlay.dart';

// Global navigator key để access navigator từ bất kỳ đâu
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🚀 Initializing app...');
  
  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
    print('✅ Environment variables loaded');
  } catch (e) {
    print('⚠️ Error loading .env file: $e');
  }
  
  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized');
  } catch (e) {
    print('❌ Firebase initialization error: $e');
  }
  
  // Initialize Supabase
  await SupabaseService.initialize();

  // Initialize date formatting
  await initializeDateFormatting('vi', null);
  
  // Initialize FCM
  try {
    await FCMService().initialize();
    print('✅ FCM Service initialized');
  } catch (e) {
    print('⚠️ FCM initialization error: $e');
  }
  
  // Debug: Check current auth session
  final session = Supabase.instance.client.auth.currentSession;
  final user = Supabase.instance.client.auth.currentUser;
  print('🔐 Auth Debug:');
  print('  Session: ${session != null ? "Active" : "None"}');
  print('  User ID: ${user?.id}');
  print('  User Email: ${user?.email}');
  
  // Nếu user đã đăng nhập, lưu device token
  if (user != null) {
    _saveDeviceTokenForCurrentUser();
  }
  
  runApp(const MyApp());
}

/// Lưu device token cho user hiện tại (nếu đã đăng nhập)
Future<void> _saveDeviceTokenForCurrentUser() async {
  try {
    final authRepo = AuthRepository();
    final profile = await authRepo.getCurrentUserProfile();
    final fcmToken = FCMService().fcmToken;
    
    if (profile != null && fcmToken != null) {
      print('💾 Saving device token for existing session...');
      await authRepo.saveDeviceToken(
        deviceToken: fcmToken,
        userId: profile.id,
        role: profile.role.value,
      );
      print('✅ Device token saved on app startup');
    } else {
      if (fcmToken == null) {
        print('⚠️ FCM token not available yet');
      }
    }
  } catch (e) {
    print('⚠️ Error saving device token on startup: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // Set global navigator key
      title: 'NP FutureGate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      home: const SplashScreen(),
      builder: (context, child) {
        // Wrap toàn bộ app với ChatFloatingOverlay
        // để nút chat hiển thị trên mọi màn hình
        return ChatFloatingOverlay(
          navigatorKey: navigatorKey,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
