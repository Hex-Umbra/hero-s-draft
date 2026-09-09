# Éditeur de contenu — création guidée et identité de classe dans la donnée — Conception

Date : 2026-09-08
Statut : **Conception** — non implémenté
Révision : v4 — **v4 : la recette ecrit `iconPath` pour une classe neuve et depose
`placeholder_icon.png` — mais a la creation seulement, une modification n'en fabriquant jamais, sous
peine d'afficher un carre magenta a la place de l'illustration des trois classes livrees** (§3.1,
§6.1). Les deux images de remplacement vivent desormais sous `assets/placeholders/images/`. v3 — **`EntityWriter._registerSignatureCard` maintenait déjà `skills` ; la §1 le
décrivait mal, et la garde devient une bijection lue sur le disque plutôt qu'une reference vers le
registre, qui aurait refuse la sortie meme de l'outil** (§1, §7.1). v2 — **`iconPath` désignait en réalité la carte de classe (1696 × 2528, 6,5 Mo), pas une
icône : le champ devient `classCard` et `iconPath` renaît optionnel pour une vraie icône** (§3.1).
Et le libellé affiché après écriture, laissé ouvert en v1, est refermé — le code séparait déjà
correctement création et modification (D14). Les deux écarts viennent d'avoir mesuré les fichiers
plutôt que d'avoir cru leur nom
Périmètre : **deux étapes, dans cet ordre.** L'étape A rend la donnée de classe honnête — les images
nommées pour ce qu'elles sont, la couleur sortie du code — et l'étape B remplace le parcours de
l'éditeur par un arbre de boutons en donnant au moteur des recettes multi-fichiers. A précède B
parce que B consomme la donnée que A crée.
Sources amont :
- Brainstorming des 2026-09-07 / 2026-09-08 (ce fil), consécutif à la livraison du lot 2
- `docs/superpowers/specs/2026-09-06-menu-debug-lot-2-editeur-de-contenu-design.md` — le moteur et
  les sept familles de validation dont cette spec hérite sans les redéfinir
- `docs/possible_upgrades/05-08-2026_brainstorm_heros_et_cartes_Opus5.md` — §155 et §159, qui
  demandent explicitement d'employer `armorMastery`
- `docs/possible_upgrades/08-09-2026_filtre_cartes_de_classe_Opus5.md` — défaut voisin, **hors
  périmètre**, documenté pour ne pas être perdu

> **Ce que cette spec change, et ce qu'elle ne change pas.**
>
> Le moteur d'écriture livré au lot 2 — `ProjectRoot`, `EntityDescriptor`, `EntityValidator`,
> `EntityWriter`, `knownValues`, l'interface `ContentFileSystem` — reste en place et garde ses
> garanties. Cette spec ajoute par-dessus : deux gardes de validation, des recettes multi-fichiers,
> et une interface entièrement nouvelle. Rien de ce qui est déjà testé n'est réécrit.

---

## 1. Le problème

Créer une classe complète est aujourd'hui impossible depuis l'outil, et personne ne s'en apercevait.

Une classe jouable, ce n'est pas un fichier : c'est un dossier, une image, N cartes de signature, et
un renvoi `skills` de `class.json` vers les identifiants de ces cartes. L'éditeur du lot 2 écrit
**une entité, un fichier** : il faut donc N+1 gestes, chacun avec son formulaire entier à remplir.

`skills` lui-même n'est **pas** à la charge de l'auteur — `EntityWriter._registerSignatureCard`
(`entity_writer.dart:135-158`) l'alimente, trié, à chaque carte de classe écrite. Ce qui manque
n'est donc pas le lien, mais l'atomicité et l'ordre :

- une carte écrite avant la classe qui la porte lève `StateError` ; l'ordre compte et rien ne
  l'annonce ;
- une classe abandonnée en cours de route — deux cartes voulues, une écrite — laisse un `skills`
  sincère et une classe incomplète ;
- `referential_integrity_test` exige la bijection **exacte** entre `classes/<id>/cards/*.json` et
  `skills` (`referential_integrity_test.dart:104-122`). Une incohérence introduite à la main dans la
  boîte JSON fait donc rougir la suite entière, longtemps après l'écriture.

Et un décalage entre `skills` et les fichiers présents ne dégrade pas doucement : `getHeroCards`
(`hero_skills_link.dart:6-13`) utilise `firstWhere` **sans `orElse`**, délibérément. Une carte de
signature introuvable **fait planter le lancement de la run**.

