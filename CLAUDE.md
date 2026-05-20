# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repo-Specific Commands

```bash
# Build (compiles TypeScript to lib/)
yarn build

# Run all checks: lint + tsc typecheck + mocha tests with nyc coverage
yarn test

# Run only mocha tests (skips lint/tsc)
yarn test-watch   # watch mode

# Type check without emit
yarn tsc

# Coverage report (lcov + text)
# nyc wraps mocha automatically via `yarn test`

# Release (cleans, reinstalls, tests, builds, then release-it)
yarn prerelease && yarn release

# Watch modes (runs all *-watch scripts concurrently)
yarn watch
```

## Architecture

This is a published npm library (`@foxden/saml-passport`, `main: ./lib`). It is a Foxquilt fork of the upstream `@node-saml/passport-saml` package, adapted to use the internal `@foxden/saml-node` package instead of `@node-saml/saml-core`.

**Key difference from upstream:** The SAML core logic lives in `@foxden/saml-node` (a separate repo: `foxden-node-saml`), not in this repo. This repo only contains the Passport.js strategy wrappers.

## Source Files (`src/`)

```
src/
  index.ts             # Public exports: Strategy, AbstractStrategy, MultiSamlStrategy + re-exports from @foxden/saml-node
  strategy.ts          # AbstractStrategy (base) + Strategy (concrete) — single-provider SAML
  multiSamlStrategy.ts # MultiSamlStrategy — dynamic multi-provider SAML via getSamlOptions callback
  types.ts             # TypeScript types: VerifiedCallback, VerifyWithRequest, VerifyWithoutRequest, MultiStrategyConfig, etc.
```

## Testing

- Framework: **Mocha** (not Jest) + Chai assertions + Sinon stubs
- Coverage: **nyc** (Istanbul), config in `.nycrc.json` — reporters: `lcov` + `text`
- Test files: `test/strategy.spec.ts`, `test/multiSamlStrategy.spec.ts`
- Run with: `yarn test` (runs lint + tsc + `nyc mocha`)

## Key Design Patterns

- `AbstractStrategy` extends `passport-strategy`'s `PassportStrategy` and holds shared sign-on/logout verify function logic
- `Strategy` sets `static newSamlProviderOnConstruct = true` — creates a `SAML` instance in the constructor
- `MultiSamlStrategy` sets `static newSamlProviderOnConstruct = false` — defers `SAML` instantiation to each `authenticate()` call, creating a new instance per request via `getSamlOptions`
- Both strategies accept two verify functions: `signonVerify` (SSO) and `logoutVerify` (SLO)
- `passReqToCallback` option toggles between `VerifyWithRequest` and `VerifyWithoutRequest` signatures

## Publishing

Built output goes to `lib/` (compiled JS + `.d.ts`). The `files` field in package.json limits published content to `lib/`, `README.md`, and `LICENSE`. Version bumping and GitHub release notes are handled by `release-it` + `@cjbarth/github-release-notes`.
