# Flutter

## Mục đích

Giải thích chi tiết về Flutter framework — công nghệ nền tảng được sử dụng để xây dựng toàn bộ ứng dụng NP FutureGate.

## Định nghĩa

Flutter là một UI toolkit mã nguồn mở do Google phát triển, cho phép xây dựng ứng dụng đa nền tảng (cross-platform) từ một codebase duy nhất. Flutter sử dụng ngôn ngữ lập trình Dart và rendering engine riêng (Skia/Impeller) để vẽ giao diện trực tiếp lên canvas, không phụ thuộc vào native UI components của hệ điều hành.

**Phiên bản sử dụng trong dự án:** Dart SDK ^3.9.2

## Lý do sử dụng trong dự án

1. **Cross-platform từ một codebase:** NP FutureGate cần chạy trên cả Android và iOS. Flutter cho phép viết một lần, chạy trên nhiều nền tảng mà không cần maintain 2 codebase riêng biệt.

2. **Hot Reload:** Tăng tốc quá trình phát triển đáng kể — thay đổi code được phản ánh ngay lập tức trên thiết bị mà không cần rebuild toàn bộ app.

3. **Widget-based architecture:** Mọi thứ trong Flutter đều là Widget, tạo nên hệ thống UI có tính tái sử dụng cao, phù hợp với ứng dụng phức tạp nhiều màn hình như NP FutureGate.

4. **Hệ sinh thái packages phong phú:** Dễ dàng tích hợp các dịch vụ bên thứ ba (Supabase, Firebase, Google ML Kit, Mistral AI) thông qua pub.dev.

5. **Performance tốt:** Flutter compile sang native ARM code, đạt hiệu suất gần native, phù hợp cho ứng dụng có realtime chat, push notifications, và xử lý AI.

## Cách tích hợp trong dự án

### Cấu trúc dự án Flutter

```
lib/
├── main.dart                    # Entry point
├── firebase_options.dart        # Firebase configuration
├── core/                        # Shared core modules
│   ├── controllers/             # BaseController, PaginationMixin
│   ├── services/                # 17 service files
│   ├── repositories/            # 16 repository files
│   ├── models/                  # 24 model files
│   ├── theme/                   # App theme, colors, text styles
│   ├── utils/                   # Utility functions
│   ├── enums/                   # Enumerations
│   └── config/                  # Configuration files
├── features/                    # Feature modules (10 modules)
│   ├── auth/                    # Authentication
│   ├── ai/                      # AI matching & chatbot
│   ├── candidate/               # Candidate features
│   ├── employer/                # Employer features
│   ├── school/                  # School features
│   ├── admin/                   # Admin features
│   ├── chat/                    # Realtime chat
│   ├── cv/                      # CV management
│   ├── interview/               # Interview scheduling
│   └── notification/            # Push notifications
├── screens/                     # Shared screens
└── shared/                      # Shared widgets
```

### Entry Point (main.dart)

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize timezone
  tz.initializeTimeZones();
  
  // Load environment variables
  await dotenv.load(fileName: '.env');
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Supabase
  await SupabaseService.initialize();

  // Initialize date formatting
  await initializeDateFormatting('vi', null);
  
  // Initialize FCM
  await FCMService().initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'NP FutureGate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      home: const SplashScreen(),
    );
  }
}
```

### Widget-based UI (Ví dụ từ Feature Module)

Mỗi feature module tuân theo cấu trúc nhất quán:

```
features/{feature_name}/
├── controllers/     # Business logic (extends BaseController/ChangeNotifier)
├── screens/         # UI screens (View layer)
└── widgets/         # Reusable widgets cho feature
```

### State Management với ChangeNotifier

```dart
class HomeCandidateController extends ChangeNotifier {
  final AuthRepository _authRepo = AuthRepository();
  final JobRepository _jobRepo = JobRepository();

  Profile? _profile;
  List<String> _savedJobIds = [];
  bool _isDisposed = false;

  Profile? get profile => _profile;
  Stream<List<JobModel>> get activeJobsStream => _jobRepo.activeJobsStream;

  Future<void> init() async {
    await Future.wait([
      _loadProfile(),
      _loadSavedJobs(),
    ]);
  }

  Future<void> _loadProfile() async {
    final profile = await _authRepo.getCurrentUserProfile();
    if (!_isDisposed) {
      _profile = profile;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
```

## Ưu điểm

| Ưu điểm | Mô tả |
|----------|--------|
| **Cross-platform** | Một codebase cho Android, iOS, Web, Desktop |
| **Hot Reload** | Phản ánh thay đổi ngay lập tức, tăng tốc phát triển |
| **Performance** | Compile sang native code, rendering engine riêng |
| **Widget system** | Tái sử dụng UI components dễ dàng |
| **Hệ sinh thái** | Hàng nghìn packages trên pub.dev |
| **Material Design** | Hỗ trợ sẵn Material Design 3 |
| **Dart language** | Type-safe, null-safety, async/await native |
| **Community** | Cộng đồng lớn, tài liệu phong phú |

## Nhược điểm

| Nhược điểm | Mô tả | Giải pháp trong dự án |
|------------|--------|----------------------|
| **App size lớn** | APK/IPA lớn hơn native (~20-30MB) | Chấp nhận trade-off cho cross-platform |
| **Platform-specific features** | Cần plugin cho tính năng native | Sử dụng packages: permission_handler, device_info_plus |
| **Learning curve** | Widget tree phức tạp với ứng dụng lớn | Tổ chức code theo feature modules |
| **Web performance** | Chưa tối ưu bằng native web | Tập trung vào mobile (Android/iOS) |
| **Dart ecosystem nhỏ hơn** | Ít thư viện hơn JavaScript/Python | Sử dụng HTTP APIs cho AI (Mistral) |

## Ví dụ code từ dự án

### 1. MaterialApp Configuration

```dart
// lib/main.dart
class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,  // Global key cho navigation từ notifications
      title: 'NP FutureGate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      home: const SplashScreen(),
      builder: (context, child) {
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
```

### 2. Async Initialization Pattern

```dart
// lib/main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize timezone
  tz.initializeTimeZones();
  
  // Load environment variables
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('⚠️ Error loading .env file: $e');
  }
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Supabase
  await SupabaseService.initialize();

  // Initialize date formatting (Vietnamese locale)
  await initializeDateFormatting('vi', null);
  
  // Initialize local notifications
  await _initializeLocalNotifications();
  
  // Initialize FCM
  await FCMService().initialize();
  
  // Setup notification navigation
  setupNotificationNavigation();
  
  runApp(const MyApp());
}
```

### 3. Global Navigator Key (cho Push Notifications)

```dart
// lib/main.dart
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
```

## Liên kết liên quan

- [Tổng quan kiến trúc](../01_tong_quan_kien_truc.md)
- [State Management ChangeNotifier](./state_management_changenotifier.md)
- [Supabase](./supabase.md)
- [Firebase FCM](./firebase_fcm.md)
- [Công nghệ sử dụng](../04_cong_nghe_su_dung/tech_stack_overview.md)
