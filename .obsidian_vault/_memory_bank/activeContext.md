<!-- last-sync: 2026-09-20 | commit: d27edc9 -->

# 🧠 Contexte Actuel

> [!IMPORTANT]
> **Plafond : 120 lignes.** Focus courant, **3 dernières livraisons au maximum**, prochaine étape. Une 4ᵉ livraison pousse la plus ancienne vers `../_archive/`. Ce fichier ne contient jamais de backlog — voir `docs/ROADMAP.md`.

## Focus courant

**P-41 est terminé en entier**, ses quatre lots A à D fermés. Sa partie 2 du lot D — la console —
est fusionnée dans `main` par la **PR #45** (2026-09-20, merge `d27edc9`, `70fea1d`..`6c1a8dd`,
5 commits, détail plus bas) : **l'outillage rattrape la donnée que les trois premiers lots avaient
créée** — [ADR-100](../_adr/ADR-100-console-de-contenu-vocabulaire-du-moteur-et-ident.md).

**La note `0.5.2` n'a pas été rouverte** : ni entrée joueur, ni entrée Technique, jugé le
2026-09-20 — tout est sous `kDebugMode`, et `stat_rule.dart`, seul modèle livré touché, n'y gagne
que des lectures. **Première livraison du projet à entrer dans `main` sans aucune entrée de patch
note.** La note reste ni taguée ni publiée (dernière release `v0.5.1`), rouverte six fois et pas
une septième. Métriques dans `progress.md`.

Réserves à ne pas perdre de vue :

- **⚠️ Les lots 1-2 de P-48 cassent toujours les sauvegardes antérieures à leurs ids de passifs en
  `snake_case`** (commit `7da5db2`). P-41 lot A a posé une chaîne de migration (`SaveMigrator`) et
  changé de clé de stockage (`run_save`, repli sur `run_save_v1`), mais sa seule étape migre
  `attaque` → `attackPower` : l'id de passif n'y est pas touché, et une partie d'avant `7da5db2` perd
  toujours son passif de classe au chargement, signalé par un `MissingSaveItem`. La note de version
  reste le seul canal qui prévienne *avant*.
- **La note `0.5.1` est close et publiée** (décision du 2026-09-16). La version que visent P-42 et la
  suite est tenue dans `docs/ROADMAP.md` ; le numéro publié se lit dans `pubspec.yaml` et la 1ʳᵉ
  entrée de `assets/data/patch_notes.json`, jamais ici.
- **Les cartes de signature non `unique` fuient toujours entre classes** en boutique et sur le bonus
  de boss — [filtre de classe](../../docs/possible_upgrades/08-09-2026_filtre_cartes_de_classe_Opus5.md),
  à joindre à `CardRarity.isAcquirable`, avant ou avec P-42. **Re-vérifié contre le code le
  2026-09-16 : non fait.** Les deux prédicats fautifs ne testent que le type et la rareté
  (`shop_controller.dart:45-51`, `reward_controller.dart:189`), aucun des deux `Notifier` ne lit
  `runProvider.heroClassId`, et `CardData` ne porte aucun prédicat de proposabilité. Ce que P-40
  bloc 2 a fait à ces deux mêmes lignes, c'est y substituer `CardRarity.isAcquirable` au
  `rarity != unique` en ligne — la condition de classe n'y est jamais entrée, et le seul commit sur
  le sujet reste `39ac887`, qui documente le défaut sans le corriger.
- **Les tiers A, B, C et E de `docs/ROADMAP.md` n'ont toujours pas été re-vérifiés contre le
  code** — seuls S et D l'ont été (2026-08-04).
- **Bouton de téléchargement mort** si le build Windows échoue quand le web réussit — correctif
  identifié, non fait, voir [ADR-080](../_adr/ADR-080-site-vitrine-pilote-par-la-donnee-et-jointure-decl.md).

## 3 dernières livraisons

1. **P-41 lot D, partie 2 — la console rattrape l'identité de classe** (2026-09-20, **fusionné
   dans `main` par la PR #45**, merge `d27edc9`, 5 commits, `70fea1d` → `6c1a8dd`, branche
   `feat/p41-lot-d-console`) — **l'outil qui écrit la donnée apprend enfin ce que trois lots y ont
   mis.** L'éditeur laissait passer `"mode": "convrt"` : les trois clés de `statRules` sont
   bornées, et leur vocabulaire est **lu sur `StatRule`** — `status:might` ne s'écrit pas
   `statusMight`, et seul le parseur connaît la correspondance. La création guidée d'une classe
   écrit un **passif de départ** dérivé de l'identifiant de la classe, avec `classes: [<id>]` : une
   classe créée n'avait jusque-là aucun passif disponible — choix vide à la sélection, et
   `referential_integrity_test` rouge *après* écriture des fichiers. Pour que ce passif ne soit pas
   refusé par une référence vers une classe que le registre ignore encore, `EntityValidator` gagne
   **`pendingIds`** — ce que la même transaction va écrire —, le trou décrit dans le code depuis
   P-30 enfin nommé ; l'unicité, elle, continue de lire le registre seul. Les récompenses de niveau
   deviennent la **8ᵉ catégorie éditable**, par une entrée de table. Le menu de debug règle les
   cibles de la Puissance (puces générées, la dernière non retirable : `HeroData` refuse une liste
   vide) et affiche classe, règles de stat et passif actif en lecture seule, **dans le vocabulaire
   du fichier**. **Aucun effet joueur.** **1179 tests** (+20), `dart analyze` propre —
   [ADR-100](../_adr/ADR-100-console-de-contenu-vocabulaire-du-moteur-et-ident.md).
