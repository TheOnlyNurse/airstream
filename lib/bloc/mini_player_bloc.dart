import 'package:airstream/barrel/bloc_basics.dart';
import 'package:airstream/events/mini_player_event.dart';
import 'package:airstream/states/mini_player_state.dart';

// Ease of use barrel
export 'package:airstream/events/mini_player_event.dart';
export 'package:airstream/states/mini_player_state.dart';

class MiniPlayerBloc extends Bloc<MiniPlayerEvent, MiniPlayerState> {
  final _repository = Repository();
  StreamSubscription _audioEvents;

  MiniPlayerBloc() :super(MiniPlayerInitial()) {
    _audioEvents = _repository.audio.playerState.listen((state) {
      switch (state) {
        case AudioPlayerState.playing:
          this.add(MiniPlayerPlaying());
          break;
        case AudioPlayerState.paused:
          this.add(MiniPlayerPaused());
          break;
        case AudioPlayerState.stopped:
          this.add(MiniPlayerStopped());
          break;
      }
    });
  }

  @override
  Stream<MiniPlayerState> mapEventToState(MiniPlayerEvent event) async* {
    final currentState = state;
    if (event is MiniPlayerPlayPause && currentState is MiniPlayerSuccess) {
      if (currentState.isPlaying) {
        _repository.audio.pause();
      } else {
        _repository.audio.play();
      }
    }

    if (event is MiniPlayerStopped) {
      yield MiniPlayerInitial();
    }
    if (event is MiniPlayerPlaying) {
      yield MiniPlayerSuccess(true);
    }
    if (event is MiniPlayerPaused) {
      yield MiniPlayerSuccess(false);
    }
  }

  @override
  Future<void> close() {
    _audioEvents.cancel();
    return super.close();
  }
}
