import 'package:cloud_firestore/cloud_firestore.dart' as cf show Filter;
import 'package:cloud_firestore/cloud_firestore.dart' hide Filter;
import 'package:data_layer/data_layer.dart';

/// {@template FirestoreFilter}
/// Filter for Firestore queries.
/// {@endtemplate}
abstract class FirestoreFilter extends Filter {
  /// {@macro FirestoreFilter}
  const FirestoreFilter();

  /// Add whatever WHERE clauses are necessary to modify this [query].

  ///
  /// By default, if [toFirestoreFilter] returns a non-null [cf.Filter], this
  /// applies `query.where(firestoreFilter)`. Subclasses that only use
  /// `query.where(...)` predicates can override [toFirestoreFilter] alone and
  /// inherit both standard and [ComboFilter] (`AND` / `OR`) support.
  Query<Json> apply(Query<Json> query) {
    final filter = toFirestoreFilter();
    if (filter != null) {
      return query.where(filter);
    }
    throw UnimplementedError(
      '$runtimeType must implement either apply() or toFirestoreFilter().',
    );
  }

  /// Returns a `cloud_firestore` [cf.Filter] representation of this filter for
  /// use in [ComboFilter] queries with [BooleanLogic.or].
  ///
  /// Returns `null` by default. Subclasses must override this method to be
  /// usable inside a [BooleanLogic.or] [ComboFilter].
  ///
  /// Note: The key to understanding this function is to realize that
  /// [cf.Filter] is unrelated to a Data Layer `FirestoreFilter`. The former is
  /// a composable representation of a Firestore query, whereas the latter is a
  /// [Filter] that can be used to filter queries.
  cf.Filter? toFirestoreFilter() => null;
}