Trois défauts secondaires accompagnent celui-là :

- `stats_dialog.dart:47-54` code en dur la couleur et l'icône de chaque classe par identifiant. Une
  classe créée par l'outil s'affiche en bleu générique. La promesse « 100 % piloté par la donnée »
  de `CLAUDE.md` est donc fausse pour les classes.
- `armorMastery` est un stat réel, lu par `run_controller.dart:253` et appliqué à chaque gain
  d'armure (`entity_stats.dart:11`), **qu'aucun `class.json` ne déclare** et qui n'apparaît dans
  aucun gabarit. Les trois classes valent 0 sans que ce soit une décision.
- La liste déroulante de catégories oblige à dérouler pour voir ce qui est créable.

## 2. Décisions retenues

| # | Décision | Motif |
|:--|:---|:---|
| D1 | L'identité visuelle de classe passe dans `class.json` **avant** tout le reste | L'étape B consomme cette couleur pour teinter ses boutons ; le champ a donc deux lecteurs, pas un |
| D2 | L'icône vient d'une **image**, jamais d'un champ `iconName` mappé vers un `IconData` | Un `IconData` construit dynamiquement casse `--tree-shake-icons` : la table de correspondance serait le codage en dur déplacé d'un cran |
| D3 | La liste déroulante devient un arbre de boutons à **trois niveaux, uniformes** | Direct, et l'arbre montre où le fichier va vivre |
| D4 | Les cartes se distinguent par **couleur de fond**, pas par un quatrième niveau | Le propriétaire se lit d'un coup d'œil ; l'arbre reste régulier |
| D5 | À la création d'une carte, le propriétaire est **un champ**, pas un niveau | Une carte qui n'existe pas encore n'est dans aucune liste à colorer |
| D6 | Le formulaire de création porte **toutes les clés du modèle** ; les champs vides sont complétés par le moteur | On remplit ce qu'on sait, le moteur garantit un fichier valide |
| D7 | La substitution des placeholders précède la validation | Sinon le validateur refuse exactement ce qu'il est censé compléter |
| D8 | Après une création, l'arbre revient à la **branche 0** | La nouvelle entité n'est pas dans le registre avant redémarrage ; enchaîner sur son formulaire donnerait l'illusion inverse |
| D9 | Le magenta signale l'inachevé, pour la couleur comme pour l'image | Langage visuel déjà établi par `placeholder_entity.png` |
| D10 | Le passif se choisit dans le **catalogue** des passifs, pas dans `knownValues` | `knownValues` liste les valeurs *employées* ; un passif jamais utilisé serait inchoisissable |
| D11 | `flutter_colorpicker` est ajouté en dépendance | Flutter ne fournit aucun sélecteur de couleur ; le spectre complet est voulu |
| D12 | `armorMastery` entre au gabarit de la classe | Le brainstorm héros le réclame et il ne coûte que du JSON |
| D13 | `iconPath` devient `classCard`, fichier `<id>.png` ; `iconPath` renaît **optionnel** pour une vraie icône | Le champ actuel désigne une image de 1696 × 2528 employée comme carte de classe en combat : le nom mentait |
| D14 | Deux messages distincts après écriture : recompilation pour une création, redémarrage à chaud pour une modification | Une donnée nouvelle n'entre au manifeste d'assets qu'à la compilation. C'est déjà ce que fait `relaunchAdvised` |

---

## 3. Étape A — la donnée de classe dit la vérité

### 3.1 Prérequis : nommer les images pour ce qu'elles sont

`iconPath` ne désigne pas une icône. Mesuré le 08/09/2026 : les trois `classes/<id>/icon.png` font
**1696 × 2528 pixels pour 6,5 Mo chacun**, et c'est bien ainsi qu'ils sont employés —
`state_sync_system.dart:52` les passe à `HeroCard(imagePath:)`, la carte du héros affichée en
combat. Le champ porte donc le nom d'une chose qu'il ne contient pas, ce qui a déjà coûté une
mauvaise décision dans cette spec avant correction.

Le champ est renommé pour ce qu'il contient, et le fichier avec lui :

| Avant | Après | Ce que c'est |
|:---|:---|:---|
| `iconPath` → `classes/<id>/icon.png` | `classCard` → `classes/<id>/<id>.png` | La carte de classe, 1696 × 2528 |
| — | `iconPath` → `classes/<id>/icon.png` | Une **vraie** icône, petite. Optionnelle |

