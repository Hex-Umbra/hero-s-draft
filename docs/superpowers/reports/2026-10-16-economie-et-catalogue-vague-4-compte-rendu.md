# Vague 4 — `0.5.6` — E4, les signatures en compétences de classe — compte rendu

**Branche** : `feat/v0.5.6-p43-e4-signatures` · **Spec** : [E4](../specs/2026-10-15-p43-e4-signatures-design.md) ([vérifications](../specs/2026-10-15-p43-e4-signatures-design-verifications.md)) · **Plans** : [partie 1](../plans/2026-10-15-p43-e4-signatures-partie-1.md) ([vérifications](../plans/2026-10-15-p43-e4-signatures-partie-1-verifications.md)) · [partie 2](../plans/2026-10-16-p43-e4-signatures-partie-2.md) ([vérifications](../plans/2026-10-16-p43-e4-signatures-partie-2-verifications.md)) · **Forme** : [README](README.md) — essai mesuré d'ADR-108 (D8).

## 0. Pour le propriétaire

*À écrire en fin de vague (§3.8).*

## 1. La branche et ses chiffres

*À écrire en fin de vague.*

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

## 3. Les tests manuels

*Fichier voisin, écrit en fin de vague.*

## 4. Trouvé périmé, et pour la file

*À écrire en fin de vague.*

## 5. Les leçons

*À écrire en fin de vague.*

## 6. Les statistiques de la session

*Mesurées juste avant le commit de §3.8.*
