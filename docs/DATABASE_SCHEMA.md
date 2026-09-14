# Supabase Veritabanı Şeması

Bu dokümanda, dijital yayın platformu için gerekli tüm veritabanı tabloları ve ilişkileri açıklanmıştır.

## 1. Sistem Tabloları

### 1.1 system_version - Uygulama Versiyonu Kontrol
Uygulamada versiyon uyumsuzluğu kontrolü için. Her açılışta bu tablo kontrol edilir.

```sql
CREATE TABLE system_version (
  id BIGSERIAL PRIMARY KEY,
  current_version VARCHAR(20) NOT NULL UNIQUE,  -- "1.0.0"
  required_version VARCHAR(20) NOT NULL,        -- Minimum gereken versiyon
  release_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  changelog TEXT,                                -- Yeniliklerin açıklaması
  download_url VARCHAR(500),                    -- APK indirilme linki
  force_update BOOLEAN DEFAULT FALSE,            -- Zorunlu güncelleme mi?
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```

---

## 2. Kimlik Doğrulama ve Kullanıcı Tabloları

### 2.1 users - Kullanıcı Hesapları
Tüm sistem kullanıcılarının ana tablosu.

```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT auth.uid(),
  username VARCHAR(50) UNIQUE NOT NULL,         -- Kullanıcı adı
  email VARCHAR(120) UNIQUE NOT NULL,           -- E-posta adresi
  password_hash VARCHAR(255) NOT NULL,          -- Şifreli parola
  phone_number VARCHAR(20),                     -- Telefon numarası
  avatar_url VARCHAR(500),                      -- Profil resmi
  bio TEXT,                                      -- Kullanıcı biyografisi
  
  -- Durum
  status VARCHAR(20) DEFAULT 'pending',         -- pending, approved, banned, suspended
  approval_status BOOLEAN DEFAULT FALSE,        -- Admin onayı
  approved_by UUID REFERENCES users(id),        -- Onaylayan yönetici
  approved_at TIMESTAMP WITH TIME ZONE,         -- Onay tarihi
  
  -- Engelleme/Banlanma
  ban_status VARCHAR(20),                       -- none, temporary, permanent
  ban_reason TEXT,
  ban_expires_at TIMESTAMP WITH TIME ZONE,
  ban_scope VARCHAR(50),                        -- 'system' (tamamen), 'tv', 'movies', 'chat' vb
  
  -- Sosyal Etkileşim Kontrol
  is_muted BOOLEAN DEFAULT FALSE,               -- Sohbette susturuldu mu?
  mute_expires_at TIMESTAMP WITH TIME ZONE,
  mute_reason TEXT,
  
  -- Tercihler
  remember_me_token VARCHAR(500),               -- Beni hatırla token
  remember_me_expires_at TIMESTAMP WITH TIME ZONE,
  
  -- Puan Sistemi
  total_points INT DEFAULT 0,                   -- Toplam kazanılan puan
  user_tier VARCHAR(50) DEFAULT 'yeni_uye',    -- Kullanıcı seviyesi
  
  -- Yönetici
  is_admin BOOLEAN DEFAULT FALSE,
  admin_role VARCHAR(50),                       -- 'root', 'admin', 'editor', 'moderator'
  ghost_mode BOOLEAN DEFAULT FALSE,             -- Hayalet mod (işlemler loglanmaz)
  
  -- Zaman Damgaları
  last_login TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  
  -- RLS Security
  CONSTRAINT check_valid_status CHECK (status IN ('pending', 'approved', 'banned', 'suspended'))
);

-- İndeksler
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_status ON users(status);
CREATE INDEX idx_users_admin_role ON users(admin_role);
```

### 2.2 user_tier_levels - Kullanıcı Seviyeleri
Dinamik kullanıcı seviyeleri tanımı.

