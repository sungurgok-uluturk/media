import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/version_provider.dart';

/// Ana Ekran (Home Screen)
/// 
/// Uygulamanın ana ekranı.
/// 
/// İlk açılışta:
/// 1. Versiyon kontrolü yapılır
/// 2. Kullanıcı giriş durumu kontrol edilir
/// 3. Yenilikleri Gör ekranı gösterilir (gerekirse)
/// 4. Ana navigasyon menüsü (TV, Radyo, Film, Sohbet, Ayarlar) gösterilir

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// Seçili sekme indeksi
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  /// Uygulamayı başlat
  /// 
  /// Akış:
  /// 1. Versiyon kontrolü yap
  /// 2. Eğer güncelleme varsa dialog göster
  /// 3. Eğer yenilikleri göstermesi gerekirse ekran göster
  /// 4. Kullanıcı giriş durumunu kontrol et
  Future<void> _initializeApp() async {
    final versionProvider = context.read<VersionProvider>();

    // Versiyon kontrolü yap
    await versionProvider.checkForUpdates();

    // Eğer güncelleme varsa
    if (versionProvider.updateAvailable) {
      _showUpdateDialog(versionProvider);
    }

    // Eğer zorunlu güncelleme ise
    if (versionProvider.isForceUpdate) {
      _showForceUpdateDialog(versionProvider);
    }
  }

  /// Güncelleme dialogu göster
  void _showUpdateDialog(VersionProvider versionProvider) {
    showDialog(
      context: context,
      barrierDismissible: !versionProvider.isForceUpdate,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Güncelleme Mevcut'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Yeni sürüm: ${versionProvider.requiredVersion}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text('Yenilikleri Gör:'),
              const SizedBox(height: 8),
              Text(
                versionProvider.changelog,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          if (!versionProvider.isForceUpdate)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Sonra'),
            ),
          ElevatedButton(
            onPressed: () {
              // Güncelleme linki aç
              if (versionProvider.downloadUrl.isNotEmpty) {
                // URL'yi aç
                // url_launcher paketi ile yapılabilir
              } else if (versionProvider.telegramChannelUrl.isNotEmpty) {
                // Telegram kanalını aç
              }
              Navigator.pop(context);
            },
            child: const Text('Güncelle'),
          ),
        ],
      ),
    );
  }

  /// Zorunlu güncelleme dialogu
  void _showForceUpdateDialog(VersionProvider versionProvider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Zorunlu Güncelleme'),
        content: const Text(
          'Uygulamayı kullanmaya devam etmek için güncelleme yapmanız gerekir.\n'
          'Lütfen uygulamayı güncelleyin.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              // Güncelleme linki aç
              if (versionProvider.downloadUrl.isNotEmpty) {
                // URL'yi aç
              } else if (versionProvider.telegramChannelUrl.isNotEmpty) {
                // Telegram kanalını aç
              }
            },
            child: const Text('Güncelle'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    // Giriş yapılmamış ise giriş ekranını göster
    if (!authProvider.isLoggedIn) {
      return const LoginScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Digital Yayın Platformu'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Hoş geldiniz, ${authProvider.currentUser?.username}!'),
            const SizedBox(height: 20),
            Text('Seçili Sekme: ${_getTabName(_selectedIndex)}'),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.tv),
            label: 'TV',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.radio),
            label: 'Radyo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.movie),
            label: 'Film',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Sohbet',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Ayarlar',
          ),
        ],
      ),
    );
  }

  /// Sekme adını al
  String _getTabName(int index) {
    const names = ['TV', 'Radyo', 'Film', 'Sohbet', 'Ayarlar'];
    return names[index];
  }
}

/// Giriş Ekranı (Placeholder)
class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Giriş Ekranı - Henüz Geliştirilmedi'),
      ),
    );
  }
}
