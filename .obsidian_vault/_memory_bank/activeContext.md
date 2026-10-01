<!-- last-sync: 2026-10-01 | commit: 25c36ba -->

# 🧠 Contexte Actuel

> [!IMPORTANT]
> **Plafond : 240 lignes.** Focus courant, **3 dernières livraisons au maximum**, prochaine étape. Une 4ᵉ livraison pousse la plus ancienne vers `../_archive/`. Ce fichier ne contient jamais de backlog — voir `docs/ROADMAP.md`.

## Focus courant

**Le programme P-43 → P-42 → P-44 lot 1 est conçu, et il se livre par vagues.** Les trois chantiers
qui restaient du programme « Identité de classe & catalogue » ont été reconçus par le
[brainstorm v3](../../docs/possible_upgrades/22-09-2026_brainstorm_heros_et_cartes_v3_Fable5.md)
(22/09 → 01/10), relu en six passes et adossé à une simulation de l'économie de deck.
**L'ordre s'est inversé** : l'économie de deck (P-43) précède le catalogue (P-42), parce qu'elle
décide combien de runes une carte porte et à quel rythme les doublons arrivent — donc combien de
cartes un lot peut contenir.

**La méthode a changé** — [ADR-102](../_adr/ADR-102-chantier-par-vagues-une-version-par-vague.md) :
une vague par version du jeu, une session par vague, un orchestrateur qui délègue la spec, le plan
et l'implémentation à des agents, fait vérifier chaque document par un agent qui ne l'a pas écrit,
et arbitre seul les questions de spec. **Le propriétaire garde le test manuel, la PR, la fusion et
le tag** ; une vague s'arrête sur sa branche et ne pousse rien. Relue avant la première vague, la
méthode est amendée par
[ADR-103](../_adr/ADR-103-vagues-fusion-puis-tag-reference-de-simulation-suivi.md) : la fusion
précède le tag, un plan ne reprend aucun geste de livraison du plan modèle, une vague interrompue
se retrouve par sa branche, la simulation se compare à une sortie de référence suivie par git —
en deux temps, le réalignement seul puis chaque changement voulu —, chaque vague laisse un compte
rendu écrit et une section dans le suivi du chantier, sous `docs/suivi_vagues_chantier/` — ce
qu'elle apporte au jeu et pourquoi, sans technique, selon le modèle du répertoire —, et une
session de clôture ferme le chantier après le dernier tag.

