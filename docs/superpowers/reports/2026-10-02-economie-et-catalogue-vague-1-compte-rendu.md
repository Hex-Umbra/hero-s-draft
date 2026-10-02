# Vague 1 — `0.5.3` — E0 et E1 — compte rendu

**Chantier** : « Économie unifiée et catalogue » — déroulé par le [fichier d'orchestration](../../possible_upgrades/01-10-2026_orchestration_chantier_economie_et_catalogue_Fable5.md), fiche §8.1.
**Branche** : `feat/v0.5.3-p43-e0-e1`, ouverte le 01/10/2026 depuis `main` à `0ccacce`.
**Ouvert le** : 02/10/2026, à la fin du plan E0 (§3.5). Complété à la fin de la vague (§3.8).
**État** : **livrée sur branche le 02/10/2026** — en attente du test manuel, de la PR, de la fusion et du tag `v0.5.3` du propriétaire (orchestration §3.9).

---

## 1. La branche et ses chiffres

| | |
|:---|:---|
| Porte d'entrée (01/10) | `main` propre et à jour ; CI du commit de tête `0ccacce` verte ; release `v0.5.2` publiée ; trois porteurs de version à `0.5.2` ; `dart analyze` propre ; **1187 tests** — la base de la vague |
| E0 | Spec `f38a0f1`, plan `bdd82f6`, cinq commits de code `258aca1`..`dd5ae0c` ; **1228 tests** (+41), `dart analyze` propre |
| E1 | Spec `229bce6`, plan `5bd2f10`, huit commits de code `ae939e6`..`633fe24` et un correctif de la revue d'ensemble `ee814e9` ; **1375 tests** (+147), `dart analyze` propre |

| Simulation (§3.6) | Relancée sur le code terminé : diff vide contre la référence (§4) |
| Note de version (§3.7) | `0.5.3`, « La Juste Mesure » — quinze entrées (4 améliorations, 7 équilibrages, 4 corrections), `52cba87` ; trois porteurs de version à `0.5.3` (`verify_version.sh 0.5.3` cohérent), liens de repli du site rafraîchis (`grep '0\.5\.2' site/*.html` vide), `node --test` 20/20 depuis `site/`, `test_scripts.sh` 57 ok |
| Mémoire (§3.7) | `c4de883` — ADR-104 (un statut par source et `ratio`) et ADR-105 (le moteur de runes data-driven, qui amende ADR-094 et complète ADR-061) ; onze fiches `_rules` et dix `_patterns` rattrapées ; `docs/ROADMAP.md` non touchée (aucune de ses lignes ne se clôt). Écart de méthode : l'agent a mesuré la base de tests sur `main` dans un worktree détaché, retiré ensuite (vérifié : il n'en reste rien) — §6 l'exclut ; sans effet sur la branche |
| **La vague** | Branche `feat/v0.5.3-p43-e0-e1`, version `0.5.3`, **24 commits** sur `main` (ce dernier compris), **1375 tests verts** (base 1187, +188), `dart analyze` propre — constatés sur la tête de la branche après la note et la mémoire |

---

## 2. La table des arbitrages

Chaque question tranchée, ses options, le filtre de l'arbre (orchestration §5) qui a départagé, et le choix. Le propriétaire les lit au moment de son test ; un arbitrage qu'il renverse se corrige sur la branche avant la fusion (§3.10).

### 2.1. Spec E0 — [`2026-10-01-p43-e0-puissance-par-source-et-ratio-design.md`](../specs/2026-10-01-p43-e0-puissance-par-source-et-ratio-design.md), §1.2

