# Vague 1 — `0.5.3` — E0 et E1 — compte rendu

**Chantier** : « Économie unifiée et catalogue » — déroulé par le [fichier d'orchestration](../../possible_upgrades/01-10-2026_orchestration_chantier_economie_et_catalogue_Fable5.md), fiche §8.1.
**Branche** : `feat/v0.5.3-p43-e0-e1`, ouverte le 01/10/2026 depuis `main` à `0ccacce`.
**Ouvert le** : 02/10/2026, à la fin du plan E0 (§3.5). Complété à la fin de la vague (§3.8).
**État** : en cours — E0 implémenté, E1 à venir.

---

## 1. La branche et ses chiffres

| | |
|:---|:---|
| Porte d'entrée (01/10) | `main` propre et à jour ; CI du commit de tête `0ccacce` verte ; release `v0.5.2` publiée ; trois porteurs de version à `0.5.2` ; `dart analyze` propre ; **1187 tests** — la base de la vague |
| E0 | Spec `f38a0f1`, plan `bdd82f6`, cinq commits de code `258aca1`..`dd5ae0c` ; **1228 tests** (+41), `dart analyze` propre |

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
- **La simulation ne fusionne pas la Puissance comme le jeu** : elle tient une entrée par gain (`d26_economy_sim.dart:1376` et suivantes) — plus fin que D36 ; elle diverge du jeu sur deux *Forme Démoniaque*, sur *Ferveur* d'un tour à l'autre et sur `might_regen`. Aucune valeur de D56 à D62 ni de D67 n'en dépend.
