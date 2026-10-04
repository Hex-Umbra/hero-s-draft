import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/ui/widgets/notification_overlay.dart';

/// Le plafond des notifications visibles (compte rendu de la vague 3, §2.3,
/// S6) : l'étape « or et XP » de la victoire empile ses messages dans la
/// même image, et aucun ne doit partir avant d'être vu.
void main() {
  ProviderContainer newContainer() {
    final container = ProviderContainer();
    // Démonter le conteneur annule les minuteurs de 3,5 s.
    addTearDown(container.dispose);
    return container;
  }

  List<String> messagesOf(ProviderContainer container) =>
      [for (final n in container.read(notificationProvider)) n.message];

  test('une elite a seconde carte et passage de niveau garde ses cinq '
      'messages, apres le remelange du dernier tour', () {
    final container = newContainer();
    final notifications = container.read(notificationProvider.notifier);
    // La fin du combat a laissé un message, déjà lu.
    notifications.show('🔄 Remélange de la défausse');

    const step = [
      '👑 RELIQUE OBTENUE : 📜 Registre des primes (RARE)',
      '⚔️ VICTOIRE ! +40 Or et +30 XP gagnés',
      '🃏 Carte trouvée : Frappe',
      '🃏 Carte trouvée : Défense',
      '🎉 LEVEL UP !',
    ];
    for (final message in step) {
      notifications.show(message);
    }

    expect(messagesOf(container), step);
  });

  test('un message au-dela du plafond retire le plus ancien, et lui seul', () {
    final container = newContainer();
    final notifications = container.read(notificationProvider.notifier);
    const count = NotificationNotifier.maxVisible + 1;

    for (var i = 1; i <= count; i++) {
      notifications.show('message $i');
    }

    expect(messagesOf(container), [
      for (var i = 2; i <= count; i++) 'message $i',
    ]);
  });
}