| # | Question | Options | Filtre qui tranche | Choix |
|:---|:---|:---|:---|:---|
| A1 | La portée de la règle « même statut et même source » | `might` seul · tout statut · les statuts du héros | 5 écarte « statuts du héros » ; 7 retient `might` seul (« tout statut » ferait entrer le lecteur de `shock`, les icônes ennemies et un rééquilibrage de `poison` et `burn`) | `might` seul, par un mécanisme général : `addStatus` compare l'id et la source sans tester `might` ; seule la Puissance reçoit une source, dans la fabrique `createStatus` |
| A2 | L'identité d'une source, pour ses six natures | l'exemplaire ou le contenu ; une étiquette ou l'id ; une source héritée ou propre | 1 pour la carte, la règle, le passif, la relique et le statut ; 4 pour l'ennemi | Toujours l'id du contenu qui pose : `card:<id de carte>` (deux exemplaires de *Forme Démoniaque* s'additionnent, comme D36 le veut), `rule:<ressource>`, `passive:<id>`, `relic:<id>`, `status:might_regen`, `enemy:<id>` |
| A3 | La forme de l'identité *(apparue à la rédaction ; retenue par l'orchestrateur)* | une chaîne · un type valeur · deux champs | 8 | Une chaîne `<nature>:<id>` nullable, écrite par le seul utilitaire `StatusSource` |
| A4 | Le sort des statuts que les runes élémentaires posent hors d'`addStatus` | les poser par `addStatus` sans source · garder la concaténation · une source de rune | **4 et 5 — maintenu par l'orchestrateur au premier tour de vérification** : un seul chemin de pose, celui que suivent déjà les statuts des cartes, plutôt qu'un chemin d'exception pour les runes | Hors de la règle de source ; **E1** les posera par `addStatus`, sans source. Changement de jeu chiffré dans la spec (brûlure 4 puis 3 au lieu de 4 puis 2 sur une cible déjà brûlée dans le même tour ; le choc d'une rune sur une cible déjà choquée compte enfin), livré et annoncé par E1 |
| A5 | La borne de `ratio` et où elle vit | ]0, 1] · ]0, +∞[ · [0, 1] · aucune ; le modèle ou le descripteur de l'éditeur | 5 puis 8 pour la valeur ; 5 pour l'endroit | ]0, 1], refusée par `StatRule.fromJson` (famille 7 de l'éditeur) ; `entity_descriptor.dart` n'est pas touché |
| A6 | L'arrondi *(apparue à la rédaction ; retenue par l'orchestrateur)* | par gain · par tour ; produit brut · tolérance · fraction | 1 ; 1 puis 6 | Par gain, arrondi supérieur avec une tolérance de 10⁻⁹, au moins 1, dans une seule fonction de `StatRule` (sinon 0,1 × 30 donnerait 4) |
| A7 | Où le joueur lit le taux *(née de « La spec doit fixer »)* | une seconde phrase à la règle · plus le titre du panneau · plus les textes de carte | 7 écarte les cartes, 8 le titre | Une seconde phrase à la règle, sur deux clés ARB par langue : « Taux : 50%, arrondi à l'entier supérieur — 6 Armure → 3 Puissance. » ; absente à ratio 1 |
| A8 | Le panneau des statuts quand deux Puissances coexistent *(née de « La spec doit fixer »)* | une ligne par entrée · une ligne sommée · une ligne nommée par sa source | 6 puis 7 | Une ligne par entrée, comme aujourd'hui, sans code ; la barre de vie garde la somme |

