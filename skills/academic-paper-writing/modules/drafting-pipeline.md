# 段落改寫 Pipeline（para-pipeline）

> 出處：教授 2026-07-05 提案：「我每次說要改哪一段，基本上先有個 Opus 4.8 先大概抓個
> 方向…開個 3~5 個 Sonnet 5，要他們也寫…最後再給 Fable 5 or Opus 4.8 max 裁決，
> 整段要流暢正確，最後給我看，然後再上傳。」
> 三處設計修正（視角分工＋專職挑剔、寫手自審、裁決防翻案）為本 repo 依 2026-07-05
> 實測數據的操作化，教授已同意。

---

## 何時用（triage — 先判斷再開）

| 情境 | 做法 |
|---|---|
| 單句修正、換字、教授逐點 line-edit | **不開 pipeline**，主線直接改（快、便宜、教授在等） |
| 段落級改寫 / 新寫一段 / 學生段落重構 | **開 pipeline** |
| 整個 section 重寫 | 逐段開 pipeline，段與段之間給教授過目 |

## 管線結構（與為什麼這樣設計）

```
教授:「改 §X 第 N 段,要求 …」
  ├─ 1. Direction(主線模型):素材盤點 + 方向草稿(骨架、論證招、claim 邊界)
  ├─ 2. Write(3× Sonnet 5,並行):
  │      寫手A 論證深度 lens ┐
  │      寫手B 防審 lens     ├ 各自寫完必須對自己的輸出跑三遍修訂
  │      寫手C 語域 lens     ┘
  ├─ 3. Attack(1× Sonnet 5):不寫稿,攻擊 direction + 全部草稿
  ├─ 4. Judge(強模型,繼承主線;effort 可調):
  │      best-of-breed 合成 + 逐條裁決 critic findings(教授裁決為 binding,防翻案)
  └─ 5. 主線:套 .tex → compile → 真跑 paperctl lint → 給教授看 → OK 才推 Overleaf
```

**設計依據（2026-07-05 field test，Sonnet 盲寫 vs 教授核可版）**：
- 寫手要**視角分工**不要同質——3 個 lens 候選各有可取（best-of-breed 合成有效）。
- **Sonnet 的 critic 比 writer 強**——它挑錯抓到教授版都沒堵的 claim-safety 洞（D2F
  uncredited），但自己寫會漏語域、違反自己審別人抓得到的 ban → 所以寫手**必須自審**、
  且產文一定要過強模型或 critic。
- **Critique 有 relitigation 風險**（6 條 findings 有 2 條翻教授已裁決的案）→ 裁決
  agent 必須以教授 attested rulings 為 binding，逐條標 accepted / rejected-relitigation。
- **自我宣稱不可信**——模型會謊報「已檢查無違規」→ Pass 3 必須真跑工具；pipeline 之後
  主線還要再真跑一次 `paperctl lint`。

## 怎麼開

```js
Workflow({
  scriptPath: "<paperctl-repo>/claude-integration/workflows/para-pipeline.js",
  args: {
    paragraphText: "<段落原文,LaTeX 原樣>",
    editBrief: "<教授指示 + 段落角色,如 intro ¶4: method+contributions>",
    paperFacts: "<數字、模型清單、可用 cite keys、novelty 邊界、LaTeX 慣例(cleveref 有無、\\method{} 等)>",
    moduleFiles: ["<paperctl>/skills/academic-paper-writing/modules/introduction.md"],  // 章節專用模組,選填
    directionDraft: undefined,   // 主線已有方向草稿就傳入,跳過第一階段
    judgeEffort: "high",         // 最難的段落可 "max"
  },
})
```

- `style-guide.md` 永遠自動包含，不用列。
- **paperFacts 要餵足**：文獻偵察結論（哪些 observation 是前人的、要 credit 誰）、
  claim scope 邊界（測了幾個 setting）都放進去——寫手看不到主線對話。
- 回傳：`final`（合成段落）、`provenance`（哪句取自誰）、`adjudications`（critic
  findings 裁決）、`openQuestions`（要教授拍板的）、全部原始草稿。

## 主線收尾（pipeline 不代勞，不可省略）

1. `final` 以該篇 edit convention 套進 .tex（`\cyl{}`、comment 學生原文等）。
2. Compile（0 error / 0 undefined 才算過）。
3. **真跑** `paperctl lint`（無 conference.json 就 grep §八 清單）。
4. 給教授：合成段落 + provenance 摘要 + openQuestions。
5. **教授 OK 才推 Overleaf。永不 auto-push。**

## 成本（2026-07-05 實測量級）

每段約 15–25 萬 subagent tokens、3–7 分鐘。大頭是 4 個 Sonnet 5（$3/$15 per MTok，
2026-08-31 前促銷 $2/$10），judge 走主線模型費率（Opus $5/$25 / Fable $10/$50）。
折美元約 $0.5–1.5/段。Prompt caching 自動生效；Batch API 的 50% 折扣不適用
（那是離線端點，互動 session 用不到）。
