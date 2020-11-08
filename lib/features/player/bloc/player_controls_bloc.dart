import 'dart:async';

import 'package:bloc/bloc.dart';

import '../../../common/providers/repository/repository.dart';
import '../../../common/repository/communication.dart';

enum PlayerControlsEvent {
  firstTrack,
  lastTrack,
  noNavigation,
  middleOfPlaylist
}

enum PlayerControlsState {
  noPrevious,
  noNext,
  noControls,
  allControls,
}

class PlayerControlsBloc
    extends Bloc<PlayerControlsEvent, PlayerControlsState> {

  PlayerControlsEvent _getControlEvent() {
    final listLength = Repository().audio.queueLength;
    final current = Repository().audio.index;
    if (listLength == 1) return PlayerControlsEvent.noNavigation;
    if (current == 0) return PlayerControlsEvent.firstTrack;
    if (current + 1 == listLength) return PlayerControlsEvent.lastTrack;
    return PlayerControlsEvent.middleOfPlaylist;
  }

  final _repository = Repository();

  PlayerControlsEvent _originalLayout;
  bool isRewindPossible = false;
  StreamSubscription _rewindPossible;
  StreamSubscription _newTracks;

  void _showRewindIsPossible() {
    switch (_originalLayout) {
      case PlayerControlsEvent.firstTrack:
        add(PlayerControlsEvent.middleOfPlaylist);
        break;
      case PlayerControlsEvent.noNavigation:
        add(PlayerControlsEvent.lastTrack);
        break;
      default:
        break;
    }
  }

  PlayerControlsBloc() : super(PlayerControlsState.noControls) {
    // Load initial layout (primer)
    _originalLayout = _getControlEvent();
    add(_originalLayout);

    _newTracks = _repository.audio.songState.listen((state) {
      if (state == AudioPlayerSongState.newSong) {
        // Get new control structure
        _originalLayout = _getControlEvent();
        add(_originalLayout);
        isRewindPossible = false;
      }
    });
    _rewindPossible = _repository.audio.audioPosition.listen((position) {
      if (position > const Duration(seconds: 5) && isRewindPossible == false) {
        _showRewindIsPossible();
        isRewindPossible = true;
      }
      if (position < const Duration(seconds: 5) && isRewindPossible) {
        isRewindPossible = false;
        add(_originalLayout);
      }
    });
  }

  @override
  Stream<PlayerControlsState> mapEventToState(
      PlayerControlsEvent event) async* {
    switch (event) {
      case PlayerControlsEvent.middleOfPlaylist:
        yield PlayerControlsState.allControls;
        break;
      case PlayerControlsEvent.firstTrack:
        yield PlayerControlsState.noPrevious;
        break;
      case PlayerControlsEvent.lastTrack:
        yield PlayerControlsState.noNext;
        break;
      case PlayerControlsEvent.noNavigation:
        yield PlayerControlsState.noControls;
        break;
    }
  }

  @override
  Future<void> close() {
    _newTracks.cancel();
    _rewindPossible.cancel();
    return super.close();
  }
}