```sql
CREATE TABLE user_tier_levels (
  id BIGSERIAL PRIMARY KEY,
  tier_name VARCHAR(50) UNIQUE NOT NULL,       -- "yeni_uye", "bronz", "gold" vb
  tier_display_name VARCHAR(100) NOT NULL,     -- "Yeni Üye", "Bronz Üye" vb
  min_points INT NOT NULL,                     -- Minimum puan
  max_points INT,                              -- Maksimum puan (NULL = sınırsız)
  benefits TEXT[],                             -- Özellikleri (JSONB olarak saklanabilir)
  color_code VARCHAR(7),                       -- Renk kodu (#RRGGBB)
  icon_url VARCHAR(500),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Başlangıç verileri
INSERT INTO user_tier_levels (tier_name, tier_display_name, min_points, max_points, color_code) VALUES
  ('yeni_uye', 'Yeni Üye', 0, 999, '#808080'),
  ('normal', 'Normal Üye', 1000, 2999, '#4CAF50'),
  ('bronz', 'Bronz Üye', 3000, 4999, '#CD7F32'),
  ('platin', 'Platin Üye', 5000, 9999, '#E5E4E2'),
  ('gold', 'Gold Üye', 10000, 49999, '#FFD700'),
  ('vip', 'VIP Üye', 50000, NULL, '#FF6B6B'),
  ('onursal', 'Onursal Üye', NULL, NULL, '#FFD700');
```

### 2.3 user_groups - Kullanıcı Grupları
Kullanıcıların ait oldukları gruplar (yetki seviyesi değil, kategori).

```sql
CREATE TABLE user_groups (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR(100) UNIQUE NOT NULL,
  description TEXT,
  permissions JSONB,                           -- Grup izinleri
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```

### 2.4 user_points - Puanlama Sistemi
Kullanıcıların kazandığı ve kaybettiği puanların kaydı.

```sql
CREATE TABLE user_points (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  action_type VARCHAR(50) NOT NULL,            -- watch_tv, watch_movie, comment vb
  points_earned INT NOT NULL,
  description TEXT,
  related_content_id VARCHAR(100),             -- TV kanal ID, film ID vb
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  
  CONSTRAINT check_action_type CHECK (action_type IN (
    'watch_tv_first_time', 'watch_tv_one_hour', 'watch_movie', 
    'watch_radio', 'comment_create', 'comment_like', 'chat_message'
  ))
);

CREATE INDEX idx_user_points_user_id ON user_points(user_id);
CREATE INDEX idx_user_points_created_at ON user_points(created_at);
```

### 2.5 points_config - Puan Konfigürasyonu
Dinamik puan sistemi ayarları (admin tarafından değiştirilebilir).

```sql
CREATE TABLE points_config (
  id BIGSERIAL PRIMARY KEY,
  action_type VARCHAR(50) UNIQUE NOT NULL,
  action_name VARCHAR(100) NOT NULL,
  points_value INT NOT NULL DEFAULT 0,
  description TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Başlangıç verileri
INSERT INTO points_config (action_type, action_name, points_value) VALUES
  ('watch_tv_first_time', 'TV Kanalını İlk İzlemek', 5),
  ('watch_tv_one_hour', 'TV Kanalını 1 Saat İzlemek', 60),
  ('watch_movie', 'Film İzlemek', 10),
  ('watch_radio', 'Radyo Dinlemek', 5),
  ('comment_create', 'Yorum Yapmak', 3),
  ('comment_like', 'Yoruma Beğeni', 1),
  ('chat_message', 'Sohbette Mesaj', 2);
```

---

## 3. İçerik Tabloları

### 3.1 tv_channel - TV Kanalları
Tüm TV kanallarının metadata ve yayın bilgileri.

```sql
CREATE TABLE tv_channel (
  id BIGSERIAL PRIMARY KEY,
  channel_name VARCHAR(100) NOT NULL,          -- Kanal adı
  channel_code VARCHAR(50) UNIQUE,             -- Kanal kodu (m3u8'de tvg-id)
  description TEXT,
  logo_url VARCHAR(500),                       -- Kanal logosu
  category VARCHAR(50),                        -- Kategori (Ulusal, Yerel, Spor vb)
  epg_url VARCHAR(500),                        -- EPG (Electronic Program Guide) linki
  
  -- Yayın Konfigürasyonu
  is_active BOOLEAN DEFAULT TRUE,
  is_encrypted BOOLEAN DEFAULT FALSE,          -- Şifreli mi?
  encryption_key VARCHAR(255),
  
  -- Erişim Kontrol
  allowed_user_tiers TEXT[],                   -- Hangi seviyelerin izleyebileceği
  
  -- Zaman Damgaları
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_tv_channel_is_active ON tv_channel(is_active);
CREATE INDEX idx_tv_channel_category ON tv_channel(category);
```

