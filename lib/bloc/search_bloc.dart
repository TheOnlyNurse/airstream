import 'package:airstream/barrel/bloc_basics.dart';
import 'package:airstream/data_providers/moor_database.dart';
import 'package:airstream/repository/album_repository.dart';
import 'package:airstream/repository/artist_repository.dart';
import 'package:flutter/material.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {

  SearchBloc({this.albumRepository, this.artistRepository}) : super(SearchInitial());

  final AlbumRepository albumRepository;
  final ArtistRepository artistRepository;
  final queryList = <String>[];
  Timer _timer;

  @override
  Stream<SearchState> mapEventToState(SearchEvent event) async* {
    if (event is SearchQuery) {
      yield SearchLoading();

      if (_timer != null) {
        _timer.cancel();
        _timer = null;
      }
      queryList.add(event.query);
      _timer =
          Timer(Duration(milliseconds: 600), () => this.add(SearchFetch()));
    }

    if (event is SearchFetch) {
      if (queryList.isNotEmpty) {
        final query = queryList.last;
        queryList.clear();
        if (query.length > 1) {
          final songResults = await Repository().song.search(query: query);
          final artistResults = await artistRepository.search(query);
          final albumResults = await albumRepository.search(query);
          final noResults = !songResults.hasData &&
              artistResults.hasError &&
              albumResults.hasError;
          if (noResults) {
            yield SearchFailure(songResults.error);
          } else {
            yield SearchSuccess(
              songs: songResults.songs ?? [],
              artists: artistResults.data ?? [],
              albums: albumResults.data ?? [],
            );
          }
        } else {
          yield SearchInitial();
        }
      }
    }
  }

  @override
  Future<void> close() {
    if (_timer != null) _timer.cancel();
    return super.close();
  }
}

abstract class SearchEvent {}

class SearchQuery extends SearchEvent {
  final String query;

  SearchQuery(this.query);
}

class SearchFetch extends SearchEvent {}

abstract class SearchState {}

class SearchInitial extends SearchState {}

class SearchLoading extends SearchState {}

class SearchSuccess extends SearchState {
	final List<Song> songs;
	final List<Album> albums;
	final List<Artist> artists;

	SearchSuccess({this.songs, this.albums, this.artists});
}

class SearchFailure extends SearchState {
  final Widget error;

  SearchFailure(this.error);
}
