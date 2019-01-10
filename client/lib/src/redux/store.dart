import "package:redux/redux.dart";

import '../models/part.dart';
import '../models/status.dart';
import 'reducers/models.dart';

class AppState {
  final Map<int, Part> parts;
  final Map<int, Status> statuses;

  AppState([this.parts = const {}, this.statuses = const {}]);
}

AppState appStateReducer(AppState state, action) => AppState(
    partsReducer(state.parts, action), statusReducer(state.statuses, action));

Store<AppState> createStore() =>
    Store(appStateReducer, initialState: AppState());
