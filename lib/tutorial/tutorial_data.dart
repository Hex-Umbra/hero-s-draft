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
        'Some cards apply status effects to enemies:\n'
        '• 🧪 Poison: damage equal to its value at the start of their turn. '
        'The value never drops — only the duration ticks down.\n'
        '• 🔥 Burn: damage at the start of their turn, then the value drops by 1. '
        'It vanishes when it reaches 0.\n'
        '• ❄️ Freeze: halves their next attack. The duration only ticks down '
        'once they have attacked.\n'
        '• ⚡ Shock: adds its value to **every** hit they take while it lasts.',
    bodyFr:
        'Certaines cartes appliquent des altérations aux ennemis :\n'
        '• 🧪 Poison : inflige sa valeur en dégâts au début de leur tour. '
        'La valeur ne baisse jamais — seule la durée décrémente.\n'
        '• 🔥 Brûlure : inflige des dégâts au début de leur tour, puis la valeur '
        'perd 1. Elle disparaît en atteignant 0.\n'
        '• ❄️ Gel : divise par deux leur prochaine attaque. La durée ne '
        'décrémente qu\'une fois qu\'ils ont attaqué.\n'
        '• ⚡ Électrocution : ajoute sa valeur à **chaque** coup qu\'ils '
        'subissent tant qu\'elle dure.',
    type: TutorialStepType.elements,
  ),
  TutorialStep(
    titleEn: 'Enemy Intentions',
    titleFr: 'Les Intentions Ennemies',
    bodyEn:
        'Enemies announce what they will do before you play. Their intent is '
        'not shown above them — read it in the **Enemy Intentions panel, '
        'bottom-right**.\n\n'
        'There are three: attack, defend, and buff. Attacks change icon and '
        'colour with their size — Quick, Attack, Heavy, Devastating — so a '
        'glance is enough to tell a scratch from a threat.\n\n'
        'The number is recalculated live: it grows with the enemy\'s level and '
        'accumulated Strength, and halves while they are Frozen.',
    bodyFr:
        'Les ennemis annoncent leur action avant que vous ne jouiez. Leur '
        'intention n\'est pas affichée au-dessus d\'eux : elle se lit dans le '
        'panneau **Intentions Ennemies, en bas à droite**.\n\n'
        'Il en existe trois : attaque, défense et renforcement. Les attaques '
        'changent d\'icône et de couleur selon leur ampleur — Rapide, Attaque, '
        'Lourde, Dévastatrice — pour distinguer d\'un coup d\'œil l\'égratignure '
        'de la menace.\n\n'
        'Le chiffre est recalculé en direct : il monte avec le niveau de '
        'l\'ennemi et sa Force accumulée, et se divise par deux tant qu\'il est '
        'Gelé.',
    type: TutorialStepType.enemies,
  ),
  TutorialStep(
    titleEn: 'Card Merging',
    titleFr: 'La Fusion de Cartes',
    bodyEn:
        'Merging is **manual**, and only outside combat. Open your Deck: when '
        'you hold three copies of the same card **at the same rarity**, the '
        'group offers a merge. Select exactly three, confirm, and they become '
        'one card of the next rarity up.\n\n'
        'Rarity **never changes a card\'s Mana cost** — it multiplies its '
        'values: ×1.2 uncommon, ×1.4 rare, ×1.6 epic, ×2.0 legendary.\n\n'
        'Forge upgrades carried by the three copies are inherited and merged, '
        'capped by the new rarity\'s capacity. Your class cards are unique, and '
        'unique cards never merge.',
    bodyFr:
        'La fusion est **manuelle**, et seulement hors combat. Ouvrez votre '
        'Deck : lorsque vous détenez trois exemplaires d\'une même carte **de '
        'même rareté**, le groupe propose une fusion. Sélectionnez-en exactement '
        'trois, confirmez, et elles deviennent une carte de la rareté '
        'supérieure.\n\n'
        'La rareté **ne change jamais le coût en Mana** — elle multiplie les '
        'valeurs : ×1,2 peu commun, ×1,4 rare, ×1,6 épique, ×2,0 légendaire.\n\n'
        'Les améliorations de forge des trois exemplaires sont héritées et '
        'consolidées, dans la limite de la capacité de la nouvelle rareté. Vos '
        'cartes de classe sont uniques, et une carte unique ne fusionne jamais.',
    type: TutorialStepType.merge,
  ),
  TutorialStep(
    titleEn: 'Experience & Leveling Up',
    titleFr: 'L\'Expérience & le Level Up',
    bodyEn:
        'Defeating enemies grants XP. Each level costs more than the last: '
        '100, then 150, then 225, and so on.\n\n'
        'Overflow XP carries into the next level, and if you gain several '
        'levels at once the rewards stack — **the world map stays locked until '
        'you have drafted them all**.\n\n'
        'Winning a fight refills your Mana and clears your skill cooldowns, '
        'whether or not it also levels you up. Note that your hero\'s XP '
        'level and the "Level" shown next to the Act are two different '
        'counters: the second is the one a victory advances, and it tracks '
        'your progress across the map.',
    bodyFr:
        'Vaincre des ennemis rapporte de l\'XP. Chaque niveau coûte plus cher '
        'que le précédent : 100, puis 150, puis 225, et ainsi de suite.\n\n'
        'L\'XP excédentaire est reportée sur le niveau suivant, et si vous '
        'gagnez plusieurs niveaux d\'un coup les récompenses s\'empilent — **la '
        'carte du monde reste verrouillée tant que vous ne les avez pas toutes '
        'draftées**.\n\n'
        'Gagner un combat restaure votre Mana et réinitialise vos temps de '
        'recharge, que ce combat vous fasse gagner un niveau ou non. '
        'Attention : le niveau d\'XP de votre héros et le « Niveau » affiché '
        'à côté de l\'Acte sont deux compteurs distincts : c\'est le second '
        'qu\'une victoire fait avancer, et il suit votre progression sur la '
        'carte.',
    type: TutorialStepType.xp,
  ),
  TutorialStep(
    titleEn: 'Reward Draft',
    titleFr: 'Le Draft de Récompenses',
    bodyEn:
        'Each level grants a draft. Three options are rolled from six kinds — '
        'Vitality, Sharpening, Steel Forge, Wisdom, Precision, Ferocity — and '
        'up to two **Mythic** options can appear on top: the Four-Leaf Clover '
        'and the Mirror.\n\n'
        'Rarity decides how much you get. Luck raises your odds on every roll, '
        'which makes the Clover the option that improves all the others.\n\n'
        'Careful with Steel Forge: it grants **Armor Mastery**, added to the '
        'Armor your passive and relics produce — not a flat block of Armor.',
    bodyFr:
        'Chaque niveau donne droit à un draft. Trois options sont tirées parmi '
        'six types — Vitalité, Aiguisage, Forge d\'Acier, Sagesse, Précision, '
        'Férocité — et jusqu\'à deux options **Mythiques** peuvent s\'y ajouter : '
        'le Trèfle à 4 feuilles et le Miroir.\n\n'
        'La rareté décide de l\'ampleur du gain. La Chance améliore vos '
        'probabilités à chaque tirage, ce qui fait du Trèfle l\'option qui '
        'améliore toutes les autres.\n\n'
        'Attention à la Forge d\'Acier : elle donne de la **Maîtrise d\'Armure**, '
        'ajoutée à l\'Armure que produisent votre passif et vos reliques — pas '
        'un bloc d\'Armure directe.',
    type: TutorialStepType.draft,
  ),
  TutorialStep(
    titleEn: 'Relics',
    titleFr: 'Les Reliques',
    bodyEn:
        'Relics grant passive bonuses for the rest of your run. You get them '
        'from **Elite** fights, from the **improved-relic Boss** — only that '
        'one of the three — and from the **Relic Shrine**, which trades several '
        'sacrificed relics for a better one. The Shop sells none.\n\n'
        'Each relic fires on a specific trigger: start of run, start of combat, '
        'start or end of turn, when you play a card, when you play an attack, '
        'or when an enemy dies. Reading the trigger matters as much as reading '
        'the effect.',
    bodyFr:
        'Les Reliques accordent des bonus passifs pour le reste de votre run. '
        'Vous les obtenez en combat **Élite**, auprès du **Boss à relique '
        'améliorée** — celui-là seulement sur les trois — et à l\'**Autel des '
        'Reliques**, qui échange plusieurs reliques sacrifiées contre une '
        'meilleure. La Boutique n\'en vend aucune.\n\n'
        'Chaque relique se déclenche sur un moment précis : début de run, début '
        'de combat, début ou fin de tour, quand vous jouez une carte, quand vous '
        'jouez une attaque, ou quand un ennemi meurt. Lire le déclencheur compte '
        'autant que lire l\'effet.',
    type: TutorialStepType.relics,
  ),
];

