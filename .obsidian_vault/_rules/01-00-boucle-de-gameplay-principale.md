## 1. Boucle de Gameplay Principale (Core Loop)

La progression dans **Hero's Draft** est structurée autour d'une boucle classique de roguelike deckbuilder enrichie d'une mécanique de draft tactique de héros et de cartes.

> [!IMPORTANT]
> **Persistance de Run (Autosave, v3.2.0)** : Depuis l'introduction du `SaveService`, l'écran d'accueil (`HomeScreen`) propose un bouton **« Continuer »** (visible uniquement si une sauvegarde valide existe) qui court-circuite entièrement les étapes de Sélection de Classe et de Draft Deck Initial pour reprendre directement sur la `MapScreen`, avec le deck, l'or, les reliques et l'état de forge exacts du dernier checkpoint résolu. Voir §3.12 pour les règles métier détaillées de ce mécanisme.

```
[Écran d'Accueil (HomeScreen)]
       │
       ├─► [Continuer] (si sauvegarde existante) ──────────────────────┐
       │                                                                │
       ▼                                                                │
[Sélection de Classe (HeroSelectionScreen)]                             │
  Paladin (100 HP, 3 Mana, 5 Atk, passif: regenArmor)
  Berserker (80 HP, 3 Mana, 15 Atk, passif: berserkerArmor)
  Mage (60 HP, 3 Mana, 10 Atk, passif: spellArmor)
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
      [Draft de Récompense (DraftScreen)] (Choix de carte de combat normal)
        │
        ▼
      [Évaluation Auto-Merge (3→1)] (Fusion 3× identiques → 1× de rareté supérieure)
        │
        ▼
      [Retour à la Carte (MapScreen)] (Si montée de niveau : pendingDrafts > 0)
```
