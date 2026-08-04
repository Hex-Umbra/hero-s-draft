## 4. Altérations d'État & Statuts (Status Effects)

Les combattants accumulent des altérations d'état. Le décompte (`tickStatuses()`) s'opère au début de leur tour respectif.

### 4.1. Statuts Implémentés

| Statut (`id`) | Type | Empilable | Effet Mécanique | Tick |
|:---|:---:|:---:|:---|:---|
| `poison` | Debuff | Oui | Inflige dégâts directs = valeur au début du tour | Durée -1 chaque tour |
| `strength` | Buff | Oui | Ajoute sa valeur à `effectiveAttaque` pour les dégâts physiques | Durée -1 chaque tour |
| `weakness` | Debuff | Oui | Réduit les dégâts physiques infligés de **25%** (`×0.75`) | Durée -1 chaque tour |
| `strength_regen` | Buff | Oui | Ajoute sa valeur au statut `strength` au début du tour | Durée -1 chaque tour |
| `armor_regen` | Buff | Oui | Génère de l'armure = valeur au début du tour | Durée -1 chaque tour |
| `burn` | Debuff | Oui | Inflige des dégâts de feu = valeur active au début du tour. Le tick réduit la valeur et la durée de 1. | Durée -1 chaque tour |
| `freeze` | Debuff | Oui | Réduit les dégâts de la prochaine attaque de l'ennemi de **50%** (calculé dans l'intention affichée). Ne se dissipe plus en début de tour mais après la résolution de son action d'attaque. | Durée décrémentée après l'action d'attaque |
| `shock` | Debuff | Oui | Ajoute sa valeur active cumulée à tout dégât d'attaque direct subi par la cible. | Durée -1 chaque tour |
| `vulnerable` | Debuff | Oui | Augmente universellement tous les dégâts reçus de **50%** (arrondi). Affecte autant le Héros que les Ennemis. | Durée -1 chaque tour |

### 4.2. Statuts Partiellement Implémentés
Aucun. Tous les statuts décrits ci-dessus sont 100% implémentés et opérationnels dans le calcul des dégâts.

### 4.3. Mécanique de Stacking (`StatusEffect.combine`)

```dart
if (isStackable) {
  value += other.value;
  duration = max(duration, other.duration);
} else {
  value = max(value, other.value);
  duration = max(duration, other.duration);
}
```
