import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import '../../game/controllers/deck_controller.dart';
import '../../models/card_instance.dart';
import '../../models/data/card_data.dart';
import '../widgets/ui_card.dart';
import '../widgets/notification_overlay.dart';

class DeckScreen extends ConsumerWidget {
  final bool allowMerge;
  const DeckScreen({super.key, this.allowMerge = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deckState = ref.watch(deckProvider);
    final masterDeck = deckState.masterDeck;
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;

    // Grouper les cartes pour identifier les fusions possibles
    final Map<String, List<CardInstance>> groups = {};
    for (var card in masterDeck) {
      final key = '${card.data.id}_${card.rarity.name}';
      groups.putIfAbsent(key, () => []).add(card);
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(
        title: Text(
          l10n.myDeck,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.black45,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.deckTotalCards(masterDeck.length),
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent:
                        200, // Doublé pour un affichage plus clair
                    childAspectRatio: 0.6,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: groups.keys.length,
                  itemBuilder: (context, index) {
                    final key = groups.keys.elementAt(index);
                    final cardList = groups[key]!;
                    final card = cardList.first;
                    final count = cardList.length;
                    final canMerge = count >= 3;

                    return Column(
                      children: [
                        Expanded(
                          child: Stack(
                            children: [
                              UiCard(
                                title: card.data.getName(locale),
                                description: card.data.getDescription(locale),
                                cost: card.data.cost,
                                target: _getTargetLabel(l10n, card.data.target),
                                rarityMultiplier: card.rarityMultiplier,
                                forgeUpgrades: card.forgeUpgrades,
                                effects: card.data.effects,
                                type: card.data.type,
                                isExhaust: card.data.isExhaust,
                                rarity: _getRarityLabel(context, card.rarity),
                              ),
                              Positioned(
                                top: 5,
                                right: 5,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Colors.amber,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    'x$count',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (card.rarity == CardRarity.unique)
                          const SizedBox.shrink()
                        else if (canMerge && allowMerge)
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                            onPressed: () {
                              _confirmMerge(context, ref, card, cardList);
                            },
                            child: Text(
                              l10n.mergeLabel(3),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        else if (canMerge && !allowMerge)
                          Text(
                            l10n.mergePossible,
                            style: const TextStyle(
                              color: Colors.orangeAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        else
                          Text(
                            l10n.mergeMoreRequired(3 - count),
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 10,
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

  String _getTargetLabel(AppLocalizations l10n, CardTarget target) {
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

  void _confirmMerge(BuildContext context, WidgetRef ref, CardInstance card, List<CardInstance> duplicates) async {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final cardName = card.data.getName(locale);

    final merged = await showDialog<bool>(
      context: context,
      builder: (ctx) => _MergeDialog(duplicates: duplicates, ref: ref),
    );

    if (merged == true) {
      if (context.mounted) {
        final nextRarityIndex = min(card.rarity.index + 1, CardRarity.values.length - 1);
        context.showNotification(
          l10n.deckMergeSuccess(cardName, nextRarityIndex + 1),
          type: NotificationType.success,
        );
      }
    }
  }
}

class _MergeDialog extends StatefulWidget {
  final List<CardInstance> duplicates;
  final WidgetRef ref;

  const _MergeDialog({
    required this.duplicates,
    required this.ref,
  });

  @override
  State<_MergeDialog> createState() => _MergeDialogState();
}

class _MergeDialogState extends State<_MergeDialog> {
  final Set<String> _selectedCardIds = {};
  int _step = 1;
  List<CardInstance> _selectedCards = [];
  List<String> _consolidatedUpgrades = [];
  final Set<String> _chosenUpgrades = {};
  late int _capacity;

  @override
  void initState() {
    super.initState();
    if (widget.duplicates.length == 3) {
      _selectedCardIds.addAll(widget.duplicates.map((c) => c.uniqueId));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _proceedToUpgrades();
      });
    }
  }

  void _proceedToUpgrades() {
    _selectedCards = widget.duplicates.where((c) => _selectedCardIds.contains(c.uniqueId)).toList();
    if (_selectedCards.length != 3) return;

    final firstCard = _selectedCards[0];
    final nextRarityIndex = min(firstCard.rarity.index + 1, CardRarity.values.length - 1);
    _capacity = firstCard.data.baseMaxForgeUpgrades + nextRarityIndex;

    final Map<String, int> consolidatedMap = {};
    for (var card in _selectedCards) {
      for (var upgrade in card.forgeUpgrades) {
        final parts = upgrade.split(':');
        if (parts.length != 2) continue;
        final id = parts[0];
        final tier = int.tryParse(parts[1]) ?? 0;
        if (tier <= 0) continue;
        consolidatedMap[id] = (consolidatedMap[id] ?? 0) + tier;
      }
    }

    _consolidatedUpgrades = [];
    consolidatedMap.forEach((id, tier) {
      _consolidatedUpgrades.add('$id:$tier');
    });

    if (_consolidatedUpgrades.length <= _capacity) {
      _performMerge(_consolidatedUpgrades);
    } else {
      setState(() {
        _step = 2;
      });
    }
  }

  void _performMerge(List<String> upgrades) {
    widget.ref.read(deckProvider.notifier).mergeCards(
      _selectedCards.map((c) => c.uniqueId).toList(),
      upgrades,
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;

    if (_step == 1) {
      return AlertDialog(
        backgroundColor: const Color(0xFF2A2A3D),
        title: Text(
          l10n.confirmMerge,
          style: const TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sélectionnez exactement 3 cartes à fusionner (Sélectionné: ${_selectedCardIds.length}/3)',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.duplicates.length,
                  itemBuilder: (context, index) {
                    final card = widget.duplicates[index];
                    final isSelected = _selectedCardIds.contains(card.uniqueId);
                    final upgradesText = card.forgeUpgrades.isEmpty
                        ? '(Sans amélioration)'
                        : card.forgeUpgrades.join(', ');
                    return CheckboxListTile(
                      title: Text(
                        '${card.data.getName(locale)} (${card.rarity.name.toUpperCase()})',
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        'Forge: $upgradesText',
                        style: const TextStyle(color: Colors.white54),
                      ),
                      value: isSelected,
                      activeColor: Colors.green,
                      checkColor: Colors.black,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            if (_selectedCardIds.length < 3) {
                              _selectedCardIds.add(card.uniqueId);
                            }
                          } else {
                            _selectedCardIds.remove(card.uniqueId);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              l10n.cancel,
              style: const TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _selectedCardIds.length == 3 ? Colors.green : Colors.grey,
            ),
            onPressed: _selectedCardIds.length == 3 ? _proceedToUpgrades : null,
            child: const Text('Continuer'),
          ),
        ],
      );
    } else {
      return AlertDialog(
        backgroundColor: const Color(0xFF2A2A3D),
        title: const Text(
          'Capacité de Forge Dépassée',
          style: TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'La rareté supérieure ne supporte que $_capacity améliorations.\nChoisissez lesquelles conserver (Sélectionné: ${_chosenUpgrades.length}/$_capacity) :',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _consolidatedUpgrades.length,
                  itemBuilder: (context, index) {
                    final upgrade = _consolidatedUpgrades[index];
                    final parts = upgrade.split(':');
                    final id = parts[0];
                    final tier = parts[1];
                    final isSelected = _chosenUpgrades.contains(upgrade);
                    return CheckboxListTile(
                      title: Text(
                        '${id.toUpperCase()} (Niveau $tier)',
                        style: const TextStyle(color: Colors.white),
                      ),
                      value: isSelected,
                      activeColor: Colors.green,
                      checkColor: Colors.black,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            if (_chosenUpgrades.length < _capacity) {
                              _chosenUpgrades.add(upgrade);
                            }
                          } else {
                            _chosenUpgrades.remove(upgrade);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              l10n.cancel,
              style: const TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _chosenUpgrades.length <= _capacity ? Colors.green : Colors.grey,
            ),
            onPressed: _chosenUpgrades.isNotEmpty && _chosenUpgrades.length <= _capacity ? () {
              _performMerge(_chosenUpgrades.toList());
            } : null,
            child: const Text('Fusionner'),
          ),
        ],
      );
    }
  }
}
