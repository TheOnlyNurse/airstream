part of '../player_screen.dart';

class _HeaderButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        RawMaterialButton(
          constraints: const BoxConstraints.tightFor(width: 60, height: 60),
          shape: const CircleBorder(),
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
          child: const Icon(Icons.close),
        ),
        RawMaterialButton(
          constraints: const BoxConstraints.tightFor(width: 60, height: 60),
          shape: const CircleBorder(),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) {
                return QueueDialog();
              },
            );
          },
          child: const Icon(Icons.queue_music),
        ),
      ],
    );
  }
}