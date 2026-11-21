# P-05 vague 1 — l'interface des ennemis — vérifications de la spec

Fichier voisin de [la spec](2026-11-21-p05-interface-des-ennemis-design.md), tenu par l'orchestrateur (ADR-108 D4) : les options écartées de chaque arbitrage, puis le journal des tours de vérification. La spec ne garde que les choix.

## 1. Les options écartées

| # | Question | Classe | Options écartées | Filtre |
|:---|:---|:---:|:---|:---:|
| A1 | La couche de chaque élément | T | La fiche ouverte dans l'état Riverpod (`CombatState`) ; la fiche dessinée en Flame | 5 |
| A2 | Où vit le plus haut montant d'armure | T | Un champ sur `EntityStats`, qui entrerait dans la sauvegarde du héros ; un champ sur `EnemyInstance` tenu par le contrôleur, soit neuf écritures de `state` | 5, 8 |
| A3 | Le sort de `StatBadge` | T | Le garder en changeant ses valeurs | 5, 7 |
| A4 | La géométrie de la barre | T | Les pixels de la maquette, recopiés | 6 |
| A5 | Les icônes des pastilles | T | Prendre dans la table d'icônes la Défense (`shield_rounded`, une autre forme que celle d'aujourd'hui) et la Puissance (l'éclair orange, que B31 écarte) | 1, 6, 8 |
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

Posées le 21/11 avec leurs maquettes (deck, diapositives 60 à 66), sous les numéros 31 à 41. **Le propriétaire y a répondu le même jour** : elles sont devenues les décisions B31 à B41 du [cadrage](../../possible_upgrades/21-11-2026_cadrage_bestiaire_P05_Fable5.md) §1.2. Ce tableau garde les options qu'il a écartées.

| Décision | Était | Question | Retenu | Écarté |
|:---:|:---|:---|:---|:---|
| B31 | P-2 | La pastille de Puissance d'un ennemi | La flèche violette d'aujourd'hui | L'éclair orange de la table, que la spec appliquait ; l'éclair rouge de la fiche |
| B32 | D-1 | La Foudre chargée dans la languette de droite | Le jaune — B14 amendée par cette exception | Le rouge, lettre de B14, que la spec appliquait |
| B33 | P-4 (vi) | Une charge rompue sans chiffre | Le nom de son état | L'icône seule |
| B34 | P-4 (i) à (iii) | Une section vide de la fiche ; un statut de 99 tours ; les descriptions | Masquée ; sans durée ; Faiblesse et Vulnérable seulement | « Aucun » ; « 99 tours » ; une phrase neuve par statut |
| B35 | P-4 (iv) | La fiche pendant le tour des ennemis | Elle ne s'ouvre pas | L'ouvrir à tout moment |
| B36 | P-4 (v) | Ce que la fiche estompe | Le plateau seul | Le HUD aussi |
| B37 | P-5 | Le tutoriel et la fiche | Une phrase à l'étape des intentions | Rien ; une démonstration |
| B38 | — | Le panneau des effets du héros | Il reste | Le retirer au profit des languettes |
| B39 | P-6 | La languette déroulée d'un ennemi du bord | Vers l'intérieur | Vers l'extérieur, coupée par l'écran |
| B40 | P-7 | La carte dont la fiche s'ouvre | Sa barre en place | Agrandie autour de son centre, comme la maquette |
| B41 | P-4 (vii) | Les icônes de la régénération du héros | 💎 et 💖 | — |

## 3. Le journal des tours

| Tour | Mode | Bloquants | Moyens | Mineurs | Rédaction | Suite |
|:---:|:---|:---:|:---:|:---:|:---:|:---|
| 1 | complet | 1 (D) | 7 (6 T, 1 P) | 8 | 1 | Tout corrigé par le rédacteur repris ; aucun constat contesté. Le bloquant — la Foudre chargée en jaune contredit B14 — devient la question D-1, le rouge appliqué en attendant. Le constat moyen de classe P devient P-6. Deux corrections vont plus loin que leur constat, acceptées : six noms de statut traduits au lieu de deux ; la commande `testWidgets` de §11 comparée elle aussi à la base de la branche |
| 2 | différentiel | 0 | 3 (T) | 7 | 3 | Les dix-neuf corrections du tour 1 sont faites. Trois constats moyens, tous nés de ces corrections : le toucher Flame passe avant le `Listener`, si bien que la décision de fermer la fiche se prend dans Flame, par une seule règle « ce point est-il sur cet ennemi », et non sur un rectangle reflété ; ce reflet est différé, réémission comprise ; un septième nom posé en français seul, « Compteur », reçoit sa clé. Toutes les corrections proposées acceptées |
| 3 | différentiel | 0 | 1 (T) | 7 | 4 | **Arrêt, autonomie `strict` — levé le même jour par le propriétaire**, qui accepte les corrections recommandées et accorde un quatrième tour. Dix des quatorze corrections du tour 2 sont justes. Le constat moyen : la zone de l'ennemi est lue « au moment de l'appel », si bien qu'un appui sur la barre ou le haut de la carte d'un ennemi fermé ouvrirait la fiche puis la refermerait dans le même appui si l'agrandissement s'applique aussitôt. Correction recommandée par le vérificateur, et par l'orchestrateur : la fermeture reçoit le pointeur, et garde la fiche que Flame vient d'ouvrir pour ce même pointeur. Les sept mineurs sont des précisions de géométrie (le repère du point, le bouton principal seul, une seule déclaration de la géométrie de la barre, le cadre qui ne recouvre pas la languette) |
| 4 | différentiel | 0 | 1 (T) | 5 | 3 | **« À corriger » : second arrêt.** Les onze réponses du propriétaire sont reprises fidèlement, et onze des douze corrections du tour 3 tiennent. Le constat moyen naît de la correction du tour 3 : la fiche se gardait « si le pointeur est celui que Flame vient de retenir, ou si le point est dans la zone de l'ennemi ouvert », et la seconde clause laissait la fiche ouverte sous un bouton du HUD posé à hauteur de la barre de l'ennemi de droite. Correction recommandée, appliquée par le rédacteur et **non revérifiée** : la fiche se garde si et seulement si le pointeur est celui que Flame vient de retenir — une clause en moins, aucune en plus. Le propriétaire choisit de passer au plan, sans cinquième tour : la règle de fermeture se vérifie sur le code de la tâche à risque |
