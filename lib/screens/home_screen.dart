import 'package:airstream/data_providers/repository/repository.dart';
import 'package:airstream/repository/album_repository.dart';
import 'package:airstream/repository/artist_repository.dart';
import 'package:airstream/widgets/home/collections.dart';
import 'package:airstream/widgets/home/playlists.dart';
import 'file:///D:/Home/Documents/FlutterProjects/airstream/lib/widgets/refresh_button.dart';
import 'package:airstream/widgets/home/search_bar.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen(
      {Key key,
      @required this.albumRepository,
      @required this.artistRepository})
      : assert(albumRepository != null),
        assert(artistRepository != null),
        super(key: key);

  final AlbumRepository albumRepository;
  final ArtistRepository artistRepository;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: CustomScrollView(
        physics: BouncingScrollPhysics(),
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: SearchBarLink(),
          ),
          _SliverTitle(
            title: 'Collections',
            onRefresh: () async {
              await albumRepository.forceSync();
              await artistRepository.forceSync();
            },
          ),
          SliverToBoxAdapter(
              child: Collections(
            albumRepository: albumRepository,
            artistRepository: artistRepository,
          )),
          _SliverTitle(
            title: 'Playlist',
            onRefresh: () async {
              await Repository().playlist.library(force: true);
            },
          ),
          Playlists(),
          SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    );
  }
}

class _SliverTitle extends StatelessWidget {
  final String title;
  final Future<Null> Function() onRefresh;

  const _SliverTitle({Key key, this.title, this.onRefresh}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.headline4),
            RefreshButton(onPressed: () => onRefresh())
          ],
        ),
      ),
    );
  }
}
