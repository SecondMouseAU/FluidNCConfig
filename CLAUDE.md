# CLAUDE.md

**Start at [`okf/index.md`](okf/index.md)**, this repo's OKF 0.2 knowledge bundle: what the repo
is, what it depends on, its components, and the mandatory policies. Read the one page a task
needs, when it needs it. Do not read the bundle up front, and never `@`-import it: `@` inlines a
file into every session, which is the cost this layout exists to avoid.

| Before you | Read |
|---|---|
| touch an OCCT or OCCTSwift API | [`okf/policies/context-first.md`](okf/policies/context-first.md) |
| write a new type, helper, or tool | [`okf/policies/search-before-building.md`](okf/policies/search-before-building.md) |
| add a file, or split one | [`okf/policies/code-structure.md`](okf/policies/code-structure.md) |
| write prose, a comment, a commit or a PR body | [`okf/policies/writing-style.md`](okf/policies/writing-style.md) |
| open an issue | [`okf/policies/issue-tracking.md`](okf/policies/issue-tracking.md) |
| ship or release a change | [`okf/policies/docs-current.md`](okf/policies/docs-current.md) |

If `okf/references/pre-pr-workflow.md` exists here, this repo is in the pre-PR review trial: read
it before `gh pr create`, or when a gate has blocked you.

---

Everything below is what a session in this checkout needs in hand: how to build it, how to test
it, and the invariants that break it. Durable what and why lives in `okf/`. Budget: 150 lines
below this rule. If a section is growing past a screen of prose, it belongs in the bundle.

## Build and test

```bash
swift build
swift test
swift-format lint --strict --configuration .swift-format -r Sources Tests
swiftlint lint --strict --config .swiftlint.yml
```

## Invariants

- Public and MIT. No dependencies, and none may be added: the reader is a deliberate YAML subset.
- Nothing is defaulted. A value the file does not state is `nil`; the caller decides what that
  means. Do not add fallback numbers here.
- Keys match case-insensitively, as FluidNC matches them. Unknown keys are ignored, so new firmware
  options must never make a parse fail.
- Real configs are the test oracle. Fixtures are synthetic, shaped like real files; do not commit
  a user's actual config.
