import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

/// Internal
// Repositories
import '../../common/repository/album_repository.dart';
import '../../common/repository/artist_repository.dart';

// Blocs
import '../../common/bloc/mini_player_bloc.dart';
import '../../common/bloc/nav_bar_bloc.dart';
import '../../common/bloc/player_target_bloc.dart';
import '../album/bloc/album_cubit.dart';

// Widgets
import '../../common/complex_widgets/player/mini_player.dart';
import '../../common/complex_widgets/nav_bar.dart';

// Screens that can be navigated from the library
import '../../common/screens/album_list_screen.dart';
import '../home/home_screen.dart';
import '../../common/screens/single_playlist_screen.dart';
import '../starred/starred_screen.dart';
import '../../common/screens/single_artist_screen.dart';
import '../../common/repository/song_repository.dart';
import '../album/screen.dart';

/// Library
part 'widgets/pages.dart';

part 'widgets/route_transition.dart';

part 'widgets/routes.dart';

class LibraryFoundation extends StatelessWidget {
  const LibraryFoundation({Key key, this.navigatorKey}) : super(key: key);

  final GlobalKey<NavigatorState> navigatorKey;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<MiniPlayerBloc>(create: (_) => MiniPlayerBloc()),
        BlocProvider<PlayerTargetBloc>(create: (_) => PlayerTargetBloc()),
        BlocProvider<NavigationBarBloc>(
          create: (context) => NavigationBarBloc(
            playerBloc: context.bloc<MiniPlayerBloc>(),
            navigatorKey: navigatorKey,
          ),
        ),
      ],
      child: WillPopScope(
        onWillPop: () async {
          var navigatorState = navigatorKey.currentState;
          if (navigatorState.canPop()) {
            navigatorState.pop();
            return false;
          } else {
            return true;
          }
        },
        child: Scaffold(
          body: SafeArea(
            child: Stack(
              children: <Widget>[
                Navigator(
                  key: navigatorKey,
                  initialRoute: 'library/',
                  onGenerateRoute: _routeTransition,
                ),
                PlayerButtonTarget(),
              ],
            ),
          ),
          floatingActionButton: PlayerActionButton(),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          bottomNavigationBar: NavigationBar(),
        ),
      ),
    );
  }
}