# Modèle — le suivi des vagues d'un chantier

Ce répertoire tient **un fichier de suivi par chantier livré par vagues**. Un suivi raconte, vague après vague, **ce que le chantier apporte au jeu et pourquoi** — pour quelqu'un qui joue au jeu et ne lit pas le code.

Ce fichier est le modèle que tous les suivis respectent : son en-tête, son organisation, ce qui s'y écrit et de quelle manière. L'exemple de référence est [`economie_unifiee_et_catalogue.md`](economie_unifiee_et_catalogue.md).

---

## 1. Ce qu'un suivi est, et ce qu'il n'est pas

| Le suivi | Ce qu'il n'est pas — et où le trouver |
|:---|:---|
| Le récit en clair de ce que chaque vague change dans le jeu, et de la raison de cette vague | **L'état technique** d'une vague — sa branche, ses tests, son étape — : c'est le journal du fichier d'orchestration du chantier |
| Écrit pour le propriétaire, un testeur, un joueur curieux | **Le compte rendu** d'une vague — arbitrages, cahier de test manuel — : `docs/superpowers/reports/`, un fichier par vague, le chantier dans son nom |
| Une dizaine de lignes par vague | **La note de version** que le joueur lit en jeu : `assets/data/patch_notes.json` |

Un fait technique qui manque ici ne manque pas : il a son endroit, et le suivi y renvoie par son en-tête.

## 2. Un fichier par chantier

- **Son nom** : le chantier, en minuscules, sans accent, mots séparés par des tirets bas — `economie_unifiee_et_catalogue.md`. Pas de date dans le nom : le fichier vit aussi longtemps que le chantier.
- **Sa création** : à l'ouverture du chantier, par la session qui écrit son fichier d'orchestration. Elle copie le squelette de §5 **sans ses blocs « Vague » et « Bilan »** — ils s'ajoutent à mesure, on ne les laisse pas en gabarit —, remplit l'en-tête et « Le chantier en quelques lignes », et ajoute la ligne du fichier dans `docs/INDEX.md`.
- **Ses mises à jour** : **chaque vague écrit sa propre section**, à la fin de son cycle, juste avant de s'arrêter — c'est l'orchestrateur de la vague qui l'écrit, parce que c'est lui qui a le fil. Dans le même geste il met à jour la ligne « Avancement » de l'en-tête. La section, l'en-tête et le journal technique partent dans le même commit.
- **Sa clôture** : ce qui clôt le chantier écrit le « Bilan du chantier » et passe l'en-tête à « Chantier clos » — une session de clôture si le fichier d'orchestration en prévoit une, sa dernière vague sinon. Jamais avant que la dernière version soit publiée : un suivi ne dit pas clos ce qui ne l'est pas.

## 3. L'organisation du fichier

Quatre blocs, toujours dans cet ordre.

1. **L'en-tête** — le chantier, ses versions, son avancement, et les liens vers ce qui fait foi techniquement. C'est la seule partie du fichier qui cite des identifiants de chantier et des chemins de fichier.
2. **« Le chantier en quelques lignes »** — écrit une fois, à l'ouverture : ce qui n'allait pas ou ce qui manquait, ce que le chantier change, dans quel ordre, en combien de vagues. Cinq à huit lignes.
3. **Une section par vague**, dans l'ordre où elles sont livrées, la plus récente en bas. Chaque section porte :
   - un titre — le numéro de la vague, sa version, et un nom en clair ;
   - une ligne d'état — la date de livraison : « *Livrée le* », ou « *Faite le* » pour une vague sans version ;
   - **« Pourquoi cette vague »** — un paragraphe ;
   - **« Ce qu'elle apporte au jeu »** — un paragraphe.
4. **« Bilan du chantier »** — écrit à la clôture : ce que le chantier entier a changé au jeu, et ce qui reste volontairement pour plus tard.

## 4. Comment écrire

