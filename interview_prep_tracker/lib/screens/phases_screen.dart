import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../widgets/phase_card.dart';
import 'phase_detail_screen.dart';

class PhasesScreen extends ConsumerWidget {
  const PhasesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phasesAsync = ref.watch(phaseProgressProvider);

    return phasesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (phases) => RefreshIndicator(
        onRefresh: () async => refreshData(ref),
        color: Theme.of(context).colorScheme.primary,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          itemCount: phases.length + 1,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Phases',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              );
            }
            final phaseProgress = phases[index - 1];
            return PhaseCard(
              phaseProgress: phaseProgress,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PhaseDetailScreen(phaseId: phaseProgress.phase.id),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
