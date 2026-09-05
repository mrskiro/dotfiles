#!/usr/bin/env node
// auditing-github-posture: GitHub repo + org best-practice audit via gh CLI.
// Reference: https://github.com/microsoft/ghqr

import { execFileSync } from "node:child_process";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, resolve } from "node:path";
import { parseArgs } from "node:util";

const __dirname = dirname(fileURLToPath(import.meta.url));
const SKILL_ROOT = resolve(__dirname, "..");

const REPO_RULES = JSON.parse(readFileSync(resolve(SKILL_ROOT, "rules/repository.json"), "utf8"));
const ORG_RULES  = JSON.parse(readFileSync(resolve(SKILL_ROOT, "rules/organization.json"), "utf8"));
const RULES = Object.fromEntries([...REPO_RULES, ...ORG_RULES].map((r) => [r.id, r]));

const REPO_QUERY = readFileSync(resolve(SKILL_ROOT, "scripts/queries/repo.graphql"), "utf8");
const ORG_REPOS_QUERY = readFileSync(resolve(SKILL_ROOT, "scripts/queries/org-repos.graphql"), "utf8");

const SEVERITY_RANK = { critical: 0, high: 1, medium: 2, low: 3, info: 4 };
const SEVERITY_LABEL = {
  critical: "🔴 Critical",
  high: "🟠 High",
  medium: "🟡 Medium",
  low: "🟢 Low",
  info: "ℹ️ Info",
};

// ---------- gh wrapper ----------

function gh(args, { stdin } = {}) {
  try {
    const out = execFileSync("gh", args, {
      stdio: ["pipe", "pipe", "pipe"],
      input: stdin,
      maxBuffer: 50 * 1024 * 1024,
      encoding: "utf8",
    });
    return { ok: true, stdout: out };
  } catch (e) {
    return {
      ok: false,
      status: e.status,
      stderr: (e.stderr || "").toString(),
      stdout: (e.stdout || "").toString(),
    };
  }
}

function ghJSON(args) {
  const r = gh(args);
  if (!r.ok) return { ok: false, status: r.status, stderr: r.stderr };
  try {
    return { ok: true, data: JSON.parse(r.stdout) };
  } catch (e) {
    return { ok: false, parseError: e.message, raw: r.stdout };
  }
}

function ghGraphQL(query, variables) {
  const args = ["api", "graphql", "-f", `query=${query}`];
  for (const [k, v] of Object.entries(variables || {})) {
    if (typeof v === "number") args.push("-F", `${k}=${v}`);
    else if (v == null) continue;
    else args.push("-f", `${k}=${v}`);
  }
  return ghJSON(args);
}

// ---------- auth + scope detection ----------

function getAuthScopes() {
  const r = gh(["auth", "status"]);
  const text = (r.stderr || r.stdout || "").toString();
  const line = text.match(/Token scopes:\s*(.+)/);
  if (!line) return [];
  return [...line[1].matchAll(/'([^']+)'/g)].map((m) => m[1]);
}

function checkScopes(needed) {
  const have = getAuthScopes();
  const missing = needed.filter((s) => !have.includes(s));
  return { have, missing };
}

// ---------- repo eval ----------

function findingFor(id, detailMsg) {
  const r = RULES[id];
  if (!r) return { id, severity: "info", title: id, recommendation: "", learnMore: "" };
  return {
    id,
    severity: r.severity,
    category: r.category,
    title: r.title,
    description: r.description,
    recommendation: r.recommendation,
    learnMore: r.learnMore,
    detail: detailMsg || undefined,
  };
}