`iconPath` renaît donc en désignant enfin une icône, et devient `String?` : les trois classes
existantes n'en ont pas encore, le champ est simplement absent de leur JSON.

Les lecteurs suivent le renommage :

- `state_sync_system.dart:52` prend `classCard` ;
- `imagesToPreload` (`game_data_registry.dart:44`) précharge `classCard` — c'est la grande image que
  Flame rend, pas l'icône.

**Aucune ligne de `pubspec.yaml` ne bouge** : les assets y sont déclarés par dossier
(`assets/data/classes/paladin/`), donc renommer un fichier à l'intérieur ne touche pas le manifeste.
`dart run tool/sync_assets.dart --check` le confirme après la migration.

**Deux conséquences côté descripteur** : le nom du fichier image n'est plus une constante mais
dérive de l'identifiant (`<id>.png`), et `imagePathKey` vise `classCard`.

**`iconPath` n'est écrit que pour une classe neuve.** La recette le calcule à partir de
l'identifiant — `classes/<id>/icon.png` — et l'écrivain y dépose
`assets/placeholders/images/placeholder_icon.png`, un carré magenta bordé de 64 × 64. L'auteur n'a
alors qu'un fichier à remplacer, pas une clé à se rappeler d'ajouter.

**Jamais en modification, en revanche.** Les trois classes livrées n'ont pas d'icône dessinée : leur
en déposer une ferait afficher un carré magenta à la place de leur illustration dans le dialogue de
stats, une régression visible par les joueurs au bénéfice de personne. Elles restent donc sans
`iconPath`, et le repli du §3.3 montre leur carte. La §10 garde les trois icônes comme travail
d'auteur.

### 3.2 La couleur

Un champ nouveau dans `class.json` :

```json
"themeColor": "#B71C1C"
```

Chaîne hexadécimale `#RRGGBB`, lue par `HeroData.fromJson` en `int? themeColor`, `null` si absente
ou malformée. **Aucun fichier existant n'est obligé de le porter.** Les trois classes le reçoivent
tout de même dans le même geste, avec les couleurs que le code affiche aujourd'hui — paladin bleu,
berserker rouge, mage violet — pour que la migration ne change rien à l'écran.

### 3.3 Ce que devient le dialogue de stats

`stats_dialog.dart:47-54` choisit aujourd'hui une couleur et un `IconData` Material par identifiant,
en six lignes de `if`. Un champ `iconName` mappé vers un `IconData` ne réglerait rien : Flutter
refuse de compiler en release un `IconData` construit à partir d'une valeur non constante lorsque
`--tree-shake-icons` est actif, ce qui imposerait une table `Map<String, IconData>` en dur — le
codage en dur qu'on retire, déplacé d'un cran.

Le dialogue lit donc la donnée :

| Ce qu'il affiche | D'où ça vient | Si absent |
|:---|:---|:---|
| Couleur | `themeColor` | `Colors.blue`, la valeur par défaut actuelle |
| Icône | `iconPath` | **la carte de classe**, `classCard`, recadrée dans le cercle |

Le repli sur la carte évite une régression visible : tant qu'aucune vraie icône n'est dessinée,
l'écran montre quelque chose de juste plutôt qu'un carré magenta.

### 3.4 Les lecteurs de `themeColor`

| Lecteur | Ce qu'il en fait |
|:---|:---|
| `stats_dialog.dart` | La couleur d'accent de la classe |
| L'arbre de l'étape B | Le fond des boutons de cartes appartenant à la classe |

Un champ à deux lecteurs est justifié ; un champ à un seul n'est souvent que du code en dur déplacé.

### 3.5 Le magenta de l'inachevé

Une classe créée par la recette n'a pas de couleur choisie tant que l'auteur n'en met pas une. Le
gris la confondrait avec les cartes neutres. Elle reçoit donc le magenta de
`placeholder_entity.png`, qui est déjà le signal « non terminé » du projet. Ses cartes apparaissent
en magenta dans l'arbre et se lisent comme telles.

---

## 4. Étape B — l'arbre de navigation

### 4.1 Le schéma

