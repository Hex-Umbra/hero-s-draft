# Vérifications — spec de la tranche 1 et de P-44 lot 1

**Spec** : [`2026-10-25-p42-tranche-1-p44-lot-1-design.md`](2026-10-25-p42-tranche-1-p44-lot-1-design.md) · **Vague** : 5, `0.5.7`, branche `feat/v0.5.7-p42-tranche-1-p44-lot-1` · **Autonomie** : `continu` (prompt de lancement du 25/10).
Tenu par l'orchestrateur (ADR-108 D4) : les options que la spec a écartées, puis le journal des tours. La spec ne garde que le choix et sa raison ; ce fichier n'est lu par un vérificateur qu'en mode différentiel.

## Les options écartées

| # | Question | Classe | Options écartées, et le filtre qui les écarte | Retenu |
|:---:|:---|:---:|:---|:---|
| A1 | Q10 : comment se dit une carte de lot | T | `category: global` + `passive` ; une valeur `lot` — sans objet, E4 a supprimé `category` (filtre 5) | `CardData.passive` seul |
| A2 | La forme C au chargeur | T | Une source neutre sans injection : une neutre qui déclarerait `passive` deviendrait carte de lot en silence (filtre 5) | Seconde source `cards/*/*.json` qui injecte `passive` ; la source neutre injecte `passive: null` |
| A3 | Le prédicat d'offre | T | Un second prédicat · reprendre le nom `isOfferableTo` · un filtre chez chaque lecteur (filtre 5) | `isOfferable(String? activePassiveId)`, quatre lecteurs |
| A4 | Mesurer O5 | T | Lire les dossiers à l'exécution — un dossier vide n'est pas dans le manifeste · un drapeau sur le passif (filtre 5) | Masqué quand aucune carte du registre ne porte le passif |
| A5 | `PassiveData.classes` à une classe | T | Retirer le champ · contrainte en test seulement · modèle non nullable (filtre 5) | Refus au chargement si absent ou de longueur ≠ 1 |
| A6 | `feeds` | T | Des mots simples, qui ne disent pas « PV manquants » (filtre 1) · `feeds` sur les trois passifs à lot seulement (filtre 4) | Vocabulaire à préfixes, exigé sur les neuf passifs, une fonction pure |
| A7 | Validateur `costs.armor` | T | Id `berserker` en dur · contrôle dans le prédicat d'offre (filtre 4) | Refus si la classe du passif a une `statRule` qui convertit l'armure |
| A8 | D17 | T | Test seul · refus par l'offre (filtre 5) | Refus au chargement, et un test |
| A9 | La forme de `costs` | T | `costs` partout · `cost` et `costs` ensemble · accepter `discard` (filtres 5, 7) | `cost` ou `costs` ; `mana` exigé ; au moins `hp` ou `armor` ; `discard` refusé |
| A10 | Où tester qu'une carte est jouable | T | Trois copies divergentes (filtre 5) | Une fonction, `EffectResolver.canAfford` |
| A11 | `scaleWith` | T | Chaîne `targetStatus:<id>` · arrondi au plus proche · calcul par cible en AoE · permis sur `draw`/`gain_mana` (filtres 4, 5, 8) | Objet `{source, ratio, statusId}`, arrondi vers le bas ; sources de cible réservées aux cartes `singleEnemy` |
| A12 | Le compteur `cardsPlayedThisTurn` | T | Remise à zéro à l'ouverture du tour · compteur dans le deck (filtre 8) | Dérivé de (tour, nombre) dans `CombatState`, incrémenté par la suite commune |
| A13 | Arrondi de `mightRatio` | T | Au plus proche · vers le haut (filtre 1) | Vers le bas, et `hits ≥ 2 ⇒ ratio < 1` |
| A14 | Rune en pourcentage sur un multi-coups | T | Formule d'E1 coup par coup, plancher multiplié par les coups · tout le bonus au premier coup · répartition vers le bas, qui perd le plancher (filtre 1, D33) | Bonus sur le total, `ceil(bonus / hits)` par coup |
| A15 | Q11 : où compter le bonus unique | T | Un contexte passé à toutes les stratégies (filtre 5) | Dans le résolveur : premier `apply_status` de chaque `statusId` |
| A16 | Où vit `piercing` | T | Dans `DamagePipeline`, qui ne voit pas l'armure (filtre 5) | Un paramètre d'`EntityStats.takeDamage` |
| A17 | `splash` | T | % des dégâts après pipeline · sans pipeline · charges par combat (filtre 6) | % de chaque coup avant pipeline, puis le pipeline de chaque cible, au moins 1 |
| A18 | Rune `lifesteal` et statut de *Soif de Sang* | T | Le plus fort des deux — la rune morte pour un Vampire (revue §7, 2.8) · la rune en statut (filtre 1, D35) | Les deux soignent ; la rune une fois par carte |
| A19 | `echo` | T | Le rejeu déclenche les événements · ne rejoue que les effets propres · garde en Dart (filtres 1, 4) | Une seconde résolution seule ; `excludesEffects` et `excludesRunes` en donnée |
| A20 | `transfusion` | T | Par `heal` (le critique) · avant la résolution · arrondi vers le bas (filtre 5) | 50 % arrondi au supérieur, après l'écho, hors soin ; `requiresCost` |
| A21 | La cible de `splash` | T | Contrôle en dur (filtre 4) | Champ `eligibleTargets` |
| A22 | *Transcendance* sur les runes neuves | T | Un champ `raisable: false` · marquer les runes `binary` (filtres 1, 7) | Règle inchangée ; `piercing` borné à 100 % |
| A23 | `freezing` | T, sous P-1 | Garder 1 point par niveau, qui divise l'effet par deux | `maxLevel: null`, 2 points par niveau |
| A24 | Le modèle des évolutions | T | Réécrire la carte vue dans `SignatureInstance` · un applicateur à part · les évolutions en runes · un fichier par évolution (filtre 5) | `deltas` + `target` + `cooldown` ; `CardInstance.extraDeltas` ; sorte `flatBonus` |
| A25 | La description évoluée | T | Texte fixe et lignes d'évolution · texte entièrement généré · badge ou icônes, affichage neuf que rien n'impose (filtres 6, 7) | Gabarits `{damage}`… ; une évolution « verbale » ajoute sa phrase |
| A26 | Moins de 3 majeures éligibles | T | Proposer moins de 3, comme les runes (filtre 1, D19) | Compléter par des mineures |
| A27 | L'attente des évolutions | T | Un compteur sauvegardé · un enchaînement dans `pendingDrafts`, qu'un abandon rejouerait · écrans chaînés (filtres 5, 8) | Attente dérivée du niveau ; même rideau ; retour à la carte entre deux écrans |
| A28 | Le format de sauvegarde | T | L'instance entière · une migration (filtre 5) | Champ `signatureEvolutions` : {signature: [`id:niveau`]} |
| A29 | Le draft de départ 2 + 3 | T | Cinq cartes imposées · une grille mêlée · l'ordre fixe de la simulation (filtre 6) | Deux groupes, deux quotas |
| A30 | Le tutoriel | T | Garder 5 neutres, infidèle (ADR-081) · recopier les mécanismes dans le jeu simulé (filtres 5, 7) | Suit le 2 + 3 ; la leçon de jeu écarte les cartes à mécanisme |
| A31 | L'éditeur de contenu | T | Éditeur neutre seul, test de compte amendé · une catégorie pour deux sources (filtre 5) | Dixième catégorie `lotCard`, le passif pour propriétaire |
| A32 | Le rendu des cartes | T | La description seule (filtre 6) | Médaillons PV / Armure, badge `3×3`, terme `scaleWith` en combat |
| A33 | Le budget de D38 | T | Les cartes seules (filtre 8) | Cartes et signatures |
| A34 | Le découpage | T | L'ordre de la fiche avec le rendu en partie 1 · les évolutions avant les lots · deux parties (filtre 7) | (1) moteur, cinq runes, statuts ; (2) forme C, lots, rendu, draft, éditeur ; (3) évolutions |
| — | Lecture de Q9 (réponse P) | interprétation, confirmée par l'orchestrateur | Cinq cartes proposées sans choix | Le joueur choisit 2 dans le lot et 3 parmi les neutres (D63) |
| — | *Célérité* sur *Surtension de Mana* | conception | *Célérité* dans les six pools : à recharge 1, +1 Mana par tour (D11) | Absente de ce pool |

