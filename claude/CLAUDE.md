# Global rules

These apply to every project, not just this repo. Project-level `CLAUDE.md`
files add to them; where the two disagree, the project file wins.

## Code style

### Write idiomatic, performant code

- Read the surrounding file first and match it. Conventions already in the tree
  beat conventions you prefer.
- Prefer the standard library and the platform's own tools. Do not add a
  dependency for something a few lines covers.
- Write for someone who knows the language. No defensive ceremony, no
  hand-rolling what the stdlib already does, no abstractions with one caller.
- Performance: avoid needless allocation and copying in hot paths, and prefer
  streaming or laziness where the language makes it natural. Leave cold paths
  plain. Measure before optimising, and say what you measured.

### Be brief when commenting

- Comment the *why*. The code already says *what*.
- No narration of obvious lines, and no comment that restates the function
  name. If a comment is the only thing making a line clear, rename the thing
  instead.
- Never leave commented-out code. Git remembers it.
- Delete a stale comment in the same change that makes it stale.
- A short header on a non-obvious file or function beats inline noise. Silence
  is the right default for code that is already clear.

### Document with the language's own doc tooling

Use the ecosystem's doc format rather than ad-hoc prose:

| Language | Tool | Form |
| --- | --- | --- |
| Rust | rustdoc | `///`, with `# Examples` / `# Errors` where useful |
| Go | godoc | `// Name ...` above the declaration |
| Python | PEP 257 | `"""docstring"""` |
| TypeScript / JavaScript | JSDoc | `/** ... */` |
| C / C++ | Doxygen | `/** ... */` or `///` |
| Java / Kotlin | Javadoc / KDoc | `/** ... */` |
| Haskell | Haddock | `-- \|` |
| OCaml | odoc | `(** ... *)` |
| Lua | LDoc | `---` |
| Nix | nixpkgs style | `#` above the binding |
| Shell | — | `#` header block per script and per function |

- Document the *contract*: what it does, parameters, returns, errors, and any
  invariant a caller must uphold. Implementation notes belong in a plain
  comment, not the doc block.
- Do not document self-evident code. An undocumented obvious function is fine;
  a documented one is noise.

## Commits

**Subject line only.** No body, no bullet lists, no trailers. If a change needs
a paragraph to explain it, that is a sign it wants splitting, not describing.
Imperative mood, no trailing period.

## Reporting

Say plainly when something was written but not tested, and what would test it.
Do not imply a change was verified when it was only written.
