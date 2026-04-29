## Manual checks (not API-verifiable)

These items cannot be confirmed via the GitHub REST/GraphQL API. Walk through
each in the GitHub UI after the automated audit.

| Area | What to verify | Where in UI |
|---|---|---|
| Audit log streaming | Connected to a SIEM and ingestion is healthy | Enterprise → Settings → Audit log → Stream |
| Secret scanning alerts | Critical alerts triaged and resolved | Repo → Security → Secret scanning |
| Secret scanning custom patterns | Org-level patterns defined for internal token formats | Org → Settings → Code security → Secret scanning |
| Secret scanning bypass requests | Bypass reviewers configured for push protection | Org → Settings → Code security → Secret scanning |
| Code scanning default setup | Enabled on all active repos (no workflow needed) | Repo → Settings → Code security → Code scanning |
| Code scanning alert triage | Open high/critical alerts reviewed | Repo → Security → Code scanning |
| Code scanning tool coverage | Every relevant language is covered by some scanner | Repo → Security → Code scanning |
| Dependency review action | `dependency-review-action` runs on PRs | Repo → `.github/workflows/` |
| Self-hosted runners | Not exposed on public repos | Repo → Settings → Actions → Runners |
| Branch protection: enforce admins | "Do not allow bypassing the above settings" enabled | Repo → Settings → Branches |
| Environment protection rules | Reviewers configured for production environments | Repo → Settings → Environments |
| SAML SSO + SCIM | SSO enforced; SCIM provisioning active | Org → Settings → Authentication Security |
| IP Allow List | Configured and enabled | Org → Settings → Authentication Security |
| Org webhooks | SSL verification on, shared secret set | Org → Settings → Webhooks |
| Org-level rulesets | At least one ruleset governs default branches across repos | Org → Settings → Rules → Rulesets |
