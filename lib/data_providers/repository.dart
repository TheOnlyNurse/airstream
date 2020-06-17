import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'package:airstream/data_providers/album_provider.dart';
import 'package:airstream/data_providers/artist_provider.dart';
import 'package:airstream/data_providers/audio_provider.dart';
import 'package:airstream/data_providers/image_cache_provider.dart';
import 'package:airstream/data_providers/playlist_provider.dart';
import 'package:airstream/data_providers/scheduler.dart';
import 'package:airstream/data_providers/settings_provider.dart';
import 'package:airstream/data_providers/song_provider.dart';
import 'package:airstream/models/album_model.dart';
import 'package:airstream/models/artist_model.dart';
import 'package:airstream/models/percentage_model.dart';
import 'package:airstream/models/playlist_model.dart';
import 'package:airstream/models/provider_response.dart';
import 'package:airstream/models/song_model.dart';
import 'package:airstream/widgets/song_list.dart';
import 'package:assets_audio_player/assets_audio_player.dart' as assets;
import 'package:flutter/material.dart';

/// The Repository collects data from providers and formats it for ease of access and use
/// in UI and Bloc generation.

class Repository {
  /// Instances
  final _instances = <String, dynamic>{
    'audio': _AudioRepo(),
    'song': _SongRepo(),
    'playlist': _PlaylistRepo(),
    'album': _AlbumRepo(),
    'artist': _ArtistRepo(),
    'settings': _SettingsRepo(),
    'image': _ImageRepo(),
  };

  /// Global Variables
  _AudioRepo get audio => _instances['audio'];

  _SongRepo get song => _instances['song'];

  _PlaylistRepo get playlist => _instances['playlist'];

  _AlbumRepo get album => _instances['album'];

  _ArtistRepo get artist => _instances['artist'];

  _SettingsRepo get settings => _instances['settings'];

  _ImageRepo get image => _instances['image'];

  /// Singleton boilerplate code
  static final Repository _instance = Repository._internal();

  Repository._internal();

  factory Repository() {
    return _instance;
  }
}

class RepoSettingsContainer {
  final int prefetch;
  final bool isOffline;
  final int imageCacheSize;
  final int musicCacheSize;

  RepoSettingsContainer(
      {this.prefetch, this.isOffline, this.imageCacheSize, this.musicCacheSize});
}

class _AudioRepo {
  Stream<PercentageModel> get percentageStream => AudioProvider().percentageSC.stream;

  int get index => AudioProvider().currentSongIndex;

  Song get current => AudioProvider().currentSong;

  int get playlistLength => AudioProvider().songQueue.length;

  assets.AssetsAudioPlayer get audioPlayer => AudioProvider().audioPlayer;

  void skipToNext() => AudioProvider().skipTo(1);

  void skipToPrevious() => AudioProvider().skipTo(-1);

  void play({@required List<Song> playlist, int index = 0}) =>
      AudioProvider().createQueueAndPlay(playlist, index);
}

class _SongRepo {
  /// Private
  final StreamController<SongChange> _songsChanged = StreamController.broadcast();

  /// Global Variables
  Stream<SongChange> get changed => _songsChanged.stream;

  /// Functions
  Future<ProviderResponse> starred({bool force = false}) async {
    if (force)
      return SongProvider().forceUpdateStarred();
    else
      return SongProvider().getStarred();
  }

  /// Get songs in a given album
  Future<ProviderResponse> listFromAlbum(Album album) => SongProvider().query(
    albumId: album.id,
    searchLimit: album.songCount,
  );

  Future<ProviderResponse> listFromPlaylist(Playlist playlist) async {
    final songList = <Song>[];
    ProviderResponse lastError;

    for (int id in playlist.songIds) {
      final list = await SongProvider().query(id: id, searchLimit: 1);
      if (list.status == DataStatus.ok) {
        assert(list.data is List<Song>);
        songList.add(list.data.first);
      } else {
        lastError = list;
      }
    }

    if (songList.isNotEmpty) {
      return ProviderResponse(status: DataStatus.ok, data: songList);
    } else if (lastError != null) {
      return lastError;
    } else {
      return ProviderResponse(
        status: DataStatus.error,
        source: ProviderSource.repository,
        message: 'no songs found in playlist',
      );
    }
  }

  Future<ProviderResponse> query({String query}) async {
    final songs = await SongProvider().query(title: query, searchLimit: 5);

    switch (songs.status) {
      case DataStatus.ok:
        if (songs.data.length < 5) {
          final artists = await SongProvider().query(artist: query, searchLimit: 5);

          switch (artists.status) {
            case DataStatus.ok:
              songs.data.addAll(artists.data);
              // Remove any duplicate data points & keep list order
              final combinedData = LinkedHashSet<Song>.from(songs.data).toList();
              return ProviderResponse(status: DataStatus.ok, data: combinedData);
              break;
            case DataStatus.error:
              return songs;
              break;
          }
        } else {
          return songs;
        }
        break;
      case DataStatus.error:
        final artists = await SongProvider().query(artist: query, searchLimit: 5);
        return artists;
        break;
    }

    throw UnimplementedError();
  }

