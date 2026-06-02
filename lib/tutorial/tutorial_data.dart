import 'tutorial_step.dart';

const List<TutorialStep> kTutorialSteps = [
  TutorialStep(
    titleEn: 'Welcome to Hero\'s Draft!',
    titleFr: 'Bienvenue dans Hero\'s Draft !',
    bodyEn: 'Hero\'s Draft is a turn-based roguelike card game. Your objective is to build a powerful deck, draft unique bonuses upon level up, and defeat enemies as you climb the dangerous world map.',
    bodyFr: 'Hero\'s Draft est un jeu de cartes roguelike au tour par tour. Votre objectif est de construire un deck puissant, de drafter des bonus uniques lors de vos passages de niveaux et de vaincre les ennemis en parcourant la carte du monde.',
    type: TutorialStepType.welcome,
  ),
  TutorialStep(
    titleEn: 'The World Map',
    titleFr: 'La Carte du Monde',
    bodyEn: 'Your journey is represented by a map of connected nodes. You start at the bottom and choose your path upward. Each node represents a different encounter. Try tapping on nodes to see details.',
    bodyFr: 'Votre voyage est représenté par une carte de nœuds connectés. Vous commencez en bas et choisissez votre chemin vers le haut. Chaque nœud représente une rencontre différente. Appuyez sur un nœud pour voir les détails.',
    type: TutorialStepType.map,
  ),
  TutorialStep(
    titleEn: 'Types of Encounters',
    titleFr: 'Types de Rencontres',
    bodyEn: 'There are different types of encounters on the map:\n'
        '• ⚔️ Combat: Standard fight to gain gold and XP.\n'
        '• 👑 Elite: Challenging fight that rewards a powerful Relic.\n'
        '• 🏪 Shop: Spend your gold to buy new cards or clean your deck.\n'
        '• 🏕️ Rest: Heal your HP or forge cards to upgrade them.\n'
        '• 🎭 Event: Narrative choices with unpredictable outcomes.\n'
        '• 💀 Boss: Defeat the Boss at the top of the map to win the act.',
    bodyFr: 'Il existe différents types de rencontres sur la carte :\n'
        '• ⚔️ Combat : Combat standard pour gagner de l\'or et de l\'XP.\n'
        '• 👑 Élite : Combat difficile qui récompense par une puissante Relique.\n'
        '• 🏪 Boutique : Dépensez votre or pour acheter des cartes ou épurer votre deck.\n'
        '• 🏕️ Repos : Soignez vos PV ou forgez des cartes pour les améliorer.\n'
        '• 🎭 Événement : Choix narratifs aux conséquences imprévisibles.\n'
        '• 💀 Boss : Battez le Boss au sommet pour remporter l\'acte.',
    type: TutorialStepType.nodeTypes,
  ),
  TutorialStep(
    titleEn: 'Combat Screen Overview',
    titleFr: 'Le Combat — Vue d\'ensemble',
    bodyEn: 'When entering combat, the screen is split into three main areas:\n'
        '• Top: Enemy zone showing their health, armor, and planned intents.\n'
        '• Middle: Hero info with Health (HP), Armor (Block), and Mana crystals.\n'
        '• Bottom: Your hand of cards and the End Turn button.',
    bodyFr: 'En combat, l\'écran est divisé en trois zones principales :\n'
        '• Haut : Zone ennemie affichant leurs PV, armure et intentions prévues.\n'
        '• Milieu : Infos du Héros avec les Points de Vie (PV), l\'Armure et le Mana.\n'
        '• Bas : Votre main de cartes et le bouton Fin de Tour.',
    type: TutorialStepType.combatOverview,
  ),
  TutorialStep(
    titleEn: 'Cards & Mana',
    titleFr: 'Les Cartes & le Mana',
    bodyEn: 'To play cards, you must spend Mana crystals (💎). Each card has a cost shown in its top corner. Mana refills completely at the start of your turn. Tap a card to inspect it.',
    bodyFr: 'Pour jouer des cartes, vous devez dépenser des cristaux de Mana (💎). Chaque carte a un coût affiché dans son coin supérieur. Le Mana se remplit au début de chaque tour. Appuyez sur une carte pour l\'examiner.',
    type: TutorialStepType.cards,
  ),
  TutorialStep(
    titleEn: 'Playing a Card',
    titleFr: 'Jouer une carte',
    bodyEn: 'Let\'s try playing a card! Select the "Basic Strike" card by tapping it, then tap the Slime enemy to attack it and reduce its HP. Remember, cards apply their effects immediately when played.',
    bodyFr: 'Essayons de jouer une carte ! Sélectionnez la carte "Frappe Basique" en appuyant dessus, puis appuyez sur le Slime pour l\'attaquer et réduire ses PV. Les cartes appliquent leurs effets immédiatement.',
    type: TutorialStepType.playCard,
  ),
  TutorialStep(
    titleEn: 'Armor & Damage',
    titleFr: 'Armure & Dégâts',
    bodyEn: 'Armor (🛡️) acts as a temporary shield. When you take damage, it is subtracted from your Armor first. Any remaining damage reduces your HP. Armor resets or decays depending on your character class.',
    bodyFr: 'L\'Armure (🛡️) agit comme un bouclier temporaire. Lorsque vous subissez des dégâts, ils sont d\'abord déduits de votre Armure. Les dégâts restants réduisent vos PV. L\'Armure se réinitialise ou diminue selon votre classe.',
    type: TutorialStepType.armorDamage,
  ),
  TutorialStep(
    titleEn: 'Elemental Effects',
    titleFr: 'Les Effets Élémentaires',
    bodyEn: 'Certain cards apply elemental statuses to enemies:\n'
        '• 🟢 Poison: Deals damage at the start of their turn, decreasing by 1.\n'
        '• 🔥 Burn: Deals damage at the end of their turn, decreasing by half.\n'
        '• ❄️ Chill: Reduces the enemy\'s next attack damage.\n'
        '• ⚡ Shock: Increases the damage the enemy takes from your next attack.',
    bodyFr: 'Certaines cartes appliquent des effets élémentaires aux ennemis :\n'
        '• 🟢 Poison : Inflige des dégâts au début de leur tour, diminue de 1.\n'
        '• 🔥 Brûlure : Inflige des dégâts à la fin de leur tour, diminue de moitié.\n'
        '• ❄️ Gel : Réduit les dégâts de la prochaine attaque de l\'ennemi.\n'
        '• ⚡ Foudre : Augmente les dégâts subis par l\'ennemi lors de votre prochaine attaque.',
    type: TutorialStepType.elements,
  ),
  TutorialStep(
    titleEn: 'Enemy Intentions',
    titleFr: 'Les Intentions Ennies',
    bodyEn: 'Enemies announce their actions before you play. Pay attention to the intent icon above them:\n'
        '• ⚔️ Sword: Attacking (shows damage value).\n'
        '• 🛡️ Shield: Defending (adding Armor).\n'
        '• 💜 Purple Arrow: Buffing or applying status effects.\n'
        '• ❓ Question Mark: Unknown or complex action.',
    bodyFr: 'Les ennemis annoncent leurs actions avant que vous ne jouiez. Observez l\'icône au-dessus d\'eux :\n'
        '• ⚔️ Épée : Attaque imminente (affiche la valeur des dégâts).\n'
        '• 🛡️ Bouclier : Défense imminente (génération d\'Armure).\n'
        '• 💜 Flèche Violette : Amélioration ou application de statut.\n'
        '• ❓ Point d\'interrogation : Action complexe ou inconnue.',
    type: TutorialStepType.enemies,
  ),
  TutorialStep(
    titleEn: 'Card Fusion',
    titleFr: 'La Fusion de Cartes',
    bodyEn: 'When you acquire three identical cards of the same level, they automatically merge into a single upgraded version! Upgraded cards have lower mana costs, higher values, or extra effects. Tap "Merge" to see!',
    bodyFr: 'Lorsque vous possédez trois cartes identiques de même niveau, elles fusionnent automatiquement en une version améliorée ! Les cartes améliorées ont un coût réduit, des valeurs accrues ou des effets bonus. Appuyez sur "Fusionner" !',
    type: TutorialStepType.merge,
  ),
  TutorialStep(
    titleEn: 'Experience & Leveling Up',
    titleFr: 'L\'Expérience & le Level Up',
    bodyEn: 'Defeating enemies grants Experience Points (XP). Once the XP bar is filled, you level up! Leveling up fully restores your Mana and triggers a Reward Draft.',
    bodyFr: 'Vaincre des ennemis rapporte des points d\'expérience (XP). Une fois la barre d\'XP remplie, vous passez au niveau supérieur ! Le passage de niveau restaure tout votre Mana et déclenche un Draft de récompense.',
    type: TutorialStepType.xp,
  ),
  TutorialStep(
    titleEn: 'Reward Draft',
    titleFr: 'Le Draft de Récompenses',
    bodyEn: 'When you level up, you draft a reward! A reel of cards is presented, and you select one to add to your deck or gain a permanent bonus. Try selecting a card in the draft below.',
    bodyFr: 'À chaque niveau gagné, vous draftez une récompense ! Une sélection de cartes s\'affiche, et vous en choisissez une pour l\'ajouter à votre deck ou obtenir un bonus permanent. Essayez de sélectionner une carte ci-dessous.',
    type: TutorialStepType.draft,
  ),
  TutorialStep(
    titleEn: 'Relics & Boss Loot',
    titleFr: 'Les Reliques',
    bodyEn: 'Relics are unique treasures that grant passive bonuses for the rest of your run. You obtain them by defeating Elite enemies, Bosses, or buying them from the Shop. Complete this step to finish the tutorial!',
    bodyFr: 'Les Reliques sont des trésors uniques qui vous accordent des bonus passifs pour le reste de votre run. Vous les obtenez en battant des Élites, des Boss, ou à la Boutique. Terminez cette étape pour finir le tutoriel !',
    type: TutorialStepType.relics,
  ),
];
