import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../common/repository/audio_repository.dart';
import '../bloc/player_controls_bloc.dart';
import '../widgets/play_button.dart';

class PlayerControls extends StatelessWidget {
  const PlayerControls({Key key, @required this.audioRepository})
      : super(key: key);
  final AudioRepository audioRepository;

  @override
  Widget build(BuildContext context) {
    final disabledColor = Theme.of(context).disabledColor;
    final enabledColor = Theme.of(context).iconTheme.color;

    bool _isPreviousEnabled(PlayerControlsState state) {
      switch (state) {
        case PlayerControlsState.noNext:
          return true;
          break;
        case PlayerControlsState.allControls:
          return true;
          break;
        default:
          return false;
      }
    }

    bool _isNextEnabled(PlayerControlsState state) {
      switch (state) {
        case PlayerControlsState.noPrevious:
          return true;
          break;
        case PlayerControlsState.allControls:
          return true;
          break;
        default:
          return false;
      }
    }

    return BlocProvider(
      create: (context) => PlayerControlsBloc(audioRepository: audioRepository),
      child: BlocBuilder<PlayerControlsBloc, PlayerControlsState>(
        builder: (context, state) {
          final isPrevious = _isPreviousEnabled(state);
          final isNext = _isNextEnabled(state);

          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _Button(
                onPressed: isPrevious ? () => audioRepository.previous() : null,
                iconData: Icons.skip_previous,
                isEnabled: isPrevious ? enabledColor : disabledColor,
              ),
              PlayButton(audioRepository: audioRepository),
              _Button(
                onPressed: isNext ? () => audioRepository.next() : null,
                iconData: Icons.skip_next,
                isEnabled: isNext ? enabledColor : disabledColor,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Button extends StatelessWidget {
  const _Button({Key key, this.onPressed, this.isEnabled, this.iconData})
      : super(key: key);
  final void Function() onPressed;
  final Color isEnabled;
  final IconData iconData;

  @override
  Widget build(BuildContext context) {
    return RawMaterialButton(
      shape: const CircleBorder(),
      onPressed: onPressed,
      child: Icon(iconData, size: 40.0, color: isEnabled),
    );
  }
}