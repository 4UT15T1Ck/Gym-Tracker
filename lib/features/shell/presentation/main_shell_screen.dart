import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym_tracker/common/routes/routes.dart';
import 'package:gym_tracker/common/utils/date_formatters.dart';
import 'package:gym_tracker/features/home/bloc/home_dashboard_cubit.dart';
import 'package:gym_tracker/features/shell/bloc/shell_active_workout_cubit.dart';
import 'package:gym_tracker/features/home/presentation/home_dashboard_screen.dart';
import 'package:gym_tracker/features/profile/bloc/profile_cubit.dart';
import 'package:gym_tracker/features/profile/presentation/profile_home_screen.dart';
import 'package:gym_tracker/features/workout/bloc/workout_home_cubit.dart';
import 'package:gym_tracker/features/workout/presentation/workout_home_screen.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeDashboardScreen(onOpenWorkoutTab: () => _onItemTapped(1)),
      const WorkoutHomeScreen(),
      const ProfileHomeScreen(),
    ];
  }

  void _onItemTapped(int index) {
    _refreshTab(index);
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
  }

  void _refreshTab(int index) {
    switch (index) {
      case 0:
        context.read<HomeDashboardCubit>().load();
        return;
      case 1:
        context.read<WorkoutHomeCubit>().load();
        return;
      case 2:
        context.read<ProfileCubit>().load();
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.grid_view), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.add_circle_outline), label: 'Workout'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: BlocBuilder<ShellActiveWorkoutCubit, ShellActiveWorkoutState>(
        builder: (context, state) {
          if (!state.hasActiveWorkout) return const SizedBox.shrink();
          return _ActiveWorkoutFab(state: state);
        },
      ),
    );
  }
}

class _ActiveWorkoutFab extends StatelessWidget {
  final ShellActiveWorkoutState state;

  const _ActiveWorkoutFab({required this.state});

  @override
  Widget build(BuildContext context) {
    final primaryText = state.isResting
        ? 'Rest ${DateFormatters.elapsed(state.restRemaining)}'
        : 'Workout ${DateFormatters.elapsed(state.elapsed)}';
    return SafeArea(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Material(
          color: Theme.of(context).colorScheme.primaryContainer,
          elevation: 6,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () async {
              final result = await Navigator.of(context).pushNamed(
                Routes.activeWorkout,
                arguments: ActiveWorkoutRouteArgs(workoutId: state.workoutId),
              );
              if (!context.mounted) return;
              if (result != null) {
                context.read<ShellActiveWorkoutCubit>().refreshNow();
              }
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
              child: Row(
                children: [
                  const Icon(Icons.fitness_center),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(primaryText, maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(
                          state.currentExerciseName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Discard workout',
                    onPressed: () async {
                      final shouldDiscard = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Discard workout?'),
                          content: const Text('This will discard the current workout and nothing will be saved.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Keep')),
                            FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Discard')),
                          ],
                        ),
                      );
                      if (shouldDiscard == true && context.mounted) {
                        await context.read<ShellActiveWorkoutCubit>().discardActiveWorkout();
                      }
                    },
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
