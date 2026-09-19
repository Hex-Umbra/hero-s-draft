import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import '../../game/systems/passive_availability.dart';
import '../../models/data/hero_data.dart';
import '../../services/game_data_service.dart';
import '../../services/audio/audio_providers.dart';
import '../../services/audio/music_scene.dart';
import 'card_dictionary_screen.dart';
import 'starter_deck_draft_screen.dart';
import '../../models/data/model_extensions.dart';
import '../widgets/class_identity.dart';
import '../widgets/class_passive_list.dart';
import '../widgets/screen_scaffold.dart';
import '../widgets/page_header.dart';

class ClassSelectionScreen extends ConsumerStatefulWidget {
  const ClassSelectionScreen({super.key});

  @override
  ConsumerState<ClassSelectionScreen> createState() =>
      _ClassSelectionScreenState();
}

class _ClassSelectionScreenState extends ConsumerState<ClassSelectionScreen> {
  /// Les identifiants des classes dont les passifs sont dépliés.
  ///
  /// Autant de cartes ouvertes que le joueur veut : comparer deux classes
  /// demande de voir leurs passifs côte à côte, et un accordéon l'en
  /// empêcherait. Des identifiants plutôt que des rangs : l'ordre
  /// d'affichage est une donnée (`displayOrder`) qui peut changer.
  ///
  /// L'état vit ici plutôt que dans chaque carte parce que la carte est
  /// reconstruite à chaque changement de largeur, et que l'écran est le seul
  /// endroit d'où l'on peut décrire ce qui est ouvert.
  final Set<String> _classesDepliees = <String>{};

  void _depliee(String id, bool ouverte) {
    if (ouverte == _classesDepliees.contains(id)) return;
    setState(() {
      if (ouverte) {
        _classesDepliees.add(id);
      } else {
        _classesDepliees.remove(id);
      }
    });
  }

  // Largeur de carte visee et espacement desktop — memes valeurs
  // numeriques que l'ancien `SliverGridDelegateWithMaxCrossAxisExtent
  // (maxCrossAxisExtent: 400, crossAxisSpacing: 20)`. Round 3
  // (2026-09-19) : il n'y a plus de constante de HAUTEUR — chaque
  // *rangee* se dimensionne a son propre contenu via `IntrinsicHeight` au
  // lieu de partager une hauteur fixe devinee pour le pire cas. Round 4
  // (2026-09-19) : `_kDesktopCardTargetWidth` plafonne aussi la largeur de
  // carte (une rangee a peu de colonnes, forcee par le nombre reel de
  // classes, ne doit pas etirer chaque carte bien au-dela de la largeur
  // pour laquelle sa mise en page a ete pensee) — voir `_buildDesktopGrid`
  // pour le detail et pourquoi l'ancien delegate n'avait pas ce probleme.
  static const double _kDesktopCardTargetWidth = 400;
  static const double _kDesktopSpacing = 20;

