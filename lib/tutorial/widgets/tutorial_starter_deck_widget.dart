import 'package:flutter/material.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';

import '../../models/data/card_data.dart';
import '../../ui/widgets/ui_card.dart';
import '../tutorial_engine.dart';

/// Étape 03 — draft du deck de départ.
///
/// Le pool est celui de `StarterDeckDraftScreen` : cartes globales non-statut.
/// Les cartes s'affichent avec le vrai [UiCard], donc le vrai médaillon de
/// mana et les vrais badges d'effets.
class TutorialStarterDeckWidget extends StatefulWidget {
  final TutorialEngine engine;

  const TutorialStarterDeckWidget({super.key, required this.engine});

  @override
  State<TutorialStarterDeckWidget> createState() =>
      _TutorialStarterDeckWidgetState();
}

class _TutorialStarterDeckWidgetState extends State<TutorialStarterDeckWidget> {
  static const int _target = 5;
  final List<CardData> _selected = [];

  void _toggle(CardData card) {
    setState(() {
      if (_selected.remove(card)) return;
      if (_selected.length < _target) _selected.add(card);
    });
    widget.engine.setStarterDeck(_selected.length == _target ? _selected : []);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final isFrench = locale == 'fr';
    final pool = widget.engine.fixtures.starterPool;
    final classCards = widget.engine.mockState.chosenHero?.skills
            .map(widget.engine.fixtures.card)
            .toList() ??
        const <CardData>[];

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isFrench ? 'Choisissez 5 cartes' : 'Pick 5 cards',
                style: const TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                '${_selected.length} / $_target',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: pool.map((card) {
                  return SizedBox(
                    key: ValueKey('tutorial-pool-${card.id}'),
                    width: 84,
                    child: UiCard.fromData(
                      card: card,
                      locale: locale,
                      l10n: l10n,
                      isSelected: _selected.contains(card),
                      onTap: () => _toggle(card),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
            ),
            child: Text(
              isFrench
                  ? 'Ajoutées d\'office : ${classCards.map((c) => c.getName(locale)).join(", ")}'
                  : 'Added automatically: ${classCards.map((c) => c.getName(locale)).join(", ")}',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade300, fontSize: 11.5),
            ),
          ),
        ],
      ),
    );
  }
}
