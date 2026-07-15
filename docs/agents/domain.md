# Domain Docs

This repository uses a single-context domain-documentation layout.

## Before exploring

Read these files when they exist:

- `CONTEXT.md` at the repository root
- Relevant ADRs under `docs/adr/`

If they do not exist, proceed silently. Domain-modeling skills create them lazily when terminology or architectural decisions are resolved.

## Layout

```
/
├── CONTEXT.md
└── docs/adr/
```

## Vocabulary

Use terminology defined in `CONTEXT.md`. Avoid synonyms that the glossary explicitly rejects.

If a necessary concept is missing, reconsider whether it belongs to the project or note it for domain modeling.

## ADR conflicts

Explicitly identify output that contradicts an existing ADR rather than silently overriding it.