**La boucle de vérification de la spec E0** : deux tours. Tour 1 — deux constats moyens (la copie `_berserkerReel` des tests de l'écran de sélection, à mettre à 0,5 ; le chiffrage d'A4), huit mineurs ou de rédaction, tous corrigés. Tour 2 — prête ; sept mineurs ou de rédaction corrigés au passage, dont un choix de l'orchestrateur : la branche ennemie d'Éveil change de comportement avec E0 (sa Puissance ne rejoint plus celle de l'intention Buff), elle reçoit donc un test.

### 2.2. Plan E0 — [`2026-10-01-p43-e0-puissance-par-source-et-ratio.md`](../plans/2026-10-01-p43-e0-puissance-par-source-et-ratio.md)

Vérifié en un tour, rejoué tâche par tâche dans un clone par le vérificateur : prêt. Deux mineurs corrigés au passage par l'orchestrateur (une contrainte globale recopiée tronquée ; un commentaire qui figeait une mesure en pixels). Le rédacteur, en rejouant le plan, a mesuré que la seconde phrase de la règle fait déborder l'encadré de l'étape « Armure & Dégâts » du tutoriel de 22 pixels : la hauteur passe de 480 à 510 — ce que la spec (§5.3) prévoyait comme risque.

### 2.3. Les décisions de SDD — exécution du plan E0

Recopiées du registre de SDD avant la suppression de son espace de travail, dans l'ordre où elles ont été prises, chacune avec ce qu'elle coûte si elle est fausse.

| # | Décision | Motif | Si elle est fausse |
|:---|:---|:---|:---|
| S1 | Tâche 3 : l'ordre TDD inversé (code écrit avant les tests, aucun rouge vu) est accepté | Les tests sont ceux du brief ; le rouge de cette tâche avait été constaté au rejeu du vérificateur du plan ; la revue de tâche puis la revue d'ensemble ont confirmé que ces tests échoueraient sans le code | Un test qui passerait sans le code |
| S2 | La revue d'ensemble prend pour base `bdd82f6`, le commit où le plan commence, et non `git merge-base main HEAD` | Entre les deux, seuls les trois commits de documentation de la vague (journal, spec, plan), déjà vérifiés | Aucun code exclu |
| S3 | Mineur de la revue d'ensemble laissé : `StatRule.convertedAmount` rend 1 pour un gain nul ou négatif | Ses deux appelants gardent l'entrée (`StatGains._convert`, la constante 6 de `describe`) ; une garde de plus serait du code sans lecteur | Un appelant futur à gain nul inventerait 1 Puissance — noté pour la file (§5) |
| S4 | Mineur de la revue d'ensemble : les icônes de statut des ennemis sont indexées par id (`status_indicator.dart:43-62`) — deux `might` sur un même ennemi rendraient une icône périmée | Hors d'E0 par A1 : aujourd'hui la Puissance d'un ennemi n'a qu'une source ; l'invariant est à consigner dans l'ADR de fin de vague | Une carte qui donnerait de la Puissance à un ennemi — l'éditeur permet de l'écrire — afficherait une icône fausse |
| S5 | Point écarté par la revue d'ensemble : les reliques d'armure de début de tour (*Talisman de fer*, *Encensoir*) ne donnent aucune Puissance au Berserker, la conversion d'un tour mourant au tic du même début de tour | Défaut antérieur à E0, hors plan : E0 ne supprime que la survie accidentelle de cette Puissance par fusion dans une *Forme Démoniaque* | Rien qu'E0 change — porté à la file (§5) |

Mineurs différés pendant les revues de tâche, tous maintenus par la revue d'ensemble : `copyWith` ne remet pas `sourceId` à `null` ; le test d'Éveil ennemi prouve la non-fusion par la valeur seule ; aucun test ne sépare une Puissance de carte de l'Éveil du héros ; un commentaire de test cite `stat_rule.dart:75` ; `_roundingTolerance` déclarée après son usage ; le taux affiché arrondit 1/3 à 33 % ; la hauteur 510 laisse 8 pixels de marge.

### 2.4. Spec E1 — [`2026-10-02-p43-e1-moteur-de-runes-design.md`](../specs/2026-10-02-p43-e1-moteur-de-runes-design.md), §1

| # | Question | Options | Filtre qui tranche | Choix |
|:---|:---|:---|:---|:---|
| A1 | La forme de l'applicateur de deltas | champs à plat (esquisse du brainstorm §4.2) · liste typée de deltas · effets de carte ajoutés · garder le `switch` | 1 (D68) écarte le `switch`, puis 4 | Une liste `deltas` typée, vocabulaire fermé `CardDelta` à trois sortes (`percentBonus`, `addEffect`, `removeExhaust`) ; la couture que les évolutions de signature reprendront en vague 5 est `EffectiveCard.apply(carte, rareté, paires (delta, niveau))` |
| A2 | Le chemin des effets qu'une rune ajoute *(apparue à la rédaction)* | le registre de stratégies · un bloc propre aux runes | 5 | Le registre (ADR-061) ; les statuts posés par `addStatus`, sans source (A4 d'E0) ; `GainSource.rune` disparaît. Conséquence assumée par l'orchestrateur : *Économe* fait entendre le son du gain de mana |
| A3 | Où vit le code *(apparue)* | modèle et `ForgeRuneRules` · tout en service · tout au modèle | 5 | L'applicateur, la borne et l'analyseur `id:niveau` au modèle ; le prédicat dans `ForgeRuneRules` (ADR-094 D5, précédent `availablePassivesFor`) |
| A4 | Les `switch` d'affichage par id de rune | en donnée dès E1 · laissés à E2 · emoji seuls | 4 | En donnée dès E1 |
| A5 | La portée de G1 | dégâts et armure · plus le soin · tout effet que la rareté multiplie · par carte | 2 (la valeur que joue la simulation) | Tout effet que la rareté multiplie : dégâts, armure, soin, statuts |
| A6 | G1 face à G2 | G1 s'arrête aux effets gelés · G1 l'emporte · une compensation · plus de fusion | 1 (D68), puis 2 | G1 s'arrête aux effets gelés : une carte dont tous les effets sont gelés (*Concentration*) ne gagne que sa rareté |
| A7 | La base et l'arrondi du pourcentage *(apparue)* | base à la rareté ou à la commune ; niveau total, par niveau ou par exemplaire ; flottant ou entier | 1 ; 1 puis 2 ; **2 — maintenu par l'orchestrateur au premier tour** | Base prise à la rareté, niveau total des exemplaires, arithmétique entière au plus proche (demi vers le haut) : le script joue « au plus proche », l'erreur de flottant de son calcul n'est pas une valeur jouée |
| A8 | Comment une rune déclare son plafond *(apparue)* | clé obligatoire, `null` = sans plafond · clé facultative · sentinelle | 1 (D27), puis 6 | `maxLevel` obligatoire, `null` = sans plafond |
| A9 | La fusion de cartes dont la somme dépasse le plafond *(née de « La spec doit fixer »)* | bornée · refusée · sommée | 1 (D72, D68) | Bornée — et, ajouté par la revue d'ensemble (§2.6, E-S3), sans jamais réunir deux runes qui s'excluent |
| A10 | La Forge de Fusion au-delà du plafond | non proposée · bornée · sommée | 1, puis 6 | Une fusion qui perdrait un niveau n'est pas proposée |
| A11 | Le feu face à une carte sans rune éligible *(apparue)* | refus à la sélection · forge vide · repli sur `sharp` | 1 (D61), puis 6 | La carte est refusée à la sélection, avec un message (`forgeNoEligibleRune`) |
| A12 | La boutique face à une carte sans rune éligible *(apparue)* | moins de runes · tirer une autre carte · garder les replis | 1 (D61, D75), puis 7 | Le prédicat lit la carte avec ses runes déjà tirées ; une pré-forgée en reçoit moins ; le repli sur `sharp` disparaît |
| A13 | Le vocabulaire des types d'effet dans l'éditeur *(apparue)* | vocabulaire du disque · liste constante au modèle · texte libre | 5 | Le vocabulaire du disque sur les motifs `clé[]`, que `vocabularyOf` lit sous la clé nue ; un test d'intégrité contre le registre de stratégies |

Trois arbitrages de l'orchestrateur pendant la boucle de vérification de la spec, au premier tour : A7 maintenu (ci-dessus) ; le son du gain de mana pour *Économe*, assumé comme conséquence d'A2 (filtre 5) ; les infobulles affichent le niveau selon `maxLevel != 1`, jamais selon `stackable` — E1 n'ajoute aucun lecteur à ce que D68 garde pour E2.

