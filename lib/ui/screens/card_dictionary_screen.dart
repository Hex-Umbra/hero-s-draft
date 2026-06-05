import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import '../../services/game_data_service.dart';
import '../../models/data/card_data.dart';
import '../../models/data/relic_data.dart';
import '../widgets/ui_card.dart';

class CardDictionaryScreen extends ConsumerWidget {
  const CardDictionaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameDataAsync = ref.watch(gameDataLoaderProvider);
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF1E1E2C),
        appBar: AppBar(
          title: Text(
            locale == 'fr' ? 'Dictionnaire' : 'Dictionary',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.black45,
          elevation: 0,
          bottom: TabBar(
            indicatorColor: Colors.amber,
            labelColor: Colors.amber,
            unselectedLabelColor: Colors.white60,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            unselectedLabelStyle: const TextStyle(fontSize: 14),
            tabs: [
              Tab(text: locale == 'fr' ? 'Cartes' : 'Cards'),
              Tab(text: l10n.relics),
            ],
          ),
        ),
        body: gameDataAsync.when(
          data: (gameData) {
            return TabBarView(
              children: [
                _buildCardsTab(context, gameData.cards, locale),
                _buildRelicsTab(context, gameData.relics, locale),
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: Colors.amber),
          ),
          error: (err, stack) => Center(
            child: Text(
              'Erreur : $err',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardsTab(
    BuildContext context,
    List<CardData> allCards,
    String locale,
  ) {
    // Grouper par type pour la clarté
    final Map<CardType, List<CardData>> groupedCards = {};
    for (var card in allCards) {
      groupedCards.putIfAbsent(card.type, () => []).add(card);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: groupedCards.entries.map((group) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  _getTypeLabel(context, group.key),
                  style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent:
                      200, // Doublé pour un affichage plus clair
                  childAspectRatio: 0.7,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: group.value.length,
                itemBuilder: (context, index) {
                  final card = group.value[index];
                  return UiCard(
                    title: card.getName(locale),
                    description: card.getDescription(locale),
                    rarity: _getRarityLabel(context, card.rarity),
                    target: _getTargetLabel(context, card.target),
                    cost: card.cost,
                    type: card.type,
                    targetType: card.target,
                    isExhaust: card.isExhaust,
                    effects: card.effects,
                  );
                },
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRelicsTab(
    BuildContext context,
    List<RelicData> allRelics,
    String locale,
  ) {
    final Map<RelicRarity, List<RelicData>> groupedRelics = {};
    for (var rarity in RelicRarity.values) {
      groupedRelics[rarity] = [];
    }
    for (var relic in allRelics) {
      groupedRelics[relic.rarity]?.add(relic);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: RelicRarity.values.map((rarity) {
          final list = groupedRelics[rarity] ?? [];
          if (list.isEmpty) return const SizedBox.shrink();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  _getRelicRarityLabel(context, rarity),
                  style: TextStyle(
                    color: _getRelicRarityColor(rarity),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 320,
                  childAspectRatio: 2.2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final relic = list[index];
                  return _RelicDictionaryCard(relic: relic, locale: locale);
                },
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  String _getRelicRarityLabel(BuildContext context, RelicRarity rarity) {
    final l10n = AppLocalizations.of(context)!;
    switch (rarity) {
      case RelicRarity.common:
        return '${l10n.rarityCommon.toUpperCase()}S';
      case RelicRarity.uncommon:
        return '${l10n.rarityUncommon.toUpperCase()}S';
      case RelicRarity.rare:
        return '${l10n.rarityRare.toUpperCase()}S';
      case RelicRarity.epic:
        return '${l10n.rarityEpic.toUpperCase()}S';
      case RelicRarity.legendary:
        return '${l10n.rarityLegendary.toUpperCase()}S';
    }
  }

  Color _getRelicRarityColor(RelicRarity rarity) {
    switch (rarity) {
      case RelicRarity.common:
        return const Color(0xFF8E8E93);
      case RelicRarity.uncommon:
        return const Color(0xFF34C759);
      case RelicRarity.rare:
        return const Color(0xFF007AFF);
      case RelicRarity.epic:
        return const Color(0xFFAF52DE);
      case RelicRarity.legendary:
        return const Color(0xFFFFCC00);
    }
  }

  String _getTypeLabel(BuildContext context, CardType type) {
    final l10n = AppLocalizations.of(context)!;
    switch (type) {
      case CardType.attack:
        return '${l10n.cardTypeAttack.toUpperCase()}S';
      case CardType.skill:
        return '${l10n.cardTypeSkill.toUpperCase()}S';
      case CardType.power:
        return '${l10n.cardTypePower.toUpperCase()}S';
      case CardType.status:
        return l10n.statusCurses;
    }
  }

  String _getRarityLabel(BuildContext context, CardRarity rarity) {
    final l10n = AppLocalizations.of(context)!;
    switch (rarity) {
      case CardRarity.common:
        return l10n.rarityCommon;
      case CardRarity.uncommon:
        return l10n.rarityUncommon;
      case CardRarity.rare:
        return l10n.rarityRare;
      case CardRarity.epic:
        return l10n.rarityEpic;
      case CardRarity.legendary:
        return l10n.rarityLegendary;
      case CardRarity.unique:
        return 'Unique';
    }
  }

  String _getTargetLabel(BuildContext context, CardTarget target) {
    final l10n = AppLocalizations.of(context)!;
    switch (target) {
      case CardTarget.singleEnemy:
        return l10n.targetSingleEnemy;
      case CardTarget.allEnemies:
        return l10n.targetAllEnemies;
      case CardTarget.self:
        return l10n.targetSelf;
      case CardTarget.none:
        return l10n.targetNone;
    }
  }
}

class _RelicDictionaryCard extends StatelessWidget {
  final RelicData relic;
  final String locale;

  const _RelicDictionaryCard({required this.relic, required this.locale});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    Color triggerColor = Colors.grey;
    String triggerText = 'Passif';
    switch (relic.trigger) {
      case RelicTrigger.startOfRun:
        triggerText = l10n.relicTriggerRun;
        triggerColor = Colors.blueAccent;
        break;
      case RelicTrigger.startOfCombat:
        triggerText = l10n.relicTriggerCombat;
        triggerColor = Colors.redAccent;
        break;
      case RelicTrigger.startOfTurn:
        triggerText = l10n.relicTriggerTurnStart;
        triggerColor = Colors.greenAccent;
        break;
      case RelicTrigger.endOfTurn:
        triggerText = l10n.relicTriggerTurnEnd;
        triggerColor = Colors.amberAccent;
        break;
      case RelicTrigger.onCardPlayed:
        triggerText = l10n.relicTriggerCardPlayed;
        triggerColor = Colors.purpleAccent;
        break;
      case RelicTrigger.onEnemyKilled:
        triggerText = l10n.relicTriggerEnemyKilled;
        triggerColor = Colors.orangeAccent;
        break;
      case RelicTrigger.onAttackPlayed:
        triggerText = locale == 'fr' ? 'Attaque Jouée' : 'Attack Played';
        triggerColor = Colors.redAccent;
        break;
      case RelicTrigger.onSkillPlayed:
        triggerText = locale == 'fr' ? 'Compétence Jouée' : 'Skill Played';
        triggerColor = Colors.cyanAccent;
        break;
      case RelicTrigger.onPowerPlayed:
        triggerText = locale == 'fr' ? 'Pouvoir Joué' : 'Power Played';
        triggerColor = Colors.pinkAccent;
        break;
    }

    Color rarityColor = Colors.grey;
    String rarityText = l10n.rarityCommon;
    switch (relic.rarity) {
      case RelicRarity.common:
        rarityColor = const Color(0xFF8E8E93);
        rarityText = l10n.rarityCommon.toUpperCase();
        break;
      case RelicRarity.uncommon:
        rarityColor = const Color(0xFF34C759);
        rarityText = l10n.rarityUncommon.toUpperCase();
        break;
      case RelicRarity.rare:
        rarityColor = const Color(0xFF007AFF);
        rarityText = l10n.rarityRare.toUpperCase();
        break;
      case RelicRarity.epic:
        rarityColor = const Color(0xFFAF52DE);
        rarityText = l10n.rarityEpic.toUpperCase();
        break;
      case RelicRarity.legendary:
        rarityColor = const Color(0xFFFFCC00);
        rarityText = l10n.rarityLegendary.toUpperCase();
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: rarityColor.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(color: rarityColor.withValues(alpha: 0.15), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(relic.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  relic.getName(locale),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: triggerColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: triggerColor.withValues(alpha: 0.3),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  triggerText,
                  style: TextStyle(
                    color: triggerColor,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Text(
                relic.getDescription(locale),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  height: 1.3,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: rarityColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  rarityText,
                  style: TextStyle(
                    color: rarityColor,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
