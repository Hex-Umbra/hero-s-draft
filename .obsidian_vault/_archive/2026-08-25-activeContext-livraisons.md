# Archive — activeContext.md, livraisons (2026-08-25)

Livraison sortie de la liste « 3 dernières livraisons » de `../_memory_bank/activeContext.md`
par débordement du plafond FIFO, lors de la synchronisation du 25 août 2026 (livraison de
P-03, système audio). Conservée verbatim. **Ne pas éditer.**

3. **Assainissement du système de pioche — P-02** (2026-08-06) — le remélange de la défausse
   devient automatique et n'intervient plus qu'une fois la pioche réellement vide (l'ancien
   seuil `< 5` détruisait la capacité à compter son deck) ; la pioche s'arrête net sur main
   pleine sans rien consommer ; `TurnPhaseManager` gagne `startPlayerCombat()` /
   `startPlayerTurn()`, de sorte que le tour 1 et le tour N+1 empruntent enfin le même code ;
   l'aléatoire devient injectable et six éléments de code mort disparaissent. Première
   relique touchant au deck (`scholars_satchel`). **+18 tests neufs, 2 réécrits** — la
   ROADMAP en annonçait 6. Voir
   [ADR-078](../_adr/ADR-078-assainissement-du-systeme-de-pioche-remelange-a-sec.md).
