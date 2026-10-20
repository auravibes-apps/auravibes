# Translation catalogs

Read this file when you add or change JSON keys, placeholders, plurals, gender forms, or linked messages.

## Key rules

- Use `snake_case` for every key.
- Group keys by feature or screen, not by widget type.
- Put shared messages under a `common` key.
- Keep the same nested key paths in `en.json` and `es.json`. Translate values for each locale.
- Check `apps/auravibes_app/AGENTS.md` and the localization audit before you change catalog policy.

The app enables runtime fallback to English. This can help at runtime when a locale lacks a key. It does not satisfy the app rule or audit. Add every key to both catalogs.

## Catalog shape

These example keys show the expected nested shape:

`en.json`:

```json
{
  "common": {
    "save": "Save",
    "cancel": "Cancel"
  },
  "workspace_list": {
    "empty_title": "No workspaces"
  }
}
```

`es.json`:

```json
{
  "common": {
    "save": "Guardar",
    "cancel": "Cancelar"
  },
  "workspace_list": {
    "empty_title": "No hay espacios de trabajo"
  }
}
```

## Placeholders

Use `{}` for positional arguments and `{name}` for named arguments. Keep each placeholder name and count the same in both catalogs.

The JSON keys and Dart constants below are examples. Use keys from the generated file.

```json
{
  "delete_prompt": "Delete {name}?",
  "items_count": "{} items"
}
```

Use `args` for positional values and `namedArgs` for named values:

```dart
TextLocale(LocaleKeys.items_count, args: [count.toString()]);
LocaleKeys.delete_prompt.tr(namedArgs: {'name': itemName});
```

## Plurals and gender

By default, `easy_localization` uses `zero`, `one`, `two`, and `other`. It ignores `few` and `many`. Set `ignorePluralRules: false` when you need those branches. Check `MainLocale` and package docs first.

```json
{
  "item_count": {
    "one": "{} item",
    "other": "{} items"
  }
}
```

Call `.plural()` with a numeric value to select a branch. Pass the value as an argument when the message uses `{}`:

```dart
LocaleKeys.item_count.plural(
  count,
  args: [count.toString()],
);
```

Use `male`, `female`, or `other` branches when a message needs gender selection. Pass the matching value with `gender`.

## Linked messages

Use `@:` to link a message to another key. Use full dotted paths.

```json
{
  "common": {
    "save": "Save"
  },
  "actions": {
    "save_button": "@:common.save"
  }
}
```

Use `@.upper:`, `@.lower:`, or `@.capitalize:` before a full key path to change letter case. Confirm the target key exists in both catalogs.
