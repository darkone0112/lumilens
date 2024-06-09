import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'dart:math';
import 'movie_player_screen.dart';

enum ViewType { fullScreen, fullScreenSmooth, twoPerRow }

class PlaylistScreen extends StatefulWidget {
  final String email;
  const PlaylistScreen({super.key, required this.email});

  @override
  _PlaylistScreenState createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  ViewType _viewType = ViewType.twoPerRow;
  String _searchQuery = '';

  void _toggleViewType() {
    setState(() {
      if (MediaQuery.of(context).orientation == Orientation.landscape) {
        // Do nothing as carousel should only be accessible in landscape mode
      } else {
        _viewType = ViewType.values[(_viewType.index + 1) % ViewType.values.length];
      }
    });
  }

  void _updateSearchQuery(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  Future<void> _removeFromPlaylist(DocumentSnapshot movie) async {
    var movieId = movie.id;
    var userEmail = widget.email;
    var userDocRef = FirebaseFirestore.instance.collection('users').doc(userEmail);

    await userDocRef.collection('favorites').doc(movieId).delete();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${movie['title']} removed from your playlist')),
    );
  }

  Widget _buildMovieItem(BuildContext context, DocumentSnapshot movie) {
    var movieTitle = movie['title']; // Assuming 'title' holds the movie title
    var movieImageUrl = movie['image'];
    var backendUrl = 'http://bolshoi-burglars-cinema.duckdns.org/'; // Adjust the URL according to your backend
    var streamingUrl = Uri.parse('$backendUrl/stream/$movieTitle');

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => MoviePlayerScreen(movieUrl: streamingUrl),
          ),
        );
      },
      onDoubleTap: () => _removeFromPlaylist(movie), // Handle double-tap to remove from playlist
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: CachedNetworkImage(
          imageUrl: movieImageUrl,
          fit: BoxFit.cover, // Ensure the image occupies all available space
          placeholder: (context, url) => const CircularProgressIndicator(),
          errorWidget: (context, url, error) => const Icon(Icons.error),
        ),
      ),
    );
  }

  Widget _buildMovieView(QuerySnapshot snapshot) {
    List<DocumentSnapshot> movies = snapshot.docs;
    List<DocumentSnapshot> filteredMovies = movies.where((movie) {
      var movieTitle = movie['title'].toString().toLowerCase();
      return movieTitle.contains(_searchQuery.toLowerCase());
    }).toList();

    if (MediaQuery.of(context).orientation == Orientation.landscape) {
      return Center(
        child: CarouselSlider.builder(
          itemCount: filteredMovies.length,
          itemBuilder: (context, index, realIndex) => _buildMovieItem(context, filteredMovies[index]),
          options: CarouselOptions(
            height: MediaQuery.of(context).size.height * 0.8,
            viewportFraction: 0.3,
            enlargeCenterPage: true,
            enableInfiniteScroll: true,
            autoPlay: true,
            scrollPhysics: const BouncingScrollPhysics(),
          ),
        ),
      );
    }
    switch (_viewType) {
      case ViewType.twoPerRow:
        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1 / 1.5,
          ),
          itemCount: filteredMovies.length,
          itemBuilder: (context, index) => _buildMovieItem(context, filteredMovies[index]),
        );
      case ViewType.fullScreenSmooth:
      case ViewType.fullScreen:
      default:
        return PageView.builder(
          itemCount: filteredMovies.length,
          itemBuilder: (context, index) => _buildMovieItem(context, filteredMovies[index]),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).orientation == Orientation.portrait) {
      setState(() {
        _viewType = ViewType.twoPerRow;
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          decoration: const InputDecoration(
            hintText: 'Search Playlist...',
            hintStyle: TextStyle(color: Colors.white54),
            border: InputBorder.none,
          ),
          style: const TextStyle(color: Colors.white),
          onChanged: _updateSearchQuery,
        ),
        actions: [
          IconButton(
            icon: const Icon(FontAwesomeIcons.layerGroup),
            onPressed: _toggleViewType,
          ),
        ],
      ),
      body: Container(
        color: Colors.black, // Set background color to black
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(widget.email)
              .collection('favorites')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error.toString()}'));
            }
            if (snapshot.hasData) {
              return _buildMovieView(snapshot.data!);
            }
            return const Center(child: Text('No movies found in your playlist'));
          },
        ),
      ),
    );
  }
}
