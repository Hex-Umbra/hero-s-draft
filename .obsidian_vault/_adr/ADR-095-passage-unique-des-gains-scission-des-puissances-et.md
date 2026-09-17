## 🧮 ADR-095 : Passage Unique des Gains, Scission des Puissances et Chaîne de Migration de Sauvegarde (P-41, lot A)

### Statut
✅ Accepté & Implémenté — branche `feat/p41-lot-a` (commits `674545c`..`b94c854`, 10 commits),
**fusionnée dans `main` par la PR #38 le 2026-09-16** (merge `f8be03a`) — **amende
[ADR-069](ADR-069-systeme-de-sauvegarde-de-run-checkpoint-carte-refr.md)**
(point 5, chaîne de sauvegarde).
**Décision 2 (scission de `attaque` en trois puissances) remplacée par
[ADR-097](ADR-097-puissance-unique-orientee-par-la-classe.md)** (P-41, lot B, partie 1,
2026-09-17) : les trois puissances fusionnent en une seule, `might`, que la classe oriente.

### Contexte
La spec [S2 — Identité de classe](../../docs/superpowers/specs/2026-08-07-s2-identite-de-classe-design.md)
§4 vise à distinguer les classes par leurs stats plutôt que par leurs seuls PV et passif ; cela suppose
qu'un gain de stat (armure, mana, puissance) passe toujours par le même endroit, et que l'attaque du
héros se scinde en trois puissances typées par carte. Six passes de re-vérification du 2026-09-16 ont
montré que ni l'un ni l'autre n'étaient vrais : trois gains d'armure et de mana écrivaient par
`copyWith` hors de `setHeroStats`, un gain de puissance (récompense *Aiguisage*) n'était recensé
nulle part, et le tutoriel (P-45) portait sa propre copie du calcul de dégâts, seule source des 50
écarts corrigés alors. Par ailleurs, `SaveService.load()` effaçait toute sauvegarde dont
`schemaVersion` différait de 1 (ADR-069, point 5) : incrémenter cette version pour accueillir les
nouvelles puissances aurait effacé toute run en cours, sans qu'aucune chaîne de migration n'existe
pour l'éviter — la première du projet restait à écrire. Le lot A pose ces trois fondations **sans
changement de comportement pour le joueur**, à une conséquence assumée près (spec §4.3, décision D8) :
plan détaillé —
[`docs/superpowers/plans/2026-09-16-p41-lot-a-passage-unique-scission-migration.md`](../../docs/superpowers/plans/2026-09-16-p41-lot-a-passage-unique-scission-migration.md).

### Décision
1. **`StatGains.apply(EntityStats, StatGain)`** (`lib/game/systems/stat_gains.dart`) devient le seul
   point de passage d'un gain d'armure, de mana ou de puissance. `StatGain(GainResource, int amount,
   GainSource)` décrit le gain sans l'appliquer ; `GainSource` (`card`, `rune`, `passive`, `relic`,
   `status`, `progression`, `enemyIntent`) étiquette sa provenance. La Maîtrise d'Armure
   (`effectiveArmorMastery`) ne s'ajoute qu'aux gains `GainSource.passive` — périmètre déjà en
   vigueur avant le lot A (la récompense *Forge d'Acier* y est calibrée, `_rules/06-00` §6.3), rendu
   ici explicite et vérifiable plutôt qu'implicite au site d'appel. `test/unit/stat_gain_single_passage_test.dart`
   interdit toute addition écrite en ligne ailleurs que dans `apply`. `RunController.grant`/
   `PlayerStatsManager.grant` sont la façade ; `setHeroStats` est supprimé, tous ses appelants
   convertis à `grant`.
2. **Trois puissances remplacent `attaque`** sur `EntityStats` : `attackPower` (renommage direct,
   clé JSON `attaque` inchangée à ce stade), `skillPower` et `alterationPower` (nouveaux, défaut `0`).
   L'extension pure `PowerRules` (`lib/game/systems/power_rules.dart`) décide quelle puissance
   renforce quel effet, selon la carte qui le porte : `damageBonusFor(CardType)` — `attackPower` +
   Force pour une carte Attaque, `skillPower` seul pour une carte Compétence, rien pour Pouvoir et
   Statut ; `statusBonusFor(CardTarget)` — `alterationPower` s'ajoute à l'**intensité** (jamais la
   durée) d'un statut posé sur un ennemi par une carte ou par une rune, rien sur soi. La règle vit
   dans une extension et non sur `EntityStats` : ce modèle est partagé avec les ennemis, et
   `PowerRules` importe `card_data.dart`, ce qui ferait dépendre `EntityStats` du registre de données
   pour une règle qui ne sert qu'au héros. Résolution de carte, runes, tutoriel (ADR-081, fonction
   pure sans provider) et aperçu des dégâts en carte lisent tous la même règle. **Aucun effet visible
   aujourd'hui** : les 12 effets `damage` du catalogue sont tous portés par des cartes Attaque, et
   `skillPower`/`alterationPower` valent 0 pour tout le monde.
