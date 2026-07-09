import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift_orm;

import 'package:enola/database/database.dart';
import 'package:enola/providers/map_providers.dart';
import 'package:enola/theme/enola_theme.dart';
import 'package:enola/screens/create_map_screen.dart';
import 'package:enola/screens/play_screen.dart';
import 'package:enola/services/drift_service.dart';
import 'package:enola/services/supabase_service.dart';
import 'package:enola/services/training_service.dart';
import 'package:enola/screens/share_pack_screen.dart';
import 'package:enola/screens/pack_shared.dart';


class PackScreen extends ConsumerWidget {
  final int packId;
  final String packName;

  const PackScreen({super.key, required this.packId, required this.packName});

  void _openCreate(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateMapScreen(initialFolderId: packId),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapsAsync = ref.watch(mapsInFolderProvider(packId));
    final width = MediaQuery.of(context).size.width;
    final cols = crossAxisCount(width);
    final maps = mapsAsync.valueOrNull ?? [];

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFECEFF4), Colors.white],
          stops: [0.0, 0.65],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: mapsAsync.isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(
                            color: EnolaTheme.accent),
                      ),
                    )
                  : CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: _PackHeader(packName: packName, packId: packId),
                        ),
                        if (maps.isEmpty)
                          SliverToBoxAdapter(
                            child: _EmptyPackState(
                                onCreate: () => _openCreate(context)),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(40, 4, 40, 100),
                            sliver: SliverToBoxAdapter(
                              child: _ReorderableMapGrid(
                                maps: maps,
                                crossAxisCount: cols,
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ),
        ),
        floatingActionButtonLocation:
            FloatingActionButtonLocation.centerFloat,
        floatingActionButton: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PackBackFab(onBack: () => Navigator.pop(context)),
            const SizedBox(width: 12),
            _CreateFab(onTap: () => _openCreate(context)),
            const SizedBox(width: 12),
            const TrainingFab(),
          ],
        ),
      ),
    );
  }
}
