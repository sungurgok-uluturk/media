# Digital Yayın Platformu - Flutter Uygulaması

Çok platformlu sosyal etkileşimli dijital yayın uygulaması. Telefon, tablet ve Smart TV'lerde çalışabilir.

## Özellikler

- **Online Yayın**: TV, Radyo, Film
- **Sosyal Etkileşim**: Sohbet, Yorumlar, Puanlama
- **Offline Destek**: M3U8 listeleri ile IPTV yayınları
- **Yönetici Paneli**: Kapsamlı yönetim sistemi
- **Multi-Platform**: Telefonlar, Tabletler, Smart TV

## Teknoloji Stack

- **Frontend**: Flutter (Dart)
- **Platform**: Android Ecosystem
- **Backend**: Supabase (PostgreSQL)
- **Lokal Veritabanı**: SQLite
- **API**: REST API + GraphQL uyumlu
- **Media Player**: Video/Audio streaming

## Proje Yapısı

```
lib/
├── config/              # Konfigürasyon dosyaları
├── models/             # Veri modelleri
├── services/           # API ve veritabanı servisleri
├── repositories/       # Veri kaynaklarını yönetme
├── providers/          # State management (Provider)
├── screens/            # UI ekranları
│   ├── tv/
│   ├── radio/
│   ├── movies/
│   ├── chat/
│   └── settings/
├── widgets/            # Tekrar kullanılabilir bileşenler
├── utils/              # Yardımcı fonksiyonlar
└── main.dart          # Uygulama giriş noktası
```

## Başlangıç

1. Supabase konfigürasyonunu tamamlayın
2. Flutter paketlerini yükleyin
3. Veritabanı migrationlarını çalıştırın
4. Uygulamayı çalıştırın

## İlerleme

- [ ] Supabase veritabanı tasarımı
- [ ] Proje yapısı ve bağımlılıklar
- [ ] Kimlik doğrulama sistemi
- [ ] TV modülü
- [ ] Radyo modülü
- [ ] Film modülü
- [ ] Sohbet sistemi
- [ ] Yönetici paneli
- [ ] Offline desteği
