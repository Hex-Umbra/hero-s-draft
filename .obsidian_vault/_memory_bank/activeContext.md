<!-- last-sync: 2026-10-02 | commit: 82f902f -->

# 🧠 Contexte Actuel

> [!IMPORTANT]
> **Plafond : 240 lignes.** Focus courant, **3 dernières livraisons au maximum**, prochaine étape. Une 4ᵉ livraison pousse la plus ancienne vers `../_archive/`. Ce fichier ne contient jamais de backlog — voir `docs/ROADMAP.md`.

## Focus courant

**La vague 2 du programme P-43 → P-42 → P-44 lot 1 est livrée sur sa branche,
`feat/v0.5.4-p43-e2-fusion-forge`, et attend le propriétaire** : son test manuel, la PR, la fusion
dans `main`, puis le tag. Elle porte le troisième lot de P-43 « Économie unifiée », **E2 —
« fusion = forge »** ([ADR-106](../_adr/ADR-106-fusion-egale-forge.md)) : la fusion donne la rune,
le feu de camp l'affûte, le Puits d'échange remplace la Forge de Fusion, la boutique vend la copie
d'une carte du deck — **la boucle de jeu change**. **Rien n'en est fusionné ni publié** : `main`
reste à `559df08`, et tout ce que le vault dit d'E2 n'y deviendra vrai qu'à la fusion. Le
[compte rendu de la vague](../../docs/superpowers/reports/2026-10-02-economie-et-catalogue-vague-2-compte-rendu.md)
porte la table des arbitrages, que le propriétaire lit au moment de son test (§2) ; le cahier de
test manuel et les statistiques de la session s'y ajoutent à la fin de la vague (orchestration
§3.8). **Un arbitrage qu'il renverse se corrige sur la branche avant la fusion**, et ses documents
— note de version, ADR — se rouvrent en place tant que la vague n'est pas taguée (orchestration
§3.10).

**La vague 1 est close** : fusionnée dans `main` le 2026-10-02 par la PR #47 (commit de fusion
`559df08`), taguée sur ce commit, CI/CD verte — `release.yml` run `36987477053` vert, release
publiée en pré-release le même jour —, constatée par la porte d'entrée de la vague 2 (`a9e2db6`)
et re-vérifiée par `gh` à cette synchronisation. ADR-104 et ADR-105 sont désormais vrais sur
`main`.

