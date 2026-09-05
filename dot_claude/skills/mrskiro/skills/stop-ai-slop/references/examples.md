# Before / After Examples

Concrete rewrites for each major pattern. Load when "show me, don't tell me" is what the user needs.

## Table of contents

1. False agency (Japanese)
2. False agency (English)
3. Proposition heading → noun heading
4. Reversal intro removed
5. Three-item parallel collapsed
6. -ing tacking-on removed
7. Copula restored
8. Hedge stack flattened
9. Synonym recycling fixed
10. Both-sides hedging committed
11. Distant voice grounded
12. Vague attribution made specific
13. Sterile-room recovery
14. Uniform rhythm broken
15. Closing cliché replaced

---

## 1. False agency (Japanese)

**Before**

> このアーキテクチャは、開発者の認知負荷を下げることを志向している。レイヤー分離という思想が、結果としてテスタビリティを担保している。

**After**

> このアーキテクチャを採用した理由は、開発者の認知負荷を下げたかったからです。レイヤー分離したことで、テストが書きやすくなりました。

What changed: the architecture stopped "intending" and "guaranteeing" things. The actual decision-maker (we / I) became visible.

---

## 2. False agency (English)

**Before**

> The system architecture ensures scalability while the codebase reflects a commitment to maintainability.

**After**

> We picked this architecture for scalability. We refactor aggressively, which keeps the code maintainable.

Same fix: name the agent.

---

## 3. Proposition heading → noun heading

**Before**

> ## TypeScriptの型推論は思考の補助線である

**After**

> ## TypeScriptの型推論、3ヶ月使った所感

Drop the claim. Name the topic. Let the body argue.

---

## 4. Reversal intro removed

**Before**

> 多くの開発者は、AIで生産性が劇的に上がると信じている。しかし実際には、そう単純な話ではない。AIの導入には、見落とされがちな3つの落とし穴がある。

**After**

> AIを業務に入れてから2ヶ月、自分の生産性はむしろ落ちました。理由を整理します。

The reversal "X think A, but really B" is the most AI-coded opening pattern. Drop it.

---

## 5. Three-item parallel collapsed

**Before**

> 良いコードレビューには3つの観点があります。1つ目は正確性、2つ目は可読性、3つ目は保守性です。

**After**

> 良いコードレビューで自分が見るのは、結局のところ「これ動くのか」と「半年後に読めるか」です。

Two is enough when two is true. Don't pad to three.

---

## 6. -ing tacking-on removed

**Before**

> 検証の結果、HRは0.65でした。これは心保護効果の重要性を浮き彫りにしており、今後の治療戦略に大きな示唆を与えています。

**After**

> 検証の結果、HRは0.65でした。

If the significance is genuinely non-obvious, write it as a separate full sentence with a real claim. Don't staple it on with a participle.

---

## 7. Copula restored

**Before**

> このツールは、開発者向けのリファレンスとして位置づけられています。

> The function serves as a bridge between the two layers.

**After**

> このツールは開発者向けのリファレンスです。

> The function bridges the two layers.

Test: does "is" / "です" work? Use it.

---

## 8. Hedge stack flattened

**Before**

> これは重要な変化である可能性があるかもしれません。

> This may potentially be one of the more significant developments possible in the field.

**After**

> これは重要な変化だと思います。

> This is one of the bigger developments in the field.

One hedge, or none.

---

## 9. Synonym recycling fixed

**Before**

> このツールを使ってコードレビューを行います。このアプローチは私たちのワークフローに馴染んでいます。この手法によって毎週数時間が節約されています。この仕組みはCIとも統合されています。

**After**

> このツールでコードレビューしています。ワークフローに馴染んでいて、毎週数時間助かっています。CIとも繋がっています。

Same noun is fine. Substituting "アプローチ" "手法" "仕組み" for "ツール" loses the reader.

---

## 10. Both-sides hedging committed

**Before**

> マイクロサービスにもモノリスにも、それぞれの良さがあります。状況に応じて選択することが重要です。

**After**

> うちは去年モノリスに戻しました。マイクロサービスは10人未満のチームでは負債になります。

Take a side. Name your case. If you can't, the sentence is dead weight.

---

## 11. Distant voice grounded

**Before**

> 多くのエンジニアは、レビュー文化の重要性を理解しつつも、実践に移すのが難しいと感じています。

**After**

> うちのチームは去年までレビューを形だけやっていて、自分が「全部LGTMで通すなら廃止しよう」と提案したところで議論が始まりました。

"Many engineers" → "my team". "Feel that X is difficult" → a specific moment.

---

## 12. Vague attribution made specific

**Before**

> 専門家によれば、これは重要な転換点とされています。

**After**

> Karpathyが2024年9月のtalkで「これは転換点だ」と言っていました ([リンク](https://example.com))。

Name and source, or cut the claim entirely.

---

## 13. Sterile-room recovery

A draft that passed all the pattern checks but still reads dead:

**Before (clean but voiceless)**

> 新しいツールを使ってみました。機能としては悪くなく、ワークフローにも合っていました。導入は比較的スムーズでした。今後も使い続ける予定です。

**After (voice restored)**

> 新しいツール、半信半疑で入れたんですが思ったより悪くなかったです。深夜にビルドが落ちてSlackが燃えたことが一度だけありましたが、それ以外は順調。少なくとも年内は使い続けます。

Specific failure ("深夜にビルドが落ちて"), specific timeframe ("年内"), and a stance ("少なくとも年内は").

---

## 14. Uniform rhythm broken

**Before (all paragraphs 3 sentences, all 25–35 chars)**

> 今週は新しいデプロイ手順を試しました。チーム全員で手順を確認しながら進めました。結果として大きなトラブルはありませんでした。
>
> 翌週は本番環境で実施することにしました。リハーサルでは見つからなかった問題が出ました。最終的には手作業で復旧することになりました。

**After (varied)**

> 今週は新しいデプロイ手順を試しました。チーム全員で確認しながら進めて、まあ無事でした。
>
> 翌週、本番で同じ手順をやったらRDSの設定が違いました。
>
> リハーサルでは見つからなかった種類のミスです。15分くらい手作業で復旧して終わり。教訓は「本番とstagingの差分を毎月診断する」だと思います。

One short paragraph in the middle, varied sentence lengths, a stance at the end.

---

## 15. Closing cliché replaced

**Before**

> 今後の展開が注目されます。

**After (option A — just stop)**

> 来月もう一度試してから記事にします。

**After (option B — let the last substantive sentence be the ending)**

> 結果として、自分のチームではPR数が週2本減りました。

The "future is bright" / "stay tuned" close is a template fingerprint. Cut it or replace with a specific next step.
