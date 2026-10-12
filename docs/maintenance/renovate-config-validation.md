# Renovate configuration validation

Pull requests that change the root `renovate.json` run Renovate's
`renovate-config-validator` in strict mode. The job only validates the
configuration; it does not run dependency updates, create branches, or open
pull requests, and it has read-only repository permissions.

To run the same check locally with Node.js 24.11.0 or newer:

```sh
npx --yes --package renovate@44.149.0 -- renovate-config-validator --strict
```

The validator checks configuration structure, option names, and rule
combinations against Renovate's supported configuration. It does not perform
dependency lookups or confirm that package names resolve. Registry and
datasource lookup warnings require a separate check; passing schema and option
validation alone does not prove that dependency lookups will succeed.
