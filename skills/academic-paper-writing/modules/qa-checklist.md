# Post-Draft QA Checklist（精簡版）

> 適用階段：所有主要 section 初稿完成後。
> 建議順序：Pass 0 → 1A → 1B → 3 → 5A → 2 → 4 → 1C/1D → 5B–5E → 6

> ⚠️ **本 checklist 是「正文」的頁數/冗餘 QA**：PASS 2「細節移 Supp」、PASS 4「table 移 Supp」是把內容**搬進** appendix。
> 所以**寫 appendix/supplementary 本身時，不要套用這套壓縮邏輯**——appendix 藍字版要完整、覆蓋每個式/表/圖/數字、≥ 學生長度（見 memory `appendix_rules.md`，`paperctl verify-appendix` 會擋）。

---

## 完整 Checklist

```
PASS 0 — 頁數確認
[ ] 目前頁數：___    超出：___ 頁    目標削減：___ 頁

PASS 1 — 一致性 + 數學
[ ] Notation Master Table 已建立，無 collision
[ ] 所有 numbered equations 維度一致性已驗證
[ ] 所有 symbols 在使用前已定義
[ ] Intro ↔ Body 一致性 table 已填寫，無 undelivered promise
[ ] §3 ↔ §4 ablation 覆蓋 table 已填寫

PASS 2 — 冗餘刪減
[ ] §2 無 Related Work 寫法段落
[ ] §3 Overview 無提前洩漏各 subsection 細節
[ ] §4.1 已壓縮，細節移 Supp
[ ] §4.2 無「數字搬運」段落（每段有 insight）
[ ] §4.4 ablation 不超過 10 行

PASS 3 — 縮寫
[ ] 縮寫首次定義表已建立
[ ] 無重複定義（Abstract 例外）
[ ] Abstract 的縮寫在 Introduction 中重新定義

PASS 4 — Supp 候補
[ ] 所有 full proofs 已移 Supp（main 有引用）
[ ] Hyperparameter table 已移 Supp
[ ] 所有移入 Supp 的內容在 main 有 "see supplementary" 句

PASS 5 — GPT 語法
[ ] Banned words 全文搜尋完成（以 paperctl lint 清單為準）
[ ] Comma + V-ing 全文清除
[ ] We/Our 連發已打散
[ ] "As shown in / As can be seen from" 弱引用已改寫（表圖當主詞）
[ ] 段落內句子邏輯流動性已 check

PASS 6 — LaTeX 格式
[ ] 全文無 \ref{} 直接引用（改用 \cref{}）
[ ] 句首 \Cref 已全部修正
[ ] 所有 figure/table 浮動位置為 [t]
[ ] 引號格式正確
[ ] 所有 review-phase 臨時標記已整理
```

---

## 時間緊張時的最低限度（4 項）

只做以下四項：

1. **Pass 1B**：方程式邊界行為驗證（找 limit behavior 是否與 prose 相反）
2. **Pass 2A**：Intro promise vs Experiments 數字對齊
3. **Pass 5A**：Banned words 全文搜尋（10 分鐘）
4. **Pass 4B**：頁數壓縮優先順序（只做前三項）

---

## 操作建議：單人 review 順序

1. **Pass 0**：確認頁數缺口
2. **Pass 1A + 1B**：建 notation table + 數學驗證（最費時，最重要）
3. **Pass 3**：快速，做完可立刻改
4. **Pass 5A**：全文搜尋 banned words
5. **Pass 2**：逐 section 審查冗餘
6. **Pass 4**：確認 Supp 候補 + 補引用句
7. **Pass 1C + 1D**：填 consistency table
8. **Pass 5B–5E + Pass 6**：最後 line-level polish
