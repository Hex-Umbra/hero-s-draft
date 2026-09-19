import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import '../../game/systems/passive_availability.dart';
import '../../models/data/hero_data.dart';
import '../../models/data/passive_data.dart';
import '../../services/game_data_service.dart';
import '../../services/audio/audio_providers.dart';
import '../../services/audio/music_scene.dart';
import 'card_dictionary_screen.dart';
import 'starter_deck_draft_screen.dart';
import '../../models/data/model_extensions.dart';
import '../widgets/class_identity.dart';
import '../widgets/screen_scaffold.dart';
import '../widgets/page_header.dart';

class ClassSelectionScreen extends ConsumerWidget {
  const ClassSelectionScreen({super.key});

  // Hauteur de cellule desktop (>=600px). Le desktop reste une grille — la
  // comparaison cote a cote entre classes est le point de cette mise en page
  // — mais sa hauteur ne se deduit plus de la largeur de carte
  // (`childAspectRatio`), qui produisait un motif en dents de scie :
  // `SliverGridDelegateWithMaxCrossAxisExtent` fait bondir son nombre de
  // colonnes par paliers quand le viewport grandit, donc la largeur de
  // carte — et la hauteur qu'un `childAspectRatio` fixe en deduisait —
  // n'est pas monotone (defaut 1, 2026-09-19).
  //
  // Mesuree aux planchers reels de chaque palier de colonnes — pas aux
  // largeurs d'ecran rondes que le round 1 avait echantillonnees par erreur
  // (1000/1400, qui tombent *dans* les paliers 3 et 4 colonnes, pas a leur
  // plancher). Pour `maxCrossAxisExtent: 400, crossAxisSpacing: 20`, le
  // plancher du palier a `n` colonnes est le premier viewport ou
  // `ceil((viewport-40)/420) == n` : 600px (le plancher desktop lui-meme,
  // sous `isMobile`) -> 2 colonnes -> carte 270px ; **881px -> 3 colonnes
  // -> carte 267px** (plus etroite que 600px) ; 1000px -> 3 colonnes ->
  // carte 307px ; **1301px -> 4 colonnes -> carte 300px** ; 1400px -> 4
  // colonnes -> carte 325px. La largeur de carte remonte vers 400px a
  // mesure que le nombre de colonnes croit (`400*(n-1)/n`), donc rien de
  // pire n'existe au-dela de ces 5 points — l'inquietude round-1 sur les
  // tres larges viewports (ultrawide) est sans objet.
  //
  // Les six fixtures de passifs reelles portent desormais leur `mastery`
  // (les neuf passifs livres en portent tous un ; les fixtures du round 1
  // n'en avaient aucun, donc elles omettaient tout un bloc de texte —
  // "Par point de Maîtrise : ..." plus un espaceur de 3px — que la carte
  // reelle rend des que `passive.mastery != null`). Remesuree avec ce bloc
  // present, aux 5 largeurs ci-dessus, sur le Paladin et le Berserker (3
  // passifs chacun) :
  //
  // | largeur | carte | pire hauteur de contenu (Berserker) |
  // |---:|---:|---:|
  // | 600  | 270.0 | 725.5 |
  // | 881  | 267.0 | 725.5 |
  // | 1000 | 306.7 | 663.5 |
  // | 1301 | 300.3 | 663.5 |
  // | 1400 | 325.0 | 617.5 |
  //
  // Pire point : 725.5px (600px et 881px, a egalite). Recherche binaire sur
  // `_kDesktopCardHeight` : 758 deborde de 2px, 760 n'y deborde plus —
  // plancher reel **760**, pas les 709px du round 1 (fixtures sans
  // `mastery`, donc sous-mesurees d'un bloc de texte entier).
  //
  // A `TextScaler.linear(1.3)` (defaut 4, la mise a l'echelle systeme —
  // seul axe ou l'app reelle peut rendre plus grand que son `fontSize`
  // nominal), la meme mesure aux 5 largeurs donne un pire point de 930.0px
  // (Paladin, 600/881px). Recherche binaire : 950 deborde de 2px, 952 n'y
  // deborde plus — plancher reel a 1.3x : **952**.
  //
  // `_kDesktopCardHeight = 1000` : au-dessus des DEUX planchers (760 a
  // l'echelle par defaut, 952 a 1.3x), avec ~48px (~5%) de marge sur le
  // plus haut des deux. Cout assume et signale au proprietaire du lot
  // (voir le rapport, section "textScaler sur desktop") : a l'echelle par
  // defaut, ce choix laisse ~240px d'espace vide en bas de chaque carte
  // desktop (1000 - 760) pour rester correct a 1.3x — nettement plus que
  // la marge de ~5-6% prise partout ailleurs dans ce lot. Le choix inverse
  // (ne couvrir que 760, laisser deborder a 1.3x) aurait laisse un
  // utilisateur avec un texte systeme agrandi face a un `RenderFlex
  // overflowed` sur desktop ; celui-ci a ete prefere, mais reste un
  // arbitrage de contenu/densite qui merite une decision explicite du
  // proprietaire plutot qu'un choix silencieux.
  static const double _kDesktopCardHeight = 1000;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        // cote a cote est le point de cette mise en page), mais sa hauteur
        // de cellule est desormais une mesure du pire contenu reel au point
        // le plus etroit du motif en dents de scie de
        // `SliverGridDelegateWithMaxCrossAxisExtent`, plus une marge — pas
        // une valeur deduite de la largeur (defaut 1, 2026-09-19).
        child: isMobile
            ? ListView.separated(
                itemCount: classes.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) => _InteractiveClassCard(
                  playerClass: classes[index],
                  ref: ref,
                  isMobile: isMobile,
                ),
              )
            : GridView.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 400,
                  mainAxisExtent: _kDesktopCardHeight,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                ),
                itemCount: classes.length,
                itemBuilder: (context, index) => _InteractiveClassCard(
                  playerClass: classes[index],
                  ref: ref,
                  isMobile: isMobile,
                ),
              ),
      ),
    );
  }
}