**Questions P nées à l'écriture** — la spec se termine autour d'elles (ADR-108 D3) :

| # | Question | Options | Recommandation du rédacteur | Réponse du propriétaire |
|:---:|:---|:---|:---|:---|
| P-1 | Le barème des statuts proportionnels : ce que vaut un point de Vulnérable, de Faiblesse, de Gel | (a) 25 % par point, plafonnés — Vulnérable 4 (+100 %), Faiblesse 2 (−50 %), Gel 3 (−75 %) ; *Trait de Glace* Gel 1 → 2, `freezing` 2 points par niveau, *Marque du Mage* Vulnérable 1 → 2, pour garder l'effet d'aujourd'hui au premier usage · (b) un point vaut l'effet d'aujourd'hui, plafond 2 · (c) sans plafond | (a), appliquée à titre provisoire (§1.4, §4.4) | **(a)**, le 03/11 — écartées : (b), le Gel n'a plus qu'un pas utile et deux points annulent l'attaque ; (c), Faiblesse et Gel à −100 % en un seul jeu. Le propriétaire transfère les charges élémentaires (P-53) au développement de `0.6.0` |
| P-2 | L'affichage des évolutions hors de leur écran (tour 1, n° 3) | (a) aucun affichage neuf : la description porte les valeurs évoluées et la phrase des évolutions verbales · (b) un badge de niveau sur la tuile · (c) badge et icônes (brainstorm §4.4) | (a), appliquée à titre provisoire | **(c)**, le 03/11 — « rien n'est caché » ; écartées : (a), aucun affichage neuf, et (b), le badge seul. La spec est amendée (A35 à A38) puis revérifiée, deux tours |
| P-3 | L'écho déclenche-t-il les événements « carte jouée » — *Flux de Mana*, reliques qui comptent les cartes ? (tour 1, n° 6) | (a) aucun événement : une seconde résolution seule · (b) tous les événements · (c) les passifs seulement | (a), appliquée à titre provisoire | **(a)**, le 03/11 |
| P-4 | L'icône de l'évolution sur chaque rouleau de l'écran d'évolution (née de P-2 (c), tour 1 de l'amendement, n° 1) | (a) l'icône sur le rouleau · (b) aucune — et rien ne relie alors une icône de tuile à son évolution | (a), appliquée à titre provisoire | **(a)**, le 03/11 |

**Arbitrages de l'orchestrateur, tour 1** — options écartées :

| # | Question | Classe | Options écartées, et le filtre qui les écarte | Retenu |
|:---:|:---|:---:|:---|:---|
| C1.1 | Q11 à la lettre (« par carte ») et l'écho | T | Un bonus par statut, la lecture d'origine (contredit la réponse du propriétaire) · aucun bonus sur l'écho · le bonus au premier statut posé sur un ennemi, une règle que la réponse ne dit pas (filtre 6) | Par résolution, le premier `apply_status`, tous statuts confondus ; l'écho, seconde résolution, a le sien |
| C1.2 | *Transcendance* sur les runes neuves | T | Reclasser P · un champ « non relevable » en donnée (filtre 4) | La règle d'E3 telle quelle (D42(c), « une rune ») ; une rune dont chaque delta est saturé (`piercing` à 100 %) n'est pas tirée |
| C1.3 | Un coût combiné touche-t-il `feeds` ? | T | Reclasser D · ajouter `damage` aux `feeds` de Rempart et de Sang, trop large (filtre 1, D45, P2) | Lecture de D45 : le coût est une part de la résolution (§9.1) ; sans elle *Percée*, imposée par la fiche, échouerait |
| C1.4 | Plancher de D33 sur `piercing` et `lifesteal` (rédacteur, n° 8) | T | Pas de plancher · plancher non borné · arrondi vers le bas (filtre 1) | Plancher L, borné par l'Armure présente ou les dégâts infligés |
| C1.5 | Majeure ramenée à 1 ou retirée pour exclusion, à la reprise (rédacteur, n° 14) | T | La signaler dans `MissingSaveItem` · une catégorie et un message neufs (filtre 6) | Sans rapport : le message existant dirait faux |
| C1.6 | Les clés du draft de départ (rédacteur, n° 12) | T | Garder les deux · supprimer les deux (`CardDraftLayout` exige un compteur) (filtre 5) | `draftDeckSnackbarMax` supprimée ; `draftDeckSelectedCount` gardée |
| C1.7 | Formes en tranches de `scaleWith` (rédacteur, n° 11) | T | Un format ICU paramétré par la forme (filtre 6) | Deux clés par source |
| C2.1 | Un `ratio` sous 1 dont l'inverse n'est pas entier (rédacteur, tour 2 n° 3) | T | Arrondir `per` dans le texte, qui afficherait une tranche fausse · une forme décimale qui tait l'arrondi (filtre 6) | Refusé au chargement, à 10⁻⁹ près |
| C2.2 | Les textes de la galerie des statuts du tutoriel (rédacteur, tour 2 n° 2) | T | Des clés sœurs propres à la galerie : deux textes pour un barème (filtre 5) | Les mêmes clés `status…Hint`, sans parenthèses |

**Arbitrages de l'amendement P-2 (c), 03/11** — options écartées :

| # | Question | Classe | Options écartées, et le filtre qui les écarte | Retenu |
|:---:|:---|:---:|:---|:---|
| A35 | Où vit l'icône d'une évolution | T | Une table Dart par id d'évolution · une `IconData` construite depuis une chaîne, élaguée en release · les tables des runes · valider les noms au chargement, le modèle lirait `lib/ui/` (filtres 4, 5) | `icon` et `color` en donnée, qui nomment deux tables `const` propres, gardées par le test d'intégrité, comme les runes |
| A36 | Le badge de niveau | T | Sous le médaillon de coût · une ligne à lui · ⌊niveau / 5⌋ · des étoiles · au bout de la ligne du nom, qui coupait les noms longs sur la tuile étroite (tour 1, n° 5) (filtre 6) | `SignatureInstance.level`, « Niv. N » au bout de la ligne du type, par `levelLabel` réécrite ; absent au niveau 0 |
| A37 | La rangée d'icônes | T | Une colonne sous le médaillon · une rangée qui passe à la ligne · une puce « +k » · « ×2 » à côté de l'icône · aucune distinction mineure / majeure (filtres 6, 8) | Une puce par évolution distincte, ordre de prise, anneau sur une majeure, chiffre sur une mineure dès 2 ; sept puces au plus, sans débordement |
| A38 | La hauteur de la barre | T | Centrer dans la bande (la barre montait de 60 px et perdait le miroir du bouton de fin de tour, tour 1, n° 2) · borner la description · un défilement · peindre sous le panneau (filtres 6, 7) | Centrée à mi-hauteur, décalée seulement si elle sort de la bande, réduite d'un bloc mesuré, plancher 0,75 ; au plancher, sur un écran d'environ 400 px, elle peut couvrir le haut du HUD du bas — limite acceptée par l'orchestrateur |

## Pour le Review Focus des plans

Remontés par la vérification de la spec — des trous de test, pas des constats (ADR-108 D2) ; chaque plan reprend ceux de sa partie.

- `real_bundle_load_test.dart:102-104` : les runes à `maxLevel == 1` passent de `[cheap, eco, enduring, freezing, quick]` à `[cheap, eco, enduring, quick, transfusion]` dès la partie 1 (tour 1).
- `forge_upgrades_catalog_test.dart:190-193` : sa matrice nomme `focus` et `demon_form` (tour 1).
- `EffectiveCard._withValue` (`effective_card.dart:139-144`) reconstruit `CardEffect` sur quatre champs et perdrait `hits`, `mightRatio`, `scaleWith` : tester multi-coups et `scaleWith` par `card.effective` et `resolveCard`, pas seulement `fromJson` (tour 1).
- Forme C : une neutre qui déclare `"passive": null` est refusée ; une carte de lot en `costs` survit à l'aller-retour de `DeckState._decodePile` (`deck_controller.dart:72-99`) (tour 1).
- Écho : ne dispatche aucun passif (sous P-3 provisoire), ne paie rien, ne bouge aucune pile, vise la même cible (tour 1).
- `splash` : un critique par cible, `piercing` appliqué, éclaboussures comptées dans le vol de vie, statut et rune (tour 1).
- `nextPendingEvolution` : Châtiment puis Bouclier Sacré au niveau 5 ; mineures puis majeures sur un saut de 4 à 10 (tour 1).
- Hors combat, `SignatureTile` (dictionnaire, sélection de classe) n'affiche jamais un gabarit brut (« {damage} ») (tour 1).
- Les registres de test construits à la main (`class_selection_screen_test`, tutoriel, `passive_absent_test`) et `passives_*_test` (`:210`, `:252`, `:365`) portent des cartes de lot, sinon le masquage leur retire leurs passifs (tour 1).
- Refus à l'écran par `hero_card.dart:87` (carte sur soi) et `signature_bar.dart:114` (`signature.cost` évolué) (tour 1).
- `consumeResource` : la signature du relais `run_controller.dart:558` change ; son appelant est `passives_mage_test.dart:141` (tour 1).
- D50 : le test compte par passif pourvu d'un lot, signatures exclues (tour 1).
- `raisableCaps` : `piercing` à 4, `lifesteal` à 5 et `echo` à 7 écartés ; `splash` 3 et `echo` 4 proposés (tour 2).
- Q11 sur une signature qui porte deux statuts d'évolution (*Projectile Magique* avec `ember` et `exposure`) : un seul bonus, sur le premier dans l'ordre des effets ajoutés (tour 2).
- La galerie des statuts du tutoriel lit le barème : changer une valeur du barème change son texte (tour 2).
- Écho sur une carte `singleEnemy` dont la cible meurt à la première résolution : le sort de ses effets sur soi (l'Armure de *Châtiment*) (tour 2).
- Écran d'évolution, mineure déjà prise : `{val}` au prochain niveau (*Zèle* 1 → 2 affiche « +4 dégâts ») et la ligne « 1 → 2 » (tour 2).
- Infobulle Flame : les trois parenthèses de statut lues sur le barème, en partie 1 (tour 2).
- `scale_with_test` : 0,3 refusé au chargement ; 0,2, 0,1, 1 et un ratio supérieur à 1 acceptés (tour 3).
- La galerie (Gel) et le tableau (Vulnérable, Faiblesse) du tutoriel lus sur le barème : un test de widget plutôt que `damage_pipeline_test.dart` (tour 3).
- Le corps des étapes « Les Effets Élémentaires » et « Les Intentions Ennemies » ne chiffre plus le Gel (tour 3).
- Infobulle Flame sans `buildContext` : le `fallback` de `getTranslation` (`card_component.dart:110-122`, vide par défaut) donnerait « () » — le remplir depuis le barème, ou ne rien écrire (tour 3).
- `{val}` d'une majeure `reduceCost` : `min(coût, valuePerLevel)` (*Dévotion* sur *Châtiment*, coût 1 → 1) (tour 3).
- `raisableCaps` sur `lifesteal` 4 et `echo` 6 : proposés, le relèvement a encore un effet (tour 3).
- `test/tutorial/tutorial_prose_test.dart` : en français et en anglais, ni « divise par deux », ni « halves », ni pourcentage dans les étapes `elements` et `enemies` (tour 4).
- Le tableau `_missingStatuses`, rendu en `:465`, une fois ses entrées non `const` : le test de widget couvre Vulnérable et Faiblesse, en plus du Gel de la galerie ; §9 range encore cette lecture dans `damage_pipeline_test.dart` (tour 4).

Remontés par la vérification de l'amendement P-2 (c), le 03/11 — partie 3 :

- *Célérité* porte la même `icon`, la même `color` et le même texte dans ses cinq pools : un test « même id ⇒ même icône, même couleur, même texte ».
- Le gabarit d'éditeur de la signature (`entity_descriptor.dart:264-274`) n'a pas d'`evolutions` : avec `evolutions`, `icon` et `color` exigés, `entity_validator_test.dart:616`, `entity_descriptor_test.dart:247` et `:390` rougissent — le gabarit porte une évolution complète.
- La barre réduite (`FittedBox`) : un toucher sur une tuile réduite joue ou arme encore, l'invite reste visible sous la colonne (S10) ; un cas à H ≈ 400.
- Au niveau 0 et en 1280 × 800, la colonne n'a pas bougé par rapport à `0.5.6`.
- Le badge sur la tuile étroite, à la vraie police : à vérifier à la main (tests manuels).
- L'aller-retour de sauvegarde garde l'ordre de première prise, que la rangée lit.
- Chaque entrée d'`evolutionIcons` et d'`evolutionColors` sert au moins une évolution.
- Sous P-4 (a) : le paramètre de `DraftCardReel` est facultatif, le draft de niveau ne change pas.

## Le journal des tours

| Tour | Mode | Vérificateur | Bloquants | Moyens | Mineurs | Rédaction | Corrigé | Contesté, tranché |
|:---:|:---|:---|---:|---:|---:|---:|:---|:---|
| 1 | complet | neuf, seul | 0 | 2 | 16 | 2 | Les 18 constats à corriger, par la rédactrice reprise ; aucun contesté. Les deux moyens : Q11 appliquée par statut alors que la réponse dit « par carte » ; l'infobulle et le badge de la face Flame absents du rendu | **Tranchés par l'orchestrateur** : C1.1 (T), C1.2 (T), C1.3 (T, lecture de D45) ; n° 3 et n° 6 reclassés **P** → P-2, P-3 ; n° 5 (lecture de Q9) sans correction, au compte rendu. Confirmés : C1.4 à C1.7, tranchés à la correction |
| 2 | différentiel | neuf, seul | 0 | 2 | 2 | 3 | Les sept, par la rédactrice reprise ; aucun contesté. Les deux moyens : la saturation de *Transcendance* oubliait `lifesteal` et `echo` ; la galerie des statuts du tutoriel gardait son barème en dur | Confirmés : C2.1, C2.2, tranchés à la correction. Les corrections du tour 1 tiennent, P-1 à P-3 tiennent sous leur option provisoire |
| 3 | différentiel | neuf, seul | 0 | 1 | 1 | 2 | Les six corrections du tour 2 tiennent. Le moyen : le corps des étapes « Les Effets Élémentaires » et « Les Intentions Ennemies » écrit encore « divise par deux » pour le Gel ; le mineur : « sans texte à réécrire » faux sous P-1 (c) ; deux rédactions (un fait écrit trois fois, la règle du `ratio` deux fois) | **Trois tours sans convergence, constats T seulement — autonomie `continu`** : l'orchestrateur applique la correction recommandée de chacun, telle quelle (consignée à part dans le compte rendu) — §4.4, §5.2, §6.1, §6.2 (deux lignes), §3.1 —, puis un dernier tour différentiel |
| 4 | différentiel, dernier tour de l'autonomie `continu` | neuf, seul | 0 | 0 | 2 | 1 | **Prête.** Les quatre corrections du tour 3 tiennent ; 2 mineurs (« jusqu'à un plafond » dans la prose du Gel ; §10 nomme le tableau et la prose du tutoriel en partie 1) et 1 rédaction (« reduces », pas « weakens », en anglais) corrigés au passage par l'orchestrateur | — |
| — | réponse du propriétaire, 03/11 | — | — | — | — | — | P-1 (a) écrite en §1.2, retirée de §1.4 ; A23 et le titre de §4.4 alignés. **Pas de tour de vérification** : la réponse est la recommandation déjà appliquée. P-2 et P-3 restent ouvertes | — |
| P-2 · 1 | différentiel, amendement P-2 (c) | neuf, seul | 0 | 2 | 7 | 2 | Les onze, par la rédactrice reprise. Les deux moyens : l'icône du rouleau verrouillée sans question (→ **P-4**, classe P) ; la barre qui montait de 60 px à tous les niveaux | n° 9 (l'icône de *Carapace*) reclassé de D en T par l'orchestrateur : les icônes relèvent du rôle `game_designer`, comme les valeurs et les noms. Tranchés à la correction et confirmés : l'échelle plancher 0,75, la constante du haut de bande sur `CombatTopBar` |
| P-2 · 2 | différentiel, les onze corrections | neuf, seul | 0 | 0 | 6 | 6 | **Prête.** Six mineurs (l'ordre du calcul d'A38, la raison du plancher, la définition de H, le HUD du bas au plancher, `DraftChoiceCard`, le point de « Niv. ») et six rédactions corrigés au passage par la rédactrice reprise | Choix de l'orchestrateur : le plancher reste 0,75 ; le recouvrement du HUD du bas au plancher est une limite acceptée ; `levelLabel` réécrite avec le point |
| — | réponses du propriétaire, 03/11 | — | — | — | — | — | P-3 (a) et P-4 (a) écrites en §1.2, §1.4 vidée, A19 et §5.1 alignés. **Pas de tour de vérification** : les réponses sont les recommandations déjà appliquées | — |