### 3.2 tv_channel_urls - TV Kanal Yayın Linkleri
Farklı kalitelerdeki yayın linkleri.

```sql
CREATE TABLE tv_channel_urls (
  id BIGSERIAL PRIMARY KEY,
  channel_id BIGINT NOT NULL REFERENCES tv_channel(id) ON DELETE CASCADE,
  
  -- Yayın Kaynağı
  source_name VARCHAR(100),                    -- "Resmi Kaynak", "Yedek Kaynak" vb
  source_url VARCHAR(500),
  
  -- Kalite Bilgisi
  quality VARCHAR(20) NOT NULL,                -- 'auto', '360p', '480p', '720p', '1080p' vb
  resolution VARCHAR(20),                      -- "1920x1080" vs.
  bandwidth INT,                               -- Bant genişliği
  
  -- URL Bilgisi
  stream_url VARCHAR(500) NOT NULL,            -- M3U8 yayın linki
  is_active BOOLEAN DEFAULT TRUE,
  
  -- Metadata
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  
  CONSTRAINT check_quality CHECK (quality IN ('auto', '360p', '480p', '720p', '1080p', '1440p', '2160p', '4320p'))
);

CREATE INDEX idx_tv_channel_urls_channel_id ON tv_channel_urls(channel_id);
CREATE INDEX idx_tv_channel_urls_quality ON tv_channel_urls(quality);
```

### 3.3 radio_channel - Radyo Kanalları
Radyo yayını bilgileri.

```sql
CREATE TABLE radio_channel (
  id BIGSERIAL PRIMARY KEY,
  channel_name VARCHAR(100) NOT NULL,
  description TEXT,
  logo_url VARCHAR(500),
  stream_url VARCHAR(500) NOT NULL,            -- Radyo yayın linki
  category VARCHAR(50),                        -- Müzik, Haber, Spor vb
  
  -- Yayında Çalan Şarkı Bilgisi (opsiyonel)
  current_song_api_url VARCHAR(500),           -- Şarkı bilgisini çeken API
  
  is_active BOOLEAN DEFAULT TRUE,
  
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_radio_channel_is_active ON radio_channel(is_active);
```

### 3.4 movies - Filmler ve Diziler
Film ve dizi içerikleri (ana tablo).

```sql
CREATE TABLE movies (
  id BIGSERIAL PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  description TEXT,
  poster_url VARCHAR(500),                     -- Film kapağı
  cover_url VARCHAR(500),
  
  -- Kategori Bilgisi
  content_type VARCHAR(50) NOT NULL,           -- 'cinema' (Sinema) veya 'series' (Dizi)
  genre_ids BIGINT[],                          -- Genre tablosuna referans
  
  -- Meta Bilgileri
  director VARCHAR(200),
  cast TEXT[],                                 -- Oyuncular
  release_date DATE,
  duration_minutes INT,                        -- Sinema için dakika
  
  -- Şifreleme ve Erişim
  is_encrypted BOOLEAN DEFAULT FALSE,
  allowed_user_tiers TEXT[],                   -- Hangi seviyelerin izleyebileceği
  
  -- Yorum ve Puan
  total_comments INT DEFAULT 0,
  average_rating DECIMAL(3,1) DEFAULT 0,      -- Ortalama puan (0-10)
  total_ratings INT DEFAULT 0,
  
  is_active BOOLEAN DEFAULT TRUE,
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  
  CONSTRAINT check_content_type CHECK (content_type IN ('cinema', 'series'))
);

CREATE INDEX idx_movies_content_type ON movies(content_type);
CREATE INDEX idx_movies_is_active ON movies(is_active);
```

### 3.5 movie_genres - Film Türleri
Dinamik film türü tanımı.

```sql
CREATE TABLE movie_genres (
  id BIGSERIAL PRIMARY KEY,
  genre_name VARCHAR(100) UNIQUE NOT NULL,    -- Fantastik, Bilim Kurgu, vb
  description TEXT,
  icon_url VARCHAR(500),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Başlangıç verileri
INSERT INTO movie_genres (genre_name) VALUES
  ('Fantastik'), ('Bilim Kurgu'), ('Romantizm'), ('Komedi'), 
  ('Polisiye'), ('Aksiyon'), ('Drama'), ('Korku'), ('Macera');
```

### 3.6 movie_seasons - Dizi Sezonları
Diziler için sezon bilgisi.

