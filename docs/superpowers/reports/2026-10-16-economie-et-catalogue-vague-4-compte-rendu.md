# Vague 4 — `0.5.6` — E4, les signatures en compétences de classe — compte rendu

**Branche** : `feat/v0.5.6-p43-e4-signatures` · **Spec** : [E4](../specs/2026-10-15-p43-e4-signatures-design.md) ([vérifications](../specs/2026-10-15-p43-e4-signatures-design-verifications.md)) · **Plans** : [partie 1](../plans/2026-10-15-p43-e4-signatures-partie-1.md) ([vérifications](../plans/2026-10-15-p43-e4-signatures-partie-1-verifications.md)) · [partie 2](../plans/2026-10-16-p43-e4-signatures-partie-2.md) ([vérifications](../plans/2026-10-16-p43-e4-signatures-partie-2-verifications.md)) · **Forme** : [README](README.md) — essai mesuré d'ADR-108 (D8).

## 0. Pour le propriétaire

**À tester d'abord**, par risque — [tests manuels](2026-10-16-economie-et-catalogue-vague-4-tests-manuels.md), 21 tests :
1. **T1 à T3, le jeu à l'écran de combat** : aucun test automatique ne monte cet écran. Châtiment armé frappe l'ennemi touché, jamais celui qu'une carte avait sélectionné ; chaque geste désarme ; le héros qui meurt souris sur une tuile laisse les boutons de l'écran de mort cliquables (S8).
2. **T4, T5, passifs et reliques** : une signature compte comme une carte de son type ; *Marque du Mage* ne se déclenche plus sur Projectile Magique.
3. **T6, T7, T16, la barre** : au-dessus du panneau des statuts même avec beaucoup de statuts (S11), immobile quand on arme (S10), le compte sur une ligne (S9). Mesuré sous Windows (Segoe UI) par la revue d'ensemble, pas sur mobile.
4. **T8, la reprise d'une run** : les signatures reviennent de la classe, la sauvegarde ne les porte pas.

**Arbitrages que le joueur verra** — tes réponses P : recharge de 2 tours aux coûts d'aujourd'hui, l'épuisement disparaît, Q-P1 (a), Q-P2 (a), P-2 (b). **À juger au test**, délégués :
- **A6, la forme de la barre** : à gauche, à mi-hauteur, tuiles de 76 px (64 sous 600 px), cinq états, toucher la signature puis l'ennemi ; les détails que la spec ne fixait pas (couleurs, opacité, polices) choisis à l'implémentation (S7) — **sauf le fond, que tu as tranché le 16/10 : neutre et sans liseré pour toutes les tuiles (O1), et sur toute la largeur de la carte de classe (O2)** ;
- **PM19, le compte de recharge** : « 2 tours » d'un bloc, centré — **dans une bande à lui, réduit à la taille, et le nom coupé d'un « … » sur une ligne tant que le compte s'affiche** (S9, revue d'ensemble) ; le nom entier reste dans l'infobulle ;
- l'invite « Choisissez une cible » pend sous la colonne des tuiles (S10).

**Faits sans toi** (autonomie `continu`) : une fois, à la spec (15/10) — après trois tours, les deux corrections recommandées du troisième appliquées telles quelles, puis un tour différentiel « prête » : (1) cinq tests qui lisaient une carte `unique` exclue des copies ou de la trouvaille, retirés ou réécrits ; (2) sept tests dont l'assertion portait sur `unique` — trois retirés avec leur objet, trois réécrits sur une commune, un disparu avec `category` ([vérifications de la spec](../specs/2026-10-15-p43-e4-signatures-design-verifications.md), tours 3 et 4). Les plans ont convergé en trois tours : rien d'autre.

**Risques connus** : la glue de l'écran de combat n'a que la revue de code et ton test ; la mise en page n'est mesurée ni sur Android ni sur iOS ; l'ennemi visé par la dernière carte garde sa bordure ambre pendant qu'une signature est armée (S12) ; le sous-titre du draft dit encore « 5 cartes globales » (§4).

