import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';

/// Admin Panel Ekranı
/// 
/// Yönetim panelinin ana ekranı.
/// 
/// Yapısı:
/// - Kullanıcı yönetimi
/// - Rapor yönetimi
/// - İçerik yönetimi
/// - Bildirim yönetimi
/// - Sistem logları

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({Key? key}) : super(key: key);

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadUsers();
      context.read<AdminProvider>().loadReports(status: 'pending');
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AdminProvider, AuthProvider>(
      builder: (context, adminProvider, authProvider, _) {
        // Sadece yöneticiler erişebilir
        if (!authProvider.isAdmin) {
          return Scaffold(
            appBar: AppBar(title: const Text('Admin Paneli')),
            body: const Center(
              child: Text('Erişim reddedildi'),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Admin Paneli'),
            centerTitle: true,
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Kullanıcılar'),
                Tab(text: 'Raporlar'),
                Tab(text: 'İçerik'),
                Tab(text: 'Bildirim'),
                Tab(text: 'Loglar'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              // Kullanıcı Yönetimi
              _buildUsersTab(context, adminProvider, authProvider),
              // Rapor Yönetimi
              _buildReportsTab(context, adminProvider),
              // İçerik Yönetimi
              _buildContentTab(context),
              // Bildirim Yönetimi
              _buildNotificationsTab(context, adminProvider, authProvider),
              // Sistem Logları
              _buildLogsTab(context, adminProvider),
            ],
          ),
        );
      },
    );
  }

  /// Kullanıcı Yönetimi Tab
  Widget _buildUsersTab(
    BuildContext context,
    AdminProvider adminProvider,
    AuthProvider authProvider,
  ) {
    return Column(
      children: [
        // Filtre Butonları
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Expanded(
                child: SegmentedButton<String>(
                  segments: const <ButtonSegment<String>>[
                    ButtonSegment<String>(value: 'all', label: Text('Tümü')),
                    ButtonSegment<String>(value: 'pending', label: Text('Beklemede')),
                    ButtonSegment<String>(value: 'banned', label: Text('Banlanmış')),
                  ],
                  selected: <String>{'all'},
                  onSelectionChanged: (Set<String> newSelection) {
                    adminProvider.loadUsers(
                      status: newSelection.first == 'all'
                          ? null
                          : newSelection.first,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        // Kullanıcı Listesi
        Expanded(
          child: adminProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : adminProvider.users.isEmpty
                  ? const Center(child: Text('Kullanıcı yok'))
                  : ListView.builder(
                      itemCount: adminProvider.users.length,
                      itemBuilder: (context, index) {
                        final user = adminProvider.users[index];
                        return _buildUserTile(
                          context,
                          user,
                          adminProvider,
                          authProvider,
                        );
                      },
                    ),
        ),
      ],
    );
  }

  /// Kullanıcı Tile
  Widget _buildUserTile(
    BuildContext context,
    Map<String, dynamic> user,
    AdminProvider adminProvider,
    AuthProvider authProvider,
  ) {
    return ListTile(
      title: Text(user['username'] ?? 'Bilinmeyen'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(user['email'] ?? ''),
          Text(
            'Durum: ${user['status'] ?? 'Bilinmeyen'}',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (value) async {
          if (value == 'approve') {
            await adminProvider.approveUser(
              userId: user['id'],
              adminId: authProvider.currentUser!.id,
            );
          } else if (value == 'ban') {
            _showBanDialog(context, adminProvider, user['id']);
          } else if (value == 'unban') {
            await adminProvider.unbanUser(userId: user['id']);
          }
        },
        itemBuilder: (context) => [
          if (user['status'] == 'pending')
            const PopupMenuItem(value: 'approve', child: Text('Onayla')),
          const PopupMenuItem(value: 'ban', child: Text('Banla')),
          if (user['status'] == 'banned')
            const PopupMenuItem(value: 'unban', child: Text('Banı Kaldır')),
        ],
      ),
    );
  }

  /// Rapor Yönetimi Tab
  Widget _buildReportsTab(
    BuildContext context,
    AdminProvider adminProvider,
  ) {
    return Column(
      children: [
        Expanded(
          child: adminProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : adminProvider.reports.isEmpty
                  ? const Center(child: Text('Rapor yok'))
                  : ListView.builder(
                      itemCount: adminProvider.reports.length,
                      itemBuilder: (context, index) {
                        final report = adminProvider.reports[index];
                        return _buildReportTile(
                          context,
                          report,
                          adminProvider,
                        );
                      },
                    ),
        ),
      ],
    );
  }

  /// Rapor Tile
  Widget _buildReportTile(
    BuildContext context,
    Map<String, dynamic> report,
    AdminProvider adminProvider,
  ) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: ListTile(
        title: Text(
          '${report['report_type']?.toUpperCase() ?? 'UNKNOWN'} Raporu',
        ),
        subtitle: Text(report['description'] ?? ''),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'resolve') {
              await adminProvider.processReport(
                reportId: report['id'],
                status: 'resolved',
              );
            } else if (value == 'reject') {
              await adminProvider.processReport(
                reportId: report['id'],
                status: 'not_resolved',
              );
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'resolve', child: Text('Çözüldü')),
            const PopupMenuItem(value: 'reject', child: Text('Çözülmedi')),
          ],
        ),
      ),
    );
  }

  /// İçerik Yönetimi Tab
  Widget _buildContentTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildContentButton(
          title: 'TV Kanalları',
          icon: Icons.tv,
          onTap: () {
            // TODO: TV yönetimi ekranına git
          },
        ),
        const SizedBox(height: 8),
        _buildContentButton(
          title: 'Radyo Kanalları',
          icon: Icons.radio,
          onTap: () {
            // TODO: Radyo yönetimi ekranına git
          },
        ),
        const SizedBox(height: 8),
        _buildContentButton(
          title: 'Filmler',
          icon: Icons.movie,
          onTap: () {
            // TODO: Film yönetimi ekranına git
          },
        ),
      ],
    );
  }

  /// İçerik Butonu
  Widget _buildContentButton({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  /// Bildirim Yönetimi Tab
  Widget _buildNotificationsTab(
    BuildContext context,
    AdminProvider adminProvider,
    AuthProvider authProvider,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ElevatedButton(
            onPressed: () {
              _showAddNotificationDialog(context, adminProvider, authProvider);
            },
            child: const Text('Bildirim Ekle'),
          ),
          const SizedBox(height: 16),
          // TODO: Bildirim listesi
          const Expanded(
            child: Center(child: Text('Bildirim yönetimi henüz uygulanmadı')),
          ),
        ],
      ),
    );
  }

  /// Sistem Logları Tab
  Widget _buildLogsTab(
    BuildContext context,
    AdminProvider adminProvider,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    adminProvider.loadAdminLogs();
                  },
                  child: const Text('Admin Logları'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    // TODO: Kullanıcı logları
                  },
                  child: const Text('Kullanıcı Logları'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: adminProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : adminProvider.adminLogs.isEmpty
                    ? const Center(child: Text('Log yok'))
                    : ListView.builder(
                        itemCount: adminProvider.adminLogs.length,
                        itemBuilder: (context, index) {
                          final log = adminProvider.adminLogs[index];
                          return ListTile(
                            title: Text(log['action_type'] ?? 'Bilinmeyen'),
                            subtitle: Text(
                              log['action_description'] ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Text(
                              _formatDate(log['created_at']),
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  /// Ban Dialog
  void _showBanDialog(
    BuildContext context,
    AdminProvider adminProvider,
    String userId,
  ) {
    final reasonController = TextEditingController();
    String? selectedDuration = 'permanent';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Kullanıcıyı Banla'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: reasonController,
                decoration: InputDecoration(
                  labelText: 'Ban Sebebi',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                minLines: 2,
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              DropdownButton<String>(
                isExpanded: true,
                value: selectedDuration,
                items: const [
                  DropdownMenuItem(value: 'permanent', child: Text('Kalıcı')),
                  DropdownMenuItem(value: '1440', child: Text('1 Gün')),
                  DropdownMenuItem(value: '10080', child: Text('1 Hafta')),
                  DropdownMenuItem(value: '43200', child: Text('1 Ay')),
                ],
                onChanged: (value) {
                  setState(() => selectedDuration = value);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                await adminProvider.banUser(
                  userId: userId,
                  reason: reasonController.text,
                  duration: selectedDuration == 'permanent'
                      ? null
                      : int.tryParse(selectedDuration ?? ''),
                );
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Kullanıcı banlandı')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Banla'),
            ),
          ],
        ),
      ),
    );
  }

  /// Bildirim Ekleme Dialog
  void _showAddNotificationDialog(
    BuildContext context,
    AdminProvider adminProvider,
    AuthProvider authProvider,
  ) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String selectedRepeat = 'once';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Bildirim Ekle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Başlık',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contentController,
                  minLines: 3,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'İçerik',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButton<String>(
                  isExpanded: true,
                  value: selectedRepeat,
                  items: const [
                    DropdownMenuItem(value: 'once', child: Text('Tek Sefer')),
                    DropdownMenuItem(value: 'daily_3_days', child: Text('3 Gün Günlük')),
                    DropdownMenuItem(value: 'daily_7_days', child: Text('7 Gün Günlük')),
                    DropdownMenuItem(value: 'weekly', child: Text('Haftada Bir')),
                    DropdownMenuItem(value: 'monthly', child: Text('Ayda Bir')),
                  ],
                  onChanged: (value) {
                    setState(() => selectedRepeat = value ?? 'once');
                  },
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
                await adminProvider.addNotification(
                  title: titleController.text,
                  content: contentController.text,
                  repeatType: selectedRepeat,
                  adminId: authProvider.currentUser!.id,
                );
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Bildirim eklendi')),
                  );
                }
              },
              child: const Text('Ekle'),
            ),
          ],
        ),
      ),
    );
  }

  /// Tarihi formatla
  String _formatDate(String? date) {
    if (date == null) return '';
    try {
      final dateTime = DateTime.parse(date);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return '';
    }
  }
}