```sql
CREATE TABLE movie_seasons (
  id BIGSERIAL PRIMARY KEY,
  movie_id BIGINT NOT NULL REFERENCES movies(id) ON DELETE CASCADE,
  season_number INT NOT NULL,
  season_name VARCHAR(100),
  description TEXT,
  poster_url VARCHAR(500),                     -- Sezon kapağı
  air_date DATE,
  episode_count INT,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  
  CONSTRAINT unique_season UNIQUE(movie_id, season_number)
);

CREATE INDEX idx_movie_seasons_movie_id ON movie_seasons(movie_id);
```

### 3.7 movie_episodes - Dizi Bölümleri
Dizinin bölümleri.

```sql
CREATE TABLE movie_episodes (
  id BIGSERIAL PRIMARY KEY,
  season_id BIGINT NOT NULL REFERENCES movie_seasons(id) ON DELETE CASCADE,
  episode_number INT NOT NULL,
  episode_title VARCHAR(255),
  description TEXT,
  thumbnail_url VARCHAR(500),
  duration_minutes INT,
  
  -- Yayın Linkleri
  stream_urls JSONB,                           -- {"720p": "url", "1080p": "url"} formatında
  
  air_date DATE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  
  CONSTRAINT unique_episode UNIQUE(season_id, episode_number)
);

CREATE INDEX idx_movie_episodes_season_id ON movie_episodes(season_id);
```

### 3.8 movie_comments - Film Yorumları
Filmler ve diziler üzerine yapılan yorumlar.

```sql
CREATE TABLE movie_comments (
  id BIGSERIAL PRIMARY KEY,
  movie_id BIGINT NOT NULL REFERENCES movies(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  comment_text TEXT NOT NULL,
  rating INT,                                  -- 1-10 arası puan
  
  -- Sosyal Etkileşim
  likes INT DEFAULT 0,
  dislikes INT DEFAULT 0,
  
  is_edited BOOLEAN DEFAULT FALSE,
  edited_at TIMESTAMP WITH TIME ZONE,
  
  is_deleted BOOLEAN DEFAULT FALSE,
  deleted_by UUID REFERENCES users(id),
  deleted_at TIMESTAMP WITH TIME ZONE,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_movie_comments_movie_id ON movie_comments(movie_id);
CREATE INDEX idx_movie_comments_user_id ON movie_comments(user_id);
```

### 3.9 movie_comment_reactions - Yorum Reaksiyonları
Kullanıcıların yorumlara verdiği beğeni/dislike.

```sql
CREATE TABLE movie_comment_reactions (
  id BIGSERIAL PRIMARY KEY,
  comment_id BIGINT NOT NULL REFERENCES movie_comments(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  reaction_type VARCHAR(20) NOT NULL,         -- 'like', 'dislike'
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  
  CONSTRAINT unique_reaction UNIQUE(comment_id, user_id),
  CONSTRAINT check_reaction_type CHECK (reaction_type IN ('like', 'dislike'))
);

CREATE INDEX idx_comment_reactions_comment_id ON movie_comment_reactions(comment_id);
```

---

## 4. Sohbet Tabloları

### 4.1 chat - Sohbet Mesajları
Genel sohbet odası mesajları.

```sql
CREATE TABLE chat (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  message TEXT NOT NULL,
  
  -- Yönetim
  is_deleted BOOLEAN DEFAULT FALSE,
  deleted_by UUID REFERENCES users(id),
  deleted_at TIMESTAMP WITH TIME ZONE,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_chat_user_id ON chat(user_id);
CREATE INDEX idx_chat_created_at ON chat(created_at);
```

### 4.2 chat_settings - Sohbet Ayarları
Sohbet odasının yönetim ayarları.

```sql
CREATE TABLE chat_settings (
  id BIGSERIAL PRIMARY KEY,
  
  is_open BOOLEAN DEFAULT TRUE,                -- Sohbet açık mı?
  is_slow_mode BOOLEAN DEFAULT FALSE,          -- Yavaş mod aktif mi?
  slow_mode_interval VARCHAR(20),              -- '1m', '2m', '5m', '10m', '60m'
  
  -- Yavaş moddan muaf tutulacak gruplar
  exempt_user_tiers TEXT[],
  
  last_cleaned_at TIMESTAMP WITH TIME ZONE,    -- Son temizleme tarihi
  
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```