function evalBranchProtection(repo) {
  const out = [];
  const ref = repo.defaultBranchRef;
  const bp = ref?.branchProtectionRule;
  const ruleset = parseRulesetProtection(repo.rulesets?.nodes || [], ref?.name);
  const hasLegacy = bp && bp.pattern;

  if (!hasLegacy && !ruleset) {
    out.push(findingFor("repo-bp-001"));
    return out;
  }

  if (!hasLegacy && ruleset) {
    out.push(findingFor("repo-bp-014"));
    evalProtectionDetails(ruleset, out);
    return out;
  }

  evalProtectionDetails(
    {
      requiredApprovingReviewCount: bp.requiredApprovingReviewCount,
      requiresStatusChecks: bp.requiresStatusChecks,
      requiresStrictStatusChecks: bp.requiresStrictStatusChecks,
      requiredStatusContexts: (bp.requiredStatusChecks || []).map((c) => c.context),
      requiresCodeOwnerReviews: bp.requiresCodeOwnerReviews,
      dismissesStaleReviews: bp.dismissesStaleReviews,
      allowsForcePushes: bp.allowsForcePushes,
      allowsDeletions: bp.allowsDeletions,
      requiresCommitSignatures: bp.requiresCommitSignatures,
      requiresLinearHistory: bp.requiresLinearHistory,
      hasReviewRule: true,
    },
    out
  );
  return out;
}

function parseRulesetProtection(nodes, branchName) {
  if (!branchName) return null;
  const detail = {
    requiredApprovingReviewCount: 0,
    requiresStatusChecks: false,
    requiresStrictStatusChecks: false,
    requiredStatusContexts: [],
    requiresCodeOwnerReviews: false,
    dismissesStaleReviews: false,
    allowsForcePushes: true,
    allowsDeletions: true,
    requiresCommitSignatures: false,
    requiresLinearHistory: false,
    hasReviewRule: false,
    rulesetCount: 0,
  };
  for (const rs of nodes) {
    if (rs.enforcement !== "ACTIVE" || rs.target !== "BRANCH") continue;
    detail.rulesetCount++;
    for (const rule of rs.rules?.nodes || []) {
      const p = rule.parameters || {};
      switch (rule.type) {
        case "PULL_REQUEST":
          detail.hasReviewRule = true;
          if ((p.requiredApprovingReviewCount ?? 0) > detail.requiredApprovingReviewCount)
            detail.requiredApprovingReviewCount = p.requiredApprovingReviewCount;
          if (p.dismissStaleReviewsOnPush) detail.dismissesStaleReviews = true;
          if (p.requireCodeOwnerReview) detail.requiresCodeOwnerReviews = true;
          break;
        case "REQUIRED_STATUS_CHECKS":
          detail.requiresStatusChecks = true;
          if (p.strictRequiredStatusChecksPolicy) detail.requiresStrictStatusChecks = true;
          for (const c of p.requiredStatusChecks || []) {
            if (!detail.requiredStatusContexts.includes(c.context))
              detail.requiredStatusContexts.push(c.context);
          }
          break;
        case "REQUIRED_LINEAR_HISTORY":
          detail.requiresLinearHistory = true;
          break;
        case "REQUIRED_SIGNATURES":
          detail.requiresCommitSignatures = true;
          break;
        case "NON_FAST_FORWARD":
          detail.allowsForcePushes = false;
          break;
        case "DELETION":
          detail.allowsDeletions = false;
          break;
      }
    }
  }
  return detail.rulesetCount > 0 ? detail : null;
}

function evalProtectionDetails(d, out) {
  if (d.hasReviewRule) {
    if ((d.requiredApprovingReviewCount ?? 0) < 1) out.push(findingFor("repo-bp-002"));
    else if (d.requiredApprovingReviewCount < 2) out.push(findingFor("repo-bp-003"));
    if (!d.dismissesStaleReviews) out.push(findingFor("repo-bp-004"));
    if (!d.requiresCodeOwnerReviews) out.push(findingFor("repo-bp-005"));
  } else {
    out.push(findingFor("repo-bp-006"));
  }

  if (d.requiresStatusChecks) {
    if (!d.requiresStrictStatusChecks) out.push(findingFor("repo-bp-007"));
    if (!d.requiredStatusContexts.length) out.push(findingFor("repo-bp-008"));
  } else {
    out.push(findingFor("repo-bp-009"));
  }

  if (d.allowsForcePushes) out.push(findingFor("repo-bp-010"));
  if (d.allowsDeletions) out.push(findingFor("repo-bp-011"));
  if (!d.requiresCommitSignatures) out.push(findingFor("repo-bp-012"));
  if (!d.requiresLinearHistory) out.push(findingFor("repo-bp-013"));
}