**Trois commandes** : `flutter test` (1697) · `flutter test test/widget/signature_bar_test.dart test/unit/heros_draft_game_targeting_test.dart` (le HUD et le ciblage) · `flutter run -d windows`.

## 1. La branche et ses chiffres

| Version | Commits | Tests | `dart analyze` | Code (`lib/`, `test/`, `assets/`) | Superpowers | Claude Code |
|:---|---:|:---|:---|:---|:---|:---|
| `0.5.6` | 31 (`848645b..`) | 1625 → 1663 → 1694 → **1697** | `No issues found!` | 120 fichiers, +4132 / −1538 | 7.0.0, `bb92a77` | 2.1.300 (15-16/10), 2.1.301 (16/10, mise à jour seule) |

## 2. Les arbitrages

Une ligne chacun ; les options écartées sont dans les fichiers de vérifications.

| # | Question | Classe | Choix | Filtre |
|:---|:---|:---:|:---|:---:|
| §1.2 | Coût et recharge des six signatures | P | Recharge 2 pour les six, aux coûts d'aujourd'hui (propriétaire, prompt de lancement) | — |
| §1.2 | L'épuisement de Bouclier Sacré et Surtension de Mana | P | Il disparaît (propriétaire) | — |
| §1.2 | Une signature déclenche-t-elle les passifs de son type ? | P | Oui ; *Marque du Mage* ne se déclenche plus sur Projectile Magique (propriétaire) | — |
| Q-P1 | Les quatre reliques « carte jouée » voient-elles une signature ? | P | Oui, par le même événement que les passifs (propriétaire, 15/10) | — |
| Q-P2 | Le tutoriel enseigne-t-il la barre par un geste ? | P | La prose seule (propriétaire, 15/10) | — |
| A1 | Le modèle | T | `SignatureData` propre, joué par une vue de carte | 1 |
| A2 | `CardCategory` | T | L'enum, le champ et l'injection disparaissent | 5 |
| A3 | Les noms | T | `Signature…` ; l'interdit d'ADR-084 n'est pas levé | 1 |
| A4 | L'éditeur de contenu | T | Neuvième catégorie `signature` | 5 |
| A5 | Le découpage | T | Draft de départ, lectures du tutoriel et éditeur en partie 1 | 7 |
| A6 | La barre au HUD (déléguée par le propriétaire) | T | À gauche, à mi-hauteur ; cinq états ; toucher la signature puis l'ennemi | 6, 5 |
| A7 | La forme de la recharge | T | `readyOn = tour + recharge`, dérivé de `turnCount` | 8 |
| A8 | Où vit la liste des signatures de la run | T | `RunState.signatures`, relue de la classe, jamais sérialisée | 5 |
| A9 | Le filtre du draft de départ | T | Le prédicat d'offre unique | 5 |
| A10 | `CardData.heroClass` | T | Retiré ; `heroClass` et `category` refusés nommés dans une carte | 5 |
| A11 | Champs de carte dans un fichier de signature | T | `rarity`, `isExhaust`, `category` refusés | 5 |
| A12 | Le test de transition E3 → E4 | T | Retiré ; test d'intégrité « ids disjoints » | 5 |
| A13 | Le prédicat d'offre | T | `CardData.isOfferable`, sans paramètre | 5 |
| PL1 | Un id de `skills` absent du registre à la reprise | T | Fail-fast, la sauvegarde est effacée | 5 |
| PL2 | Une signature neuve sans propriétaire (éditeur) | T | Faute d'identité nommée `heroClass` | 5 |
| PL3 | Prose de `SignatureData` | T | Les quatre clés exigées, non vides | 5 |
| PL4 | Vocabulaire du type d'une signature | T | `SignatureData.playableTypes`, source unique | 5 |
| PL5 | Répertoire du descripteur de signature | T | `skills`, catalogue `classes/*/skills/` | 5 |
| PL6 | « La signature est dans la run » | T | Comparée par id | 1 |
| PL7 | Nom dans la recette de classe | T | `ClassRecipe.signatures` | 1 |
| PL8 | Régression `smite` du tutoriel | T | Reformulée sur une attaque à Armure synthétique | 5, 7 |
| PL9 | Quand écrire `CLAUDE.md:89` | T | Avec la purge de `heroClass` (Task 7) | 5 |
| PL10 | Découpage de l'éditeur | T | Une ligne au déplacement, la catégorie en Task 5 | 8 |
| V1 | `SignatureData.getDescription` sans lecteur en partie 1 (plan, tour 1) | T | Reporté à la partie 2 | 5 |
| P-2 | La tuile « détaillée » du dictionnaire | P | Onglet « Signatures » ; nom, coût, recharge, description, et le type (propriétaire, 16/10) | — |
| PM1 | Où vit la priorité des cinq états | T | Fonction pure `signatureTileStateOf` | 5 |
| PM2 | Comment la barre rend ses gestes | T | `onPlay`, `onArm`, `onDisarm`, `onInsufficientMana`, la paire de l'infobulle | 5 |
| PM3 | Qui joue le son « mana insuffisant » | T | L'écran, sur le rappel | 5 |
| PM4 | Où vit la secousse | T | Un widget de tuile privé, à état | 1 |
| PM5 | La forme d'`awaitingEnemyTarget` | T | Accesseur et mutateur ; `false` éteint l'illumination sans rappel | 6, 8 |
| PM6 | Où Flame détecte l'annulation | T | `setFocusedCard` et le toucher du décor | 8 |
| PM7 | Un ennemi mort ou mourant touché pendant l'attente | T | Flame l'ignore, l'attente demeure | 5 |
| PM8 | L'illumination au survol | T | `onPointerMove` du jeu | 8 |
| PM9 | `onSelectEnemy` dans l'écran | T | Ne joue que la signature armée | 5 |
| PM10 | L'ordre dans `_playSignature` | T | `playSignature` d'abord ; animation et son s'il rend `true` | 5 |
| PM11 | La condition d'activité de la barre | T | Celle de `canEndTurn`, plus le combat fini | 7 |
| PM12 | Une autre tuile touchée pendant qu'une signature est armée | T | Jouer désarme d'abord ; armer remplace | 1 |
| PM13 | Une classe sans signature | T | Ni bloc ni en-tête | 8 |
| PM14 | Le bandeau du tutoriel | T | Texte en ligne, sans clé ARB | 5 |
| PM15 | Quand ajouter chaque clé ARB | T | Chacune avec son premier lecteur | 5 |
| PM16 | La couleur de classe en combat | T | `firstWhere` sans repli | 5 |
| PM17 | Tester le ciblage Flame | T | Un test du jeu non monté | 8 |
| PM18 | Le nom de la locale du draft | T | `offerableCards` | 5 |
| PM19 | La forme du compte de recharge (signalée P, reclassée T : A6) | T | `signatureTurnsLeft(n)` d'un bloc, centré, en grand | A6 |

