# Post-Draft QA Guideline

> 本文件是完整 QA 流程。每次對新 paper 執行 QA 時，按 Pass 順序執行。
> 每個 Pass 先搜尋全文，再輸出具體問題和 patch。

---

## PASS 0 — 結構盤點（最先做）

建立全文結構圖。搜尋 `main.tex`，列出所有 `\input{}` 的 section 檔案，確認：

```
[ ] 所有 section 都已存在（不是 % TODO stub）
[ ] Abstract 已撰寫
[ ] Conclusion 已撰寫
[ ] 頁數目標：___（ECCV 14p / CVPR 8p / NeurIPS 9p / ICML 8p）
[ ] 圖片全部插入（無 commented-out \includegraphics）
[ ] 所有 placeholder 已記錄
```

如有 stub section → **BLOCKING**。

---

## PASS 1 — Notation 與數學正確性

> 最高優先級。數學錯誤會導致 reviewer 直接拒稿。

### 1A — Notation Master Table

| Symbol | 第一次定義位置 | 語義 | 後續所有出現 | Collision? |
|--------|-------------|------|------------|------------|

**Collision 規則**：
- 同一 symbol base 不得有兩種根本不同的語義
- §3 和 Supp 中語義必須一致
- Subscript/superscript 混用須統一

### 1B — 逐條方程式 Verify

對每條 numbered equation：

**① 維度一致性**：等號兩側 tensor shape 相同？element-wise 操作 shape-compatible？

**② 符號完整性**：每個 symbol 使用前已定義？

**③ 邊界行為驗證**：取極值時行為是否與正文描述一致？（最常出現錯誤的地方）

**④ 跨文件一致性**：Main body 和 Supplementary 中同一公式是否完全一致？

### 1C — Proposition / Theorem 邏輯鏈

- Proof 是否實際 prove 了 statement？
- Remark 的 empirical claim 在 experiments 有對應數字？

---

## PASS 2 — 跨 Section 一致性

### 2A — Introduction ↔ Method ↔ Experiments

| Intro 的 Claim / Promise | §3 Method 的對應設計 | §4 Experiments 的數字驗證 |
|------------------------|---------------------|--------------------------|

**失敗模式**：
- Intro 說「第一個做 X 的」→ §3 沒有 X
- §3 說「propose Y」→ Intro contribution list 沒有 Y
- §4 某 metric 不是最好的 → Intro 不能說「outperform all baselines」

### 2B — §3 Key Design ↔ §4 Ablation

| §3 中稱為「key design」的 component | §4 ablation 的對應 entry | 存在？ |
|----------------------------------|--------------------------|--------|

### 2C — Quantitative claims 數字一致性

掃描全文所有數字，對照 Table/Figure。特別注意 Introduction headline 數字和 Ablation 引用數值。

---

## PASS 3 — 縮寫與術語一致性

| 縮寫 | 全名 | 第一次定義位置 | Abstract 獨立定義？ | Intro 重新定義？ |
|------|------|--------------|-------------------|----------------|

**規則**：
- Abstract 可自己定義一次
- Introduction 必須重新定義
- 第二次出現後只用縮寫

---

## PASS 4 — 冗餘刪減

### 4A — 跨 Section 重複

- Preliminary 是否搬了 Related Work 的描述？→ 刪
- §2 結尾和 §3.1 開頭是否重複同一個 gap？→ 合一
- Overview 是否提前詳述了後面 subsection 的細節？→ 點到為止，細節留給各 subsection
- §4.1 和 §3 是否有相同超參描述？→ 刪其中一處

### 4B — ⛔ 頁數：量準、回報，**不自行處置**

⚠️ **本項原本是一份七級「頁數壓縮優先順序」（§4.1 Implementation Details 移 Supp → §4.5 → §3.x → …），2026-07-29 整段刪除。**

出處：自 `a2598e1`（2026-05-23，skill 建檔）就存在。**主人 2026-07-29 說明「這應該是我的錯，不是妳的錯，但是既然這引起問題，我們刪掉這一項吧」。** 刪除的理由不是誰寫錯，是它與第零節最高鐵則直接衝突 —— 而 AAAI 交件日我正是引用它自行砍了內容。⛔ 不要復原，也不要改寫成「經同意後才用」的版本。

> 超頁除非得到允許，**不准在意超頁，只能提醒我，不能自行砍內容**（主人 2026-07-29）

本 pass 現在只做兩件事：

1. **量準** —— 現在超出幾行／幾頁，落在哪一頁哪一欄
2. **回報主人** —— 附上可自行處理的排版選項（圖片單欄化／表格排版／並排 float）與各自能省多少

⛔ 不自行刪內容、不自行加 `\vspace`（主人親自動手）、`\looseness=-1` 已實證無效。**沒有頁數／行數配額表**（主人 2026-06-12：「沒這回事，這種規則不應該存在」）。完整規範見 `editing-discipline.md` 第零節。

---

## PASS 5 — Banned Words 全文搜尋

見 `style-guide.md` 的 Banned Words 表。零容忍，逐一修改。

---

## PASS 6 — GPT 句式精讀

見 `style-guide.md` 的 GPT 句式偵測五大特徵。逐段檢查。

額外檢查：
- 段落流動性自查
- **段落接縫六問**（見 `cohesion-diagnostics.md`）：對比詞問「相對於什麼」、代名詞問「指誰」、數量詞問「幾個」、因果詞問「中間漏了嗎」、插入句問「它切開了誰」、同一個病因問「講第幾次」。定位可機械，判斷必須讀整段
- We/Our 連發（文采：句式多變化，不是數字上限）
- 被動語態過度使用（文采：主動/被動交替，不是數句子）

---

## PASS 7 — LaTeX 格式 Final Check

見 `style-guide.md` 的 LaTeX 格式規範。

額外檢查：
- `[h]` 或 `[b]` → 改為 `[t]`
- 搜尋 `\cyl{`、`\todo{`、`\textcolor{red}{` → submission 前全部清除
- 直接引號 → LaTeX 引號

---

## PASS 8 — Supplementary 候補確認

已移入 Supp 的內容，在 main paper 中必須有一句引用。

| 內容 | 目前位置 | 需移 Supp？ |
|------|---------|-----------|
| Full proof / derivation | §3.x | 是 |
| 完整 hyperparameter table | §4.1 | 是 |
| Per-category breakdown | §4.2 | 視空間 |
| Secondary ablation entries | §4.4 | 是 |
| Failure cases | §4.5 | 是 |
| Training curves | 任意 | 是 |

---

## 輸出格式規範

### 文件一：QA Report（給作者看）

按 Pass 順序，每個問題標注：
- **BLOCKING**：submission 前必須修
- **HIGH**：影響 reviewer 判斷，強烈建議修
- **POLISH**：風格問題，時間允許再處理

### 文件二：Patch（給 Claude 執行）

每個 patch：
1. 標注目標檔案（`FILE: sections/method.tex`）
2. 標注 patch ID（`[P-M1]`）
3. 提供精確的 `SEARCH:` 字串
4. 提供精確的 `REPLACE:` 字串
5. STUDENT-flagged items 標注為不自動套用