function evalRepoSecurity(repo) {
  const out = [];
  if (!repo.hasVulnerabilityAlertsEnabled) out.push(findingFor("repo-sec-001"));

  const alerts = repo.vulnerabilityAlerts?.nodes || [];
  let critical = 0, high = 0;
  for (const a of alerts) {
    if (a.dismissedAt) continue;
    const sev = (a.securityVulnerability?.severity || "").toLowerCase();
    if (sev === "critical") critical++;
    else if (sev === "high") high++;
  }
  if (critical > 0) out.push(findingFor("repo-sec-002", `${critical} critical Dependabot alerts`));
  if (high > 0) out.push(findingFor("repo-sec-003", `${high} high-severity Dependabot alerts`));

  if (repo.isArchived) return out;

  if (!(repo.securityMdFile?.oid)) out.push(findingFor("repo-sec-004"));

  const codeowners =
    repo.codeownersFile?.oid ||
    repo.githubCodeownersFile?.oid ||
    repo.docsCodeownersFile?.oid;
  if (!codeowners) out.push(findingFor("repo-sec-005"));

  const dependabotConfig = repo.dependabotYmlFile?.oid || repo.dependabotYamlFile?.oid;
  if (!dependabotConfig) {
    if (repo.hasVulnerabilityAlertsEnabled) out.push(findingFor("repo-sec-006"));
    else out.push(findingFor("repo-sec-007"));
  }

  const codeql = repo.codeqlConfigFile?.oid || repo.codeqlAltConfigFile?.oid;
  if (!codeql) {
    out.push(findingFor("repo-sec-008"));
    out.push(findingFor("repo-sec-009"));
  }
  return out;
}

function evalRepoAccess(repo) {
  const out = [];
  const collabs = (repo.collaborators?.edges || []).map((e) => ({
    login: e.node?.login,
    permission: e.permission,
  }));
  let admin = 0, write = 0, read = 0;
  for (const c of collabs) {
    const p = (c.permission || "").toLowerCase();
    if (p === "admin") admin++;
    else if (p === "write" || p === "maintain") write++;
    else if (p === "read") read++;
  }
  if (admin > 3) out.push(findingFor("repo-acc-001", `${admin} admin collaborators`));
  if (collabs.length > 0) {
    out.push(
      findingFor(
        "repo-acc-002",
        `${collabs.length} direct collaborators (admin:${admin} write:${write} read:${read})`
      )
    );
  }

  const keys = repo.deployKeys?.nodes || [];
  let writeKeys = 0, unverified = 0;
  for (const k of keys) {
    if (!k.readOnly) writeKeys++;
    if (!k.verified) unverified++;
  }
  if (writeKeys > 0) out.push(findingFor("repo-acc-003", `${writeKeys} write deploy keys`));
  if (unverified > 0) out.push(findingFor("repo-acc-004", `${unverified} unverified deploy keys`));
  if (keys.length > 0) out.push(findingFor("repo-acc-005", `${keys.length} deploy keys configured`));
  return out;
}

function evalRepoMetadata(repo) {
  const out = [];
  if (repo.isArchived) return out;
  if (!repo.description) out.push(findingFor("repo-meta-001"));
  if (!(repo.repositoryTopics?.nodes?.length)) out.push(findingFor("repo-meta-002"));
  if (repo.pushedAt) {
    const pushedMs = Date.parse(repo.pushedAt);
    if (!Number.isNaN(pushedMs)) {
      const ageDays = (Date.now() - pushedMs) / (1000 * 60 * 60 * 24);
      if (ageDays > 365) out.push(findingFor("repo-meta-003"));
    }
  }
  return out;
}

function evalRepoFeatures(repo) {
  const out = [];
  if (repo.isArchived) return out;
  if (!repo.hasIssuesEnabled && !repo.hasDiscussionsEnabled) out.push(findingFor("repo-feat-001"));
  if (!repo.deleteBranchOnMerge) out.push(findingFor("repo-feat-002"));
  return out;
}

function evalRepoCommunity(repo) {
  const out = [];
  if (!repo.hasDiscussionsEnabled) out.push(findingFor("repo-comm-001"));
  return out;
}

