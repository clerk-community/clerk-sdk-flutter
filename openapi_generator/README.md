## Generates clerk_backend_api package from open-api spec

Generated with https://pub.dev/packages/openapi_generator_cli

```sh
dart pub global activate openapi_generator_cli
```

```sh
openapi-generator generate --generator-name dart --config openapi-generator-config.json --output ../packages/clerk_backend_api --input-spec https://raw.githubusercontent.com/clerk/openapi-specs/refs/heads/main/bapi/2025-11-10.yml
```