**La méthode est celle d'[ADR-102](../_adr/ADR-102-chantier-par-vagues-une-version-par-vague.md),
amendée par [ADR-103](../_adr/ADR-103-vagues-fusion-puis-tag-reference-de-simulation-suivi.md)** :
une vague par version du jeu, une session par vague, un orchestrateur qui délègue et arbitre ; le
propriétaire teste, fusionne, puis tague ; la simulation se compare à sa sortie de référence ;
chaque vague laisse un compte rendu et une section non technique dans
`docs/suivi_vagues_chantier/`. **Deux documents font foi, et ne se recopient pas** : le
[fichier d'orchestration](../../docs/possible_upgrades/01-10-2026_orchestration_chantier_economie_et_catalogue_Fable5.md)
pour le *déroulé* — vagues, versions, journal d'avancement — et le
[brainstorm v3](../../docs/possible_upgrades/22-09-2026_brainstorm_heros_et_cartes_v3_Fable5.md)
pour les *décisions de conception*. `docs/ROADMAP.md` garde une ligne par chantier et ne bouge
qu'à la clôture d'une ligne — P-43 se clôt en vague 4.

Réserves à ne pas perdre de vue :

- **Ce que la vague 2 laisse ouvert**, consigné dans ADR-106 et au compte rendu §5 : **les fusions
  restent rares jusqu'à la vague 3** — la forge du feu a disparu, la trouvaille n'existe pas
  encore ; *Précis* au niveau 10 ajoute 50 points de critique, une carte du Berserker peut devenir
  critique à coup sûr — à regarder au test ; *Spectral* sur une carte qui s'épuise déjà, et la
  paire *Spectral* / *Persistant*, attendent les cartes de lot de la vague 5 ; le rendu Flame
  recalcule le coût courant à chaque image ; le libellé anglais « SHARPEN » du feu côtoie la
  récompense de niveau « Sharpening ».
- **Ce que la vague 1 laisse ouvert**, consigné dans ADR-104 et ADR-105 : les icônes de statut
  des ennemis supposent une entrée par `id` — une carte qui donnerait de la Puissance à un ennemi
  casserait cet invariant ; l'éligibilité des runes élémentaires ne lit pas la cible de la carte ;
  *Talisman de fer* et *Encensoir* ne donnent aucune Puissance au Berserker (défaut antérieur, à
  ouvrir en ticket). Ses trois points « pour E2 » sont tenus par ADR-106.
- **Un test peut-être instable** : `test/widget/content_editor_screen_test.dart`, groupe des
  imports, a échoué une fois dans une suite complète pendant la vague 1 ; vert dans la suite
  complète de cette synchronisation. À surveiller.
- **⚠️ Les lots 1-2 de P-48 cassent toujours les sauvegardes antérieures à leurs ids de passifs en
  `snake_case`** (commit `7da5db2`). P-41 lot A a posé une chaîne de migration (`SaveMigrator`) et
  changé de clé de stockage (`run_save`, repli sur `run_save_v1`), mais sa seule étape migre
  `attaque` → `attackPower` : l'id de passif n'y est pas touché, et une partie d'avant `7da5db2` perd
  toujours son passif de classe au chargement, signalé par un `MissingSaveItem`. La note de version
  reste le seul canal qui prévienne *avant*.
- **La version se lit dans `pubspec.yaml` et la 1ʳᵉ entrée de
  `assets/data/patch_notes.json`, jamais ici.** Sur la branche de la vague 2, les trois porteurs de
  version portent déjà la sienne (`4e4fa5c`), **ni taguée ni publiée** ; sur `main`, celle de la
  vague 1, publiée. Les versions que visent les vagues font foi dans le fichier d'orchestration, §1.
- **Une vague vérifie par `gh` que la précédente est taguée et que sa CI/CD est verte.** Le
  2026-10-01, `gh` a échoué une fois à joindre l'API GitHub depuis la session, puis a répondu.
  Si cela se reproduit à une porte d'entrée, c'est le propriétaire qui confirme, et le journal
  le note — la porte ne suppose jamais.
- **Les tiers A, B, C et E de `docs/ROADMAP.md` n'ont toujours pas été re-vérifiés contre le
  code** — seuls S et D l'ont été (2026-08-04).
- **Bouton de téléchargement mort** si le build Windows échoue quand le web réussit — correctif
  identifié, non fait, voir [ADR-080](../_adr/ADR-080-site-vitrine-pilote-par-la-donnee-et-jointure-decl.md).

## 3 dernières livraisons

1. **Vague 2 — P-43 lot E2 : la fusion donne la rune, le feu affûte, le Puits échange, la boutique
   copie** (2026-10-02, branche `feat/v0.5.4-p43-e2-fusion-forge`, 27 commits `a9e2db6` → `82f902f`
   sur `main` à `559df08` — **livrée sur la branche, vague 2 du fichier d'orchestration, en attente
   du test, de la PR, de la fusion et du tag du propriétaire**) — **la rune ne s'obtient plus au
   feu : elle naît de la fusion.** Chaque fusion 3 → 1 garde toutes les runes de ses trois
   exemplaires et en **offre une parmi trois**, au niveau 1, tirées au rang que la carte atteint ;
   une seule rune de chaque type par carte, *Véloce* et *Économe* à partir de la deuxième fusion
   (`minFusionRank`). Le feu de camp **affûte** : une rune gagne un niveau pour 50 or × son niveau.
   Le **Puits d'échange**, tous les trois actes, remplace la Forge de Fusion : une rune contre toute
   autre permise, aux deux tiers de son niveau, pour 50 or × le niveau donné. La boutique vend **la
   copie d'une carte du deck** et **retient son étal à son nœud** — la décision du propriétaire, à
   la levée de l'arrêt de la spec. Trois runes neuves, *Allégé*, *Précis*, *Spectral*, et trois
   sortes de delta. **Disparaissent** : la forge du feu — fentes, relances, fentes achetées, sa
   session dans `RunState` —, la capacité de runes, `pools`, `stackable`. Deux défauts antérieurs
   se ferment au passage : le second repos par le retour système, le retirage gratuit de l'étal.
   `ShopController` devient le premier Notifier du dossier des contrôleurs à écouter un autre
   provider (`ref.listen`, pas `ref.watch`). **La spec ne converge qu'au quatrième tour** : la
   troisième vérification a rendu deux constats moyens, la vague s'est arrêtée, le propriétaire a
   levé l'arrêt. La simulation, relancée en deux temps : le réalignement rend sa référence à
   l'identique, le *Spectral* du script aligné sur le jeu change 477 lignes sur 798, écart
   expliqué, référence recommitée. Note de version écrite (`4e4fa5c`). **1480 tests** (+105 sur la
   base de **1375**, celle de la porte d'entrée), `dart analyze` propre (**vérifié le
   2026-10-02**) — [ADR-106](../_adr/ADR-106-fusion-egale-forge.md), qui amende ADR-074, ADR-094,
   ADR-105 et ADR-067, et rend caducs ce qui restait d'ADR-025, ADR-039 D1 et D3, ADR-024 point 4.
2. **Vague 1 — P-43 lots E0 et E1 : la Puissance par source, le `ratio`, et le moteur de runes en
   donnée** (2026-10-01 → 2026-10-02, branche `feat/v0.5.3-p43-e0-e1`, 22 commits `0f56cd4` →
   `52cba87` sur `main` à `0ccacce` — **fusionnée dans `main` le 2026-10-02 par la PR #47, merge
   `559df08`, taguée, CI/CD verte, release publiée**) — **la Puissance garde la
   durée de ce qui la donne, et une rune devient un fichier.** *E0* : un statut retient sa source,
   et `addStatus` ne fusionne plus que même statut **et** même source — seule la Puissance en
   reçoit une ; *Forme Démoniaque* puis *Mur de Fer* donnent 7 ce tour-ci puis 2, au lieu de 12
   pendant quatre tours. La règle de classe gagne un `ratio` borné à ]0, 1] : le Berserker convertit
   la moitié de son Armure, arrondie au-dessus, et sa règle le dit en clair. *E1* : une rune
   déclare son effet en **deltas typés** (`percentBonus`, `addEffect`, `removeExhaust`), qu'un
   **applicateur unique**, `EffectiveCard`, calcule pour le moteur, les rendus de carte et le tutoriel ;
   son éligibilité par **un prédicat** lu dans la donnée, exclusions symétriques comprises ; son
   plafond par **`maxLevel`**, borné aux quatre endroits qui écrivent un niveau. *Tranchant* et
   *Endurci* passent à +15 % de la base, au moins +1 ; G1 fait gagner au moins 1 par fusion à tout
   chiffre que la rareté multiplie, G2 gèle la pioche et le mana ; les statuts des runes
   élémentaires fusionnent avec ceux de la cible ; le feu refuse une carte qui ne peut plus
   recevoir de rune. **La revue d'ensemble a trouvé un trou** — la fusion de cartes réunissait
   *Persistant* et *Économe*, que le prédicat interdit ensemble : corrigé avant la note (`ee814e9`).
   La simulation, relancée en un seul temps, rend sa référence à l'identique (compte rendu §4) :
   E0 et E1 n'y changent rien qu'elle lise. Note de version écrite (`52cba87`). **1375 tests** (+188
   sur la base de **1187**, re-mesurée sur `main` à `0ccacce`), `dart analyze` propre (**vérifié le
   2026-10-02**) — [ADR-104](../_adr/ADR-104-un-statut-par-source-et-ratio-de-conversion.md),
   [ADR-105](../_adr/ADR-105-moteur-de-runes-data-driven.md), qui amende ADR-094.