  @override
  Widget build(BuildContext context) {
    ref.read(musicConductorProvider).onScene(MusicScene.menu);

    // Les données sont déjà chargées par le SplashScreen
    final gameData = ref.watch(gameDataLoaderProvider).requireValue;
    final classes = [...gameData.heroes]
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    final l10n = AppLocalizations.of(context)!;

    return ScreenScaffold(
      backgroundType: ScreenBackgroundType.dark,
      appBar: PageHeader(
        title: l10n.selectClass,
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book),
            tooltip: l10n.cardDictionary,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CardDictionaryScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 10 : 20),
        // Mobile : liste a une colonne, chaque carte se dimensionne a son
        // propre contenu (`ListView.separated`). Une grille a hauteur
        // deduite de la largeur (`childAspectRatio`, ou meme une hauteur
        // fixe partagee) couple deux axes qui n'ont aucune raison de l'etre
        // — trois phrases generees et un selecteur a plusieurs passifs
        // n'ont pas tous besoin de la meme hauteur a chaque largeur d'ecran
        // — et un ecran court laissait le bouton "Selectionner" hors-champ
        // (defaut 2, 2026-09-19). Une liste rend l'overflow vertical
        // structurellement impossible : l'ecran defile, la carte ne
        // deborde jamais. Desktop : grille conservee (comparer les classes
        // cote a cote est le point de cette mise en page), mais chaque
        // rangee se dimensionne desormais elle aussi a son propre contenu
        // — voir `_buildDesktopGrid` (defaut 1, round 3, 2026-09-19).
        child: isMobile
            ? ListView.separated(
                itemCount: classes.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) => _buildCard(
                  classes[index],
                  isMobile: true,
                ),
              )
            : _buildDesktopGrid(classes),
      ),
    );
  }

  // Grille desktop : la comparaison cote a cote entre classes est le point
  // de cette mise en page (ruling explicite), donc une grille est
  // conservee plutot qu'une liste. Mais `GridView`/`SliverGrid` imposent la
  // geometrie (donc la hauteur) de chaque cellule *avant* que ses enfants
  // ne soient mis en page — ils ne peuvent structurellement pas laisser le
  // contenu decider de sa propre hauteur, d'ou la constante qu'il fallait
  // remesurer a chaque round (750 -> 1000 -> ...). Ici, la grille est
  // reconstruite a la main comme une pile de rangees (`ListView.separated`
  // de rangees, exactement comme la liste mobile juste au-dessus), chaque
  // rangee enveloppee dans `IntrinsicHeight` : elle se dimensionne a la
  // plus haute carte qu'elle contient, mesuree pour de vrai a chaque
  // frame plutot que devinee une fois pour toutes. Aucune carte ne peut
  // plus deborder (la rangee est toujours aussi haute qu'il le faut), et
  // aucune carte ne gaspille plus d'espace que ce que son propre contenu
  // demande (pas de marge de securite a calculer).
  //
  // `IntrinsicHeight` doit pouvoir traverser tout l'arbre de la carte pour
  // mesurer sa hauteur naturelle — un `LayoutBuilder` sur ce chemin leve
  // "LayoutBuilder does not support returning intrinsic dimensions"
  // (verifie directement). `_InteractiveClassCardState` n'en a plus : son
  // `LayoutBuilder` (qui ne servait qu'a lire la taille de la carte pour
  // l'effet de tilt et le halo de survol) est remplace par `_cardSize`, qui
  // lit la taille reellement rendue via une `GlobalKey`.
  //
  // Nombre de colonnes : meme formule que l'ancien
  // `SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 400,
  // crossAxisSpacing: 20)` — `ceil(largeurDisponible / 420)` colonnes. Mais
  // `columns` est ensuite **plafonne au nombre de classes** (`clamp(1,
  // classes.length)`), ce que l'ancien delegate ne faisait jamais : une
  // grille `SliverGrid` accepte des cellules vides (3 classes dans une
  // grille a 4 ou 5 colonnes laisse simplement des cases vides a droite).
  // Une rangee construite a la main n'a pas cette option — sans plafond,
  // `columns` resterait a 4-6 alors qu'il n'y a que 3 classes, et
  // `classes.sublist` produirait des rangees de 1 carte, chacune large de
  // toute la largeur disponible.
  //
  // Consequence du plafond, verifiee visuellement (round 4, 2026-09-19) :
  // avec 2-3 classes seulement, `columns` plafonne a 2-3 bien avant que la
  // formule en ait besoin, et diviser toute la largeur disponible entre si
  // peu de colonnes donnerait des cartes bien plus larges que
  // `_kDesktopCardTargetWidth` (mesure : 3 cartes de ~627px a 1395px de
  // large, alors que la cible est 400px). `cardWidth` est donc **plafonnee
  // a `_kDesktopCardTargetWidth`** — une carte n'est jamais plus large que
  // la largeur pour laquelle sa mise en page a ete pensee — et la rangee
  // est **centree** (`MainAxisAlignment.center`) pour ne pas coller les
  // cartes plafonnees au bord gauche d'un ecran large. La densite (nombre
  // de colonnes par palier de largeur) reste celle de l'ancien delegate ;
  // ce qui ne l'est plus, deliberement, c'est la largeur de carte au-dela
  // du point ou le nombre de classes livrees devient le facteur limitant
  // plutot que la largeur d'ecran.
  /// Une carte, branchée sur l'état de dépliage de l'écran.
  ///
  /// Le même geste sur les deux plateformes : le clic, ou l'appui, bascule
  /// le dépliage. Le survol l'a fait un temps (2026-09-19) et ne le fait
  /// plus — il remesurait la rangée desktop entière à chaque passage de
  /// souris, y compris quand on ne faisait que traverser l'écran.
  Widget _buildCard(HeroData playerClass, {required bool isMobile}) {
    return _InteractiveClassCard(
      playerClass: playerClass,
      ref: ref,
      isMobile: isMobile,
      isExpanded: _classesDepliees.contains(playerClass.id),
      onTap: () => _depliee(
        playerClass.id,
        !_classesDepliees.contains(playerClass.id),
      ),
    );
  }

  Widget _buildDesktopGrid(List<HeroData> classes) {
    if (classes.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableWidth = constraints.maxWidth;
        final int columns = (availableWidth / (_kDesktopCardTargetWidth + _kDesktopSpacing))
            .ceil()
            .clamp(1, classes.length);
        final double computedCardWidth =
            (availableWidth - (columns - 1) * _kDesktopSpacing) / columns;
        final double cardWidth = computedCardWidth < _kDesktopCardTargetWidth
            ? computedCardWidth
            : _kDesktopCardTargetWidth;

        final rows = <List<HeroData>>[
          for (var i = 0; i < classes.length; i += columns)
            classes.sublist(i, (i + columns).clamp(0, classes.length)),
        ];

        return ListView.separated(
          itemCount: rows.length,
          separatorBuilder: (context, index) =>
              const SizedBox(height: _kDesktopSpacing),
          itemBuilder: (context, rowIndex) {
            final row = rows[rowIndex];
            return IntrinsicHeight(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                // `start`, et non `stretch` : la rangee prend bien la
                // hauteur de sa carte la plus haute, mais elle n'y etire pas
                // les autres. Deplier une carte ne doit changer QUE cette
                // carte — avec `stretch`, ouvrir le Paladin faisait passer
                // le Berserker de 396 a 519px et le laissait avec du vide en
                // bas. Contrepartie assumee : au repos les bas ne sont plus
                // alignes, puisque les classes n'ont pas toutes le meme
                // nombre de lignes generees (le Berserker porte une regle de
                // stat que les deux autres n'ont pas).
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < row.length; i++) ...[
                    if (i > 0) const SizedBox(width: _kDesktopSpacing),
                    SizedBox(
                      width: cardWidth,
                      child: _buildCard(row[i], isMobile: false),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _InteractiveClassCard extends StatefulWidget {
  final HeroData playerClass;
  final WidgetRef ref;
  final bool isMobile;

  /// Les passifs de cette carte sont-ils dépliés ? L'écran le décide, pas la
  /// carte : une seule à la fois peut l'être.
  final bool isExpanded;

  /// Bascule le dépliage des passifs. Même geste sur les deux plateformes.
  final VoidCallback onTap;

  const _InteractiveClassCard({
    required this.playerClass,
    required this.ref,
    required this.isMobile,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  State<_InteractiveClassCard> createState() => _InteractiveClassCardState();
}

class _InteractiveClassCardState extends State<_InteractiveClassCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  double _tiltX = 0.0;
  double _tiltY = 0.0;
  Offset? _mousePosition;

  // Ancre le conteneur rendu de la carte, pour le tilt et le halo de
  // survol. Round 3 (2026-09-19) a retire le `LayoutBuilder` qui donnait
  // autrefois `cardSize` : `IntrinsicHeight` (desktop) ne peut pas
  // traverser un `LayoutBuilder` ("LayoutBuilder does not support
  // returning intrinsic dimensions", verifie par un sondage direct) et la
  // carte doit desormais se dimensionner a son contenu sur les deux
  // chemins. `_cardSize` retombe sur la taille reellement rendue au frame
  // precedent — le mobile (`ListView`, hauteur non bornee) en avait deja
  // besoin depuis le round 2 ; le desktop (auparavant toujours borne par
  // le delegate de grille) en depend maintenant aussi.
  final GlobalKey _cardKey = GlobalKey();

  Size get _cardSize {
    final renderBox = _cardKey.currentContext?.findRenderObject();
    if (renderBox is RenderBox && renderBox.hasSize) {
      return renderBox.size;
    }
    return Size.zero;
  }

  /// Le passif retenu, par son rang dans `availablePassivesFor` — le point
  /// d'accès unique de P-49 (spec §5.1, P5). Le premier par défaut, et le
  /// choix du joueur ensuite (spec §8.3).
  int _passiveIndex = 0;

  // For float/breath animation of icon
  late final AnimationController _floatController;
  late final Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -4, end: 4).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  void _onPointerMove(PointerEvent event) {
    final cardSize = _cardSize;
    if (cardSize.width == 0 || cardSize.height == 0) return;

    // Relative position from center (-0.5 to 0.5)
    final double relX = (event.localPosition.dx / cardSize.width) - 0.5;
    final double relY = (event.localPosition.dy / cardSize.height) - 0.5;

    setState(() {
      // Limit tilt angle (approx 0.025 radians max)
      _tiltX = relX * 0.05;
      _tiltY = relY * 0.05;
      _mousePosition = event.localPosition;
    });
  }

  void _onPointerExit() {
    setState(() {
      _isHovered = false;
      _tiltX = 0.0;
      _tiltY = 0.0;
      _mousePosition = null;
    });
  }

  void _onPointerEnter() {
    setState(() {
      _isHovered = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final playerClass = widget.playerClass;
    final gameData = widget.ref.watch(gameDataLoaderProvider).requireValue;
    final passives = availablePassivesFor(playerClass, gameData);
    // Le rang peut sortir de la liste si la donnée change sous l'écran : on
    // retombe sur le premier plutôt que de lever.
    final index = _passiveIndex < passives.length ? _passiveIndex : 0;
    final locale = Localizations.localeOf(context).languageCode;

    final classColor = ClassIdentity.colorOf(playerClass);

    // PV et mana toujours : ce sont les deux reperes que le joueur compare
    // d'une classe a l'autre. Les trois autres seulement si elles disent
    // quelque chose — « PV max et stats de depart non nulles » (spec §8.3).
    // Genere depuis la donnee : aucun `hero.id` n'est compare (ADR-090).
    final statBadges = <({Widget icon, String value})>[
      (
        icon: Icon(
          Icons.favorite,
          size: widget.isMobile ? 14 : 16,
          color: Colors.redAccent,
        ),
        value: '${playerClass.maxHp}',
      ),
      (
        icon: Icon(
          Icons.diamond_rounded,
          size: widget.isMobile ? 14 : 16,
          color: Colors.cyanAccent,
        ),
        value: '${playerClass.maxMana}',
      ),
      if (playerClass.mastery > 0)
        (
          icon: Icon(
            Icons.shield_outlined,
            size: widget.isMobile ? 14 : 16,
            color: Colors.lightBlueAccent,
          ),
          value: '${playerClass.mastery}',
        ),
      if (playerClass.critChance > 0)
        (
          icon: Icon(
            Icons.bolt_outlined,
            size: widget.isMobile ? 14 : 16,
            color: Colors.redAccent,
          ),
          value: '${playerClass.critChance}%',
        ),
      if (playerClass.luck > 0)
        (
          icon: Icon(
            Icons.casino_outlined,
            size: widget.isMobile ? 14 : 16,
            color: Colors.amberAccent,
          ),
          value: '${playerClass.luck}',
        ),
    ];

    final l10n = AppLocalizations.of(context)!;

    return MouseRegion(
          onEnter: (_) => _onPointerEnter(),
          onExit: (_) => _onPointerExit(),
          // Le geste de dépliage, identique en desktop et en mobile. Le
          // bouton et les lignes de passif ont leurs propres gestes, qui
          // gagnent sur celui-ci.
          child: GestureDetector(
            onTap: widget.onTap,
            child: Listener(
            onPointerMove: (e) => _onPointerMove(e),
            onPointerHover: (e) => _onPointerMove(e),
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              tween: Tween<double>(begin: 0.0, end: _isHovered ? 1.0 : 0.0),
              builder: (context, hoverVal, child) {
                // Interpolate rotation to standard or tilt value
                final double currentTiltX = _tiltX * hoverVal;
                final double currentTiltY = _tiltY * hoverVal;

                return Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.002) // Perspective 3D
                    ..rotateX(
                      currentTiltY,
                    ) // Inversé : le côté avec le curseur s'éloigne (tilt vers l'arrière)
                    ..rotateY(-currentTiltX),
                  alignment: Alignment.center,
                  child: AnimatedContainer(
                    key: _cardKey,
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A3D),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: classColor.withValues(
                          alpha: _isHovered ? 1.0 : 0.7,
                        ),
                        width: _isHovered ? 3.0 : 2.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: classColor.withValues(
                            alpha: _isHovered ? 0.4 : 0.15,
                          ),
                          blurRadius: _isHovered ? 25 : 10,
                          spreadRadius: _isHovered ? 4 : 1,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Stack(
                        children: [
                          if (_isHovered && _mousePosition != null)
                            Positioned.fill(
                              child: IgnorePointer(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: RadialGradient(
                                      center: Alignment(
                                        (_mousePosition!.dx / _cardSize.width) *
                                                2 -
                                            1,
                                        (_mousePosition!.dy / _cardSize.height) *
                                                2 -
                                            1,
                                      ),
                                      radius: 0.6,
                                      colors: [
                                        classColor.withValues(alpha: 0.12),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          Padding(
                            padding: EdgeInsets.all(widget.isMobile ? 5 : 20),
                            child: Column(
                              // `min` : la carte se dimensionne a son propre
                              // contenu. Necessaire en mobile, ou la carte
                              // vit desormais dans un `ListView` a hauteur
                              // non bornee (`max`, la valeur par defaut,
                              // y leverait une erreur de layout) ; sans
                              // consequence en desktop, ou chaque rangee de
                              // la grille donne toujours une contrainte de
                              // hauteur bornee (tendue, calculee par
                              // `IntrinsicHeight` a partir du contenu reel
                              // de la rangee) (defaut 1 et 2, 2026-09-19).
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(height: widget.isMobile ? 8 : 10),
                                // Floating hero image
                                AnimatedBuilder(
                                  animation: _floatAnimation,
                                  builder: (context, child) {
                                    final double floatOffset =
                                        _floatAnimation.value *
                                        (widget.isMobile ? 0.5 : 1.0);
                                    return Transform.translate(
                                      offset: Offset(0, floatOffset),
                                      child: child,
                                    );
                                  },
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: classColor,
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: classColor.withValues(
                                            alpha: 0.5,
                                          ),
                                          blurRadius: widget.isMobile ? 5 : 10,
                                        ),
                                      ],
                                    ),
                                    child: ClassAvatar(
                                      hero: playerClass,
                                      diameter: widget.isMobile ? 48 : 65,
                                    ),
                                  ),
                                ),
                                SizedBox(height: widget.isMobile ? 10 : 15),
                                Text(
                                  playerClass.getName(locale),
                                  style: TextStyle(
                                    fontSize: widget.isMobile ? 20 : 26,
                                    fontWeight: FontWeight.bold,
                                    color: classColor,
                                    letterSpacing: 1.2,
                                    shadows: [
                                      Shadow(
                                        color: classColor.withValues(
                                          alpha: 0.3,
                                        ),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: widget.isMobile ? 8 : 12),
                                // Stats with beautiful icons and display
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: widget.isMobile ? 4 : 12,
                                    vertical: widget.isMobile ? 6 : 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.04),
                                    borderRadius: BorderRadius.circular(
                                      widget.isMobile ? 6 : 10,
                                    ),
                                  ),
                                  child: Wrap(
                                    alignment: WrapAlignment.center,
                                    spacing: widget.isMobile ? 8 : 14,
                                    runSpacing: widget.isMobile ? 2 : 4,
                                    children: [
                                      for (final badge in statBadges)
                                        _buildStatBadge(badge.icon, badge.value),
                                    ],
                                  ),
                                ),
                                SizedBox(height: widget.isMobile ? 6 : 8),
                                // Ce que renforce la Puissance de la classe,
                                // et ce qu'elle convertit — genere depuis
                                // `mightTargets` et `statRules`, jamais ecrit
                                // classe par classe (spec §8.3, ADR-090).
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: widget.isMobile ? 4 : 12,
                                    vertical: widget.isMobile ? 5 : 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orangeAccent.withValues(alpha: 0.06),
                                    borderRadius: BorderRadius.circular(
                                      widget.isMobile ? 6 : 10,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        playerClass.mightTargets.sentence(l10n),
                                        style: TextStyle(
                                          fontSize: widget.isMobile ? 9.5 : 10.5,
                                          color: Colors.orangeAccent.withValues(
                                            alpha: 0.9,
                                          ),
                                          height: 1.25,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      for (final rule in playerClass.statRules) ...[
                                        SizedBox(height: widget.isMobile ? 2 : 4),
                                        Text(
                                          rule.describe(l10n),
                                          style: TextStyle(
                                            fontSize: widget.isMobile ? 9.5 : 10.5,
                                            fontStyle: FontStyle.italic,
                                            color: Colors.orangeAccent.withValues(
                                              alpha: 0.75,
                                            ),
                                            height: 1.25,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Divider(
                                  color: Colors.white12,
                                  height: widget.isMobile ? 16 : 25,
                                ),
                                // Description text. Plain child, pas
                                // `Expanded`/`SingleChildScrollView` : la
                                // carte se dimensionne desormais a son
                                // contenu des deux cotes — `ListView`
                                // mobile non borne, `IntrinsicHeight` par
                                // rangee en desktop — rien ne reste a
                                // faire tenir de force dans un espace fixe
                                // ou devine (defaut 1 et 2, 2026-09-19).
                                Text(
                                  playerClass.getDescription(locale),
                                  style: TextStyle(
                                    fontSize: widget.isMobile ? 11.5 : 13,
                                    color: Colors.white70,
                                    fontStyle: FontStyle.italic,
                                    height: 1.3,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: widget.isMobile ? 10 : 15),
                                // Premium Selection Button
                                _PremiumSelectionButton(
                                  classColor: classColor,
                                  isMobile: widget.isMobile,
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            StarterDeckDraftScreen(
                                              playerClass: playerClass,
                                              passive: passives.isEmpty
                                                  ? null
                                                  : passives[index],
                                            ),
                                      ),
                                    );
                                  },
                                ),
                                if (passives.isNotEmpty) ...[
                                  SizedBox(height: widget.isMobile ? 6 : 8),
                                  ClassPassiveList(
                                    passives: passives,
                                    selectedIndex: index,
                                    classMastery: playerClass.mastery,
                                    isExpanded: widget.isExpanded,
                                    isMobile: widget.isMobile,
                                    locale: locale,
                                    classColor: classColor,
                                    onSelect: (i) => setState(
                                      () => _passiveIndex = i,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            ),
          ),
        );
  }

  Widget _buildStatBadge(Widget iconWidget, String value) {
    final bool isMobile = widget.isMobile;
    return Row(
      // Ces badges vivent dans un `Wrap` (tache 5) : un `Row` a sa taille par
      // defaut (`MainAxisSize.max`) y revendique toute la largeur restante,
      // ce qui force chaque badge suivant sur sa propre ligne. `min` laisse
      // le badge se limiter a son contenu, pour que le `Wrap` les aligne
      // vraiment cote a cote (defaut 1 du 2026-09-18).
      mainAxisSize: MainAxisSize.min,
      children: [
        iconWidget,
        SizedBox(width: isMobile ? 2 : 4),
        Text(
          value,
          style: TextStyle(
            fontSize: isMobile ? 12 : 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _PremiumSelectionButton extends StatefulWidget {
  final Color classColor;
  final VoidCallback onPressed;
  final bool isMobile;

  const _PremiumSelectionButton({
    required this.classColor,
    required this.onPressed,
    required this.isMobile,
  });

  @override
  State<_PremiumSelectionButton> createState() =>
      _PremiumSelectionButtonState();
}

class _PremiumSelectionButtonState extends State<_PremiumSelectionButton>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _pressController, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final gradient = ClassIdentity.gradientOf(widget.classColor);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => _pressController.forward(),
        onTapUp: (_) {
          _pressController.reverse();
          widget.onPressed();
        },
        onTapCancel: () => _pressController.reverse(),
        child: AnimatedScale(
          scale: _isHovered ? 1.04 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: widget.isMobile ? 38 : 48,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(widget.isMobile ? 8 : 12),
                boxShadow: [
                  BoxShadow(
                    color: widget.classColor.withValues(
                      alpha: _isHovered ? 0.5 : 0.25,
                    ),
                    blurRadius: _isHovered ? 15 : 6,
                    offset: Offset(0, _isHovered ? 4 : 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  l10n.select,
                  style: TextStyle(
                    fontSize: widget.isMobile ? 14 : 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
