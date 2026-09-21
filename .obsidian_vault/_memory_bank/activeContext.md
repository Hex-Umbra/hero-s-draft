<!-- last-sync: 2026-09-21 | commit: 3727f09 -->

# 🧠 Contexte Actuel

> [!IMPORTANT]
> **Plafond : 240 lignes.** Focus courant, **3 dernières livraisons au maximum**, prochaine étape. Une 4ᵉ livraison pousse la plus ancienne vers `../_archive/`. Ce fichier ne contient jamais de backlog — voir `docs/ROADMAP.md`.

## Focus courant

**P-41 est terminé en entier**, ses quatre lots A à D fermés. Sa partie 2 du lot D — la console —
est fusionnée dans `main` par la **PR #45** (2026-09-20, merge `d27edc9`, `70fea1d`..`6c1a8dd`,
5 commits, détail plus bas) : **l'outillage rattrape la donnée que les trois premiers lots avaient
créée** — [ADR-100](../_adr/ADR-100-console-de-contenu-vocabulaire-du-moteur-et-ident.md).

**La note `0.5.2` n'a pas été rouverte** : ni entrée joueur, ni entrée Technique, jugé le
2026-09-20 — tout est sous `kDebugMode`, et `stat_rule.dart`, seul modèle livré touché, n'y gagne
que des lectures. **Première livraison du projet à entrer dans `main` sans aucune entrée de patch
note.** Rouverte six fois et pas une septième, la note a été **taguée et publiée le 2026-09-21**
— première publication depuis `v0.5.1`, détail dans `progress.md`, où vivent aussi les métriques.

**La condition préalable à P-42 est levée depuis** : le filtre de classe sur les pools d'offre est
livré le 2026-09-21 ([ADR-101](../_adr/ADR-101-predicat-de-proposabilite-unique-et-draft-de-depart.md)),
**et lui non plus n'a pas de note de version** — deuxième livraison du projet dans ce cas, pour un
motif inverse : le défaut corrigé était **latent**, les six cartes de classe livrées étant toutes
`unique` et donc déjà exclues des deux pools par `CardRarity.isAcquirable`. Rien n'avait jamais
fuité ; la correction est la fondation, pas le correctif.

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
- **Les tiers A, B, C et E de `docs/ROADMAP.md` n'ont toujours pas été re-vérifiés contre le
  code** — seuls S et D l'ont été (2026-08-04).
- **Bouton de téléchargement mort** si le build Windows échoue quand le web réussit — correctif
  identifié, non fait, voir [ADR-080](../_adr/ADR-080-site-vitrine-pilote-par-la-donnee-et-jointure-decl.md).

## 3 dernières livraisons

1. **Le filtre de classe sur les pools d'offre — un prédicat, deux appels, un piège gardé**
   (2026-09-21, branche `fix/filtre-cartes-de-classe`, commit `3727f09`) — **la règle « une classe
   ne se voit proposer que ses propres cartes de signature » cesse de n'avoir aucun domicile.** Le
   prédicat d'éligibilité était recopié mot pour mot en boutique et au bonus de boss `doubleXp`, et
   aucun des deux `Notifier` ne lisait `runProvider.heroClassId` : c'était la cause, plus que le
   défaut — rien n'aurait rappelé la condition de classe au troisième pool créé.
   `CardData.isOfferableTo` porte désormais la règle entière, et **ne teste que `heroClass`, jamais
   `category` en plus** : le chargeur injecte les deux depuis le même chemin de fichier, les tester
   tous les deux ferait croire à deux conditions. **Le draft de départ reste délibérément dehors**,
   sur `category == global` — les signatures y sont ajoutées d'office par `getHeroCards`, les offrir
   aussi les rendrait prenables deux fois ; le test qui le garde a été **vérifié en appliquant la
   correction fautive**, qui le fait passer de 10 à 11 cartes offertes. **Aucun effet joueur, et
   aucune note de version** : les six cartes de classe livrées sont toutes `unique` depuis
   `f381e85` (2026-09-05), donc déjà exclues des deux pools — **le défaut était latent, jamais
   observable**, et la prémisse du brainstorm du 08/09 (« un paladin peut acheter une carte de
   mage ») était déjà fausse quand elle a été écrite. **1187 tests** (+8), `dart analyze` propre —
   [ADR-101](../_adr/ADR-101-predicat-de-proposabilite-unique-et-draft-de-depart.md).
2. **P-41 lot D, partie 2 — la console rattrape l'identité de classe** (2026-09-20, **fusionné
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
3. **P-41 lot D, partie 1 — le tutoriel enseigne la classe qu'on a choisie**
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
> [!NOTE]
> **Rotations.** Sortie le 2026-09-21, dans `../_archive/` : `2026-09-21-activeContext-livraisons.md`
> (P-41 lot C partie 2). Sorties le 2026-09-20 : `2026-09-20-activeContext-livraisons-3.md`
> (P-41 lot C partie 1), `2026-09-20-activeContext-livraisons-2.md` (lot B partie 2) et
> `2026-09-20-activeContext-livraisons.md` (lot B partie 1, avec quatre réserves closes). Sorties
> le 2026-09-18 : `2026-09-18-activeContext-livraisons-2.md` (P-49) et
> `2026-09-18-activeContext-livraisons.md` (P-41 lot A). Les onze rotations précédentes portent le
> même nom, daté du 2026-09-17 au 2026-08-20.

## Prochaine étape

**P-41 n'a plus de lot ouvert, et sa livraison est entre les mains des joueurs** : campagne de test
manuelle du propriétaire faite, tag posé et publication verte le 2026-09-21. **Le chantier suivant
est P-42** — pools de cartes par classe —, qui n'a pas encore de spec : il s'ouvre par un
brainstorm. **Le filtre de classe des cartes de signature, qui le précédait, est fait**
([ADR-101](../_adr/ADR-101-predicat-de-proposabilite-unique-et-draft-de-depart.md)) : P-42 peut
donner à ses cartes n'importe quelle rareté sans qu'aucune fuie d'une classe à l'autre. Reste une
seule chose à trancher avant lui, tenue dans `docs/ROADMAP.md` : la **Maîtrise dans l'onglet Héros
du menu de debug**, laissée hors du lot D partie 2 alors qu'elle pilote tout P-49 — question ouverte
en ROADMAP §4.

Le Jalon 2 « Feel & contenu » (`docs/ROADMAP.md` §9) reste ouvert : P-06, P-07, le prototype de
P-08, P-05. **P-07 doit lire [ADR-083](../_adr/ADR-083-latence-et-synchronisation-du-chemin-de-lecture.md)
D6 avant de toucher aux animations.**
