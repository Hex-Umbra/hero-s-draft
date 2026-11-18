import 'package:roguelike_card_game/game/controllers/combat_controller.dart';

/// Le début de phase ennemie complet, tel que l'application l'enchaîne (spec
/// P-53, A12) : la fermeture du tour du joueur et la première vague du Feu,
/// les vagues suivantes jusqu'à la dernière, puis les autres statuts des
/// ennemis et le nettoyage des morts.
void runEnemyPhaseStart(CombatController combat) {
  combat.startEnemyTurn();
  while (combat.resolveNextFireWave()) {}
  combat.resolveEnemyStatuses();
}
