# Why AI Writes This Way

Load this only when:
- The user asks "why does AI write like this?"
- Patterns the skill doesn't catch keep appearing — the author needs the underlying mechanism to derive their own rules as LLM style drifts

Knowing the cause helps you spot *new* patterns. Pattern lists alone go stale because model training and RLHF change every release.

## Three causes, in increasing depth

### 1. RLHF reward signal

After pre-training, LLMs are fine-tuned with human feedback (Reinforcement Learning from Human Feedback). Annotators rate pairs of responses; the model learns to produce the preferred kind.

In practice, annotators reward outputs that *look* helpful, structured, and authoritative — even when those qualities are surface-level. The model overfits to the appearance:

- **Bullet lists with bold headers** read as "organized"
- **Three-item parallels** read as "comprehensive"
- **Hedges** ("may", "could potentially") read as "calibrated"
- **Em dashes and complex punctuation** read as "thoughtful"
- **Closing summaries** read as "complete"
- **Adjective stacks** ("rich, multifaceted, nuanced") read as "well-considered"

None of these are wrong in human writing. They become AI-slop when the model deploys them by default, regardless of whether the content warrants them.

This is why removing surface patterns helps but isn't sufficient: the underlying behavior — *performing helpfulness* — generates new patterns the lists haven't caught yet.

### 2. Risk-averse safety training

A separate fine-tuning pass trains the model to avoid offense, controversy, and confident claims that might be wrong. The behaviors that result:

- **Both-sides hedging**: "There are valid arguments on multiple sides…"
- **Distant voice**: speaking about "many people" or "society" rather than as a specific person, because a specific person could be wrong
- **Refusal to commit to specifics**: vague attribution ("experts say") and specific failure avoidance
- **Closing with "time will tell"** instead of a prediction

The opinion-vacuum is structural, not stylistic. Even a model told to "have an opinion" tends to ladder back to safety. This is why "absence of the writer" is the deepest mark of AI-slop: it's not a writing tic, it's a trained reflex.

### 3. Statistical regression to corpus center

Pre-training reads the entire public web. The model's default prose style is the *mean* of that corpus — closer to corporate blog posts, content marketing, and entry-level explainers than to any specific human writer.

Effects:

- **Vocabulary convergence**: words common in SEO-optimized content ("delve", "tapestry", "leverage", "landscape", "pivotal") show up everywhere because they were over-represented in the training distribution
- **Rhythm uniformity**: paragraph length, sentence length, and section structure converge on blog-post norms — 3–5 sentence paragraphs, H2 every ~300 words, opening hook
- **Translation-ese in Japanese**: a large fraction of Japanese training data is translated from English (Wikipedia, MDN, technical docs), so the model's default Japanese inherits English syntactic patterns

The writer's job is to *not write like the corpus mean*. A real human's writing has eccentricities — a favorite punctuation tic, a particular cadence, a personal vocabulary — that the corpus mean lacks.

## How to use this knowledge

When you notice a pattern the skill's lists don't catch, trace it back:

1. **Is this RLHF performance?** ("Does this make me look organized / thoughtful / authoritative?") → cut
2. **Is this safety hedging?** ("Am I avoiding a position because being wrong would be bad?") → take the position
3. **Is this corpus-mean prose?** ("Could this sentence appear in any blog post on this topic?") → make it specific to your situation

This generalizes beyond the current pattern lists. As models update, the surface tics change, but the three underlying causes don't.

## Reading for more depth

- Wikipedia: [Signs of AI writing](https://en.wikipedia.org/wiki/Wikipedia:Signs_of_AI_writing) — the empirical pattern catalog from WikiProject AI Cleanup
- The [LLMの文体に関する実験 (Zenn, j_m)](https://zenn.dev/j_m/articles/dba4be5c018925) covers RLHF-induced style bias in Japanese
