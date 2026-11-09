### 5.13. Table d'Icônes d'Effet — `EffectIconTable`, `EffectKind` et `effect_style`

Une seule table dit l'icône et la couleur de chaque **sorte d'effet** en combat : la bande et la
liste de la tuile de signature, les puces d'évolution, le panneau des statuts du héros et celui du
tutoriel. Vague 5, en attente du propriétaire — réponse P-6 (a),
[ADR-114](../_adr/ADR-114-les-evolutions-de-signature.md) D6. Le document et ses seize sortes :
[`_rules/07-00`](../_rules/07-00-architecture-des-donnees.md) §7.1.

> [!IMPORTANT]
> **La donnée nomme, l'interface traduit.** `assets/data/effect_icons.json` porte des **noms**
> (`"hardware_rounded"`, `"redAccent"`) ; seul `lib/ui/widgets/effect_style.dart` les traduit en
> `IconData` et `Color`. La couche données ne connaît ni Flutter ni Material, comme pour les runes
> (`rune_style.dart`, [`_patterns/10-00`](10-00-architecture-du-systeme-de-forge-et-de-fusion.md)).

#### 5.13.1. Les pièces

| Pièce | Fichier | Rôle |
|:---|:---|:---|
| `EffectKind` | `lib/models/data/effect_kind.dart` | **La seule écriture du vocabulaire** : `of(effect)` rend `status:<statusId>` pour un `apply_status`, son type sinon ; `isKind(key)` vrai pour `damage`, `armor`, `heal`, `draw`, `gain_mana`, `crit`, `target:allEnemies` ou `status:<id>` en `snake_case` |
| `EffectIconTable` / `EffectIconEntry` | `lib/models/data/effect_icon_table.dart` | Le document chargé : `entryOf(kind)`, `kinds` ; `fromJson` refuse, en nommant la clé, une sorte inconnue (`apply_status` nu compris), une valeur qui n'est pas un objet à `icon` et `color` non vides, une clé de trop. `EffectIconTable.empty()` sert de défaut aux widgets et aux registres de test |
| `effectIcons`, `effectColors` | `lib/ui/widgets/effect_style.dart` | Les deux tables de traduction, partagées avec les icônes d'évolution (`EvolutionIcon`, l'anneau d'une majeure) |
| `effectVisualsOf(table, kind)` | même fichier | L'icône et la couleur d'une sorte ; un nom inconnu ou une sorte absente retombent sur `Icons.help_outline` et le gris |
| `effectVisualsOrNull(table, kind)` | même fichier | `null` pour une sorte absente : le panneau des statuts garde alors son icône d'aujourd'hui (`metallicize`, `lifesteal`), jamais l'icône d'aide |

#### 5.13.2. Le chemin de la table

`loadGameDataRegistry` la charge par `GameDataLoader.loadDocument`, sa faute accumulée avec celles
des entités ([`_patterns/17-00`](17-00-chargeur-de-donnees-generique-et-motifs-de-che.md) §17.7) ;
le registre la porte en `effectIcons`, `EffectIconTable.empty()` par défaut. `GameScreen` la lit
dans le registre et la passe à `SignatureBar` et à `CombatSidePanels`, qui la passe à
`StatusEffectsPanel` ; le panneau des éléments du tutoriel la lit sur `engine.data`. **Aucun widget
ne lit le registre lui-même** : la table descend par paramètre, comme les autres données de combat.

#### 5.13.3. Ce qui garde l'alignement

| Garde | Ce qu'il rend impossible |
|:---|:---|
| `test/unit/effect_icon_table_test.dart` | Une sorte mal formée acceptée, une faute non nommée |
| `test/unit/referential_integrity_test.dart` | Un nom d'icône ou de couleur livré absent de `effectIcons` / `effectColors` ; un `status:<id>` que `EffectResolver.createStatus` ne fabrique pas ; **une sorte que les faces des cartes dessinent autrement** — Flutter (`getEffectVisuals`, `ui_card_helpers.dart`) et Flame (`CardTextRenderer.getEffectVisuals`) comparés au document, P-6 (a) |

> [!NOTE]
> **Trois jeux d'icônes subsistent à côté de la table** : les faces des cartes, qui gardent leur
> propre code mais doivent rester égales au document ; les émojis des statuts ennemis (Flame,
> `status_indicator.dart`) ; l'icône de la rune *Précis*, qui reprend le Vulnérable des cartes
> (`gps_fixed_rounded`) quand le critique de la table est `flare_rounded`. Les passer sur le document
> est une ligne de `docs/ROADMAP.md`.
