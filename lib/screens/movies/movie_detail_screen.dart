import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/movie_provider.dart';
import '../../providers/auth_provider.dart';

/// Film Detay Ekranı
/// 
/// Seçili filmin tüm detaylarını gösterir.
/// 
/// Yapısı:
/// - Film kapağı ve temel bilgiler
/// - İzle ve Fragmanı İzle butonları
/// - Sezon/Bölüm seçimi (dizi için)
/// - Yorumlar
/// - Rapor etme seçeneği

class MovieDetailScreen extends StatefulWidget {
  const MovieDetailScreen({Key? key}) : super(key: key);

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen>
    with SingleTickerProviderStateMixin {
  /// Tab controller
  late TabController _tabController;

  /// Yorum text controller
  late TextEditingController _commentController;

  /// Puan slider değeri
  double _rating = 5.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _commentController = TextEditingController();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<MovieProvider, AuthProvider>(
      builder: (context, movieProvider, authProvider, _) {
        final movie = movieProvider.selectedMovie;
        if (movie == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Film Detayları')),
            body: const Center(child: Text('Film seçilmedi')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Film Detayları'),
            centerTitle: true,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Kapak Resmi ve Butonlar
                _buildCoverSection(context, movie),
                const SizedBox(height: 20),

                // Film Bilgileri
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Başlık
                      Text(
                        movie.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Yönetmen ve Oyuncular
                      if (movie.director != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Text(
                            'Yönetmen: ${movie.director}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                      if (movie.cast != null && movie.cast!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            'Oyuncular: ${movie.cast!.join(", ")}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),

                      // Puan ve Yorum Sayısı
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${movie.averageRating.toStringAsFixed(1)}⭐',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${movie.totalRatings} kişi oyladı',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${movie.totalComments} Yorum',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Açıklama
                      if (movie.description != null) ...[const SizedBox(height: 12)],
                      if (movie.description != null)
                        Text(
                          movie.description!,
                          style: TextStyle(
                            height: 1.5,
                            color: Colors.grey[700],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Dizi Sezonları (dizi için)
                if (movie.isSeries) ...[_buildSeasonSelector(context, movieProvider)],

                // Tab Navigation
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(text: 'Yorumlar'),
                      Tab(text: 'Detaylar'),
                    ],
                  ),
                ),

                // Tab İçeriği
                SizedBox(
                  height: 400,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Yorumlar Tab
                      _buildCommentsTab(context, movieProvider, authProvider),
                      // Detaylar Tab
                      _buildDetailsTab(context, movie),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Kapak Resmi ve Butonlar
  Widget _buildCoverSection(BuildContext context, dynamic movie) {
    return Stack(
      children: [
        // Kapak Resmi
        if (movie.coverUrl != null)
          Container(
            width: double.infinity,
            height: 250,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(movie.coverUrl!),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                ),
              ),
            ),
          )
        else
          Container(
            width: double.infinity,
            height: 250,
            color: Colors.grey[300],
            child: const Icon(Icons.movie, size: 64),
          ),

        // Butonlar
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // İzle butonunun işlevi
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Oynatıcı açılacak')),
                    );
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('İzle'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Fragmanı izle
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Fragman oynatılacak')),
                    );
                  },
                  icon: const Icon(Icons.play_circle_outlined),
                  label: const Text('Fragmanı İzle'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Sezon Seçici (Dizi için)
  Widget _buildSeasonSelector(
    BuildContext context,
    MovieProvider movieProvider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: const Text(
            'Sezonlar',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: movieProvider.seasons.length,
            itemBuilder: (context, index) {
              final season = movieProvider.seasons[index];
              final isSelected =
                  movieProvider.selectedSeason?.id == season.id;

              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: FilterChip(
                  label: Text(
                    season.seasonName ?? 'Sezon ${season.seasonNumber}',
                  ),
                  selected: isSelected,
                  onSelected: (selected) async {
                    if (selected) {
                      await movieProvider.selectSeason(season);
                    }
                  },
                ),
              );
            },
          ),
        ),
        if (movieProvider.episodes.isNotEmpty) ...[const SizedBox(height: 12)],
        if (movieProvider.episodes.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: const Text(
              'Bölümler',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        if (movieProvider.episodes.isNotEmpty) ...[const SizedBox(height: 8)],
        if (movieProvider.episodes.isNotEmpty)
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: movieProvider.episodes.length,
              itemBuilder: (context, index) {
                final episode = movieProvider.episodes[index];
                final isSelected =
                    movieProvider.selectedEpisode?.id == episode.id;

                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text('B${episode.episodeNumber}'),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        movieProvider.selectEpisode(episode);
                      }
                    },
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 12),
      ],
    );
  }

  /// Yorumlar Tab
  Widget _buildCommentsTab(
    BuildContext context,
    MovieProvider movieProvider,
    AuthProvider authProvider,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Yorum Ekleme (Giriş yapmış ise)
        if (authProvider.isLoggedIn)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Yorum Yap'),
                const SizedBox(height: 8),
                TextField(
                  controller: _commentController,
                  minLines: 3,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Yorumunuzu yazınız...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Puan: ${_rating.toStringAsFixed(1)}⭐'),
                    Slider(
                      value: _rating,
                      min: 0,
                      max: 10,
                      onChanged: (value) {
                        setState(() => _rating = value);
                      },
                      flex: 1,
                    ),
                  ],
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_commentController.text.isNotEmpty) {
                        final success = await movieProvider.addComment(
                          userId: authProvider.currentUser!.id,
                          commentText: _commentController.text,
                          rating: _rating.toInt(),
                        );

                        if (mounted) {
                          if (success) {
                            _commentController.clear();
                            _rating = 5.0;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Yorum başarıyla eklendi'),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Yorum ekleme hatası'),
                              ),
                            );
                          }
                        }
                      }
                    },
                    child: const Text('Gönder'),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),

        // Mevcut Yorumlar
        const Text(
          'Yorumlar',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (movieProvider.comments.isEmpty)
          const Center(child: Text('Henüz yorum yok'))
        else
          ...movieProvider.comments
              .map((comment) => _buildCommentTile(comment, authProvider))
              .toList(),
      ],
    );
  }

  /// Yorum Tile
  Widget _buildCommentTile(
    Map<String, dynamic> comment,
    AuthProvider authProvider,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                comment['username'] ?? 'Bilinmeyen Kullanıcı',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (comment['rating'] != null)
                Text(
                  '${comment['rating']}⭐',
                  style: const TextStyle(color: Colors.orange),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
                comment['comment_text'] ?? '',
                style: const TextStyle(fontSize: 12),
              ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.thumb_up_outlined, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text('${comment['likes'] ?? 0}', style: const TextStyle(fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  /// Detaylar Tab
  Widget _buildDetailsTab(BuildContext context, dynamic movie) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildDetailRow('Tür:', movie.isSeries ? 'Dizi' : 'Sinema'),
        if (movie.releaseDate != null)
          _buildDetailRow(
            'Yayın Tarihi:',
            '${movie.releaseDate?.year}-${movie.releaseDate?.month.toString().padLeft(2, '0')}-${movie.releaseDate?.day.toString().padLeft(2, '0')}',
          ),
        if (movie.durationMinutes != null && movie.isCinema)
          _buildDetailRow('Süre:', '${movie.durationMinutes} dakika'),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () => _showReportDialog(context),
          icon: const Icon(Icons.flag),
          label: const Text('Sorunu Bildir'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.withOpacity(0.1),
            foregroundColor: Colors.red,
          ),
        ),
      ],
    );
  }

  /// Detay Satırı
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  /// Rapor Dialog'u
  void _showReportDialog(BuildContext context) {
    final reportController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sorunu Bildir'),
        content: TextField(
          controller: reportController,
          minLines: 3,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'Sorunu açıklayınız',
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
              final movieProvider = context.read<MovieProvider>();
              final authProvider = context.read<AuthProvider>();

              final success = await movieProvider.reportMovie(
                description: reportController.text,
                userId: authProvider.currentUser?.id ?? 'unknown',
              );

              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Rapor başarıyla gönderildi'
                          : 'Rapor gönderme hatası',
                    ),
                  ),
                );
              }
            },
            child: const Text('Gönder'),
          ),
        ],
      ),
    );
  }
}
