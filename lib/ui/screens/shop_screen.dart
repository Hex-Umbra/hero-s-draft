import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../game/controllers/run_controller.dart';
import '../../game/controllers/deck_controller.dart';
import '../../services/game_data_service.dart';
import '../../models/data/card_data.dart';
import '../../models/card_instance.dart';
import '../widgets/ui_card.dart';

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  bool _isInitialized = false;
  List<CardData> _cardsForSale = [];
  final List<CardData> _purchasedCards = [];
  bool _purchasedHeal = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _initializeShop();
      _isInitialized = true;
    }
  }

  void _initializeShop() {
    final gameData = ref.read(gameDataLoaderProvider).requireValue;
    // Filtrer pour ne pas vendre de statuts ou malédictions
    final allCards = gameData.cards.where((c) => c.type != CardType.status).toList();
    
    // Choisir 3 cartes aléatoires
    final rng = Random();
    List<CardData> shuffled = List.from(allCards)..shuffle(rng);
    _cardsForSale = shuffled.take(3).toList();
  }

  void _buyCard(CardData card, int price) {
    final runController = ref.read(runProvider.notifier);
    if (runController.spendGold(price)) {
      setState(() {
        _purchasedCards.add(card);
      });
      // Créer une instance et l'ajouter au deck
      final instance = CardInstance(data: card);
      ref.read(deckProvider.notifier).addCardToMasterDeck(instance);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Acheté : ${card.name}'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pas assez d\'or !'), backgroundColor: Colors.red),
      );
    }
  }

  void _buyHeal(int price, int amount) {
    final runController = ref.read(runProvider.notifier);
    final currentPv = ref.read(runProvider).heroStats.currentPv;
    final maxPv = ref.read(runProvider).heroStats.maxPv;
    
    if (currentPv >= maxPv) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vous avez déjà tous vos PV !'), backgroundColor: Colors.orange),
      );
      return;
    }

    if (runController.spendGold(price)) {
      setState(() {
        _purchasedHeal = true;
      });
      runController.heal(amount);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Soin appliqué !'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pas assez d\'or !'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final runState = ref.watch(runProvider);
    final int healPrice = 30;
    final int healAmount = (runState.heroStats.maxPv * 0.3).round();

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(
        title: const Text('Boutique', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black45,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.monetization_on, color: Colors.amber, size: 24),
                const SizedBox(width: 4),
                Text(
                  '${runState.gold}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber),
                ),
              ],
            ),
          )
        ],
        automaticallyImplyLeading: false, // Empêcher le retour sans compléter le nœud
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Cartes à vendre',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _cardsForSale.length,
                  itemBuilder: (context, index) {
                    final card = _cardsForSale[index];
                    final isPurchased = _purchasedCards.contains(card);
                    int price = 25;
                    if (card.rarity == CardRarity.uncommon) price = 50;
                    if (card.rarity == CardRarity.rare) price = 100;

                    return Padding(
                      padding: const EdgeInsets.only(right: 20),
                      child: Opacity(
                        opacity: isPurchased ? 0.3 : 1.0,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 150,
                              height: 220,
                              child: UiCard(
                                title: card.name,
                                description: card.description,
                                onTap: isPurchased ? null : () => _buyCard(card, price),
                              ),
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton.icon(
                              onPressed: isPurchased ? null : () => _buyCard(card, price),
                              icon: const Icon(Icons.monetization_on, color: Colors.amber, size: 18),
                              label: Text('$price', style: const TextStyle(fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black45,
                                foregroundColor: Colors.white,
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Divider(color: Colors.white24, height: 40),
              const Text(
                'Services',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Card(
                      color: Colors.black45,
                      child: ListTile(
                        leading: const Icon(Icons.local_hospital, color: Colors.greenAccent, size: 40),
                        title: const Text('Potion de Soin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Text('Restaure $healAmount PV', style: const TextStyle(color: Colors.white70)),
                        trailing: ElevatedButton.icon(
                          onPressed: _purchasedHeal ? null : () => _buyHeal(healPrice, healAmount),
                          icon: const Icon(Icons.monetization_on, color: Colors.amber, size: 18),
                          label: Text('$healPrice', style: const TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _purchasedHeal ? Colors.grey : Colors.green.shade800,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  ref.read(runProvider.notifier).completeCurrentNode();
                  Navigator.of(context).pop();
                },
                child: const Text('Quitter la boutique', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