```
┌────────────────────────────────────────────────────────────────┐
│  ÉDITEUR DE CONTENU                                            │
└────────────────────────────────────────────────────────────────┘

  [ Carte ] [ Relique ] [ Événement ] [ Passif ]          ← niveau 0 : les 7 types,
  [ Amélioration ] [▓▓ CLASSE ▓▓] [ Ennemi ]                 toujours affichés
   │
   └──▶ [ Créer ]  [▓▓ MODIFIER ▓▓]                       ← niveau 1, décalé d'un cran
         │
         └──▶ [ paladin ] [ berserker ] [▓▓ MAGE ▓▓]      ← niveau 2, liste dynamique
               │
               └──▶ ┌──────────────────────────────┐     ← niveau 3, le formulaire
                     │ Nom (fr)   [Le Mage       ]  │
                     │ PV max [100]   Mana [3]      │
                     │ Passif     [spell_armor  ▾]  │
                     │ …                            │
                     │        ( Écrire )            │
                     └──────────────────────────────┘

  Branche Créer — pas de niveau 2, on crée, on ne choisit pas :

   └──▶ [▓▓ CRÉER ▓▓]  [ Modifier ]
         │
         └──▶ ┌──────────────────────────────────────┐
               │ Identifiant   [gambler            ]  │
               │ Nom (fr)      [Le Parieur         ]  │
               │ Cartes de signature      [  2  ]     │
               │   ├ carte 1  nom [     ] id [     ]  │
               │   └ carte 2  nom [     ] id [     ]  │
               │ Couleur       ( ● ) → roue           │
               │ …                                    │
               │      ( Créer la classe )             │
               └──────────────────────────────────────┘
```

### 4.2 Les règles de l'arbre

1. **Rien ne se replie vers le haut.** Les sept boutons de type restent affichés quel que soit le
   niveau atteint ; le niveau 1 reste affiché quand le niveau 2 s'ouvre, et ainsi de suite.
2. **Chaque descente ajoute une tabulation** — une marge à gauche, constante.
3. **Le bouton actif prend un style « cliqué »** distinct du repos.
4. **Un seul chemin ouvert à la fois.** Cliquer un autre bouton du même niveau referme ce qui
   pendait sous le précédent et ouvre le nouveau. Cliquer le bouton déjà actif le désélectionne et
   referme sa branche.
5. **Aucune liste n'a besoin de recherche.** Mesuré le 08/09/2026 : 25 reliques au maximum,
   23 cartes, 8 améliorations, 5 événements, 4 ennemis, 3 classes, 3 passifs. Une grille de boutons
   enroulée suffit.

### 4.3 Les cartes : la couleur au lieu d'un niveau

Une carte vit à deux endroits — `assets/data/cards/` pour les neutres,
`assets/data/classes/<id>/cards/` pour celles d'une classe. En **modification**, la liste du
niveau 2 les rassemble toutes, ordonnées par propriétaire (neutres d'abord, puis chaque classe en
bloc), chaque bouton portant le fond de son propriétaire : gris pour les neutres, `themeColor` pour
les autres. Le bouton porte aussi l'icône de la classe, pour que la distinction ne repose pas sur la
seule couleur.

En **création**, la couleur ne peut rien : la carte n'existe pas encore. Le propriétaire devient donc
le premier champ du formulaire, une rangée de pastilles reprenant le même code — `(gris) Neutre`,
puis une pastille par classe. C'est ce champ qui décide du répertoire, donc du fichier écrit.

### 4.4 Après une création : retour à la branche 0

La recette écrit sur le disque, mais le registre du jeu est chargé au démarrage. La nouvelle entité
n'existe donc pas encore pour l'application qui tourne. Ouvrir son formulaire de modification juste
après l'avoir créée donnerait l'illusion qu'elle est vivante.

À la place : **toutes les sélections sont relâchées, l'arbre revient à son état initial**, et le
message de résultat reste affiché sous l'arbre — celui que `_outcome()` produit déjà.

---

## 5. Étape B — les formulaires

### 5.1 Le formulaire complet, et l'ordre des opérations

Le formulaire de création affiche **toutes les clés que le modèle de la catégorie sait lire**. On
remplit ce qu'on veut ; **tout champ laissé vide est complété par le moteur** avant écriture.

L'ordre est imposé et n'est pas négociable :

```
composer  →  substituer les placeholders  →  valider  →  écrire
```

Placé après la validation, le remplissage ne servirait à rien : la famille 5 refuse la prose
bilingue vide, c'est-à-dire précisément ce que le moteur est chargé de compléter.

