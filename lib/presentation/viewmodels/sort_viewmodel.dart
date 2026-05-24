import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SortOption { distance, time }

final sortOptionProvider = StateProvider<SortOption>((ref) => SortOption.distance);