**Décisions de SDD — partie 1** (registre de SDD, recopiées avant sa suppression) :

| # | Décision | Classe | Coût si fausse |
|:---|:---|:---:|:---|
| S1 | Le commentaire-sentinelle de `real_bundle_load_test.dart` qui citait `classes/<classe>/cards/` réécrit en Task 6 : périmé, la vague 5 range ses cartes sous `cards/<lot>/` | T | Une ligne de commentaire |
| S2 | Le vocabulaire d'une signature lu sur ses seuls fichiers (Task 5) — **renversée par S3** | T | — |
| S3 | Le vocabulaire d'une signature est l'union des fichiers de carte et de signature : la spec §8, « même vocabulaire que la carte », prime sur le plan | T | Un vocabulaire un peu plus large dans un éditeur de debug |
| S4 | `playSignature` ne vérifie pas que `enemyId` est un ennemi présent, comme le chemin d'une carte (spec §4.3) ; reporté au Review Focus du plan de la partie 2 | T | Un id inconnu venu d'une interface fautive paierait le mana et poserait la recharge pour rien |
| S5 | Les libellés « globales » (ARB `draftDeckSubtitle`, doc du widget du tutoriel, locale `globalCards`) attendent la partie 2, avec le bandeau : la spec §6 fige les textes de l'écran en partie 1 | T | Un mot périmé pendant une partie |
| S6 | Revue de la Task 5, constat important : une carte neutre portant un `heroClass` passait le validateur et s'inscrivait dans `skills` — corrigé aux deux bouts (validateur, écrivain), deux tests | T | — |