Valeurs de substitution :

| Nature | Placeholder |
|:---|:---|
| Prose bilingue (`name_fr`, `description_en`, …) | `[À REMPLIR] <identifiant>` — criard par construction |
| Nombre | le défaut du gabarit (100 / 3 / 5 …) |
| Énumération | la première valeur du gabarit |
| `themeColor` | le magenta de l'inachevé |
| Référence optionnelle (`passiveTrait`) | absente — le modèle l'accepte à `null` |
| Image | `placeholder_entity.png`, comportement déjà livré |

### 5.2 Ce qui reste obligatoire

Trois choses ne peuvent pas être devinées et bloquent la création tant qu'elles manquent :

- **l'identifiant** — c'est le nom du fichier ;
- **le propriétaire, pour une carte** — c'est le répertoire ;
- **le nombre de cartes de signature et leurs identifiants, pour une classe** — `skills` les
  référence, et un décalage plante le lancement de la run.

### 5.3 Ce qui n'apparaît jamais au formulaire

- `id` — saisi à part, dans le triangle d'identité ;
- `classCard` / `spritePath` — calculés par `EntityWriter` à partir de l'identifiant ;
- `skills` — dérivé des cartes que la recette vient de créer ;
- `heroClass` et `category` — **imposés par le répertoire ; les écrire fait échouer le chargement**
  (`CLAUDE.md`, autorité du répertoire).

`iconPath` n'y figure pas davantage : la recette le dérive de l'identifiant pour une classe neuve
(§3.1), et une classe existante qui n'en a pas ne doit pas en recevoir.

### 5.4 Le sélecteur de couleur

Vérifié dans le SDK (`packages/flutter/lib/src/material/`) : Flutter fournit un sélecteur de date et
un sélecteur d'heure, **aucun sélecteur de couleur**, et aucune classe `*ColorPicker` dans ses
sources. Le paquet `flutter_colorpicker` est donc ajouté, contrainte de version résolue par
`flutter pub add`.

Il atterrit dans `dependencies:` et non `dev_dependencies:`, puisqu'il est importé depuis `lib/`.
L'écran étant derrière `kDebugMode` — constante de compilation, donc branche éliminée — son code
disparaît des builds de release ; le paquet reste néanmoins dans `pubspec.yaml`, le lock et la page
de licences. C'est la première dépendance du projet qui ne serve qu'au debug, et c'est un coût
accepté en connaissance de cause.

### 5.5 Le passif : un catalogue, pas un vocabulaire

`knownValues` dérive du disque les valeurs **déjà employées** — c'est ce qui rend `effectType`
découvrable, et c'est le bon outil pour une chaîne libre. Pour `passiveTrait`, ce serait faux : un
passif présent sur le disque mais qu'aucune classe n'utilise encore n'apparaîtrait pas, et serait
donc impossible à choisir.

Le défaut est invisible aujourd'hui — 3 passifs, 3 utilisés, les deux listes coïncident — et
apparaîtrait au quatrième passif écrit. La liste vient donc de l'énumération de
`assets/data/passives/`, que `_entityFiles` (`known_values.dart:62`) sait déjà produire : il suffit
de l'appeler avec le descripteur du passif et de prendre les identifiants.

**La règle générale** : tout `referenceKey` vise un **catalogue d'entités**, jamais un vocabulaire
d'usage.

---

## 6. Le moteur : les recettes

Une recette est un geste qui produit **un ensemble cohérent de fichiers**, là où `EntityWriter`
produit une entité. Elle s'appuie sur lui sans le remplacer, et hérite donc de son rollback : si une
écriture échoue en cours de route, tout ce que la recette a posé est retiré.

### 6.1 La recette de classe

Entrées obligatoires : identifiant, N, et pour chacune des N cartes son identifiant.
Écrit, dans cet ordre :

```
assets/data/classes/<id>/class.json      (avec iconPath déjà écrit)
assets/data/classes/<id>/<id>.png        (carte de classe, placeholder)
assets/data/classes/<id>/icon.png        (icone, placeholder — creation seule)
assets/data/classes/<id>/cards/<c1>.json (placeholder)
assets/data/classes/<id>/cards/<cN>.json (placeholder)
puis  dart run tool/sync_assets.dart
```

