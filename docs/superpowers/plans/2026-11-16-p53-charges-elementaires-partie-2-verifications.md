# P-53, les charges élémentaires, partie 2 — vérifications du plan

**Plan** : [`2026-11-16-p53-charges-elementaires-partie-2.md`](2026-11-16-p53-charges-elementaires-partie-2.md), depuis la [spec](../specs/2026-11-15-p53-charges-elementaires-design.md) §10, partie 2. **Vague 7**, `0.5.9`, branche `feat/v0.5.9-p53-charges-elementaires`. Base de tests : **1766** (`9325e082`) ; total attendu par le rédacteur : **1772** (+6, tous en Task 1). Tâches à risque : aucune. Autonomie : `continu` (levée du 16/11). Tenu par l'orchestrateur (§3.4 du [fichier d'orchestration](../../possible_upgrades/01-10-2026_orchestration_chantier_economie_et_catalogue_Fable5.md)) : les options écartées, puis le journal des tours.

## 1. Les options écartées

### Arbitrages T (rédacteur, confirmés par l'orchestrateur le 16/11)

| Question | Options écartées | Choix | Filtre |
|:---|:---|:---|:---:|
| Q2 — transmettre les coups de Foudre un à un à Flame (spec §10, §5.2) | un journal dans `CombatState` (le héros vit dans `RunState` : deux champs, deux synchronisations) ; un flux d'événements hors état (Flame ne lirait plus l'état) ; Flame recalcule `hitBonus` sur l'état d'avant (chiffre faux quand une carte pose entre deux coups, et une règle dans Flame) ; n'afficher que la somme (change ce que le joueur lit, contre L-b) | par l'état : chaque coup note son bonus sur le défenseur, `EntityStats.chargeHits`, hors sauvegarde, sur le modèle de `lastActionWasCrit`, par `ChargeRules.noteHit` dans `_strike` et à l'attaque ennemie ; Flame la lit dans `triggerHitReactions`. Complément de la partie 1, testé, en Task 1 (spec §10) | 5 |
| Les dégâts nominaux du compte rendu de vague (S6 du compte rendu) | les afficher (chiffre faux) ; les garder sans lecteur | `FireResolution.damage` et `FireSplash.damage` retirés ; F-a lit `tranches`, `splashes`, `targetId`, `charge`, `chargeId` | 8, 6 |
| `ChargeTrack.ruptures` | le retirer (Flame déduirait une tranche de « points ≥ seuil », une règle) | gardé, lu par `HeroCard` pour reconnaître son Feu résolu | 5 |
| Gangue, halo et givre | un système à part ; du code par élément | enfants de la carte, posés et retirés par une seule méthode, `refreshChargeVisuals`, selon la sorte de rupture de la piste, commune aux deux chemins d'`EnemyCard` et à `HeroCard` | 4, 5 |
| La gangue du héros pendant l'attente | dès la rupture | pendant son tour gelé seulement, comme la spec | 6 |
| Le givre aux coins | par-dessus les cartes | sous les cartes (priorité −50) | 6 |
| Le voisin attend sa boule de feu | un mécanisme neuf ; aucune attente | `holdVisualStats()` sur le chemin différé existant, et `resolvePendingHits()` après chaque vague | 5, 8 |
| Le Feu affiché en vert Poison sur un porteur empoisonné (S10) | déduire le Poison de son tic (plus large que F-a) | un drapeau `fireDamage` : ennemis nommés par le compte rendu ; héros dont la transition montre son Feu résolu | 7 |
| Le délai de vague | 600 ms (spec §4.10) | 800 ms (0,6 s de vague + 0,2 s, spec §5.2) | 6 |
| Le moment du total « −N » | le retarder après les bonus (décale le son à l'impact) | les « +N » partent à l'impact, décalés de 100 ms ; le total ne bouge pas | 8 |
| Le héros porteur de Feu sous le seuil | rien | un rougeoiement, comme un porteur ennemi | 6 |

### Question P ouverte

| # | Question | Options | Recommandation |
|:---|:---|:---|:---|
| Q-P2 | Ce qui s'affiche à chaque coup quand la Foudre est **sous** le seuil (+1 par point, D86), que la maquette ne dessine pas | (a) tout bonus, en jaune atténué sous le seuil, en `#FFEA00` une fois chargé ; (b) seul le bonus sur une cible chargée (la maquette telle quelle) ; (c) tout bonus, dans le même `#FFEA00` | (c) |

## 2. Le journal des tours

| Tour | Mode | Bloquants | Moyens | Mineurs | Rédaction | Corrigé | Contesté et tranché |
|:---:|:---|---:|---:|---:|---:|:---|:---|
| 1 | complet | 0 | 2 | 10 | 4 | à corriger — base 1766 et total 1772 confirmés (six tests, tous en Task 1, le même nombre sous les trois options de Q-P2), toutes les références contrôlées, rien de déjà fait par la partie 1, Q2 en Task 1 avant toute animation, Flame lecteur, aucun champ de S11 sans lecteur à la fin. Constats confiés au rédacteur repris avec son contexte : (1) **moyen**, course entre le bris de la gangue et la consommation du gel (Task 3) ; (2) **moyen**, le héros ne peut pas être chargé pendant la phase ennemie en `0.5.9` (la fermeture du tour du joueur remet sa Foudre chargée à 0) : M16-L3 injouable, M16-L4 faux ; (3) M16-L2 sur un ennemi chargé ; (4) `selfDamage` et `splashDamage` sans lecteur ; (5) un commentaire de `FireResolution` ; (6), (7) la spec à amender — A12 et §4.7 (le compte rendu sans dégâts), §4.10 (800 ms) ; (8) un seul « +N 🔥 » par voisin et par vague ; (9) une assertion de PV perdue ; (10) M16-F2 ; (11) porteur et voisin ; (12) maquettes de Q-P2 ; (13)-(16) rédaction | Reclassés T par l'orchestrateur : le constat (8), rendu P, est la réponse P-c du propriétaire — la maquette p. 9 validée affiche « −24 +2 🔥 » en une fois ; le constat (12), rendu P, n'est pas une question neuve — les maquettes de Q-P2 sont fabriquées pour l'arrêt. Le retrait des dégâts du compte rendu et les 800 ms, écarts à la spec jugés justifiés par le vérificateur : la spec est amendée (filtre 8, un fait à un seul endroit) |
| 2 | différentiel | 0 | 0 | 1 | 2 | **prêt** au sens de la grille (plus aucun bloquant ni moyen) — les seize corrections du tour 1 confirmées : la gangue relâchée avant les secousses, plus d'ordre de frames qui la fasse fondre ; la fermeture du tour du joueur ; la spec amendée en A12, §4.7 et §4.10, aucun autre passage périmé ; 48 recalculé ; total 1772. Corrigés au passage par le rédacteur repris : (1) le tiroir de debug, non modal, permet de charger le héros pendant la phase ennemie — le chemin du héros chargé se voit en `0.5.9` sous les trois options de Q-P2, M16-L3 gagne cette étape ; (2), (3) rédaction | Le correcteur du tour 1 notait que `DebugActions.poseCharge` n'est pas gardé par la phase : confirmé, et c'est ce qui rend le constat (1) juste |
