# Vague 6 — `0.5.8` — la tranche 2 — compte rendu

**Branche** : `feat/v0.5.8-p42-tranche-2` · **Spec** : aucune (R31, à l'essai) · **Plan** : [tranche 2](../plans/2026-11-15-p42-tranche-2.md) ([vérifications](../plans/2026-11-15-p42-tranche-2-verifications.md)) · **Maquettes** : [la réserve de mana](../../presentations/2026-11-15_reserve_de_mana_maquettes.pptx) · **Forme** : [README](README.md).

*Ouvert à la fin du plan (§3.5), fermé à la §3.8.*

## 0. Pour le propriétaire

**À tester d'abord**, par risque — [tests manuels](2026-11-15-economie-et-catalogue-vague-6-tests-manuels.md), 25 tests ; **aucun agent n'a lancé le jeu**, l'écran n'a d'autre filet que toi (D77) :
1. **T1 à T5, la réserve à l'écran** (C) : flèches, légende « +n au prochain tour », « (plafond) » au-delà du plafond seulement, le tour ennemi, la légende qui part avec le combat gagné.
2. **T6 à T9, le message de fin de tour** (D) et le téléphone : cyan, deux lignes, le bouton « Fin de Tour » libre ; les autres classes à l'identique ; les petites flèches à plus de cinq cristaux.
3. **T10 à T13, la banque elle-même** : plafond relevé par la Maîtrise et par un Mana max plus haut, reliques de mana, *Méditation* et sa *Source de Mana*.
4. **T14 à T23, les quinze cartes et les trois passifs rendus**, le tutoriel du Mage.

**Arbitrages que le joueur verra** — ta réponse : C et D ensemble (A14). **Faits sans toi, à juger au test** : les cartes et leurs valeurs, déléguées en ordres de grandeur — *Frénésie sanglante* à 1 mana au lieu de 3 (à 3, dominée par *Frappe Lourde*), *Fléau béni*, *Charge du croisé*, *Traque*, *Cataclysme*, *Bouclier d'éther* ; le Mage démarre sur *Canalisation* (A11) ; *Persistant* et *Résonant* refusés à *Méditation* (A6, D44) ; au tutoriel, le message reste « Mana restant » et rien ne passe en réserve (T1.1) ; au tour ennemi, la légende sans « (plafond) » (T1.2) ; « +2 par carte jouée ce tour » compte aussi les signatures (S4) ; la main de l'étape « Jouer des cartes » tenue dans le mana (S6). L'autonomie `continu` n'a pas servi : le plan a convergé au troisième tour.

**Risques connus** : la mise en page n'est vue par personne avant toi, ni sur Android ni sur iOS ; à grand facteur de texte, la boîte du message peut passer d'1 ou 2 px sous le bouton (déjà vrai avant) ; *Persistant* n'est pas garanti au tirage sur *Lacération* (T13 demande quatre tirages).

**Trois commandes** : `flutter test` (1682) · `flutter test test/unit/mana_reserve_test.dart test/unit/passives_mage_test.dart` (la banque et ses bornes) · `flutter run -d windows`.

## 1. La branche et ses chiffres

| Version | Commits | Tests | `dart analyze` | Code (`lib/`, `test/`, `assets/`) | Superpowers | Claude Code |
|:---|---:|:---|:---|:---|:---|:---|
| `0.5.8` | 8 de code (`866fefd7..ec438c28`), après 2 de documentation | 1620 → **1682** | `No issues found!` | 59 fichiers, +1595 / −141 | 7.0.0, `bb92a77` | 2.1.319 |

## 2. Les arbitrages

Une ligne chacun ; les options écartées sont dans le [fichier de vérifications](../plans/2026-11-15-p42-tranche-2-verifications.md).

| # | Question | Classe | Choix | Filtre |
|:---|:---|:---:|:---|:---:|
| A14 | La réserve à l'écran | P | C et D ensemble : flèches et légende cyan sous les cristaux ; message de fin de tour « n Mana en réserve » bordé de cyan ; Mage sous *Canalisation* seulement (propriétaire, 15/11, sur maquettes) | — |
| A7 · A8 · A9 · A13 | Les cartes qui complètent les lots, la courbe de Voile, les textes de *Canalisation* | délégué | Croisé + *Fléau béni*, *Charge du croisé* ; Vampire + *Traque*, *Frénésie sanglante* à 1 mana ; Voile + *Cataclysme*, *Bouclier d'éther*, courbe 1-2-3-3-3 (rédacteur `game_designer`, prompt du 15/11) | P1, P2, 7 |
| Q8 · O3 | Cartes-pont ; composition de la tranche | P · T | Aucune (vague 5) ; Croisé, Vampire, Voile gardés, rien dans la vague 5 ne les contredit | — · 7 |
| A1-A4 | La réserve sur `RunState`, jamais sauvegardée ; un calcul `ManaReserve.preview` ; tout mana non dépensé, hors `StatGains` ; rien sans *Canalisation* | T | plan §2 | 1, 4, 5, 6, 8 |
| A5 · A6 | `mana_regen` sur `might_regen`, icône du mana ; D44 sur *Méditation* par `excludesEffects` `status:<id>` | T | plan §2 | 1, 4, 6 |
| A10 · A11 · A12 | `feeds` de *Canalisation* `["power", "skill"]` ; le démasquage par la donnée, le Mage démarre sur *Canalisation* ; le tutoriel ne simule pas la réserve, message « Mana restant » | T | plan §2 | 1, 7 |
| A14 bis · A15 | Les lectures de C et D (n, « (plafond) » au-delà du plafond, la barre qui descend de 14 px) ; *Persistant* accepté sur *Lacération* | T | plan §2 | 6, 7, 8 |
| T1.1 | Le Mage du tutoriel sous *Canalisation* (rendu P par le vérificateur) | T | Reclassé T : le tutoriel ne simule aucun passif, et en `0.5.6` déjà son Mage démarrait sur *Canalisation* avec ce message | 7 |
| T1.2 | Au tour ennemi, la légende lit la réserve écrite, sans « (plafond) » | T | La réponse C vaut pour le tour du joueur ; *Essence spirituelle* ne fausse plus le n | 6, 8 |

**Décisions de SDD** (registre recopié avant sa suppression ; revue d'ensemble sur `6d3afeaf..ffb55edb`, « prête », une passe de correction `ec438c28`) :

| # | Décision | Classe | Coût si fausse |
|:---|:---|:---:|:---|
| S1 | Task 1, tri des mineurs visibles : `mana_regen` ajouté aux listes `isPlayerEffect` (face compacte, texte Flame) ; `effect_line_texts.dart` (signatures seules) et `status_indicator.dart` (carte ennemie seule, A5) laissés | T | Une phrase absente le jour où une signature posera le statut |
| S2 | Task 2, tâche à risque : revue sur le modèle le plus capable, cinq mutations du plan rouges, deux des siennes vertes — le plafond codé à 3, la réserve passée par `StatGains` — ; trois tests ajoutés, 1638 → 1641, totaux du plan décalés de 3 | T | — |
| S3 | Task 3, tri visible : sans réserve, le message « Mana restant » des autres classes rendu par le `Text` d'avant (le propriétaire le veut inchangé) ; la marge sous le bouton à grand facteur de texte et la taille des flèches aux tests manuels | T | Une retouche de taille après le test |
| S4 | Task 4, tri visible : « +2 par carte jouée ce tour » gardé sans « ou signature », convention des textes `scaleWith` de la vague 5 | T | Une phrase à reprendre après le test |
| S5 | Task 5 jouée par l'orchestrateur (amendement) : analyse propre, 1681 verts, greps conformes | T | — |
| S6 | Revue d'ensemble, trois mineurs corrigés : au tutoriel, la main de l'étape « Jouer des cartes » tient dans le mana (*Bouclier d'éther* à 3 avec une attaque la dépassait, un test) ; la légende quitte le combat fini ; un commentaire de test rendu faux par D30. Gardé : le vocabulaire `status:<id>` écrit en trois endroits, de forme identique | T | Une factorisation plus tard |

## 3. Les tests manuels

[Le fichier](2026-11-15-economie-et-catalogue-vague-6-tests-manuels.md), 25 tests, à remplir : 0 ✅ · 0 ❌ · 25 non testés. Il reprend les quatorze points du plan (§8, M1 à M14, correspondance dans ses repères) et onze de plus ; sa lecture du code a corrigé quatre prémisses du plan — l'onglet « Héros » du debug n'a pas de champ de Maîtrise (T10 passe par *Affinité*), « Sauter la phase ennemie » n'ouvre pas de tour et ne lit pas la réserve, le cas du poison demande deux ennemis, *Ferveur* donne +2 au Paladin (Maîtrise 1).

## 4. Trouvé périmé, et pour la file

- `effect_line_texts.dart` n'a pas de phrase pour `mana_regen` : à écrire le jour où une signature posera le statut (S1).
- `'status:${statusId}'` s'écrit dans `forge_rune_rules.dart`, `passive_feeds.dart` et `EffectKind.of`, qui se dit pourtant « la seule écriture du vocabulaire » : à factoriser à la quatrième lectrice.
- Au tutoriel, quand aucun couple attaque + Armure du deck ne tient dans le mana, la main d'avant est gardée : un deck de départ très atypique laisserait l'étape en deux tours.
- La garde `if (preview == null) return;` de `ManaReservePassive` est inatteignable (prévue par le plan, elle rétrécit le type).
- Deux rangées de cristaux (seize ou plus) feraient déborder le HUD de 88 px sous *Canalisation* : irréaliste aujourd'hui.
- `CLAUDE.md` (étape 2 du flux de contenu, paragraphe *Tooling*) ne dit toujours pas qu'un dossier de lot `cards/<passif>/` exige sa ligne de `pubspec.yaml`, comme une classe ou un ennemi (relevé en vague 5, confirmé par `memory-bank-sync`).
- Un commit local hors vague sur `feat/v0.5.7-p42-tranche-1-p44-lot-1`, `97c24ce7` (« la direction artistique évolutive des cartes »), n'est ni poussé ni fusionné.

## 5. Les leçons

1. **L'essai de R31 — un plan qui s'ouvre par ses décisions, sans spec — tient.** Le plan a coûté 30,54 $ et 64 min d'agents, en trois tours (0/3/5/3, 0/1/0/3, puis prêt), sans arrêt ; la vague 4 avait payé 59,63 $ (spec et deux plans, 3 h 31 d'agents, deux arrêts), la vague 5 198,77 $ (spec et trois plans). Les vagues ne pèsent pas pareil — celle-ci est « moyenne », sans écran neuf à concevoir —, mais aucun constat n'est né d'une décision absente du plan, et les relectures n'ont trouvé aucune exigence qu'une spec aurait portée. Le défaut du test du propriétaire reste à compter (§3). Amendement : garder R31 pour les lots moyens ; le verdict des vagues 7 et 8 au propriétaire, après son test.
2. **La réponse P tranchée avant la vague, sur maquettes, a supprimé tous les arrêts.** C et D sont passés tels quels dans le plan ; les ambiguïtés de lecture (le n, « (plafond) », la place de la légende) ont été tranchées en T par la maquette elle-même. Amendement : rien, la règle de la vague 5 (une question visible se pose avec ses maquettes) suffit.
3. **Les mutations de la tâche à risque ont trouvé deux trous que le plan et le rejeu du vérificateur avaient laissés** : un plafond codé à 3 et une réserve passée par `StatGains` restaient verts, parce que tous les héros testés ont 3 de Mana et aucune règle de classe sur le mana. Amendement : le relecteur d'une tâche à risque ajoute ses propres mutations aux cinq du plan — c'est ce que son brief lui demandait, et c'est là qu'il a trouvé.
4. **Les trois amendements des vagues 4 et 5 ont servi** : le tri des mineurs visibles a corrigé trois écarts (`isPlayerEffect`, le message « Mana restant » des autres classes, la légende après victoire) ; la vérification finale jouée sans agent a tenu en un appel ; le recoupement des exemples avec leurs données a fait corriger au tour 1 trois références et un compte (`audio_catalogue_test`, 71 → 86). Amendement : rien, les garder.
5. **Une question reclassée P → T par l'orchestrateur** (T1.1, le tutoriel) a évité un arrêt : la vague ne changeait pas le comportement du tutoriel. Le propriétaire le juge au test (T20). Amendement : rien ; la règle « dans le doute, P » reste, le doute se lève par le comportement d'avant la vague.

## 6. Les statistiques de la session

**Mesuré le 15/11/2026 à 05:07**, avant le commit de §3.8 — sessions : 1 (`eda831dc`) · arrêts : 0 · durée : du 15/11 à 02:46 au 15/11 à 05:07, dont 1 h 30 de temps actif de l'orchestrateur · tours de spec : 0 (R31) · tours de plan : 3
Prix lus le 15/11 sur https://platform.claude.com/docs/en/about-claude/pricing · 1 € = 1,1052 $ (BCE, 13/11) · suppléments : aucun (`server_tool_use`, `speed`, `inference_geo` vérifiés)

| | Spec | Plans | Implémentation | Fin de vague | Orchestrateur(s) | **Total** |
|:---|---:|---:|---:|---:|---:|---:|
| Temps actif | — | 1 h 04 | 1 h 02 | 30 min | 1 h 30 | **4 h 07** |
| Agents — Opus / Sonnet / Haiku | — | 4 / 0 / 0 | 3 / 9 / 0 | 3 / 0 / 1 | 1 / 0 / 0 | **11 / 9 / 1** |
| Appels au modèle | — | 301 | 230 | 168 | 119 | **818** |
| Jetons traités, dont hors cache | — | 67,60 M · 2,26 M | 25,77 M · 1,28 M | 31,12 M · 0,61 M | 30,67 M · 0,36 M | **155,15 M · 4,51 M** |
| Sortie (minimum) | — | 313 k | 177 k | 161 k | 101 k | **752 k** |
| Coût API — $ / € | — | 30,54 / 27,63 | 10,79 / 9,77 | 12,15 / 10,99 | 10,98 / 9,94 | **64,46 / 58,33** |

*Hors cache* : l'entrée hors cache et les écritures en cache. La porte d'entrée et la note du journal comptent à l'orchestrateur ; les tests manuels, le site et les prix dans la fin de vague.