3. **Le dossier du programme — brainstorm v3, revue, simulation, méthode par vagues**
   (2026-09-22 → 2026-10-01, directement sur `main`, depuis `3cd743f` — les deux dernières passes
   de revue entrent par le commit qui suit `25c36ba` —, **documentation et outillage seulement**)
   — **le programme a désormais une conception entière et un déroulé.** Le
   brainstorm v3 remplace celui du 05/08 : ses décisions acquises, D1 à D75, refondent l'économie
   de deck — la fusion devient le moteur de progression et donne la rune, le feu de camp affûte, une
   carte se trouve après chaque combat, les signatures quittent le deck pour devenir des
   compétences de classe, chaque passif reçoit son lot de cartes. Sa
   [revue](../../docs/possible_upgrades/29-09-2026_revue_brainstorm_v3_heros_et_cartes_Fable5.md)
   l'a vérifié contre le code puis relu quatre fois après chaque vague de décisions ; la quatrième
   passe n'a trouvé aucune contradiction, et ses deux constats de fond sont venus de la lecture des
   chemins de code, pas du document. **Un outil entre dans le dépôt** :
   `tool/simulations/d26_economy_sim.dart`, qui a mesuré les valeurs d'économie retenues et
   contredit six prémisses du brainstorm — dont celle d'un deck qui gonfle : la fusion en est le
   puits ([rapport](../../docs/possible_upgrades/30-09-2026_simulation_D26_economie_Fable5.md),
   [`_patterns/20-00`](../_patterns/20-00-simulation-de-l-economie-de-deck.md)). **La ROADMAP est
   redécoupée** : P-43 « Économie unifiée » passe premier, P-42 devient le catalogue par lots de
   passif, P-44 compte quatre lots dont le premier se livre avec P-42 ; P-18 perd ses deux derniers
   points, P-16 hérite de cinq constats de la simulation. **Trois fiches de règles rattrapent le
   code** au passage — `might` au lieu de `strength`, `eco` qui rend du mana à la pose, une boucle
   qui ne promet plus de carte après un combat normal. **Aucun effet joueur, aucune note de
   version.** **Une cinquième passe, le même jour, a relu le fichier d'orchestration lui-même**
   avant de lancer la première vague : le fond tenait, le mode d'emploi a été corrigé. **Une
   sixième a rejoué le fichier corrigé** — la porte d'entrée de la vague 1 passe, la simulation
   relancée rend sa référence à l'identique — et trouvé une prémisse que le code dément : le
   plafond de niveau d'une rune ne tient pas par la seule fusion de cartes, il se pose aux quatre
   endroits qui écrivent un niveau.
   **1187 tests**, inchangés, `dart analyze` propre (**vérifié le 2026-10-01**) —
   [ADR-102](../_adr/ADR-102-chantier-par-vagues-une-version-par-vague.md),
   [ADR-103](../_adr/ADR-103-vagues-fusion-puis-tag-reference-de-simulation-suivi.md).
