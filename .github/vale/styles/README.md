# Vale Styles

This directory stores Vale linting styles. Styles are **not committed** to the
repository — they are downloaded at lint time by running:

```bash
vale sync
```

The `vale.yml` GitHub Actions workflow runs `vale sync` automatically before
linting pull requests.

## Configured styles

| Package | Purpose |
|---------|---------|
| `Vale`  | Vale's built-in prose rules (the baseline) |

## Adding more styles

1. Add the package name to the `Packages` line in `/.vale.ini`
2. Run `vale sync` locally to download it
3. Add the package name to `BasedOnStyles` in `/.vale.ini`

Popular packages: `Google`, `write-good`, `proselint`, `alex`
See: <https://vale.sh/hub/>