**Décisions de SDD — partie 2** (registre de SDD, recopiées avant sa suppression ; revue d'ensemble sur `bb4a020..3b5fd85`, « avec corrections », un seul passage de correction, `e434d0d`) :

| # | Décision | Classe | Coût si fausse |
|:---|:---|:---:|:---|
| S7 | Les détails visuels que la spec ne fixe pas (fond en recharge, opacité 0,45 de l'état inactif, polices, 4 px entre tuiles) choisis par l'implémenteur, sous la délégation A6 | T | Une retouche visuelle au test |
| S8 | L'infobulle d'une signature survivait à la mort du héros et couvrait les boutons de l'écran de mort : masquée quand le héros est mort | T | Une condition |
| S9 | Le compte de recharge débordait (64 px) et chevauchait le nom (76 px) : bande à lui, une ligne réduite à la taille ; **le nom passe sur une ligne, avec « … », tant que le compte s'affiche** | T | Le propriétaire rejuge la forme au test |
| S10 | L'invite « Choisissez une cible » faisait sauter les tuiles de 16 px : posée sous la colonne sans la déplacer | T | Une retouche de mise en page |
| S11 | La barre était peinte sous le panneau des statuts, qui prenait les touchers de la tuile basse : posée au-dessus, sous l'infobulle | T | Une ligne déplacée |
| S12 | L'ennemi visé par la dernière carte garde sa bordure ambre pendant qu'une signature est armée, la même que l'illumination du survol : à la file (vocabulaire visuel existant ; les dégâts vont à l'ennemi touché) | T | Sur écran tactile, le joueur peut croire que la signature frappera l'ennemi ambre |
| O1 | **Tranché par le propriétaire, 16/10, à son test** : une tuile sur deux rouge à la sélection de classe — toutes les tuiles de signature (carte de classe, dictionnaire, barre) prennent un fond neutre, le même quel que soit le type, et perdent le liseré du type ; spec §5.1 amendée ; `7ed2422`, revue approuvée, +2 tests | P | — |
| O2 | **Tranché par le propriétaire, 16/10** : les tuiles de signature de la carte de classe occupent toute sa largeur (le dictionnaire ne change pas) ; `f419d7e`, revue approuvée, +1 test | P | — |

## 3. Les tests manuels

[`2026-10-16-economie-et-catalogue-vague-4-tests-manuels.md`](2026-10-16-economie-et-catalogue-vague-4-tests-manuels.md) — 21 tests, à remplir par le propriétaire.

## 4. Trouvé périmé, et pour la file

- **La simulation ne tourne plus** : elle lit `classes/*/cards/`, que la vague a renommé (`tool/simulations/d26_economy_sim.dart:866`) ; `dart analyze` propre — accepté par ADR-108 D5.
- **Texte joueur périmé** : le sous-titre du draft de départ dit « 5 cartes globales » (`draftDeckSubtitle`, `lib/l10n/app_fr.arb:224`) ; la spec §6 a figé les textes de l'écran cette vague.
- **L'écran de combat sans banc de test** : la glue des signatures (S8 compris) n'a aucun garde automatique.
- **La bordure ambre** partagée par la sélection et l'illumination du survol (S12).
- **`SignatureData`** : un type JSON faux rend une `TypeError`, pas une `FormatException` ; une cible inconnue retombe sans bruit sur `singleEnemy` (comme `CardData`).
- **L'éditeur de contenu** nomme encore « carte » ses champs de signature (`cardCount`, `cardIds`, `cardNameFr`…).
- **Tests faibles** : `onLongPressCancel` et l'illumination au survol sans test ; le test de bordure de `SignatureTile` lit n'importe quel `Container` ; des fixtures du dictionnaire aux noms trompeurs ; un aller-retour de `card_offer_filter_test` compare deux listes vides.
- **Polissage** : couleurs en dur dans `SignatureTile`, aucune `Semantics` sur les tuiles, des imports hors d'ordre, des lignes de plus de 80 colonnes.

## 5. Les leçons

1. **Les plans de décisions tiennent leur promesse** : 0,32 milliard de jetons et 123 $ contre 1,31 milliard et 389 $ en vague 3 ; la spec et les plans font 49 % du coût, contre 73 à 76 %. Amendement : rien, garder D1.
2. **Un mineur visible du joueur est sous-classé par la revue de tâche** : trois défauts de mise en page (S9 à S11) notés « mineurs » en Tasks 2 et 4 ne sont remontés qu'à la revue d'ensemble, qui les a mesurés. Amendement : à chaque tâche d'interface, l'orchestrateur trie ses mineurs visibles du joueur avant la suivante.
3. **Deux arrêts pour trois questions P nées à l'écriture**, dont P-2 sur un écran neuf. Amendement : la fiche d'une vague qui crée des écrans pose au propriétaire, avant la vague, le contenu de chacun.
4. **Une tâche de vérification pure n'a pas besoin d'agent** : la Task 7 (des commandes, aucun fichier) jouée par l'orchestrateur. Amendement : le gabarit de plan la marque « orchestrateur ».
5. **La glue de l'écran de combat reste sans filet automatique**. Amendement : rien pour la méthode ; un banc de test de l'écran de combat est à porter à la file de la ROADMAP.

## 6. Les statistiques de la session

**Mesuré le 16/10/2026 à 13:19**, après les corrections O1 et O2 (comptées en fin de vague) — sessions : 3 (`45afce4c`, arrêtée en 3.3 ; `1f50c59f`, arrêtée en 3.4 ; `f62aaed4`) · arrêts : 2 · durée : du 15/10 à 09:38 au 16/10 à 13:19, dont 10 h 09 de temps actif cumulé · tours de spec : 4 · tours de plan : 6 (3 + 3)
Prix lus le 16/10 sur https://platform.claude.com/docs/en/about-claude/pricing · 1 € = 1,1208 $ (BCE, 15/10) · suppléments : aucun (`server_tool_use`, `speed`, `inference_geo` vérifiés)

| | Spec | Plans | Implémentation | Fin de vague | Orchestrateur(s) | **Total** |
|:---|---:|---:|---:|---:|---:|---:|
| Temps actif | 1 h 18 | 2 h 13 | 1 h 57 | 28 min | 4 h 13 | **10 h 09** |
| Agents — Opus / Sonnet | 5 / 0 | 8 / 0 | 9 / 24 | 1 / 6 | 3 / 0 | **26 / 30** |
| Appels au modèle | 316 | 477 | 473 | 164 | 297 | **1 727** |
| Jetons traités, dont hors cache | 65,7 M · 2,49 M | 94,4 M · 2,76 M | 54,3 M · 2,82 M | 31,2 M · 0,81 M | 75,7 M · 1,57 M | **321,3 M · 10,46 M** |
| Sortie (minimum) | 24 k | 96 k | 142 k | 33 k | 288 k | **583 k** |
| Coût API — $ / € | 25,59 / 22,83 | 34,04 / 30,37 | 21,08 / 18,80 | 9,07 / 8,09 | 33,12 / 29,55 | **122,89 / 109,64** |
