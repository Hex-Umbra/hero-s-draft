## 🎯 ADR-100 : La Console Rattrape l'Identité de Classe — Vocabulaire Lu sur le Moteur, Identifiants en Attente de Transaction (P-41, lot D, partie 2)

### Statut

✅ Accepté — chantier **P-41, lot D, partie 2**, fusionné dans `main` par la **PR #45**
(2026-09-20, merge `d27edc9`, `70fea1d`..`6c1a8dd`, 5 commits de code).

**Clôt le lot D, et P-41 en entier.** Amende la famille 8 du pipeline de validation
d'[ADR-089](ADR-089-editeur-de-contenu-seam-disque-et-validation-totale.md) et étend la table
déclarative d'[ADR-092](ADR-092-formulaire-infere-du-document-et-ressources-liees.md) d'une
huitième catégorie. Reprend le précédent de `PassiveMastery.fields`
([ADR-096](ADR-096-passifs-partages-eligibilite-et-maitrise-hybride.md)) et la doctrine « ce que
le geste impose, la recette l'écrit »
d'[ADR-090](ADR-090-identite-visuelle-de-classe-portee-par-la-donnee.md). Valide la donnée
produite par [ADR-097](ADR-097-puissance-unique-orientee-par-la-classe.md) (`statRules`) et
[ADR-098](ADR-098-recompenses-de-niveau-en-donnee-et-gabarits-a-tr.md) (les huit récompenses).

**Aucun effet joueur** : tout ce que cette décision touche est élagué du build release par
`kDebugMode`. C'est la raison pour laquelle la note `0.5.2` n'a **pas** été rouverte pour cette
livraison — ni entrée joueur, ni entrée Technique.

### Contexte

Trois lots de P-41 avaient déplacé de la mécanique de jeu vers la donnée — la conversion d'armure
en `statRules`, neuf passifs dont l'éligibilité est déclarée, huit récompenses de niveau en fiches
— **sans que l'outil qui écrit cette donnée l'apprenne**. L'écart s'était creusé en trois trous
concrets, tous nommés par le code lui-même :

1. **L'éditeur laissait écrire `"mode": "convrt"`.** `statRules` n'était borné par rien ; seule la
   vue JSON brute l'atteignait, et le descripteur le disait en commentaire depuis le lot B. C'est
   exactement la faute pour laquelle un éditeur validant existe : elle ne se voit qu'au chargement
   suivant, et elle fait alors échouer **toute la catégorie**, pas seulement son fichier.
2. **La création guidée produisait une classe sans aucun passif disponible.** Choix vide à la
   sélection, et `referential_integrity_test` rouge — mais *après* que l'auteur a écrit ses
   fichiers. L'invariant était gardé au niveau du dépôt, jamais au niveau du geste.
3. **Les récompenses de niveau étaient la seule catégorie à avoir une source de chargement sans
   descripteur d'édition** : neuf sources déclarées, sept catégories éditables.

Derrière le point 2 se tenait une question de fond. `EntityValidator` juge un brouillon contre le
**registre chargé au démarrage**. Une recette qui écrit une classe *puis* un passif qui la nomme se
fait donc refuser son propre passif : au moment où il est jugé, la classe n'existe ni dans le
registre ni sur le disque. Le trou était décrit mot pour mot dans le code depuis P-30 —
`_signatureCards` s'en protégeait **en n'étant pas** un contrôle par référence. Le passif, lui, en
est un.

### Décision

**D1 — Le vocabulaire de `statRules` est lu sur `StatRule`, jamais recopié dans le descripteur.**
Trois getters (`statNames`, `modeNames`, `targetNames`) exposent les tables privées du parseur.
`_names(RuleTarget.values)` rendrait `statusMight`, que **nul fichier ne porte** : `class.json`
écrit `status:might`, et le seul endroit qui connaisse la correspondance est le parseur. Écrire
`['armor', 'mana']` dans le descripteur ferait diverger la liste et le parseur au premier ajout.

**D2 — Le gabarit de classe porte `"statRules": []`, jamais une règle toute faite.** Une règle au
gabarit ferait naître *toute* classe créée convertisseuse d'armure : un défaut par défaut. Une clé
absente resterait invisible au formulaire, qui n'infère que sur ce que le document porte. La liste
vide rend la clé visible et arme la validation dès qu'une règle y entre. Conséquence assumée : une
liste vide donne un champ « JSON brut » et non un formulaire — un élément-modèle découplé du
gabarit est un champ de descripteur à part entière, hors de ce lot.

**D3 — La recette de classe écrit un passif de départ, dérivé de l'identifiant de la classe.**
Même doctrine qu'`iconPath` : ce que le geste impose, la recette l'écrit, et l'identifiant ne se
saisit pas. Le passif porte `"classes": ["<id>"]` — sans quoi il serait ouvert à *toutes* les
classes et polluerait le pool des trois livrées. Sa prose reste `[À REMPLIR] <id>`,
**volontairement voyante** : inventer un nom ferait passer un squelette pour un choix.

