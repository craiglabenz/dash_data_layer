Defining a `Repository<T>` often amounts to defining a `SourceList<T>`. However, this begs the question: __Why does the Repository class exist?__

The answer to this question is two-fold.

First, Repositories are the public-facing utility in `pkg:data_layer`, exposing a simpler API with simpler parameters. Specifically, the inner `Operation` construct is hidden from developers by the `Repository`, which creates one for the `SourceList` for each data request.

Second, Repositories are where you should place any custom business logic which does not neatly fall into one of the core `DataContract` methods.