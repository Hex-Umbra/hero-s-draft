# P-05 vague 1 — l'interface des ennemis — vérifications de la spec

Fichier voisin de [la spec](2026-11-21-p05-interface-des-ennemis-design.md), tenu par l'orchestrateur (ADR-108 D4) : les options écartées de chaque arbitrage, puis le journal des tours de vérification. La spec ne garde que les choix.

## 1. Les options écartées

| # | Question | Classe | Options écartées | Filtre |
|:---|:---|:---:|:---|:---:|
| A1 | La couche de chaque élément | T | La fiche ouverte dans l'état Riverpod (`CombatState`) ; la fiche dessinée en Flame | 5 |
| A2 | Où vit le plus haut montant d'armure | T | Un champ sur `EntityStats`, qui entrerait dans la sauvegarde du héros ; un champ sur `EnemyInstance` tenu par le contrôleur, soit neuf écritures de `state` | 5, 8 |
| A3 | Le sort de `StatBadge` | T | Le garder en changeant ses valeurs | 5, 7 |
| A4 | La géométrie de la barre | T | Les pixels de la maquette, recopiés | 6 |
| A5 | Les icônes des pastilles | T | Garder les icônes codées d'aujourd'hui pour les trois types | 4, 6 |
| A6 | Les largeurs des colonnes | T | Une colonne du niveau mesurée ; un nom extensible, le niveau à sa suite | 5, 6 |
| A7 | L'infobulle unique | T | Une infobulle par pastille | 1, 8 |
| A8 | Le composant des languettes | T | Deux composants, ennemi et héros ; les icônes Material de la table ; une entrée par `id` | 5, 6, 7 |
| A9 | La détection du survol | T | `HoverCallbacks` par composant | 6, 8 |
| A10 | L'ordre du toucher | T | La fiche avant la signature armée | 1, 5 |
| A11 | La mise au premier plan | T | Agrandir autour du centre ; un voile en Flutter ; une bordure portée par la sélection (tour 1, constat 2) ; un voile au-dessus des textes flottants (tour 1, constat 14) | 6, 8 |
| A12 | La fermeture | T | Fermer par les seuls touchers Flame ; deux propriétaires de l'état | 1, 5 |
| A13 | Le cadre de la fiche | T | Dessiné en Flame | 5, 6 |
| A15 | Le tutoriel | T | Laisser les maquettes de l'étape 6 telles quelles | 6 |
| A16 | Le découpage | T | Deux plans | 7 |
| — | Le « +1 » de B6 (était P-1) | T | Le construire dès cette vague, sous l'une de ses deux lectures (deux pastilles puis « +N » ; une pastille puis « +N ») : aucune intention n'a deux effets en `0.6.1`, ce serait du code sans lecteur. Il se fixe avec B1 | 7 |
| — | La main inerte au survol, fiche ouverte | T | La laisser réagir : B13 dit le reste du plateau estompé, et un toucher ailleurs ferme la fiche | 6 |
| — | Les noms de statut en français seul | T | N'en traduire que deux : six sont posés ainsi, la languette du héros les montrerait tous | 4 |

## 2. Les questions du propriétaire

Posées le 21/11 avec leurs maquettes (deck, diapositives 60 à 66), sous les numéros 31 à 41. La spec les applique à titre provisoire jusqu'à sa réponse.

| N° | Dans la spec | Question | Appliqué à titre provisoire |
|:---:|:---|:---|:---|
| 31 | P-2 | La pastille de Puissance : éclair orange de la table, flèche violette d'aujourd'hui, ou éclair rouge de la fiche | L'éclair orange |
| 32 | D-1 | La Foudre chargée dans la languette de droite : rouge (B14) ou jaune (vague 7) | Le rouge, lettre de B14 |
| 33 | P-4 (vi) | Une charge rompue sans chiffre : le nom de son état, ou l'icône seule | Le nom |
| 34 | P-4 (i) | Une section vide de la fiche : masquée, ou « Aucun » | Masquée |
| 35 | P-4 (iv) | La fiche pendant le tour des ennemis | Elle ne s'ouvre pas |
| 36 | P-4 (v) | Ce que la fiche estompe | La scène Flame seule |
| 37 | P-5 | Le tutoriel parle-t-il de la fiche | Une phrase à l'étape des intentions |
| 38 | — | Le panneau des effets du héros, avec ses languettes | Il reste |
| 39 | P-6 | La languette déroulée d'un ennemi du bord | Vers l'intérieur |
| 40 | P-7 | La carte dont la fiche s'ouvre : barre en place, ou agrandie autour du centre | Barre en place |
| 41 | P-4 (vii) | Les icônes de la régénération de Mana et de PV du héros | 💎 et 💖 |

P-4 (ii) — un statut de 99 tours n'affiche pas de durée — et P-4 (iii) — une description pour la Faiblesse et le Vulnérable seulement — vont avec la question 34.

## 3. Le journal des tours

| Tour | Mode | Bloquants | Moyens | Mineurs | Rédaction | Suite |
|:---:|:---|:---:|:---:|:---:|:---:|:---|
| 1 | complet | 1 (D) | 7 (6 T, 1 P) | 8 | 1 | Tout corrigé par le rédacteur repris ; aucun constat contesté. Le bloquant — la Foudre chargée en jaune contredit B14 — devient la question D-1, le rouge appliqué en attendant. Le constat moyen de classe P devient P-6. Deux corrections vont plus loin que leur constat, acceptées : six noms de statut traduits au lieu de deux ; la commande `testWidgets` de §11 comparée elle aussi à la base de la branche |
| 2 | différentiel | 0 | 3 (T) | 7 | 3 | Les dix-neuf corrections du tour 1 sont faites. Trois constats moyens, tous nés de ces corrections : le toucher Flame passe avant le `Listener`, si bien que la décision de fermer la fiche se prend dans Flame, par une seule règle « ce point est-il sur cet ennemi », et non sur un rectangle reflété ; ce reflet est différé, réémission comprise ; un septième nom posé en français seul, « Compteur », reçoit sa clé. Toutes les corrections proposées acceptées |
| 3 | différentiel | 0 | 1 (T) | 7 | 4 | **Non corrigé : arrêt, autonomie `strict`.** Dix des quatorze corrections du tour 2 sont justes. Le constat moyen : la zone de l'ennemi est lue « au moment de l'appel », si bien qu'un appui sur la barre ou le haut de la carte d'un ennemi fermé ouvrirait la fiche puis la refermerait dans le même appui si l'agrandissement s'applique aussitôt. Correction recommandée par le vérificateur, et par l'orchestrateur : la fermeture reçoit le pointeur, et garde la fiche que Flame vient d'ouvrir pour ce même pointeur. Les sept mineurs sont des précisions de géométrie (le repère du point, le bouton principal seul, une seule déclaration de la géométrie de la barre, le cadre qui ne recouvre pas la languette) |
