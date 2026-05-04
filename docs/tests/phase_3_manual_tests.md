# Protocole de Tests Manuels - Phase 3 (Feedbacks, UI & UX)

Ce document liste les scénarios de test à réaliser pour valider l'implémentation des retours visuels et des améliorations d'interface.

## 1. Clarté du Combat

### 1.1 Barres de Vie (`HealthBarComponent`)
- [x] **Visuel :** Vérifier que le Héros a une barre **verte** en bas de sa carte.
- [x] **Visuel :** Vérifier que les Ennemis ont une barre **rouge** au-dessus de leur carte.
- [x] **Mise à jour :** Infliger des dégâts et vérifier que la barre diminue proportionnellement.
- [x] **Mise à jour :** Soigner le héros et vérifier que la barre remonte.

### 1.2 Intentions Ennemies (`Telegraphing`)
- [x] **Génération :** Au début du tour du joueur, vérifier qu'une icône flotte au-dessus de chaque ennemi.
- [x] **Cohérence :** Vérifier que l'icône correspond à l'action (Épée = Attaque, Bouclier = Défense, Éclair = Buff).
- [x] **Exécution :** Pendant le tour ennemi, vérifier que l'ennemi exécute bien l'action annoncée (ex: si une épée de 10 était affichée, le joueur doit perdre 10 PV).

---

## 2. Le "Juice" (Animations)

### 2.1 Screen Shake
- [x] **Attaque Joueur :** Jouer une carte d'attaque. Vérifier qu'une **légère** secousse se produit.
- [ ] **Dégâts subis :** Se laisser attaquer par un ennemi. Vérifier qu'une secousse **plus forte** se produit lors de l'impact.

### 2.2 Animations de "Dash"
- [x] **Héros :** Jouer une carte d'attaque. Vérifier que le Héros fait un bond rapide vers le haut avant de revenir.
- [x] **Ennemis :** Pendant le tour ennemi, vérifier que l'ennemi qui attaque fait un bond vers le bas (vers le héros).
- [x] **Fluidité :** Vérifier l'effet "rebond" (`bounceOut`) lors du retour à la position initiale.

### 2.3 Floating Text
- [ ] **Trajectoire :** Vérifier que les nombres de dégâts/soins s'envolent en arc de cercle aléatoire.
- [ ] **Disparition :** Vérifier que le texte disparaît progressivement en fondu (`fade out`).
- [ ] **Critiques :** Si une carte inflige de gros dégâts (ou selon le flag `isCritical`), vérifier que le texte est plus gros et "pop" avec un effet de zoom.

---

## 3. Interface Avancée

### 3.1 Bannières de Phase
- [ ] **Transition :** Cliquer sur "Fin de Tour". Vérifier qu'une bannière **"TOUR ENNEMI"** apparaît au centre.
- [ ] **Retour :** Après la riposte, vérifier qu'une bannière **"TOUR JOUEUR"** apparaît.
- [ ] **Lisibilité :** Vérifier que le texte est bien centré et que l'overlay ne bloque pas les clics une fois disparu.

### 3.2 Système de Tooltips
- [ ] **Cartes :** Maintenir un appui long sur une carte en main. Vérifier l'apparition d'un encadré détaillé (Nom, Effets détaillés).
- [ ] **Statistiques :** Maintenir un appui long sur le badge d'Armure ou de Force. Vérifier que la description explique bien la statistique.
- [ ] **Fermeture :** Relâcher l'appui. Vérifier que le tooltip disparaît immédiatement.

---

## Checklist Technique Finale
- [ ] Aucun crash lors de l'utilisation prolongée.
- [ ] `dart analyze` ne retourne aucune erreur.
- [ ] Les animations ne ralentissent pas le jeu (performances stables).
