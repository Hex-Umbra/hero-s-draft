import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/charge_track.dart';
import '../../models/data/charge_data.dart';
import '../../models/entity_stats.dart';
import '../../models/status_effect.dart';
import '../services/proportional_status.dart';
import 'charge_rules.dart';

/// Le côté d'une carte où se tient une languette : les bonus à gauche, les
/// altérations et les charges à droite.
enum StatusSide { left, right }

/// Le ton d'une entrée : vert d'un bonus, rouge d'une altération, jaune de la
/// seule Foudre chargée (spec P-05, B14, B32).
enum ReadoutTone { buff, debuff, charged }

/// Une entrée de languette, écrite : ce que la languette montre au repos, ce
/// qu'elle déroule et ce que la fiche en dit (spec P-05, §4.3). Le côté n'est
/// pas un champ : [of] le dit par la liste qui porte l'entrée.
class StatusReadout {
  /// L'identité de l'entrée : le statut et sa source, ou la charge.
  final String key;
  final String emoji;

  /// Ce que la languette montre au repos.
  final String restValue;
  final ReadoutTone tone;

  /// Ce que la languette déroulée écrit, et son sous-titre.
  final String title;
  final String? subtitle;

  /// Les tours restants, que la fiche écrit ; nul sans durée (99 ou charge).
  final int? turnsLeft;

  /// La ligne d'aide que la fiche écrit sous l'entrée : ce que fait le
  /// statut, ou la phrase courte de la charge ; nulle pour un statut sans
  /// phrase (le compteur d'un passif, un statut de relique) et pour une charge
  /// sur le héros, dont le sous-titre dit déjà l'effet.
  final String? hint;

  const StatusReadout({
    required this.key,
    required this.emoji,
    required this.restValue,
    required this.tone,
    required this.title,
    this.subtitle,
    this.turnsLeft,
    this.hint,
  });

  /// Une durée de 99 est un statut qui ne s'use pas : ni durée, ni tours
  /// restants (B34).
  static const int _permanent = 99;

  /// Les entrées de [stats], rangées par côté : à gauche les statuts `buff` ;
  /// à droite les statuts `debuff` qui ne sont pas des charges, puis les lignes
  /// de charge. [counterId] est l'id du compteur du passif actif, nul pour un
  /// ennemi.
  static ({List<StatusReadout> left, List<StatusReadout> right}) of(
    EntityStats stats,
    ChargeCatalog charges,
    AppLocalizations l10n,
    String locale, {
    String? counterId,
  }) {
    StatusReadout ofStatus(StatusEffect status) {
      final isBuff = status.type == StatusType.buff;
      final name = _nameOf(status, l10n, counterId);
      final duration = status.duration;
      return StatusReadout(
        key: '${status.id}:${status.sourceId ?? ''}',
        emoji: statusEmoji(status.id),
        restValue: '${status.value}',
        tone: isBuff ? ReadoutTone.buff : ReadoutTone.debuff,
        title: isBuff
            ? l10n.tabBuff(name, status.value)
            : l10n.tabDebuff(name, status.value),
        subtitle:
            duration > 0 && duration < _permanent ? l10n.tabTurns(duration) : null,
        turnsLeft: duration < _permanent ? duration : null,
        hint: switch (status.id) {
          'weakness' => l10n.statusWeaknessHint(
              ProportionalStatus.weakness.percentPerPoint,
              ProportionalStatus.weakness.maxPercent,
            ),
          'vulnerable' => l10n.statusVulnerableHint(
              ProportionalStatus.vulnerable.percentPerPoint,
              ProportionalStatus.vulnerable.maxPercent,
            ),
          'poison' => l10n.statusPoisonHint(status.value),
          'might' => l10n.statusMightHint(status.value),
          'might_regen' => l10n.statusMightRegenHint(status.value),
          'armor_regen' => l10n.statusArmorRegenHint(status.value),
          'mana_regen' => l10n.statusManaRegenHint(status.value),
          'hp_regen' => l10n.statusHpRegenHint(status.value),
          _ => null,
        },
      );
    }

    return (
      left: [
        for (final status in stats.statuses)
          if (status.type == StatusType.buff) ofStatus(status),
      ],
      right: [
        for (final status in stats.statuses)
          if (status.type == StatusType.debuff && !charges.isCharge(status.id))
            ofStatus(status),
        for (final line in ChargeRules.linesFor(stats))
          _ofCharge(line, stats.charges[line.chargeId], charges, l10n, locale),
      ],
    );
  }

