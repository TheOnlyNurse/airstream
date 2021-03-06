part of repository_library;

class _SongRepository {
  _SongRepository({@required this.dao}) : assert(dao != null);

  final SongsDao dao;

  /// Returns a song list (with on item) by id
  Future<SongResponse> byId(int id) {
    return dao.search(SongSearch.byId, argument: id);
  }

  /// Get songs in a given album
  Future<SongResponse> fromAlbum(Album album) {
    return dao.search(SongSearch.byAlbum, argument: album.id);
  }

  /// Convert playlist song id list to song details from database
  Future<SongResponse> fromPlaylist(Playlist playlist) async {
    final songList = <Song>[];
    ProviderResponse lastError;

    for (int id in playlist.songIds) {
      final query = await dao.search(SongSearch.byId, argument: id);
      if (query.hasNoData) {
        lastError = query;
        continue;
      }
      songList.add(query.songs.first);
    }

    if (songList.isNotEmpty) {
      return SongResponse(hasData: true, songs: songList);
    } else if (lastError != null) {
      return SongResponse(passOn: lastError);
    } else {
      return SongResponse(error: 'No songs found in playlist');
    }
  }

  Future<SongResponse> starred() => dao.starred();

  Future<SongResponse> topSongsOf(Artist artist) => dao.topSongsOf(artist);

  /// Searches both song titles and artist names
  /// Searches artist names
  ///  1. When searching song titles returns less than 5 results
  ///  2. When song titles returns no results
  Future<SongResponse> search({String query}) async {
    final titleQuery = await dao.search(SongSearch.byTitle, argument: query);
    if (titleQuery.hasData) {
      if (titleQuery.songs.length < 5) {
        return _onNotEnoughResults(titleQuery, query);
      } else {
				return titleQuery;
			}
		} else {
			return dao.search(SongSearch.byArtistName, argument: query);
		}
	}

	/// Searches artist name and combines the first query and the new query
	/// Complements the search function above and shouldn't be used alone
	Future<SongResponse> _onNotEnoughResults(SongResponse firstQuery,
			String query,) async {
		final artistQuery = await dao.search(
			SongSearch.byArtistName,
			argument: query,
		);
		if (artistQuery.hasNoData) return firstQuery;
		firstQuery.songs.addAll(artistQuery.songs);
		// Remove any duplicate data points & keep list order
		final combinedData = LinkedHashSet<Song>.from(firstQuery.songs).toList();
		return SongResponse(hasData: true, songs: combinedData);
	}
}
