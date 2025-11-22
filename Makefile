test:
	cd packages/data_layer && dart test
	cd packages/data_layer_hive && dart test

publish_data_layer_dry:
	cd packages/data_layer && dart pub publish --dry-run

publish_data_layer:
	cd packages/data_layer && dart pub publish
