import 'tutorial_step.dart';

const List<TutorialStep> kTutorialSteps = [
  TutorialStep(
    titleEn: 'Welcome to Hero\'s Draft!',
    titleFr: 'Bienvenue dans Hero\'s Draft !',
    bodyEn:
        'Hero\'s Draft is a turn-based roguelike card game. Your objective is to build a powerful deck, draft unique bonuses upon level up, and defeat enemies as you climb the dangerous world map.',
    bodyFr:
        'Hero\'s Draft est un jeu de cartes roguelike au tour par tour. Votre objectif est de construire un deck puissant, de drafter des bonus uniques lors de vos passages de niveaux et de vaincre les ennemis en parcourant la carte du monde.',
    type: TutorialStepType.welcome,
  ),
  TutorialStep(
    titleEn: 'Choose Your Class',
    titleFr: 'Choisissez votre classe',
    bodyEn:
        'Every run starts here. The three classes differ by their health pool '
        'and — above all — by their passive, which decides how they earn Armor. '
        'Pick one: the rest of this tutorial will use it.',
    bodyFr:
        'Toute partie commence ici. Les trois classes se distinguent par leurs '
        'points de vie et surtout par leur passif, qui décide de la façon dont '
        'elles gagnent de l\'Armure. Choisissez-en une : la suite de ce '
        'tutoriel s\'y adaptera.',
    type: TutorialStepType.classChoice,
  ),
  TutorialStep(
    titleEn: 'Your Starting Deck',
    titleFr: 'Votre deck de départ',
    bodyEn:
        'Pick 5 cards from the common pool. Your class cards are added on top, '
        'automatically — they are unique, and unlike the others they can never '
        'be merged. This deck is the one you will play with for the rest of '
        'the tutorial.',
    bodyFr:
        'Choisissez 5 cartes dans le pool commun. Les cartes de votre classe '
        's\'y ajoutent automatiquement : elles sont uniques et, contrairement '
        'aux autres, ne pourront jamais être fusionnées. C\'est avec ce deck '
        'que vous jouerez le reste du tutoriel.',
    type: TutorialStepType.starterDeck,
  ),
  TutorialStep(
    titleEn: 'The World Map',
    titleFr: 'La Carte du Monde',
    bodyEn:
        'Your journey is represented by a map of connected nodes. You start at the bottom and choose your path upward. Each node represents a different encounter. Try tapping on nodes to see details.',
    bodyFr:
        'Votre voyage est représenté par une carte de nœuds connectés. Vous commencez en bas et choisissez votre chemin vers le haut. Chaque nœud représente une rencontre différente. Appuyez sur un nœud pour voir les détails.',
    type: TutorialStepType.map,
  ),
  TutorialStep(
    titleEn: 'Types of Encounters',
    titleFr: 'Types de Rencontres',
    bodyEn:
        'There are different types of encounters on the map:\n'
        '• ⚔️ Combat: Standard fight to gain gold and XP.\n'
        '• 👑 Elite: Challenging fight that rewards a powerful Relic.\n'
        '• 🏪 Shop: Spend your gold to buy new cards or clean your deck.\n'
        '• 🏕️ Rest: Heal your HP or forge cards to upgrade them.\n'
        '• 🎭 Event: Narrative choices with unpredictable outcomes.\n'
        '• 💀 Boss: Defeat the Boss at the top of the map to win the act.',
    bodyFr:
        'Il existe différents types de rencontres sur la carte :\n'
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
    bodyEn:
        'When entering combat, the screen layout features:\n'
        '• Center (Vertical Stack): The Enemy card (top) faces your Hero card (bottom) directly.\n'
        '• Bottom: Your fanned hand of cards, Mana crystals, and your Health bar (HP).\n'
        '• Left Side: Player active status effects ("Effets du Joueur") and your Draw pile.\n'
        '• Right Side: End Turn button, current Turn number, Enemy Intentions panel, and Discard pile.',
    bodyFr:
        'En combat, l\'interface présente la disposition suivante :\n'
        '• Centre (Empilement Vertical) : La carte de l\'Ennemi (en haut) fait face à la carte de votre Héros (en bas).\n'
        '• Bas : Votre main de cartes en éventail, vos cristaux de Mana et votre barre de Points de Vie (PV).\n'
        '• Côté Gauche : Le panneau des effets du joueur ("Effets du Joueur") et la Pioche.\n'
        '• Côté Droit : Le bouton "Fin de Tour", le numéro du Tour, le panneau des intentions ennemies ("Intentions Ennemies") et la Défausse.',
    type: TutorialStepType.combatOverview,
  ),
  TutorialStep(
    titleEn: 'Cards & Mana',
    titleFr: 'Les Cartes & le Mana',
    bodyEn:
        'Playing a card costs Mana. The cost sits in the **round cyan medallion '
        'at the top-left corner** of the card.\n\n'
        '• **Card body**: icons and numbers, not sentences — a sword for damage, '
        'a shield for Armor, and so on.\n'
        '• **Full description**: **tap** the card. It rises, its description '
        'panel opens, and every valid target lights up. Hovering only enlarges it.\n'
        '• **Three types**: Attack, Skill and Power. A Power is exiled once '
        'played — it will not come back this combat.\n\n'
        'The damage printed on a card is not the final number: your Hero\'s '
        'Attack stat is added on top, and rarity multiplies the base value.',
    bodyFr:
        'Jouer une carte coûte du Mana. Le coût est inscrit dans le **médaillon '
        'rond cyan en haut à gauche** de la carte.\n\n'
        '• **Corps de la carte** : des icônes et des chiffres, pas des phrases — '
        'une épée pour les dégâts, un bouclier pour l\'Armure, etc.\n'
        '• **Description complète** : **appuyez** sur la carte. Elle se relève, '
        'son panneau de description s\'ouvre et les cibles valides s\'illuminent. '
        'Le survol ne fait que l\'agrandir.\n'
        '• **Trois types** : Attaque, Compétence et Pouvoir. Un Pouvoir joué part '
        'à l\'exil — il ne reviendra pas de ce combat.\n\n'
        'Les dégâts imprimés sur une carte ne sont pas le chiffre final : '
        'l\'Attaque de votre héros s\'y ajoute, et la rareté multiplie la valeur '
        'de base.',
    type: TutorialStepType.cards,
  ),
  TutorialStep(
    titleEn: 'Playing Cards & Ending the Turn',
    titleFr: 'Jouer des cartes & finir le tour',
    bodyEn:
        'A turn draws 5 cards. To play one, **drag it onto its target**: an '
        'enemy for attacks, your Hero card in the centre for cards that '
        'affect you. Dragging a card to the bottom of the screen cancels it.\n\n'
        'You can also tap a card to raise it, then tap its target.\n\n'
        'When you end your turn, any leftover Mana triggers a warning — a '
        'second click confirms. Your hand is discarded, the enemy acts, and '
        'your next turn opens with your Armor back to 0 and your Mana refilled.',
    bodyFr:
        'Un tour pioche 5 cartes. Pour en jouer une, **glissez-la sur sa '
        'cible** : un ennemi pour les attaques, votre carte Héros au centre '
        'pour les cartes qui vous visent. Relâcher la carte en bas de l\'écran '
        'l\'annule.\n\n'
        'Vous pouvez aussi appuyer sur une carte pour la relever, puis appuyer '
        'sur sa cible.\n\n'
        'Quand vous finissez votre tour, le mana restant déclenche un '
        'avertissement — un second clic confirme. Votre main est défaussée, '
        'l\'ennemi agit, puis votre tour suivant s\'ouvre avec votre Armure '
        'remise à 0 et votre Mana refait.',
    type: TutorialStepType.playCard,
  ),
  TutorialStep(
    titleEn: 'Armor & Damage',
    titleFr: 'Armure & Dégâts',
    bodyEn:
        'Armor absorbs damage before your HP. Any damage left over after the '
        'Armor is gone hits your health.\n\n'
        '**Armor always resets to 0 at the start of your turn** — every class, '
        'no exception — and again at the end of a combat. It is a one-turn '
        'expense, never a stock you build up.\n\n'
        'What your class changes is *how you earn it*: that is your passive. '
        'Armor Mastery, a permanent stat, is added to every Armor gain your '
        'passive or your relics produce.',
    bodyFr:
        'L\'Armure absorbe les dégâts avant vos PV. Ce qui dépasse une fois '
        'l\'Armure épuisée entame votre santé.\n\n'
        '**L\'Armure retombe toujours à 0 au début de votre tour** — toutes '
        'classes confondues, sans exception — et de nouveau à la fin d\'un '
        'combat. C\'est une dépense pour un tour, jamais un stock qu\'on '
        'accumule.\n\n'
        'Ce que votre classe change, c\'est la *façon d\'en gagner* : c\'est '
        'votre passif. La Maîtrise d\'Armure, statistique permanente, s\'ajoute '
        'à chaque gain d\'Armure produit par votre passif ou vos reliques.',
    type: TutorialStepType.armorDamage,
  ),
  TutorialStep(
    titleEn: 'Elemental Effects',
    titleFr: 'Les Effets Élémentaires',
    bodyEn:
        'Certain cards apply elemental statuses to enemies:\n'
        '• 🟢 Poison: Deals damage at the start of their turn, decreasing by 1.\n'
        '• 🔥 Burn: Deals damage at the end of their turn, decreasing by half.\n'
        '• ❄️ Chill: Reduces the enemy\'s next attack damage.\n'
        '• ⚡ Shock: Increases the damage the enemy takes from your next attack.',
    bodyFr:
        'Certaines cartes appliquent des effets élémentaires aux ennemis :\n'
        '• 🟢 Poison : Inflige des dégâts au début de leur tour, diminue de 1.\n'
        '• 🔥 Brûlure : Inflige des dégâts à la fin de leur tour, diminue de moitié.\n'
        '• ❄️ Gel : Réduit les dégâts de la prochaine attaque de l\'ennemi.\n'
        '• ⚡ Foudre : Augmente les dégâts subis par l\'ennemi lors de votre prochaine attaque.',
    type: TutorialStepType.elements,
  ),
  TutorialStep(
    titleEn: 'Enemy Intentions',
    titleFr: 'Les Intentions Ennies',
    bodyEn:
        'Enemies announce their actions before you play. Pay attention to the intent icon above them:\n'
        '• ⚔️ Sword: Attacking (shows damage value).\n'
        '• 🛡️ Shield: Defending (adding Armor).\n'
        '• 💜 Purple Arrow: Buffing or applying status effects.\n'
        '• ❓ Question Mark: Unknown or complex action.',
    bodyFr:
        'Les ennemis annoncent leurs actions avant que vous ne jouiez. Observez l\'icône au-dessus d\'eux :\n'
        '• ⚔️ Épée : Attaque imminente (affiche la valeur des dégâts).\n'
        '• 🛡️ Bouclier : Défense imminente (génération d\'Armure).\n'
        '• 💜 Flèche Violette : Amélioration ou application de statut.\n'
        '• ❓ Point d\'interrogation : Action complexe ou inconnue.',
    type: TutorialStepType.enemies,
  ),
  TutorialStep(
    titleEn: 'Card Fusion',
    titleFr: 'La Fusion de Cartes',
    bodyEn:
        'Card merging is an out-of-combat master deck management action. When you acquire three identical cards of the same level outside of combat, they automatically merge into a single upgraded version! Upgraded cards have lower mana costs, higher values, or extra effects. Tap "Merge" to see!',
    bodyFr:
        'La fusion de cartes est une action de gestion du deck principal effectuée hors combat. Lorsque vous obtenez trois cartes identiques de même niveau en dehors des affrontements, elles fusionnent automatiquement en une version améliorée ! Les cartes améliorées ont un coût réduit, des valeurs accrues ou des effets bonus. Appuyez sur "Fusionner" pour voir !',
    type: TutorialStepType.merge,
  ),
  TutorialStep(
    titleEn: 'Experience & Leveling Up',
    titleFr: 'L\'Expérience & le Level Up',
    bodyEn:
        'Defeating enemies grants Experience Points (XP). Once the XP bar is filled, you level up! Leveling up fully restores your Mana and triggers a Reward Draft.',
    bodyFr:
        'Vaincre des ennemis rapporte des points d\'expérience (XP). Une fois la barre d\'XP remplie, vous passez au niveau supérieur ! Le passage de niveau restaure tout votre Mana et déclenche un Draft de récompense.',
    type: TutorialStepType.xp,
  ),
  TutorialStep(
    titleEn: 'Reward Draft',
    titleFr: 'Le Draft de Récompenses',
    bodyEn:
        'When you level up, you draft a reward! A selection of options is presented, which include permanent hero stat upgrades (+Max HP, +Atk, etc.) or card cloning (Mirror). Try selecting an option in the draft below.',
    bodyFr:
        'À chaque niveau gagné, vous draftez une récompense ! Une sélection d\'options s\'affiche : vous pouvez choisir des améliorations de statistiques permanentes pour votre héros (+PV Max, +Atk, etc.) ou le clonage de cartes (Miroir). Essayez de sélectionner une option ci-dessous.',
    type: TutorialStepType.draft,
  ),
  TutorialStep(
    titleEn: 'Relics & Boss Loot',
    titleFr: 'Les Reliques',
    bodyEn:
        'Relics are unique treasures that grant passive bonuses for the rest of your run. You obtain them by defeating Elite enemies, Bosses, or buying them from the Shop. Complete this step to finish the tutorial!',
    bodyFr:
        'Les Reliques sont des trésors uniques qui vous accordent des bonus passifs pour le reste de votre run. Vous les obtenez en battant des Élites, des Boss, ou à la Boutique. Terminez cette étape pour finir le tutoriel !',
    type: TutorialStepType.relics,
  ),
];