function auditRepo(ownerRepo) {
  const [owner, name] = ownerRepo.split("/");
  if (!owner || !name) throw new Error(`--repo expects OWNER/REPO, got ${ownerRepo}`);

  const r = ghGraphQL(REPO_QUERY, { owner, name });
  if (!r.ok) {
    return { target: ownerRepo, error: r.stderr || r.parseError || "graphql failed", findings: [] };
  }
  const repo = r.data?.data?.repository;
  if (!repo) return { target: ownerRepo, error: "repository not found", findings: [] };

  const findings = [
    ...evalBranchProtection(repo),
    ...evalRepoSecurity(repo),
    ...evalRepoAccess(repo),
    ...evalRepoMetadata(repo),
    ...evalRepoFeatures(repo),
    ...evalRepoCommunity(repo),
  ];
  return { target: ownerRepo, repo, findings };
}

// ---------- org eval ----------

function evalOrgSecurity(settings) {
  const out = [];
  if (!settings.two_factor_requirement_enabled) {
    if (settings.emu_enabled) out.push(findingFor("org-sec-006"));
    else out.push(findingFor("org-sec-001"));
  }
  if (!settings.web_commit_signoff_required) out.push(findingFor("org-sec-002"));
  if (settings.default_repository_permission === "admin") out.push(findingFor("org-sec-003"));
  if (settings.members_can_create_public_repositories) out.push(findingFor("org-sec-004"));

  if (!settings.dependabot_alerts_enabled_for_new_repositories) out.push(findingFor("org-def-001"));
  if (!settings.dependabot_security_updates_enabled_for_new_repositories) out.push(findingFor("org-def-002"));
  if (!settings.dependency_graph_enabled_for_new_repositories) out.push(findingFor("org-def-003"));
  if (!settings.secret_scanning_enabled_for_new_repositories) out.push(findingFor("org-def-004"));
  if (!settings.secret_scanning_push_protection_enabled_for_new_repositories) out.push(findingFor("org-def-005"));
  if (!settings.advanced_security_enabled_for_new_repositories) out.push(findingFor("org-def-006"));
  return out;
}

function evalOrgActions(perms) {
  const out = [];
  if (!perms) return out;
  if (perms.default_workflow_permissions === "write") out.push(findingFor("org-act-001"));
  if (perms.allowed_actions === "all") out.push(findingFor("org-act-002"));
  else if (perms.allowed_actions === "local_only") out.push(findingFor("org-act-003"));
  return out;
}

function evalOrgCopilot(c) {
  const out = [];
  if (!c) return out;
  if (c.seat_management_setting === "assign_all") out.push(findingFor("org-cop-001"));
  if (c.public_code_suggestions === "allowed") out.push(findingFor("org-cop-002"));
  const total = c.seat_breakdown?.total ?? 0;
  const inactive = c.seat_breakdown?.inactive_this_cycle ?? 0;
  if (total > 0) {
    const pct = (inactive / total) * 100;
    if (pct > 20) out.push(findingFor("org-cop-003", `${pct.toFixed(0)}% inactive (${inactive}/${total})`));
  }
  return out;
}

function evalOrgAlerts(a) {
  const out = [];
  if (!a) return out;
  if (a.criticalDependabot > 0) out.push(findingFor("org-alert-001", `${a.criticalDependabot} critical`));
  if (a.highDependabot > 0) out.push(findingFor("org-alert-002", `${a.highDependabot} high`));
  if (a.openDependabot > 0 && a.criticalDependabot === 0 && a.highDependabot === 0)
    out.push(findingFor("org-alert-003", `${a.openDependabot} open (no critical/high)`));
  if (a.openCodeScanning > 0) out.push(findingFor("org-alert-004", `${a.openCodeScanning} open`));
  if (a.openSecretScanning > 0) out.push(findingFor("org-alert-005", `${a.openSecretScanning} open`));
  return out;
}

function evalOrgSecurityManagers(sm) {
  const out = [];
  if (!sm) return out;
  if (!sm.hasSecurityManager) out.push(findingFor("org-sec-005"));
  return out;
}

function fetchOrgSettings(org) {
  const r = ghJSON(["api", `orgs/${org}`]);
  if (!r.ok) return null;
  return r.data;
}