**La langue.** En français, en phrases complètes, au présent pour ce que le jeu fait — le passé seulement pour ce qui manquait avant la vague. Les mots du jeu tels que le joueur les lit à l'écran : le nom français d'une carte, d'un passif, d'une rune, d'un écran.

**Ce qui n'entre jamais dans une section de vague** : un nom de fichier, un terme de code ou un identifiant, un numéro de décision ou de lot, un nombre de tests, de commits ou d'agents. Un identifiant se traduit par le nom que le jeu affiche ; s'il n'a pas de nom à l'écran, il n'a pas sa place ici.

**« Pourquoi cette vague ».** Le problème, dit du point de vue de celui qui joue : ce qui n'allait pas, ce qui manquait, ce qui était injuste ou illisible. Puis pourquoi maintenant : ce qu'une vague précédente a rendu possible, ou ce qu'une vague suivante attend de celle-ci.

**« Ce qu'elle apporte au jeu ».** Ce qui change quand on lance une partie. Trois exigences :

- **dire ce qui est livré, pas ce qui était prévu** — la section s'écrit à la fin de la vague, sur ce qu'elle a réellement fait ;
- **dire aussi ce que la vague retire ou laisse en attente** — une option qui disparaît pour une version, un mécanisme encore rare, un contenu qui arrive plus tard ;
- **dire quand rien ne se voit** — une vague de préparation ou de fondations l'écrit en une phrase, sans chercher à paraître.

**Les chiffres.** Seulement ceux que le joueur voit à l'écran — un coût, un nombre de cartes, une durée en tours. Une vague sans version peut donner en plus ceux du plan : le nombre de vagues, la version visée.

**La longueur.** Une dizaine de lignes par vague, deux paragraphes. Pas de liste à puces, sauf pour trois choses réellement parallèles.

**Ce qui est écrit reste écrit.** Une vague n'édite pas la section d'une vague précédente. Seule une session de correction de la même vague reprend sa propre section, si ce que la vague apporte au jeu a changé.

## 5. Le squelette à copier

```markdown
# Suivi des vagues — <nom du chantier en clair>

**Chantier** : <ce que le chantier fait, en une ligne> — <ses identifiants dans `docs/ROADMAP.md`>
**Versions** : de `<version de départ>` à `<version visée>`
**Ouvert le** : <JJ/MM/AAAA>
**Avancement** : <K> vague(s) livrée(s) sur <M> — dernière : vague <N>, le <JJ/MM/AAAA>
**Ce qui fait foi techniquement** : le [fichier d'orchestration](<chemin relatif>) — son journal donne l'état de chaque vague ; ses décisions de conception sont dans <lien vers le document de décisions>
**Modèle** : [`_modele_suivi.md`](_modele_suivi.md)

---

## Le chantier en quelques lignes

<Ce qui n'allait pas ou ce qui manquait. Ce que le chantier change, et dans quel ordre. En combien de vagues, jusqu'à quelle version.>

---

## Vague <N> — version `<x.y.z>` — <un nom en clair>

*Livrée le <JJ/MM/AAAA>.*

**Pourquoi cette vague.** <Le problème, vu par celui qui joue. Pourquoi maintenant.>

**Ce qu'elle apporte au jeu.** <Ce qui change quand on joue. Ce qu'elle retire ou laisse en attente. Ou : rien de visible, et pourquoi c'était nécessaire.>

---

## Bilan du chantier

*Écrit à la clôture du chantier, le <JJ/MM/AAAA>.*

<Ce que le chantier entier a changé au jeu. Ce qui reste volontairement pour plus tard.>
```

`<K>` est le nombre de vagues livrées, `<N>` le numéro de la dernière : ils diffèrent dès qu'un chantier a une vague 0. Une vague sans version — une vague de préparation — écrit « sans version » dans son titre et « *Faite le* » sur sa ligne d'état. À la clôture, la ligne « Avancement » devient : `**Chantier clos le** : <JJ/MM/AAAA> — <M> vagues`.
