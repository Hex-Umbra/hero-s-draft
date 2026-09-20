# Archive — livraison sortie d'`activeContext.md` le 2026-09-20

Rotation FIFO du plafond de 3 livraisons, provoquée par l'entrée de **P-41 lot D, partie 1**
(PR #44). Texte conservé **verbatim**, tel qu'il figurait dans
`.obsidian_vault/_memory_bank/activeContext.md` avant la passe.

---

3. **P-41 lot B, partie 2 — l'identité de classe** (2026-09-18, **fusionné dans `main` par la
   PR #41**, merge `5086272`, 18 commits, `74c54cf` → `83e65b9`) — **la première livraison de P-41 que le
   joueur ressent.** Le Paladin renforce tout, le Berserker ses seules Attaques, le Mage ses
   Compétences et ses altérations. Le Berserker **n'a plus jamais d'armure** : toute source devient
   une Puissance d'un tour, par une `statRules` de son `class.json` qu'applique
   `StatGains.apply(stats, gain, rules)`, troisième paramètre désormais obligatoire. Les **neuf
   passifs** remplacent les trois (`berserker_armor` et `spell_armor` supprimés) ; un passif choisit
   son déclencheur par sa donnée, compte par un statut caché, et reçoit ce qu'il ne peut recalculer.
   Stats de départ propres (Maîtrise 1 au Paladin, 10 % de critique au Berserker) ; la Puissance
   porte un éclair. **1021 tests** (+83), `dart analyze` propre —
   [ADR-097](../_adr/ADR-097-puissance-unique-orientee-par-la-classe.md), section « Partie 2 ».
