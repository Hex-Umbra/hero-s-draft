import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import '../../game/controllers/run_controller.dart';
import '../../game/controllers/deck_controller.dart';
import '../../models/card_instance.dart';
import '../../models/data/card_data.dart';
import '../../models/data/hero_data.dart';
import '../../models/data/passive_data.dart';
import '../../services/game_data_service.dart';
import '../widgets/ui_card.dart';
import 'map_screen.dart';

class StarterDeckDraftScreen extends ConsumerStatefulWidget {
  final HeroData playerClass;
  final PassiveData passive;

  const StarterDeckDraftScreen({
    super.key,
    required this.playerClass,
    required this.passive,
  });

  @override
  ConsumerState<StarterDeckDraftScreen> createState() => _StarterDeckDraftScreenState();
}

class _StarterDeckDraftScreenState extends ConsumerState<StarterDeckDraftScreen> {
  late List<CardData> _draftPool;
  final Set<int> _selectedIndexes = {};
  bool _isPoolGenerated = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isPoolGenerated) {
      _generateDraftPool();
      _isPoolGenerated = true;
    }
  }

  void _generateDraftPool() {
    final gameData = ref.read(gameDataLoaderProvider).requireValue;
    
    // 1. Filtrer pour n'obtenir que les cartes globales non statut
    final globalCards = gameData.cards
        .where((c) => c.category == CardCategory.global && c.type != CardType.status)
        .toList();

    if (globalCards.isEmpty) {
      _draftPool = [];
      return;
    }

    final rng = Random();
    final List<CardData> pool = [];
    final Map<String, int> cardCounts = {};

    // 2. Tirer 10 cartes en respectant les raretés
    for (int i = 0; i < 10; i++) {
      CardData? chosenCard;
      int attempts = 0;

      while (chosenCard == null && attempts < 50) {
        attempts++;
        final rarity = _rollRarity(rng);
        
        // Filtrer les cartes globales de cette rareté
        var matchingCards = globalCards.where((c) => c.rarity == rarity).toList();
        
        // Si aucune carte de cette rareté n'existe, on tente les raretés inférieures en cascade
        if (matchingCards.isEmpty) {
          final fallbackOrder = [
            CardRarity.epic,
            CardRarity.rare,
            CardRarity.uncommon,
            CardRarity.common,
          ];
          for (var fallbackRarity in fallbackOrder) {
            matchingCards = globalCards.where((c) => c.rarity == fallbackRarity).toList();
            if (matchingCards.isNotEmpty) break;
          }
        }

        if (matchingCards.isNotEmpty) {
          final card = matchingCards[rng.nextInt(matchingCards.length)];
          final currentCount = cardCounts[card.id] ?? 0;

          // Règle du doublon max (pas plus de 2 copies d'une même carte dans le pool)
          if (currentCount < 2) {
            chosenCard = card;
            cardCounts[card.id] = currentCount + 1;
          }
        }
      }

      // Si après 50 essais on n'a rien trouvé, on prend n'importe quelle carte globale existante
      if (chosenCard == null && globalCards.isNotEmpty) {
        final card = globalCards[rng.nextInt(globalCards.length)];
        chosenCard = card;
        cardCounts[card.id] = (cardCounts[card.id] ?? 0) + 1;
      }

      if (chosenCard != null) {
        pool.add(chosenCard);
      }
    }

    setState(() {
      _draftPool = pool;
    });
  }

  CardRarity _rollRarity(Random rng) {
    final double roll = rng.nextDouble() * 100.0;
    
    // Seuils validés :
    // Commun : 60% (0.0 -> 60.0)
    // Peu Commun : 20% (60.0 -> 80.0)
    // Rare : 14% (80.0 -> 94.0)
    // Épique : 5% (94.0 -> 99.0)
    // Légendaire : 1% (99.0 -> 100.0)
    
    if (roll < 60.0) return CardRarity.common;
    if (roll < 80.0) return CardRarity.uncommon;
    if (roll < 94.0) return CardRarity.rare;
    if (roll < 99.0) return CardRarity.epic;
    return CardRarity.legendary;
  }

  void _toggleCardSelection(int index) {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      if (_selectedIndexes.contains(index)) {
        _selectedIndexes.remove(index);
      } else {
        if (_selectedIndexes.length < 5) {
          _selectedIndexes.add(index);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.draftDeckSnackbarMax),
              backgroundColor: Colors.orangeAccent,
              duration: const Duration(seconds: 1),
            ),
          );
        }
      }
    });
  }

  void _startAdventure() {
    if (_selectedIndexes.length != 5) return;

    final gameData = ref.read(gameDataLoaderProvider).requireValue;

    // 1. Récupérer toutes les cartes de classe du personnage (cartes persos auto-ajoutées)
    final classCards = gameData.cards
        .where((c) => c.category == CardCategory.characterSpecific && c.heroClass == widget.playerClass.id)
        .toList();

    // 2. Assembler le deck de départ (5 choisies + N de classe auto-ajoutées)
    final List<CardInstance> finalDeck = [];

    // Ajouter les cartes spécifiques de classe
    for (var cardData in classCards) {
      finalDeck.add(CardInstance(data: cardData));
    }

    // Ajouter les 5 cartes globales sélectionnées par index
    final selectedCards = _selectedIndexes.map((idx) => _draftPool[idx]).toList();
    for (var cardData in selectedCards) {
      finalDeck.add(CardInstance(data: cardData));
    }

    // 3. Initialiser les providers
    ref.read(deckProvider.notifier).clearDeck();
    ref.read(runProvider.notifier).startNewRun(widget.playerClass, widget.passive);
    ref.read(deckProvider.notifier).initializeStarterDeck(finalDeck);

    // 4. Redirection propre vers la map de jeu
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const MapScreen()),
      (route) => route.isFirst,
    );
  }

  String _getRarityLabel(CardRarity rarity) {
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
    }
  }

  String _getTargetLabel(CardTarget target) {
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

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    final locale = Localizations.localeOf(context).languageCode;
    final l10n = AppLocalizations.of(context)!;
    
    // Couleurs thématiques par classe
    Color classColor = Colors.blue;
    if (widget.playerClass.id == 'berserker') classColor = Colors.red;
    if (widget.playerClass.id == 'mage') classColor = Colors.purple;

    return Scaffold(
      backgroundColor: const Color(0xFF13131E),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 12.0 : 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // HEADER (Immersif & Thématique)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E2C).withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: classColor.withValues(alpha: 0.3), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: classColor.withValues(alpha: 0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      l10n.draftDeckTitle,
                      style: TextStyle(
                        fontSize: isMobile ? 22 : 28,
                        fontWeight: FontWeight.w900,
                        color: classColor,
                        letterSpacing: 1.5,
                        shadows: [
                          Shadow(
                            color: classColor.withValues(alpha: 0.5),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.draftDeckSubtitle,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: isMobile ? 11 : 14,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    // Badge Compteur
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: _selectedIndexes.length == 5 ? Colors.green.withValues(alpha: 0.2) : Colors.amber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _selectedIndexes.length == 5 ? Colors.green : Colors.amber.withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        l10n.draftDeckSelectedCount(_selectedIndexes.length),
                        style: TextStyle(
                          color: _selectedIndexes.length == 5 ? Colors.greenAccent : Colors.amberAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // GRID DE DRAFT
              Expanded(
                child: _draftPool.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.amber),
                      )
                    : GridView.builder(
                        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: isMobile ? 140 : 180,
                          childAspectRatio: 0.65,
                          crossAxisSpacing: isMobile ? 8 : 16,
                          mainAxisSpacing: isMobile ? 8 : 16,
                        ),
                        itemCount: _draftPool.length,
                        itemBuilder: (context, index) {
                          final card = _draftPool[index];
                          final isSelected = _selectedIndexes.contains(index);
                          final isMaxSelected = _selectedIndexes.length == 5;

                          return GestureDetector(
                            onTap: () => _toggleCardSelection(index),
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 200),
                              opacity: isSelected ? 1.0 : (isMaxSelected ? 0.4 : 1.0),
                              child: Stack(
                                children: [
                                  UiCard(
                                    title: card.getName(locale),
                                    description: card.getDescription(locale),
                                    cost: card.cost,
                                    effects: card.effects,
                                    level: 1,
                                    rarity: _getRarityLabel(card.rarity),
                                    target: _getTargetLabel(card.target),
                                    type: card.type,
                                    isExhaust: card.isExhaust,
                                    isSelected: isSelected,
                                  ),
                                  // Indicateur Checkmark
                                  if (isSelected)
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: classColor,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 1.5),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.5),
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 20),

              // BOUTON DE VALIDATION
              AnimatedScale(
                scale: _selectedIndexes.length == 5 ? 1.0 : 0.96,
                duration: const Duration(milliseconds: 150),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: _selectedIndexes.length == 5
                        ? [
                            BoxShadow(
                              color: classColor.withValues(alpha: 0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      backgroundColor: _selectedIndexes.length == 5 ? classColor : Colors.grey.shade800,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _selectedIndexes.length == 5 ? _startAdventure : null,
                    child: Text(
                      l10n.draftDeckProceed,
                      style: TextStyle(
                        fontSize: isMobile ? 16 : 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: _selectedIndexes.length == 5 ? Colors.white : Colors.white24,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