  void star({@required List<Song> songList, bool toStar = false}) {
    for (var song in songList) {
      SongProvider().changeStar(song, toStar);
    }
    if (toStar)
      _songsChanged.add(SongChange.starred);
    else
      _songsChanged.add(SongChange.unstarred);
  }
}

class _PlaylistRepo {
  /// Private Variables
  final _provider = PlaylistProvider();
  final _scheduler = Scheduler();
  final StreamController<PlaylistChange> _onChange = StreamController.broadcast();

  /// Global Variables
  Stream<PlaylistChange> get changed => _onChange.stream;

  /// Global Functions
  Future<ProviderResponse> library() {
    return PlaylistProvider().library();
  }

  void removeSongs(Playlist playlist, List<int> indexList) async {
    for (int index in indexList) {
      _scheduler.schedule(
        'updatePlaylist?playlistId=${playlist.id}&songIndexToRemove=$index',
      );
    }
    await _provider.removeSong(playlist.id, indexList);
    _onChange.add(PlaylistChange.songsRemoved);
  }

  void addSongs(Playlist playlist, List<Song> songList) async {
    for (var song in songList) {
      _scheduler.schedule(
        'updatePlaylist?playlistId=${playlist.id}&songIdToAdd=${song.id}',
      );
    }
    await _provider.addSong(playlist.id, songList.map((e) => e.id).toList());
    _onChange.add(PlaylistChange.songsAdded);
  }
}

class _AlbumRepo {
  final provider = AlbumProvider();

  Future<ProviderResponse> library() => provider.library();

  Future<ProviderResponse> search({String query}) => provider.query(
        where: 'title LIKE ?',
        args: ['%$query%'],
        searchLimit: 5,
      );

  Future<ProviderResponse> fromArtist(Artist artist) => provider.query(
        where: 'artistId = ?',
        args: [artist.id],
        searchLimit: artist.albumCount,
      );

  Future<ProviderResponse> fromSong(Song song) => provider.query(
        where: 'id = ?',
        args: [song.albumId],
        searchLimit: 1,
      );

  Future<ProviderResponse> random(int limit) => provider.collection(
        CollectionType.random,
        limit: limit ?? 100,
      );

  Future<ProviderResponse> recent(int limit) =>
      provider.collection(
        CollectionType.recent,
        limit: limit ?? 100,
      );

  Future<ProviderResponse> byAlphabet() => provider.collection(CollectionType.alphabet);

  Future<ProviderResponse> allGenres() => provider.collection(CollectionType.allGenres);

  Future<ProviderResponse> genre(String genre) =>
      provider.query(
        where: 'genre = ?',
        args: [genre],
      );

  Future<ProviderResponse> decadesList() =>
      provider.collection(
        CollectionType.allDecades,
      );

  Future<ProviderResponse> decade(int decade) async {
    final albums = <Album>[];

    for (int year = 0; year < 10; year++) {
      final ProviderResponse results = await provider.query(
        where: 'year = ?',
        args: [decade + year],
      );
      if (results.status == DataStatus.ok) albums.addAll(results.data);
    }

    return ProviderResponse(status: DataStatus.ok, data: albums);
  }

  Future<ProviderResponse> mostPlayed() async => provider.played('frequent');

  Future<ProviderResponse> recentlyPlayed() async => provider.played('recent');
}

class _ArtistRepo {
  Future<ProviderResponse> library() => ArtistProvider().library();

  Future<ProviderResponse> query({String query}) => ArtistProvider().query(name: query);
}

class _SettingsRepo {
  Future<RepoSettingsContainer> get() async {
    final provider = SettingsProvider();
    return RepoSettingsContainer(
      prefetch: await provider.prefetchValue,
      isOffline: await provider.isOffline,
      imageCacheSize: await provider.imageCacheSize,
      musicCacheSize: await provider.musicCacheSize,
    );
  }

  void set(SettingsChangedType type, dynamic value) =>
      SettingsProvider().setSetting(type, value);

  Stream<bool> get changed => SettingsProvider().isOfflineChanged.stream;
}

class _ImageRepo {
  Future<ProviderResponse> fromArt(String artId, {isHiDef = false}) async {
    final imageResponse = await ImageCacheProvider().query(artId, isHiDef);
    if (imageResponse.status == DataStatus.error && isHiDef) {
      return fromArt(artId);
    } else {
      return imageResponse;
    }
  }

  Future<ProviderResponse> fromSongId(int songId) async {
    final songResponse = await SongProvider().query(id: songId, searchLimit: 1);
    if (songResponse.status == DataStatus.error) return songResponse;
    assert(songResponse.data is List<Song>);

    return fromArt(songResponse.data.first.art);
  }

  Future<ProviderResponse> collage(List<int> songIds) async {
    final imageList = <File>[];
    ProviderResponse lastError;

    for (int id in songIds) {
      final response = await fromSongId(id);
      if (response.status == DataStatus.ok) imageList.add(response.data);
      if (response.status == DataStatus.error) lastError = response;
    }

    if (imageList.isEmpty) {
      return lastError;
    } else {
      return ProviderResponse(status: DataStatus.ok, data: imageList);
    }
  }
}

enum SongChange { unstarred, starred }

enum PlaylistChange { songsRemoved, songsAdded, fetched }