function fetchOrgActionsPerms(org) {
  const r = ghJSON(["api", `orgs/${org}/actions/permissions`]);
  if (!r.ok) return null;
  const base = r.data;
  const w = ghJSON(["api", `orgs/${org}/actions/permissions/workflow`]);
  if (w.ok) {
    base.default_workflow_permissions = w.data.default_workflow_permissions;
    base.can_approve_pull_request_reviews = w.data.can_approve_pull_request_reviews;
  }
  return base;
}

function fetchCopilot(org) {
  const r = ghJSON(["api", `orgs/${org}/copilot/billing`]);
  if (!r.ok) return null;
  return r.data;
}

function fetchOrgAlerts(org) {
  const result = {
    available: false,
    openDependabot: 0,
    criticalDependabot: 0,
    highDependabot: 0,
    openCodeScanning: 0,
    openSecretScanning: 0,
  };

  const dep = ghJSON(["api", "--paginate", `orgs/${org}/dependabot/alerts?state=open&per_page=100`]);
  if (dep.ok && Array.isArray(dep.data)) {
    result.available = true;
    result.openDependabot = dep.data.length;
    for (const a of dep.data) {
      const sev = (a.security_advisory?.severity || "").toLowerCase();
      if (sev === "critical") result.criticalDependabot++;
      else if (sev === "high") result.highDependabot++;
    }
  }
  const cs = ghJSON(["api", "--paginate", `orgs/${org}/code-scanning/alerts?state=open&per_page=100`]);
  if (cs.ok && Array.isArray(cs.data)) {
    result.available = true;
    result.openCodeScanning = cs.data.length;
  }
  const ss = ghJSON(["api", "--paginate", `orgs/${org}/secret-scanning/alerts?state=open&per_page=100`]);
  if (ss.ok && Array.isArray(ss.data)) {
    result.available = true;
    result.openSecretScanning = ss.data.length;
  }
  return result;
}

function fetchSecurityManagers(org) {
  const r = ghJSON(["api", `orgs/${org}/security-managers`]);
  if (!r.ok) return null;
  return { hasSecurityManager: Array.isArray(r.data) && r.data.length > 0 };
}

function fetchEMU(org) {
  const r = gh(["api", `orgs/${org}/external-groups`]);
  return r.ok;
}

function fetchOrgRepoNames(org) {
  const names = [];
  let after = null;
  while (true) {
    const r = ghGraphQL(ORG_REPOS_QUERY, { org, first: 100, after });
    if (!r.ok) break;
    const conn = r.data?.data?.organization?.repositories;
    if (!conn) break;
    for (const n of conn.nodes) names.push({ name: n.name, isArchived: n.isArchived });
    if (!conn.pageInfo.hasNextPage) break;
    after = conn.pageInfo.endCursor;
  }
  return names;
}

function auditOrg(org, { includeArchived = false } = {}) {
  const settings = fetchOrgSettings(org);
  if (settings == null) return { target: org, error: `cannot read org ${org}`, findings: [] };

  settings.emu_enabled = fetchEMU(org);

  const findings = [];
  findings.push(...evalOrgSecurity(settings));
  findings.push(...evalOrgActions(fetchOrgActionsPerms(org)));
  findings.push(...evalOrgCopilot(fetchCopilot(org)));
  findings.push(...evalOrgAlerts(fetchOrgAlerts(org)));
  findings.push(...evalOrgSecurityManagers(fetchSecurityManagers(org)));

  const result = { target: org, settings, findings, repos: [] };

  {
    const repos = fetchOrgRepoNames(org);
    for (const r of repos) {
      if (r.isArchived && !includeArchived) continue;
      const repoResult = auditRepo(`${org}/${r.name}`);
      result.repos.push(repoResult);
    }
  }
  return result;
}

// ---------- rendering ----------

function severityCounts(findings) {
  const c = { critical: 0, high: 0, medium: 0, low: 0, info: 0 };
  for (const f of findings) c[f.severity] = (c[f.severity] || 0) + 1;
  return c;
}

function sortBySeverity(findings) {
  return [...findings].sort(
    (a, b) => (SEVERITY_RANK[a.severity] ?? 99) - (SEVERITY_RANK[b.severity] ?? 99)
  );
}