**La boucle de vérification de la spec E1** : deux tours. Tour 1 — quatre constats moyens, tous corrigés : le vocabulaire choisi par A13 ne marchait pas sur une liste de chaînes (rejoué dans un clone au tour 2 : les huit runes livrées valident) ; « *Endurci* ne faisait rien sur une carte sans armure » était faux — elle donnait une Armure à part, que la carte n'affichait pas ; les infobulles ne disaient pas le chiffre joué quand une carte porte deux exemplaires d'une rune (désormais une ligne par rune, au niveau total, et `{val}` = le gain marginal) ; la prose du tutoriel sur la rareté devenait fausse (réécrite en deux langues). Tour 2 — prête ; neuf mineurs ou de rédaction corrigés au passage.

### 2.5. Plan E1 — [`2026-10-02-p43-e1-moteur-de-runes.md`](../plans/2026-10-02-p43-e1-moteur-de-runes.md)

Neuf tâches, 1228 → 1373 tests. Vérifié en un tour, rejoué en entier dans un clone par le rédacteur puis par le vérificateur (182 blocs appliqués à occurrence unique, les totaux constatés à chaque tâche) : prêt. Deux arbitrages de l'orchestrateur :

| Question | Options | Filtre | Choix |
|:---|:---|:---|:---|
| `CardTextRenderer.buildDescription()`, comptée par la spec parmi les sites à réécrire, n'a aucun appelant | la réécrire · la supprimer | 5 (pas de code mort, `CLAUDE.md`) | Supprimée |
| Une Attaque `target: self` portant une rune élémentaire poserait désormais le statut sur le héros (les effets de rune passent par la stratégie, qui lit la cible de la carte) — aucune carte livrée, mais l'éditeur permet d'en écrire une | une condition de cible en donnée dès E1 · consigner | 7 (périmètre : un mécanisme neuf, hors de la spec, sans contenu à filtrer) | Consigné, sans code ; à trancher quand une carte ou une rune le rendra possible — note pour l'ADR de la vague |

### 2.6. Les décisions de SDD — exécution du plan E1

Recopiées du registre de SDD avant la suppression de son espace de travail, dans l'ordre où elles ont été prises.

| # | Décision | Motif | Si elle est fausse |
|:---|:---|:---|:---|
| E-S1 | Deux commits (`ae939e6`, `16767d1`) portent la ligne `Co-Authored-By: Claude Sonnet 5.5` — l'attribution de la session de l'implémenteur — au lieu de la ligne Opus des contraintes ; laissés tels quels | Aucune réécriture d'un commit (orchestration §6) ; la ligne nomme le modèle qui a écrit le code | Une ligne d'attribution non uniforme dans l'historique de la branche |
| E-S2 | Tâche 4 : le rouge n'a pas été observé à part (modifications en une passe) ; accepté | Le rouge de cette tâche (échec de compilation) a été constaté aux deux rejeux du plan ; la revue a jugé que les tests échoueraient sans le code | Un test qui passerait sans le code |
| E-S3 | **Constat important de la revue d'ensemble** : la fusion de cartes 3 → 1 réunissait des runes que le prédicat interdit ensemble — trois *Potions de Soin* portant *Persistant*, *Économe* et rien donnaient une carte qui rend du mana sans s'épuiser, atteignable en partie neuve. **Corrigé** (`ee814e9`) : `consolidate` écarte une rune exclue par une rune gardée avant elle, de façon symétrique, en lisant `excludesRunes` dans la donnée ; la première arrivée est gardée ; un test sur les trois potions | Filtre 1 : consigner pour E2 laissait atteignable en `0.5.3` le moteur que D44 et D51 ferment, et que la note joueur de la spec promet fermé ; filtre 4 : une règle en donnée ; filtre 8 : l'ordre de première apparition | Une fusion perd une rune sans dialogue — la note de version dit la règle. **E2, dont l'héritage (D13) garde toutes les runes, devra suivre la même règle** |
| E-S4 | Mineur laissé : une relance payante de la forge du feu ne peut rien changer sur *Concentration*, *Focalisation* et *Surtension de Mana*, qui n'ont plus qu'une rune éligible (*Véloce*) | D68 fige le déroulé ; E2 supprime la forge du feu | Un joueur paie en `0.5.3` une relance inutile — dans la file (§5) |
| E-S5 | Mineur laissé pour E2 : les descriptions des runes qui ajoutent un effet écrivent leur niveau, pas la valeur que joue l'applicateur ; `{val}` et `{percent}` valent 0 pour une rune sans pourcentage | Identique pour les huit runes livrées (une unité par niveau) ; `cheap` (E2) aura besoin de son propre substitut | Une rune future à deux unités par niveau afficherait un chiffre faux |
| E-S6 | Mineur laissé : l'emoji d'une rune et la fente de la forge lisent encore `id:niveau` à la main | Affichage, hors de la règle « un seul analyseur » d'ADR-094 D5 ; E2 réécrit la forge | Rien de joué |

Deux ajouts de tests faits avec le correctif `ee814e9` : le test de boutique ne peut plus passer à vide ; la sélection du feu a son cas positif (une *Frappe* sans rune ouvre la forge).

