import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ---------------------------------------------------------------------------
// Data models
// ---------------------------------------------------------------------------

class _PatchSection {
  final String category;
  final String emoji;
  final List<String> entries;

  const _PatchSection({
    required this.category,
    required this.emoji,
    required this.entries,
  });

  factory _PatchSection.fromJson(Map<String, dynamic> json) => _PatchSection(
        category: json['category'] as String,
        emoji: json['emoji'] as String,
        entries: List<String>.from(json['entries'] as List),
      );
}

class _PatchVersion {
  final String version;
  final String date;
  final String title;
  final List<_PatchSection> sections;

  const _PatchVersion({
    required this.version,
    required this.date,
    required this.title,
    required this.sections,
  });

  factory _PatchVersion.fromJson(Map<String, dynamic> json) => _PatchVersion(
        version: json['version'] as String,
        date: json['date'] as String,
        title: json['title'] as String,
        sections: (json['sections'] as List)
            .map((s) => _PatchSection.fromJson(s as Map<String, dynamic>))
            .toList(),
      );
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class PatchNotesScreen extends StatefulWidget {
  const PatchNotesScreen({super.key});

  @override
  State<PatchNotesScreen> createState() => _PatchNotesScreenState();
}

class _PatchNotesScreenState extends State<PatchNotesScreen> {
  late Future<List<_PatchVersion>> _patchNotesFuture;

  @override
  void initState() {
    super.initState();
    _patchNotesFuture = _loadPatchNotes();
  }

  Future<List<_PatchVersion>> _loadPatchNotes() async {
    final raw = await rootBundle.loadString('assets/data/patch_notes.json');
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => _PatchVersion.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.article_outlined, color: Colors.amberAccent, size: 22),
            const SizedBox(width: 8),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFFFFD54F), Color(0xFFFFAB40)],
              ).createShader(bounds),
              child: const Text(
                'PATCH NOTES',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  letterSpacing: 3,
                ),
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<List<_PatchVersion>>(
        future: _patchNotesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.amberAccent),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Erreur de chargement\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }
          final patches = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            itemCount: patches.length,
            separatorBuilder: (_, _) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return _PatchVersionCard(patch: patches[index], isLatest: index == 0);
            },
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Version card widget
// ---------------------------------------------------------------------------

class _PatchVersionCard extends StatefulWidget {
  final _PatchVersion patch;
  final bool isLatest;

  const _PatchVersionCard({required this.patch, required this.isLatest});

  @override
  State<_PatchVersionCard> createState() => _PatchVersionCardState();
}

class _PatchVersionCardState extends State<_PatchVersionCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _controller;
  late Animation<double> _rotateAnim;

  @override
  void initState() {
    super.initState();
    _expanded = widget.isLatest; // expand latest by default
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: _expanded ? 1.0 : 0.0,
    );
    _rotateAnim = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  Color get _accentColor =>
      widget.isLatest ? const Color(0xFFFFAB40) : Colors.white38;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.isLatest
              ? [const Color(0xFF1E1B2E), const Color(0xFF2A1F3D)]
              : [const Color(0xFF141420), const Color(0xFF1A1A2C)],
        ),
        border: Border.all(
          color: _accentColor.withValues(alpha: 0.4),
          width: widget.isLatest ? 1.5 : 0.8,
        ),
        boxShadow: widget.isLatest
            ? [
                BoxShadow(
                  color: const Color(0xFFFFAB40).withValues(alpha: 0.08),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header row
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _toggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  // Version badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _accentColor, width: 1),
                    ),
                    child: Text(
                      'v${widget.patch.version}',
                      style: TextStyle(
                        color: _accentColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title & date
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              widget.patch.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            if (widget.isLatest) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.greenAccent.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                      color: Colors.greenAccent, width: 0.8),
                                ),
                                child: const Text(
                                  'NOUVEAU',
                                  style: TextStyle(
                                    color: Colors.greenAccent,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.patch.date,
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Chevron
                  RotationTransition(
                    turns: _rotateAnim,
                    child: Icon(
                      Icons.expand_more,
                      color: _accentColor.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Expandable content
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 280),
            crossFadeState: _expanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(color: _accentColor.withValues(alpha: 0.2), height: 16),
                  ...widget.patch.sections
                      .map((s) => _SectionBlock(section: s)),
                ],
              ),
            ),
            secondChild: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section block inside a version card
// ---------------------------------------------------------------------------

class _SectionBlock extends StatelessWidget {
  final _PatchSection section;

  const _SectionBlock({required this.section});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category header
          Row(
            children: [
              Text(section.emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                section.category.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Entries
          ...section.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 5, right: 8),
                    child: CircleAvatar(
                      radius: 2.5,
                      backgroundColor: Colors.white38,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      entry,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
