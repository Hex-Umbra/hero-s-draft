import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';

/// Mode debug de la run : declare au lancement, jamais deduit apres coup.
///
/// Une run debug ne persiste rien — ni ecriture, ni effacement. Le verrou est
/// pose dans `SaveService` lui-meme plutot qu'a chaque appelant, pour qu'un
/// futur bouton de sauvegarde ne puisse pas passer a cote.
@immutable
class DebugRunState {
  /// Vrai quand la run en cours a ete lancee par le bouton « Run Debug ».
  final bool isDebugRun;

  /// Vrai quand la *prochaine* run doit etre une run debug. Pose par le bouton
  /// de l'accueil, consomme par `startNewRun` — qui n'intervient que deux
  /// ecrans plus loin, apres le choix de classe et le draft de depart.
  final bool requested;

  const DebugRunState({this.isDebugRun = false, this.requested = false});

  DebugRunState copyWith({bool? isDebugRun, bool? requested}) => DebugRunState(
    isDebugRun: isDebugRun ?? this.isDebugRun,
    requested: requested ?? this.requested,
  );
}

class DebugRunNotifier extends Notifier<DebugRunState> {
  @override
  DebugRunState build() => const DebugRunState();

  /// Le bouton « Run Debug » de l'accueil.
  void requestDebugRun() => state = state.copyWith(requested: true);

  /// Le bouton « Jouer » de l'accueil.
  ///
  /// Chaque depart declare son intention : sans cela, une demande de run debug
  /// laissee en attente — bouton presse, puis retour a l'accueil — teindrait
  /// silencieusement la run normale suivante.
  void requestNormalRun() => state = state.copyWith(requested: false);

  /// Consomme la demande au moment ou la run nait.
  void applyRequestedMode() =>
      state = DebugRunState(isDebugRun: state.requested);

  /// Charger une sauvegarde, c'est par definition reprendre une run legitime :
  /// sans cela, enchainer une run debug puis « Continuer » priverait la vraie
  /// partie de toute sauvegarde.
  void clearForLoadedRun() => state = const DebugRunState();
}

final debugRunProvider = NotifierProvider<DebugRunNotifier, DebugRunState>(
  DebugRunNotifier.new,
);
