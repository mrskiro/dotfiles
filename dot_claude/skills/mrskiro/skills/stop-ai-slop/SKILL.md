---
name: stop-ai-slop
description: >
  "AIっぽい" "AI臭" "AI slop" "humanize" "humanize this draft" "ChatGPTっぽさ"
  "Claudeっぽさ" "review for AI patterns" "rewrite to sound human" "polish
  this draft" "doesn't sound like me" "this reads weird" — Detect and remove
  patterns that mark text as AI-generated, in Japanese or English, across
  genres (academic, tech blog, essay, business). Use when reviewing or
  editing LLM-drafted text before publication, even when the user says
  "polish this", "make it sound less like ChatGPT", or asks to proofread
  a draft they suspect was AI-influenced.
license: MIT
metadata:
  target-text-languages: ja, en
  inspired-by: iKora128/stop-ai-slop-jp; m0370 humanizer checklist; Wikipedia Signs of AI writing
---

# Stop AI Slop

Detect and remove AI-writing patterns from a draft. Apply the standing instructions below whenever a draft is brought in for review or editing.

## The big principle

AI-slop is, at root, the **absence of the writer**. Em dashes, pet words, and three-item parallels are symptoms. If the draft has no stance, no specific claim, and no voice, surface fixes are premature.

Before touching commas, get answers to three questions:

- What does the piece commit to? (an arguable claim someone could push back on)
- Where do specifics live? (a named person, an actual failure, a number, a date)
- What distinguishes this from the median article on the same topic?

If those are unanswered, work at the idea level first. Symbol cleanup last.

## Operating modes

Pick the mode by where the draft is in its life. The user rarely names a mode — infer it from what they show you.

### Mode A: Pre-draft (notes or outline only)

No body text exists yet. Before producing a draft, confirm the three principle questions. Push back on writing body until those have concrete answers — a draft that starts without a stance produces slop no amount of editing will save.

### Mode B: Mid-draft (editing in place)

A draft exists and is being shaped. Apply the priority order below. Do not jump to symbol cleanup before the human-judgment work is done.

### Mode C: Pre-publication (final pass)

The draft is close to done. Run the mechanical checks (deterministic search/replace) and read aloud for rhythm. Score on the 5 axes. If total < 35/50, return to Mode B.

## Priority order

Fix in this order. Skipping #1–3 and doing only #4–5 leaves the slop intact under a clean surface.

1. **Stance** — Is there an arguable, specific claim? If not, the draft needs a rewrite at the idea level, not the word level.
2. **False agency** — Are inanimate objects performing human verbs? ("The data shows…", "文化が醸成される", "The architecture decides…") Rewrite to name the actual human agent.
3. **Structural templates** — Proposition-style headings, reversal intros, uniform paragraph length, three-item parallels.
4. **Vocabulary and phrasing** — Pet words, super-move coinages, translation-ese verbs, adverb stacking, hedge stacking, English metaphors-as-filler.
5. **Symbols and artifacts** — Em dashes, decorative emoji, `**` residue, stray middle-dot enumerations, smart-quotes around plain words.

## Mechanical checks (Mode C — pure search/replace)

These need no judgment. Apply last:

- `——` / `—` / `--` → colon, comma, period, or line break per context
- `**word**` around non-headings → strip
- Decorative emoji (🚀🎯✨💡🔥) sprinkled evenly across paragraphs → remove
- `中黒` enumeration ("A・B・C") of three or more → prose with と/や (ja) or "and"/"or" (en)
- Half-width space after `:` in Japanese text → remove
- Section-leading summary sentences ("In this section we discuss…", "ここでは〜について解説します") → delete; the heading already says it
- Closing template clichés ("今後の展開が注目されます", "It will be interesting to see…") → cut or replace with a real claim

## Human-judgment checks

For the full catalog with examples, load `references/structures.md`. The high-frequency ones:

- **False agency** — objects doing human verbs. Name the agent.
- **Proposition-style headings** — "X is Y" headings turn each section into a mini-TED-talk. Use noun phrases instead.
- **Reversal intro** — "Most people think X. But actually Y." Drop the setup; state Y directly.
- **Three-item parallel** — "3 keys", "3 perspectives", "3 principles". Collapse to two or one when possible. AI defaults to three.
- **Hedge stacking** — "may possibly be…", "〜の可能性があるかもしれません" → one hedge or none.
- **-ing tacking-on** — "…, highlighting the importance of…", "〜を浮き彫りにしており" → cut. Let the fact stand.
- **Copula avoidance** — "serves as", "stands as", "〜として位置づけられています" → plain "is" / "〜です".
- **Synonym recycling** — same referent called "tool", "approach", "means", "framework" within three sentences → pick one and stick with it.
- **Both-sides hedging** — "There are upsides and downsides" with no side taken. Either commit or cut.
- **Distant voice** — "Many people…", "Engineers tend to…", "現代社会において". Replace with a specific person, case, or number.
- **Vague attribution** — "experts say", "research suggests", "専門家によると" with no citation. Cite or cut.

