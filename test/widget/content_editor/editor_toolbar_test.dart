import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/ui/widgets/content_editor/editor_app_bar.dart';

void main() {
  test('le depot se reduit a ses deux derniers dossiers', () {
    expect(shortRoot('C:/Users/moi/Jeux/roguelike_card_game'),
        '…/Jeux/roguelike_card_game');
    expect(shortRoot('/depot'), '/depot');
  });
}
