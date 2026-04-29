## Token scope → rule mapping

`gh auth status` shows current scopes. Add what you're missing with:

```bash
gh auth refresh -s <scope1>,<scope2>
```

| Scope | Unlocks | Rules affected |
|---|---|---|
| `repo` | private repo metadata, branch protection details, alerts on private repos | `repo-bp-*`, `repo-sec-*`, `repo-acc-*`, `repo-meta-*`, `repo-feat-*`, `repo-comm-*` |
| `read:org` | org settings, member counts, security manager team, EMU probe, default repo permissions | `org-sec-*`, `org-def-*` |
| `copilot` | Copilot billing & policy | `org-cop-001`, `org-cop-002`, `org-cop-003` |
| `admin:org` (read) | Actions permissions endpoint on some orgs | `org-act-001`, `org-act-002`, `org-act-003` |
| `read:audit_log` | Enterprise audit log (out of scope here, used by upstream ghqr only) | enterprise rules — not implemented in this skill |

If a scope is missing, the corresponding `gh api` call returns 403/404, the
rule check returns no data, and the rule simply does not fire (it is not a
false-positive — it's a silent skip). The script prints a stderr warning
listing the missing scopes when run.

### Verification

```bash
gh auth status
gh api user -i 2>&1 | grep -i x-oauth-scopes
```

The second form shows the live scopes from the API response header, which is
useful when `gh auth status` is stale.
