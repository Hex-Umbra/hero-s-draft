// Simulation D26 — l'économie de deck du brainstorm v3, sur 15 actes.
//
// Script hors du code du jeu, suivi par git avec sa sortie de référence
// (d26_reference_output.md, à côté) : ni déclaré dans pubspec.yaml, ni
// importé par lib/, ni un test. Il n'importe rien de lib/ : Flame, donc
// Flutter, refuse `dart run`. Les FORMULES du jeu y sont portées, chacune
// avec son `fichier:ligne` ; les DONNÉES (ennemis, neutres, signatures,
// reliques, récompenses de niveau, runes, passifs, classes) sont relues dans
// assets/data/ à chaque lancement.
//
// Les règles simulées sont les décisions D1-D49 du brainstorm
// docs/possible_upgrades/22-09-2026_brainstorm_heros_et_cartes_v3_Fable5.md
// (« Dxx », « §x »). Là où il laisse une valeur ouverte, la valeur retenue
// est marquée DÉFAUT et, quand c'est un levier, elle varie (§ 8 du script).
//
//   dart run tool/simulations/d26_economy_sim.dart [--quick] [--out f.md]

import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

// ===========================================================================
// 1. Constantes du jeu, portées
// ===========================================================================

/// Multiplicateur de valeur par rang de fusion — card_instance.dart:35-50.
const rarityMult = [1.0, 1.2, 1.4, 1.6, 2.0];
const rankLabels = ['commune', 'peu commune', 'rare', 'épique', 'légendaire'];

/// Prix d'une carte par rareté, +20 par rune — shop_controller.dart:20-43.
const cardPriceByRank = [25, 50, 100, 150, 200];
const shopPricePerRune = 20; // shop_controller.dart:42
const shopHealPrice = 30; // shop_screen.dart:294
const shopHealRatio = 0.3; // shop_screen.dart:295
const shopPurgePrice = 75; // shop_screen.dart:429
const shopMirrorBasePrice = 150; // shop_state.dart:16 (150 << achats)
const restHealRatio = 0.3; // rest_screen.dart:29
const startingGold = 50; // inventory_controller.dart:50
const maxHandSize = 10; // game_constants.dart:36
const baseCardsPerTurn = 5; // run_controller.dart:82
const baseCritMultiplier = 1.5; // entity_stats.dart:38
const floors = 10; // map_generator_service.dart:14
const maxWidth = 5; // map_generator_service.dart:14
const middleFloor = floors ~/ 2; // map_generator_service.dart:15
const maxActiveEnemies = 5; // combat_controller.dart:169

/// Quotas de types de nœuds par carte — game_constants.dart:25-31, dans
/// l'ordre de déclaration (l'ordre compte : map_validator.dart:58, :125).
const nodeQuotas = <String, List<int>>{
  'combat': [12, 22],
  'elite': [3, 6],
  'rest': [3, 6],
  'shop': [2, 5],
  'event': [4, 9],
};

/// Échelle de rareté des reliques — relic_data.dart (common … legendary).
const relicRarities = ['common', 'uncommon', 'rare', 'epic', 'legendary'];

/// Les actes rapportés (mission) ; la simulation en joue 15 (D26).
const reportedActs = [1, 3, 5, 8, 10, 12, 15];
const actCount = 15;

/// Garde-fou de la simulation, pas une règle du jeu : une courbe d'XP qui
/// diverge (palier constant, voir la calibration) s'arrête au niveau 999.
const levelCap = 999;

// ===========================================================================
// 2. Paramètres — les leviers de D26 et leurs valeurs par défaut
// ===========================================================================

class Params {
  const Params({
    this.normalGuaranteed = 1,
    this.eliteExtra = 0.25,
    this.relicAEliteBonus = 0.25,
    this.relicBPerCopy = 0.01,
    this.d31Relics = 'pool',
    this.mirrorPool = 'mythic',
    this.exchange = 'none',
    this.wellEvery = 3,
    this.altar = 'today',
    this.sharpenB = 50,
    this.wellBase = 50,
    this.sharpenStrategy = 'concentrate',
    this.xpCurve = 'perAct',
    this.xpConstant = 250,
    this.xpTable = const [],
    this.xpLevelScaling = true,
    this.ddaK = 2,
    this.ecoQuickMinRank = 2,
    this.maxLevelTable = 's8',
    this.blessingD43 = false,
    this.onlyFind = false,
    this.mightBudget = 'plusOne',
    this.mythicMode = 'perReward',
  });

  /// D31 : cartes garanties après un combat normal.
  final int normalGuaranteed;

  /// D31 : chance d'une seconde carte en élite.
  final double eliteExtra;

  /// D31, relique A : +X de chance de seconde carte en élite, par exemplaire.
  /// DÉFAUT 0,25 — valeur laissée à la simulation par D31.
  final double relicAEliteBonus;

  /// D31, relique B (épique) : +1 % par exemplaire d'une seconde carte en
  /// combat normal et d'une troisième en élite.
  final double relicBPerCopy;

  /// Les trois reliques de D31 : 'pool' (dans la réserve de reliques, A et C
  /// rares, B épique — DÉFAUT), 'forced' (tenues dès l'acte 1, borne haute),
  /// 'absent'.
  final String d31Relics;

  /// Q3 : le Miroir (`cloneCard`) en pool 'mythic' (aujourd'hui) ou 'draft'.
  final String mirrorPool;

  /// D8 « plus tard » : 'none' (DÉFAUT validé), 'event', 'campfire'.
  final String exchange;

  /// D22 : un Puits tous les N actes ; 0 = aujourd'hui, 25 % par carte
  /// (map_content_placer.dart:24).
  final int wellEvery;

  /// L'Autel : 'today' (map_content_placer.dart:10), 'every3' (actes 4, 7,
  /// 10, 13 — décalé du Puits), 'none'.
  final String altar;

  /// D20 : coût d'affûtage `b × niveau`. DÉFAUT 50 (« 50 or, par exemple »,
  /// brainstorm §4.2).
  final int sharpenB;

  /// D6, D39 : coût du Puits `base × niveau` de la rune donnée. DÉFAUT 50.
  final int wellBase;

  /// §4.2 : 'concentrate' (la meilleure rune du deck — DÉFAUT) ou
  /// 'beforeFusion' (affûter les cartes d'une paire avant leur fusion).
  final String sharpenStrategy;

  /// Q17 : 'current' (100 × 1,5^(n−1), player_stats_manager.dart:127),
  /// 'constant' (un palier constant par niveau), 'perAct' (un palier par acte
  /// — DÉFAUT : la forme constante diverge, voir la calibration).
  final String xpCurve;
  final int xpConstant;
  final List<int> xpTable;

  /// L'XP d'un ennemi × (1 + 0,1 × (niveau − 1)) (reward_controller.dart:86).
  /// `false` : variante qui retire ce bonus, pour tester un palier constant.
  final bool xpLevelScaling;

  /// D47 : terme de deck de `PlayerPower`. < 0 = formule actuelle, cartes × 2
  /// (encounter_system.dart:101) ; sinon k × Σ `fusionRank`. DÉFAUT k = 2 (D59 ;
  /// la première passe du 30/09 tournait à k = 5, rapport §1.2 et §7).
  final double ddaK;

  /// D48 : `minFusionRank` d'`eco` et `quick`.
  final int ecoQuickMinRank;

  /// §8 : 's8' (table proposée), 'uncapped' (sans plafond sauf les runes
  /// binaires, D27), 'cap5'.
  final String maxLevelTable;

  /// D43 : Bénédiction à `threshold: 3`, Maîtrise sur le seuil, plancher 2.
  final bool blessingD43;

  /// Diagnostic de la prémisse de D48 : la trouvaille comme seule source de
  /// doublon (ni clones de boss, ni achats de cartes, ni Miroir).
  final bool onlyFind;

  /// Q21 : 'plusOne' (D38 tel qu'écrit, ≤ coût + 1) ou 'costFloor'
  /// (≤ max(coût, 0,5)).
  final String mightBudget;

  /// Le tirage des mythiques : 'perReward' (le code : un jet indépendant par
  /// récompense mythique, level_up_reward_service.dart:127-145) ou 'pool'
  /// (la lecture de D51 : le pool sort à 0,5 %, puis une mythique tirée).
  final String mythicMode;

  Params copyWith({
    int? normalGuaranteed,
    double? eliteExtra,
    double? relicAEliteBonus,
    double? relicBPerCopy,
    String? d31Relics,
    String? mirrorPool,
    String? exchange,
    int? wellEvery,
    String? altar,
    int? sharpenB,
    int? wellBase,
    String? sharpenStrategy,
    String? xpCurve,
    int? xpConstant,
    List<int>? xpTable,
    bool? xpLevelScaling,
    double? ddaK,
    int? ecoQuickMinRank,
    String? maxLevelTable,
    bool? blessingD43,
    bool? onlyFind,
    String? mightBudget,
    String? mythicMode,
  }) =>
      Params(
        normalGuaranteed: normalGuaranteed ?? this.normalGuaranteed,
        eliteExtra: eliteExtra ?? this.eliteExtra,
        relicAEliteBonus: relicAEliteBonus ?? this.relicAEliteBonus,
        relicBPerCopy: relicBPerCopy ?? this.relicBPerCopy,
        d31Relics: d31Relics ?? this.d31Relics,
        mirrorPool: mirrorPool ?? this.mirrorPool,
        exchange: exchange ?? this.exchange,
        wellEvery: wellEvery ?? this.wellEvery,
        altar: altar ?? this.altar,
        sharpenB: sharpenB ?? this.sharpenB,
        wellBase: wellBase ?? this.wellBase,
        sharpenStrategy: sharpenStrategy ?? this.sharpenStrategy,
        xpCurve: xpCurve ?? this.xpCurve,
        xpConstant: xpConstant ?? this.xpConstant,
        xpTable: xpTable ?? this.xpTable,
        xpLevelScaling: xpLevelScaling ?? this.xpLevelScaling,
        ddaK: ddaK ?? this.ddaK,
        ecoQuickMinRank: ecoQuickMinRank ?? this.ecoQuickMinRank,
        maxLevelTable: maxLevelTable ?? this.maxLevelTable,
        blessingD43: blessingD43 ?? this.blessingD43,
        onlyFind: onlyFind ?? this.onlyFind,
        mightBudget: mightBudget ?? this.mightBudget,
        mythicMode: mythicMode ?? this.mythicMode,
      );

  String get key => [
        normalGuaranteed, eliteExtra, relicAEliteBonus, relicBPerCopy,
        d31Relics, mirrorPool, exchange, wellEvery, altar, sharpenB, wellBase,
        sharpenStrategy, xpCurve, xpConstant, xpTable.join(','), xpLevelScaling, ddaK,
        ecoQuickMinRank, maxLevelTable, blessingD43, onlyFind, mightBudget,
        mythicMode,
      ].join('|');
}

// ===========================================================================
// 3. Le modèle de données de la simulation
// ===========================================================================

enum CType { attack, skill, power }

enum Tgt { single, all, self }

/// Un effet de carte. `kind` : damage, armor, draw, heal, mana, self (statut
/// sur soi), enemy (statut sur la cible). `scale` porte les mécanismes P-44
/// (§9.2) : armor, missingHp, attacksPlayed, lowHpX2, vulnX2.
class Eff {
  const Eff(
    this.kind,
    this.value, {
    this.hits = 1,
    this.status = '',
    this.duration = 0,
    this.scale = '',
  });

  final String kind;
  final int value;
  final int hits;
  final String status;
  final int duration;
  final String scale;
}

class CardDef {
  const CardDef(
    this.id,
    this.cost,
    this.type,
    this.target,
    this.effects, {
    this.exhaust = false,
    this.hpCost = 0,
    this.armorCost = 0,
    this.lot = '',
    this.cooldown = 0,
  });

  final String id;
  final int cost;
  final CType type;
  final Tgt target;
  final List<Eff> effects;
  final bool exhaust;
  final int hpCost;
  final int armorCost;

  /// '' : neutre ; 'sig' : signature (D49) ; sinon l'id du lot.
  final String lot;

  /// D49 : temps de recharge d'une signature, en tours.
  final int cooldown;

  bool has(String kind) => effects.any((e) => e.kind == kind);
  bool get hasDamage => has('damage');

  CardDef withLot(String newLot) => CardDef(id, cost, type, target, effects,
      exhaust: exhaust, hpCost: hpCost, armorCost: armorCost, lot: newLot);
}

class EnemyDef {
  const EnemyDef(this.id, this.maxHp, this.baseDamage, this.tier, this.xp,
      this.gold, this.crit, this.intents);

  final String id;
  final int maxHp;
  final int baseDamage;
  final int tier;
  final int xp;
  final int gold;
  final int crit;

  /// (type, valeur) — `attack` ou `buff`, parcourus en boucle
  /// (combat_controller.dart:380-390).
  final List<(String, int)> intents;
}

class RelicDef {
  const RelicDef(this.id, this.rarity, this.trigger, this.effect, this.value);

  final String id;

  /// Index dans [relicRarities].
  final int rarity;
  final String trigger;
  final String effect;
  final int value;
}

class RewardDef {
  const RewardDef(this.id, this.effect, this.stat, this.pool, this.values);

  final String id;
  final String effect;
  final String stat;
  final String pool;
  final Map<String, int> values;
}

class PassiveDef {
  const PassiveDef(this.id, this.value, this.duration, this.threshold,
      this.masteryField, this.perPoint);

  final String id;
  final int value;
  final int duration;
  final int threshold;
  final String masteryField;
  final int perPoint;
}

class ClassDef {
  const ClassDef(this.id, this.maxHp, this.maxMana, this.crit, this.mastery,
      this.mightTargets, this.convertsArmor, this.signatures, this.lots);

  final String id;
  final int maxHp;
  final int maxMana;
  final int crit;
  final int mastery;
  final Set<String> mightTargets;

  /// `statRules` : armure → Puissance 1 tour (classes/berserker/class.json).
  final bool convertsArmor;
  final List<CardDef> signatures;
  final List<String> lots;
}

/// Un événement d'aujourd'hui (assets/data/events/) : ses choix, chacun une
/// liste d'actions (type, valeur).
class EventDef {
  const EventDef(this.id, this.choices);

  final String id;
  final List<List<(String, int)>> choices;
}

/// Une rune (D3, D4, §8). `needs` : condition d'éligibilité en donnée (D44).
class RuneDef {
  const RuneDef(this.id, this.weight,
      {this.types = const [], this.needs = '', this.excludes = const []});

  final String id;
  final int weight;
  final List<String> types;
  final String needs;
  final List<String> excludes;
}

// ===========================================================================
// 4. Chargement des données (assets/data/) et lots du §7
// ===========================================================================

Directory _findRoot() {
  var dir = File.fromUri(Platform.script).parent;
  for (var i = 0; i < 6; i++) {
    if (Directory('${dir.path}/assets/data').existsSync()) return dir;
    dir = dir.parent;
  }
  return Directory.current;
}