Mineurs différés pendant les revues de tâche, tous maintenus par la revue d'ensemble : la copie champ par champ de `CardEffect` dans l'applicateur ; une double analyse dans `fusionOptionsFor` ; le défaut `deltas = const []` du constructeur de rune, pensé pour les tests ; pas de test d'Attaque multi-cibles avec rune élémentaire ; la doc de `ForgeRuneRules` qui parle encore de « tier » ; `scaleValue` public sans test direct ; les rendus Flame non testés par leur tâche ; un alias inutile `scaledValue` ; la fente d'une rune absente du registre sous son id ; un `continue` qui saute l'exclusion d'une candidate face à une rune hors catalogue ; un bloc de six lignes et le tirage 80/15/5 dupliqués entre le feu et la boutique ; la sélection du feu qui ne lit pas `pools` ; l'or dépensé avant un retour inatteignable ; le garde-fou des ids de rune limité aux littéraux exacts ; le message de carte pleine en dur ; trois limites de l'éditeur (motifs composés, vocabulaire vide sur une arborescence vide, cas de validateur manquants).

---

## 3. Le cahier de test manuel

Ce qu'il faut jouer pour voir chaque changement de la `0.5.3`, puis ce qui doit rester tel quel. Le menu de debug (onglet Héros, cartes, reliques, or) raccourcit les mises en place.

### 3.1. La Puissance du Berserker (E0)

| À jouer | Attendu |
|:---|:---|
| Écran de sélection de classe, carte du Berserker | La règle de classe a une seconde phrase : « Taux : 50%, arrondi à l'entier supérieur — 6 Armure → 3 Puissance. » ; rien ne déborde, sur mobile comme sur bureau. Paladin et Mage : inchangés, une seule phrase (ils n'ont pas de règle) |
| Tutoriel avec le Berserker, étape « Armure & Dégâts » | Le cadre montre les deux phrases sans déborder ; le badge de Puissance affiche la moitié de l'Armure gagnée, arrondie au-dessus |
| Berserker : jouer *Mur de Fer* (10 Armure) | +5 Puissance ce tour, au lieu de +10. *Défense* (5) → +3 ; *Éveil* (4) → +2 ; *Cri de Guerre* (4) → +2 |
| Berserker : *Forme Démoniaque*, puis *Mur de Fer* au même tour | Puissance 7 ce tour-ci, puis 2 pendant trois tours (avant : 12 pendant quatre tours). Le panneau des effets montre **deux** lignes « Puissance » ; la barre de vie affiche la somme |
| Berserker avec le passif *Rage*, *Forme Démoniaque* en cours | La Puissance de *Rage* ne s'accumule plus d'un tour à l'autre dans celle de *Forme Démoniaque* |
| Deux *Forme Démoniaque* jouées à un tour d'écart | Une seule ligne « Puissance » de 4 : la même carte s'additionne, comme avant |
| Paladin avec *Ferveur*, deux déclenchements à la suite | Une seule ligne, qui prend la plus longue durée — comme avant |

### 3.2. Les runes (E1)

| À jouer | Attendu |
|:---|:---|
| Feu de camp → forge, *Tranchant* sur une *Frappe* commune | La description dit « +1 Dégâts sur la carte (+15% de la base, au moins +1) » ; la carte inflige 1 de plus (avant : +2). Sur *Frappe Lourde*, +2 |
| *Endurci* | Proposée seulement sur une carte qui donne de l'Armure (parmi les neutres : *Défense*, *Mur de Fer*, *Éveil*, *Cri de Guerre*) ; plus jamais sur *Frappe* |
| *Économe* | Jamais proposée sur une carte gratuite (*Concentration*, *Focalisation*, *Surtension de Mana*) |
| *Persistant* | Jamais sur une carte qui pioche ou rend du mana ; jamais sur une carte qui porte *Économe* ou *Véloce*, ni l'inverse |
| *Économe*, *Véloce*, *Congelant*, *Persistant* | Jamais au niveau 2 ou plus : ni au feu, ni sur une carte pré-forgée de la boutique, ni après une fusion de cartes, ni au nœud Forge de Fusion ; plus reproposées à une carte qui les porte déjà |
| Fusionner trois *Potions de Soin* portant *Persistant*, *Économe* et rien | La carte obtenue ne porte que *Persistant* |
| Une *Concentration* peu commune qui porte *Véloce* 1, au feu | Refusée à la sélection, avec un message qui dit qu'aucune rune ne peut plus s'y poser ; la forge ne s'ouvre pas |
| Une *Frappe* sans rune, au feu | La forge s'ouvre normalement |
| Fusion 3 → 1 | Chaque chiffre de dégâts, d'armure, de soin ou de statut monte d'au moins 1 par rareté. *Coup Empoisonné* légendaire : 7 dégâts et 5 Poison (avant : 6 et 2) ; *Forme Démoniaque* légendaire : 6 Puissance (avant : 4) ; *Concentration* légendaire : pioche toujours 2 (avant : 4) |
| *Brûlant* ou *Surchargé* sur une attaque, jouée deux fois sur le même ennemi dans le tour | La brûlure se fond dans celle qui est en cours, et s'éteint au même rythme ; le choc compte enfin dans les dégâts du coup suivant |
| Jouer une carte qui porte *Économe* | Le son du gain de mana se fait entendre |
| Infobulle d'une carte qui porte deux *Tranchant* 1 | Une seule ligne, « Tranchant 2 : … », au chiffre que la carte joue |
| Tutoriel, étape de la fusion | Le texte sur la rareté dit « au moins +1 par fusion » et que la pioche et le mana ne changent pas |
| Cartes communes sans dégâts ni armure (*Potion de Soin*, *Concentration*…) au feu | Elles se voient proposer *Véloce*, *Économe* ou *Persistant* (selon ce qui leur est permis) : c'est le repli de la forge, qui existait déjà, maintenant que *Tranchant* et *Endurci* ne leur sont plus proposées |