**Deux documents font foi, et ne se recopient pas** : le
[fichier d'orchestration](../../docs/possible_upgrades/01-10-2026_orchestration_chantier_economie_et_catalogue_Fable5.md)
pour le *déroulé* — vagues, versions, journal d'avancement, fiches de vague — et le brainstorm v3
pour les *décisions de conception*. `docs/ROADMAP.md` garde une ligne par chantier et y renvoie.

**Aucun code n'a changé depuis le 2026-09-21** : `git diff 3727f09..HEAD -- lib test assets` est
vide. Seuls des documents et un outil hors build, la simulation, sont entrés dans `main`.

Réserves à ne pas perdre de vue :

- **⚠️ Les lots 1-2 de P-48 cassent toujours les sauvegardes antérieures à leurs ids de passifs en
  `snake_case`** (commit `7da5db2`). P-41 lot A a posé une chaîne de migration (`SaveMigrator`) et
  changé de clé de stockage (`run_save`, repli sur `run_save_v1`), mais sa seule étape migre
  `attaque` → `attackPower` : l'id de passif n'y est pas touché, et une partie d'avant `7da5db2` perd
  toujours son passif de classe au chargement, signalé par un `MissingSaveItem`. La note de version
  reste le seul canal qui prévienne *avant*.
- **La version publiée se lit dans `pubspec.yaml` et la 1ʳᵉ entrée de
  `assets/data/patch_notes.json`, jamais ici.** Les versions que visent les vagues font foi dans
  le fichier d'orchestration, §1 ; la décision qui les fixe et le suivi du chantier les rappellent.
- **Une vague vérifie par `gh` que la précédente est taguée et que sa CI/CD est verte.** Le
  2026-10-01, `gh` a échoué une fois à joindre l'API GitHub depuis la session, puis a répondu.
  Si cela se reproduit à une porte d'entrée, c'est le propriétaire qui confirme, et le journal
  le note — la porte ne suppose jamais.
- **Les tiers A, B, C et E de `docs/ROADMAP.md` n'ont toujours pas été re-vérifiés contre le
  code** — seuls S et D l'ont été (2026-08-04).
- **Bouton de téléchargement mort** si le build Windows échoue quand le web réussit — correctif
  identifié, non fait, voir [ADR-080](../_adr/ADR-080-site-vitrine-pilote-par-la-donnee-et-jointure-decl.md).

## 3 dernières livraisons

1. **Le dossier du programme — brainstorm v3, revue, simulation, méthode par vagues**
   (2026-09-22 → 2026-10-01, directement sur `main`, depuis `3cd743f` — les deux dernières passes
   de revue entrent par le commit qui suit `25c36ba` —, **documentation et outillage seulement**)
   — **le programme a désormais une conception entière et un déroulé.** Le
   brainstorm v3 remplace celui du 05/08 : ses décisions acquises, D1 à D75, refondent l'économie
   de deck — la fusion devient le moteur de progression et donne la rune, le feu de camp affûte, une
   carte se trouve après chaque combat, les signatures quittent le deck pour devenir des
   compétences de classe, chaque passif reçoit son lot de cartes. Sa
   [revue](../../docs/possible_upgrades/29-09-2026_revue_brainstorm_v3_heros_et_cartes_Fable5.md)
   l'a vérifié contre le code puis relu quatre fois après chaque vague de décisions ; la quatrième
   passe n'a trouvé aucune contradiction, et ses deux constats de fond sont venus de la lecture des
   chemins de code, pas du document. **Un outil entre dans le dépôt** :
   `tool/simulations/d26_economy_sim.dart`, qui a mesuré les valeurs d'économie retenues et
   contredit six prémisses du brainstorm — dont celle d'un deck qui gonfle : la fusion en est le
   puits ([rapport](../../docs/possible_upgrades/30-09-2026_simulation_D26_economie_Fable5.md),
   [`_patterns/20-00`](../_patterns/20-00-simulation-de-l-economie-de-deck.md)). **La ROADMAP est
   redécoupée** : P-43 « Économie unifiée » passe premier, P-42 devient le catalogue par lots de
   passif, P-44 compte quatre lots dont le premier se livre avec P-42 ; P-18 perd ses deux derniers
   points, P-16 hérite de cinq constats de la simulation. **Trois fiches de règles rattrapent le
   code** au passage — `might` au lieu de `strength`, `eco` qui rend du mana à la pose, une boucle
   qui ne promet plus de carte après un combat normal. **Aucun effet joueur, aucune note de
   version.** **Une cinquième passe, le même jour, a relu le fichier d'orchestration lui-même**
   avant de lancer la première vague : le fond tenait, le mode d'emploi a été corrigé. **Une
   sixième a rejoué le fichier corrigé** — la porte d'entrée de la vague 1 passe, la simulation
   relancée rend sa référence à l'identique — et trouvé une prémisse que le code dément : le
   plafond de niveau d'une rune ne tient pas par la seule fusion de cartes, il se pose aux quatre
   endroits qui écrivent un niveau.
   **1187 tests**, inchangés, `dart analyze` propre (**vérifié le 2026-10-01**) —
   [ADR-102](../_adr/ADR-102-chantier-par-vagues-une-version-par-vague.md),
   [ADR-103](../_adr/ADR-103-vagues-fusion-puis-tag-reference-de-simulation-suivi.md).
2. **Le filtre de classe sur les pools d'offre — un prédicat, deux appels, un piège gardé**
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
3. **P-41 lot D, partie 2 — la console rattrape l'identité de classe** (2026-09-20, **fusionné
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
> [!NOTE]
> **Rotations.** Sortie le 2026-10-01, dans `../_archive/` : `2026-10-01-activeContext-livraisons.md`
> (P-41 lot D partie 1). Sortie le 2026-09-21 : `2026-09-21-activeContext-livraisons.md`
> (P-41 lot C partie 2). Sorties le 2026-09-20 : `2026-09-20-activeContext-livraisons-3.md`
> (P-41 lot C partie 1), `2026-09-20-activeContext-livraisons-2.md` (lot B partie 2) et
> `2026-09-20-activeContext-livraisons.md` (lot B partie 1, avec quatre réserves closes). Sorties
> le 2026-09-18 : `2026-09-18-activeContext-livraisons-2.md` (P-49) et
> `2026-09-18-activeContext-livraisons.md` (P-41 lot A). Les onze rotations précédentes portent le
> même nom, daté du 2026-09-17 au 2026-08-20.

## Prochaine étape

**La vague 1 du fichier d'orchestration** : les deux premiers lots de P-43 — les garde-fous de
Puissance, puis le moteur de runes en donnée, sans changement de boucle. Elle se lance dans une
session neuve, par le prompt unique de son §0. **Sa porte d'entrée n'attend aucun tag** : la
vague 0 — la méthode et la ROADMAP — est faite. La porte exige en revanche un arbre propre, un
`main` poussé et le run CI de son commit de tête vert. À la
sortie de la vague, c'est le propriétaire qui teste, ouvre la PR, fusionne et pose le tag ; la
vague 2 n'ouvre qu'une fois la CI/CD verte.

Une question reste tenue dans `docs/ROADMAP.md` §4, hors programme : la **Maîtrise dans l'onglet
Héros du menu de debug**, laissée hors du lot D partie 2 de P-41 alors qu'elle pilote tout P-49.

Le Jalon 2 « Feel & contenu » (`docs/ROADMAP.md` §9) reste ouvert : P-06, P-07, le prototype de
P-08, P-05 — dont dépendent les lots 2 à 4 de P-44, après le programme. **P-07 doit lire
[ADR-083](../_adr/ADR-083-latence-et-synchronisation-du-chemin-de-lecture.md) D6 avant de toucher
aux animations.**
