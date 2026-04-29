#!/usr/bin/env node
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import readline from 'node:readline';

const PROJECTS_DIR = path.join(os.homedir(), '.claude/projects');
const ROLE_WEIGHT = { user: 3, summary: 3, assistant: 1 };
const CONCURRENCY = 10;

function parseArgs(argv) {
  const args = {
    keywords: [],
    since: null,
    project: null,
    limit: 10,
    role: null,
    maxSnippet: 150,
    verbose: false,
    or: false,
    help: false,
  };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--since') args.since = argv[++i];
    else if (a === '--project') args.project = argv[++i];
    else if (a === '--limit') args.limit = parseInt(argv[++i], 10);
    else if (a === '--role') args.role = argv[++i];
    else if (a === '--max-snippet') args.maxSnippet = parseInt(argv[++i], 10);
    else if (a === '--verbose' || a === '-v') args.verbose = true;
    else if (a === '--or') args.or = true;
    else if (a === '--help' || a === '-h') args.help = true;
    else args.keywords.push(a);
  }
  return args;
}

function parseDuration(s) {
  const m = /^(\d+)([dhm])$/.exec(s);
  if (!m) return null;
  const n = parseInt(m[1], 10);
  const ms = m[2] === 'd' ? 86400e3 : m[2] === 'h' ? 3600e3 : 60e3;
  return n * ms;
}

function extractText(rec) {
  if (rec.type === 'summary') {
    return { role: 'summary', text: rec.summary || '' };
  }
  if (rec.type === 'user' && rec.message?.role === 'user') {
    const c = rec.message.content;
    if (typeof c === 'string') return { role: 'user', text: c };
    if (Array.isArray(c)) {
      const texts = c.filter(b => b?.type === 'text').map(b => b.text || '').join('\n');
      if (texts) return { role: 'user', text: texts };
    }
    return null;
  }
  if (rec.type === 'assistant' && rec.message?.role === 'assistant') {
    const c = rec.message.content;
    if (Array.isArray(c)) {
      const texts = c.filter(b => b?.type === 'text').map(b => b.text || '').join('\n');
      if (texts) return { role: 'assistant', text: texts };
    }
    return null;
  }
  return null;
}

function tokensMatch(text, tokens, anyMode) {
  const lower = text.toLowerCase();
  return anyMode
    ? tokens.some(t => lower.includes(t))
    : tokens.every(t => lower.includes(t));
}

function countMatchedTokens(text, tokens) {
  const lower = text.toLowerCase();
  let n = 0;
  for (const t of tokens) if (lower.includes(t)) n++;
  return n;
}

function extractSnippet(text, tokens, maxLen) {
  const lower = text.toLowerCase();
  let firstIdx = -1;
  for (const t of tokens) {
    const i = lower.indexOf(t);
    if (i >= 0 && (firstIdx < 0 || i < firstIdx)) firstIdx = i;
  }
  if (firstIdx < 0) firstIdx = 0;
  const half = Math.floor(maxLen / 2);
  const start = Math.max(0, firstIdx - half);
  const end = Math.min(text.length, start + maxLen);
  let snippet = text.slice(start, end).replace(/\s+/g, ' ').trim();
  if (start > 0) snippet = '…' + snippet;
  if (end < text.length) snippet = snippet + '…';
  return snippet;
}

async function searchFile(filePath, tokens, opts, hits) {
  let stream;
  try {
    stream = fs.createReadStream(filePath, { encoding: 'utf8' });
  } catch {
    return;
  }
  const rl = readline.createInterface({ input: stream, crlfDelay: Infinity });
  for await (const line of rl) {
    if (!line) continue;
    let rec;
    try { rec = JSON.parse(line); } catch { continue; }
    const ext = extractText(rec);
    if (!ext) continue;
    if (opts.role && ext.role !== opts.role) continue;
    if (!tokensMatch(ext.text, tokens, opts.or)) continue;
    const cwd = rec.cwd || '';
    if (opts.project && !cwd.toLowerCase().includes(opts.project.toLowerCase())) continue;
    const ts = rec.timestamp || null;
    if (opts.sinceMs && ts) {
      const t = Date.parse(ts);
      if (Number.isFinite(t) && Date.now() - t > opts.sinceMs) continue;
    }
    const matched = opts.or ? countMatchedTokens(ext.text, tokens) : tokens.length;
    const score = (ROLE_WEIGHT[ext.role] || 1) * matched;
    const hit = {
      sessionId: rec.sessionId || null,
      project: cwd ? path.basename(cwd) : path.basename(path.dirname(filePath)),
      timestamp: ts,
      role: ext.role,
      snippet: extractSnippet(ext.text, tokens, opts.maxSnippet),
    };
    if (opts.verbose) {
      hit.cwd = cwd;
      hit.score = score;
      hit.matched = matched;
      hit.file = filePath;
    }
    hit._score = score;
    hits.push(hit);
  }
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  if (args.help || args.keywords.length === 0) {
    process.stderr.write(
      'Usage: search.mjs <keyword>... [--or] [--since 7d] [--project <name>] ' +
      '[--role user|assistant|summary] [--limit 10] [--max-snippet 150] [--verbose]\n'
    );
    process.exit(args.help ? 0 : 2);
  }
  const tokens = args.keywords.map(k => k.toLowerCase());
  const sinceMs = args.since ? parseDuration(args.since) : null;
  if (args.since && sinceMs == null) {
    process.stderr.write(`Invalid --since: ${args.since} (use e.g. 7d, 24h, 30m)\n`);
    process.exit(2);
  }
  const opts = { ...args, sinceMs };

  let entries;
  try {
    entries = fs.readdirSync(PROJECTS_DIR);
  } catch (e) {
    process.stderr.write(`Cannot read ${PROJECTS_DIR}: ${e.message}\n`);
    process.exit(1);
  }

  const files = [];
  for (const dir of entries) {
    const dirPath = path.join(PROJECTS_DIR, dir);
    let stat;
    try { stat = fs.statSync(dirPath); } catch { continue; }
    if (!stat.isDirectory()) continue;
    let inner;
    try { inner = fs.readdirSync(dirPath); } catch { continue; }
    for (const f of inner) {
      if (!f.endsWith('.jsonl')) continue;
      const fp = path.join(dirPath, f);
      let s;
      try { s = fs.statSync(fp); } catch { continue; }
      if (opts.sinceMs && Date.now() - s.mtimeMs > opts.sinceMs) continue;
      files.push(fp);
    }
  }

  const hits = [];
  for (let i = 0; i < files.length; i += CONCURRENCY) {
    const batch = files.slice(i, i + CONCURRENCY);
    await Promise.all(batch.map(fp => searchFile(fp, tokens, opts, hits)));
  }

  hits.sort((a, b) => {
    if (b._score !== a._score) return b._score - a._score;
    const at = a.timestamp ? Date.parse(a.timestamp) : 0;
    const bt = b.timestamp ? Date.parse(b.timestamp) : 0;
    return bt - at;
  });

  const out = hits.slice(0, opts.limit);
  for (const h of out) {
    delete h._score;
    process.stdout.write(JSON.stringify(h) + '\n');
  }

  process.stderr.write(
    `Found ${hits.length} matches across ${files.length} sessions, showing top ${out.length}\n`
  );
}

main().catch(e => {
  process.stderr.write(`Error: ${e.stack || e.message}\n`);
  process.exit(1);
});
