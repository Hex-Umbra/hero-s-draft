<!-- last-sync: 2026-10-02 | commit: 52cba87 -->

# 🧠 Contexte Actuel

> [!IMPORTANT]
> **Plafond : 240 lignes.** Focus courant, **3 dernières livraisons au maximum**, prochaine étape. Une 4ᵉ livraison pousse la plus ancienne vers `../_archive/`. Ce fichier ne contient jamais de backlog — voir `docs/ROADMAP.md`.

## Focus courant

**La vague 1 du programme P-43 → P-42 → P-44 lot 1 est livrée sur sa branche,
`feat/v0.5.3-p43-e0-e1`, et attend le propriétaire** : son test manuel, la PR, la fusion dans
`main`, puis le tag. Elle porte les deux premiers lots de P-43 « Économie unifiée » — **E0**, la
Puissance par source et le `ratio` de conversion
([ADR-104](../_adr/ADR-104-un-statut-par-source-et-ratio-de-conversion.md)), et **E1**, le moteur
de runes en donnée ([ADR-105](../_adr/ADR-105-moteur-de-runes-data-driven.md)) — sans changer la
boucle de jeu. **Rien n'en est fusionné ni publié** : `main` reste à `0ccacce`, et tout ce que le
vault dit de E0 et E1 n'y deviendra vrai qu'à la fusion. Le
[compte rendu de la vague](../../docs/superpowers/reports/2026-10-02-economie-et-catalogue-vague-1-compte-rendu.md)
porte la table des arbitrages, que le propriétaire lit au moment de son test (§2), et le cahier de
test manuel (§3) ; **un arbitrage qu'il renverse se corrige sur la branche avant la fusion**, et
ses documents — note de version, ADR — se rouvrent en place tant que la vague n'est pas taguée
(orchestration §3.10).

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

- **Ce que la vague 1 laisse ouvert**, consigné dans ADR-104, ADR-105 et au compte rendu §5 : les
  icônes de statut des ennemis supposent une entrée par `id` — une carte qui donnerait de la
  Puissance à un ennemi casserait cet invariant ; l'éligibilité des runes élémentaires ne lit pas
  la cible de la carte ; *Talisman de fer* et *Encensoir* ne donnent aucune Puissance au Berserker
  (défaut antérieur, à ouvrir en ticket) ; **pour E2** — l'héritage de la fusion devra suivre la
  règle d'exclusion de `consolidate`, la relance payante est sans effet sur les cartes à une seule
  rune éligible, et les descriptions des runes à effet ajouté écrivent leur niveau.
- **Un test peut-être instable** : `test/widget/content_editor_screen_test.dart`, groupe des
  imports, a échoué une fois dans une suite complète pendant la vague (compte rendu §5) ; vert dans
  la suite complète de cette synchronisation. À surveiller.
- **⚠️ Les lots 1-2 de P-48 cassent toujours les sauvegardes antérieures à leurs ids de passifs en
  `snake_case`** (commit `7da5db2`). P-41 lot A a posé une chaîne de migration (`SaveMigrator`) et
  changé de clé de stockage (`run_save`, repli sur `run_save_v1`), mais sa seule étape migre
  `attaque` → `attackPower` : l'id de passif n'y est pas touché, et une partie d'avant `7da5db2` perd
  toujours son passif de classe au chargement, signalé par un `MissingSaveItem`. La note de version
  reste le seul canal qui prévienne *avant*.
- **La version se lit dans `pubspec.yaml` et la 1ʳᵉ entrée de
  `assets/data/patch_notes.json`, jamais ici.** Sur la branche de la vague 1, les trois porteurs de
  version portent déjà la sienne (`52cba87`), **ni taguée ni publiée** ; sur `main`, la dernière
  publiée. Les versions que visent les vagues font foi dans le fichier d'orchestration, §1.
- **Une vague vérifie par `gh` que la précédente est taguée et que sa CI/CD est verte.** Le
  2026-10-01, `gh` a échoué une fois à joindre l'API GitHub depuis la session, puis a répondu.
  Si cela se reproduit à une porte d'entrée, c'est le propriétaire qui confirme, et le journal
  le note — la porte ne suppose jamais.
- **Les tiers A, B, C et E de `docs/ROADMAP.md` n'ont toujours pas été re-vérifiés contre le
  code** — seuls S et D l'ont été (2026-08-04).
- **Bouton de téléchargement mort** si le build Windows échoue quand le web réussit — correctif
  identifié, non fait, voir [ADR-080](../_adr/ADR-080-site-vitrine-pilote-par-la-donnee-et-jointure-decl.md).

## 3 dernières livraisons