### 3.3. Ce qui doit rester inchangé

- Le déroulé de chaque écran : la forge du feu (fentes, relances, achat de fente), la boutique, la fusion de cartes et son dialogue d'héritage, le nœud Forge de Fusion — seul s'ajoute le refus du feu ci-dessus.
- Le nombre de runes qu'une carte peut porter selon sa rareté, et les prix de la forge et de la boutique.
- *Tranchant*, *Endurci*, *Brûlant* et *Surchargé* restent sans plafond de niveau.
- Paladin et Mage : leurs passifs, leurs statistiques ; le poison s'additionne comme avant.
- Une partie neuve est conseillée : avant la `1.0`, une sauvegarde d'une version précédente n'a pas à se recharger.

## 4. La simulation

Relancée le 02/10/2026 sur la tête de la branche, le code des deux lots terminé et vert (`ee814e9` pour le code ; commande : `dart run tool/simulations/d26_economy_sim.dart --out .superpowers/d26_vague_1.md`, fichier supprimé avant le lancement) — 337 s.

- **Un seul temps, sans réalignement** (fiche 8.1, orchestration §7.3, ligne 1) : E0 ajoute `ratio` à la classe du Berserker, que le script ignore (son taux est en dur) ; E1 ajoute aux huit runes `deltas`, `maxLevel` et les champs d'éligibilité, que le script ignore, et retire l'`eligibleCardTypes` de *Tranchant* et d'*Endurci*, qu'il ignorait déjà ; aucun `weight` n'a bougé, ni l'`eligibleCardTypes` des six autres runes (vérifié par commande contre `main`).
- **Résultat** : `git diff --no-index tool/simulations/d26_reference_output.md .superpowers/d26_vague_1.md` — **code 0, rien d'affiché : identique**, ligne « Données lues » comprise (aucun fichier créé ni supprimé sous `assets/data/`).
- **Ce que ce diff vide prouve** : que le script n'a pas bougé et que la réserve de la fiche tient — un test de non-régression du script, pas une validation des données de la vague (D73). Ni le script ni la référence ne sont recommités.

## 5. Trouvé périmé, et pour la file