**L'ordre n'est pas libre.** `class.json` part avec un `skills` vide, puis chaque carte est écrite
par `EntityWriter`, qui l'y ajoute elle-même (`_registerSignatureCard`). Chaque état intermédiaire
est donc cohérent, et l'état final porte les N cartes. L'inverse — écrire la classe avec son `skills`
complet avant les cartes — violerait la bijection du §7.1 à chaque étape sauf la dernière.

Cela suppose une seule chose du moteur : que les N+1 écritures partagent **une même transaction**,
pour que le rollback les couvre toutes et que `sync_assets` ne tourne qu'une fois au lieu de N+1.

`sync_assets` est lancé **une fois**, à la fin : une classe ajoute deux lignes au manifeste
(`classes/<id>/` et `classes/<id>/cards/`), et un dossier non déclaré disparaît silencieusement du
build.

### 6.2 La recette d'ennemi

Identifiant et noms. Écrit `enemies/<id>/enemy.json` et `enemies/<id>/sprite.png`, puis
`sync_assets`. **Pas de description** — le modèle n'en a pas — et pas de cartes.

### 6.3 Les cinq catégories simples

Carte, relique, événement, passif, amélioration de forge : un fichier, le comportement de
`EntityWriter` d'aujourd'hui, plus la substitution des placeholders du §5.1. Pour une carte, le
propriétaire choisi au §4.3 décide du répertoire.

---

## 7. Les deux gardes nouvelles

### 7.1 La bijection `skills` ↔ `cards/`

Le réflexe serait d'ajouter à `EntityDescriptor` la symétrique de `enumListKeys` pour les
références — un `referenceListKeys` valant `{'skills': EntityCategory.card}` — et de laisser
`_references` (`entity_validator.dart:240`) la traiter élément par élément.

**Ce serait faux.** `_references` interroge le **registre**, chargé au démarrage de l'application.
Or les cartes qu'une recette vient d'écrire n'y sont pas, ni aucune carte créée depuis le lancement.
Le contrôle refuserait la sortie même de l'outil.

La garde interroge donc le **disque**, et vérifie l'invariant réel plutôt qu'une approximation : le
tableau `skills` d'une classe doit être exactement l'ensemble des `*.json` de son dossier `cards/`.
C'est mot pour mot ce qu'exige `referential_integrity_test`, avancé au moment de l'écriture au lieu
de celui des tests. En création, la recette le satisfait par construction ; en modification, il
attrape la main qui édite `skills` dans la boîte JSON.

### 7.2 Gabarit ⊇ modèle

Le §1 relève `armorMastery` : un stat réel, lu par le jeu, absent de tous les `class.json` et de tous
les gabarits. Le corriger une fois ne garantit rien pour la prochaine fois — le gabarit est une
chaîne écrite à la main, le modèle est du code, et rien ne les tient ensemble.

La garde : un test qui, **pour chaque descripteur**, lit le fichier source du modèle, y relève les
clés effectivement lues (motif `json['…']`), et vérifie que chacune figure au gabarit ou dans
l'ensemble explicitement exclu du §5.3.

Ses limites, énoncées plutôt que découvertes : il lit du texte, pas un arbre syntaxique — Dart n'a
pas de réflexion utilisable en test ici. Si un `fromJson` cessait d'employer la forme littérale
`json['clé']`, le test cesserait de le couvrir sans échouer. Il doit donc **aussi** vérifier qu'il a
trouvé au moins une clé par modèle, faute de quoi son silence serait celui d'une recherche vide.

`armorMastery` entre au gabarit de la classe dans le même geste, valeur `0` — le défaut du modèle,
rendu explicite et donc modifiable depuis le formulaire. C'est ce que réclame le brainstorm héros
(§155, §159) : *« les utiliser ne coûte que du JSON »* — encore faut-il pouvoir écrire ce JSON.

---

## 8. Tests

Tout test cité ici doit pouvoir échouer. Chacun est écrit d'abord, vu rouge, puis rendu vert.

**Étape A**
1. `HeroData.fromJson` lit `classCard`, et `iconPath` vaut `null` quand le champ est absent.
2. `imagesToPreload` référence `classCard` — le test échouerait s'il restait sur l'ancien champ,
   ce qui priverait Flame de la seule grande image qu'il préchargeait.
3. `HeroData.fromJson` lit `themeColor` et retombe sur `null` si le champ est absent ou malformé.
4. Le dialogue de stats affiche la couleur du `HeroData` fourni, et non une couleur codée en dur —
   vérifié avec une classe fictive dont la couleur n'est aucune des trois actuelles.
