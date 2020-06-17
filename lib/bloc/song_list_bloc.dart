import 'dart:async';
import 'package:airstream/data_providers/repository.dart';
import 'package:airstream/events/song_list_event.dart';
import 'package:airstream/models/album_model.dart';
import 'package:airstream/models/playlist_model.dart';
import 'package:airstream/models/provider_response.dart';
import 'package:airstream/models/song_model.dart';
import 'package:airstream/states/song_list_state.dart';
import 'package:bloc/bloc.dart';

class SongListBloc extends Bloc<SongListEvent, SongListState> {
  Playlist playlist;
  Function(bool hasSelection) songsSelected;

  @override
  SongListState get initialState => SongListInitial();

  @override
  Stream<SongListState> mapEventToState(SongListEvent event) async* {
    final currentState = state;

    if (event is SongListFetch) {
      ProviderResponse response;
      songsSelected = event.callback;

      switch (event.type) {
        case SongListType.playlist:
          assert(event.typeValue is Playlist);
          playlist = event.typeValue;
          response = await Repository().song.listFromPlaylist(event.typeValue);
          break;
        case SongListType.album:
          assert(event.typeValue is Album);
          response = await Repository().song.listFromAlbum(event.typeValue);
          break;
        case SongListType.starred:
          assert(event.typeValue is List<Song>);
          response = ProviderResponse(status: DataStatus.ok, data: event.typeValue);
          break;
        case SongListType.search:
          assert(event.typeValue is List<Song>);
          response = ProviderResponse(status: DataStatus.ok, data: event.typeValue);
          break;
        default:
          throw UnimplementedError();
      }

      if (response.status == DataStatus.ok) {
        yield SongListSuccess(songList: response.data);
      } else {
        yield SongListFailure(response.message);
      }
    }

    if (currentState is SongListSuccess) {
      if (event is SongListSelection) {
        if (currentState.selected.contains(event.index)) {
          currentState.selected.remove(event.index);
        } else {
          currentState.selected.add(event.index);
        }

        if (songsSelected != null) {
          if (currentState.selected.isEmpty) {
            songsSelected(false);
          } else {
            songsSelected(true);
          }
        }

        yield currentState.copyWith(selected: currentState.selected);
      }

      if (event is SongListClearSelection) {
        if (songsSelected != null) {
          songsSelected(false);
        }

        yield currentState.copyWith(selected: []);
      }

      if (event is SongListStarSelection) {
        final starredSongs = <Song>[];

        for (int index in currentState.selected) {
          starredSongs.add(currentState.songList[index]);
        }

        Repository().song.star(songList: starredSongs, toStar: true);
        this.add(SongListClearSelection());
      }

      if (event is SongListPlaylistSelection) {
        final addedSongs = <Song>[];

        for (int index in currentState.selected) {
          addedSongs.add(currentState.songList[index]);
        }

        Repository().playlist.addSongs(event.playlist, addedSongs);
        this.add(SongListClearSelection());
      }

      if (event is SongListRemoveSelection) {
        final songList = currentState.songList;
        final removeMap = <int, Song>{};
        currentState.selected.sort((a, b) => b.compareTo(a));

        for (int index in currentState.selected) {
          removeMap[index] = currentState.songList[index];
          songList.remove(removeMap[index]);
        }

        if (playlist != null) {
          Repository().playlist.removeSongs(playlist, currentState.selected);
        } else {
          Repository().song.star(songList: removeMap.values.toList(), toStar: false);
        }

        yield currentState.copyWith(
          songList: songList,
          selected: [],
          removeMap: removeMap,
        );
      }
    }
  }
}

enum SongListType { album, playlist, starred, search }