class _InteractiveClassCard extends StatefulWidget {
  final HeroData playerClass;
  final WidgetRef ref;
  final bool isMobile;

  const _InteractiveClassCard({
    required this.playerClass,
    required this.ref,
    required this.isMobile,
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

  // Ancre le conteneur rendu de la carte : sur le chemin mobile
  // (`ListView`, hauteur non bornee), `constraints.maxHeight` vaut
  // `Infinity` — sans repli, le tilt et le halo de survol degeneraient (Y
  // fige a une valeur constante, halo colle au bord haut). Sans
  // consequence en pratique (survol a la souris sous 600px seulement), mais
  // c'est une regression introduite par le passage au `ListView` ; `_resolvedCardSize`
  // retombe sur la taille reellement rendue au frame precedent.
  final GlobalKey _cardKey = GlobalKey();

  Size _resolvedCardSize(BoxConstraints constraints) {
    if (constraints.hasBoundedHeight) {
      return Size(constraints.maxWidth, constraints.maxHeight);
    }
    final renderBox = _cardKey.currentContext?.findRenderObject();
    if (renderBox is RenderBox && renderBox.hasSize) {
      return renderBox.size;
    }
    return Size(constraints.maxWidth, constraints.maxHeight);
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

  void _onPointerMove(PointerEvent event, Size cardSize) {
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
    final passive = passives.isEmpty ? null : passives[index];
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

    final String traitDesc = passive?.getDescription(locale) ?? '';
    // Ce qu'un point de Maîtrise apporte au passif (spec P-49, §6.5).
    final String? masteryPerPoint = passive?.mastery?.describe(locale, 1);
    final l10n = AppLocalizations.of(context)!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardSize = _resolvedCardSize(constraints);

        return MouseRegion(
          onEnter: (_) => _onPointerEnter(),
          onExit: (_) => _onPointerExit(),
          child: Listener(
            onPointerMove: (e) => _onPointerMove(e, cardSize),
            onPointerHover: (e) => _onPointerMove(e, cardSize),
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
                                        (_mousePosition!.dx / cardSize.width) *
                                                2 -
                                            1,
                                        (_mousePosition!.dy / cardSize.height) *
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
                              // consequence en desktop, ou la grille donne
                              // toujours une contrainte de hauteur fixe
                              // (defaut 1 et 2, 2026-09-19).
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
                                SizedBox(height: widget.isMobile ? 1 : 8),
                                // Passive trait
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: widget.isMobile ? 8 : 12,
                                    vertical: widget.isMobile ? 6 : 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.cyanAccent.withValues(
                                      alpha: 0.06,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      widget.isMobile ? 6 : 10,
                                    ),
                                    border: Border.all(
                                      color: Colors.cyanAccent.withValues(
                                        alpha: 0.25,
                                      ),
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _PassiveSelector(
                                        passives: passives,
                                        selectedIndex: index,
                                        isMobile: widget.isMobile,
                                        locale: locale,
                                        onSelect: (i) => setState(
                                          () => _passiveIndex = i,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        traitDesc,
                                        style: TextStyle(
                                          fontSize: widget.isMobile
                                              ? 9.5
                                              : 10.5,
                                          color: Colors.cyanAccent.withValues(
                                            alpha: 0.85,
                                          ),
                                          height: 1.25,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      if (masteryPerPoint != null) ...[
                                        const SizedBox(height: 3),
                                        Text(
                                          l10n.passiveMasteryPerPoint(
                                            masteryPerPoint,
                                          ),
                                          style: TextStyle(
                                            fontSize: widget.isMobile
                                                ? 9
                                                : 10,
                                            fontStyle: FontStyle.italic,
                                            color: Colors.cyanAccent.withValues(
                                              alpha: 0.7,
                                            ),
                                            height: 1.2,
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
                                // contenu des deux cotes (`ListView` mobile
                                // non borne, `mainAxisExtent` desktop mesure
                                // pour l'accueillir) — rien ne reste a
                                // faire tenir de force dans un espace fixe
                                // (defaut 1 et 2, 2026-09-19).
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
                                              passive: passive,
                                            ),
                                      ),
                                    );
                                  },
                                ),
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
        );
      },
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

/// Le selecteur de passif de la carte de classe : une puce par passif
/// disponible (point d'acces unique de P-49), tapable pour changer le choix
/// retenu.
///
/// Extrait de `_InteractiveClassCardState.build()` (defaut 3, 2026-09-19) :
/// c'est la seule facon d'atteindre six des neuf passifs livres — un choix
/// non trivial que la carte n'exposait qu'a travers une rangee de 14-19px de
/// haut, sans `HitTestBehavior.opaque` ni marge de frappe, contre les 48px
/// recommandes par Material. `behavior: HitTestBehavior.opaque` fait
/// reagir toute la puce (icone + texte + l'espace mort entre eux), et le
/// `Padding` vertical lui redonne une hauteur de frappe raisonnable.
class _PassiveSelector extends StatelessWidget {
  final List<PassiveData> passives;
  final int selectedIndex;
  final bool isMobile;
  final String locale;
  final ValueChanged<int> onSelect;

  // Les trois valeurs d'opacite que chaque puce module selon la selection,
  // nommees une seule fois plutot que repetees a chaque site d'usage.
  static const double _kSelectedAlpha = 1.0;
  static const double _kUnselectedIconAlpha = 0.35;
  static const double _kUnselectedTextAlpha = 0.45;

  const _PassiveSelector({
    required this.passives,
    required this.selectedIndex,
    required this.isMobile,
    required this.locale,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (passives.isEmpty) {
      return Text(
        '—',
        style: TextStyle(
          fontSize: isMobile ? 10 : 11,
          color: Colors.cyanAccent,
        ),
      );
    }

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: isMobile ? 8 : 10,
      runSpacing: isMobile ? 3 : 2,
      children: [
        for (var i = 0; i < passives.length; i++) _buildChip(i),
      ],
    );
  }

  Widget _buildChip(int i) {
    final bool selected = i == selectedIndex;
    return GestureDetector(
      // `deferToChild` (le defaut) ne reagit qu'aux enfants qui peignent
      // reellement quelque chose ; la puce contenait un `SizedBox` de 2px
      // entre l'icone et le texte qui ne peint rien, donc une bande morte
      // au milieu de la puce. `opaque` fait reagir toute sa zone.
      behavior: HitTestBehavior.opaque,
      onTap: passives.length == 1 ? null : () => onSelect(i),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shield,
              size: isMobile ? 12 : 16,
              color: Colors.cyanAccent.withValues(
                alpha: selected ? _kSelectedAlpha : _kUnselectedIconAlpha,
              ),
            ),
            SizedBox(width: isMobile ? 2 : 6),
            // `Flexible` (jamais `Expanded`) : a la largeur la plus etroite
            // de la plage mobile (320px), le nom le plus long du jeu ne
            // tient plus sur une ligne et doit pouvoir enjamber la suivante
            // au lieu de deborder a droite (defaut 2, round 3 du
            // 2026-09-18 : le retrait du round 2 supposait a tort qu'aucune
            // largeur de la plage ne forcerait de retour a la ligne).
            Flexible(
              child: Text(
                passives[i].getName(locale).toUpperCase(),
                style: TextStyle(
                  fontSize: isMobile ? 10 : 11,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  color: Colors.cyanAccent.withValues(
                    alpha: selected ? _kSelectedAlpha : _kUnselectedTextAlpha,
                  ),
                  letterSpacing: 0.8,
                  decoration: passives.length > 1 && selected
                      ? TextDecoration.underline
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
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
