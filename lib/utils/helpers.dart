/// Uygulama Yardımcı Fonksiyonları
/// 
/// Uygulamada kullanılan genel yardımcı fonksiyonlar.

/// Tarihi formatla (Türkçe)
String formatDateTurkish(DateTime date) {
  const months = [
    'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
    'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
  ];

  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

/// Saati formatla
String formatTime(DateTime dateTime) {
  return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
}

/// Göreceli zamanı formatla ("2 saat önce" gibi)
String formatRelativeTime(DateTime dateTime) {
  final now = DateTime.now();
  final difference = now.difference(dateTime);

  if (difference.inSeconds < 60) return 'Az önce';
  if (difference.inMinutes < 60) return '${difference.inMinutes}d önce';
  if (difference.inHours < 24) return '${difference.inHours}s önce';
  if (difference.inDays < 7) return '${difference.inDays}g önce';

  return formatDateTurkish(dateTime);
}

/// Video süresini formatla (HH:MM:SS)
String formatDuration(Duration duration) {
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  final hours = twoDigits(duration.inHours);
  final minutes = twoDigits(duration.inMinutes.remainder(60));
  final seconds = twoDigits(duration.inSeconds.remainder(60));

  if (duration.inHours == 0) {
    return '$minutes:$seconds';
  }
  return '$hours:$minutes:$seconds';
}

/// Dosya boyutunu formatla (KB, MB, GB)
String formatFileSize(int bytes) {
  if (bytes <= 0) return '0 B';
  const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
  int i = (bytes.toString().length / 3).ceil() - 1;
  return (bytes / (1000 * i == 0 ? 1 : i)).toStringAsFixed(2) + ' ' + suffixes[i];
}

/// Email doğrulama
bool isValidEmail(String email) {
  final emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  return emailRegex.hasMatch(email);
}

/// Telefon numarası doğrulama (Türkçe)
bool isValidPhoneNumber(String phone) {
  final phoneRegex = RegExp(r'^(\+90|0)(5\d{2})\d{3}\d{2}\d{2}$');
  return phoneRegex.hasMatch(phone.replaceAll(' ', ''));
}

/// URL doğrulama
bool isValidUrl(String url) {
  final urlRegex = RegExp(
    r'^(https?:\/\/)?' +
    r'((([a-z\d]([a-z\d-]*[a-z\d])\.)+[a-z]{2,})|((\d{1,3}\.){3}\d{1,3}))' +
    r'(\/[-a-z\d%_.~+:]*)?' +
    r'(\?[;&a-z\d%_.~+=-]*)?' +
    r'(\#[-a-z\d_]*)?$',
  );
  return urlRegex.hasMatch(url);
}

/// Şifre gücü kontrol et
int getPasswordStrength(String password) {
  int strength = 0;
  if (password.length >= 8) strength++;
  if (password.contains(RegExp(r'[a-z]'))) strength++;
  if (password.contains(RegExp(r'[A-Z]'))) strength++;
  if (password.contains(RegExp(r'[0-9]'))) strength++;
  if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength++;
  return strength;
}

/// İçeriği kısalt (100 karakter)
String truncateText(String text, {int maxLength = 100}) {
  if (text.length <= maxLength) return text;
  return '${text.substring(0, maxLength)}...';
}

/// Metin tırnak işaretiyle kaplı mı kontrol et
bool isWrappedInQuotes(String text) {
  return (text.startsWith('"') && text.endsWith('"')) ||
      (text.startsWith("'") && text.endsWith("'"));
}

/// Metin boşluk içermiyor mu kontrol et
bool hasNoWhitespace(String text) {
  return !text.contains(RegExp(r'\s'));
}

/// Turkçe karakterleri dönüştür (URL uyumlu)
String turkishToUrl(String text) {
  return text
      .replaceAll('ç', 'c')
      .replaceAll('ğ', 'g')
      .replaceAll('ı', 'i')
      .replaceAll('ö', 'o')
      .replaceAll('ş', 's')
      .replaceAll('ü', 'u')
      .replaceAll('Ç', 'C')
      .replaceAll('Ğ', 'G')
      .replaceAll('İ', 'I')
      .replaceAll('Ö', 'O')
      .replaceAll('Ş', 'S')
      .replaceAll('Ü', 'U')
      .replaceAll(' ', '-')
      .toLowerCase();
}
