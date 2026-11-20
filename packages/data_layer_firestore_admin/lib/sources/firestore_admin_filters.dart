import 'package:data_layer/data_layer.dart';
import 'package:google_cloud_firestore/google_cloud_firestore.dart'
    as gcf
    show Filter;
import 'package:google_cloud_firestore/google_cloud_firestore.dart' hide Filter;

/// {@template FirestoreAdminFilter}
/// Filter for Firestore Admin queries.
/// {@endtemplate}
mixin FirestoreAdminFilter on Filter {
  /// Add whatever WHERE clauses are necessary to modify this [query].
  ///
  /// By default, if [toFirestoreFilter] returns a non-null [gcf.Filter], this
  /// applies `query.whereFilter(firestoreFilter)`. Subclasses that only use
  /// `whereFilter` predicates can override [toFirestoreFilter] alone and
  /// inherit both standard and [ComboFilter] (`AND` / `OR`) support.
  Query<DocumentData> apply(Query<DocumentData> query) {
    final filter = toFirestoreFilter();
    if (filter != null) {
      return query.whereFilter(filter);
    }
    throw UnimplementedError(
      '$runtimeType must implement either apply() or toFirestoreFilter().',
    );
  }

  /// Returns a `google_cloud_firestore` [gcf.Filter] representation of this
  /// filter for use in [ComboFilter] queries with [BooleanLogic.or].
  ///
  /// Returns `null` by default. Subclasses must override this method to be
  /// usable inside a [BooleanLogic.or] [ComboFilter].
  ///
  /// Note: The key to understanding this function is to realize that
  /// [gcf.Filter] is unrelated to a Data Layer `FirestoreFilter`. The former is
  /// a composable representation of a Firestore query, whereas the latter is a
  /// [Filter] that can be used to filter queries.
  gcf.Filter? toFirestoreFilter() => null;
}