function renderFindingsTable(findings) {
  if (!findings.length) return "_No findings._\n";
  const sorted = sortBySeverity(findings);
  const lines = ["| Severity | ID | Finding | Recommendation |", "|---|---|---|---|"];
  for (const f of sorted) {
    const detail = f.detail ? ` (${f.detail})` : "";
    lines.push(
      `| ${SEVERITY_LABEL[f.severity] || f.severity} | \`${f.id}\` | ${f.title}${detail} | ${
        f.recommendation || ""
      } |`
    );
  }
  return lines.join("\n") + "\n";
}

function renderRepo(result) {
  const parts = [];
  parts.push(`### Repository: \`${result.target}\`\n`);
  if (result.error) {
    parts.push(`> Error: ${result.error}\n`);
    return parts.join("\n");
  }
  const c = severityCounts(result.findings);
  parts.push(
    `**Findings:** ${result.findings.length} ` +
      `(critical ${c.critical}, high ${c.high}, medium ${c.medium}, low ${c.low}, info ${c.info})\n`
  );
  parts.push(renderFindingsTable(result.findings));
  return parts.join("\n");
}

function renderOrg(result) {
  const parts = [];
  parts.push(`## Organization: \`${result.target}\`\n`);
  if (result.error) {
    parts.push(`> Error: ${result.error}\n`);
    return parts.join("\n");
  }
  const c = severityCounts(result.findings);
  parts.push(
    `**Org-level findings:** ${result.findings.length} ` +
      `(critical ${c.critical}, high ${c.high}, medium ${c.medium}, low ${c.low}, info ${c.info})\n`
  );
  parts.push(renderFindingsTable(result.findings));

  if (result.repos.length) {
    parts.push(`---\n`);
    parts.push(`## Repositories (${result.repos.length})\n`);
    const totals = severityCounts(result.repos.flatMap((r) => r.findings));
    parts.push(
      `**Aggregate repo findings:** critical ${totals.critical}, high ${totals.high}, ` +
        `medium ${totals.medium}, low ${totals.low}, info ${totals.info}\n`
    );
    for (const r of result.repos) parts.push(renderRepo(r));
  }
  return parts.join("\n");
}

function renderManualChecks() {
  const path = resolve(SKILL_ROOT, "references/manual-checks.md");
  try {
    return "\n---\n" + readFileSync(path, "utf8");
  } catch {
    return "";
  }
}

function renderHeader(target, mode) {
  const ts = new Date().toISOString();
  return `# GitHub Posture Audit\n\n**Target:** ${target}\n**Mode:** ${mode}\n**Generated:** ${ts}\n\n---\n`;
}

// ---------- main ----------

function printScopeWarning(missing) {
  if (!missing.length) return;
  process.stderr.write(
    `[warn] gh token missing scopes: ${missing.join(", ")}. ` +
      `Some checks may be skipped. Run: gh auth refresh -s ${missing.join(",")}\n`
  );
}

function main() {
  const { values } = parseArgs({
    options: {
      repo: { type: "string" },
      org: { type: "string" },
      "include-archived": { type: "boolean", default: false },
      json: { type: "boolean", default: false },
      help: { type: "boolean", short: "h", default: false },
    },
    allowPositionals: false,
  });

  if (values.help || (!values.repo && !values.org)) {
    process.stdout.write(
      `Usage: audit.mjs [--repo OWNER/REPO | --org NAME [--include-archived]] [--json]\n`
    );
    process.exit(values.help ? 0 : 2);
  }

  if (values.repo && values.org) {
    process.stderr.write("error: pass either --repo or --org, not both\n");
    process.exit(2);
  }

  const needed = values.org ? ["read:org", "repo"] : ["repo"];
  const { missing } = checkScopes(needed);
  printScopeWarning(missing);

  let result;
  let mode;
  if (values.repo) {
    mode = "repo";
    result = auditRepo(values.repo);
  } else {
    mode = "org";
    result = auditOrg(values.org, {
      includeArchived: values["include-archived"],
    });
  }

  if (values.json) {
    process.stdout.write(JSON.stringify(result, null, 2) + "\n");
    return;
  }

  const target = values.repo || values.org;
  process.stdout.write(renderHeader(target, mode));
  if (mode === "repo") process.stdout.write(renderRepo(result));
  else process.stdout.write(renderOrg(result));
  process.stdout.write(renderManualChecks());
}

main();
