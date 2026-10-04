## 1. Boucle de Gameplay Principale (Core Loop)

La progression dans **Hero's Draft** est structurée autour d'une boucle classique de roguelike deckbuilder enrichie d'une mécanique de draft tactique de héros et de cartes.

> [!IMPORTANT]
> **Persistance de Run (Autosave, v3.2.0)** : Depuis l'introduction du `SaveService`, l'écran d'accueil (`HomeScreen`) propose un bouton **« Continuer »** (visible uniquement si une sauvegarde valide existe) qui court-circuite entièrement les étapes de Sélection de Classe et de Draft Deck Initial pour reprendre directement sur la `MapScreen`, avec le deck — runes comprises —, l'or et les reliques exacts du dernier checkpoint résolu. Voir §3.13 pour les règles métier détaillées de ce mécanisme.

```
[Écran d'Accueil (HomeScreen)]
       │
       ├─► [Continuer] (si sauvegarde existante) ──────────────────────┐
       │                                                                │
       ▼                                                                │
[Sélection de Classe (ClassSelectionScreen)] — un passif choisi parmi trois │
  Paladin (100 PV, 3 Mana, Maîtrise 1 — Puissance sur tout)
  Berserker (80 PV, 3 Mana, Critique 10 — Puissance sur les Attaques, armure convertie en Puissance)
  Mage (60 PV, 3 Mana — Puissance sur les Compétences et les altérations)
       │
       ▼
[Draft Deck Initial (StarterDeckDraftScreen)]
  Constitution du deck : choix de 5 cartes globales + cartes de classe uniques chargées via compétences
       │                                                                │
       ▼                                                                ▼
[Carte Stratégique (MapScreen)] ◄──────────────────────────────────────┘ ◄─── Graphe Acyclique Dirigé (10 étages)
  │   ▲ (Si pendingDrafts > 0 : Overlay Level Up bloquant → DraftScreen)
  │   │
  ├─► [Écrans Spécifiques] : Boutique (ShopScreen), Feu de Camp (CampfireScreen), Événement (EventScreen)
  │
  └─► [Combat (GameScreen)]
        │
        ▼
      [Récompenses de combat] (XP et or ; une carte trouvée en combat normal, une ou deux en élite — avec sa relique —,
                               commune, ajoutée au deck sans choix ; le boss garde la récompense de son type :
                               des clones, le triple d'XP et d'or avec une rune montée d'un niveau, ou une relique)
        │
        ▼
      [Évaluation Auto-Merge (3→1)] (Fusion 3× identiques → 1× de rareté supérieure)
        │
        ▼
      [Retour à la Carte (MapScreen)] (Si montée de niveau : pendingDrafts > 0)
```

La carte trouvée après chaque combat, et le prix d'un niveau par acte, sont du lot E3 de P-43 —
branche de la vague 3, en attente du propriétaire : règles en [`_rules/06-00`](06-00-economie-de-jeu.md)
§6.4 et §6.5, décision en [ADR-107](../_adr/ADR-107-trouvaille-et-progression.md).
