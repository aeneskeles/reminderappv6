import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/notification_service.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Supabase'i başlat
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );
  
  // Bildirim servisini başlat
  await NotificationService.instance.initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _authService = AuthService();
  bool _isAuthenticated = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuth();
    _authService.authStateChanges.listen((event) async {
      final isAuth = _authService.isAuthenticated;
      setState(() {
        _isAuthenticated = isAuth;
      });
      
      // Google ile giriş yapıldıysa profil oluştur
      if (isAuth && event.session != null && event.session!.user != null) {
        final user = event.session!.user;
        // Eğer Google ile giriş yapıldıysa (provider google ise)
        if (user.appMetadata['provider'] == 'google') {
          await _handleGoogleSignInProfile(user);
        }
      }
    });
  }

  Future<void> _handleGoogleSignInProfile(User user) async {
    try {
      final authService = AuthService();
      final existingProfile = await authService.getUserProfile();
      
      if (existingProfile == null) {
        // Profil yoksa oluştur
        final fullName = user.userMetadata?['full_name'] as String? ?? 
                        user.userMetadata?['name'] as String? ?? '';
        final nameParts = fullName.split(' ');
        final firstName = nameParts.isNotEmpty ? nameParts[0] : '';
        final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

        final supabase = Supabase.instance.client;
        await supabase.from('profiles').insert({
          'id': user.id,
          'first_name': firstName.isNotEmpty ? firstName : (user.userMetadata?['name'] as String? ?? 'Kullanıcı'),
          'last_name': lastName,
          'email': user.email ?? '',
          'full_name': fullName.isNotEmpty ? fullName : (user.userMetadata?['name'] as String? ?? 'Kullanıcı'),
        });
      }
    } catch (e) {
      print('Google profil oluşturulurken hata: $e');
    }
  }

  Future<void> _checkAuth() async {
    setState(() {
      _isAuthenticated = _authService.isAuthenticated;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      );
    }

    return MaterialApp(
      title: 'Hatırlatıcı Uygulaması',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
      ),
      home: _isAuthenticated ? const HomeScreen() : const LoginScreen(),
    );
  }
}
