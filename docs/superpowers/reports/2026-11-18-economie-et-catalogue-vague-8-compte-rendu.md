# Vague 8 — `0.6.0` — la tranche 3 de P-42 : Sanctifié, Carnage, Marque — compte rendu

**Branche** : `feat/v0.6.0-p42-tranche-3` · **Spec** : [tranche 3](../specs/2026-11-18-p42-tranche-3-design.md) ([vérifications](../specs/2026-11-18-p42-tranche-3-design-verifications.md)) · **Plan** : [tranche 3](../plans/2026-11-18-p42-tranche-3.md) ([vérifications](../plans/2026-11-18-p42-tranche-3-verifications.md))

*Ouvert à la fin du plan (§3.5), fermé à la §3.8.*

## 0. Pour le propriétaire

*À écrire à la §3.8.*

## 1. La branche et ses chiffres

| Plan | Commits de code | Tests | `dart analyze` | Superpowers | Claude Code |
|:---|:---|:---|:---|:---|:---|
| Tranche 3 | 7 (`9a0f6c3d..a65bf4c7`, après le plan `0e704f7e`) | 1776 → **1826** | `No issues found!` | 7.0.0, `bb92a77` | 2.1.319 |

## 2. Les arbitrages

Une ligne chacun ; les options écartées sont dans les fichiers de vérifications de la [spec](../specs/2026-11-18-p42-tranche-3-design-verifications.md) et du [plan](../plans/2026-11-18-p42-tranche-3-verifications.md).

| # | Question | Classe | Choix | Filtre |
|:---|:---|:---:|:---|:---:|
| Q12 | Les élémentaires restent-elles des Attaques | P | Oui : elles changent de dossier, pas de type (propriétaire, 18/11) | — |
| D43 | La variante « armure conservée » pour Sanctifié | P | Non : aucune carte ni mécanisme d'armure conservée (propriétaire, 18/11) | — |
| Q11 | Le double bonus de Puissance | P | Close en vague 5 : un seul bonus par carte, la règle s'applique au lot Marque | — |
| A3 | La carte de dégâts de groupe jouée la première | P | (c) : elle ne marque ni ne consomme ; la première carte à cible unique marque ; *Nova* de même (propriétaire, 18/11) | — |
| A4 | La carte à cible unique qui tue sa cible | P | (ii) : elle ne compte pas, la carte de dégâts suivante marque ; texte « … qui vise un seul ennemi sans le tuer … » (propriétaire, 18/11) | — |
| A1-A2 | Le déclencheur de D34 ; ce qu'est une carte de dégâts | T | `RelicTrigger.onDamagingCardPlayed`, envoyé après le déclencheur du type ; `EffectiveCard.dealsDamage`, effets ajoutés compris | 1, 4, 5, 7 |
| A5-A7 | Les reliques et le libellé ; `hp_regen` ; son icône | T | Pas de relique, une clé ARB ; modèle de `mana_regen`, symétrique, borné, jamais à 0 PV ; le cœur rose du soin | 4, 5, 6, 7, 8 |
| A8-A10 | *Exécution* et *Exploitation* ; le nom du statut en anglais | T | Les sources livrées `targetMissingHp` et `targetStatus`, sans mécanisme neuf ; une clé `statusName` à sélection | 4, 6, 7 |
| A11-A13 | Les `feeds` ; les six déplacements ; le démasquage | T | *Frénésie* + `damage`, *Bénédiction* + `status:hp_regen` ; `git mv` sans retouche, tutoriel inchangé ; par la donnée (O5) | 1, 5, 7 |
| A14-A16 | Les cartes des trois lots | délégué | Spec §3.2, écarts au brainstorm acceptés (propriétaire, 18/11) : *Exploitation* et *Salve* en Compétences, +1 par tranche ou par point, *Salve* 2 × 3, *Moulinet* et *Coup de grâce* +1 | — |
| A18 | Le découpage | T | Un seul plan | 7 |
| A19 (D-1) | La Faiblesse vieillie avant l'action de son porteur | D → T | Moteur inchangé, durées des cartes allongées d'un tour ; le décalage antérieur va à la file (accepté par le propriétaire, 18/11) | 1, 3 |
| A20 (P-1) | Le nom affiché d'`hp_regen` | P → T | « Source de Vie » / « Life Spring », précédent de la vague 6 (accepté par le propriétaire, 18/11) | 6 |
| D1-D9 | Où tester la signature et `dealsDamage` ; une seule tâche de données ; `scaleStatus` au tuple du catalogue ; la couleur du libellé ; l'ordre du soin ; le registre du tutoriel ; `_statusName` | T | Plan, « Décisions du plan » | 5, 8 |
| D10 | *Prière* reçoit-elle *Résonant* | P → T | Oui : l'exclusion de `mana_regen` vient de D44 (mana et pioche), `hp_regen` n'en est pas ; `heal_potion` la reçoit déjà ; *Persistant* ne s'offre à aucun Pouvoir | 1, 4 |

**Décisions de SDD** (registre recopié avant sa suppression ; balayage préalable, sept tâches, aucune passe de correction par tâche ; revue d'ensemble sur `0e704f7e..fe0891c6`, « prête avec corrections », 0 critique, 0 important, une passe) :

| # | Décision | Classe | Coût si fausse |
|:---|:---|:---:|:---|
| S0 | Balayage préalable : six paires de tâches et sept tâches, sans contradiction ; une règle posée, R1 | T | — |
| S1 | R1 : en Task 6, un fichier de carte ne se corrige que s'il s'écarte de la spec §3.2 ; un test rouge sur un fichier conforme remonte à l'orchestrateur, sans toucher ni donnée ni moteur (aucun n'a rougi) | T | Un aller-retour de plus sur une valeur de test |
| S2 | La Task 7, la vérification finale, rejouée par l'orchestrateur sans implémenteur (aucun fichier) : tout conforme | T | — |
| S3 | Revue d'ensemble, corrigé : deux commentaires faux (le registre de test du tutoriel citait trois tests supprimés par D77 ; *Marque du Mage* « première source de Vulnérable du jeu ») et une métadonnée ARB en trop dans `app_fr.arb` (`a65bf4c7`) | T | — |
| S4 | Laissé de côté : l'accord des noms anglais de `statusName` n'a pas de test — la spec ne demande que le français, et un test de plus déplacerait le total du plan | T | Un nom anglais qui dériverait sans test |
| S5 | Constats mineurs triés par la revue d'ensemble, aucun avant la fusion : un test qui enchaîne deux cartes, *Salve* écrite en formule, l'ennemi pris en tête du registre, pas de test de la Source de Vie après une mort par le Feu (même garde que le Poison) | T | — |

## 3. Les tests manuels

*À écrire à la §3.8.*

## 4. Trouvé périmé, et pour la file

*À écrire à la §3.8.*

## 5. Les leçons

*À écrire à la §3.8.*

## 6. Les statistiques de la session

*Mesurées à la §3.8.*
