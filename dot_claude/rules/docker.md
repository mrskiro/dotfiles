---
paths:
  - "Dockerfile*"
  - "Containerfile*"
  - "**/Dockerfile*"
  - "**/*.dockerfile"
  - "**/Containerfile*"
---

- After editing, run `hadolint --ignore DL3008 --ignore DL3018 --ignore DL3059 --ignore DL3066 <file>` from the repository root. hadolint resolves `.hadolint.yaml` against the cwd, not the Dockerfile, so running it from elsewhere silently drops the repo's own config. CLI `--ignore` merges with the config file's `ignored` list despite what `--help` says
- Suppress noise with `--ignore`, not `--failure-threshold`. `-t` only changes the exit code — the filtered-out lines still print, and an agent will chase them
- DL3008/DL3018 (pin apt/apk versions) are ignored deliberately: hard-pinning distro packages breaks the build once the pinned version leaves the index, which costs more than the reproducibility it buys. DL3059/DL3066 are style noise
- Judge DL3064 (secrets in `ARG`/`ENV`) by build stage. In a multi-stage build only the final stage's environment ships; a token in a builder stage is not an exposure
- Drop to a non-root user in the final stage
- Use `ADD` only for remote URLs or archive extraction. Otherwise `COPY`