- **Les reliques d'armure de début de tour sont sans effet chez le Berserker** (S5) : *Talisman de fer* et *Encensoir* s'appliquent avant le tic (`run_controller.dart:463`, `:466`) ; la Puissance qu'elles convertissent meurt dans le même début de tour. Défaut antérieur à la vague, à ouvrir en ticket.
- **`StatRule.convertedAmount` et un gain nul** (S3) : la précondition « gain strictement positif » est documentée, pas imposée.
- **Une carte d'armure ne dit pas sa Puissance convertie** (A7) : chez le Berserker, *Mur de Fer* affiche « 10 Armure » ; la règle de classe dit le taux, pas la carte. Le brainstorm §7.2 le souhaitait (« la description doit le dire ») ; aucun rendu de carte ne lit aujourd'hui les règles de classe.
- **Un quatrième lecteur « une entrée par id »** : `status_indicator.dart:43-62` (icônes des ennemis), que la fiche ne nommait pas ; il casse déjà avec les statuts que les runes élémentaires concatènent, et A4 le répare en E1.
- **La fiche E1 disait qu'*Endurci* « ne faisait rien » sur une carte sans armure** (fiche 8.1, ligne joueur ; revue §15 W6) : faux — elle donnait 2 × niveau d'Armure à part, figé par `stat_gains_characterization_test.dart:116-119`. La spec E1 et la note le disent juste.
- **Le multiplicateur de rareté était écrit à huit endroits, dont deux dans le tutoriel**, que la fiche ne nommait pas ; **la boutique et le feu retombaient sur `sharp` sans regarder l'éligibilité** (A11, A12 les ferment) ; **`CardTextRenderer.buildDescription()` était du code mort** ; **`_rules/03-8` décrit une « Sélection Pondérée par Rareté » (`weightCommon`…) que le code n'a plus**.
- **Les cartes communes sans dégâts ni armure se voient proposer au feu *Véloce*, *Économe* ou *Persistant*** : leur pool `common` est vide sous le prédicat, et le repli préexistant de la forge descend au pool `rare` (D68 garde `pools` jusqu'à E2). C'est ce qui rendait E-S3 atteignable ; à dire dans la note de version.
- **La relance payante sans effet** (E-S4) et **les descriptions des runes à effet ajouté** (E-S5) : pour E2.
- **La cible des statuts de rune** (§2.5) : l'éligibilité des runes élémentaires ne lit pas la cible de la carte.
- **Le badge « Usage unique » et les particules d'épuisement ignorent *Persistant*** (ADR-094, Conséquences) : non planifié.
- **Pour E2** : sous le prédicat, la première fusion d'une *Concentration* n'a aucune rune éligible (D65 tient, à vide) ; l'héritage de D13 devra suivre la règle d'exclusion de `consolidate` (E-S3).
- **Un test peut-être instable** : `test/widget/content_editor_screen_test.dart` (groupe des imports) a échoué une fois dans une suite complète de l'implémenteur du correctif, sans se reproduire — cinq relances isolées vertes par l'orchestrateur. À surveiller.
- **La simulation ne fusionne pas la Puissance comme le jeu** : elle tient une entrée par gain (`d26_economy_sim.dart:1376` et suivantes) — plus fin que D36 ; elle diverge du jeu sur deux *Forme Démoniaque*, sur *Ferveur* d'un tour à l'autre et sur `might_regen`. Aucune valeur de D56 à D62 ni de D67 n'en dépend.

---

## 6. Les statistiques de la session

Ajoutées le 02/10/2026 à la demande du propriétaire, après la livraison. **Mesurées, pas estimées** : dans les transcriptions de la session (`~/.claude/projects/<projet>/9cb99a89-77ab-4370-a2a0-03f08d7f30ee.jsonl` pour l'orchestrateur, un fichier par sous-agent sous `…/subagents/`), chaque appel au modèle compté une fois par identifiant de message. Les heures sont locales (UTC+2) ; les jalons viennent des commits de la branche. Ces chiffres ne comptent pas l'ajout de cette section.

### 6.1. Le temps

| | |
|:---|:---|
| Début | **01/10/2026 à 22:12** — le prompt de lancement |
| Fin | **02/10/2026 à 06:19** — le dernier message de l'orchestrateur, après le commit `5a3af40` (06:18) |
| Durée | **8 h 07 min**, d'une traite, sans arrêt ni reprise |
| Temps actif de l'orchestrateur | environ 3 h 16 min — ses tours de travail, en comptant les attentes de moins de dix minutes (les tâches courtes de l'implémentation) : ce temps chevauche donc en partie celui des agents |
| Temps actif cumulé des sous-agents | environ 7 h 23 min — lancés l'un après l'autre, sauf les cinq reprises par message (§1 du fichier d'orchestration : tout se déroule en série) |

| Étape | De | À | Durée |
|:---|:---|:---|---:|
| Porte d'entrée et branche (3.1, 3.2) | 22:12 | 22:15 | 3 min |
| E0 — spec, deux tours de vérification (3.3) | 22:15 | 23:20 | 1 h 04 |
| E0 — plan, un tour (3.4) | 23:20 | 00:32 | 1 h 12 |
| E0 — implémentation, cinq tâches, revue d'ensemble, ouverture du compte rendu (3.5) | 00:32 | 01:04 | 32 min |
| E1 — spec, deux tours (3.3) | 01:04 | 02:35 | 1 h 31 |
| E1 — plan, un tour (3.4) | 02:35 | 04:27 | 1 h 52 |
| E1 — implémentation, huit tâches, revue d'ensemble et correctif (3.5) | 04:27 | 05:42 | 1 h 15 |
| Simulation (3.6) — 337 s de calcul | 05:42 | 05:48 | 6 min |
| Note de version et mémoire (3.7) | 05:48 | 06:17 | 29 min |
| Compte rendu, suivi, journal (3.8) | 06:17 | 06:19 | 2 min |

Les specs et les plans prennent plus des deux tiers du temps (5 h 39) ; l'implémentation, un peu plus d'un cinquième (1 h 47).

### 6.2. Les agents

**43 agents** : l'orchestrateur, et **42 sous-agents** lancés par lui — aucun sous-agent n'en a lancé d'autre. Cinq d'entre eux ont été repris avec leur contexte, par message, pour corriger leur document : le rédacteur de la spec E0 (deux fois), celui de la spec E1 (deux fois), celui du plan E1 (une fois).

| Rôle | Nombre | Modèle |
|:---|---:|:---|
| Orchestrateur | 1 | Opus 5.5 |
| Rédacteurs de spec et de plan | 4 | Opus 5.5 |
| Vérificateurs de spec et de plan | 6 | Opus 5.5 |
| Implémenteurs de tâche (5 pour E0, 8 pour E1, 1 correctif) | 14 | Sonnet 5.5 |
| Relecteurs de tâche (5 pour E0, 8 pour E1) | 13 | Sonnet 5.5, sauf deux sur Opus 5.5 (les tâches 1 et 5 d'E1, le moteur et l'éligibilité) |
| Revues d'ensemble des deux plans | 2 | Opus 5.5 |
| Revue ciblée du correctif | 1 | Sonnet 5.5 |
| Skills de fin de vague (`patch-notes-writer`, `memory-bank-sync`) | 2 | Opus 5.5 |
| **Sous-agents** | **42** | 16 Opus 5.5, 26 Sonnet 5.5 |

Appels au modèle : 166 pour l'orchestrateur, 1 691 pour les sous-agents (1 492 sur Opus, 199 sur Sonnet) — **1 857** en tout.

### 6.3. Les jetons

| | Orchestrateur (Opus) | Sous-agents Opus | Sous-agents Sonnet | **Total** |
|:---|---:|---:|---:|---:|
| Entrée hors cache | 342 | 2 996 | 398 | **3 736** |
| Écriture en cache | 886 703 | 9 520 621 | 1 473 718 | **11 881 042** |
| Lecture du cache | 58 500 406 | 434 991 239 | 12 927 757 | **506 419 402** |
| Sortie | 213 285 | 334 411 | 102 999 | **650 695** |
| **Total traité** | 59 600 736 | 444 849 267 | 14 504 872 | **518 954 875** |

- **Environ 519 millions de jetons traités**, dont 97,6 % relus depuis le cache : chaque appel d'un agent relit son contexte, qui grandit à chaque fichier lu. Hors lecture du cache, **12,5 millions** (entrée, écriture en cache, sortie) ; la sortie seule, **650 695 jetons**.
- **Où ils sont allés.** Les rédacteurs et vérificateurs de specs et de plans font 73 % du total (378 millions) : ils lisent le code en entier pour re-mesurer chaque `fichier:ligne`, et les rédacteurs comme les vérificateurs de plan ont rejoué leur plan dans un clone. L'implémentation, trente agents en deux lots, n'en fait que 7 % (37 millions) : chaque implémenteur ne lit que le brief de sa tâche. Le plan E1 seul — rédaction, rejeu, vérification — compte pour 142 millions.

| Étape | Sous-agents | Temps actif | Jetons traités | Dont sortie |
|:---|---:|---:|---:|---:|
| E0 — spec | 3 | 62 min | 67,0 M | 52 679 |
| E0 — plan | 2 | 71 min | 55,7 M | 55 792 |
| E0 — implémentation | 11 | 23 min | 9,6 M | 37 829 |
| E1 — spec | 3 | 88 min | 112,7 M | 100 579 |
| E1 — plan | 2 | 111 min | 142,2 M | 16 160 |
| E1 — implémentation | 19 | 61 min | 27,6 M | 102 973 |
| Fin de vague — skills | 2 | 27 min | 44,6 M | 71 398 |
| Orchestrateur | — | ≈ 196 min | 59,6 M | 213 285 |

### 6.4. Le coût au tarif de l'API

Ce que la session aurait coûté facturée au tarif public de l'API Claude — pas une facture réelle. **Méthode** : chaque catégorie de jetons multipliée par son prix, modèle par modèle ; les écritures en cache au prix de leur durée, que les transcriptions ventilent (l'orchestrateur écrit son cache pour une heure, les sous-agents pour cinq minutes) ; les jetons de réflexion sont comptés dans la sortie, comme l'API les facture. Prix lus le 02/10/2026 sur la [page des tarifs](https://platform.claude.com/docs/en/about-claude/pricing), en dollars ; conversion au taux de référence de la BCE du 01/10/2026, **1 € = 1,1298 $**. Aucun supplément ne s'applique : aucune recherche web, vitesse standard, routage mondial par défaut, palier standard.

| Prix, $ par million de jetons | Entrée | Écriture en cache, 5 min | Écriture en cache, 1 h | Lecture du cache | Sortie |
|:---|---:|---:|---:|---:|---:|
| Claude Opus 5.5 | 4,00 | 5,00 | 8,00 | 0,20 | 20,00 |
| Claude Sonnet 5.5 | 2,00 | 2,50 | 4,00 | 0,20 | 10,00 |

| | Dollars | **Euros** |
|:---|---:|---:|
| Orchestrateur (Opus 5.5) | 23,06 $ | **20,41 €** |
| Sous-agents Opus 5.5 (16) | 141,30 $ | **125,07 €** |
| Sous-agents Sonnet 5.5 (26) | 7,30 $ | **6,46 €** |
| **Total de la session** | **171,66 $** | **151,94 €** |

**Par catégorie** : la lecture du cache fait 59 % du coût (101,28 $, 89,64 €), l'écriture en cache 34 % (58,38 $, 51,67 €), la sortie 7 % (11,98 $, 10,60 €) ; l'entrée hors cache, un centime. Le cache, relu à chaque appel, coûte donc plus que tout ce que les modèles écrivent — mais sans lui, ces 506 millions de jetons relus l'auraient été au prix plein de l'entrée, vingt fois plus cher sur Opus 5.5.

| Étape | Sous-agents | Dollars | Euros |
|:---|---:|---:|---:|
| E0 — spec | 3 | 23,16 $ | 20,50 € |
| E0 — plan | 2 | 17,41 $ | 15,41 € |
| E0 — implémentation | 11 | 4,38 $ | 3,87 € |
| E1 — spec | 3 | 36,88 $ | 32,64 € |
| E1 — plan | 2 | 41,89 $ | 37,07 € |
| E1 — implémentation | 19 | 11,84 $ | 10,48 € |
| Fin de vague — skills | 2 | 13,05 $ | 11,55 € |
| Orchestrateur | — | 23,06 $ | 20,41 € |

**Par rôle** : les rédacteurs de specs et de plans, 84,59 $ (74,87 €) ; les vérificateurs, 34,75 $ (30,76 €) ; l'orchestrateur, 23,06 $ (20,41 €) ; les deux skills de fin de vague, 13,05 $ (11,55 €) ; les relecteurs de tâche et les revues d'ensemble, 10,67 $ (9,44 €) ; les implémenteurs, 5,55 $ (4,91 €). Les specs et les plans font 70 % du coût (119,34 $) ; l'implémentation des deux lots, 9 % (16,22 $) — ses implémenteurs tournent sur Sonnet 5.5, avec un brief court par tâche, et seules ses revues d'ensemble et deux revues de tâche passent sur Opus 5.5.
