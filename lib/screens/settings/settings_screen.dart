import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/auth_provider.dart';

/// Ayarlar Ekranı
/// 
/// Uygulama ayarlarını ve kullanıcı tercihlerini yönetir.
/// 
/// Yapısı:
/// - Tema seçimi
/// - Uygulama ayarları
/// - Player ayarları
/// - Kullanıcı profili
/// - Oturum yönetimi

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsProvider>().loadSettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<SettingsProvider, AuthProvider>(
      builder: (context, settingsProvider, authProvider, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Ayarlar'),
            centerTitle: true,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Kullanıcı Profili
                if (authProvider.isLoggedIn)
                  _buildUserProfile(context, authProvider),

                // Tema Ayarları
                _buildThemeSettings(context, settingsProvider),

                // Uygulama Ayarları
                _buildAppSettings(context, settingsProvider),

                // Player Ayarları
                _buildPlayerSettings(context, settingsProvider),

                // Bilgiler ve Bağlantılar
                _buildInfoSection(context),

                // Oturum Yönetimi
                if (authProvider.isLoggedIn)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          _showLogoutDialog(context, authProvider);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Oturumu Kapat'),
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // TODO: Login ekranına yönlendir
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Giriş ekranına yönlendiriliyorsunuz'),
                            ),
                          );
                        },
                        child: const Text('Giriş Yap'),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Kullanıcı Profili
  Widget _buildUserProfile(
    BuildContext context,
    AuthProvider authProvider,
  ) {
    final user = authProvider.currentUser;
    if (user == null) return const SizedBox();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Profil Resmi
          CircleAvatar(
            radius: 40,
            backgroundImage: user.avatarUrl != null
                ? NetworkImage(user.avatarUrl!)
                : null,
            child: user.avatarUrl == null
                ? const Icon(Icons.person, size: 40)
                : null,
          ),
          const SizedBox(height: 12),
          // Kullanıcı Adı
          Text(
            user.username,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          // Email
          Text(
            user.email,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          // Kullanıcı Seviyesi
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              user.userTier.replaceAll('_', ' ').toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue[900],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Profil Düzenleme Butonu
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                _showProfileEditDialog(context, authProvider);
              },
              child: const Text('Profili Düzenle'),
            ),
          ),
        ],
      ),
    );
  }

  /// Tema Ayarları
  Widget _buildThemeSettings(
    BuildContext context,
    SettingsProvider settingsProvider,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tema',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('Açık'),
                selected: settingsProvider.theme == 'light',
                onSelected: (selected) {
                  if (selected) {
                    settingsProvider.setTheme('light');
                  }
                },
              ),
              FilterChip(
                label: const Text('Koyu'),
                selected: settingsProvider.theme == 'dark',
                onSelected: (selected) {
                  if (selected) {
                    settingsProvider.setTheme('dark');
                  }
                },
              ),
              FilterChip(
                label: const Text('Sistem'),
                selected: settingsProvider.theme == 'system',
                onSelected: (selected) {
                  if (selected) {
                    settingsProvider.setTheme('system');
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// Uygulama Ayarları
  Widget _buildAppSettings(
    BuildContext context,
    SettingsProvider settingsProvider,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Uygulama Ayarları',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          // Başlangıç Sekmesi
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Başlangıç Sekmesi'),
            subtitle: Text(settingsProvider.startTab.toUpperCase()),
            onTap: () {
              _showStartTabDialog(context, settingsProvider);
            },
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          ),
          // Bildirimler
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Bildirimleri Etkinleştir'),
            value: settingsProvider.notificationsEnabled,
            onChanged: (value) {
              settingsProvider.setNotifications(value);
            },
          ),
          // Radyo Arka Plan Oynatması
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Radyo Arka Planda Çalsın'),
            value: settingsProvider.radioBackgroundPlayback,
            onChanged: (value) {
              settingsProvider.setRadioBackgroundPlayback(value);
            },
          ),
          // Otomatik Kalite Seçimi
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Otomatik Kalite Seçimi'),
            value: settingsProvider.autoSelectQuality,
            onChanged: (value) {
              settingsProvider.setAutoSelectQuality(value);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// Player Ayarları
  Widget _buildPlayerSettings(
    BuildContext context,
    SettingsProvider settingsProvider,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Player Ayarları',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          // TV Player Başlangıç Modu
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('TV Player Başlangıç Modu'),
            subtitle: Text(
              settingsProvider.tvPlayerStartMode == 'fullscreen'
                  ? 'Tam Ekran'
                  : 'Mini',
            ),
            onTap: () {
              _showTvPlayerModeDialog(context, settingsProvider);
            },
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          ),
          // TV Kanal Listesi Konumu
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('TV Kanal Listesi Konumu'),
            subtitle: Text(
              _getPositionName(settingsProvider.tvChannelListPosition),
            ),
            onTap: () {
              _showChannelListPositionDialog(context, settingsProvider);
            },
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          ),
          // TV Kanal Listesi Şeffaflığı
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('TV Kanal Listesi Şeffaflığı'),
            subtitle: Text(
              settingsProvider.tvChannelListTransparency == 'transparent'
                  ? 'Şeffaf'
                  : 'Opak',
            ),
            onTap: () {
              _showTransparencyDialog(context, settingsProvider);
            },
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// Bilgi ve Bağlantılar Sektion
  Widget _buildInfoSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bilgi ve Bağlantılar',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Web Sitesi'),
            trailing: const Icon(Icons.open_in_new, size: 16),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Web sitesi açılacak')),
              );
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Telegram Kanalı'),
            trailing: const Icon(Icons.open_in_new, size: 16),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Telegram açılacak')),
              );
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Hakkında'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              _showAboutDialog(context);
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Gizlilik Politikası'),
            trailing: const Icon(Icons.open_in_new, size: 16),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Gizlilik politikası açılacak')),
              );
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Kullanım Şartları'),
            trailing: const Icon(Icons.open_in_new, size: 16),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Kullanım şartları açılacak')),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// TV Player Modu Seçim Dialog
  void _showTvPlayerModeDialog(
    BuildContext context,
    SettingsProvider settingsProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('TV Player Başlangıç Modu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Tam Ekran'),
              value: 'fullscreen',
              groupValue: settingsProvider.tvPlayerStartMode,
              onChanged: (value) {
                if (value != null) {
                  settingsProvider.setTvPlayerStartMode(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('Mini'),
              value: 'mini',
              groupValue: settingsProvider.tvPlayerStartMode,
              onChanged: (value) {
                if (value != null) {
                  settingsProvider.setTvPlayerStartMode(value);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Kanal Listesi Konumu Dialog
  void _showChannelListPositionDialog(
    BuildContext context,
    SettingsProvider settingsProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kanal Listesi Konumu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Sol'),
              value: 'left',
              groupValue: settingsProvider.tvChannelListPosition,
              onChanged: (value) {
                if (value != null) {
                  settingsProvider.setTvChannelListPosition(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('Sağ'),
              value: 'right',
              groupValue: settingsProvider.tvChannelListPosition,
              onChanged: (value) {
                if (value != null) {
                  settingsProvider.setTvChannelListPosition(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('Alt'),
              value: 'bottom',
              groupValue: settingsProvider.tvChannelListPosition,
              onChanged: (value) {
                if (value != null) {
                  settingsProvider.setTvChannelListPosition(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('Üst'),
              value: 'top',
              groupValue: settingsProvider.tvChannelListPosition,
              onChanged: (value) {
                if (value != null) {
                  settingsProvider.setTvChannelListPosition(value);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Şeffaflık Dialog
  void _showTransparencyDialog(
    BuildContext context,
    SettingsProvider settingsProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kanal Listesi Şeffaflığı'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Şeffaf'),
              value: 'transparent',
              groupValue: settingsProvider.tvChannelListTransparency,
              onChanged: (value) {
                if (value != null) {
                  settingsProvider.setTvChannelListTransparency(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('Opak'),
              value: 'opaque',
              groupValue: settingsProvider.tvChannelListTransparency,
              onChanged: (value) {
                if (value != null) {
                  settingsProvider.setTvChannelListTransparency(value);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Başlangıç Sekmesi Dialog
  void _showStartTabDialog(
    BuildContext context,
    SettingsProvider settingsProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Başlangıç Sekmesi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('TV'),
              value: 'tv',
              groupValue: settingsProvider.startTab,
              onChanged: (value) {
                if (value != null) {
                  settingsProvider.setStartTab(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('Radyo'),
              value: 'radio',
              groupValue: settingsProvider.startTab,
              onChanged: (value) {
                if (value != null) {
                  settingsProvider.setStartTab(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('Film'),
              value: 'movie',
              groupValue: settingsProvider.startTab,
              onChanged: (value) {
                if (value != null) {
                  settingsProvider.setStartTab(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('Sohbet'),
              value: 'chat',
              groupValue: settingsProvider.startTab,
              onChanged: (value) {
                if (value != null) {
                  settingsProvider.setStartTab(value);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Profil Düzenleme Dialog
  void _showProfileEditDialog(
    BuildContext context,
    AuthProvider authProvider,
  ) {
    final user = authProvider.currentUser;
    if (user == null) return;

    final usernameController = TextEditingController(text: user.username);
    final phoneController = TextEditingController(text: user.phoneNumber);
    final bioController = TextEditingController(text: user.bio);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profili Düzenle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(
                  labelText: 'Kullanıcı Adı',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Telefon Numarası',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bioController,
                minLines: 3,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Biyografi',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await authProvider.updateProfile({
                'phone_number': phoneController.text,
                'bio': bioController.text,
              });

              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Profil güncellendi'
                          : 'Profil güncelleme hatası',
                    ),
                  ),
                );
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  /// Oturum Kapatma Dialog
  void _showLogoutDialog(
    BuildContext context,
    AuthProvider authProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Oturumu Kapat'),
        content: const Text('Oturumunuzu kapatmak istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              await authProvider.logout();
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Oturum kapatıldı')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  /// Hakkında Dialog
  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Digital Yayın Platformu',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2026 Tüm hakları saklıdır.',
    );
  }

  /// Konum adını getir
  String _getPositionName(String position) {
    switch (position) {
      case 'left':
        return 'Sol';
      case 'right':
        return 'Sağ';
      case 'bottom':
        return 'Alt';
      case 'top':
        return 'Üst';
      default:
        return 'Sağ';
    }
  }
}
