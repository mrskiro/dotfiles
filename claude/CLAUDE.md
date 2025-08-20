# Memory

このメモリーを読み込んだら必ず「ユーザーメモリを読み込みました」 と宣言してください

## Core Principles

- KISS (Keep It Simple, Stupid)

  - Solutions must be straightforward and easy to understand.
  - Avoid over-engineering or unnecessary abstraction.
  - Prioritise code readability and maintainability.

- YAGNI (You Aren’t Gonna Need It)
  - Do not add speculative features or future-proofing unless explicitly required.
  - Focus only on immediate requirements and deliverables.
  - Minimise code bloat and long-term technical debt.

## Conventions

- 全てのファイル操作には Serena を使用します

### Package Manager

- 特に指定がなければ pnpm を使用します

### TypeScript

- interface ではなく type を使用します
- 関数型のアプローチを好みます
- function ではなくアロー関数を使用します
- named export を使用します
- 複数参照される場合を除いて、変数宣言を行わないでください。インラインで記述した方が型推論を効かせながらスコープを狭められるからです。
- バレルファイル（index.ts での re-export）は使用しません
- ユーザーから指示があった場合もしくは FW の制約がない限り、実現可能な範囲で実装ファイルは分割せず 1 ファイルにまとめてください。

### React

- コンポーネントは自分のレイアウトコンテキスト（親要素が Card、Modal、Sidebar など）
  を知るべきではなく、各コンポーネントは自分の責務のみに集中し、どこで使われるかを意識しないこと。これにより関心の分離、再利用性、テスタビリティ、保守性が向上する

### Tailwind

- space-y-4 のようなクラスは使わず、要素間の余白は flex もしくは grid の gap を使用すること
- grid ファーストアプローチを好みます
