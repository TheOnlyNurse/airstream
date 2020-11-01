import 'package:airstream/data_providers/repository/repository.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

/// Internal Links
import '../models/image_adapter.dart';
import '../cubit/single_album_cubit.dart';
import '../complex_widgets/error_widgets.dart';
import '../static_assets.dart';
import '../widgets/flexible_image_with_title.dart';
import '../widgets/circle_close_button.dart';
import '../complex_widgets/song_list/sliver_song_list.dart';
import '../data_providers/moor_database.dart';
import '../repository/artist_repository.dart';
import '../widgets/future_button.dart';

class SingleAlbumScreen extends StatelessWidget {
  const SingleAlbumScreen({
    Key key,
    @required this.cubit,
  })  : assert(cubit != null),
        super(key: key);

  final SingleAlbumCubit cubit;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SingleAlbumCubit, SingleAlbumState>(
      cubit: cubit,
      builder: (_, state) {
        if (state is SingleAlbumInitial) {
          return Center(child: CircularProgressIndicator());
        }

        if (state is SingleAlbumSuccess) {
          return _Success(state, cubit: cubit);
        }

        if (state is SingleAlbumError) {
          return Center(child: Text('TODO: proper error screen'));
        }

        return NoStateErrorScreen(message: state.toString());
      },
    );
  }
}

class _Success extends StatelessWidget {
  const _Success(this.state, {Key key, this.cubit}) : super(key: key);

  final SingleAlbumSuccess state;
  final SingleAlbumCubit cubit;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: airstreamScrollPhysics,
      slivers: [
        SliverAppBar(
          expandedHeight: 400,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          stretch: true,
          stretchTriggerOffset: 200,
          flexibleSpace: FlexibleImageWithTitle(
            title: FutureButton<Artist>(
              future: GetIt.I.get<ArtistRepository>().byId(
                    state.album.artistId,
                  ),
              onTap: (response) => Navigator.pushReplacementNamed(
                context,
                'library/singleArtist',
                arguments: response,
              ),
              child: AutoSizeText(
                state.album.title,
                style: Theme.of(context).textTheme.headline4,
                maxLines: 2,
                textAlign: TextAlign.center,
              ),
            ),
            adapter: ImageAdapter(album: state.album, isHiDef: true),
          ),
          automaticallyImplyLeading: false,
          titleSpacing: 8,
          title: CircleCloseButton(),
          actions: [
            _StarButton(isStarred: state.album.isStarred, cubit: cubit),
            _MoreOptions(),
          ],
        ),
        SliverToBoxAdapter(child: _ShuffleButton(songs: state.songs)),
        SliverSongList(songs: state.songs),
      ],
    );
  }
}

class _ShuffleButton extends StatelessWidget {
  const _ShuffleButton({Key key, @required this.songs})
      : assert(songs != null),
        super(key: key);

  final List<Song> songs;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Center(
        child: RawMaterialButton(
          fillColor: Theme.of(context).buttonColor,
          constraints: BoxConstraints.tightFor(width: 200, height: 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          onPressed: () {
            songs.shuffle();
            Repository().audio.start(playlist: songs);
          },
          child: Text('Shuffle', style: Theme.of(context).textTheme.headline6),
        ),
      ),
    );
  }
}

class _StarButton extends StatefulWidget {
  const _StarButton({Key key, this.isStarred = false, @required this.cubit})
      : assert(cubit != null),
        super(key: key);

  final bool isStarred;
  final SingleAlbumCubit cubit;

  @override
  __StarButtonState createState() => __StarButtonState();
}

class __StarButtonState extends State<_StarButton> {
  bool isStarred;

  @override
  void initState() {
    isStarred = widget.isStarred;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return RawMaterialButton(
      constraints: BoxConstraints.tightFor(height: 55, width: 55),
      shape: CircleBorder(),
      onPressed: () {
        var newStarred = !isStarred;
        widget.cubit.change(newStarred);
        setState(() => isStarred = newStarred);
      },
      child: Icon(isStarred ? Icons.star : Icons.star_border),
    );
  }
}

class _MoreOptions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      icon: Icon(Icons.more_vert),
      itemBuilder: (_) => <PopupMenuEntry>[
        const PopupMenuItem(child: Text('Refresh album')),
      ],
      onSelected: (_) => null,
    );
  }
}
