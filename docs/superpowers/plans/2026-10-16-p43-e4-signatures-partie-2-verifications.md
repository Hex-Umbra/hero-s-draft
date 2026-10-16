# Vérifications — plan E4 partie 2

**Plan** : [`2026-10-16-p43-e4-signatures-partie-2.md`](2026-10-16-p43-e4-signatures-partie-2.md) · **Spec** : [`2026-10-15-p43-e4-signatures-design.md`](../specs/2026-10-15-p43-e4-signatures-design.md), §11 partie 2 · **Vague** : 4, `0.5.6`, branche `feat/v0.5.6-p43-e4-signatures` · **Autonomie** : `continu` · **Base de tests** : 1663 · **Tâches à risque** : aucune.
Tenu par l'orchestrateur (ADR-108 D4) : les options que le plan a écartées, puis le journal des tours.

## Les options écartées

Questions de classe T nées à l'écriture du plan, tranchées par le rédacteur, confirmées par l'orchestrateur.

| # | Question | Options écartées, et le filtre qui les écarte | Retenu |
|:---:|:---|:---|:---|
| PM1 | Où vit la priorité des cinq états | Dans les tuiles privées · dans un provider — l'état d'animation de Flame n'entre pas dans Riverpod (filtre 5) | Fonction pure `signatureTileStateOf` |
| PM2 | Comment la barre rend ses gestes | Un seul `onTap`, l'écran décidant selon la cible (filtre 5) | `onPlay`, `onArm`, `onDisarm`, `onInsufficientMana`, et la paire de l'infobulle |
| PM3 | Qui joue le son « mana insuffisant » | La barre lisant le provider audio (filtre 5) | L'écran, sur le rappel |
| PM4 | Où vit la secousse | Une barre à état, contraire à la spec (filtre 1) | Un widget de tuile privé, à état |
| PM5 | La forme d'`awaitingEnemyTarget` | Un champ nu · un mutateur qui rappelle l'écran (filtres 6 puis 8) | Accesseur et mutateur ; `false` éteint l'illumination sans rappel |
| PM6 | Où Flame détecte l'annulation | Deux sites dans `CardInteractionHandler` (filtre 8) | `setFocusedCard` (carte non nulle) et le toucher du décor dans `onTapDown` |
| PM7 | Un ennemi mort ou mourant touché pendant l'attente | Le contrôle dans `playSignature` (écarté en partie 1, S4) · dans l'écran (filtre 5) | Flame l'ignore et garde l'attente |
| PM8 | L'illumination au survol | `HoverCallbacks` sur `EnemyCard` (filtre 8) | `onPointerMove` du jeu |
| PM9 | `onSelectEnemy` dans l'écran | Garder `selectEnemy` quand rien n'est armé, un chemin que Flame n'appelle jamais (filtre 5) | Ne joue que la signature armée |
| PM10 | L'ordre dans `_playSignature` | Doubler `canPlayCard` dans l'écran (filtre 5) | `playSignature` d'abord ; animation et son s'il rend `true` |
| PM11 | La condition d'activité de la barre | Modifier `canEndTurn` (filtre 7) | Celle de `canEndTurn`, plus le combat fini pour la barre seule |
| PM12 | Une autre tuile touchée pendant qu'une signature est armée | La laisser armée (filtre 1, un seul geste à la fois, §5.3) | Jouer désarme d'abord ; armer remplace |
| PM13 | Une classe sans signature | Un titre vide (filtre 8) | Ni bloc ni en-tête |
| PM14 | Le bandeau du tutoriel | Une cinquième clé ARB (filtre 5) | Texte en ligne, comme le reste du widget |
| PM15 | Quand ajouter chaque clé ARB | Les quatre en Task 1 (filtre 5, pas de code sans lecteur) | Chacune avec son premier lecteur |
| PM16 | La couleur de classe en combat | Une couleur de repli (filtre 5) | `firstWhere` sans repli |
| PM17 | Tester le ciblage Flame | Le test manuel seul (filtre 8) | Un test du jeu non monté |
| PM18 | Le nom de la locale du draft | Garder `globalCards` (filtre 5) | `offerableCards` |
| PM19 | La forme du compte de recharge sur une tuile (signalée P-1 par le rédacteur ; **reclassée T par l'orchestrateur** : la forme de la barre est déléguée, A6) | (a) le nombre seul et une cinquième clé pour le mot · (c) couper la chaîne traduite après le nombre (filtre 5 : une clé de plus, ou une chaîne traduite découpée) | (b) `signatureTurnsLeft(n)` d'un bloc, centré et en grand |

**Question P née à l'écriture, ouverte** — le plan se termine et se vérifie autour d'elle (ADR-108 D3) :

| # | Question | Options | Recommandation |
|:---:|:---|:---|:---|
| P-2 | La tuile « détaillée » du dictionnaire (spec §6) : qu'ajoute-t-elle à la compacte (nom, coût, recharge, description) ? | (a) le même contenu en plus grand · (b) en plus, le libellé du type (Attaque / Compétence, clés ARB existantes) · (c) le type et la cible | (b) — le type dit quels passifs et quelles reliques la signature déclenche (Q-P1), sans texte neuf |

## Le journal des tours

| Tour | Mode | Vérificateur | Bloquants | Moyens | Mineurs | Rédaction | Corrigé | Contesté, tranché |
|:---:|:---|:---|---:|---:|---:|---:|:---|:---|
| 1 | complet, test de la Task 3 esquissé dans un clone | neuf, seul | 1 | 1 | 5 | 3 | Le test de `HerosDraftGame` non monté se construit et passe (7 tests) ; hypothèses de Flame 1.38.2 confirmées ; textes FR/EN identiques à la spec (comparaison scriptée) ; décompte juste. Le bloquant — le grep « vide » de la Task 6 sur `test/` vise des littéraux que les tests neufs écrivent ; le moyen — l'infobulle ouverte par appui long ne se ferme jamais sur mobile ; cinq mineurs et trois rédactions — par le rédacteur repris | **Tranché par l'orchestrateur, mineur n° 5** (T, filtre 8) : un membre créé par une tâche reçoit son lecteur dans `lib/` à une tâche nommée du même plan, contrôlé en Task 7 ; écarté : fusionner chaque widget avec son premier lecteur (des tâches deux fois plus grosses). Diffère de V1 (partie 1), où aucun lecteur n'existait dans toute la partie |
| 2 | différentiel | neuf, seul | 0 | 1 | 2 | 1 | Sept des dix corrections du tour 1 jugées justes, sondées dans le clone (l'appui long rend deux `onHideTooltip` ; la clé sous la translation bouge de 4 px). Le moyen — le test de la secousse, écrit à la lettre, lit la tuile au repos (un `pump()` initial manque) ; deux mineurs — un défaut de paramètre non constant, un grep de contrôle qui répond par homonymie avec `CombatState.signatureTurnsLeft` ; une rédaction — par le rédacteur repris | — |
| 3 | différentiel | neuf, seul | 0 | 0 | 2 | 1 | **Prêt.** Les quatre corrections du tour 2 tiennent, sondées dans le clone (la secousse lue après `pump()` puis 25 ms ; `dart analyze` propre avec le registre facultatif ; le grep filtré ne garde que la clé ARB). Les deux mineurs (la parenthèse sur les six `getDescription(` existants ; « au moins une ligne ») et la rédaction (un seul toucher) corrigés au passage par l'orchestrateur | — |
