import 'package:cloud_firestore/cloud_firestore.dart' hide Filter;
import 'package:data_layer/data_layer.dart';

/// {@template FirestoreFilter}
/// Filter for Firestore queries.
/// {@endtemplate}
mixin FirestoreFilter on Filter {
  /// Add whatever WHERE clauses are necessary to modify this [query].
  Query<Json> apply(Query<Json> query);
}
