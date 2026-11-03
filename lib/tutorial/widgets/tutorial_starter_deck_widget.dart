import 'package:flutter/material.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';

import '../../game/systems/starter_draft.dart';
import '../../models/data/card_data.dart';
import '../../models/data/signature_data.dart';
import '../../ui/widgets/ui_card.dart';
import '../tutorial_engine.dart';

/// Étape 03 — draft du deck de départ.
///
/// Le draft est celui de `StarterDeckDraftScreen`, par `StarterDraft` : le lot
/// du passif actif et les neutres, chacun à son quota. Les cartes s'affichent
/// avec le vrai [UiCard], donc le vrai médaillon de mana et les vrais badges
/// d'effets.
class TutorialStarterDeckWidget extends StatefulWidget {
  final TutorialEngine engine;

  const TutorialStarterDeckWidget({super.key, required this.engine});

  @override
  State<TutorialStarterDeckWidget> createState() =>
      _TutorialStarterDeckWidgetState();
}

class _TutorialStarterDeckWidgetState extends State<TutorialStarterDeckWidget> {
  final List<CardData> _selected = [];

  StarterDraft get _draft => widget.engine.fixtures
      .starterDraft(widget.engine.mockState.activePassive?.id);

  void _toggle(CardData card) {
    final draft = _draft;
    setState(() {
      if (_selected.remove(card)) return;
      if (draft.accepts(_selected, card)) _selected.add(card);
    });
    widget.engine.setStarterDeck(draft.isComplete(_selected) ? _selected : []);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final isFrench = locale == 'fr';
    final draft = _draft;
    final passive = widget.engine.mockState.activePassive;
    final signatures = widget.engine.mockState.chosenHero?.skills
            .map(widget.engine.fixtures.signature)
            .toList() ??
        const <SignatureData>[];

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  if (passive != null && draft.lot.isNotEmpty)
                    _section(
                      title: l10n.draftDeckLotSection(passive.getName(locale)),
                      cards: draft.lot,
                      quota: draft.lotQuota,
                      locale: locale,
                      l10n: l10n,
                    ),
                  if (draft.neutrals.isNotEmpty)
                    _section(
                      title: l10n.draftDeckNeutralSection,
                      cards: draft.neutrals,
                      quota: draft.neutralQuota,
                      locale: locale,
                      l10n: l10n,
                    ),
                ],
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
                  ? 'Vos signatures, toujours disponibles en combat : ${signatures.map((s) => s.getName(locale)).join(", ")}'
                  : 'Your signatures, always available in combat: ${signatures.map((s) => s.getName(locale)).join(", ")}',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade300, fontSize: 11.5),
            ),
          ),
        ],
      ),
    );
  }

  /// Une section : son titre, son compteur `choisis/quota`, ses cartes.
  Widget _section({
    required String title,
    required List<CardData> cards,
    required int quota,
    required String locale,
    required AppLocalizations l10n,
  }) {
    final picked = _selected.where(cards.contains).length;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            Text(
              l10n.draftDeckQuota(picked, quota),
              style: TextStyle(
                color: picked == quota ? Colors.greenAccent : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: cards.map((card) {
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
        const SizedBox(height: 12),
      ],
    );
  }
}