Map<String, dynamic> _json(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

List<File> _jsonFiles(String dir) {
  final files = Directory(dir)
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.json'))
      .toList();
  files.sort((a, b) => a.path.compareTo(b.path));
  return files;
}

CardDef cardFromJson(Map<String, dynamic> j,
    {String lot = '', int cooldown = 0, CType? typeOverride}) {
  final target = switch (j['target']) {
    'allEnemies' => Tgt.all,
    'self' => Tgt.self,
    _ => Tgt.single,
  };
  final effects = <Eff>[];
  for (final raw in (j['effects'] as List? ?? const [])) {
    final m = raw as Map<String, dynamic>;
    final v = m['value'] as int;
    switch (m['type']) {
      case 'damage':
        effects.add(Eff('damage', v));
      case 'armor':
        effects.add(Eff('armor', v));
      case 'draw':
        effects.add(Eff('draw', v));
      case 'heal':
        effects.add(Eff('heal', v));
      case 'gain_mana':
        effects.add(Eff('mana', v));
      case 'apply_status':
        effects.add(Eff(target == Tgt.self ? 'self' : 'enemy', v,
            status: m['statusId'] as String,
            duration: m['duration'] as int? ?? 1));
    }
  }
  return CardDef(
    j['id'] as String,
    j['cost'] as int,
    typeOverride ?? CType.values.byName(j['type'] as String),
    target,
    effects,
    exhaust: j['isExhaust'] as bool? ?? false,
    lot: lot,
    cooldown: cooldown,
  );
}

/// D38 : chaque coup reçoit `mightRatio` de la Puissance, le plus haut qui
/// tienne Σ hits × mightRatio ≤ coût en mana + 1. Q21 : la variante
/// 'costFloor' borne par le coût, avec un plancher de 0,5.
double mightRatioOf(CardDef d, Eff e, Params p) => p.mightBudget == 'costFloor'
    ? min(1.0, max(d.cost, 0.5) / e.hits)
    : min(1.0, (d.cost + 1) / e.hits);

/// Le noyau neutre : les 9 neutres gardées par §7.4 (`focus` supprimée, revue
/// B.4) ; les autres neutres d'aujourd'hui migrent dans un lot.
const coreNeutralIds = [
  'strike_basic', 'defend_basic', 'quick_attack', 'heavy_strike', 'sweep',
  'iron_wall', 'awakening', 'concentration', 'heal_potion',
];

/// Le passif de chaque lot — §7, D10, D15.
const lotPassive = {
  'rempart': 'regen_armor',
  'croise': 'fervor',
  'sanctifie': 'blessing',
  'sang': 'rage',
  'vampire': 'bloodthirst',
  'carnage': 'frenzy',
  'voile': 'channeling',
  'marque': 'mage_mark',
  'arcaniste': 'mana_flux',
};

const classLots = {
  'paladin': ['rempart', 'croise', 'sanctifie'],
  'berserker': ['sang', 'vampire', 'carnage'],
  'mage': ['voile', 'marque', 'arcaniste'],
};

/// Les cartes d'un lot : les exemples du §7 (valeurs indicatives, « ordres de
/// grandeur, jamais des chiffres de spec ») et les survivantes qui y migrent
/// (§7.1-7.3, revue B.4), complétées à 6 cartes (D16) par des cartes
/// génériques du lot — DÉFAUT : 6 dégâts ou 5-6 armure par mana (§7).
List<CardDef> lotCards(String lot, Map<String, CardDef> json) {
  CardDef survivor(String id) => json[id]!.withLot(lot);
  switch (lot) {
    case 'rempart': // §7.1, passif Régénération
      return const [
        CardDef('muraille', 2, CType.skill, Tgt.self, [Eff('armor', 12)],
            lot: 'rempart'),
        CardDef('bastion', 3, CType.power, Tgt.self,
            [Eff('self', 3, status: 'armor_regen', duration: 4)],
            lot: 'rempart'),
        CardDef('rempart_brise', 1, CType.attack, Tgt.single,
            [Eff('damage', 0, scale: 'armor')],
            lot: 'rempart'),
        CardDef('percee', 0, CType.attack, Tgt.single, [Eff('damage', 10)],
            armorCost: 4, lot: 'rempart'),
        CardDef('rempart_g1', 1, CType.skill, Tgt.self, [Eff('armor', 6)],
            lot: 'rempart'),
        CardDef('rempart_g2', 2, CType.attack, Tgt.single,
            [Eff('damage', 6), Eff('armor', 6)],
            lot: 'rempart'),
      ];
    case 'croise': // §7.1, passif Ferveur
      return const [
        CardDef('riposte', 1, CType.attack, Tgt.single,
            [Eff('damage', 3), Eff('armor', 5)],
            lot: 'croise'),
        CardDef('jugement', 3, CType.attack, Tgt.all,
            [Eff('damage', 5), Eff('armor', 6)],
            lot: 'croise'),
        CardDef('marteau_sacre', 2, CType.attack, Tgt.single,
            [Eff('damage', 3, hits: 3)],
            lot: 'croise'),
        CardDef('croise_g1', 1, CType.attack, Tgt.single,
            [Eff('damage', 4), Eff('armor', 3)],
            lot: 'croise'),
        CardDef('croise_g2', 1, CType.skill, Tgt.self, [Eff('armor', 6)],
            lot: 'croise'),
        CardDef('croise_g3', 2, CType.attack, Tgt.single,
            [Eff('damage', 8), Eff('armor', 4)],
            lot: 'croise'),
      ];
    case 'sanctifie': // §7.1, passif Bénédiction
      return [
        const CardDef('sommation', 1, CType.skill, Tgt.single,
            [Eff('enemy', 1, status: 'weakness', duration: 2)],
            lot: 'sanctifie'),
        const CardDef('edit', 2, CType.skill, Tgt.all,
            [Eff('enemy', 1, status: 'weakness', duration: 1)],
            lot: 'sanctifie'),
        const CardDef('vigile', 1, CType.power, Tgt.self,
            [Eff('self', 2, status: 'armor_regen', duration: 3)],
            lot: 'sanctifie'),
        // D55 : un soin dans le temps, `hp_regen` 2 pendant 3 tours.
        const CardDef('priere', 2, CType.power, Tgt.self,
            [Eff('self', 2, status: 'hp_regen', duration: 3)],
            lot: 'sanctifie'),
        survivor('metallicize'),
        const CardDef('sanctifie_g1', 1, CType.skill, Tgt.self,
            [Eff('armor', 6)],
            lot: 'sanctifie'),
      ];
    case 'sang': // §7.2, passif Rage
      return [
        const CardDef('transe', 2, CType.power, Tgt.self,
            [Eff('self', 1, status: 'might_regen', duration: 3)],
            lot: 'sang'),
        const CardDef('sang_verse', 0, CType.attack, Tgt.single,
            [Eff('damage', 8)],
            hpCost: 4, lot: 'sang'),
        const CardDef('dernier_souffle', 2, CType.attack, Tgt.single,
            [Eff('damage', 4, scale: 'missingHp')],
            lot: 'sang'),
        survivor('demon_form'),
        const CardDef('sang_g1', 1, CType.skill, Tgt.self, [Eff('armor', 6)],
            lot: 'sang'),
        const CardDef('sang_g2', 1, CType.attack, Tgt.single,
            [Eff('damage', 6)],
            lot: 'sang'),
      ];
    case 'vampire': // §7.2, passif Soif de Sang (D35)
      return const [
        CardDef('morsure', 1, CType.attack, Tgt.single,
            [Eff('damage', 4), Eff('draw', 1)],
            lot: 'vampire'),
        CardDef('laceration', 0, CType.attack, Tgt.single, [Eff('damage', 4)],
            exhaust: true, lot: 'vampire'),
        CardDef('curee', 2, CType.attack, Tgt.single,
            [Eff('damage', 8), Eff('draw', 1)],
            lot: 'vampire'),
        CardDef('frenesie_sanglante', 3, CType.attack, Tgt.single,
            [Eff('damage', 4, scale: 'attacksPlayed')],
            lot: 'vampire'),
        CardDef('vampire_g1', 1, CType.attack, Tgt.single, [Eff('damage', 6)],
            lot: 'vampire'),
        CardDef('vampire_g2', 1, CType.skill, Tgt.self, [Eff('armor', 6)],
            lot: 'vampire'),
      ];
    case 'carnage': // §7.2, passif Frénésie
      return [
        const CardDef('moulinet', 2, CType.attack, Tgt.all, [Eff('damage', 6)],
            lot: 'carnage'),
        const CardDef('tourbillon', 1, CType.attack, Tgt.all,
            [Eff('damage', 2), Eff('draw', 1)],
            lot: 'carnage'),
        const CardDef('coup_de_grace', 3, CType.attack, Tgt.all,
            [Eff('damage', 9)],
            lot: 'carnage'),
        const CardDef('execution', 1, CType.attack, Tgt.single,
            [Eff('damage', 4, scale: 'lowHpX2')],
            lot: 'carnage'),
        survivor('warcry'),
        const CardDef('carnage_g1', 1, CType.attack, Tgt.single,
            [Eff('damage', 6)],
            lot: 'carnage'),
      ];
    case 'voile': // §7.3, passif Canalisation (D30)
      return const [
        CardDef('barriere', 2, CType.power, Tgt.self,
            [Eff('self', 2, status: 'armor_regen', duration: 3)],
            lot: 'voile'),
        CardDef('meditation', 1, CType.skill, Tgt.self,
            [Eff('self', 1, status: 'mana_regen', duration: 2)],
            exhaust: true, lot: 'voile'),
        CardDef('sceau', 3, CType.power, Tgt.self,
            [Eff('self', 1, status: 'might_regen', duration: 4)],
            lot: 'voile'),
        CardDef('voile_g1', 3, CType.skill, Tgt.single, [Eff('damage', 15)],
            lot: 'voile'),
        CardDef('voile_g2', 1, CType.skill, Tgt.self, [Eff('armor', 5)],
            lot: 'voile'),
        CardDef('voile_g3', 2, CType.skill, Tgt.single, [Eff('damage', 10)],
            lot: 'voile'),
      ];
    case 'marque': // §7.3, passif Marque du Mage (D34)
      return [
        survivor('fireball'),
        survivor('ice_bolt'),
        survivor('thunder_clap'),
        survivor('poison_stab'),
        const CardDef('exploitation', 2, CType.attack, Tgt.single,
            [Eff('damage', 4, scale: 'vulnX2')],
            lot: 'marque'),
        const CardDef('salve', 1, CType.attack, Tgt.single,
            [Eff('damage', 2, hits: 2)],
            lot: 'marque'),
      ];
    case 'arcaniste': // §7.3, passif Flux de Mana
      return const [
        CardDef('eclat', 1, CType.skill, Tgt.single, [Eff('damage', 5)],
            lot: 'arcaniste'),
        CardDef('onde', 2, CType.skill, Tgt.all, [Eff('damage', 4)],
            lot: 'arcaniste'),
        CardDef('embrasement', 1, CType.skill, Tgt.single,
            [Eff('enemy', 4, status: 'burn', duration: 3)],
            lot: 'arcaniste'),
        CardDef('decharge', 3, CType.skill, Tgt.single,
            [Eff('damage', 12), Eff('enemy', 1, status: 'vulnerable', duration: 1)],
            lot: 'arcaniste'),
        CardDef('arcaniste_g1', 1, CType.skill, Tgt.self, [Eff('armor', 5)],
            lot: 'arcaniste'),
        CardDef('arcaniste_g2', 1, CType.skill, Tgt.single,
            [Eff('damage', 3), Eff('draw', 1)],
            lot: 'arcaniste'),
      ];
  }
  throw ArgumentError('lot inconnu : $lot');
}

/// Le draft de départ (validé : neutres et lot draftables, 5 cartes
/// distinctes, D49 sort les signatures du deck). DÉFAUT de la politique :
/// 2 cartes du lot et 3 neutres, dans un ordre fixe par classe.
const starterLotPicks = {
  'rempart': ['muraille', 'rempart_brise'],
  'croise': ['riposte', 'marteau_sacre'],
  'sanctifie': ['sommation', 'vigile'],
  'sang': ['sang_verse', 'demon_form'],
  'vampire': ['morsure', 'curee'],
  'carnage': ['moulinet', 'execution'],
  'voile': ['barriere', 'meditation'],
  'marque': ['fireball', 'thunder_clap'],
  'arcaniste': ['eclat', 'decharge'],
};
const starterNeutralPicks = {
  'paladin': ['strike_basic', 'defend_basic', 'iron_wall'],
  'berserker': ['strike_basic', 'heavy_strike', 'iron_wall'],
  'mage': ['strike_basic', 'defend_basic', 'awakening'],
};

/// Synthèse des reliques ajoutées par le brainstorm, absentes des données.
/// D31 : A « monte la chance de seconde carte en élite » (rareté DÉFAUT rare),
/// B « une épique » (+1 %), C « une carte garantie de plus » (DÉFAUT rare).
/// D42a : une légendaire porte au-delà de 1 le nombre de runes affûtées par
/// la récompense de boss « XP ».
const relicD31A = RelicDef('d31_a_elite', 2, 'special', 'd31a', 0);
const relicD31B = RelicDef('d31_b_lucky', 3, 'special', 'd31b', 0);
const relicD31C = RelicDef('d31_c_extra', 2, 'special', 'd31c', 0);
const relicD42 = RelicDef('d42_whetstone', 4, 'special', 'd42', 1);

class GameData {
  GameData._(this.enemies, this.neutrals, this.relics, this.rewards,
      this.classes, this.passives, this.runes, this.events);

  final List<EnemyDef> enemies;
  final Map<String, CardDef> neutrals;
  final List<RelicDef> relics;
  final List<RewardDef> rewards;
  final Map<String, ClassDef> classes;
  final Map<String, PassiveDef> passives;
  final List<RuneDef> runes;
  final List<EventDef> events;

  final Map<String, List<CardDef>> _lots = {};
  final Map<String, List<CardDef>> _pools = {};

  List<CardDef> lot(String id) =>
      _lots.putIfAbsent(id, () => lotCards(id, neutrals));

  /// Le pool offrable d'une run : noyau neutre + lot du passif actif (D16,
  /// §6 : `isOfferableTo` gagne `passive == run.activePassive`) — 15 cartes.
  List<CardDef> pool(String lotId) => _pools.putIfAbsent(lotId,
      () => [for (final id in coreNeutralIds) neutrals[id]!, ...lot(lotId)]);

  static GameData load() {
    final root = '${_findRoot().path}/assets/data';

    final enemies = <EnemyDef>[];
    for (final dir in Directory('$root/enemies').listSync().whereType<Directory>()) {
      final j = _json('${dir.path}/enemy.json');
      enemies.add(EnemyDef(
        j['id'] as String,
        j['maxHp'] as int,
        j['baseDamage'] as int,
        j['tier'] as int,
        j['xp'] as int,
        j['gold'] as int,
        j['critChance'] as int? ?? 0,
        [
          for (final i in (j['intents'] as List? ?? const []))
            ((i as Map<String, dynamic>)['type'] as String, i['value'] as int),
        ],
      ));
    }
    enemies.sort((a, b) => a.id.compareTo(b.id));

    final neutrals = <String, CardDef>{};
    for (final f in _jsonFiles('$root/cards')) {
      final c = cardFromJson(_json(f.path));
      neutrals[c.id] = c;
    }

    final relics = <RelicDef>[
      for (final f in _jsonFiles('$root/relics'))
        () {
          final j = _json(f.path);
          return RelicDef(
            j['id'] as String,
            relicRarities.indexOf(j['rarity'] as String),
            j['trigger'] as String,
            j['effectType'] as String,
            j['value'] as int? ?? 0,
          );
        }(),
    ];

    final rewards = <RewardDef>[
      for (final f in _jsonFiles('$root/level_up_rewards'))
        () {
          final j = _json(f.path);
          return RewardDef(
            j['id'] as String,
            j['effect'] as String,
            j['stat'] as String? ?? '',
            j['pool'] as String,
            (j['values'] as Map<String, dynamic>? ?? const {})
                .map((k, v) => MapEntry(k, v as int)),
          );
        }(),
    ];

    final passives = <String, PassiveDef>{};
    for (final f in _jsonFiles('$root/passives')) {
      final j = _json(f.path);
      final m = j['mastery'] as Map<String, dynamic>?;
      passives[j['id'] as String] = PassiveDef(
        j['id'] as String,
        j['value'] as int? ?? 0,
        j['duration'] as int? ?? 1,
        j['threshold'] as int? ?? 0,
        m?['field'] as String? ?? '',
        m?['perPoint'] as int? ?? 0,
      );
    }

    final classes = <String, ClassDef>{};
    for (final dir in Directory('$root/classes').listSync().whereType<Directory>()) {
      final j = _json('${dir.path}/class.json');
      final id = j['id'] as String;
      final signatures = <CardDef>[
        for (final f in _jsonFiles('${dir.path}/cards'))
          cardFromJson(
            _json(f.path),
            lot: 'sig',
            // DÉFAUT validé : recharge 2 pour les six (esquisse de `smite`, §4.4).
            cooldown: 2,
            // D28 : `magic_missile` devient une Compétence.
            typeOverride: f.path.contains('magic_missile') ? CType.skill : null,
          ),
      ];
      final rules = j['statRules'] as List? ?? const [];
      classes[id] = ClassDef(
        id,
        j['maxHp'] as int,
        j['maxMana'] as int,
        j['critChance'] as int? ?? 0,
        j['mastery'] as int? ?? 0,
        {for (final t in (j['mightTargets'] as List)) t as String},
        rules.any((r) => (r as Map<String, dynamic>)['mode'] == 'convert'),
        signatures,
        classLots[id]!,
      );
    }

    // Les runes, dans l'ordre que la référence a mesuré — les huit fichiers
    // d'avant E2 triés, puis les neuf du §8 — : la liste est tirée par index,
    // et un fichier neuf rangé au milieu décalerait tous les tirages (D73 ;
    // spec P-43 E2, §9). Chacune vient de son fichier s'il existe — poids et
    // types lus dans la donnée, condition et exclusions données par le
    // `switch` —, de son entrée en dur sinon. Éligibilité en donnée (D44).
    const runeOrder = [
      'burning', 'eco', 'enduring', 'freezing', 'hardened', 'quick', 'sharp',
      'shocking', 'cheap', 'piercing', 'lifesteal', 'transfusion', 'precise',
      'splash', 'echo', 'retain', 'spectral',
    ];
    // §8 — les runes sans fichier. DÉFAUT : poids 50, `minFusionRank` 1.
    const hardRunes = {
      'piercing': RuneDef('piercing', 50, needs: 'damage'),
      'lifesteal': RuneDef('lifesteal', 50, needs: 'damage'),
      'transfusion': RuneDef('transfusion', 50, needs: 'hpCost'), // D40
      'splash': RuneDef('splash', 50, needs: 'singleDamage'),
      'echo': RuneDef('echo', 50),
      'retain': RuneDef('retain', 50),
    };
    final fromFiles = <String, RuneDef>{};
    for (final f in _jsonFiles('$root/forge_upgrades')) {
      final j = _json(f.path);
      final id = j['id'] as String;
      if (!runeOrder.contains(id)) {
        throw StateError('rune « $id » (${f.path}) absente de runeOrder : '
            'lui donner sa place dans la liste tirée par index');
      }
      final weight = j['weight'] as int? ?? 50;
      final types = [for (final t in (j['eligibleCardTypes'] as List? ?? const [])) t as String];
      fromFiles[id] = switch (id) {
        // D33 : en pourcentage de la valeur de base — DÉFAUT : éligible à
        // toute carte qui porte l'effet (sans quoi aucune Compétence de
        // dégâts du Mage ne prend de rune de dégâts).
        'sharp' => RuneDef(id, weight, needs: 'damage'),
        'hardened' => RuneDef(id, weight, needs: 'armor'),
        // §8 : `requiresMinCost: 1` ; `cheap` exclut `eco` (D44) ; `enduring`
        // exclut `eco` et `quick` (D51) — DÉFAUT : l'exclusion vaut dans les
        // deux sens.
        'eco' => RuneDef(id, weight,
            types: types, needs: 'cost1', excludes: const ['cheap', 'enduring']),
        'quick' => RuneDef(id, weight, types: types, excludes: const ['enduring']),
        // D44 : `excludesEffects: ["gain_mana", "draw"]` ; D51 : `excludesRunes`.
        'enduring' => RuneDef(id, weight,
            types: types, needs: 'exhaustNoEngine', excludes: const ['eco', 'quick']),
        // §8, fichiers d'E2 (spec P-43 E2, §3.2) : la définition qu'avait leur
        // entrée en dur.
        'cheap' => RuneDef(id, weight, needs: 'cost1', excludes: const ['eco']),
        'precise' => RuneDef(id, weight, needs: 'damage'),
        'spectral' => RuneDef(id, weight, needs: 'damage'),
        _ => RuneDef(id, weight, types: types),
      };
    }
    final runes = [
      for (final id in runeOrder)
        fromFiles[id] ??
            hardRunes[id] ??
            (throw StateError('rune « $id » : ni fichier ni entrée en dur')),
    ];

    final events = <EventDef>[
      for (final f in _jsonFiles('$root/events'))
        () {
          final j = _json(f.path);
          return EventDef(j['id'] as String, [
            for (final c in (j['choices'] as List))
              [
                for (final a in ((c as Map<String, dynamic>)['actions'] as List? ?? const []))
                  ((a as Map<String, dynamic>)['type'] as String, a['value'] as int? ?? 0),
              ],
          ]);
        }(),
    ];

    return GameData._(
        enemies, neutrals, relics, rewards, classes, passives, runes, events);
  }
}

GameData? _dataCache;
GameData get data => _dataCache ??= GameData.load();

// ===========================================================================
// 5. La carte d'un acte — portage du générateur
// ===========================================================================

class MapNode {
  MapNode(this.id, this.floor, this.type, this.bossReward);

  final int id;
  final int floor;

  /// combat, elite, rest, shop, event, boss, well (Puits), altar (Autel).
  String type;

  /// cards, xp, relic — map_node_generator.dart:54-60.
  final String bossReward;
  final List<int> conns = [];
}

/// map_node_generator.dart:6-15.
String randomNodeType(int floor, Random rng) {
  if (floor == 0) return 'combat';
  final r = rng.nextDouble();
  if (r < 0.6) return 'combat';
  if (r < 0.75) return 'event';
  if (r < 0.85) return 'shop';
  if (r < 0.95) return 'rest';
  return 'elite';
}

bool _isForcedFloor(int y) =>
    y == 0 || y == middleFloor || y == floors - 2 || y == floors - 1;

/// map_generator_service.dart:14-53.
List<MapNode> generateMap(int act, Random rng, Params p) {
  // map_node_generator.dart:17-83
  final byFloor = <List<MapNode>>[];
  final all = <MapNode>[];
  for (var y = 0; y < floors; y++) {
    var width = 2 + rng.nextInt(maxWidth - 1);
    if (y == middleFloor) width = 1;
    if (y == floors - 1) width = 3;
    final row = <MapNode>[];
    for (var x = 0; x < width; x++) {
      var type = randomNodeType(y, rng);
      var reward = '';
      if (y == middleFloor) {
        type = 'elite';
      } else if (y == floors - 2) {
        type = 'rest';
      } else if (y == floors - 1) {
        type = 'boss';
        reward = const ['cards', 'xp', 'relic'][x];
      }
      final node = MapNode(all.length, y, type, reward);
      row.add(node);
      all.add(node);
    }
    byFloor.add(row);
  }
  // map_connection_builder.dart:10-55
  for (var y = 0; y < floors - 1; y++) {
    final cur = byFloor[y];
    final next = byFloor[y + 1];
    for (var i = 0; i < cur.length; i++) {
      final base = (i * next.length / cur.length).floor();
      final count = 1 + rng.nextInt(2);
      final targets = <int>{};
      for (var j = 0; j < count; j++) {
        targets.add((base + rng.nextInt(3) - 1).clamp(0, next.length - 1));
      }
      for (final t in targets) {
        cur[i].conns.add(next[t].id);
      }
    }
    for (var j = 0; j < next.length; j++) {
      if (!cur.any((n) => n.conns.contains(next[j].id))) {
        cur[(j * cur.length / next.length).floor()].conns.add(next[j].id);
      }
    }
  }
  _optimizeMapTypes(all, rng);
  _placeSpecial(all, act, rng, p);
  return all;
}

List<MapNode> _preds(MapNode node, List<MapNode> all) =>
    [for (final n in all) if (n.conns.contains(node.id)) n];

/// map_validator.dart:202-224.
bool _hasThreeConsecutive(MapNode node, List<MapNode> all, String type, int len) {
  if (node.type != type) return false;
  if (len == 3) return true;
  for (final pred in _preds(node, all)) {
    if (pred.type == type && _hasThreeConsecutive(pred, all, type, len + 1)) {
      return true;
    }
  }
  return false;
}

/// map_validator.dart:226-246.
List<MapNode> _chainOfThree(MapNode node, List<MapNode> all, String type) {
  final chain = [node];
  final preds = [for (final n in _preds(node, all)) if (n.type == type) n];
  if (preds.isNotEmpty) {
    chain.add(preds.first);
    final pp = [for (final n in _preds(preds.first, all)) if (n.type == type) n];
    if (pp.isNotEmpty) chain.add(pp.first);
  }
  return chain;
}

bool _violates(List<MapNode> all, String type) =>
    all.any((n) => n.type == type && _hasThreeConsecutive(n, all, type, 1));

/// map_validator.dart:6-37.
void _optimizeMapTypes(List<MapNode> all, Random rng) {
  for (var iter = 0; iter < 15; iter++) {
    _balanceQuotas(all);
    var changed = false;
    for (final node in all) {
      if ((node.type == 'elite' || node.type == 'rest') &&
          _hasThreeConsecutive(node, all, node.type, 1)) {
        for (final c in _chainOfThree(node, all, node.type)) {
          if (!_isForcedFloor(c.floor)) {
            c.type = const ['combat', 'shop', 'event'][rng.nextInt(3)];
            changed = true;
            break;
          }
        }
        if (changed) break;
      }
    }
    if (!changed) break;
  }
  _balanceQuotas(all);
}

/// map_validator.dart:39-200.
void _balanceQuotas(List<MapNode> all) {
  for (var attempt = 0; attempt < 100; attempt++) {
    final counts = <String, int>{};
    for (final n in all) {
      counts[n.type] = (counts[n.type] ?? 0) + 1;
    }
    int count(String t) => counts[t] ?? 0;
    int minOf(String t) => nodeQuotas[t]?[0] ?? 0;

    String? deficient;
    for (final e in nodeQuotas.entries) {
      if (count(e.key) < e.value[0]) {
        deficient = e.key;
        break;
      }
    }
    if (deficient != null) {
      MapNode? cand;
      for (final n in all) {
        if (_isForcedFloor(n.floor) || count(n.type) <= minOf(n.type)) continue;
        final orig = n.type;
        n.type = deficient;
        final bad = (deficient == 'elite' || deficient == 'rest') &&
            _violates(all, deficient);
        n.type = orig;
        if (!bad) {
          cand = n;
          break;
        }
      }
      if (cand == null) {
        for (final n in all) {
          if (!_isForcedFloor(n.floor) && count(n.type) > minOf(n.type)) {
            cand = n;
            break;
          }
        }
      }
      if (cand == null) break;
      cand.type = deficient;
      continue;
    }

    String? excessive;
    for (final e in nodeQuotas.entries) {
      if (count(e.key) > e.value[1]) {
        excessive = e.key;
        break;
      }
    }
    if (excessive != null) {
      String? target;
      for (final e in nodeQuotas.entries) {
        if (count(e.key) < e.value[1] && e.key != excessive) {
          target = e.key;
          break;
        }
      }
      MapNode? cand;
      if (target != null) {
        for (final n in all) {
          if (_isForcedFloor(n.floor) || n.type != excessive) continue;
          n.type = target;
          final bad =
              (target == 'elite' || target == 'rest') && _violates(all, target);
          n.type = excessive;
          if (!bad) {
            cand = n;
            break;
          }
        }
        if (cand == null) {
          for (final n in all) {
            if (!_isForcedFloor(n.floor) && n.type == excessive) {
              cand = n;
              break;
            }
          }
        }
      }
      if (cand == null || target == null) break;
      cand.type = target;
      continue;
    }
    break;
  }
}

/// map_content_placer.dart:5-38 ; le Puits au rythme de D22.
void _placeSpecial(List<MapNode> all, int act, Random rng, Params p) {
  final altar = switch (p.altar) {
    'none' => false,
    'every3' => act >= 4 && (act - 4) % 3 == 0,
    _ => act >= 5 && (act % 5 == 0 || rng.nextDouble() < 0.10), // :10
  };
  if (altar) {
    final elig = [
      for (final n in all)
        if (const [2, 3, 4, 6, 7].contains(n.floor)) n, // :11-14
    ];
    if (elig.isNotEmpty) elig[rng.nextInt(elig.length)].type = 'altar';
  }
  // D22 : garanti tous les N actes ; sinon aujourd'hui, 25 % par carte (:24).
  final well =
      p.wellEvery > 0 ? act % p.wellEvery == 0 : rng.nextDouble() < 0.25;
  if (well) {
    final elig = [
      for (final n in all)
        if (n.floor >= 3 &&
            n.floor <= 7 &&
            (n.type == 'combat' || n.type == 'event'))
          n, // :25-30
    ];
    if (elig.isNotEmpty) elig[rng.nextInt(elig.length)].type = 'well';
  }
}

// ===========================================================================
// 6. Les rencontres — portage d'encounter_system.dart
// ===========================================================================

int _bracket(int act) => (act - 1) ~/ 2; // :23, :28

double hpActFactor(int act) => // :19, :21, :36-42
    pow(1.35, _bracket(act)).toDouble() * (1 + ((act - 1) % 2) * 0.05);

double dmgActFactor(int act) => // :20, :22, :45-51
    pow(1.25, _bracket(act)).toDouble() * (1 + ((act - 1) % 2) * 0.03);

int unlockedTier(int act) => min(3, 1 + (act - 1) ~/ 5); // :55-58

int maxEnemiesFor(int act, bool boss, bool elite) => // :60-79
    1 + (act - 1) ~/ (boss ? 5 : (elite ? 2 : 1));

int enemyLevelFor(int playerLevel, bool boss, bool elite) => // :136-148
    max(1, playerLevel + (boss ? 2 : (elite ? 1 : 0)));

double _nodeMult(bool boss, bool elite) => boss ? 3.0 : (elite ? 1.5 : 1.0);

double hpMultFor(int eL, int act, bool boss, bool elite) => // :151-162
    (1 + 0.06 * (eL - 1)) * hpActFactor(act) * _nodeMult(boss, elite);

double dmgMultFor(int eL, int act, bool boss, bool elite) => // :165-176
    (1 + 0.04 * (eL - 1)) * dmgActFactor(act) * _nodeMult(boss, elite);

/// PlayerPower et budget final — encounter_system.dart:86-131 ; le terme de
/// deck `deckTerm` est `cartes × 2` aujourd'hui (:101), `k × Σ fusionRank`
/// sous D47.
({double power, double budget}) budgetFor({
  required int level,
  required int act,
  required int maxHp,
  required int might,
  required int maxMana,
  required int relics,
  required double deckTerm,
  required bool boss,
  required bool elite,
}) {
  final power =
      maxHp + might * 10.0 + maxMana * 15.0 + relics * 5.0 + deckTerm;
  final expected = 145.0 + (level - 1) * 15.0 + (act - 1) * 20.0;
  final base = 40.0 + (level - 1) * 10.0 + (act - 1) * 25.0;
  final modifier = 1.0 + (power / expected - 1.0) * 0.5;
  final node = boss ? 2.0 : (elite ? 1.5 : 1.0);
  return (power: power, budget: base * modifier * node + (act - 1) * 10.0);
}

/// encounter_system.dart:179-208.
double combatRating(EnemyDef e, int eL, int act, bool boss, bool elite) {
  final hp = (e.maxHp * hpMultFor(eL, act, boss, elite)).round();
  final dmg = (e.baseDamage * dmgMultFor(eL, act, boss, elite)).round();
  return e.tier * 15.0 + hp / 4.0 + (dmg * 2.0) * (1.0 + e.crit / 100.0);
}

/// encounter_system.dart:210-304 : tirage uniforme sous budget.
List<EnemyDef> generateEnemies(
    double budget, int act, int eL, bool boss, bool elite, Random rng) {
  final tier = unlockedTier(act);
  final eligible = [for (final e in data.enemies) if (e.tier <= tier) e];
  final pool = eligible.isNotEmpty ? eligible : data.enemies;
  final rating = {for (final e in pool) e.id: combatRating(e, eL, act, boss, elite)};
  final out = <EnemyDef>[];
  var remaining = budget;
  while (remaining > 0 && out.length < maxEnemiesFor(act, boss, elite)) {
    final cands = [for (final e in pool) if (rating[e.id]! <= remaining) e];
    if (cands.isEmpty) break;
    final chosen = cands[rng.nextInt(cands.length)];
    out.add(chosen);
    remaining -= rating[chosen.id]!;
  }
  if (out.isEmpty) {
    var lowest = pool.first;
    for (final e in pool) {
      if (rating[e.id]! < rating[lowest.id]!) lowest = e;
    }
    out.add(lowest);
  }
  return out;
}

// ===========================================================================
// 7. Cartes en jeu : rang de fusion, runes, valeurs
// ===========================================================================

class CardInst {
  CardInst(this.def, this.rank, [Map<String, int>? runes])
      : runes = runes ?? <String, int>{};

  final CardDef def;

  /// Le `fusionRank` (D28) : 0 commune … 4 légendaire.
  final int rank;

  /// `id → niveau` : le format `id:tier` de `forgeUpgrades` (§4.2).
  final Map<String, int> runes;

  String get key => '${def.id}#$rank';

  CardInst copy({bool withRunes = true}) =>
      CardInst(def, rank, withRunes ? Map.of(runes) : null);

  /// `cheap` : −1 coût, minimum 0 (§8).
  int get cost => max(0, def.cost - (runes.containsKey('cheap') ? 1 : 0));

  int get runeLevels => runes.values.fold(0, (a, b) => a + b);
}

/// Valeur d'un effet à un rang : multiplicateur de rareté
/// (card_instance.dart:35-50, arrondi effect_resolver.dart:224) et monotonie
/// stricte G1 (§4.5) : chaque rang change le chiffre.
int scaled(int base, int rank) {
  if (base <= 0) return base;
  var v = base;
  for (var r = 1; r <= rank; r++) {
    v = max((base * rarityMult[r]).round(), v + 1);
  }
  return v;
}

/// Rune en pourcentage (D33, §8) : +[p] % de la valeur de base de la carte
/// par niveau, au moins +1 par niveau — `sharp` et `hardened` à 15,
/// `spectral` à 40 (spec P-43 E2, A10, §9). L'ordre des opérations est celui
/// d'avant le paramètre : `15 / 100` est le même flottant que `0.15`, et le
/// produit se fait de gauche à droite — `sharp` et `hardened` ne bougent pas
/// au bit près.
int percentRuneBonus(int cardValue, int level, int p) =>
    max((p / 100 * level * cardValue).round(), level);

/// D48 : `eco` et `quick` à `minFusionRank` 2 ; les autres à 1 (DÉFAUT).
int minRankOf(String id, Params p) =>
    (id == 'eco' || id == 'quick') ? p.ecoQuickMinRank : 1;

/// Runes binaires ou à niveau unique (D27, §8).
const binaryRunes = {'eco', 'quick', 'enduring', 'retain', 'cheap', 'transfusion'};

/// `maxLevel` de base d'une rune (D27, table du §8), avant la mythique D42c.
int? baseMaxLevel(String id, Params p) {
  if (binaryRunes.contains(id)) return 1;
  switch (p.maxLevelTable) {
    case 'uncapped':
      return null;
    case 'cap5':
      return 5;
  }
  return switch (id) {
    'freezing' => 1,
    'piercing' => 4,
    'lifesteal' => 3,
    'precise' => 10,
    'splash' => 3,
    'echo' => 4,
    _ => null,
  };
}

/// Éligibilité d'une rune à une carte qui atteint [rank] (§4.2 : id absent de
/// la carte, `minFusionRank ≤ rang atteint` ; D44 : règles en donnée).
bool runeEligible(RuneDef r, CardInst c, int rank, Params p) {
  if (c.runes.containsKey(r.id) || minRankOf(r.id, p) > rank) return false;
  final d = c.def;
  if (r.types.isNotEmpty && !r.types.contains(d.type.name)) return false;
  for (final x in r.excludes) {
    if (c.runes.containsKey(x)) return false;
  }
  return switch (r.needs) {
    'damage' => d.hasDamage,
    'armor' => d.has('armor'),
    'cost1' => d.cost >= 1,
    'exhaustNoEngine' => d.exhaust && !d.has('draw') && !d.has('mana'),
    'hpCost' => d.hpCost > 0,
    'singleDamage' => d.hasDamage && d.target == Tgt.single,
    _ => true,
  };
}

// ===========================================================================
// 8. Le combat abstrait — tours, pioche, Puissance, PV
// ===========================================================================
//
// Pas le moteur du jeu : un ordre de grandeur (mission). Une main de 5 tirée
// du deck, 3 mana, une IA gloutonne (valeur estimée par mana), les ennemis
// qui frappent selon leurs intentions, l'armure qui absorbe. Il sert deux
// mesures : les PV perdus par combat (le repos en dépend, point 3 validé) et
// les dégâts d'un tour contre un mannequin.

class Foe {
  Foe(this.def, this.hp, this.atk, this.crit) : maxHp = hp;

  final EnemyDef def;
  int hp;
  final int maxHp;

  /// `might / baseDamage` : le multiplicateur d'intention
  /// (enemy_instance.dart:20-23).
  final double atk;
  final int crit;
  int step = 0;
  int bonus = 0;

  /// id → [valeur, durée] ; cumul `StatusEffect.combine` : valeurs sommées,
  /// durée max (status_effect.dart:17).
  final Map<String, List<int>> st = {};

  bool get alive => hp > 0;
  bool has(String id) => st.containsKey(id);
  int v(String id) => st[id]?[0] ?? 0;

  (String, int) get intent => def.intents.isEmpty
      ? ('attack', def.baseDamage)
      : def.intents[step % def.intents.length];
}

class FightResult {
  const FightResult(this.turns, this.dmgPerTurn, this.stalemate, this.damageTaken);

  final int turns;
  final double dmgPerTurn;
  final bool stalemate;

  /// Les PV que le combat a coûtés, sans le plancher à 1.
  final int damageTaken;
}

class Fight {
  Fight(this.run, this.foes, {this.mannequin = false})
      : hp = run.hp,
        sigs = [for (final s in run.cls.signatures) CardInst(s, 0)];

  final Run run;
  final List<Foe> foes;
  final bool mannequin;
  final List<CardInst> sigs;

  int hp;
  int armor = 0;
  int mana = 0;
  int reserve = 0;
  final List<List<int>> mightSt = [];
  final List<List<int>> armorRegen = [];
  final List<List<int>> mightRegen = [];
  final List<List<int>> manaRegen = [];
  final List<List<int>> hpRegen = [];
  int lsVal = 0;
  int lsDur = 0;
  final List<CardInst> drawPile = [];
  final List<CardInst> hand = [];
  final List<CardInst> discard = [];
  final Map<CardDef, int> sigReady = {};
  int turn = 1;
  int attacksThisTurn = 0;
  bool markUsed = false;
  int skillCount = 0;
  int damageTaken = 0;
  final List<double> dmgByTurn = [];

  Random get rng => run.rng;
  int get maxHp => run.maxHp;
  int get mightNow => run.might + mightSt.fold(0, (a, s) => a + s[0]);
  bool get allDead => foes.every((f) => !f.alive);

  int mightFor(CType t) => run.targetsType(t) ? mightNow : 0;
  int get altBonus => run.cls.mightTargets.contains('alteration') ? mightNow : 0;

  /// Les 5 premiers ennemis vivants (combat_controller.dart:169).
  List<Foe> get active {
    final out = <Foe>[];
    for (final f in foes) {
      if (f.alive) {
        out.add(f);
        if (out.length == maxActiveEnemies) break;
      }
    }
    return out;
  }

  /// La cible : l'ennemi actif le plus entamé (politique DÉFAUT).
  Foe? get target {
    Foe? best;
    for (final f in active) {
      if (best == null || f.hp < best.hp) best = f;
    }
    return best;
  }

  void drawN(int n) {
    for (var i = 0; i < n; i++) {
      if (hand.length >= maxHandSize) return; // deck_controller.dart:200
      if (drawPile.isEmpty) {
        if (discard.isEmpty) return;
        discard.shuffle(rng);
        drawPile.addAll(discard);
        discard.clear();
      }
      hand.add(drawPile.removeLast());
    }
  }

  /// Un gain d'armure passe par `StatGains` : chez le Berserker, il devient
  /// Puissance pour le tour, au ratio 0,5 arrondi au-dessus (D37).
  void gainArmor(int a) {
    if (a <= 0) return;
    if (run.cls.convertsArmor) {
      mightSt.add([(a * 0.5).ceil(), 1]);
    } else {
      armor += a;
    }
  }

  void heal(int a) => hp = min(maxHp, hp + max(0, a));

  Iterable<RelicDef> relicsOn(String trigger) =>
      run.relics.where((r) => r.trigger == trigger);

  /// run_controller.dart:428-441, turn_phase_manager.dart:27-41.
  void startCombat() {
    mana = run.maxMana;
    for (final r in relicsOn('startOfCombat')) {
      if (r.effect == 'gain_armor') gainArmor(r.value);
      if (r.effect == 'gain_mana') mana += r.value;
    }
    passiveStartOfTurn(0);
    drawPile.addAll(run.deck);
    drawPile.shuffle(rng);
    drawN(run.cardsPerTurn);
    for (final s in sigs) {
      sigReady[s.def] = 1; // D41 : disponibles dès le tour 1
    }
  }

  /// run_controller.dart:443-478 et status_effect_processor.dart:12-66.
  void startTurn() {
    final surviving = armor;
    armor = 0;
    mana = run.maxMana + reserve; // D30 : la réserve de Canalisation
    reserve = 0;
    for (final r in relicsOn('startOfTurn')) {
      if (r.effect == 'gain_mana') mana += r.value;
      if (r.effect == 'gain_armor') gainArmor(r.value);
    }
    final mightGain = mightRegen.fold(0, (a, s) => a + s[0]);
    final armorGain = armorRegen.fold(0, (a, s) => a + s[0]);
    final manaGain = manaRegen.fold(0, (a, s) => a + s[0]);
    final hpGain = hpRegen.fold(0, (a, s) => a + s[0]);
    if (mightGain > 0) mightSt.add([mightGain, 3]); // :34-44
    heal(hpGain); // `hp_regen` de Prière (D55), sur ce modèle
    for (final list in [mightSt, armorRegen, mightRegen, manaRegen, hpRegen]) {
      for (final s in list) {
        s[1]--;
      }
      list.removeWhere((s) => s[1] <= 0);
    }
    if (lsDur > 0 && --lsDur == 0) lsVal = 0;
    gainArmor(armorGain); // :57-63, après le tic
    mana += manaGain; // `mana_regen` de Méditation (§7.3), sur ce modèle
    passiveStartOfTurn(surviving);
    drawN(run.cardsPerTurn);
  }

  void passiveStartOfTurn(int surviving) {
    switch (run.passive.id) {
      case 'rage': // passive_strategies.dart:163-178
        mightSt.add([run.passiveValue() * (1 + (maxHp - hp) ~/ 10), 1]);
      case 'blessing': // passive_strategies.dart:141-155 ; D43
        heal((surviving ~/ run.blessingThreshold()) * run.blessingValue());
    }
  }

  void endTurn() {
    switch (run.passive.id) {
      case 'regen_armor': // passive_strategies.dart:24-31
        gainArmor(run.passiveValue());
      case 'channeling': // D30 : réserve, plafond maxMana + Maîtrise
        reserve = min(mana, run.maxMana + run.mastery);
    }
    for (final r in relicsOn('endOfTurn')) {
      if (r.effect == 'heal') heal(r.value);
      if (r.effect == 'gain_armor') gainArmor(r.value);
    }
    final kept = [for (final c in hand) if (c.runes.containsKey('retain')) c];
    discard.addAll(hand.where((c) => !c.runes.containsKey('retain')));
    hand
      ..clear()
      ..addAll(kept);
  }

  int foeAttack(Foe f) {
    final (type, value) = f.intent;
    if (type != 'attack') return 0;
    var dmg = (value * f.atk).round() + f.bonus;
    if (f.has('freeze')) dmg = (dmg * 0.5).round(); // enemy_instance.dart:28-29
    if (f.has('weakness')) dmg = (dmg * 0.75).round(); // damage_pipeline.dart:15-18
    return dmg;
  }

  int get incoming => active.fold(0, (a, f) => a + foeAttack(f));

  /// Le tour ennemi (turn_phase_manager.dart:61-75, combat_controller.dart).
  /// DÉFAUT : les statuts vieillissent après l'attaque, pour que `freeze`
  /// (1 tour) touche l'intention qu'il affiche.
  void enemyTurn() {
    for (final f in foes) {
      if (!f.alive) continue;
      final dot = f.v('poison') + f.v('burn'); // status_effect_processor.dart:70-94
      if (dot > 0) applyDamage(f, dot);
    }
    if (allDead) return;
    for (final f in active) {
      final (type, value) = f.intent;
      if (type == 'attack') {
        // crit ennemi en espérance, ×1,5 (entity_stats.dart:38)
        final dmg = (foeAttack(f) * (1 + f.crit / 100 * 0.5)).round();
        final absorbed = min(armor, dmg);
        armor -= absorbed;
        hp -= dmg - absorbed;
        damageTaken += dmg - absorbed;
        if (absorbed > 0 && run.passive.id == 'fervor') {
          mightSt.add([run.passiveValue(), run.passiveDuration()]); // :124-131
        }
        if (hp <= 0) {
          // Pas de mort (point 3 validé) : PV plancher 1, quasi-mort comptée.
          if (!mannequin) {
            run.inc('nearDeaths');
            run.firsts.putIfAbsent('firstNearDeath', () => run.act);
          }
          hp = 1;
        }
      } else if (type == 'buff') {
        f.bonus += value;
      }
      f.step++;
    }
    for (final f in foes) {
      for (final s in f.st.values) {
        s[1]--;
      }
      f.st.removeWhere((_, s) => s[1] <= 0);
    }
  }

  int applyDamage(Foe f, int dmg) {
    if (dmg <= 0) return 0;
    final effective = min(dmg, f.hp);
    dmgByTurn[turn - 1] += dmg;
    f.hp -= dmg;
    if (!f.alive) onKill();
    return effective;
  }

  void onKill() {
    if (run.passive.id == 'frenzy') {
      mightSt.add([run.passiveValue(), 1]); // passive_strategies.dart:210-222
      drawN(1);
    }
    for (final r in relicsOn('onEnemyKilled')) {
      if (r.effect == 'heal') heal(r.value);
      if (r.effect == 'gain_mana') mana += r.value;
    }
  }

  void addFoeStatus(Foe f, String id, int value, int duration) {
    final s = f.st[id];
    if (s == null) {
      f.st[id] = [value, duration];
    } else {
      s[0] += value;
      s[1] = max(s[1], duration);
    }
  }

  void addSelfStatus(String id, int value, int duration) {
    switch (id) {
      case 'might':
        mightSt.add([value, duration]); // D36 : un statut par source
      case 'armor_regen':
        armorRegen.add([value, duration]);
      case 'might_regen':
        mightRegen.add([value, duration]);
      case 'mana_regen':
        manaRegen.add([value, duration]);
      case 'hp_regen':
        hpRegen.add([value, duration]);
    }
  }

  bool playable(CardInst c) =>
      c.cost <= mana &&
      (c.def.hpCost == 0 || hp > c.def.hpCost) && // D40 : PV > coût
      armor >= c.def.armorCost;

  double _critE(CardInst c) {
    final p = min(1.0, (run.crit + 5 * (c.runes['precise'] ?? 0)) / 100.0);
    return 1 + p * (run.critMult - 1);
  }

  double _scaleTerm(Eff e) => switch (e.scale) {
        'armor' => armor.toDouble(),
        'missingHp' => 0.2 * (maxHp - hp),
        'attacksPlayed' => 2.0 * attacksThisTurn,
        _ => 0.0,
      };

  /// Valeur par coup avant Puissance : base au rang, parts de `sharp` et de
  /// `spectral` (D33 ; spec P-43 E2, A10), terme `scaleWith` jamais multiplié
  /// par la rareté (§9.2 #1). Chaque part se calcule sur la base au rang,
  /// coups additionnés puis répartis ; aucune ne porte sur l'autre.
  double _perHit(CardInst c, Eff e) {
    final base = scaled(e.value, c.rank);
    final sharp = c.runes['sharp'];
    final spectral = c.runes['spectral'];
    final share = sharp == null
        ? 0.0
        : percentRuneBonus(max(0, base) * e.hits, sharp, 15) / e.hits;
    final spectralShare = spectral == null
        ? 0.0
        : percentRuneBonus(max(0, base) * e.hits, spectral, 40) / e.hits;
    return base + share + spectralShare + _scaleTerm(e);
  }

  int _armorOf(CardInst c, Eff e) {
    final base = scaled(e.value, c.rank);
    final h = c.runes['hardened'];
    return base + (h == null ? 0 : percentRuneBonus(base, h, 15));
  }

  /// Coups qui recevront la Puissance après [c], dans le mana restant.
  double _followHits(CardInst c) {
    var budget = mana - c.cost;
    var hits = 0.0;
    final others = [
      ...hand.where((o) => o != c),
      ...sigs.where((s) => s != c && sigReady[s.def]! <= turn),
    ]..sort((a, b) => a.cost.compareTo(b.cost));
    for (final o in others) {
      if (o.cost > budget || !o.def.hasDamage || !run.targetsType(o.def.type)) {
        continue;
      }
      budget -= o.cost;
      for (final e in o.def.effects) {
        if (e.kind == 'damage') {
          hits += e.hits *
              mightRatioOf(o.def, e, run.p) *
              (o.def.target == Tgt.all ? active.length : 1);
        }
      }
    }
    return hits;
  }

  /// L'IA : la valeur estimée d'une carte jouée maintenant, en points de
  /// dégâts. Des poids de politique (DÉFAUT), pas des règles du jeu.
  double estimate(CardInst c) {
    final d = c.def;
    final r = c.runes;
    final tgt = target;
    if (tgt == null) return 0;
    final mt = mightFor(d.type).toDouble();
    final critE = _critE(c);
    final follow = _followHits(c);
    final inc = incoming;
    final residual = switch (run.passive.id) {
      'blessing' => 0.4,
      'fervor' => 0.3,
      _ => 0.1,
    };
    var v = 0.0;
    for (final e in d.effects) {
      switch (e.kind) {
        case 'damage':
          for (final f in d.target == Tgt.all ? active : [tgt]) {
            var x = _perHit(c, e) + mt * mightRatioOf(d, e, run.p);
            if (e.scale == 'lowHpX2' && f.hp < 0.3 * f.maxHp) x *= 2;
            if (e.scale == 'vulnX2' && f.has('vulnerable')) x *= 2;
            x = x * critE + f.v('shock');
            if (f.has('vulnerable')) x *= 1.5;
            final total = x * e.hits;
            v += min(total, f.hp.toDouble());
            if (total >= f.hp) {
              v += 0.6 * foeAttack(f) + (run.passive.id == 'frenzy' ? 4 : 0);
            }
            final splash = r['splash'];
            if (splash != null && d.target == Tgt.single) {
              v += (active.length - 1) * x * 0.25 * splash * e.hits;
            }
          }
          if (lsDur > 0) v += 0.5 * min(lsVal, maxHp - hp);
        case 'armor':
          final a = _armorOf(c, e);
          if (run.cls.convertsArmor) {
            v += (a * 0.5).ceil() * follow;
          } else {
            v += 0.9 * min(a, max(0, inc - armor)) + residual * a;
          }
        case 'draw':
          if (hand.length < maxHandSize &&
              (drawPile.isNotEmpty || discard.isNotEmpty)) {
            v += 2.5 * e.value;
          }
        case 'mana':
          v += 3.5 * e.value;
        case 'heal':
          v += 0.6 * min(scaled(e.value, c.rank), maxHp - hp);
        case 'self':
          v += _selfValue(e.status, scaled(e.value, c.rank), e.duration, follow);
        case 'enemy':
          final val = scaled(e.value, c.rank) + altBonus;
          for (final f in d.target == Tgt.all ? active : [tgt]) {
            v += switch (e.status) {
              'burn' || 'poison' => min(val * e.duration, f.hp).toDouble(),
              'shock' => val * (follow + 2.0),
              'weakness' => 0.25 * foeAttack(f) * e.duration * 0.9,
              'vulnerable' => 3.0 * follow + 2.0 * e.duration,
              'freeze' => 0.5 * foeAttack(f),
              _ => 0.0,
            };
          }
      }
    }
    if (d.type == CType.attack) {
      final alt = altBonus;
      v += ((r['burning'] ?? 0) > 0 ? (r['burning']! + alt) * r['burning']! : 0) +
          ((r['shocking'] ?? 0) > 0 ? (r['shocking']! + alt) * 2.0 : 0) +
          ((r['freezing'] ?? 0) > 0 ? 0.5 * foeAttack(tgt) : 0);
    }
    if (r.containsKey('quick')) v += 2.5;
    if (r.containsKey('eco')) v += 3.5;
    final echo = r['echo'];
    if (echo != null) v *= 1 + 0.15 * echo;
    if (d.hpCost > 0) v -= d.hpCost * (run.passive.id == 'rage' ? 0.1 : 0.5);
    if (d.armorCost > 0) {
      v -= 0.9 * min(d.armorCost, max(0, inc - armor + d.armorCost));
    }
    switch (run.passive.id) {
      case 'mana_flux':
        if (d.type == CType.skill) {
          v += skillCount + 1 >= run.fluxThreshold() ? 3.5 : 1.0;
        }
      case 'mage_mark':
        if (d.hasDamage && !markUsed) v += 2.0;
      case 'bloodthirst':
        if (d.type == CType.attack) v += 1.0;
    }
    return v;
  }

  double _selfValue(String status, int value, int duration, double follow) {
    final mightUseful = run.cls.mightTargets.contains('attack') ||
        run.cls.mightTargets.contains('skill');
    return switch (status) {
      'might' => mightUseful ? value * follow + value * (duration - 1) * 1.5 : 0.0,
      'armor_regen' => run.cls.convertsArmor
          ? (value * 0.5).ceil() * 1.2 * duration
          : value * duration * 0.6,
      'might_regen' => value * duration * 1.8,
      'mana_regen' => value * duration * 3.5,
      'hp_regen' => 0.6 * min(value * duration, maxHp - hp),
      _ => 0.0,
    };
  }

  /// La résolution d'une carte (effect_resolver.dart:130-235).
  void play(CardInst c, {bool isSig = false}) {
    final d = c.def;
    mana -= c.cost;
    hp -= d.hpCost;
    armor -= d.armorCost;
    if (isSig) {
      sigReady[d] = turn + d.cooldown; // D49 : recharge en tours
    } else {
      hand.remove(c);
    }
    final r = c.runes;
    final quick = r['quick'];
    if (quick != null) drawN(quick); // :167-169
    final eco = r['eco'];
    if (eco != null) mana += eco; // :170-173
    final tgt = target;
    if (d.type == CType.attack && tgt != null) {
      // Runes élémentaires, avant les effets (:176-219).
      final alt = altBonus;
      for (final f in d.target == Tgt.all ? active : [tgt]) {
        final burn = r['burning'];
        if (burn != null) addFoeStatus(f, 'burn', burn + alt, burn);
        final freeze = r['freezing'];
        if (freeze != null) addFoeStatus(f, 'freeze', freeze + alt, freeze);
        final shock = r['shocking'];
        if (shock != null) addFoeStatus(f, 'shock', shock + alt, shock);
      }
    }
    var dealt = _resolve(c, tgt);
    final echo = r['echo'];
    if (echo != null && rng.nextDouble() < 0.15 * echo) dealt += _resolve(c, target);
    final lifesteal = r['lifesteal'];
    if (lifesteal != null && dealt > 0) heal((0.2 * lifesteal * dealt).round());
    if (d.hpCost > 0 && r.containsKey('transfusion')) {
      heal((d.hpCost * 0.5).round()); // D40
    }
    switch (run.passive.id) {
      case 'mage_mark': // D34 : la 1re carte de dégâts du tour
        if (d.hasDamage && !markUsed && tgt != null && tgt.alive) {
          addFoeStatus(tgt, 'vulnerable', 1, run.passiveDuration());
          markUsed = true;
        }
      case 'bloodthirst': // passive_strategies.dart:186-203
        if (d.type == CType.attack) {
          lsVal = run.passiveValue() + ((maxHp - hp) * 100 ~/ maxHp) ~/ 25;
          lsDur = run.passive.duration;
        }
      case 'mana_flux': // passive_strategies.dart:100-116 ; D43
        if (d.type == CType.skill && ++skillCount >= run.fluxThreshold()) {
          mana += run.passive.value;
          skillCount = 0;
        }
    }
    for (final rel in relicsOn('onCardPlayed')) {
      if (rel.effect == 'gain_armor') gainArmor(rel.value);
    }
    if (!isSig) {
      final exhausts = d.type == CType.power ||
          (d.exhaust && !r.containsKey('enduring')) ||
          r.containsKey('spectral');
      if (!exhausts) discard.add(c);
    }
    if (d.type == CType.attack) attacksThisTurn++;
  }

  int _resolve(CardInst c, Foe? tgt) {
    final d = c.def;
    var dealt = 0;
    for (final e in d.effects) {
      switch (e.kind) {
        case 'damage':
          dealt += _dealDamage(c, e, tgt);
        case 'armor':
          gainArmor(_armorOf(c, e));
        case 'draw':
          drawN(e.value); // G2 : ni rareté ni rune sur la pioche
        case 'heal':
          var h = scaled(e.value, c.rank);
          if (rng.nextInt(100) < run.crit) h = (h * run.critMult).round(); // strategies.dart:92-96
          heal(h);
        case 'mana':
          mana += e.value; // G2
        case 'self':
          addSelfStatus(e.status, scaled(e.value, c.rank), e.duration);
        case 'enemy':
          final val = scaled(e.value, c.rank) + altBonus; // power_rules.dart:27-32
          final targets = d.target == Tgt.all ? active : [if (tgt != null && tgt.alive) tgt];
          for (final f in targets) {
            addFoeStatus(f, e.status, val, e.duration);
          }
      }
    }
    // Soif de Sang : le Vol de vie paie une fois par carte de dégâts, borné
    // aux dégâts (strategies.dart:61-69).
    if (d.hasDamage && lsDur > 0 && dealt > 0) heal(min(lsVal, dealt));
    return dealt;
  }

  int _dealDamage(CardInst c, Eff e, Foe? tgt) {
    final r = c.runes;
    final mt = mightFor(c.def.type) * mightRatioOf(c.def, e, run.p);
    final critChance = run.crit + 5 * (r['precise'] ?? 0);
    var current = tgt;
    var dealt = 0;
    for (var h = 0; h < e.hits; h++) {
      if (current == null || !current.alive) current = target;
      final targets = c.def.target == Tgt.all ? active : [?current];
      for (final f in targets) {
        var x = _perHit(c, e) + mt;
        if (e.scale == 'lowHpX2' && f.hp < 0.3 * f.maxHp) x *= 2;
        if (e.scale == 'vulnX2' && f.has('vulnerable')) x *= 2;
        var dmg = x.round();
        if (rng.nextInt(100) < critChance) dmg = (dmg * run.critMult).round(); // damage_pipeline.dart:20-28
        dmg += f.v('shock'); // :30-43
        if (f.has('vulnerable')) dmg = (dmg * 1.5).round(); // :45-49
        dealt += applyDamage(f, dmg);
        final splash = r['splash'];
        if (splash != null && c.def.target == Tgt.single) {
          for (final o in active) {
            if (o != f) applyDamage(o, (dmg * 0.25 * splash).round());
          }
        }
      }
    }
    return dealt;
  }

  void playerTurn() {
    attacksThisTurn = 0;
    markUsed = false;
    for (var guard = 0; guard < 40 && !allDead; guard++) {
      CardInst? best;
      var bestIsSig = false;
      var bestScore = 0.3;
      for (final c in hand) {
        if (!playable(c)) continue;
        final s = estimate(c) / max(c.cost, 0.5);
        if (s > bestScore) {
          best = c;
          bestScore = s;
          bestIsSig = false;
        }
      }
      for (final s in sigs) {
        if (sigReady[s.def]! > turn || !playable(s)) continue;
        final score = estimate(s) / max(s.cost, 0.5);
        if (score > bestScore) {
          best = s;
          bestScore = score;
          bestIsSig = true;
        }
      }
      if (best == null) break;
      play(best, isSig: bestIsSig);
    }
  }

  /// [measureTurns] > 0 : mannequin, on s'arrête après ce nombre de tours.
  FightResult runFight({int maxTurns = 40, int measureTurns = 0}) {
    startCombat();
    var stalemate = false;
    while (true) {
      dmgByTurn.add(0);
      playerTurn();
      if (allDead) break;
      endTurn();
      enemyTurn();
      if (allDead) break;
      if (measureTurns > 0 && turn >= measureTurns) break;
      if (turn >= maxTurns) {
        stalemate = true;
        break;
      }
      turn++;
      startTurn();
    }
    if (!mannequin) run.hp = max(1, hp);
    final n = min(3, dmgByTurn.length);
    var sum = 0.0;
    for (var i = 0; i < n; i++) {
      sum += dmgByTurn[i];
    }
    return FightResult(turn, n == 0 ? 0 : sum / n, stalemate, damageTaken);
  }
}

// ===========================================================================
// 9. Une run — l'économie
// ===========================================================================

/// Les mesures, relevées en fin de chaque acte : (clé, libellé, décimales).
const metricDefs = <(String, String, int)>[
  ('deck', 'Taille du deck', 0),
  ('fusions', 'Fusions de 3 copies (cumul)', 0),
  ('fusionsEvent', 'Fusions par l’événement D29 (cumul)', 0),
  ('exchanges', 'Échanges 3 → 1 (cumul)', 0),
  ('bestRank', 'Rang de la meilleure carte (0 = commune)', 0),
  ('runes', 'Runes portées par le deck', 0),
  ('runeSum', 'Niveaux de rune, somme', 0),
  ('runeMax', 'Niveau de rune, max', 0),
  ('ecoQuick', 'Runes `eco` + `quick` dans le deck', 0),
  ('fires', 'Visites de feu de camp (cumul)', 0),
  ('rests', '… dont repos', 0),
  ('forgets', '… dont oubli', 0),
  ('sharpens', '… dont affûtage', 0),
  ('fireExchanges', '… dont échange 3 → 1', 0),
  ('sharpBoss', 'Niveaux de rune du boss « XP » (D42a, cumul)', 0),
  ('sharpEvent', 'Niveaux de rune par événement (D42b, cumul)', 0),
  ('goldGained', 'Or gagné (cumul)', 0),
  ('goldSpent', 'Or dépensé (cumul)', 0),
  ('gold', 'Or en réserve', 0),
  ('level', 'Niveau du héros', 0),
  ('levelsAct', 'Niveaux gagnés dans l’acte', 0),
  ('xpAct', 'XP gagnée dans l’acte', 0),
  ('evolutions', 'Évolutions de signature (2 signatures)', 0),
  ('ceilingOffers', 'Mythique D42c offerte (cumul)', 0),
  ('ceilings', 'Mythique D42c prise (cumul)', 0),
  ('relics', 'Reliques', 0),
  ('d31Copies', 'Exemplaires des reliques de D31', 0),
  ('power', 'PlayerPower (DDA)', 0),
  ('budget', 'Budget ennemi d’un combat normal', 0),
  ('budgetCur', 'Budget sous la DDA actuelle (cartes × 2)', 0),
  ('budgetK2', 'Budget sous Σ rang × 2', 0),
  ('budgetK5', 'Budget sous Σ rang × 5', 0),
  ('budgetK10', 'Budget sous Σ rang × 10', 0),
  ('enemies', 'Ennemis par combat normal', 1),
  ('enemyHp', 'PV d’un ennemi moyen (combat normal)', 0),
  ('encounterHp', 'PV d’une rencontre normale', 0),
  ('dmgTurn', 'Dégâts par tour (tours 1-3, mannequin)', 0),
  ('turns', 'Tours pour vider un combat normal', 1),
  ('enemyDmg', 'Dégâts ennemis par tour, rencontre normale', 0),
  ('hpLoss', 'PV perdus par combat normal (sans plancher)', 0),
  ('hpPct', 'PV en fin d’acte (% du max)', 0),
  ('nearDeaths', 'Quasi-morts (cumul)', 0),
  ('found', 'Cartes trouvées, D31 (cumul)', 0),
  ('bossCards', 'Clones de boss (cumul)', 0),
  ('shopCards', 'Cartes achetées (cumul)', 0),
  ('copyCards', '… dont copie du deck, D46', 0),
  ('mirrorCards', 'Clones du Miroir, niveau + boutique (cumul)', 0),
  ('shopVisits', 'Boutiques visitées (cumul)', 0),
  ('events', 'Événements (cumul)', 0),
  ('wellVisits', 'Puits visités (cumul)', 0),
  ('wellSwaps', 'Échanges au Puits (cumul)', 0),
  ('altarUses', 'Échanges à l’Autel (cumul)', 0),
  ('relicTrades', 'Reliques échangées, D23 (cumul)', 0),
  ('purges', 'Purges payantes en boutique (cumul)', 0),
  ('combats', 'Combats normaux et élites (cumul)', 0),
  ('elites', '… dont élites', 0),
  ('stalemates', 'Combats non finis en 40 tours (cumul)', 0),
];
final metricIndex = {
  for (var i = 0; i < metricDefs.length; i++) metricDefs[i].$1: i,
};
final metricCount = metricDefs.length;

/// L'acte où la première carte atteint un rang par fusion, et celui de la
/// première quasi-mort (99 = jamais).
const firstKeys = [
  'firstFusion', 'firstRare', 'firstEpic', 'firstLegendary', 'firstNearDeath',
  'firstCeiling',
];

class Run {
  Run(this.p, this.cls, this.lotId, this.rng)
      : passive = data.passives[lotPassive[lotId]!]!,
        pool = data.pool(lotId),
        maxHp = cls.maxHp,
        hp = cls.maxHp,
        crit = cls.crit,
        mastery = cls.mastery,
        maxMana = cls.maxMana {
    final byId = {for (final c in pool) c.id: c};
    for (final id in [...starterLotPicks[lotId]!, ...starterNeutralPicks[cls.id]!]) {
      deck.add(CardInst(byId[id]!, 0));
    }
    if (p.d31Relics == 'forced') {
      for (final r in const [relicD31A, relicD31B, relicD31C]) {
        gainRelic(r);
      }
    }
  }

  final Params p;
  final ClassDef cls;
  final String lotId;
  final Random rng;
  final PassiveDef passive;
  final List<CardDef> pool;
  final List<CardInst> deck = [];
  final List<RelicDef> relics = [];
  final Map<String, int> maxLevelBonus = {};
  final Map<String, double> cum = {};
  final Map<String, List<double>> actAcc = {};
  final Map<String, int> firsts = {};

  int maxHp;
  int hp;
  int might = 0;
  int crit;
  double critMult = baseCritMultiplier;
  int mastery;
  int luck = 0;
  int maxMana;
  int cardsPerTurn = baseCardsPerTurn;
  int gold = startingGold;
  int level = 1;
  int xp = 0;
  int act = 1;
  double actXp = 0;
  int levelsAct = 0;

  void inc(String k, [double v = 1]) => cum[k] = (cum[k] ?? 0) + v;
  void acc(String k, double v) => actAcc.putIfAbsent(k, () => []).add(v);

  /// power_rules.dart:17-21 : la Puissance selon `mightTargets`.
  bool targetsType(CType t) => switch (t) {
        CType.attack => cls.mightTargets.contains('attack'),
        CType.skill => cls.mightTargets.contains('skill'),
        CType.power => false,
      };

  /// La valeur d'un passif, Maîtrise comprise (passives/*.json, bloc mastery).
  int passiveValue() =>
      passive.value + (passive.masteryField == 'value' ? passive.perPoint * mastery : 0);
  int passiveDuration() =>
      passive.duration + (passive.masteryField == 'duration' ? passive.perPoint * mastery : 0);

  /// mana_flux.json : seuil 3, −1 par point de Maîtrise ; plancher 2 (D43).
  int fluxThreshold() => max(2, passive.threshold + passive.perPoint * mastery);

  /// Bénédiction : tranche de 5 (passive_strategies.dart:146), ou D43 :
  /// `threshold: 3`, Maîtrise sur le seuil, plancher 2.
  int blessingThreshold() => p.blessingD43 ? max(2, 3 - mastery) : 5;
  int blessingValue() => p.blessingD43 ? passive.value : passiveValue();

  int copies(String id) => relics.where((r) => r.id == id).length;

  /// `maxLevel` d'une rune pour cette run : table (§8) + mythique D42c.
  int? maxLevel(String id) {
    final b = baseMaxLevel(id, p);
    return b == null ? null : b + (maxLevelBonus[id] ?? 0);
  }

  int get sumRanks => deck.fold(0, (a, c) => a + c.rank);

  /// D47 : le terme de deck de `PlayerPower`.
  double get deckTerm => p.ddaK < 0 ? deck.length * 2.0 : p.ddaK * sumRanks;

  void gainGold(int g) {
    gold += g;
    inc('goldGained', g.toDouble());
  }

  void spend(int g) {
    gold -= g;
    inc('goldSpent', g.toDouble());
  }

  void heal(int a) => hp = min(maxHp, hp + a);

  Map<String, int> groupCounts() {
    final m = <String, int>{};
    for (final c in deck) {
      m[c.key] = (m[c.key] ?? 0) + 1;
    }
    return m;
  }

  bool get hasPair => groupCounts().values.any((n) => n == 2);

  // --- Valeur statique d'une carte : sert aux choix (rune, oubli, clone) ---

  double mightEstimate(CType t) {
    if (!targetsType(t)) return 0;
    var m = might.toDouble();
    switch (passive.id) {
      case 'rage':
        m += passiveValue() * (1 + (maxHp - hp) ~/ 10);
      case 'fervor' || 'frenzy':
        m += passiveValue() * 0.5;
    }
    return m;
  }

  /// Valeur d'une pose, en points de dégâts. Poids de politique (DÉFAUT).
  double staticValue(CardInst c) {
    final d = c.def;
    final r = c.runes;
    final me = mightEstimate(d.type);
    final critP = min(1.0, (crit + 5 * (r['precise'] ?? 0)) / 100.0);
    final critE = 1 + critP * (critMult - 1);
    final alt = cls.mightTargets.contains('alteration') ? might.toDouble() : 0.0;
    var v = 0.0;
    for (final e in d.effects) {
      final val = scaled(e.value, c.rank);
      switch (e.kind) {
        case 'damage':
          final sharp = r['sharp'];
          final spectral = r['spectral'];
          final bonus = (sharp == null
                  ? 0
                  : percentRuneBonus(max(0, val) * e.hits, sharp, 15)) +
              (spectral == null
                  ? 0
                  : percentRuneBonus(max(0, val) * e.hits, spectral, 40));
          final scaleTerm = switch (e.scale) {
            'armor' => 8.0,
            'missingHp' => 0.2 * (maxHp - hp),
            'attacksPlayed' => 2.0,
            _ => 0.0,
          };
          var dmg = (val * e.hits + bonus + (scaleTerm + me * mightRatioOf(d, e, p)) * e.hits) *
              critE;
          if (e.scale == 'lowHpX2' || e.scale == 'vulnX2') dmg *= 1.3;
          v += dmg * (d.target == Tgt.all ? 2.0 : 1.0) +
              dmg * 0.25 * (r['splash'] ?? 0) +
              dmg * 0.1 * (r['lifesteal'] ?? 0);
        case 'armor':
          final h = r['hardened'];
          final a = val + (h == null ? 0 : percentRuneBonus(val, h, 15));
          v += cls.convertsArmor ? (a * 0.5).ceil() * 1.5 : a * 0.8;
        case 'draw':
          v += 3.0 * e.value;
        case 'mana':
          v += 4.0 * e.value;
        case 'heal':
          v += 0.6 * val;
        case 'self':
          v += switch (e.status) {
            'might' => val * (1.5 + (e.duration - 1) * 1.5),
            'armor_regen' => cls.convertsArmor
                ? (val * 0.5).ceil() * 1.2 * e.duration
                : val * e.duration * 0.6,
            'might_regen' => val * e.duration * 1.8,
            'mana_regen' => val * e.duration * 3.5,
            'hp_regen' => 0.6 * val * e.duration,
            _ => 0.0,
          };
        case 'enemy':
          final n = d.target == Tgt.all ? 2.0 : 1.0;
          v += n *
              switch (e.status) {
                'burn' || 'poison' => (val + alt) * e.duration,
                'shock' => (val + alt) * 3.0,
                'weakness' => 2.0 * e.duration,
                'vulnerable' => 4.0 * e.duration,
                'freeze' => 3.0,
                _ => 0.0,
              };
      }
    }
    if (d.type == CType.attack) {
      final burn = r['burning'] ?? 0;
      v += burn * (burn + alt) + (r['shocking'] ?? 0) * 3.0 + (r['freezing'] ?? 0) * 3.0;
    }
    if (r.containsKey('quick')) v += 3;
    if (r.containsKey('eco')) v += 4;
    if (r.containsKey('cheap')) v += 4;
    if (r.containsKey('retain')) v += 0.5;
    if (r.containsKey('enduring')) v *= 1.3;
    if (r.containsKey('transfusion')) v += 0.25 * d.hpCost;
    v *= 1 + 0.15 * (r['echo'] ?? 0);
    if (r.containsKey('spectral') && !d.exhaust && d.type != CType.power) v *= 0.8;
    return v - d.hpCost * (passive.id == 'rage' ? 0.1 : 0.5) - d.armorCost * 0.8;
  }

  // --- Entrées de cartes et fusion (D1, D3, D13, D31) ---

  void addCard(CardInst c, [String? source]) {
    deck.add(c);
    if (source != null) inc(source);
    fuseAll();
  }

  void noteRank(int rank) {
    for (var r = 1; r <= rank; r++) {
      firsts.putIfAbsent(firstKeys[r - 1], () => act);
    }
  }

  RuneDef _weighted(List<RuneDef> list) {
    final total = list.fold(0, (a, r) => a + r.weight);
    var roll = rng.nextInt(total);
    for (final r in list) {
      roll -= r.weight;
      if (roll < 0) return r;
    }
    return list.last;
  }

  /// D3 : 3 runes tirées (pondérées, éligibles, id absent de la carte), le
  /// joueur en choisit une, qui entre au niveau 1 (§4.2).
  void offerRune(CardInst c) {
    final eligible = [for (final r in data.runes) if (runeEligible(r, c, c.rank, p)) r];
    final offered = <RuneDef>[];
    while (offered.length < 3 && eligible.isNotEmpty) {
      final r = _weighted(eligible);
      offered.add(r);
      eligible.remove(r);
    }
    if (offered.isEmpty) return;
    final base = staticValue(c);
    var best = offered.first;
    var bestGain = double.negativeInfinity;
    for (final r in offered) {
      c.runes[r.id] = 1;
      final g = staticValue(c) - base;
      c.runes.remove(r.id);
      if (g > bestGain) {
        bestGain = g;
        best = r;
      }
    }
    c.runes[best.id] = 1;
  }

  /// La fusion (D3) : le rang monte, les runes des trois ingrédients sont
  /// gardées et additionnées par id (D13), bornées par `maxLevel` (D27), puis
  /// une rune neuve.
  CardInst fuseInto(List<CardInst> three, CardDef def) {
    final rank = three.first.rank + 1;
    final runes = <String, int>{};
    for (final c in three) {
      c.runes.forEach((k, v) => runes[k] = (runes[k] ?? 0) + v);
    }
    runes.updateAll((k, v) {
      final cap = maxLevel(k);
      return cap == null ? v : min(v, cap);
    });
    for (final c in three) {
      deck.remove(c);
    }
    final out = CardInst(def, rank, runes);
    offerRune(out);
    deck.add(out);
    noteRank(rank);
    return out;
  }

  /// Fusion automatique dès trois copies identiques (id et rang), en
  /// cascade (P3 : la fusion est le moteur).
  void fuseAll() {
    while (true) {
      final groups = <String, List<CardInst>>{};
      for (final c in deck) {
        groups.putIfAbsent(c.key, () => []).add(c);
      }
      final g = groups.values.where((g) => g.length >= 3 && g.first.rank < 4).firstOrNull;
      if (g == null) return;
      g.sort((a, b) => b.runeLevels.compareTo(a.runeLevels));
      fuseInto(g.sublist(0, 3), g.first.def);
      inc('fusions');
    }
  }

  /// Trois cartes de même rang, les moins utiles, hors paires (D29, D8).
  List<CardInst>? pickThree() {
    final counts = groupCounts();
    for (var r = 0; r < 4; r++) {
      final cands = [for (final c in deck) if (c.rank == r) c];
      if (cands.length < 3) continue;
      final key = {for (final c in cands) c: (counts[c.key] == 2 ? 1000 : 0) + staticValue(c)};
      cands.sort((a, b) => key[a]!.compareTo(key[b]!));
      return cands.sublist(0, 3);
    }
    return null;
  }

  CardInst bestCloneOf(List<CardInst> opts) {
    final counts = groupCounts();
    double key(CardInst c) =>
        (counts[c.key] == 2 ? 1e6 : 0) +
        (counts[c.key] == 1 && (c.def.lot == lotId || c.rank > 0) ? 1e3 : 0) +
        c.rank * 100 +
        staticValue(c);
    return opts.reduce((a, b) => key(a) >= key(b) ? a : b);
  }

  // --- Affûtage (D14, D20, D42) et oubli ---

  ({CardInst card, String rune, int level})? sharpenTarget({bool free = false}) {
    Iterable<CardInst> cands = deck.where((c) => c.runes.isNotEmpty);
    if (p.sharpenStrategy == 'beforeFusion') {
      final counts = groupCounts();
      final pairs = cands.where((c) => counts[c.key] == 2).toList();
      if (pairs.isNotEmpty) cands = pairs;
    }
    CardInst? bestCard;
    var bestRune = '';
    var bestLevel = 0;
    var bestGain = 0.01;
    for (final c in cands) {
      final base = staticValue(c);
      for (final e in c.runes.entries.toList()) {
        final cap = maxLevel(e.key);
        if (cap != null && e.value >= cap) continue;
        if (!free && p.sharpenB * e.value > gold) continue;
        c.runes[e.key] = e.value + 1;
        final g = staticValue(c) - base;
        c.runes[e.key] = e.value;
        if (g > bestGain) {
          bestCard = c;
          bestRune = e.key;
          bestLevel = e.value;
          bestGain = g;
        }
      }
    }
    return bestCard == null ? null : (card: bestCard, rune: bestRune, level: bestLevel);
  }

  /// D14 : une rune, un niveau, par visite ; D20 : `b × niveau`.
  bool sharpenAtFire() {
    final t = sharpenTarget();
    if (t == null) return false;
    spend(p.sharpenB * t.level);
    t.card.runes[t.rune] = t.level + 1;
    return true;
  }

  int sharpenReserve() {
    final t = sharpenTarget(free: true);
    return t == null ? 0 : p.sharpenB * t.level;
  }

  /// D42a : une rune tirée dans tout le deck monte d'un niveau.
  void sharpenRandom() {
    final opts = <(CardInst, String)>[];
    for (final c in deck) {
      for (final e in c.runes.entries) {
        final cap = maxLevel(e.key);
        if (cap == null || e.value < cap) opts.add((c, e.key));
      }
    }
    if (opts.isEmpty) return;
    final (c, id) = opts[rng.nextInt(opts.length)];
    c.runes[id] = c.runes[id]! + 1;
    inc('sharpBoss');
  }

  CardInst? worstCard() {
    final counts = groupCounts();
    for (final singletonsOnly in [true, false]) {
      CardInst? worst;
      var wv = double.infinity;
      for (final c in deck) {
        if (c.rank != 0 || (singletonsOnly && counts[c.key] != 1)) continue;
        final v = staticValue(c) / max(c.cost, 1);
        if (v < wv) {
          wv = v;
          worst = c;
        }
      }
      if (worst != null) return worst;
    }
    return null;
  }

  bool forget() {
    if (deck.length <= 5) return false;
    final w = worstCard();
    if (w == null) return false;
    deck.remove(w);
    return true;
  }

  /// D8 : trois cartes de même rang → une carte aléatoire du pool, un rang
  /// au-dessus, sans runes (DÉFAUT).
  bool exchange3to1() {
    if (deck.length < 12) return false;
    final three = pickThree();
    if (three == null) return false;
    for (final c in three) {
      deck.remove(c);
    }
    addCard(CardInst(pool[rng.nextInt(pool.length)], three.first.rank + 1), 'exchanges');
    return true;
  }

  // --- Reliques ---

  List<RelicDef> get relicPool => [
        ...data.relics,
        if (p.d31Relics == 'pool') ...const [relicD31A, relicD31B, relicD31C],
        relicD42,
      ];

  /// reward_controller.dart:108-155 (élite, amélioré) ; event_controller.dart:80-100.
  int rollRelicRarity({bool improved = false}) {
    final l = luck.toDouble();
    double leg, epic, rare, unc;
    if (improved) {
      leg = 10.0 + l * 0.5;
      final common = max(0.0, 40.0 - (act - 1) * 10.0);
      if (common > 0) {
        final rest = 90.0 - common;
        unc = 20 / 85 * rest + l * 3;
        rare = 35 / 85 * rest + l * 2;
        epic = 30 / 85 * rest + l;
      } else {
        final baseUnc = max(0.0, 20 / 85 * 90 - (act - 5) * 10.0);
        if (baseUnc > 0) {
          final rest = 90.0 - baseUnc;
          rare = 35 / 65 * rest + l * 2;
          epic = 30 / 65 * rest + l;
          unc = baseUnc + l * 3;
        } else {
          rare = 35 / 65 * 90 + l * 2;
          epic = 30 / 65 * 90 + l;
          unc = 0;
        }
      }
    } else {
      leg = 1.0 + l * 0.5;
      epic = 5.0 + l;
      rare = 14.0 + l * 2;
      unc = 20.0 + l * 3;
    }
    final roll = rng.nextDouble() * 100;
    if (roll < leg) return 4;
    if (roll < leg + epic) return 3;
    if (roll < leg + epic + rare) return 2;
    if (roll < leg + epic + rare + unc) return 1;
    return 0;
  }

  /// Tirage avec remise : une relique peut tomber plusieurs fois
  /// (reward_controller.dart:157-164 ; point 1 validé).
  RelicDef drawRelic(int rarity) {
    final all = relicPool;
    var f = all.where((r) => r.rarity == rarity).toList();
    if (f.isEmpty) f = all.where((r) => r.rarity == 0).toList();
    if (f.isEmpty) f = all;
    return f[rng.nextInt(f.length)];
  }

  void gainRelic(RelicDef r) {
    relics.add(r);
    if (r.trigger == 'startOfRun') _applyRunRelic(r, 1);
  }

  void loseRelic(RelicDef r) {
    relics.remove(r);
    if (r.trigger == 'startOfRun') _applyRunRelic(r, -1);
  }

  /// player_stats_manager.dart:239-303 et :435-455.
  void _applyRunRelic(RelicDef r, int sign) {
    final v = sign * r.value;
    switch (r.effect) {
      case 'gain_might':
        might += v;
      case 'gain_crit':
        crit += v;
      case 'gain_mana':
        maxMana += v;
      case 'gain_luck':
        luck += v;
      case 'increase_cards_per_turn':
        cardsPerTurn += v;
    }
  }

  // --- XP, niveaux, récompenses de niveau (D11, D24, D42c, Q3, Q17) ---

  int xpNeed() => switch (p.xpCurve) {
        'constant' => p.xpConstant,
        'perAct' => p.xpTable[min(act, p.xpTable.length) - 1],
        _ => (100 * pow(1.5, level - 1)).round(), // player_stats_manager.dart:127
      };

  void gainXp(int amount) {
    xp += amount;
    actXp += amount;
    while (level < levelCap && xp >= xpNeed()) {
      xp -= xpNeed();
      level++;
      levelsAct++;
      levelUp();
    }
  }

  /// level_up_reward_service.dart:38-87.
  String rollRewardRarity({required bool levelReward}) {
    final l = luck.toDouble();
    final mythic = levelReward ? 0.5 + l * 0.15 : 0.0;
    final leg = 2.0 + l * 0.5;
    final epic = 6.0 + l * 1.5;
    final rare = 16.0 + l * 3.0;
    final unc = 24.0 + l * 4.0;
    var roll = rng.nextDouble() * 100;
    if (levelReward && roll < mythic) return 'mythic';
    roll -= mythic;
    if (roll < leg) return 'legendary';
    roll -= leg;
    if (roll < epic) return 'epic';
    roll -= epic;
    if (roll < rare) return 'rare';
    roll -= rare;
    if (roll < unc) return 'uncommon';
    return 'common';
  }

  /// D11 : Sagesse passe en mythique ; Q3 : le pool du Miroir est un levier.
  String poolOf(RewardDef r) => switch (r.id) {
        'wisdom' => 'mythic',
        'mirror' => p.mirrorPool,
        _ => r.pool,
      };

  /// level_up_reward_service.dart:89-148 : 3 emplacements du pool `draft`,
  /// puis un jet indépendant par mythique ; D42c ajoute une mythique.
  void levelUp() {
    final draft = [for (final r in data.rewards) if (poolOf(r) == 'draft') r];
    final offers = <(RewardDef?, int)>[];
    for (var i = 0; i < 3 && draft.isNotEmpty; i++) {
      final rarity = rollRewardRarity(levelReward: false);
      final r = draft[rng.nextInt(draft.length)];
      offers.add((r, r.values[rarity] ?? 0));
    }
    // Les mythiques ; `null` est celle de D42c (+1 au `maxLevel` d'une rune).
    // DÉFAUT : Sagesse mythique à +1 (D11, pas de valeur `mythic` en donnée).
    final mythics = <RewardDef?>[
      for (final r in data.rewards)
        if (poolOf(r) == 'mythic') r,
      null,
    ];
    if (p.mythicMode == 'pool') {
      if (rollRewardRarity(levelReward: true) == 'mythic') {
        final r = mythics[rng.nextInt(mythics.length)];
        offers.add((r, r?.values['mythic'] ?? 1));
      }
    } else {
      for (final r in mythics) {
        if (rollRewardRarity(levelReward: true) == 'mythic') {
          offers.add((r, r?.values['mythic'] ?? 1));
        }
      }
    }
    if (offers.any((o) => o.$1 == null)) inc('ceilingOffers');
    _chooseReward(offers);
  }

  void _chooseReward(List<(RewardDef?, int)> offers) {
    for (final (r, amount) in offers) {
      if (r?.id == 'wisdom') {
        maxMana += amount;
        return;
      }
    }
    if (offers.any((o) => o.$1 == null)) {
      // Une rune binaire ne gagne rien à un niveau de plus.
      const binary = {'enduring', 'retain', 'cheap', 'transfusion'};
      final capped = <String, int>{};
      for (final c in deck) {
        for (final e in c.runes.entries) {
          final cap = maxLevel(e.key);
          if (cap != null && e.value >= cap && !binary.contains(e.key)) {
            capped[e.key] = (capped[e.key] ?? 0) + 1;
          }
        }
      }
      if (capped.isNotEmpty) {
        final id = capped.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
        maxLevelBonus[id] = (maxLevelBonus[id] ?? 0) + 1; // D42c
        inc('ceilings');
        firsts.putIfAbsent('firstCeiling', () => act);
        return;
      }
    }
    if (offers.any((o) => o.$1?.effect == 'cloneCard') && hasPair && !p.onlyFind) {
      // Le Miroir : 1 clone parmi 3 cartes du deck, runes comprises (mirror.json).
      final opts = ([...deck]..shuffle(rng)).take(3).toList();
      if (opts.isNotEmpty) addCard(bestCloneOf(opts).copy(), 'mirrorCards');
      return;
    }
    (RewardDef, int)? best;
    var bestScore = double.negativeInfinity;
    for (final (r, amount) in offers) {
      if (r == null || r.effect != 'stat') continue;
      final s = switch (r.stat) {
        'might' => targetsType(CType.attack) || targetsType(CType.skill) ? 4.0 * amount : 0.0,
        'maxHp' => 0.6 * amount,
        'mastery' => 3.0 * amount,
        'critChance' => 0.8 * amount,
        'critDamage' => 0.12 * amount,
        'luck' => 2.0,
        'maxMana' => 20.0 * amount,
        _ => 0.0,
      };
      if (s > bestScore) {
        bestScore = s;
        best = (r, amount);
      }
    }
    if (best == null) return;
    final (r, amount) = best;
    switch (r.stat) {
      // player_stats_manager.dart:73-97
      case 'might':
        might += amount;
      case 'maxHp':
        maxHp += amount;
        hp += amount;
      case 'mastery':
        mastery += amount;
      case 'critChance':
        crit += amount;
      case 'critDamage':
        critMult += amount / 100;
      case 'luck':
        luck += amount;
      case 'maxMana':
        maxMana += amount;
    }
  }

  // --- Combats et récompenses ---

  List<Foe> spawn({required bool boss, required bool elite, bool mannequin = false}) {
    final b = budgetFor(
      level: level,
      act: act,
      maxHp: maxHp,
      might: might,
      maxMana: maxMana,
      relics: relics.length,
      deckTerm: deckTerm,
      boss: boss,
      elite: elite,
    );
    final eL = enemyLevelFor(level, boss, elite);
    final defs = generateEnemies(b.budget, act, eL, boss, elite, rng);
    final foes = <Foe>[];
    for (final e in defs) {
      // combat_controller.dart:151-158
      final hpE = (e.maxHp * hpMultFor(eL, act, boss, elite)).round();
      final mightE = (e.baseDamage * dmgMultFor(eL, act, boss, elite)).round();
      foes.add(Foe(e, mannequin ? 1 << 30 : hpE,
          e.baseDamage > 0 ? mightE / e.baseDamage : 1.0, e.crit));
    }
    if (!boss && !elite && !mannequin) {
      acc('power', b.power);
      acc('budget', b.budget);
      acc('enemies', defs.length.toDouble());
      acc('encounterHp', foes.fold(0, (a, f) => a + f.maxHp).toDouble());
      // L'attaque de base de chaque ennemi, crit en espérance.
      acc('enemyDmg', foes.fold(0.0, (a, f) => a + f.def.baseDamage * f.atk * (1 + f.crit / 200)));
      for (final f in foes) {
        acc('enemyHp', f.maxHp.toDouble());
      }
    }
    return foes;
  }

  /// reward_controller.dart:83-101.
  void rewardFoes(List<Foe> foes, {required bool boss, required bool elite, bool triple = false}) {
    final m = 1.0 + 0.10 * (enemyLevelFor(level, boss, elite) - 1);
    var xpGain = 0;
    var goldGain = 0;
    for (final f in foes) {
      xpGain += (f.def.xp * (p.xpLevelScaling ? m : 1.0)).round();
      goldGain += (f.def.gold * m).round();
    }
    if (triple) {
      xpGain *= 3;
      goldGain *= 3;
    }
    gainGold(goldGain);
    gainXp(xpGain);
  }

  void visitCombat({required bool elite}) {
    inc('combats');
    if (elite) inc('elites');
    final foes = spawn(boss: false, elite: elite);
    final res = Fight(this, foes).runFight();
    if (!elite) {
      acc('turns', res.turns.toDouble());
      acc('hpLoss', res.damageTaken.toDouble());
    }
    if (res.stalemate) inc('stalemates');
    rewardFoes(foes, boss: false, elite: elite);
    if (elite) gainRelic(drawRelic(rollRelicRarity())); // :106-165
    // D31 : la table `cardDrops`, puis les reliques A, B, C.
    var n = elite ? 1 : p.normalGuaranteed + copies(relicD31C.id);
    if (elite) {
      if (rng.nextDouble() < p.eliteExtra + p.relicAEliteBonus * copies(relicD31A.id)) {
        n++;
        if (rng.nextDouble() < p.relicBPerCopy * copies(relicD31B.id)) n++;
      }
    } else if (rng.nextDouble() < p.relicBPerCopy * copies(relicD31B.id)) {
      n++;
    }
    for (var i = 0; i < n; i++) {
      // D1 : tirage uniforme dans le pool offrable, `common`, sans refus.
      addCard(CardInst(pool[rng.nextInt(pool.length)], 0), 'found');
    }
  }

  void visitBoss(String reward) {
    final foes = spawn(boss: true, elite: false);
    final res = Fight(this, foes).runFight();
    if (res.stalemate) inc('stalemates');
    rewardFoes(foes, boss: true, elite: false, triple: reward == 'xp');
    switch (reward) {
      case 'xp': // D42a : plus de carte ; une rune monte, +1 par légendaire
        for (var i = 0; i < 1 + copies(relicD42.id); i++) {
          sharpenRandom();
        }
      case 'relic':
        gainRelic(drawRelic(rollRelicRarity(improved: true)));
      case 'cards': // reward_controller.dart:170-184 ; 2 parmi 5, boss_card_draft_screen.dart:28
        final opts = ([...deck]..shuffle(rng)).take(5).map((c) => c.copy()).toList();
        for (var i = 0; i < 2 && opts.isNotEmpty; i++) {
          final pick = bestCloneOf(opts);
          opts.remove(pick);
          addCard(pick, 'bossCards');
        }
    }
  }

  // --- Feu de camp, boutique, événements, Puits, Autel ---

  /// D5, D14 ; politique validée : repos sous 50 % des PV, sinon affûter,
  /// sinon oublier. Le Berserker Sang ne se repose jamais (D26).
  void visitRest() {
    inc('fires');
    final sang = passive.id == 'rage';
    if (!sang && hp < maxHp * 0.5) {
      heal((maxHp * restHealRatio).round());
      inc('rests');
      return;
    }
    if (sharpenAtFire()) {
      inc('sharpens');
      return;
    }
    if (p.exchange == 'campfire' && exchange3to1()) {
      inc('fireExchanges');
      return;
    }
    if (forget()) {
      inc('forgets');
      return;
    }
    if (!sang) {
      heal((maxHp * restHealRatio).round());
      inc('rests');
    }
  }

  /// shop_controller.dart:187-225 : rareté selon l'acte, runes bornées par
  /// `fusionRank` (revue §2.1, option 2 retenue).
  CardInst shopCard(CardDef d) {
    final roll = rng.nextInt(100); // :158-184
    final up = switch (act) {
      1 => roll < 10 ? 1 : 0,
      2 => roll < 25 ? 1 : 0,
      _ => roll < 10 ? 2 : (roll < 50 ? 1 : 0),
    };
    final card = CardInst(d, up);
    final r2 = rng.nextInt(100); // :197-209
    var n = act == 2 ? (r2 < 15 ? 1 : 0) : (act >= 3 ? (r2 < 10 ? 2 : (r2 < 40 ? 1 : 0)) : 0);
    n = min(n, card.rank);
    for (var i = 0; i < n; i++) {
      final eligible = [for (final r in data.runes) if (runeEligible(r, card, card.rank, p)) r];
      if (eligible.isEmpty) break;
      final rune = _weighted(eligible);
      final t = rng.nextInt(100); // :143-153
      final cap = maxLevel(rune.id);
      final lvl = t < 80 ? 1 : (t < 95 ? 2 : 3);
      card.runes[rune.id] = cap == null ? lvl : min(lvl, cap);
    }
    return card;
  }

  void visitShop() {
    inc('shopVisits');
    final offers = <(CardInst, int, bool)>[];
    for (final d in ([...pool]..shuffle(rng)).take(3)) {
      final c = shopCard(d);
      offers.add((c, cardPriceByRank[c.rank] + shopPricePerRune * c.runes.length, false));
    }
    if (deck.isNotEmpty) {
      // D46 : la copie d'une carte du deck, même rang, sans runes.
      final src = deck[rng.nextInt(deck.length)];
      offers.add((src.copy(withRunes: false), cardPriceByRank[src.rank], true));
    }
    final mirrorOpts = ([...deck]..shuffle(rng)).take(3).toList(); // shop_screen.dart:204-215
    if (p.onlyFind) {
      offers.clear();
      mirrorOpts.clear();
    }
    var mirrorBuys = 0;
    void buy((CardInst, int, bool) o) {
      spend(o.$2);
      offers.remove(o);
      if (o.$3) inc('copyCards');
      addCard(o.$1, 'shopCards');
    }

    // 1. Compléter une fusion d'abord (politique validée).
    var progress = true;
    while (progress) {
      progress = false;
      final counts = groupCounts();
      for (final o in [...offers]..sort((a, b) => a.$2.compareTo(b.$2))) {
        if (counts[o.$1.key] == 2 && gold >= o.$2) {
          buy(o);
          progress = true;
          break;
        }
      }
      if (progress) continue;
      final price = shopMirrorBasePrice << mirrorBuys;
      final t = mirrorOpts.where((c) => groupCounts()[c.key] == 2).firstOrNull;
      if (t != null && gold >= price) {
        spend(price);
        mirrorBuys++;
        addCard(t.copy(), 'mirrorCards');
        progress = true;
      }
    }
    // 2. Un soin sous 50 % des PV.
    if (hp < maxHp * 0.5 && gold >= shopHealPrice) {
      spend(shopHealPrice);
      heal((maxHp * shopHealRatio).round());
    }
    // 3. Former une paire, en gardant l'or du prochain affûtage.
    final reserve = sharpenReserve();
    for (final o in [...offers]..sort((a, b) => a.$2.compareTo(b.$2))) {
      if (groupCounts()[o.$1.key] == 1 &&
          (o.$1.def.lot == lotId || o.$1.rank > 0) &&
          gold - o.$2 >= reserve) {
        buy(o);
      }
    }
    // 4. Une purge payante si le deck est gros et l'or en trop.
    if (deck.length > 25 && gold - shopPurgePrice >= reserve + 50) {
      final w = worstCard();
      if (w != null) {
        deck.remove(w);
        spend(shopPurgePrice);
        inc('purges');
      }
    }
  }

  void visitEvent() {
    inc('events');
    final ids = [
      for (final e in data.events) e.id,
      'd29_fusion',
      'd23_relic',
      'd42b_sharpen',
      if (p.exchange == 'event') 'exchange',
    ];
    switch (ids[rng.nextInt(ids.length)]) {
      case 'd29_fusion':
        _eventFusion();
      case 'd23_relic':
        _eventRelicTrade();
      case 'd42b_sharpen':
        _eventSharpen();
      case 'exchange':
        exchange3to1();
      case final id:
        _playDataEvent(data.events.firstWhere((e) => e.id == id));
    }
  }

  /// Les événements d'aujourd'hui, lus dans la donnée ; le choix par un
  /// score (DÉFAUT) : le gain si les PV le permettent, le soin sinon.
  void _playDataEvent(EventDef e) {
    final low = hp < maxHp * 0.5;
    final sang = passive.id == 'rage';
    List<(String, int)>? best;
    var bestScore = double.negativeInfinity;
    for (final actions in e.choices) {
      var s = 0.0;
      var goldNeed = 0;
      var dmg = 0;
      for (final (type, v) in actions) {
        switch (type) {
          case 'spend_gold':
            goldNeed += v;
            s -= v;
          case 'gain_gold':
            s += v;
          case 'take_damage':
            dmg += v;
            s -= v * (sang ? 0.3 : (low ? 3.0 : 1.0));
          case 'heal':
            s += min(v, maxHp - hp) * (low ? 2.0 : 0.5);
          case 'gain_max_hp':
            s += v * 2.0;
          case 'gain_might':
            s += 25;
          case 'gain_relic':
            s += 30;
        }
      }
      if (goldNeed > gold || dmg >= hp) continue;
      if (s > bestScore) {
        bestScore = s;
        best = actions;
      }
    }
    for (final (type, v) in best ?? const <(String, int)>[]) {
      switch (type) {
        case 'spend_gold':
          spend(v);
        case 'gain_gold':
          gainGold(v);
        case 'take_damage':
          hp = max(1, hp - v);
        case 'heal':
          heal(v);
        case 'gain_max_hp': // player_stats_manager.dart:30-36
          maxHp = max(1, maxHp + v);
          hp = min(maxHp, hp + max(0, v));
        case 'gain_might':
          might += v;
        case 'gain_relic':
          gainRelic(drawRelic(rollRelicRarity()));
      }
    }
  }

  /// D29 (Q18, DÉFAUT validé) : 10 % des PV max + 30 or × rang visé ; trois
  /// cartes de même rareté, la gagnante tirée, les runes héritées (D13).
  void _eventFusion() {
    if (deck.length < 12) return;
    final three = pickThree();
    if (three == null) return;
    final hpCost = (maxHp * 0.10).round();
    final goldCost = 30 * (three.first.rank + 1);
    if (gold < goldCost || hp <= hpCost + 1) return;
    if (passive.id != 'rage' && hp < maxHp * 0.3) return;
    spend(goldCost);
    hp -= hpCost;
    fuseInto(three, three[rng.nextInt(3)].def);
    inc('fusionsEvent');
    fuseAll();
  }

  /// D23 (Q15, DÉFAUT validé) : la relique la plus faible contre 40 or par
  /// rang de rareté, ou 20 % des PV max sous 50 % des PV.
  void _eventRelicTrade() {
    // Les reliques du brainstorm (D31, D42) ne sont jamais données : la
    // politique ne sait pas les valoriser.
    final tradable = relics.where((r) => r.trigger != 'special').toList();
    if (relics.length < 3 || tradable.isEmpty) return;
    final low = tradable.map((r) => r.rarity).reduce(min);
    final weakest = tradable.where((r) => r.rarity == low).toList();
    final r = weakest[rng.nextInt(weakest.length)];
    loseRelic(r);
    if (hp < maxHp * 0.5) {
      heal((maxHp * 0.2).round());
    } else {
      gainGold(40 * (r.rarity + 1));
    }
    inc('relicTrades');
  }

  /// D42b (DÉFAUT validé) : +1 niveau de rune contre 10 % des PV max.
  void _eventSharpen() {
    final t = sharpenTarget(free: true);
    if (t == null) return;
    final hpCost = (maxHp * 0.10).round();
    if (hp <= hpCost + 1 || (passive.id != 'rage' && hp < maxHp * 0.3)) return;
    hp -= hpCost;
    t.card.runes[t.rune] = t.level + 1;
    inc('sharpEvent');
  }

  /// D6, D39 : une rune contre une autre, aux deux tiers du niveau (arrondi,
  /// au moins 1), bornée par `maxLevel` ; `base × niveau` de la rune donnée.
  void visitWell() {
    inc('wellVisits');
    CardInst? bestCard;
    var from = '';
    var to = '';
    var toLevel = 0;
    var cost = 0;
    var bestGain = 0.5;
    for (final c in deck) {
      if (c.runes.isEmpty) continue;
      final base = staticValue(c);
      for (final e in c.runes.entries.toList()) {
        final price = p.wellBase * e.value;
        if (price > gold) continue;
        final raw = max(1, (e.value * 2 / 3).round());
        c.runes.remove(e.key);
        for (final r in data.runes) {
          if (r.id == e.key || !runeEligible(r, c, c.rank, p)) continue;
          final cap = maxLevel(r.id);
          final lvl = cap == null ? raw : min(raw, cap);
          c.runes[r.id] = lvl;
          final g = staticValue(c) - base;
          c.runes.remove(r.id);
          if (g > bestGain) {
            bestGain = g;
            bestCard = c;
            from = e.key;
            to = r.id;
            toLevel = lvl;
            cost = price;
          }
        }
        c.runes[e.key] = e.value;
      }
    }
    if (bestCard == null) return;
    spend(cost);
    bestCard.runes.remove(from);
    bestCard.runes[to] = toLevel;
    inc('wellSwaps');
  }

  bool get altarUsable {
    final counts = List.filled(relicRarities.length, 0);
    for (final r in relics) {
      if (r.trigger != 'special') counts[r.rarity]++;
    }
    return counts.sublist(0, 4).any((n) => n >= 3);
  }

  /// relic_exchange_screen.dart:28-41, :127-148 : 3 reliques d'une rareté
  /// contre une de la rareté au-dessus.
  void visitAltar() {
    final roll = rng.nextDouble();
    final offered = roll < 0.40 ? 1 : (roll < 0.75 ? 2 : (roll < 0.95 ? 3 : 4));
    final have = [
      for (final r in relics)
        if (r.rarity == offered - 1 && r.trigger != 'special') r,
    ]..shuffle(rng);
    if (have.length < 3) return;
    for (final r in have.take(3)) {
      loseRelic(r);
    }
    gainRelic(drawRelic(offered));
    inc('altarUses');
  }

  // --- Le chemin d'un acte ---

  /// DÉFAUT validé : « cartes » si le deck a une paire, sinon XP et relique
  /// en alternance.
  String preferredBoss() =>
      hasPair && !p.onlyFind ? 'cards' : (act.isOdd ? 'xp' : 'relic');

  /// Politique validée : le Puits s'il est accessible (le chemin y est
  /// planifié), puis événement, repos sous 50 % des PV, combat, boutique,
  /// élite, repos. L'Autel quand il est utilisable.
  MapNode choose(List<MapNode> options, List<MapNode> map) {
    final well = options.where((n) => n.type == 'well').firstOrNull;
    if (well != null) return well;
    final pref = preferredBoss();
    if (options.every((n) => n.type == 'boss')) {
      return options.where((n) => n.bossReward == pref).firstOrNull ??
          options[rng.nextInt(options.length)];
    }
    if (options.every((n) => n.floor == floors - 2)) {
      final good = options
          .where((n) => n.conns.any((id) => map[id].bossReward == pref))
          .toList();
      if (good.isNotEmpty) return good[rng.nextInt(good.length)];
    }
    final low = passive.id != 'rage' && hp < maxHp * 0.5;
    final order = [
      if (altarUsable) 'altar',
      'event',
      if (low) 'rest',
      'combat',
      'shop',
      'elite',
      'rest',
      'altar',
    ];
    for (final t in order) {
      final c = options.where((n) => n.type == t).toList();
      if (c.isNotEmpty) return c[rng.nextInt(c.length)];
    }
    return options[rng.nextInt(options.length)];
  }

  /// Les nœuds d'où l'on passe par le Puits : ses ancêtres, lui, ses
  /// descendants. `null` s'il n'y a pas de Puits.
  Set<int>? _wellRoute(List<MapNode> map) {
    final well = map.where((n) => n.type == 'well').firstOrNull;
    if (well == null) return null;
    final allowed = {well.id};
    final down = [well.id];
    while (down.isNotEmpty) {
      for (final n in map[down.removeLast()].conns) {
        if (allowed.add(n)) down.add(n);
      }
    }
    final parents = <int, List<int>>{};
    for (final n in map) {
      for (final t in n.conns) {
        parents.putIfAbsent(t, () => []).add(n.id);
      }
    }
    final up = [well.id];
    while (up.isNotEmpty) {
      for (final n in parents[up.removeLast()] ?? const <int>[]) {
        if (allowed.add(n)) up.add(n);
      }
    }
    return allowed;
  }

  void playAct() {
    final map = generateMap(act, rng, p);
    final allowed = _wellRoute(map);
    bool ok(MapNode n) => allowed == null || allowed.contains(n.id);
    var options = [for (final n in map) if (n.floor == 0 && ok(n)) n];
    while (options.isNotEmpty) {
      final node = choose(options, map);
      switch (node.type) {
        case 'combat':
          visitCombat(elite: false);
        case 'elite':
          visitCombat(elite: true);
        case 'rest':
          visitRest();
        case 'shop':
          visitShop();
        case 'event':
          visitEvent();
        case 'well':
          visitWell();
        case 'altar':
          visitAltar();
        case 'boss':
          visitBoss(node.bossReward);
          return;
      }
      options = [for (final id in node.conns) if (ok(map[id])) map[id]];
    }
  }

  /// Fin d'acte : le tour de dégâts contre 6 mannequins d'un combat normal
  /// de l'acte, puis le relevé de toutes les mesures.
  List<double> endOfAct() {
    var dmg = 0.0;
    for (var i = 0; i < 6; i++) {
      final foes = spawn(boss: false, elite: false, mannequin: true);
      dmg += Fight(this, foes, mannequin: true).runFight(measureTurns: 3).dmgPerTurn;
    }
    double avg(String k) {
      final l = actAcc[k];
      return l == null || l.isEmpty ? 0 : l.reduce((a, b) => a + b) / l.length;
    }

    double budgetUnder(double term) => budgetFor(
          level: level,
          act: act,
          maxHp: maxHp,
          might: might,
          maxMana: maxMana,
          relics: relics.length,
          deckTerm: term,
          boss: false,
          elite: false,
        ).budget;
    final runeLevels = [for (final c in deck) ...c.runes.values];
    final values = <String, double>{
      'deck': deck.length.toDouble(),
      'bestRank': deck.fold(0, (a, c) => max(a, c.rank)).toDouble(),
      'runes': runeLevels.length.toDouble(),
      'runeSum': runeLevels.fold(0, (a, b) => a + b).toDouble(),
      'runeMax': runeLevels.fold(0, (a, b) => max(a, b)).toDouble(),
      'ecoQuick': deck
          .where((c) => c.runes.containsKey('eco') || c.runes.containsKey('quick'))
          .length
          .toDouble(),
      'gold': gold.toDouble(),
      'level': level.toDouble(),
      'levelsAct': levelsAct.toDouble(),
      'xpAct': actXp,
      'evolutions': 2.0 * (level ~/ 5), // D19, D21 : tous les 5 niveaux
      'relics': relics.length.toDouble(),
      'd31Copies': (copies(relicD31A.id) + copies(relicD31B.id) + copies(relicD31C.id))
          .toDouble(),
      'power': avg('power'),
      'budget': avg('budget'),
      'budgetCur': budgetUnder(deck.length * 2.0),
      'budgetK2': budgetUnder(2.0 * sumRanks),
      'budgetK5': budgetUnder(5.0 * sumRanks),
      'budgetK10': budgetUnder(10.0 * sumRanks),
      'enemies': avg('enemies'),
      'enemyHp': avg('enemyHp'),
      'encounterHp': avg('encounterHp'),
      'dmgTurn': dmg / 6,
      'turns': avg('turns'),
      'enemyDmg': avg('enemyDmg'),
      'hpLoss': avg('hpLoss'),
      'hpPct': 100.0 * hp / maxHp,
    };
    return [for (final m in metricDefs) values[m.$1] ?? cum[m.$1] ?? 0.0];
  }
}

/// Une run complète : 15 actes (D26).
(List<double>, List<int>) simulateRun(Params p, String clsId, String lotId, int seed) {
  final run = Run(p, data.classes[clsId]!, lotId, Random(seed));
  final values = <double>[];
  for (var act = 1; act <= actCount; act++) {
    run
      ..act = act
      ..actXp = 0
      ..levelsAct = 0;
    run.actAcc.clear();
    run.playAct();
    values.addAll(run.endOfAct());
  }
  return (values, [for (final k in firstKeys) run.firsts[k] ?? 99]);
}

// ===========================================================================
// 10. Les lots de runs, en parallèle
// ===========================================================================

const configs = [
  ('paladin', 'rempart'),
  ('paladin', 'croise'),
  ('paladin', 'sanctifie'),
  ('berserker', 'sang'),
  ('berserker', 'vampire'),
  ('berserker', 'carnage'),
  ('mage', 'voile'),
  ('mage', 'marque'),
  ('mage', 'arcaniste'),
];
const allCfgs = [0, 1, 2, 3, 4, 5, 6, 7, 8];
const classLabel = {'paladin': 'Paladin', 'berserker': 'Berserker', 'mage': 'Mage'};
const lotLabel = {
  'rempart': 'Rempart',
  'croise': 'Croisé',
  'sanctifie': 'Sanctifié',
  'sang': 'Sang',
  'vampire': 'Vampire',
  'carnage': 'Carnage',
  'voile': 'Voile',
  'marque': 'Marque',
  'arcaniste': 'Arcaniste',
};
String configLabel(int cfg) =>
    '${classLabel[configs[cfg].$1]} · ${lotLabel[configs[cfg].$2]}';

/// Graine fixée : la run i de la configuration c a toujours la même graine,
/// quel que soit le levier — les écarts viennent du levier, pas du hasard.
const seedBase = 26000000;
const chunkSize = 25;

class Job {
  const Job(this.p, this.cfg, this.from, this.count);

  final Params p;
  final int cfg;
  final int from;
  final int count;
}

class Chunk {
  const Chunk(this.values, this.firsts);

  final Float64List values;
  final Int32List firsts;
}

Chunk runJob(Job j) {
  final (cls, lot) = configs[j.cfg];
  final values = Float64List(j.count * actCount * metricCount);
  final firsts = Int32List(j.count * firstKeys.length);
  for (var i = 0; i < j.count; i++) {
    final (v, f) = simulateRun(j.p, cls, lot, seedBase + j.cfg * 100000 + j.from + i);
    values.setAll(i * actCount * metricCount, v);
    firsts.setAll(i * firstKeys.length, f);
  }
  return Chunk(values, firsts);
}

Future<Chunk> _spawn(Job job) => Isolate.run(() => runJob(job));

/// Les runs d'une configuration sous un jeu de paramètres.
class Batch {
  Batch(this.cfg, this.runs, this.values, this.firsts);

  final int cfg;
  final int runs;
  final Float64List values;
  final Int32List firsts;

  double at(int run, int act, int m) =>
      values[(run * actCount + act - 1) * metricCount + m];
  int first(int run, int k) => firsts[run * firstKeys.length + k];

  Batch slice(int n) => Batch(
        cfg,
        n,
        Float64List.sublistView(values, 0, n * actCount * metricCount),
        Int32List.sublistView(firsts, 0, n * firstKeys.length),
      );
}

class Scenario {
  const Scenario(this.p, this.runs, this.cfgs);

  final Params p;
  final int runs;
  final List<int> cfgs;

  String get key => '${p.key}#$runs#${cfgs.join(',')}';
}

/// Fait tourner plusieurs scénarios dans un seul pool d'isolates.
Future<Map<String, List<Batch>>> runMany(List<Scenario> scenarios) async {
  final jobs = <(String, Job)>[];
  for (final s in scenarios) {
    for (final cfg in s.cfgs) {
      for (var from = 0; from < s.runs; from += chunkSize) {
        jobs.add((s.key, Job(s.p, cfg, from, min(chunkSize, s.runs - from))));
      }
    }
  }
  final results = List<Chunk?>.filled(jobs.length, null);
  var next = 0;
  Future<void> worker() async {
    while (next < jobs.length) {
      final i = next++;
      results[i] = await _spawn(jobs[i].$2);
    }
  }

  final workers = max(1, min(jobs.length, Platform.numberOfProcessors - 1));
  await Future.wait([for (var w = 0; w < workers; w++) worker()]);

  final out = <String, List<Batch>>{};
  for (final s in scenarios) {
    final batches = <Batch>[];
    for (final cfg in s.cfgs) {
      final values = Float64List(s.runs * actCount * metricCount);
      final firsts = Int32List(s.runs * firstKeys.length);
      for (var i = 0; i < jobs.length; i++) {
        final (key, job) = jobs[i];
        if (key != s.key || job.cfg != cfg) continue;
        values.setAll(job.from * actCount * metricCount, results[i]!.values);
        firsts.setAll(job.from * firstKeys.length, results[i]!.firsts);
      }
      batches.add(Batch(cfg, s.runs, values, firsts));
    }
    out[s.key] = batches;
  }
  return out;
}

// ===========================================================================
// 11. Statistiques et mise en forme
// ===========================================================================

List<double> column(List<Batch> bs, String metric, int act) {
  final m = metricIndex[metric]!;
  final out = <double>[];
  for (final b in bs) {
    for (var r = 0; r < b.runs; r++) {
      out.add(b.at(r, act, m));
    }
  }
  return out..sort();
}

List<double> firstColumn(List<Batch> bs, String key) {
  final k = firstKeys.indexOf(key);
  final out = <double>[];
  for (final b in bs) {
    for (var r = 0; r < b.runs; r++) {
      out.add(b.first(r, k).toDouble());
    }
  }
  return out..sort();
}

double quantile(List<double> s, double q) {
  if (s.isEmpty) return double.nan;
  final pos = (s.length - 1) * q;
  final lo = pos.floor();
  final hi = pos.ceil();
  return s[lo] + (s[hi] - s[lo]) * (pos - lo);
}

String fmtNum(double v, int dec) {
  if (v.isNaN) return '—';
  if (dec == 0) return '${v.round()}';
  return v.toStringAsFixed(dec).replaceAll('.', ',');
}

/// « médiane (P10–P90) », ou la médiane seule si les trois coïncident.
String cell(List<double> s, int dec) {
  final m = fmtNum(quantile(s, 0.5), dec);
  final a = fmtNum(quantile(s, 0.1), dec);
  final b = fmtNum(quantile(s, 0.9), dec);
  return a == m && b == m ? m : '$m ($a–$b)';
}

/// Acte médian (P10–P90) de la première fois, et la part des runs qui y
/// arrivent en 15 actes. Rang le plus proche : les actes sont entiers.
String firstCell(List<double> s) {
  String act(double q) {
    final v = s[((s.length - 1) * q).round()];
    return v > actCount ? '—' : 'A${v.round()}';
  }

  final pct = (100 * s.where((v) => v <= actCount).length / s.length).round();
  return '${act(0.5)} (${act(0.1)}–${act(0.9)}) · $pct %';
}

/// Les mesures des tables par classe × lot : celles que la mission demande.
const annexMetrics = {
  'deck', 'fusions', 'fusionsEvent', 'bestRank', 'runes', 'runeSum', 'runeMax',
  'ecoQuick', 'fires', 'rests', 'forgets', 'sharpens', 'sharpBoss', 'sharpEvent',
  'goldGained', 'goldSpent', 'gold', 'level', 'levelsAct', 'evolutions', 'relics',
  'power', 'budget', 'enemies', 'enemyHp', 'encounterHp', 'dmgTurn', 'turns',
  'enemyDmg', 'hpLoss', 'hpPct', 'nearDeaths', 'found', 'bossCards', 'shopCards',
  'copyCards', 'mirrorCards',
};

const shortLabels = {
  'deck': 'Deck',
  'fusions': 'Fusions',
  'fusionsEvent': 'Fusions D29',
  'exchanges': 'Échanges 3→1',
  'bestRank': 'Meilleur rang',
  'runes': 'Runes',
  'runeSum': 'Σ niveaux',
  'runeMax': 'Niveau max',
  'ecoQuick': 'eco + quick',
  'fires': 'Feux',
  'rests': 'Repos',
  'forgets': 'Oublis',
  'sharpens': 'Affûtages',
  'fireExchanges': '3→1 au feu',
  'sharpBoss': 'Niv. boss XP',
  'sharpEvent': 'Niv. événement',
  'goldGained': 'Or gagné',
  'goldSpent': 'Or dépensé',
  'gold': 'Or en réserve',
  'level': 'Niveau',
  'levelsAct': 'Niveaux / acte',
  'evolutions': 'Évolutions',
  'relics': 'Reliques',
  'd31Copies': 'Reliques D31',
  'power': 'PlayerPower',
  'budget': 'Budget',
  'enemies': 'Ennemis',
  'enemyHp': 'PV ennemi',
  'encounterHp': 'PV rencontre',
  'dmgTurn': 'Dégâts / tour',
  'turns': 'Tours',
  'enemyDmg': 'Dégâts ennemis / tour',
  'hpLoss': 'PV perdus / combat',
  'hpPct': 'PV %',
  'nearDeaths': 'Quasi-morts',
  'found': 'Trouvées',
  'bossCards': 'Clones boss',
  'shopCards': 'Achats',
  'copyCards': 'Copies D46',
  'mirrorCards': 'Clones Miroir',
  'wellVisits': 'Puits',
  'wellSwaps': 'Échanges Puits',
  'altarUses': 'Autel',
  'relicTrades': 'Reliques D23',
  'stalemates': 'Non finis',
  'firstFusion': '1re fusion',
  'firstRare': '1re rare',
  'firstEpic': '1re épique',
  'firstLegendary': '1re légendaire',
  'firstNearDeath': '1re quasi-mort',
  'firstCeiling': '1re mythique D42c prise',
  'ceilingOffers': 'D42c offerte',
  'ceilings': 'D42c prise',
};

/// Une colonne de table de levier : `metric@act` ou `first:clé`.
String columnHeader(String spec) {
  if (spec.startsWith('first:')) return shortLabels[spec.substring(6)]!;
  final [metric, act] = spec.split('@');
  return '${shortLabels[metric]} A$act';
}

String columnCell(List<Batch> bs, String spec) {
  if (spec.startsWith('first:')) return firstCell(firstColumn(bs, spec.substring(6)));
  final [metric, act] = spec.split('@');
  return cell(column(bs, metric, int.parse(act)), metricDefs[metricIndex[metric]!].$3);
}

void table(StringBuffer out, List<String> header, List<List<String>> rows) {
  out.writeln('| ${header.join(' | ')} |');
  out.writeln('|${[for (var i = 0; i < header.length; i++) i == 0 ? ':---' : '---:'].join('|')}|');
  for (final r in rows) {
    out.writeln('| ${r.join(' | ')} |');
  }
  out.writeln();
}

// ===========================================================================
// 12. Les leviers (mission : une table par levier, le reste fixé)
// ===========================================================================

class Variant {
  const Variant(this.label, this.p);

  final String label;
  final Params p;
}

class Lever {
  const Lever(this.title, this.source, this.variants, this.columns,
      {this.cfgs = allCfgs, this.byConfig = const []});

  final String title;
  final String source;
  final List<Variant> variants;
  final List<String> columns;
  final List<int> cfgs;

  /// Colonnes détaillées par classe × lot (une table par colonne).
  final List<String> byConfig;
}

List<String> at3(String metric) => ['$metric@5', '$metric@10', '$metric@15'];

List<Lever> buildLevers(Params ref, Params t3, Params k2, Params k2flat) => [
      Lever('Trouvaille — cartes garanties et seconde carte en élite', 'D31', [
        Variant('**1 garantie, élite 25 %** (réf.)', ref),
        Variant('1 garantie, élite 0 %', ref.copyWith(eliteExtra: 0)),
        Variant('1 garantie, élite 50 %', ref.copyWith(eliteExtra: 0.5)),
        Variant('2 garanties, élite 25 %', ref.copyWith(normalGuaranteed: 2)),
      ], [
        ...at3('deck'), 'fusions@15', 'bestRank@15', 'first:firstFusion',
        'first:firstRare', 'first:firstEpic', 'runeSum@15',
      ]),
      Lever('Sources de doublon — la prémisse de D48', 'D48, §4.1', [
        Variant('**toutes** (réf.)', ref),
        Variant('trouvaille seule (ni boss « cartes », ni achat, ni Miroir)',
            ref.copyWith(onlyFind: true)),
      ], [
        'fusions@5', 'fusions@15', 'bestRank@10', 'bestRank@15', 'deck@15',
        'first:firstFusion', 'first:firstRare', 'first:firstEpic',
      ]),
      Lever('Reliques de trouvaille', 'D31', [
        Variant('**A +25 %, B +1 %, dans la réserve** (réf.)', ref),
        Variant('A +15 %', ref.copyWith(relicAEliteBonus: 0.15)),
        Variant('A +50 %', ref.copyWith(relicAEliteBonus: 0.5)),
        Variant('B +2 % par exemplaire', ref.copyWith(relicBPerCopy: 0.02)),
        Variant('A, B, C tenues dès l’acte 1', ref.copyWith(d31Relics: 'forced')),
        Variant('Reliques absentes', ref.copyWith(d31Relics: 'absent')),
      ], [
        'd31Copies@5', 'd31Copies@15', 'found@15', 'deck@15', 'fusions@15',
        'first:firstRare', 'first:firstEpic',
      ]),
      Lever('Pool du Miroir', 'Q3, §4.1', [
        Variant('**mythique** (réf.)', ref),
        Variant('`draft`', ref.copyWith(mirrorPool: 'draft')),
      ], [
        'mirrorCards@15', 'fusions@15', 'bestRank@15', 'first:firstRare',
        'first:firstEpic', 'budget@15', 'dmgTurn@15',
      ]),
      Lever('Échange 3 → 1', 'D8, Q4', [
        Variant('**absent** (réf.)', ref),
        Variant('événement', ref.copyWith(exchange: 'event')),
        Variant('option du feu de camp', ref.copyWith(exchange: 'campfire')),
      ], [
        ...at3('deck'), 'exchanges@15', 'fusions@15', 'bestRank@15',
        'first:firstRare', 'first:firstEpic', 'sharpens@15', 'forgets@15',
      ]),
      Lever('Rythme du Puits', 'D22', [
        Variant('tous les 2 actes', ref.copyWith(wellEvery: 2)),
        Variant('**tous les 3 actes** (réf.)', ref),
        Variant('tous les 4 actes', ref.copyWith(wellEvery: 4)),
        Variant('aujourd’hui (25 % par carte)', ref.copyWith(wellEvery: 0)),
      ], [
        'wellVisits@15', 'wellSwaps@15', 'goldSpent@15', 'gold@15',
        'runeSum@15', 'runeMax@15', 'ecoQuick@15',
      ]),
      Lever('Rythme de l’Autel', 'Q16, map_content_placer.dart:10', [
        Variant('**aujourd’hui** (réf.)', ref),
        Variant('tous les 3 actes (4, 7, 10, 13)', ref.copyWith(altar: 'every3')),
        Variant('absent', ref.copyWith(altar: 'none')),
      ], [
        'altarUses@15', 'relics@10', 'relics@15', 'budget@15', 'relicTrades@15',
      ]),
      Lever('Coût de base de l’affûtage `b`', 'D20', [
        Variant('b = 25', ref.copyWith(sharpenB: 25)),
        Variant('**b = 50** (réf.)', ref),
        Variant('b = 100', ref.copyWith(sharpenB: 100)),
        Variant('b = 150', ref.copyWith(sharpenB: 150)),
      ], [
        ...at3('sharpens'), 'forgets@15', 'runeSum@15', 'runeMax@15',
        'gold@15', 'goldSpent@15',
      ], byConfig: [
        'sharpens@15', 'gold@15',
      ]),
      Lever('Forme de la courbe d’XP', 'D24, Q17', [
        Variant('actuelle, 100 × 1,5^(n−1)', ref.copyWith(xpCurve: 'current')),
        Variant('**table par acte, 2 niv./acte** (réf.)', ref),
        Variant('table par acte, 3 niv./acte', t3),
        Variant('palier constant (${k2.xpConstant} XP), calé sur l’acte 1', k2),
        Variant('palier constant (${k2flat.xpConstant} XP), XP sans bonus de niveau', k2flat),
      ], [
        'levelsAct@1', 'levelsAct@5', 'levelsAct@15', ...at3('level'),
        'evolutions@15', 'enemyHp@15', 'turns@15', 'hpPct@15', 'nearDeaths@15',
      ], byConfig: [
        'level@15', 'nearDeaths@15',
      ]),
      Lever('Coefficient de la DDA', 'D47, encounter_system.dart:101', [
        Variant('actuelle, cartes × 2', ref.copyWith(ddaK: -1)),
        Variant('**Σ rang × 2** (réf.)', ref),
        Variant('Σ rang × 5', ref.copyWith(ddaK: 5)),
        Variant('Σ rang × 10', ref.copyWith(ddaK: 10)),
      ], [
        'power@5', 'power@15', ...at3('budget'), 'encounterHp@15', 'turns@15',
        'nearDeaths@15', 'goldGained@15', 'level@15',
      ], byConfig: [
        'budget@15', 'turns@15',
      ]),
      Lever('`minFusionRank` d’`eco` et `quick`', 'D48', [
        Variant('**2, la rare** (réf.)', ref),
        Variant('3, l’épique', ref.copyWith(ecoQuickMinRank: 3)),
      ], [
        'ecoQuick@10', 'ecoQuick@15', 'runes@15', 'dmgTurn@15', 'turns@15',
      ]),
      Lever('Tirage des mythiques — la chance de D42(c)',
          'D42(c), D51, level_up_reward_service.dart:127-145', [
        Variant('**un jet par mythique, comme le code** (réf.)', ref),
        Variant('le pool sort à 0,5 %, puis une mythique (lecture de D51)',
            ref.copyWith(mythicMode: 'pool')),
      ], [
        'ceilingOffers@15', 'ceilings@15', 'first:firstCeiling', 'ecoQuick@15',
      ]),
      Lever('Budget de Puissance des cartes à 0 mana', 'Q21, D38', [
        Variant('**≤ coût + 1, D38 tel qu’écrit** (réf.)', ref),
        Variant('≤ max(coût, 0,5)', ref.copyWith(mightBudget: 'costFloor')),
      ], [
        ...at3('dmgTurn'), 'turns@15', 'hpLoss@15', 'nearDeaths@15',
      ], cfgs: const [0, 3, 4], byConfig: [
        'dmgTurn@10', 'dmgTurn@15',
      ]),
      Lever('Table des `maxLevel`', '§8, D27', [
        Variant('**table du §8** (réf.)', ref),
        Variant('sans plafond (sauf binaires)', ref.copyWith(maxLevelTable: 'uncapped')),
        Variant('plafond 5 partout', ref.copyWith(maxLevelTable: 'cap5')),
      ], [
        'runeSum@15', 'runeMax@15', 'sharpens@15', 'forgets@15', 'gold@15',
        'dmgTurn@15',
      ]),
      Lever('Ordre d’affûtage — pour information', '§4.2, D32', [
        Variant('**concentrer** (réf.)', ref),
        Variant('affûter avant de fusionner', ref.copyWith(sharpenStrategy: 'beforeFusion')),
      ], [
        'runeSum@15', 'runeMax@15', 'sharpens@15', 'goldSpent@15', 'gold@15',
        'dmgTurn@15',
      ]),
      Lever('Bénédiction, seuil 3 et Maîtrise sur le seuil — Sanctifié seul', 'D43', [
        Variant('**tranche de 5** (réf.)', ref),
        Variant('`threshold: 3`, plancher 2', ref.copyWith(blessingD43: true)),
      ], [
        'hpPct@5', 'hpPct@15', 'rests@15', 'sharpens@15', 'nearDeaths@15',
      ], cfgs: const [2]),
    ];

// ===========================================================================
// 13. Le programme
// ===========================================================================

int roundTo(double v, int step) => max(step, (v / step).round() * step);

/// Q17 : cale la courbe pour qu'un héros médian gagne [target] niveaux par
/// acte — sur l'acte 1 pour le palier constant (l'acte le plus pauvre en XP),
/// acte par acte pour la table. Quatre itérations : le niveau change le
/// niveau des ennemis, donc l'XP qu'ils rapportent.
Future<Params> calibrate(Params start, double target, int runs) async {
  var p = start.copyWith(xpConstant: 250, xpTable: List.filled(actCount, 250));
  for (var iter = 0; iter < 5; iter++) {
    final s = Scenario(p, runs, allCfgs);
    final batches = (await runMany([s]))[s.key]!;
    final xp = [
      for (var a = 1; a <= actCount; a++) quantile(column(batches, 'xpAct', a), 0.5),
    ];
    p = p.xpCurve == 'constant'
        ? p.copyWith(xpConstant: roundTo(xp[0] / target, 5))
        : p.copyWith(xpTable: [for (final x in xp) roundTo(x / target, 5)]);
  }
  return p;
}

Future<void> main(List<String> args) async {
  final quick = args.contains('--quick');
  final outAt = args.indexOf('--out');
  final outPath = outAt >= 0 && outAt + 1 < args.length ? args[outAt + 1] : null;
  final refRuns = quick ? 25 : 300;
  final leverRuns = quick ? 25 : 200;
  final calRuns = quick ? 10 : 40;
  final watch = Stopwatch()..start();
  void log(String s) => stderr.writeln('[${watch.elapsed.inSeconds} s] $s');

  log('calibration de la courbe d’XP (Q17)');
  const base = Params();
  final t2 = await calibrate(base.copyWith(xpCurve: 'perAct'), 2, calRuns);
  final t3 = await calibrate(base.copyWith(xpCurve: 'perAct'), 3, calRuns);
  final k2 = await calibrate(base.copyWith(xpCurve: 'constant'), 2, calRuns);
  final k2flat = await calibrate(
      base.copyWith(xpCurve: 'constant', xpLevelScaling: false), 2, calRuns);
  final ref = t2;

  log('référence : ${configs.length} configurations × $refRuns runs');
  final refScenario = Scenario(ref, refRuns, allCfgs);
  final refBatches = (await runMany([refScenario]))[refScenario.key]!;

  final levers = buildLevers(ref, t3, k2, k2flat);
  final scenarios = <String, Scenario>{};
  for (final l in levers) {
    for (final v in l.variants) {
      if (v.p.key == ref.key && l.cfgs == allCfgs) continue;
      final s = Scenario(v.p, leverRuns, l.cfgs);
      scenarios[s.key] = s;
    }
  }
  log('leviers : ${scenarios.length} scénarios × $leverRuns runs');
  final leverBatches = await runMany(scenarios.values.toList());
  List<Batch> batchesFor(Params p, List<int> cfgs) {
    if (p.key == ref.key && cfgs == allCfgs) {
      return [for (final b in refBatches) b.slice(leverRuns)];
    }
    return leverBatches[Scenario(p, leverRuns, cfgs).key]!;
  }

  final out = StringBuffer();
  out.writeln('# Simulation D26 — sorties brutes');
  out.writeln();
  out.writeln('Graine $seedBase. Référence : $refRuns runs par configuration ; '
      'leviers : $leverRuns runs par configuration, mêmes graines. '
      'Cellule : médiane (P10–P90). « A5 » : fin de l’acte 5.');
  out.writeln();
  out.writeln('Données lues : ${data.enemies.length} ennemis, '
      '${data.neutrals.length} neutres (noyau de ${coreNeutralIds.length}), '
      '${data.relics.length} reliques (+ 4 du brainstorm), '
      '${data.rewards.length} récompenses de niveau, ${data.runes.length} runes, '
      '${data.events.length} événements (+ 3 du brainstorm).');
  out.writeln();

  out.writeln('## Calibration de la courbe d’XP (Q17)');
  out.writeln();
  table(out, ['Forme', 'Cible', 'Valeur calée'], [
    ['Table par acte (réf.)', '2 niv./acte', t2.xpTable.join(' · ')],
    ['Table par acte', '3 niv./acte', t3.xpTable.join(' · ')],
    ['Palier constant', '2 niv. à l’acte 1', '${k2.xpConstant} XP par niveau'],
    ['Palier constant, XP sans bonus de niveau', '2 niv. à l’acte 1', '${k2flat.xpConstant} XP par niveau'],
  ]);

  out.writeln('## Référence — synthèse à l’acte 15');
  out.writeln();
  const synth = [
    'deck@15', 'fusions@15', 'bestRank@15', 'first:firstFusion', 'first:firstRare',
    'first:firstEpic', 'runeSum@15', 'sharpens@15', 'gold@15', 'level@15',
    'dmgTurn@15', 'enemyHp@15', 'turns@15', 'enemyDmg@15', 'hpLoss@15',
    'hpPct@15', 'nearDeaths@15', 'first:firstNearDeath',
  ];
  table(out, ['Configuration', for (final c in synth) columnHeader(c)], [
    for (final b in refBatches) [configLabel(b.cfg), for (final c in synth) columnCell([b], c)],
    ['**Toutes**', for (final c in synth) columnCell(refBatches, c)],
  ]);

  out.writeln('## Référence — toutes configurations, toutes les mesures');
  out.writeln();
  table(out, ['Mesure', for (final a in reportedActs) 'A$a'], [
    for (final m in metricDefs)
      [m.$2, for (final a in reportedActs) cell(column(refBatches, m.$1, a), m.$3)],
  ]);
  table(out, ['Première fois', 'Acte médian (P10–P90) · part des runs'], [
    for (final k in firstKeys) [shortLabels[k]!, firstCell(firstColumn(refBatches, k))],
  ]);

  out.writeln('## Référence — par classe × lot, par acte');
  out.writeln();
  for (final b in refBatches) {
    out.writeln('### ${configLabel(b.cfg)}');
    out.writeln();
    table(out, ['Mesure', for (final a in reportedActs) 'A$a'], [
      for (final m in metricDefs)
        if (annexMetrics.contains(m.$1))
          [m.$2, for (final a in reportedActs) cell(column([b], m.$1, a), m.$3)],
    ]);
    table(out, ['Première fois', 'Acte médian (P10–P90) · part des runs'], [
      for (final k in firstKeys) [shortLabels[k]!, firstCell(firstColumn([b], k))],
    ]);
  }

  out.writeln('## Leviers');
  out.writeln();
  for (final l in levers) {
    out.writeln('### ${l.title} (${l.source})');
    out.writeln();
    if (l.cfgs != allCfgs) {
      out.writeln('Configurations : ${l.cfgs.map(configLabel).join(', ')}.');
      out.writeln();
    }
    table(out, ['Variante', for (final c in l.columns) columnHeader(c)], [
      for (final v in l.variants)
        [v.label, for (final c in l.columns) columnCell(batchesFor(v.p, l.cfgs), c)],
    ]);
    for (final spec in l.byConfig) {
      out.writeln('*${columnHeader(spec)}, par classe × lot :*');
      out.writeln();
      table(out, ['Configuration', for (final v in l.variants) v.label], [
        for (final cfg in l.cfgs)
          [
            configLabel(cfg),
            for (final v in l.variants)
              columnCell([batchesFor(v.p, l.cfgs).firstWhere((b) => b.cfg == cfg)], spec),
          ],
      ]);
    }
  }

  log('terminé');
  if (outPath != null) {
    File(outPath).writeAsStringSync(out.toString());
    log('écrit : $outPath');
  } else {
    stdout.write(out.toString());
  }
}
