import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'movie_player_screen.dart';
import 'settings_modal.dart';  // Ensure this is pointing to the correct file

enum ViewType { fullScreen, fullScreenSmooth, twoPerRow, listView }

class HomeScreen extends StatefulWidget {
  final String email;
  const HomeScreen({super.key, required this.email});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ViewType _viewType = ViewType.fullScreen;

  void _toggleViewType() {
    setState(() {
      _viewType = ViewType.values[(_viewType.index + 1) % ViewType.values.length];
    });
  }

Widget _buildMovieItem(BuildContext context, DocumentSnapshot movie) {
  var movieTitle = movie['title']; // Assuming 'title' holds the movie title
  var movieImageUrl = movie['image'];
  var backendUrl = 'http://bolshoi-burglars-cinema.duckdns.org/'; // Localhost for Android emulator
  var streamingUrl = Uri.parse('$backendUrl/stream/$movieTitle'); // Adjust the path according to your Django backend

  return GestureDetector(
    onTap: () {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => MoviePlayerScreen(movieUrl: streamingUrl),
        ),
      );
    },
    child: Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Expanded(
            child: CachedNetworkImage(
              imageUrl: movieImageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => const CircularProgressIndicator(),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(movieTitle),
          ),
        ],
      ),
    ),
  );
}

Widget _buildMovieView(QuerySnapshot snapshot) {
  List<DocumentSnapshot> movies = snapshot.docs;
  switch (_viewType) {
    case ViewType.twoPerRow:
      return GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1 / 1.5,
        ),
        itemCount: movies.length,
        itemBuilder: (context, index) => _buildMovieItem(context, movies[index]),
      );
    case ViewType.listView:
      return ListView.builder(
        itemCount: movies.length,
        itemBuilder: (context, index) => _buildMovieItem(context, movies[index]),
      );
    case ViewType.fullScreenSmooth:
    case ViewType.fullScreen:
    default:
      return PageView.builder(
        itemCount: movies.length,
        itemBuilder: (context, index) => _buildMovieItem(context, movies[index]),
      );
  }
}



  void _showSettingsModal() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const SettingsModal();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Library'),
        actions: [
          IconButton(
            icon: const Icon(FontAwesomeIcons.layerGroup),
            onPressed: _toggleViewType,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettingsModal,  // Call to show the settings modal
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('movies').snapshots(),
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
          return const Center(child: Text('No movies found'));
        },
      ),
    );
  }
}