**D4 — `EntityValidator` gagne `pendingIds`, uni au registre pour les références seulement.**
`Map<EntityCategory, Set<String>>` : ce que **la même transaction** va écrire. `_idsOf` l'unit au
registre pour la famille 8 ; `_registryIdsOf`, extrait sous ce nom, reste seul lu par l'unicité de
la famille 1 — sans quoi la classe qu'une recette s'apprête à écrire se trouverait « déjà portée
par une entité de cette catégorie », c'est-à-dire par elle-même. **Une référence ne se juge jamais
sur les seuls pendants** : registre nul ⇒ contrôle sauté, jamais deviné.

**D5 — Les récompenses de niveau deviennent la 8ᵉ catégorie, par une entrée de table.** Le
catalogue, les valeurs connues, le formulaire inféré, l'écrivain et l'aller-retour sur les fichiers
livrés sont tous pilotés par `kEntityDescriptors` : une entrée suffit, et les `switch` exhaustifs
sur `EntityCategory` cessent de compiler tant que leur `case` manque — le filet, pas l'obstacle.

**D6 — Le menu de debug règle les cibles de la Puissance et affiche l'identité de la run, hors
ARB.** Les puces sont **générées** depuis `MightTarget.values`. L'identité — classe, règles de stat
dans le **vocabulaire du fichier** (`StatRule.toString()`), passif actif — est en lecture seule :
ces trois-là viennent du `class.json` et du choix de passif, et les écraser produirait une run
qu'aucune sauvegarde ne saurait relire. Libellés en français sans accents écrits en dur, comme tous
ceux du tiroir : y introduire l'ARB pour une ligne afficherait au développeur la phrase du joueur
plutôt que la donnée qu'il édite. `StatRuleLabel.describe` reste la phrase du joueur.
**La dernière cible ne peut pas être retirée** : `HeroData.fromJson` refuse une liste vide comme
une faute de donnée, et un outil de debug ne doit pas produire un état que la couche de données
refuse de relire.

### Preuves dans le code

| Décision | Emplacement |
|:---|:---|
| D1 | `lib/models/data/stat_rule.dart:64-66` (les trois getters) ; `entity_descriptor.dart:427-429` (les trois clés énumérées) ; `test/unit/stat_rule_vocabulary_test.dart` — chaque nom exposé se relit par `fromJson`, et la parité énumération ↔ vocabulaire est asservie |
| D2 | `lib/services/content_editor/entity_descriptor.dart:451` |
| D3 | `lib/services/content_editor/class_recipe.dart:58` (`starterPassiveId`), `:112-118` (`_starterPassiveMechanics`, qui impose `classes`) |
| D4 | `lib/services/content_editor/entity_validator.dart:63` (le champ), `:560-565` (`_idsOf`), `:571-592` (`_registryIdsOf`), `:140-146` (l'unicité lit le second, et dit pourquoi) ; `lib/ui/screens/content_editor_screen.dart:329` (`_judge` verse l'identifiant de la classe) |
| D5 | `entity_descriptor.dart:28` et `:361` ; `lib/ui/widgets/content_editor/editor_style.dart:113` |
| D6 | `lib/ui/widgets/debug/tabs/debug_hero_tab.dart:75-79` (puces générées), `:117-130` (identité en lecture seule), `:171-183` (`_toggleTarget`, garde de la dernière cible) ; `lib/models/data/stat_rule.dart:113` (`toString()`) |

Mesuré le 2026-09-20 sur `d27edc9` : **1179 tests au vert** (+20), `dart analyze` propre.

### Conséquences

**Ce qui est gagné.**

- La faute `"convrt"` est refusée à l'écriture, là où elle coûtait le chargement d'une catégorie.
- Une classe créée depuis la console est **immédiatement jouable** : elle a un passif, donc un
  choix non vide à la sélection, et `referential_integrity_test` reste vert.
- `pendingIds` **nomme** un trou qui était jusque-là contourné. Toute recette future écrivant deux
  entités dont l'une réfère à l'autre passe par ce seam au lieu d'éviter le contrôle.

**Ce qui est payé, et assumé.**

- **Toute classe créée depuis la console naît avec un passif nommé comme elle**, prose
  `[À REMPLIR]` et mécanique du gabarit. C'est un squelette à éditer, pas un passif de production.
- **Tout nouveau `class.json` écrit par l'éditeur porte `"statRules": []`.** `parseAll([])` rend
  `const []` : aucun effet de jeu. Les trois classes livrées ne sont pas touchées — le gabarit ne
  complète jamais un fichier en modification.
- **`pendingIds` ne couvre que la transaction en cours, pas la session.** L'angle mort « le
  registre ne voit pas ce que la session vient d'écrire » reste entier pour une écriture
  *précédente* : seul un redémarrage à chaud le referme.
- **La Maîtrise reste absente de l'onglet « Héros ».** Le §9.2 de la spec nomme trois lectures et
  un réglage ; `mastery` n'en est pas — alors qu'elle pilote tout P-49. Écart délibérément laissé
  au propriétaire, **porté en question ouverte dans `docs/ROADMAP.md` §4**, pas refermé ici.
