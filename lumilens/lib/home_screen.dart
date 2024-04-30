import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
          itemBuilder: (context, index) {
            return Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  Expanded(
                    child: CachedNetworkImage(
                      imageUrl: movies[index]['image'],
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const CircularProgressIndicator(),
                      errorWidget: (context, url, error) => const Icon(Icons.error),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(movies[index]['title']),
                  ),
                ],
              ),
            );
          },
        );
      case ViewType.listView:
        return ListView.builder(
          itemCount: movies.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(movies[index]['title']),
            );
          },
        );
      case ViewType.fullScreenSmooth:
        return PageView.builder(
          itemCount: movies.length,
          controller: PageController(viewportFraction: 0.8),
          itemBuilder: (context, index) {
            return Container(
              color: Colors.black,
              child: Center(
                child: CachedNetworkImage(
                  imageUrl: movies[index]['image'],
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const CircularProgressIndicator(),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              ),
            );
          },
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        );
      case ViewType.fullScreen:
      default:
        return PageView.builder(
          itemCount: movies.length,
          itemBuilder: (context, index) {
            return Container(
              color: Colors.black,
              child: Center(
                child: CachedNetworkImage(
                  imageUrl: movies[index]['image'],
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const CircularProgressIndicator(),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              ),
            );
          },
        );
    }
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
            onPressed: () {
              // Settings action
            },
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
