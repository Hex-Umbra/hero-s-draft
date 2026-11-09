import 'dart:math' show max;

import 'card_instance.dart';
import 'data/card_data.dart';
import 'data/card_delta.dart';
import 'data/effect_kind.dart';
import 'data/forge_upgrade_data.dart';
import 'data/signature_data.dart';
import 'data/signature_evolution_data.dart';
import 'effective_card.dart';
import 'missing_save_item.dart';

/// Une entrée de la bande et de la liste de combat : la sorte d'un effet
/// (`EffectKind`), sa valeur évoluée — absente pour une cible — et, pour un
/// statut, sa durée (spec A40).
typedef EffectLine = ({String kind, int? value, int? duration});

/// Une signature en jeu : sa donnée, ses évolutions prises, et sa vue de
/// carte (spec P-43 E4, §4.1 ; spec P-42 T1 et P-44 lot 1, §4.10).
class SignatureInstance {
  final SignatureData data;

  /// Les évolutions prises, des références `id:niveau` dans l'ordre de leur
  /// première prise.
  final List<String> evolutions;

  const SignatureInstance(this.data, {this.evolutions = const []});

  /// Les évolutions prises avec leur niveau, relues dans le pool de la
  /// signature, dans l'ordre de leur première prise ; un id hors du pool est
  /// passé.
  List<(SignatureEvolutionData, int)> get taken => [
        for (final MapEntry(key: id, value: level)
            in ForgeUpgradeData.levelsOf(evolutions).entries)
          if (data.evolutions.where((e) => e.id == id).firstOrNull
              case final evolution?)
            (evolution, level),
      ];

  /// La somme des niveaux des évolutions prises.
  int get level => taken.fold(0, (sum, t) => sum + t.$2);

  /// Le coût à payer, évolutions comprises.
  int get cost => asCard.currentCost;

  /// La recharge, en tours : celle de la donnée, plus ce que les majeures
  /// prises y changent, jamais sous 1 (D54).
  int get cooldown =>
      max(1, data.cooldown + taken.fold(0, (sum, t) => sum + t.$1.cooldown));

  /// Les niveaux d'évolution que la signature attend d'un héros de niveau
  /// [heroLevel] (A27).
  int pendingFor(int heroLevel) => max(0, heroLevel ~/ 5 - level);

  /// Le niveau du héros auquel la prochaine évolution devient due.
  int get nextEvolutionHeroLevel => (level + 1) * 5;

  /// Le rang de la prochaine évolution : mineure si son niveau est impair
  /// (héros niveau 5, 15, 25...), majeure sinon (D21).
  EvolutionTier get nextTier =>
      (level + 1).isOdd ? EvolutionTier.minor : EvolutionTier.major;

  /// Relit les évolutions sauvegardées de [data] (spec P-42 T1 et P-44 lot 1,
  /// §8) : [raw] est la valeur de sa clé dans `signatureEvolutions`. Seul un
  /// id absent du pool entre au rapport ; une référence mal formée, une
  /// majeure au-delà du niveau 1 ou une majeure exclue par une majeure gardée
  /// avant elle sont corrigées sans rapport — elles ne naissent que d'une
  /// sauvegarde écrite à la main, et le rapport dit au joueur qu'un élément a
  /// disparu d'une mise à jour.
  static (SignatureInstance, List<MissingSaveItem>) restore(
    SignatureData data,
    Object? raw,
  ) {
    final missing = <MissingSaveItem>[];
    // 1. Absente, ou d'une autre forme qu'une liste : aucune évolution.
    if (raw is! List) return (SignatureInstance(data), missing);

    final pool = {
      for (final evolution in data.evolutions) evolution.id: evolution,
    };
    final known = <String>[];
    final reported = <String>{};
    for (final entry in raw) {
      // 2. Mal formée ou de niveau nul : ignorée, sans rapport.
      if (entry is! String) continue;
      final parsed = ForgeUpgradeData.parseRef(entry);
      if (parsed == null) continue;
      final (id, _) = parsed;
      // 3. Absente du pool : retirée, et signalée une fois.
      if (!pool.containsKey(id)) {
        if (reported.add(id)) {
          missing.add(MissingSaveItem(
            id: id,
            nameFr: id,
            nameEn: id,
            category: 'signatureEvolution',
          ));
        }
        continue;
      }
      known.add(entry);
    }

    final keptMajors = <SignatureEvolutionData>[];
    final evolutions = <String>[];
    // 4. Les références d'un même id réunies, niveaux additionnés, dans
    // l'ordre de leur première apparition.
    for (final MapEntry(key: id, value: level)
        in ForgeUpgradeData.levelsOf(known).entries) {
      final evolution = pool[id]!;
      if (evolution.tier == EvolutionTier.minor) {
        evolutions.add('$id:$level');
        continue;
      }
      // 5. Une majeure exclue par une majeure gardée avant elle, dans un
      // sens ou dans l'autre, est retirée : la première arrivée est gardée,
      // comme `ForgeRuneRules.consolidate`.
      if (keptMajors.any(evolution.excludesOrIsExcludedBy)) continue;
      keptMajors.add(evolution);
      // 4, suite. Une majeure ne se prend qu'une fois : ramenée au niveau 1.
      evolutions.add('$id:1');
    }

    // 6. La signature reconstruite, dans l'ordre lu.
    return (SignatureInstance(data, evolutions: evolutions), missing);
  }