3. **`SaveMigrator`** (`lib/services/save_migrations.dart`) amène un blob de sauvegarde à
   `saveMigrator.currentVersion` (2 depuis ce lot) en traversant `steps[n]` de proche en proche, au
   lieu d'échouer sur toute version différente de la version de référence. `steps[1]` renomme
   `heroStats.attaque` en `heroStats.attackPower` (`skillPower`/`alterationPower` n'ont pas besoin
   d'être écrites : `EntityStats.fromJson` les lit à 0 quand elles manquent). `migrate()` distingue
   trois cas : version absente/non entière/`< 1` → `FormatException` (sauvegarde corrompue,
   `SaveService` l'efface) ; version `> currentVersion` → `SaveFromNewerBuildException`
   (sauvegarde **conservée**, jamais effacée, `SaveLoadResult.savedByNewerBuild = true`) ; étape
   manquante entre deux versions connues → `StateError` (erreur de programmation, pas une donnée
   utilisateur). La version courante est **déclarée** sur `saveMigrator`, jamais déduite du nombre
   d'étapes.
4. **Nouvelle clé de stockage `run_save`** (décision du propriétaire, D8) : `save()` écrit désormais
   sous `run_save` et retire `run_save_v1` ; `load()` lit `run_save`, à défaut `run_save_v1`.
   Toutes les versions web du jeu partagent la même origine et restent en ligne, donc le même
   `shared_preferences` — et tout build publié jusqu'à `0.5.1` efface sans recours toute sauvegarde
   dont `schemaVersion` diffère de 1 sous `run_save_v1`. Changer la clé au lieu du seul schéma fait
   qu'un build publié ignore silencieusement une sauvegarde écrite par ce lot, au lieu de l'effacer.
   Conséquence assumée et **seule visible pour le joueur** : une partie sauvegardée par ce build
   n'est plus proposée par les builds antérieurs, elle n'y est plus effacée.
5. **Suppression de la chaîne morte `bonusAttack`** : `RunState.effectiveAttaque` n'alimentait que
   `HeroCard.bonusAttack`, transmis mais jamais lu (`hero_card.dart`). Supprimée avant le renommage
   de `attaque`, pour ne pas le lui faire traverser.

### Preuves dans le code
- `lib/game/systems/stat_gains.dart` (`GainResource`, `GainSource`, `StatGain`, `StatGains.apply`).
- `lib/game/systems/power_rules.dart` (`extension PowerRules on EntityStats`).
- `lib/services/save_migrations.dart` (`SaveMigrator`, `SaveFromNewerBuildException`, `saveMigrator`,
  `_migrateV1ToV2`).
- `lib/services/save_service.dart` (`_saveKey = 'run_save'`, `_legacySaveKey = 'run_save_v1'`,
  `SaveLoadResult.savedByNewerBuild`).
- `lib/game/controllers/run/player_stats_manager.dart` (`grant`), `lib/game/controllers/run_controller.dart`
  (façade `grant`, `setHeroStats` supprimé).
- `lib/models/entity_stats.dart` (`attackPower`, `skillPower`, `alterationPower`,
  `effectiveAttackPower`).
- `lib/ui/screens/home_screen.dart` (dialogue `newerSaveTitle`/`newerSaveMessage`), ARB
  `app_fr.arb`/`app_en.arb`.
- Tests : `test/unit/stat_gain_single_passage_test.dart`, `test/unit/stat_gains_characterization_test.dart`,
  `test/unit/power_split_test.dart`, `test/unit/save_migrations_test.dart`,
  `test/unit/save_service_test.dart`, `test/widget/home_screen_save_test.dart`.

### Conséquences
- ✅ **Un seul endroit sait quelles règles s'appliquent à un gain** : la Maîtrise d'Armure ne peut
  plus s'appliquer par accident à un gain non-passif, ni en manquer un qui devrait l'avoir — le
  guard test le verrouille.
- ✅ **Le tutoriel et le jeu partagent la même règle de puissance** (`PowerRules`) au lieu d'une copie
  qui dérive avec le temps (cause des 50 écarts d'ADR-081).
- ✅ **Une sauvegarde ancienne n'est plus effacée par une évolution de schéma** : `SaveMigrator` pose
  l'infrastructure que P-41 lot suivant et P-49 réutiliseront pour leurs propres étapes.
- ⚠️ **Un build antérieur n'affiche plus la sauvegarde écrite par ce lot** au lieu de l'effacer —
  décision assumée du propriétaire (D8), inverse d'ADR-069 point 5 sur ce point précis.
- ⚠️ **Suites relevées, non traitées par ce lot** (six suites techniques dans le plan, trois suites de
  revue finale dans `docs/ROADMAP.md` §4) : le budget de rencontre ne compte que `attackPower`,
  l'aperçu de carte n'affiche pas `alterationPower`, `run_save`/`run_save_v1` ne s'arbitrent pas par
  date lorsqu'ils coexistent, le dialogue d'écrasement de « Nouvelle Partie » ne mentionne pas une
  sauvegarde plus récente, et un double bonus d'`alterationPower` (carte + rune sur la même carte)
  reste à surveiller dès que l'un des deux chemins devient réel.
