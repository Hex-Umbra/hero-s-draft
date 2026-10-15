# Vague 4 — `0.5.6` — E4, les signatures en compétences de classe — compte rendu

**Branche** : `feat/v0.5.6-p43-e4-signatures` · **Spec** : [E4](../specs/2026-10-15-p43-e4-signatures-design.md) ([vérifications](../specs/2026-10-15-p43-e4-signatures-design-verifications.md)) · **Plans** : [partie 1](../plans/2026-10-15-p43-e4-signatures-partie-1.md) ([vérifications](../plans/2026-10-15-p43-e4-signatures-partie-1-verifications.md)) · **Forme** : [README](README.md) — essai mesuré d'ADR-108 (D8).

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

**Décisions de SDD — partie 1** (registre de SDD, recopiées avant sa suppression) :

| # | Décision | Classe | Coût si fausse |
|:---|:---|:---:|:---|
| S1 | Le commentaire-sentinelle de `real_bundle_load_test.dart` qui citait `classes/<classe>/cards/` réécrit en Task 6 : périmé, la vague 5 range ses cartes sous `cards/<lot>/` | T | Une ligne de commentaire |
| S2 | Le vocabulaire d'une signature lu sur ses seuls fichiers (Task 5) — **renversée par S3** | T | — |
| S3 | Le vocabulaire d'une signature est l'union des fichiers de carte et de signature : la spec §8, « même vocabulaire que la carte », prime sur le plan | T | Un vocabulaire un peu plus large dans un éditeur de debug |
| S4 | `playSignature` ne vérifie pas que `enemyId` est un ennemi présent, comme le chemin d'une carte (spec §4.3) ; reporté au Review Focus du plan de la partie 2 | T | Un id inconnu venu d'une interface fautive paierait le mana et poserait la recharge pour rien |
| S5 | Les libellés « globales » (ARB `draftDeckSubtitle`, doc du widget du tutoriel, locale `globalCards`) attendent la partie 2, avec le bandeau : la spec §6 fige les textes de l'écran en partie 1 | T | Un mot périmé pendant une partie |
| S6 | Revue de la Task 5, constat important : une carte neutre portant un `heroClass` passait le validateur et s'inscrivait dans `skills` — corrigé aux deux bouts (validateur, écrivain), deux tests | T | — |

## 3. Les tests manuels

*Fichier voisin, écrit en fin de vague.*

## 4. Trouvé périmé, et pour la file

*À écrire en fin de vague.*

## 5. Les leçons

*À écrire en fin de vague.*

## 6. Les statistiques de la session

*Mesurées juste avant le commit de §3.8.*
