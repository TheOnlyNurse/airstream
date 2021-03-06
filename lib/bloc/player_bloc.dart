import 'package:airstream/barrel/bloc_basics.dart';
import 'package:airstream/events/player_events.dart';
import 'package:airstream/repository/album_repository.dart';
import 'package:airstream/repository/image_repository.dart';
import 'package:airstream/states/player_state.dart';
export 'package:airstream/events/player_events.dart';
export 'package:airstream/states/player_state.dart';

class PlayerBloc extends Bloc<PlayerEvent, PlayerState> {
  final _repository = Repository();
  final AlbumRepository albumRepository;
  final ImageRepository imageRepository;

  StreamSubscription _newSong;
  StreamSubscription _audioStopped;

  PlayerBloc({this.albumRepository, this.imageRepository}) : super(PlayerInitial(Repository().audio.current)) {
    _newSong = _repository.audio.songState.listen((state) {
      if (state == AudioPlayerSongState.newSong) {
        this.add(PlayerFetch());
      }
    });
    _audioStopped = _repository.audio.playerState.listen((state) {
      if (state == AudioPlayerState.stopped) {
        this.add(PlayerStopped());
      }
    });
  }

  @override
  Stream<PlayerState> mapEventToState(PlayerEvent event) async* {
    final currentState = state;

    if (event is PlayerFetch) {
      final song = _repository.audio.current;
      final response = await albumRepository.byId(song.albumId);
      if (response.hasData) {
        yield PlayerSuccess(song: song, album: response.data);
        this.add(PlayerFetchArt(song.art));
      }
    }

    if (event is PlayerFetchArt) {
      final response = await imageRepository.highDefinition(event.artId);
      if (response != null && currentState is PlayerSuccess) {
        yield currentState.copyWith(image: response);
      }
    }

    if (event is PlayerStopped) {
      yield PlayerSuccess(song: _repository.audio.current, isFinished: true);
    }
  }

  @override
  Future<void> close() {
    _audioStopped.cancel();
    _newSong.cancel();
    return super.close();
  }
}
