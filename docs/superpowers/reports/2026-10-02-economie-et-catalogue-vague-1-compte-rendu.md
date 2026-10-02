# Vague 1 — `0.5.3` — E0 et E1 — compte rendu

**Chantier** : « Économie unifiée et catalogue » — déroulé par le [fichier d'orchestration](../../possible_upgrades/01-10-2026_orchestration_chantier_economie_et_catalogue_Fable5.md), fiche §8.1.
**Branche** : `feat/v0.5.3-p43-e0-e1`, ouverte le 01/10/2026 depuis `main` à `0ccacce`.
**Ouvert le** : 02/10/2026, à la fin du plan E0 (§3.5). Complété à la fin de la vague (§3.8).
**État** : en cours — E0 et E1 implémentés ; restent la simulation, la note de version, la mémoire, et ce compte rendu à compléter.

---

## 1. La branche et ses chiffres

| | |
|:---|:---|
| Porte d'entrée (01/10) | `main` propre et à jour ; CI du commit de tête `0ccacce` verte ; release `v0.5.2` publiée ; trois porteurs de version à `0.5.2` ; `dart analyze` propre ; **1187 tests** — la base de la vague |
| E0 | Spec `f38a0f1`, plan `bdd82f6`, cinq commits de code `258aca1`..`dd5ae0c` ; **1228 tests** (+41), `dart analyze` propre |
| E1 | Spec `229bce6`, plan `5bd2f10`, huit commits de code `ae939e6`..`633fe24` et un correctif de la revue d'ensemble `ee814e9` ; **1375 tests** (+147), `dart analyze` propre |

*(Le total de la vague, le nombre de commits et l'état final s'écrivent en §3.8.)*

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

*(Écrit en §3.8, pour la vague entière.)*

## 4. La simulation

*(Relancée en §3.6, une fois le code de la vague terminé.)*

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