> [!NOTE]
> **Rotations.** Sorties le 2026-10-02, dans `../_archive/` : `2026-10-02-activeContext-livraisons-2.md`
> (le filtre de classe sur les pools d'offre) et `2026-10-02-activeContext-livraisons.md`
> (P-41 lot D partie 2). Sortie le 2026-10-01 : `2026-10-01-activeContext-livraisons.md`
> (P-41 lot D partie 1). Sortie le 2026-09-21 : `2026-09-21-activeContext-livraisons.md`
> (P-41 lot C partie 2). Sorties le 2026-09-20 : `2026-09-20-activeContext-livraisons-3.md`
> (P-41 lot C partie 1), `2026-09-20-activeContext-livraisons-2.md` (lot B partie 2) et
> `2026-09-20-activeContext-livraisons.md` (lot B partie 1, avec quatre réserves closes). Sorties
> le 2026-09-18 : `2026-09-18-activeContext-livraisons-2.md` (P-49) et
> `2026-09-18-activeContext-livraisons.md` (P-41 lot A). Les onze rotations précédentes portent le
> même nom, daté du 2026-09-17 au 2026-08-20.

## Prochaine étape

**D'abord le propriétaire, sur la vague 2** : il joue le cahier de test du
[compte rendu](../../docs/superpowers/reports/2026-10-02-economie-et-catalogue-vague-2-compte-rendu.md),
une fois la fin de vague écrite (orchestration §3.8), lit la table des arbitrages (§2), ouvre la PR
de `feat/v0.5.4-p43-e2-fusion-forge`, la fusionne dans `main`, puis pose le tag sur le commit de
fusion (ADR-103 D1). Une correction demandée se fait sur la branche, avant la fusion.

**Puis la vague 3 du fichier d'orchestration** : le lot E3 de P-43, « trouvaille et progression »
— une carte après chaque combat, qui rend les fusions fréquentes, `maxHandSize`, l'XP, la difficulté
adaptative sur la somme des rangs, les sources d'affûtage hors du feu. Elle se lance dans une
session neuve, par le prompt unique du §0 de l'orchestration, et **sa porte d'entrée attend le tag
de la vague 2** : tag ancêtre de `main`, CI/CD verte, constatée par `gh` — et c'est elle qui notera
la vague 2 close. Elle hérite d'ADR-106 : `canSharpen`, `boundLevel` et la réécriture `id:n →
id:n+1` pour les sources d'affûtage neuves ; `fusionRank`, que lisent le prédicat, G1 et la borne
des pré-forgées, pour la difficulté adaptative. Côté simulation, le script lira la table d'XP du
jeu, et l'écart « attendu d'avance » de la ligne « Données lues » est probablement nul (compte
rendu de la vague 2, §5).

Une question reste tenue dans `docs/ROADMAP.md` §4, hors programme : la **Maîtrise dans l'onglet
Héros du menu de debug**, laissée hors du lot D partie 2 de P-41 alors qu'elle pilote tout P-49.

Le Jalon 2 « Feel & contenu » (`docs/ROADMAP.md` §9) reste ouvert : P-06, P-07, le prototype de
P-08, P-05 — dont dépendent les lots 2 à 4 de P-44, après le programme. **P-07 doit lire
[ADR-083](../_adr/ADR-083-latence-et-synchronisation-du-chemin-de-lecture.md) D6 avant de toucher
aux animations.**