  /// Le nom d'un statut : le compteur d'un passif, puis `statusName` pour les
  /// ids qu'il couvre, sinon le `name` de l'entrée.
  static String _nameOf(
    StatusEffect status,
    AppLocalizations l10n,
    String? counterId,
  ) {
    if (status.id == counterId) return l10n.statusPassiveCounter;
    final localized = l10n.statusName(status.id);
    return localized == status.id ? status.name : localized;
  }

  /// Une ligne de charge : « Gel 2/3 » sous le seuil, « Feu 5 », l'état rompu
  /// (« Gelé ») et, pour la Foudre chargée, ses points en jaune. Sa ligne
  /// d'aide est la phrase courte de la charge, selon la rupture en vigueur de
  /// [track].
  static StatusReadout _ofCharge(
    ChargeLine line,
    ChargeTrack? track,
    ChargeCatalog charges,
    AppLocalizations l10n,
    String locale,
  ) {
    final data = charges[line.chargeId];
    final name = data?.name(locale) ?? line.chargeId;
    final state = data?.brokenName(locale) ?? name;
    final key = 'charge:${line.chargeId}';
    final emoji = statusEmoji(line.chargeId);
    final hint = data?.summaryFor(locale, track?.rupture);

    if (line.kind == RuptureKind.explode) {
      return StatusReadout(
        key: key,
        emoji: emoji,
        hint: hint,
        restValue: '${line.points}',
        tone: ReadoutTone.debuff,
        title: l10n.tabChargeOpen(name, line.points),
      );
    }
    if (line.state == ChargeState.none) {
      return StatusReadout(
        key: key,
        emoji: emoji,
        hint: hint,
        restValue: '${line.points}/${line.threshold}',
        tone: ReadoutTone.debuff,
        title: l10n.tabChargePoints(name, line.points, line.threshold),
      );
    }
    return switch (line.kind) {
      RuptureKind.amplifyHits => StatusReadout(
          key: key,
          emoji: emoji,
          hint: hint,
          restValue: '${line.points}',
          tone: ReadoutTone.charged,
          title: l10n.tabChargeOpen(state, line.points),
          subtitle: l10n.tabChargeBonus(line.value),
        ),
      RuptureKind.weakenDealt => StatusReadout(
          key: key,
          emoji: emoji,
          hint: hint,
          restValue: state,
          tone: ReadoutTone.debuff,
          title: state,
          subtitle: line.state == ChargeState.brokenPending
              ? l10n.tabChargeWeakenNext(line.value)
              : l10n.tabChargeWeakenNow(line.value),
        ),
      _ => StatusReadout(
          key: key,
          emoji: emoji,
          hint: hint,
          restValue: state,
          tone: ReadoutTone.debuff,
          title: state,
        ),
    };
  }

  static Color toneColor(ReadoutTone tone) => switch (tone) {
        ReadoutTone.buff => const Color(0xFF69F0AE),
        ReadoutTone.debuff => const Color(0xFFFF5252),
        ReadoutTone.charged => Colors.yellowAccent,
      };
}

/// L'emoji d'un statut ou d'une charge, par son id.
String statusEmoji(String id) {
  switch (id) {
    case 'poison':
      return '🧪';
    case 'might':
      return '⚡';
    case 'weakness':
      return '🥀';
    case 'vulnerable':
      return '🎯';
    case 'might_regen':
      return '✊';
    case 'armor_regen':
      return '🛡️';
    case 'mana_regen':
      return '💎';
    case 'hp_regen':
      return '💖';
    case 'lifesteal':
      return '🧛';
    case 'burn':
      return '🔥';
    case 'freeze':
      return '❄️';
    case 'shock':
      return '⚡';
    default:
      return '✨';
  }
}
