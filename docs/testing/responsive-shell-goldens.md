# Responsive shell goldens

Generate and verify responsive shell golden images on Linux x64. CI uses the
`ubuntu-26.04` runner; matching that environment avoids platform-specific image
differences. FVM reads the repository's Flutter version from `.fvmrc`
(`3.47.5` currently).

From `apps/auravibes_app`, update the goldens with:

```sh
fvm flutter test test/widgets/responsive_shell_test.dart --no-pub --tags=golden --update-goldens
```

Then verify the updated goldens with:

```sh
fvm flutter test test/widgets/responsive_shell_test.dart --no-pub --tags=golden
```
