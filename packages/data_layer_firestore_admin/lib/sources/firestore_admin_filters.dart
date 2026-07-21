import 'package:data_layer/data_layer.dart';
import 'package:google_cloud_firestore/google_cloud_firestore.dart' hide Filter;

/// {@template FirestoreAdminFilter}
/// Filter for Firestore Admin queries.
/// {@endtemplate}
mixin FirestoreAdminFilter on Filter {
  /// Add whatever WHERE clauses are necessary to modify this [query].
  Query<DocumentData> apply(Query<DocumentData> query);
}
