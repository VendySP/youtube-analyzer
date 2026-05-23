mkdir -p ytA-layer/python

pip install \
    --platform manylinux2014_x86_64 \
    --target ytA-layer/python/ \
    --implementation cp \
    --python-version 3.12 \
    --only-binary=:all: \
    google-api-python-client

cd ytA-layer
zip -r ytAnalyzer_api_layer.zip python/