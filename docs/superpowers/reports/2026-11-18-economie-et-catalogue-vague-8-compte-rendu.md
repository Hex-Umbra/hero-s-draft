# Vague 8 — `0.6.0` — la tranche 3 de P-42 : Sanctifié, Carnage, Marque — compte rendu

**Branche** : `feat/v0.6.0-p42-tranche-3` · **Spec** : [tranche 3](../specs/2026-11-18-p42-tranche-3-design.md) ([vérifications](../specs/2026-11-18-p42-tranche-3-design-verifications.md)) · **Plan** : [tranche 3](../plans/2026-11-18-p42-tranche-3.md) ([vérifications](../plans/2026-11-18-p42-tranche-3-verifications.md))

*Ouvert à la fin du plan (§3.5), fermé à la §3.8.*

## 0. Pour le propriétaire

**À tester d'abord**, par risque (le détail est au [fichier des tests manuels](2026-11-18-economie-et-catalogue-vague-8-tests-manuels.md)) :

1. ***Marque du Mage*** (T1 à T4) : *Projectile Magique* marque de nouveau, une seconde carte du tour ne remarque pas ; une carte sans dégâts, une carte de groupe et *Nova* ne marquent ni ne consomment ; une carte qui tue sa cible laisse la marque à la suivante.
2. **La Faiblesse de Sanctifié** (T5, T8, T9) : *Sommation* réduit deux attaques, pas la troisième ; *Édit* et *Réprimande* une seule.
3. **La Source de Vie** (T6) : « Source de Vie : +2 », cœur rose, +2 PV au début de trois tours, jamais au-delà du maximum.
4. **Carnage** (T7, T10) : jugez-le à l'acte 2 ou plus — à l'acte 1, un combat ne compte qu'un ennemi ; *Exécution* contre un boss.
5. **Les neuf passifs et le draft** (T11, T12, T18) : trois passifs par classe, 2 cartes du lot et 3 neutres sur un groupe de 9, et les cartes déplacées absentes sous les autres passifs.

**Les arbitrages que le joueur verra** : vos réponses Q12, D43, A3 (c) et A4 (ii), le texte de la Marque ; les cartes et leurs valeurs, écarts au brainstorm compris ; « Source de Vie » ; les durées de Faiblesse allongées d'un tour (A19) ; *Prière* qui reçoit la rune *Résonant* (D10).

**Faits sans vous** (autonomie `continu`) : D10, rendue P par le rédacteur du plan et reclassée T — l'exclusion de la Source de Mana vient de D44, qui ne vise que le mana et la pioche ; *Persistant*, lui, ne s'offre à aucun Pouvoir. Les décisions T de la spec et du plan, et S0 à S5 au §2.

**Risques connus** : les valeurs des seize cartes sont des ordres de grandeur ; Vulnérable s'accumule au-delà du plafond affiché sur l'ennemi (T19) ; le décalage antérieur de la Faiblesse (*Sentence*, T20) et le tour ennemi joué après une victoire (S9 de la vague 7 : *Prière* y soigne d'un tour de trop) restent à la file.

**Rejouer l'essentiel** : `flutter test test/unit/passives_mage_test.dart test/unit/hp_regen_test.dart test/unit/tranche_3_cards_test.dart` · `dart analyze` · `bash .github/scripts/verify_version.sh 0.6.0`.

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

[20 tests](2026-11-18-economie-et-catalogue-vague-8-tests-manuels.md), les seize points M1 à M16 de la spec et trois de plus (*Nova*, les élémentaires dans leur lot, *Résonant* sur *Prière*) ; à remplir par le propriétaire.

## 4. Trouvé périmé, et pour la file

- **Le fichier d'orchestration, §3.7** : « celle de la vague 7 est notée par la session de clôture » est un reste d'avant D76 — c'est la vague 8 que la clôture note (§8.9, point 3) ; la clôture de la vague 7 est notée ici, par `memory-bank-sync`.
- **La Faiblesse de N tours réduit N − 1 attaques** (A19) : antérieur à la vague (*Sentence*, `0.5.7`) ; T20 l'observe.
- **L'ennemi affiche Vulnérable au-delà de 4 points et la Faiblesse au-delà de 2**, quand le pipeline plafonne (spec §2).
- **Le tour ennemi joué après une victoire par les statuts** (S9 de la vague 7) : toujours ouvert ; *Prière* y soigne d'un tour de trop, comme *Bénédiction*.
- **Une relique peut choisir le déclencheur des cartes de dégâts dans l'éditeur et ne se déclenchera jamais** (revue d'ensemble), comme celui des dégâts subis ; la face d'une carte à source de cible montre sa base tant qu'aucune cible n'est visée (spec §2).
- **Les noms anglais de `statusName` n'ont pas de test d'accord** (S4).