### 4.3 chat_user_restrictions - Sohbette Kullanıcı Kısıtlamaları
Kullanıcılara karşı alınan disiplin önlemleri.

```sql
CREATE TABLE chat_user_restrictions (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  restriction_type VARCHAR(50) NOT NULL,       -- 'muted', 'blocked'
  reason TEXT,
  restricted_by UUID REFERENCES users(id),
  
  expires_at TIMESTAMP WITH TIME ZONE,         -- NULL = kalıcı
  is_appealed BOOLEAN DEFAULT FALSE,
  appeal_message TEXT,
  appeal_resolved BOOLEAN DEFAULT FALSE,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  
  CONSTRAINT check_restriction_type CHECK (restriction_type IN ('muted', 'blocked'))
);

CREATE INDEX idx_chat_restrictions_user_id ON chat_user_restrictions(user_id);
```

---

## 5. Yönetim ve Raporlama Tabloları

### 5.1 reports - Kullanıcı Raporları
TV, Radyo, Film ve diğer içerikler hakkında raporlar.

```sql
CREATE TABLE reports (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  report_type VARCHAR(50) NOT NULL,            -- 'tv', 'radio', 'movie', 'user'
  report_category VARCHAR(100),                -- "Yayın Hatası", "İçerik Problemi" vb
  reported_content_id VARCHAR(100),            -- TV/Radyo/Film ID
  
  description TEXT NOT NULL,
  additional_notes TEXT,
  
  -- Yönetim
  status VARCHAR(20) DEFAULT 'pending',        -- 'pending', 'resolved', 'not_resolved'
  assigned_to UUID REFERENCES users(id),
  resolution_notes TEXT,
  resolved_at TIMESTAMP WITH TIME ZONE,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  
  CONSTRAINT check_report_type CHECK (report_type IN ('tv', 'radio', 'movie', 'user')),
  CONSTRAINT check_status CHECK (status IN ('pending', 'resolved', 'not_resolved'))
);

CREATE INDEX idx_reports_user_id ON reports(user_id);
CREATE INDEX idx_reports_status ON reports(status);
CREATE INDEX idx_reports_report_type ON reports(report_type);
```