## Vocabulary watch

Load `references/phrases.md` when running this pass. Categories to scan for:

- **English AI-favored words**: delve, tapestry, landscape, pivotal, multifaceted, testament, navigate, leverage, realm, intricate, paramount, crucial, comprehensive, robust
- **Japanese pet words**: 泥臭さ、手触り、解像度、熱量、本質、営み、文脈、設計、装置、思想
- **Japanese super-move coinages**: 真理、虚飾、禁欲的、美学、境地、結末
- **English-metaphor filler**: "update your mental OS", "hack your life", "refactor your mindset", "level up your", "10x your"
- **Adverb stacking**: very, extremely, incredibly, とても、非常に、めっちゃ、普通に、ガチで
- **Academic-tic words**: "本稿", "本記事", "筆者", "this paper", "this article" in body prose

## The sterile-room trap

After removing patterns, the draft can become clean but voiceless. That is also AI-slop, just a different flavor. Restore voice:

- State a position at least once per major section. "I think X" or "I'd avoid this", not "It could be argued…"
- Include at least one concrete object per section: a named person, a number, a failure, a quote, a date
- Vary paragraph length on purpose. A single one-line paragraph between two long ones breaks the uniform rhythm AI defaults to
- Allow venom, self-mockery, irony where the topic earns it. AI cannot write these and their absence is felt
- Mix sentence endings — in Japanese, vary だ / です / 体言止め / 体言+句点; in English, vary length and structure

## Read aloud (Mode C)

Before final delivery, read the piece aloud, or sentence-by-sentence slowly if reading aloud isn't possible. Mark:

- Spots where you want a pause but there's no comma or paragraph break
- Spots where you run out of breath (split the sentence)
- Spots where consecutive sentences share rhythm (vary endings)

Lists miss what the mouth catches.

## Scoring

Score 1–10 on each axis. Total < 35/50 → return to Mode B, do not just polish.

| Axis | Question |
|---|---|
| Stance | Is there an arguable, specific claim someone could push back on? |
| Rhythm | Do paragraph length, tone, and sentence endings vary? |
| Agency | Are human agents named where they act? (no false agency) |
| Concreteness | Does the writing descend from abstraction to specific cases? |
| Cuts | What can be removed without loss of meaning? |

## Genre presets

The mix shifts by genre. Apply the relevant emphasis from `references/phrases.md` and `references/structures.md`:

- **Academic** — hedge stacking, vague attribution, -ing tacking-on, copula avoidance
- **Tech blog** — false agency ("the framework decides"), three-item parallels, English-jargon metaphors
- **Essay / personal** — stance, sterile-room recovery, super-move coinages, distant voice
- **Business** — both-sides hedging, distant voice, adverb stacking, closing clichés

## Output format

When the user asks for a **review only** (no rewrite): produce a list of findings grouped by priority (Stance → False agency → Structural → Vocabulary → Symbols). For each finding: quote the offending span, name the pattern, suggest a fix. End with a 5-axis score.

When the user asks for a **rewrite**: produce the edited text. After the text, summarize the 3 most significant changes in one sentence each. Do not over-edit — preserve the author's wording wherever no AI pattern is present.

When the user asks for a **pre-draft check** (Mode A): refuse to write body text. Ask the three principle questions. Wait for answers.

## When to load each reference

- `references/structures.md` — load on Mode B or C activation. The structural patterns are the core of the skill.
- `references/phrases.md` — load when running the vocabulary watch.
- `references/examples.md` — load when the user asks "show me, don't tell me", or when a specific pattern is unclear and an example would settle it.
- `references/why.md` — load only on explicit request, or when patterns the skill doesn't catch keep appearing (so the author can derive their own rules as LLM style drifts).

## Acknowledgments

This skill synthesizes prior work:

- iKora128/stop-ai-slop-jp (MIT) — priority-order spine, 5-axis scoring, Japanese-native pattern observation
- m0370 (Zenn) "AI生成文からAIくささを取り除く" — academic-leaning patterns (-ing tacking-on, copula avoidance, hedge stacking)
- Wikipedia: Signs of AI writing — vocabulary watch foundations
- hardikpandya/stop-slop (MIT) — original English template
- blader/humanizer, matsuikentaro1/humanizer_academic — pattern catalogs
