### 2.8. ✨ Évolutions de Signature

Les signatures de classe ([`_rules/02-2`](02-2-systeme-de-heros.md) §Signatures) évoluent avec le
niveau du héros — P-42 tranche 1, partie 3, livrée sur la branche de la vague 5, en attente du test,
de la PR, de la fusion et du tag du propriétaire — [ADR-114](../_adr/ADR-114-les-evolutions-de-signature.md), dont le
tirage et l'écran sont amendés par [ADR-115](../_adr/ADR-115-le-choix-libre-des-evolutions-et-les-rideaux-de-la-carte.md) (D78 à D82).
Architecture : [`_patterns/03-8`](../_patterns/03-8-signatureevolutionrules-regles-pures-des-evolutions.md)
(les règles), [`_patterns/05-12`](../_patterns/05-12-barre-de-signatures-bande-et-calque.md) (la tuile).

#### 2.8.1. Le rythme

> [!IMPORTANT]
> **Tous les 5 niveaux du héros, chaque signature gagne un niveau** (D19, D21) : une évolution
> de **son propre pool**, choisie parmi **tout ce que le palier admet** — rien n'est tiré (D78). **Mineure aux niveaux impairs** de la signature
> (héros 5, 15, 25…), **majeure aux pairs** (10, 20, 30…), sans plafond. Une mineure se reprend et
> monte d'un niveau ; une majeure ne se prend qu'une fois.

