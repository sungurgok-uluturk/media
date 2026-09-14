import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/movie_provider.dart';
import '../../models/movie_model.dart';
import 'movie_detail_screen.dart';

/// Film/Dizi Listeleme Ekranı
/// 
/// Filmleri ve dizileri listeler.
/// 
/// Yapısı:
/// - Kategori seçimi (Sinema, Dizi)
/// - Tür filtreleme
/// - Arama
/// - Liste ve ızgara görünümü
/// - Pagination

class MovieListScreen extends StatefulWidget {
  const MovieListScreen({Key? key}) : super(key: key);

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  /// Arama controller'ı
  late TextEditingController _searchController;

  /// Görünüm türü (list, grid)
  bool _isGridView = false;

  /// Seçili kategori
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();

    // İlk yüklemede filmleri getir
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MovieProvider>().loadMovies();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MovieProvider>(
      builder: (context, movieProvider, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Filmler ve Diziler'),
            centerTitle: true,
            elevation: 0,
            actions: [
              IconButton(
                icon: Icon(_isGridView ? Icons.list : Icons.grid_3x3),
                onPressed: () {
                  setState(() {
                    _isGridView = !_isGridView;
                  });
                },
              ),
            ],
          ),
          body: Column(
            children: [
              // Arama ve Filtreleme
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Kategori seçimi
                    Row(
                      children: [
                        Expanded(
                          child: SegmentedButton<String>(
                            segments: const <ButtonSegment<String>>[
                              ButtonSegment<String>(
                                value: 'all',
                                label: Text('Tümü'),
                              ),
                              ButtonSegment<String>(
                                value: 'cinema',
                                label: Text('Sinema'),
                              ),
                              ButtonSegment<String>(
                                value: 'series',
                                label: Text('Dizi'),
                              ),
                            ],
                            selected: <String>{
                              _selectedCategory ?? 'all'
                            },
                            onSelectionChanged: (Set<String> newSelection) {
                              setState(() {
                                _selectedCategory = newSelection.first;
                              });
                              if (_selectedCategory == 'all') {
                                movieProvider.loadMovies();
                              } else {
                                movieProvider
                                    .loadMovies(contentType: _selectedCategory);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Arama kutusu
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Film veya dizi ara...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  movieProvider.clearSearch();
                                  setState(() {});
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: (query) {
                        movieProvider.searchMovies(
                          query,
                          contentType: _selectedCategory == 'all'
                              ? null
                              : _selectedCategory,
                        );
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 12),

                    // Tür filtreleri
                    if (movieProvider.genres.isNotEmpty)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: movieProvider.genres
                              .map((genre) => Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: FilterChip(
                                      label: Text(genre['genre_name'] ?? 'Bilinmeyen'),
                                      onSelected: (selected) async {
                                        if (selected) {
                                          await movieProvider
                                              .loadMoviesByGenre(
                                            genre['id'],
                                            contentType: _selectedCategory ==
                                                    'all'
                                                ? null
                                                : _selectedCategory,
                                          );
                                        }
                                      },
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(),

              // Film listesi
              Expanded(
                child: movieProvider.isLoading &&
                        movieProvider.movies.isEmpty &&
                        movieProvider.searchResults.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : _buildMovieGrid(movieProvider),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Film listesini oluştur
  Widget _buildMovieGrid(MovieProvider movieProvider) {
    // Arama sonuçları varsa onları göster
    final movies = _searchController.text.isNotEmpty
        ? movieProvider.searchResults
        : movieProvider.movies;

    if (movies.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.movie_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isNotEmpty
                  ? 'Film bulunamadı'
                  : 'Film yükleniyor...',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    if (_isGridView) {
      return GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.7,
        ),
        itemCount: movies.length + (movieProvider.isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == movies.length) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final movie = movies[index];
          return MovieGridItem(
            movie: movie,
            onTap: () {
              context.read<MovieProvider>().selectMovie(movie);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MovieDetailScreen(),
                ),
              );
            },
          );
        },
      );
    } else {
      return ListView.builder(
        itemCount: movies.length + (movieProvider.isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == movies.length) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          final movie = movies[index];
          return MovieListItem(
            movie: movie,
            onTap: () {
              context.read<MovieProvider>().selectMovie(movie);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MovieDetailScreen(),
                ),
              );
            },
          );
        },
      );
    }
  }
}

/// Film Grid Item
class MovieGridItem extends StatelessWidget {
  final Movie movie;
  final VoidCallback onTap;

  const MovieGridItem({
    Key? key,
    required this.movie,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Poster
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (movie.posterUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        movie.posterUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.movie),
                          );
                        },
                      ),
                    )
                  else
                    Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.movie),
                    ),
                  // Puan
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${movie.averageRating.toStringAsFixed(1)}★',
                        style: const TextStyle(
                          color: Colors.yellow,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  // Yorum sayısı
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${movie.totalComments} 💬',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Başlık
          Text(
            movie.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Film List Item
class MovieListItem extends StatelessWidget {
  final Movie movie;
  final VoidCallback onTap;

  const MovieListItem({
    Key? key,
    required this.movie,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
        ),
        child: movie.posterUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  movie.posterUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.movie),
                    );
                  },
                ),
              )
            : Container(
                color: Colors.grey[300],
                child: const Icon(Icons.movie),
              ),
      ),
      title: Text(movie.title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (movie.director != null) Text('Yönetmen: ${movie.director}'),
          Text('Puan: ${movie.averageRating.toStringAsFixed(1)}★'),
        ],
      ),
      onTap: onTap,
    );
  }
}
