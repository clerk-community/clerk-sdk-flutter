## Testing notes

### Run coverage for all packages

```shell
melos run coverage
```

### Run coverage for Dart packages only (clerk_auth + clerk_backend_api)

```shell
melos run coverage:dart
```

### Run coverage for Flutter packages only (clerk_flutter)

```shell
melos run coverage:flutter
```

### Generate HTML report (requires lcov)

```shell
melos run coverage:html
```