  /// La signature sous la forme d'une carte, pour que le moteur de jeu et le
  /// rendu la lisent comme une carte. Neuve à chaque appel : commune, jamais
  /// épuisée, portant les évolutions en `extraDeltas`. Une signature ne coûte
  /// que du Mana : `hpCost` et `armorCost` restent à 0.
  ///
  /// Sa description est la forme hors combat : le gabarit rempli des valeurs
  /// évoluées, suivi de la phrase de chaque évolution verbale (A25).
  CardInstance get asCard {
    final taken = this.taken;
    final deltas = [
      for (final (evolution, level) in taken)
        for (final delta in evolution.deltas) (delta, level),
    ];
    final target = taken
            .map((t) => t.$1.target)
            .nonNulls
            .lastOrNull ??
        data.target;
    final evolved =
        EffectiveCard.apply(_baseCard(target), CardRarity.common, deltas);

    String describe(String locale) {
      final buffer = StringBuffer(SignatureData.fillTemplate(
        locale == 'fr' ? data.descriptionFr : data.descriptionEn,
        evolved.effects,
      ));
      for (final (evolution, level) in taken.where((t) => t.$1.isVerbal)) {
        buffer.write(
            ' ${evolution.getDescription(level, locale, cost: data.cost)}.');
      }
      return buffer.toString();
    }

    return CardInstance(
      data: _baseCard(
        target,
        descriptionEn: describe('en'),
        descriptionFr: describe('fr'),
      ),
      extraDeltas: deltas,
    );
  }

  CardData _baseCard(
    CardTarget target, {
    String? descriptionEn,
    String? descriptionFr,
  }) =>
      CardData(
        id: data.id,
        nameEn: data.nameEn,
        nameFr: data.nameFr,
        descriptionEn: descriptionEn ?? data.descriptionEn,
        descriptionFr: descriptionFr ?? data.descriptionFr,
        cost: data.cost,
        type: data.type,
        rarity: CardRarity.common,
        target: target,
        animation: data.animation,
        sfx: data.sfx,
        isExhaust: false,
        effects: data.effects,
      );

  /// Les entrées de la bande et de la liste (A40), lues sur la vue évoluée :
  /// une par effet propre, puis une par changement de chaque évolution
  /// verbale prise. Une évolution chiffrée n'en ajoute aucune.
  List<EffectLine> get effectLines {
    final evolved = asCard.effective;
    final added = evolved.addedEffects.iterator;
    return [
      for (final e in evolved.effects)
        (
          kind: EffectKind.of(e),
          value: e.value,
          duration: e.type == 'apply_status' ? e.duration : null,
        ),
      for (final (evolution, level) in taken.where((t) => t.$1.isVerbal)) ...[
        for (final delta in evolution.deltas)
          if (delta is AddEffectDelta && added.moveNext())
            (
              kind: EffectKind.of(added.current),
              value: added.current.value,
              duration: added.current.duration,
            )
          else if (delta is CritBonusDelta)
            (
              kind: EffectKind.crit,
              value: delta.valuePerLevel * level,
              duration: null,
            ),
        if (evolution.target != null)
          (kind: EffectKind.allEnemies, value: null, duration: null),
      ],
    ];
  }
}