## 5. Les leçons

1. **L'arrêt P de la spec s'est levé en un commit, sans tour** : la spec était écrite pour la recommandation, les options et leurs textes à côté. Amendement proposé : la leçon 1 de la vague 7 vaut aussi pour la spec — au §4.1, une question P s'écrit pour toutes ses options, la recommandée appliquée.
2. **Une question rendue P par le rédacteur du plan ne l'était pas** (D10) : elle appliquait à une carte neuve une exclusion déjà décidée. Amendement proposé : au §5, une question qui ne fait qu'appliquer une règle acquise à un contenu neuf est T, par le filtre 1.
3. **Un plan prescrivait de corriger une donnée pour faire passer un test** (Task 6, constat moyen du tour 1, puis R1) : il aurait fait retoucher des valeurs que le propriétaire avait fixées. Amendement proposé : au §4.3, « un test rouge ne corrige jamais une valeur de la spec ; il remonte à l'orchestrateur ».
4. **Un mineur « à corriger à la passe finale » a failli tomber** : la vérification finale n'écrit aucun fichier ; la revue d'ensemble, qui trie les mineurs différés, l'a rattrapé. Rien.
5. **Sept tâches sans aucune passe de correction**, pour un plan vérifié en deux tours. Rien.

## 6. Les statistiques de la session

**Mesuré le 18/11/2026 à 18:29**, avant le commit de §3.8 — sessions : 2 (`82c1c3c5`, `b7fef18c`) · arrêts : 1 (18/11) · durée : du 18/11 à 10:14 au 18/11 à 18:27, dont 1 h 08 de temps actif des orchestrateurs · tours de spec : 1 · tours de plan : 2
Prix lus le 18/11 sur https://platform.claude.com/docs/en/about-claude/pricing · 1 € = 1,0968 $ (BCE, 18/11) · suppléments : aucun (`server_tool_use`, `speed`, `inference_geo` vérifiés)

| | Spec | Plans | Implémentation | Fin de vague | Orchestrateur(s) | **Total** |
|:---|---:|---:|---:|---:|---:|---:|
| Temps actif | 48 min | 33 min | 31 min | 23 min | 1 h 08 | **3 h 23** |
| Agents — Opus / Sonnet | 2 / 0 | 3 / 0 | 2 / 13 | 2 / 1 | 2 / 0 | **11 / 14** |
| Appels au modèle | 246 | 236 | 148 | 123 | 144 | **897** |
| Jetons traités, dont hors cache | 62,92 M · 1,22 M | 47,16 M · 1,02 M | 14,18 M · 1,03 M | 24,20 M · 0,50 M | 37,39 M · 0,81 M | **185,85 M · 4,58 M** |
| Sortie (minimum) | 261 k | 177 k | 123 k | 125 k | 126 k | **813 k** |
| Coût API — $ / € | 23,60 / 21,52 | 17,86 / 16,28 | 7,36 / 6,71 | 8,62 / 7,86 | 16,28 / 14,84 | **73,72 / 67,21** |

*Hors cache* : l'entrée hors cache et les écritures en cache. La session `bb0be5f8` (clôture de la vague 7, avant l'ouverture de la branche), la session parallèle `adf7b095` (un brainstorming sans branche) et l'agent de cette mesure ne sont pas comptés. Les reprises par message (deux à la spec, une au plan) comptent à leur agent ; la porte d'entrée et la levée d'arrêt comptent à l'orchestrateur.
