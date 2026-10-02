# Rotation de `activeContext.md` — 2026-10-02 (2)

Sortie du bloc « 3 dernières livraisons » de `../_memory_bank/activeContext.md` le **2026-10-02**,
poussée par l'entrée de la **vague 2 du programme P-43 → P-42 → P-44 lot 1** — lot E2 de P-43,
« fusion = forge », livré sur la branche `feat/v0.5.4-p43-e2-fusion-forge`. FIFO strict à 3 : la
4ᵉ livraison sort. Recopiée **telle quelle** — chiffres, dates et affirmations intouchés.

## La livraison sortie

**Le filtre de classe sur les pools d'offre — un prédicat, deux appels, un piège gardé**
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
