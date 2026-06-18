# Structural AI-Writing Patterns

The structural problems that produce AI-slop. Load this when reviewing or editing a draft (Mode B or C).

## Table of contents

1. False agency
2. Proposition-style headings
3. Reversal intros
4. Three-item parallels
5. -ing tacking-on
6. Copula avoidance
7. Hedge stacking
8. Synonym recycling
9. Both-sides hedging
10. Distant voice
11. Vague attribution
12. Uniform rhythm
13. Closing template clichés
14. Section-leading summary sentences

---

## 1. False agency

Objects, abstractions, or systems performing verbs that require a human agent. The result is a writer who never appears in their own text.

**AI version**

- The data shows that engagement dropped.
- 文化が醸成されている。
- The architecture decides the API surface.
- お弁当が設計されていた。
- This research suggests three implications.
- 思想が結実している。

**Human version**

- I checked the dashboard; engagement dropped.
- 田中さんがこの慣習を社内に根づかせた。
- We chose this architecture, which forces a particular API surface.
- 母がお弁当に工夫を凝らしていた。
- I take three things away from this study.
- 田中さんは10年かけてこの考えにたどり着いた。

Test: ask "who actually did this?" If the answer is a person and the sentence hides them behind a noun, that is false agency.

---

## 2. Proposition-style headings

Headings that assert a claim ("X is Y") rather than name a topic. They turn every section into a mini-TED-talk, which is exhausting and reads as AI.

**AI version**

- "Refactoring Is an Act of Love"
- "The Real Power of TypeScript Lies in Inference"
- "AIエージェントは思考の鏡である"
- "なぜRailsは今も最強なのか"

**Human version**

- "Refactoring this week"
- "TypeScript inference, in practice"
- "AIエージェントを2ヶ月使った感想"
- "Rails 7.2を試した"

Headings should let readers skim. Claim headings force readers to evaluate the claim before reading.

---

## 3. Reversal intros

The "Most people think X. But actually Y." opening. It signals "I am about to say something contrarian" before saying anything.

**AI version**

> Most developers think microservices are the modern default. But the truth is, monoliths are making a comeback.

> 多くの人がAIで生産性が上がると思っている。しかし実際は違う。

**Human version**

> We moved back to a monolith last quarter.

> AIで自分の生産性は上がっていない。月の出力を測ってみた。

Drop the setup. State the position directly.

---

## 4. Three-item parallels

AI defaults to three items. Three reasons, three principles, three perspectives. When the underlying idea has two or four, the writer pads or trims to hit three.

**Symptom**

- "Three keys to good engineering"
- "3つの観点から考える"
- "There are three main reasons…"

**Fix**

Ask: does the underlying material actually have three parts, or is the writer hitting a rhythm? If the latter, collapse to two or expand to four. Better yet, drop the enumeration and write prose.

---

## 5. -ing tacking-on

Facts followed by a participial phrase that explains why the fact matters. AI cannot resist annotating its own evidence.

**AI version**

- The HR was 0.65, highlighting the importance of cardiac protection.
- We shipped on time, demonstrating the team's commitment to quality.
- HRは0.65でした。これは心保護効果の重要性を浮き彫りにしており、今後の治療戦略に大きな示唆を与えています。

**Human version**

- The HR was 0.65.
- We shipped on time.
- HRは0.65でした。

Let facts stand. Readers infer significance themselves. If the significance is genuinely non-obvious, state it as a separate sentence — do not staple it on with a participle.

---

## 6. Copula avoidance

AI hesitates to use "is" / "です" plainly. It reaches for "serves as", "stands as", "represents", "constitutes", "〜として位置づけられています", "〜の役割を果たしています".

**AI version**

- The function serves as a bridge between two layers.
- This pattern stands as a testament to good design.
- このツールは開発者向けのリファレンスとして位置づけられています。

**Human version**

- The function bridges two layers.
- This pattern is good design.
- このツールは開発者向けのリファレンスです。

Test: can the verb be replaced with "is" / "です" with no loss? Then replace it.

---

## 7. Hedge stacking

A single hedge is fine. Multiple stacked hedges are AI overcalibration.