- **L'attente se dérive, jamais stockée** : `max(0, niveau du héros ~/ 5 − niveau de la
  signature)`. Un saut de 4 à 10 laisse deux mineures puis deux majeures à choisir.
- **Deux signatures en attente se choisissent ensemble**, sur un seul écran (D79), dans l'ordre de
  `skills` de `class.json` ; sur un saut de plusieurs paliers, l'écran se rouvre pour le suivant.
- **Ce que le palier admet** : au palier mineur, les trois mineures ; au palier majeur, les
  majeures éligibles, **plus toutes les mineures** quand il reste moins de trois majeures éligibles
  (Q6). Une majeure prise, ou exclue par une majeure prise (`excludes`, lu dans les deux sens, Q7),
  ne se propose plus.

#### 2.8.2. Les six pools — 3 mineures, 4 majeures chacun

| Signature | Mineures | Majeures |
|:---|:---|:---|
| *Châtiment* (`smite`) | *Zèle* (+2 dégâts), *Égide* (+2 Armure), *Ardeur* (+5 % de critique) | *Célérité*, *Sentence* (1 Faiblesse 2 tours), *Rayonnement* (tous les ennemis), *Dévotion* (−1 mana) |
| *Bouclier Sacré* (`holy_shield`) | *Garde* (+2 Armure), *Miséricorde* (+1 soin), *Résolution* (+1 Puissance) | *Célérité*, *Consécration* (2 Puissance 2 tours), *Inspiration* (pioche 1), *Égide durable* (3 Armure 2 tours) |
| *Frappe Téméraire* (`reckless_strike`) | *Brutalité* (+3 dégâts), *Instinct* (+5 % de critique), *Fracas* (+1 Vulnérable) | *Célérité* ⟂ *Dévastation* (+10 dégâts, recharge +1), *Fauchage* (tous les ennemis), *Sang-froid* (−1 mana) |
| *Posture de Rage* (`rage_form`) | *Colère* (+1 Puissance), *Carapace* (+2 Armure), *Second souffle* (+2 soin) | *Célérité*, *Démence* (1 Éveil de Puissance 3 tours), *Ralliement* (pioche +1), *Furie* (−1 mana) |
| *Projectile Magique* (`magic_missile`) | *Acuité* (+2 dégâts), *Précision* (+5 % de critique), *Braise* (+1 Brûlure) | *Célérité* ⟂ *Surcharge* (+8 dégâts, recharge +1), *Nova* (tous les ennemis), *Mise à nu* (2 Vulnérable 2 tours) |
| *Surtension de Mana* (`mana_surge`) | *Bouclier de mana* (+2 Armure), *Harmonie* (+1 Puissance), *Clarté* (+1 soin) | *Prescience* (pioche +1), *Glyphe de garde* (3 Armure 2 tours), *Exaltation* (2 Puissance 2 tours), *Sérénité* (soin 4) — **pas de *Célérité*** |

⟂ : les deux majeures s'excluent. Valeurs par niveau de mineure ; **des ordres de grandeur**, que le
test du propriétaire corrige. *Célérité* (`haste`) raccourcit la recharge d'un tour, **jamais sous
1** (D54) ; elle porte le même id dans cinq pools mais reste déclarée dans chaque fichier (D7). Sur
*Posture de Rage*, l'Armure de *Carapace* devient Puissance comme toute Armure du Berserker.

#### 2.8.3. Ce qu'une évolution change

- **Chiffrée** — `flatBonus` (un effet existant, au niveau), `reduceCost`, `cooldown` — ou
  **verbale** — `addEffect` (un effet ajouté), `critBonus`, `target: allEnemies` (une majeure sur
  une signature à cible unique). Une évolution n'est pas les deux.
- **La signature évoluée** (`SignatureInstance.asCard`) : sa cible, celle de la dernière majeure
  `target` prise ; son coût, réduit par `reduceCost` ; sa recharge, `max(1, base + Σ cooldown)` ;
  ses effets, augmentés ou ajoutés dans l'ordre de première prise. Elle se joue comme avant, comme
  une carte de son type.
- **Les descriptions des signatures sont des gabarits** (`{damage}`, `{armor}`, `{heal}`,
  `{might}`, `{draw}`, `{gain_mana}`), remplis des valeurs évoluées, suivis des phrases des
  évolutions verbales.

#### 2.8.4. Où le joueur les voit

| Lieu | Ce qu'il montre |
|:---|:---|
| **Le rideau de la carte** | Reste tant qu'un draft de niveau **ou** une évolution attend ; le toucher ouvre d'abord le draft, puis l'écran des évolutions. Les nœuds restent verrouillés, la barre du haut accessible. **Une forme par ce qui attend**, à la couleur de la classe (D80 à D82) : un draft, un bandeau transparent sur ses bords, sur des flèches qui montent (« LEVEL UP ! ») ; une mineure, un bandeau plein avec son icône (« ÉVOLUTION MINEURE ») ; une majeure, un médaillon doré et des rayons (« ÉVOLUTION MAJEURE »), qui l'emporte si les rangs diffèrent |
| **L'écran d'évolution** | Les signatures en attente **ensemble** (D79) : une colonne chacune, sa fiche — le résultat du choix — puis son pool entier, rangé en ce qui se prend maintenant, l'autre rang et le niveau du héros qui l'ouvre, les majeures prises, les majeures exclues et par laquelle ; « Niveau 1 → 2 » pour une mineure reprise. Un seul bouton, actif quand chacune a son choix. Sur téléphone, un onglet par signature ; sur une fenêtre basse, deux colonnes sans fiche. Le retour ramène au rideau sans rien perdre |
| **La tuile de combat** | **Plus de texte au repos** (PN12 (d)) : une icône par effet évolué avec sa valeur, trois par ligne ; un badge « Niv. n » au bout de la ligne du type, en ambre d'accent quand la tuile répond (PN13) ; une puce par évolution prise, sous la bande. **L'appui long déroule la liste**, une phrase par icône, par-dessus les tuiles voisines, dans **tous** les états, inactive comprise (P-5) — il ne joue, n'arme ni ne désarme rien ; relâcher la replie |
| **Mon Deck** | En tête, une fiche par signature de la run : type, coût, recharge et description évolués, évolutions prises et leur niveau, la prochaine par son rang et le niveau du héros, sans chiffre d'XP |
| **Hors run** | Carte de classe et dictionnaire : la signature de base, gabarit rempli de la donnée, sans badge ni icône |
| **Le menu de debug** | Onglet Héros, section « Évolutions de signature » : pose une évolution admissible par les mêmes règles, sans attente ni sauvegarde (P-7) |

Les icônes de la bande, de la liste et des puces viennent de la table d'icônes d'effet
([`_rules/07-00`](07-00-architecture-des-donnees.md) §7.1) ; celles d'une évolution, de son fichier.

#### 2.8.5. La sauvegarde

Les évolutions se sauvegardent sous `signatureEvolutions` — une liste de références `id:niveau`
par signature, dans l'ordre de première prise, **toujours écrite**, vide s'il n'y a rien. Une
référence dont l'id a quitté le pool est signalée au chargement ; une référence mal formée ou une
majeure impossible est corrigée sans rapport. Chaque choix déclenche la sauvegarde
([`_rules/03-13`](03-13-persistance-de-run.md)).
