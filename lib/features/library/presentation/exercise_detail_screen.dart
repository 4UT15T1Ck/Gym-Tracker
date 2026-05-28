import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym_tracker/core/enums/tracking_type_enum.dart';
import 'package:gym_tracker/features/library/bloc/exercise_detail_cubit.dart';

class ExerciseDetailScreen extends StatelessWidget {
  const ExerciseDetailScreen({super.key});
  static const _bgColor = Color(0xFF080A0F);
  static const _cardColor = Color(0xFF151A23);
  static const _mutedText = Color(0xFF8C94A5);
  static const _accent = Color(0xFF4A8DFF);
  static const _accentTextDark = Color(0xFF0E335A);
  static const _outline = Color(0xFF283041);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExerciseDetailCubit, ExerciseDetailState>(
      builder: (context, state) {
        final detail = state.detail;
        final theme = Theme.of(context);
        return Scaffold(
          backgroundColor: _bgColor,
          body: detail == null
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(
                  bottom: false,
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      14,
                      16,
                      MediaQuery.of(context).padding.bottom + 16,
                    ),
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(
                              Icons.arrow_back_ios_new,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              detail.exercise.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 160,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _cardColor,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: _outline),
                        ),
                        child: const Icon(
                          Icons.fitness_center,
                          size: 52,
                          color: _accentTextDark,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        detail.exercise.name,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        detail.exercise.trackingType.displayName,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: _accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Primary: ${detail.primaryMuscle.name}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: _mutedText,
                        ),
                      ),
                      if (detail.secondaryMuscles.isNotEmpty)
                        Text(
                          'Secondary: ${detail.secondaryMuscles.map((m) => m.name).join(', ')}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: _mutedText,
                          ),
                        ),
                      if (detail.equipment != null)
                        Text(
                          'Equipment: ${detail.equipment!.name}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: _mutedText,
                          ),
                        ),
                      const SizedBox(height: 16),
                      if (detail.exercise.shortDescription != null)
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _cardColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            detail.exercise.shortDescription!,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: Colors.white,
                              height: 1.35,
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      Text(
                        'Instructions',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...detail.exercise.instructions.indexed.map(
                        (entry) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _cardColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _outline),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: _accent,
                                child: Text(
                                  '${entry.$1 + 1}',
                                  style: const TextStyle(
                                    color: _accentTextDark,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  entry.$2,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.white,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Stats',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _cardColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total sessions: ${detail.stats?.totalSessions ?? 0}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Personal best: ${detail.stats?.personalBest?.weight?.toStringAsFixed(1) ?? '-'} kg',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: _mutedText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...?detail.stats?.recentHistory
                          .take(5)
                          .map(
                            (entry) => Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: _cardColor,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: _outline),
                              ),
                              child: ListTile(
                                title: Text(
                                  entry.workoutName,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  '${entry.sets.length} sets',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: _mutedText,
                                  ),
                                ),
                                trailing: const Icon(
                                  Icons.chevron_right,
                                  color: _mutedText,
                                ),
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
