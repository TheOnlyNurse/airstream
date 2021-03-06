import 'package:airstream/data_providers/moor_database.dart';

import 'provider_response.dart';

class SongResponse extends ProviderResponse {
  final bool _hasData;
  final String _error;
  final ProviderResponse _passOn;
  final List<Song> songs;

  const SongResponse({
    bool hasData = false,
    ProviderResponse passOn,
    String error,
    this.songs,
  })

  /// If hasData defaults to false then passOn or error cannot equal both be null
  : _hasData = hasData,
        _error = error,
        _passOn = passOn,
        assert(
            !hasData ? passOn == null ? error != null : passOn != null : true);

  Song get song => songs.first;

  @override
  String get errorString => _passOn?.errorString ?? _error;

  @override
  String get source => _passOn?.source ?? 'Song Details';

  @override
  bool get hasData => _passOn?.hasData ?? _hasData;
}