2. **P-41 lot D, partie 1 — le tutoriel enseigne la classe qu'on a choisie**
   (2026-09-20, **fusionné dans `main` par la PR #44**, merge `54c28dd`, 9 commits,
   `30d48dc` → `639a222`, branche `feat/p41-lot-d-tutoriel`) — **le tutoriel cesse d'enseigner
   une règle que la classe choisie ne suit pas.** Trois étapes arrêtaient chacune de court-circuiter
   un point de passage qui existait déjà : l'étape 02 déplie les passifs que `availablePassivesFor`
   ouvre à la classe — dans le **`ClassPassiveList` de l'écran de sélection**, le widget de
   production et non une seconde implémentation (spec §1.4) — et retaper la classe déjà choisie
   replie sa carte au lieu de reposer son passif. L'étape « Armure & Dégâts » fait passer son gain
   de démonstration par `StatGains.apply` et les `statRules` de la classe au lieu d'écrire 4 Armure
   en dur : elle se joue **en deux temps** (le gain, puis le coup), son panneau droit part de 0, son
   titre est **généré** depuis la règle qui vise l'Armure (`shortTitle`, deux clés ARB neuves) et la
   règle est écrite en clair sous les panneaux par `StatRuleLabel.describe`. L'étape « Jouer des
   cartes » **mesure le gain réel** de part et d'autre de `playCard` au lieu de lire la valeur
   imprimée sur la carte. Les deux acquis que le lot B avait livrés sans les verrouiller —
   `critChance` forcé à 0, conversion d'armure appliquée par `playCard` — passent sous test.
   **Aucun mécanisme nouveau, donc aucun ADR** : la livraison applique ADR-081, ADR-090 et
   ADR-097. **1159 tests** (+24), `dart analyze` propre.
3. **P-41 lot C, partie 2 — le choix du passif, et le conditionnement des récompenses**
   (2026-09-20, **fusionné dans `main` par la PR #43**, merge `2f850c4`, 20 commits de code,
   `2d167fa` → `0db8d4e`, branche `feat/p41-lot-c-selection`) — **l'écran de sélection de classe
   cesse de mentir deux fois.** Le joueur y **choisit son passif** : la carte déplie *tous* ceux
   que `availablePassivesFor()` rend — jamais un `take(3)`, trois étant un compte et non une règle
   que P-13 fera varier — et le retenu part avec la run. Six des neuf passifs du lot B étaient
   jusque-là livrés, testés et inatteignables. `baseDamage` (5 / 15 / 10) quitte `HeroData`, les
   trois `class.json` et `sword_icon.dart` : aucune run ne le reprenait, toutes démarrant à
   `might: 0`. La carte montre à la place les PV et le mana **toujours**, `mastery`, `critChance`
   et `luck` **seulement si > 0**, plus l'orientation de la Puissance et la règle de stat en clair
   — trois textes **générés depuis la donnée**, sur des `switch` exhaustifs dans
   `model_extensions.dart`, aucun `hero.id` comparé (ADR-090) ; premier **pluriel ICU** des ARB du
   projet. *Affinité* n'est plus tirée quand le passif actif ne déclare pas de `mastery` : un champ
   `requires` sur `LevelUpRewardData`, **le mécanisme et non la récompense**, qui lit
   `RunState.activePassive` et non le point d'accès de P-49. La carte se dimensionne désormais à
   son contenu — une colonne sur mobile, rangées intrinsèques en desktop. **1135 tests** (+70),
   `dart analyze` propre —
   [ADR-099](../_adr/ADR-099-choix-du-passif-et-conditionnement-des-recompenses.md).
> [!NOTE]
> **Rotations.** Sorties le 2026-09-20, dans `../_archive/` : `2026-09-20-activeContext-livraisons-3.md`
> (P-41 lot C partie 1), `2026-09-20-activeContext-livraisons-2.md` (lot B partie 2) et
> `2026-09-20-activeContext-livraisons.md` (lot B partie 1, avec quatre réserves closes). Sorties
> le 2026-09-18 : `2026-09-18-activeContext-livraisons-2.md` (P-49) et
> `2026-09-18-activeContext-livraisons.md` (P-41 lot A). Les onze rotations précédentes portent le
> même nom, daté du 2026-09-17 au 2026-08-20.

## Prochaine étape

**P-41 n'a plus de lot ouvert.** Ce qui reste n'est pas du code : il reste au propriétaire à
**regarder tourner les lots B, C et D** — les trois identités de classe, le nouvel écran de
sélection et le tutoriel ne se vérifient pas par la suite de tests, et les cartes de classe ont été
recalibrées à l'œil. Le tag `v0.5.2` attend cette campagne manuelle et P-42. Deux choses à trancher
avant le chantier suivant, tenues dans `docs/ROADMAP.md` : le **filtre de classe des cartes de
signature** (avant ou avec P-42), et la **Maîtrise dans l'onglet Héros du menu de debug**, laissée
hors du lot D partie 2 alors qu'elle pilote tout P-49 — question ouverte en ROADMAP §4.

Le Jalon 2 « Feel & contenu » (`docs/ROADMAP.md` §9) reste ouvert : P-06, P-07, le prototype de
P-08, P-05. **P-07 doit lire [ADR-083](../_adr/ADR-083-latence-et-synchronisation-du-chemin-de-lecture.md)
D6 avant de toucher aux animations.**