**AI version**

- This may potentially be one of the more significant changes possible.
- It could possibly be argued that this is somewhat important.
- これは重要な可能性があるかもしれません。

**Human version**

- This is one of the bigger changes.
- This matters.
- これは重要です。 (or, if uncertain: これは重要かもしれません。)

One hedge, or none. Stacking signals AI fear of commitment.

---

## 8. Synonym recycling

Same referent renamed every two sentences to avoid repetition. The result is the reader losing track of what's being discussed.

**AI version**

> We use this tool for code review. The approach works well in our workflow. This method has saved us hours. The framework integrates with our CI.

(All four sentences refer to the same thing.)

**Human version**

> We use this tool for code review. It works well in our workflow. It has saved us hours, and integrates with our CI.

Pick one noun and reuse it. Repetition is fine.

---

## 9. Both-sides hedging

"There are upsides and downsides" with no side taken. Judgment is abdicated.

**AI version**

- This approach has its benefits and drawbacks. Both perspectives are valid.
- AはAで良い面があるし、Bにも長所があります。

**Human version**

- I prefer B. A's main draw is X, but in our case X doesn't matter.
- 私はBにしました。AはXの場合に向くが、うちはXじゃない。

Take a position. If you genuinely can't, cut the sentence.

---

## 10. Distant voice

Speaking from far away — "people in general", "society", "engineers" — to avoid taking a personal position.

**AI version**

- Many engineers struggle with this problem.
- In modern society, communication is increasingly digital.
- 多くの開発者がこの課題に直面しています。
- 現代社会において、コミュニケーションのあり方が変化しています。

**Human version**

- I struggle with this. So does my coworker Y.
- My team uses Slack for everything. Email is dead in this org.
- 自分はこの課題で先月二日溶かしました。
- うちのチームはSlackで全部済ませています。

Replace "people / society / engineers" with a specific person, team, or self.

---

## 11. Vague attribution

Citing without citing. "Experts say", "research shows", "専門家によると".

**AI version**

- Experts say this is the future.
- Studies have shown that X.
- 専門家によると、これは重要な転換点です。

**Human version**

- Andrej Karpathy called this "the future" in his Sep 2024 talk.
- A 2023 paper by Smith et al. found X (link).
- 名前のある専門家か、出典のURLを添える。

Cite specifically or cut the claim. Vague authority is worse than no authority.

---

## 12. Uniform rhythm

Paragraphs all 3–5 sentences. All sentences the same length. All endings the same form. The text feels machine-stamped.

**Symptom**

- Every paragraph ends with "〜なんだと感じました" or "〜ということが分かった".
- Every sentence is 25–40 words.
- Every section closes with a one-sentence takeaway.

**Fix**

- Throw in a one-line paragraph between two long ones
- End some sentences short. Some long.
- Mix だ / です / 体言止め in Japanese; mix declarative / questioning / fragments in English (sparingly)
- A section can end mid-thought, not always on a takeaway

---

## 13. Closing template clichés

Endings that signal "the article is over" via formula.

**AI version**

- It will be interesting to see how this develops.
- Only time will tell.
- The future of X is bright.
- 今後の展開が注目されます。
- 今後に期待です。
- 続報が待たれます。

**Human version**

Either:
- Stop. Let the last substantive sentence be the last sentence.
- Or end with a specific next action: "Next month I'll try Y."

Test: if the ending could be appended to any article on any topic, it's a template.

---

## 14. Section-leading summary sentences

The first sentence of each section restates what the section is about — content the heading already conveyed.

**AI version**

> ## Why TypeScript matters
>
> In this section, we'll explore why TypeScript matters for modern web development.

> ## なぜTypeScriptが重要か
>
> ここではTypeScriptがなぜ重要なのか、その理由を解説します。

**Human version**

> ## Why TypeScript matters
>
> The compiler caught a null-deref last week that would have shipped to prod.

> ## なぜTypeScriptが重要か
>
> 先週コンパイラがnull参照を捕まえた。これがJSなら本番に出ていた。

Delete the throat-clearing sentence. Start with the substance.
