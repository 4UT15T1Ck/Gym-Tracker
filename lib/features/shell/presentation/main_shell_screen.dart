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
  static const _barBg = Color(0xFF12151D);
  static const _inactive = Color(0xFF5E646F);
  static const _active = Color(0xFF4A8DFF);
  static const _activeBorder = Color(0xFF7A7F89);

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
      bottomNavigationBar: Container(
        color: _barBg,
        padding: const EdgeInsets.fromLTRB(4, 2, 4, 6),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: _TabItem(
                  icon: Icons.home,
                  label: 'Home',
                  active: _selectedIndex == 0,
                  onTap: () => _onItemTapped(0),
                ),
              ),
              Expanded(
                child: _TabItem(
                  icon: Icons.fitness_center,
                  label: 'Workout',
                  active: _selectedIndex == 1,
                  onTap: () => _onItemTapped(1),
                ),
              ),
              Expanded(
                child: _TabItem(
                  icon: Icons.person,
                  label: 'Profile',
                  active: _selectedIndex == 2,
                  onTap: () => _onItemTapped(2),
                ),
              ),
            ],
          ),
        ),
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

class _TabItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _TabItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const inactive = _MainShellScreenState._inactive;
    const activeColor = _MainShellScreenState._active;
    final child = AnimatedContainer(
      duration: const Duration(milliseconds: 170),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        border: active
            ? Border.all(color: _MainShellScreenState._activeBorder, width: 1.2)
            : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: active ? activeColor : inactive, size: 26),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: active ? activeColor : inactive,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: child,
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
              padding: const EdgeInsets.fromLTRB(8, 4, 2, 4),
              child: Row(
                children: [
                  const Icon(Icons.fitness_center),
                  const SizedBox(width: 4),
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