1. **Vague 1 — P-43 lots E0 et E1 : la Puissance par source, le `ratio`, et le moteur de runes en
   donnée** (2026-10-01 → 2026-10-02, branche `feat/v0.5.3-p43-e0-e1`, 22 commits `0f56cd4` →
   `52cba87` sur `main` à `0ccacce` — **livrée sur la branche, vague 1 du fichier d'orchestration,
   en attente du test, de la PR, de la fusion et du tag du propriétaire**) — **la Puissance garde la
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
2. **Le dossier du programme — brainstorm v3, revue, simulation, méthode par vagues**
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
3. **Le filtre de classe sur les pools d'offre — un prédicat, deux appels, un piège gardé**
   (2026-09-21, branche `fix/filtre-cartes-de-classe`, commit `3727f09`) — **la règle « une classe
   ne se voit proposer que ses propres cartes de signature » cesse de n'avoir aucun domicile.** Le
   prédicat d'éligibilité était recopié mot pour mot en boutique et au bonus de boss `doubleXp`, et
   aucun des deux `Notifier` ne lisait `runProvider.heroClassId` : c'était la cause, plus que le
   défaut — rien n'aurait rappelé la condition de classe au troisième pool créé.
   `CardData.isOfferableTo` porte désormais la règle entière, et **ne teste que `heroClass`, jamais
   `category` en plus** : le chargeur injecte les deux depuis le même chemin de fichier, les tester
   tous les deux ferait croire à deux conditions. **Le draft de départ reste délibérément dehors**,
   sur `category == global` — les signatures y sont ajoutées d'office par `getHeroCards`, les offrir
   aussi les rendrait prenables deux fois ; le test qui le garde a été **vérifié en appliquant la
   correction fautive**, qui le fait passer de 10 à 11 cartes offertes. **Aucun effet joueur, et
   aucune note de version** : les six cartes de classe livrées sont toutes `unique` depuis
   `f381e85` (2026-09-05), donc déjà exclues des deux pools — **le défaut était latent, jamais
   observable**, et la prémisse du brainstorm du 08/09 (« un paladin peut acheter une carte de
   mage ») était déjà fausse quand elle a été écrite. **1187 tests** (+8), `dart analyze` propre —
   [ADR-101](../_adr/ADR-101-predicat-de-proposabilite-unique-et-draft-de-depart.md).
> [!NOTE]
> **Rotations.** Sortie le 2026-10-02, dans `../_archive/` : `2026-10-02-activeContext-livraisons.md`
> (P-41 lot D partie 2). Sortie le 2026-10-01 : `2026-10-01-activeContext-livraisons.md`
> (P-41 lot D partie 1). Sortie le 2026-09-21 : `2026-09-21-activeContext-livraisons.md`
> (P-41 lot C partie 2). Sorties le 2026-09-20 : `2026-09-20-activeContext-livraisons-3.md`
> (P-41 lot C partie 1), `2026-09-20-activeContext-livraisons-2.md` (lot B partie 2) et
> `2026-09-20-activeContext-livraisons.md` (lot B partie 1, avec quatre réserves closes). Sorties
> le 2026-09-18 : `2026-09-18-activeContext-livraisons-2.md` (P-49) et
> `2026-09-18-activeContext-livraisons.md` (P-41 lot A). Les onze rotations précédentes portent le
> même nom, daté du 2026-09-17 au 2026-08-20.

## Prochaine étape

**D'abord le propriétaire, sur la vague 1** : il joue le cahier de test du
[compte rendu](../../docs/superpowers/reports/2026-10-02-economie-et-catalogue-vague-1-compte-rendu.md)
(§3), lit la table des arbitrages (§2), ouvre la PR de `feat/v0.5.3-p43-e0-e1`, la fusionne dans
`main`, puis pose le tag sur le commit de fusion (ADR-103 D1). Une correction demandée se fait sur
la branche, avant la fusion.

**Puis la vague 2 du fichier d'orchestration** : le lot E2 de P-43, « fusion = forge » — la fusion
qui propose une rune, l'affûtage au feu, le Puits d'échange, la copie du deck en boutique ; la
forge du feu, `pools`, `stackable` et la capacité y disparaissent. Elle se lance dans une session
neuve, par le prompt unique du §0 de l'orchestration, et **sa porte d'entrée attend le tag de la
vague 1** : tag ancêtre de `main`, CI/CD verte, constatée par `gh` — et c'est elle qui notera la
vague 1 close. Elle hérite de trois points d'ADR-105 : l'héritage de la fusion suit la règle
d'exclusion de `consolidate`, la relance sans effet disparaît avec la forge du feu, et `cheap`
aura besoin de son propre substitut de description.

Une question reste tenue dans `docs/ROADMAP.md` §4, hors programme : la **Maîtrise dans l'onglet
Héros du menu de debug**, laissée hors du lot D partie 2 de P-41 alors qu'elle pilote tout P-49.

Le Jalon 2 « Feel & contenu » (`docs/ROADMAP.md` §9) reste ouvert : P-06, P-07, le prototype de
P-08, P-05 — dont dépendent les lots 2 à 4 de P-44, après le programme. **P-07 doit lire
[ADR-083](../_adr/ADR-083-latence-et-synchronisation-du-chemin-de-lecture.md) D6 avant de toucher
aux animations.**
