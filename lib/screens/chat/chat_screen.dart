import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';

/// Sohbet Ekranı
/// 
/// Genel sohbet odasının UI'ı.
/// 
/// Yapısı:
/// - Mesaj listesi (üste en yeni)
/// - Mesaj gönderme inputu
/// - Yönetici kontrolleri (admin ise)
/// - Kullanıcı kısıtlaması durumu göstergesi

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  /// Mesaj gönderme controller'ı
  late TextEditingController _messageController;

  /// ScrollController
  late ScrollController _scrollController;

  /// Kullanıcının kısıtlama durumu
  String? _userRestrictionType; // 'muted', 'blocked', null

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _scrollController = ScrollController();

    // İlk yüklemede mesajları getir
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final chatProvider = context.read<ChatProvider>();
      final authProvider = context.read<AuthProvider>();

      await chatProvider.loadMessages();

      // Kullanıcının kısıtlamalarını kontrol et
      if (authProvider.isLoggedIn) {
        final restrictions =
            await chatProvider.getUserRestrictions(authProvider.currentUser!.id);

        if (restrictions.isNotEmpty) {
          final restriction = restrictions.first;
          final expiresAt = restriction['expires_at'] != null
              ? DateTime.parse(restriction['expires_at'])
              : null;

          // Kısıtlama hala geçerli mi?
          if (expiresAt == null || DateTime.now().isBefore(expiresAt)) {
            setState(() {
              _userRestrictionType = restriction['restriction_type'];
            });
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ChatProvider, AuthProvider>(
      builder: (context, chatProvider, authProvider, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Sohbet'),
            centerTitle: true,
            elevation: 0,
            actions: [
              // Yönetici Menüsü
              if (authProvider.isAdmin)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    _handleAdminAction(context, chatProvider, value);
                  },
                  itemBuilder: (BuildContext context) => [
                    const PopupMenuItem<String>(
                      value: 'settings',
                      child: Text('Ayarlar'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'clear',
                      child: Text('Sohbeti Temizle'),
                    ),
                  ],
                ),
            ],
          ),
          body: Column(
            children: [
              // Sohbet Durumu Uyarısı
              if (!chatProvider.isChatOpen)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: Colors.orange[100],
                  child: const Text(
                    'Sohbet şu anda kapalı',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.orange),
                  ),
                ),
              if (chatProvider.isSlowMode)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: Colors.blue[100],
                  child: Text(
                    'Yavaş mod aktif (${chatProvider.slowModeInterval})',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.blue[900]),
                  ),
                ),

              // Kısıtlama Uyarısı
              if (_userRestrictionType != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: Colors.red[100],
                  child: Column(
                    children: [
                      Text(
                        _userRestrictionType == 'muted'
                            ? 'Sohbette susturuldunuz'
                            : 'Sohbetten engellendiniz',
                        style: TextStyle(color: Colors.red[900]),
                      ),
                      if (_userRestrictionType == 'blocked')
                        const SizedBox(height: 8),
                      if (_userRestrictionType == 'blocked')
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              _showAppealDialog(context, chatProvider);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: const Text('İtiraz Et'),
                          ),
                        ),
                    ],
                  ),
                ),

              // Mesaj Listesi
              Expanded(
                child: chatProvider.isLoading &&
                        chatProvider.messages.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : chatProvider.messages.isEmpty
                        ? const Center(
                            child: Text('Henüz mesaj yok'),
                          )
                        : ListView.builder(
                            reverse: true,
                            controller: _scrollController,
                            itemCount: chatProvider.messages.length,
                            itemBuilder: (context, index) {
                              final message = chatProvider.messages[index];
                              return _buildMessageTile(
                                context,
                                message,
                                chatProvider,
                                authProvider,
                              );
                            },
                          ),
              ),

              // Mesaj Gönderme İnputu
              if (_userRestrictionType != 'blocked')
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: _userRestrictionType == 'muted'
                                ? 'Susturuldunuz - mesaj gönderemezsiniz'
                                : 'Mesaj yazınız...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          enabled: _userRestrictionType != 'muted',
                          maxLines: null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      FloatingActionButton(
                        mini: true,
                        onPressed: _userRestrictionType != 'muted'
                            ? () => _sendMessage(context, chatProvider,
                                authProvider)
                            : null,
                        child: const Icon(Icons.send),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Mesaj Tile
  Widget _buildMessageTile(
    BuildContext context,
    Map<String, dynamic> message,
    ChatProvider chatProvider,
    AuthProvider authProvider,
  ) {
    final isCurrentUser = message['user_id'] == authProvider.currentUser?.id;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment:
            isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isCurrentUser)
            CircleAvatar(
              radius: 16,
              child: Icon(Icons.person, size: 16),
            ),
          const SizedBox(width: 8),
          Flexible(
            child: GestureDetector(
              onLongPress: authProvider.isAdmin
                  ? () => _showMessageOptions(context, chatProvider, message)
                  : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isCurrentUser
                      ? Colors.blue[100]
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isCurrentUser)
                      Text(
                        message['username'] ?? 'Bilinmeyen',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    Text(
                      message['message'] ?? '',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(message['created_at']),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isCurrentUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  /// Mesaj Gönder
  void _sendMessage(
    BuildContext context,
    ChatProvider chatProvider,
    AuthProvider authProvider,
  ) async {
    if (_messageController.text.isEmpty) return;
    if (!authProvider.isLoggedIn) return;

    final message = _messageController.text;
    _messageController.clear();

    final success = await chatProvider.sendMessage(
      userId: authProvider.currentUser!.id,
      message: message,
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(chatProvider.error ?? 'Mesaj gönderme hatası'),
        ),
      );
    }
  }

  /// Mesaj Seçenekleri (Yönetici için)
  void _showMessageOptions(
    BuildContext context,
    ChatProvider chatProvider,
    Map<String, dynamic> message,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => ListView(
        shrinkWrap: true,
        children: [
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('Mesajı Sil'),
            onTap: () async {
              Navigator.pop(context);
              final success = await chatProvider.deleteMessage(
                messageId: message['id'],
                adminId: 'admin-user-id', // TODO: AuthProvider'dan al
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Mesaj silindi'
                          : 'Mesaj silme hatası',
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  /// Yönetici İşlemleri
  void _handleAdminAction(
    BuildContext context,
    ChatProvider chatProvider,
    String action,
  ) {
    if (action == 'settings') {
      _showSettingsDialog(context, chatProvider);
    } else if (action == 'clear') {
      _showClearConfirmDialog(context, chatProvider);
    }
  }

  /// Ayarlar Dialogu
  void _showSettingsDialog(
    BuildContext context,
    ChatProvider chatProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sohbet Ayarları'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Sohbeti Aç/Kapat'),
              value: chatProvider.isChatOpen,
              onChanged: (value) async {
                await chatProvider.toggleChat(isOpen: value);
                if (mounted) Navigator.pop(context);
              },
            ),
            SwitchListTile(
              title: const Text('Yavaş Modu Etkinleştir'),
              value: chatProvider.isSlowMode,
              onChanged: (value) async {
                await chatProvider.toggleSlowMode(
                  isSlowMode: value,
                  interval: '5m',
                );
                if (mounted) Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  /// Temizleme Onay Dialogu
  void _showClearConfirmDialog(
    BuildContext context,
    ChatProvider chatProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sohbeti Temizle'),
        content: const Text(
          'Tüm mesajlar silinecek. Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await chatProvider.clearChat();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Sohbet temizlendi'
                          : 'Sohbet temizleme hatası',
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Temizle'),
          ),
        ],
      ),
    );
  }

  /// İtiraz Dialogu
  void _showAppealDialog(
    BuildContext context,
    ChatProvider chatProvider,
  ) {
    final appealController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('İtiraz Et'),
        content: TextField(
          controller: appealController,
          minLines: 3,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'İtiraz nedenini açıklayınız',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              // TODO: restrictionId'yi doğru şekilde al
              // await chatProvider.submitAppeal(
              //   restrictionId: 1,
              //   appealMessage: appealController.text,
              // );
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('İtiraz gönderildi')),
                );
              }
            },
            child: const Text('Gönder'),
          ),
        ],
      ),
    );
  }

  /// Zamanı formatla
  String _formatTime(String? createdAt) {
    if (createdAt == null) return '';
    try {
      final dateTime = DateTime.parse(createdAt);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) return 'Şimdi';
      if (difference.inMinutes < 60) return '${difference.inMinutes}d önce';
      if (difference.inHours < 24) return '${difference.inHours}s önce';
      return '${difference.inDays}g önce';
    } catch (e) {
      return '';
    }
  }
}