5. Le dialogue replie sur `classCard` quand `iconPath` est absent, et prend `iconPath` quand il est
   présent — deux assertions, sans quoi le repli du §3.3 n'est pas couvert.

**Étape B — l'arbre**
3. Le niveau 1 n'apparaît qu'après sélection d'un type ; le niveau 2 qu'après « Modifier ».
4. Cliquer un autre type referme la branche ouverte.
5. Après une création réussie, plus aucun bouton n'est sélectionné, et le message de résultat reste
   affiché.
6. Les boutons de cartes portent le fond de leur propriétaire — une carte de classe ne porte pas le
   gris des neutres.

**Étape B — les formulaires et le moteur**
7. Un formulaire de création entièrement vide, hormis les champs obligatoires du §5.2, **écrit un
   fichier valide** : c'est le test qui échouerait si la substitution passait après la validation.
8. La recette de classe écrit les quatre fichiers et un `skills` qui référence exactement les cartes
   écrites.
9. Une recette dont une écriture échoue en cours de route ne laisse rien derrière elle.
10. Un `skills` référençant une carte absente du dossier `cards/` est refusé — et, symétriquement,
    un `skills` qui **omet** une carte présente l'est aussi : la bijection se vérifie dans les deux
    sens ou elle ne vérifie rien.
11. Gabarit ⊇ modèle, pour les sept catégories — et le test échoue si un modèle ne livre aucune clé.
12. Le catalogue des passifs proposé contient un passif présent sur le disque qu'aucune classe
    n'emploie — le cas que `knownValues` manquerait.

## 9. Hors périmètre

- **Le filtre de classe sur les pools d'offre** — documenté dans
  `docs/possible_upgrades/08-09-2026_filtre_cartes_de_classe_Opus5.md`, délibérément non traité ici :
  c'est du code de jeu, pas de l'outillage.
- **La refonte des passifs et des stats de classe** — brainstorm héros, chantier propre. Cette spec
  se contente d'exposer `armorMastery` au formulaire pour la rendre possible.
- **Le renommage et la suppression d'entités** — restent manuels, décision tenue depuis le lot 2.
- **Le mode « Modifier » pour les classes et ennemis existants** garde le comportement livré :
  relecture du fichier avant écriture, refus d'écrire sans relecture.

## 10. Ce qui reste à la charge de l'auteur

- **Trois vraies icônes de classe à dessiner.** `iconPath` étant optionnel et le dialogue repliant
  sur la carte de classe (§3.3), rien n'est bloqué ; l'écran y gagnera le jour où les trois
  `icon.png` existeront.
- **La couleur de thème des trois classes existantes** est reprise du code — bleu, rouge, violet.
  Si une autre teinte convient mieux, c'est le moment : elle n'est plus dans le code.

Le libellé affiché après écriture, lui, est **tranché** : `relaunchAdvised = !draft.isModification`
(`entity_writer.dart:76`) sépare déjà exactement les deux cas de D14, et les deux messages sont
justes tels qu'ils sont. Une donnée nouvelle n'entre au manifeste d'assets qu'à la compilation ;
une modification de contenu se voit au redémarrage à chaud.

## 11. Risques

| Risque | Parade |
|:---|:---|
| L'arbre réécrit l'écran de fond en comble ; ses tests widget aussi | Le moteur, lui, ne bouge pas : ses tests unitaires restent le filet pendant la réécriture de l'interface |
| Une couleur choisie librement peut être illisible sur le fond de l'arbre | Accepté : la roue complète est un choix explicite. Le bouton porte aussi l'icône de la classe |
| `flutter_colorpicker` est une dépendance de plus pour du debug | Le code disparaît des builds de release ; le coût résiduel est le lock et la page de licences |
| Le test « gabarit ⊇ modèle » lit du texte, pas un AST | Il vérifie aussi qu'il a trouvé au moins une clé par modèle, pour que son silence ne passe pas pour un succès |
| Le renommage touche trois binaires de 6,5 Mo | Un `git mv` par classe, aucun octet réécrit ; `sync_assets --check` confirme que le manifeste ne bouge pas |
| Le dialogue de stats change d'aspect — image de classe au lieu d'un glyphe Material | Voulu : c'est la seule façon de sortir la table en dur sans la remplacer par une autre. Le repli montre toujours une image juste, jamais un placeholder |
