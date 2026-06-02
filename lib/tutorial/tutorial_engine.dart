import 'package:flutter/foundation.dart';

class TutorialCard {
  final String id;
  final String nameEn;
  final String nameFr;
  final int cost;
  final int damage;
  final int armor;
  final String? effectType; // 'poison', 'fire', 'ice', 'lightning'
  final bool isAoe;

  const TutorialCard({
    required this.id,
    required this.nameEn,
    required this.nameFr,
    required this.cost,
    required this.damage,
    required this.armor,
    this.effectType,
    this.isAoe = false,
  });
}

class TutorialEnemy {
  final String nameEn;
  final String nameFr;
  int hp;
  int maxHp;
  int armor;
  String intentIcon;
  int intentValue;
  List<String> activeStatuses;

  TutorialEnemy({
    required this.nameEn,
    required this.nameFr,
    required this.hp,
    required this.maxHp,
    required this.armor,
    required this.intentIcon,
    required this.intentValue,
    required this.activeStatuses,
  });
}

class TutorialMockState {
  int heroHp = 80;
  int heroMaxHp = 80;
  int heroMana = 3;
  int heroMaxMana = 3;
  int heroArmor = 0;
  List<TutorialCard> hand = [];
  List<TutorialCard> deck = [];
  TutorialEnemy? enemy;
  int playerXp = 0;
  int xpToNextLevel = 100;
  int playerLevel = 1;
  bool hasDrafted = false;

  void reset() {
    heroHp = 80;
    heroMaxHp = 80;
    heroMana = 3;
    heroMaxMana = 3;
    heroArmor = 0;
    hand = [];
    deck = [];
    enemy = null;
    playerXp = 0;
    xpToNextLevel = 100;
    playerLevel = 1;
    hasDrafted = false;
  }
}

class TutorialEngine extends ChangeNotifier {
  int _currentStepIndex = 0;
  final TutorialMockState mockState = TutorialMockState();

  int get currentStepIndex => _currentStepIndex;

  bool get isLastStep => _currentStepIndex == 12;

  void nextStep() {
    if (_currentStepIndex < 12) {
      _currentStepIndex++;
      resetMockState();
      notifyListeners();
    }
  }

  void prevStep() {
    if (_currentStepIndex > 0) {
      _currentStepIndex--;
      resetMockState();
      notifyListeners();
    }
  }

  void resetMockState() {
    mockState.reset();
    switch (_currentStepIndex) {
      case 4: // Step 5: Cards & Mana
        mockState.heroMana = 3;
        mockState.hand = [
          const TutorialCard(
            id: 'strike',
            nameEn: 'Basic Strike',
            nameFr: 'Frappe Basique',
            cost: 1,
            damage: 6,
            armor: 0,
          ),
          const TutorialCard(
            id: 'defend',
            nameEn: 'Defend',
            nameFr: 'Défense',
            cost: 1,
            damage: 0,
            armor: 4,
          ),
          const TutorialCard(
            id: 'fireball',
            nameEn: 'Fireball',
            nameFr: 'Boule de Feu',
            cost: 2,
            damage: 10,
            armor: 0,
            effectType: 'fire',
          ),
        ];
        break;
      case 5: // Step 6: Play Card
        mockState.heroMana = 3;
        mockState.hand = [
          const TutorialCard(
            id: 'strike',
            nameEn: 'Basic Strike',
            nameFr: 'Frappe Basique',
            cost: 1,
            damage: 6,
            armor: 0,
          ),
          const TutorialCard(
            id: 'defend',
            nameEn: 'Defend',
            nameFr: 'Défense',
            cost: 1,
            damage: 0,
            armor: 4,
          ),
        ];
        mockState.enemy = TutorialEnemy(
          nameEn: 'Tutorial Slime',
          nameFr: 'Slime d\'Entraînement',
          hp: 20,
          maxHp: 20,
          armor: 0,
          intentIcon: 'sword',
          intentValue: 5,
          activeStatuses: [],
        );
        break;
      case 6: // Step 7: Armor & Damage
        mockState.heroHp = 80;
        mockState.heroArmor = 0;
        mockState.enemy = TutorialEnemy(
          nameEn: 'Training Dummy',
          nameFr: 'Mannequin de Test',
          hp: 30,
          maxHp: 30,
          armor: 0,
          intentIcon: 'sword',
          intentValue: 10,
          activeStatuses: [],
        );
        break;
      case 9: // Step 10: Merge
        mockState.hand = [
          const TutorialCard(
            id: 'strike_1',
            nameEn: 'Basic Strike Lvl 1',
            nameFr: 'Frappe Basique Niv.1',
            cost: 1,
            damage: 6,
            armor: 0,
          ),
          const TutorialCard(
            id: 'strike_2',
            nameEn: 'Basic Strike Lvl 1',
            nameFr: 'Frappe Basique Niv.1',
            cost: 1,
            damage: 6,
            armor: 0,
          ),
          const TutorialCard(
            id: 'strike_3',
            nameEn: 'Basic Strike Lvl 1',
            nameFr: 'Frappe Basique Niv.1',
            cost: 1,
            damage: 6,
            armor: 0,
          ),
        ];
        break;
      case 10: // Step 11: XP
        mockState.playerXp = 0;
        mockState.playerLevel = 1;
        break;
      default:
        break;
    }
  }

  bool playCard(TutorialCard card) {
    if (mockState.heroMana < card.cost) return false;
    mockState.heroMana -= card.cost;
    mockState.hand.remove(card);

    final enemy = mockState.enemy;
    if (enemy != null) {
      if (card.damage > 0) {
        if (enemy.armor >= card.damage) {
          enemy.armor -= card.damage;
        } else {
          final remainingDamage = card.damage - enemy.armor;
          enemy.armor = 0;
          enemy.hp = (enemy.hp - remainingDamage).clamp(0, enemy.maxHp);
        }
      }
      if (card.armor > 0) {
        mockState.heroArmor += card.armor;
      }
    }
    notifyListeners();
    return true;
  }

  void simulateDamageTake({required bool withArmor}) {
    if (withArmor) {
      mockState.heroArmor = 4;
      mockState.heroHp = (mockState.heroHp - 6).clamp(0, mockState.heroMaxHp);
      mockState.heroArmor = 0;
    } else {
      mockState.heroArmor = 0;
      mockState.heroHp = (mockState.heroHp - 10).clamp(0, mockState.heroMaxHp);
    }
    notifyListeners();
  }

  void mergeCards() {
    mockState.hand = [
      const TutorialCard(
        id: 'strike_upgraded',
        nameEn: 'Basic Strike Lvl 2',
        nameFr: 'Frappe Basique Niv.2',
        cost: 1,
        damage: 9,
        armor: 0,
      ),
    ];
    notifyListeners();
  }

  void gainXp(int amount) {
    mockState.playerXp += amount;
    if (mockState.playerXp >= mockState.xpToNextLevel) {
      mockState.playerLevel++;
      mockState.playerXp = mockState.playerXp - mockState.xpToNextLevel;
    }
    notifyListeners();
  }
}