### 5.2 admin_logs - Yönetici İşlem Logları
Yöneticilerin yaptığı tüm işlemler (ghost mode'da loglanmaz).

```sql
CREATE TABLE admin_logs (
  id BIGSERIAL PRIMARY KEY,
  admin_id UUID NOT NULL REFERENCES users(id),
  
  action_type VARCHAR(100) NOT NULL,           -- "user_approved", "tv_channel_added" vb
  action_description TEXT,
  affected_user_id UUID REFERENCES users(id),
  affected_content_id VARCHAR(100),
  
  changes_made JSONB,                          -- Yapılan değişikliklerin detayı
  ip_address INET,
  user_agent TEXT,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_admin_logs_admin_id ON admin_logs(admin_id);
CREATE INDEX idx_admin_logs_action_type ON admin_logs(action_type);
CREATE INDEX idx_admin_logs_created_at ON admin_logs(created_at);
```

### 5.3 user_logs - Kullanıcı İşlem Logları
Kullanıcıların yaptığı önemli işlemler.

```sql
CREATE TABLE user_logs (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  action_type VARCHAR(100) NOT NULL,           -- "watch_tv", "post_comment" vb
  action_description TEXT,
  content_id VARCHAR(100),                     -- İlgili içerik ID
  
  ip_address INET,
  device_info JSONB,                           -- Cihaz bilgileri
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_user_logs_user_id ON user_logs(user_id);
CREATE INDEX idx_user_logs_action_type ON user_logs(action_type);
CREATE INDEX idx_user_logs_created_at ON user_logs(created_at);
```

### 5.4 admin_roles - Yönetici Rolleri ve İzinleri
Yönetici rollerinin detaylı izin tanımlaması.

```sql
CREATE TABLE admin_roles (
  id BIGSERIAL PRIMARY KEY,
  role_name VARCHAR(50) UNIQUE NOT NULL,       -- 'root', 'admin', 'editor', 'moderator'
  role_display_name VARCHAR(100),
  description TEXT,
  
  -- İzinler (JSONB formatında)
  permissions JSONB NOT NULL,                  -- Tüm izinlerin listesi
  
  is_editable BOOLEAN DEFAULT TRUE,            -- Root dışında düzenlenebilir mi?
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Örnek permission yapısı:
-- {
--   "tv": {
--     "edit": true, "add": true, "delete": true,
--     "encrypt": true, "close": false
--   },
--   "radio": { ... },
--   "chat": { "manage": true, "delete_message": true, ... },
--   ...
-- }
```

### 5.5 admin_custom_permissions - Özel Yönetici İzinleri
Root'un diğer yöneticilere tanıyabileceği özel izinler.

```sql
CREATE TABLE admin_custom_permissions (
  id BIGSERIAL PRIMARY KEY,
  admin_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  -- Base permission'a ek özel izinler
  custom_permissions JSONB,
  
  granted_by UUID NOT NULL REFERENCES users(id),
  granted_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  
  CONSTRAINT only_root_can_grant CHECK (
    EXISTS(SELECT 1 FROM users WHERE id = granted_by AND admin_role = 'root')
  )
);

CREATE INDEX idx_custom_permissions_admin_id ON admin_custom_permissions(admin_id);
```

---

## 6. Bildirim Tabloları

### 6.1 notifications - Sistem Bildirimleri
Kullanıcılara gönderilen bildirimler.

```sql
CREATE TABLE notifications (
  id BIGSERIAL PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  content TEXT NOT NULL,
  notification_type VARCHAR(50),               -- 'update', 'maintenance', 'announcement' vb
  
  -- Gönderim Ayarları
  repeat_type VARCHAR(20) DEFAULT 'once',      -- 'once', 'every_6_hours', 'daily_3_days' vb
  repeat_limit INT,                            -- Kaç defa tekrarlanacak (NULL = sınırsız)
  
  repeat_count INT DEFAULT 0,                  -- Şu ana kadar kaç defa gönderildi
  last_sent_at TIMESTAMP WITH TIME ZONE,
  next_send_at TIMESTAMP WITH TIME ZONE,
  
  is_active BOOLEAN DEFAULT TRUE,
  
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_notifications_next_send_at ON notifications(next_send_at);
```

### 6.2 user_notification_status - Kullanıcı Bildirim Durumu
Her kullanıcının bildirim tercihini takip et.

```sql
CREATE TABLE user_notification_status (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  notification_id BIGINT NOT NULL REFERENCES notifications(id) ON DELETE CASCADE,
  
  is_sent BOOLEAN DEFAULT FALSE,
  is_read BOOLEAN DEFAULT FALSE,
  read_at TIMESTAMP WITH TIME ZONE,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  
  CONSTRAINT unique_user_notification UNIQUE(user_id, notification_id)
);

CREATE INDEX idx_user_notification_status_user_id ON user_notification_status(user_id);
```

---

## 7. Uygulama Yapılandırması

### 7.1 app_config - Genel Uygulama Ayarları
Platform geneline ait ayarlar.

```sql
CREATE TABLE app_config (
  id BIGSERIAL PRIMARY KEY,
  
  -- Sosyal Bağlantılar
  telegram_channel_url VARCHAR(500),
  website_url VARCHAR(500),
  instagram_url VARCHAR(500),
  twitter_url VARCHAR(500),
  facebook_url VARCHAR(500),
  
  -- Bakım Modu
  maintenance_mode BOOLEAN DEFAULT FALSE,
  maintenance_message TEXT,
  
  -- Diğer Ayarlar
  app_name VARCHAR(100) DEFAULT 'Digital Yayın Platformu',
  contact_email VARCHAR(120),
  
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_by UUID REFERENCES users(id)
);
```

---

## Veritabanı Oluşturma Adımları

1. Supabase Dashboard'da yeni bir project oluşturun
2. SQL Editor'da yukarıdaki tüm `CREATE TABLE` komutlarını çalıştırın
3. RLS (Row Level Security) politikalarını ayarlayın
4. Başlangıç verilerini (`INSERT` komutları) çalıştırın

## API Tasarımı (REST/GraphQL Uyumluluğu)

Tüm sorgular şu şekilde yapılandırılmıştır:
- **REST**: `/api/v1/resource` formatında
- **GraphQL**: Query/Mutation olarak tasarlanmıştır
- **Filters**: `?status=active&user_id=xxx` parametreleriyle
- **Pagination**: `limit` ve `offset` parametreleriyle

Bu yapı sayesinde veritabanı değişse bile API katmanını güncellemeniz yeterlidir.
