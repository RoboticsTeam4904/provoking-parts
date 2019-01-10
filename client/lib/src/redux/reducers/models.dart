import 'package:redux/redux.dart';

import '../../models/base.dart';
import '../../models/part.dart';
import '../../models/status.dart';

class UpdateModelAction<T extends Model> {
  final T previous;
  final T current;

  UpdateModelAction({this.previous, this.current});
}

Map<int, T> updateModelReducer<T extends Model>(
        Map<int, T> models, UpdateModelAction<T> action) =>
    Map.from(models)
      ..remove(action.previous?.id)
      ..addAll(
          action.current == null ? {} : {action.current.id: action.current});

class ModelReducer<T extends Model>
    extends TypedReducer<Map<int, T>, UpdateModelAction<T>> {
  ModelReducer(reducer) : super(reducer);
}

final partsReducer = combineReducers<Map<int, Part>>([
  ModelReducer<Part>(updateModelReducer),
]);

final statusReducer = combineReducers<Map<int, Status>>([
  ModelReducer<Status>(updateModelReducer),
]);
