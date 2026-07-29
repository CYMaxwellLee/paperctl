# Experimental Results 寫作模組

> 繼承 `style-guide.md` 的所有規範。本模組專注於 §4 Experiments。

> ⚠️ **適用範圍：正文 §4。** 本模組的「不重抄 Table 數字、insight 先於數字」是**寫作原則**（文字要講 insight，不是把 Table 抄成句子），⛔ **不是「頁數不夠所以要壓縮」** —— 超頁的處置見本檔最後一節。
> **Appendix / Supplementary 的改寫相反**：藍字版是完整獨立版，要**覆蓋每個 table/figure/數字、≥ 學生長度、不可壓縮**。
> 補 appendix 時以 paper-editing skill 的「Appendix 改寫鐵則」為準，`paperctl verify-appendix` 會擋掉「只 highlight 少數數字」這種正文寫法。

---

## 核心精神：Experiments 不是報數字，是結辯

Experiments section 的角色是**結辯**：Introduction 提出了 claims，Methodology 給出了設計，Experiments 要用嚴謹的證據證明「前面說的都是對的」。

Reviewer 自己會看 Table 裡的數字。**你的文字要做的事是：告訴 reviewer 從這些數字中應該讀出什麼 insight，而不是把數字從 Table 抄到句子裡。**

**⚠️ 報數字邏輯（必須避免）的典型症狀**：
- 「Our method achieves 73.2% mAP on Dataset A, 81.5% Acc on Dataset B, outperforming all baselines.」→ 資訊量為零
- 「Compared to Baseline X, we improve by +3.1% on Metric A and +2.7% on Metric B.」→ 同樣零資訊量

**✅ 正確的寫法是講 insight**：
- 數字差異背後的**原因**是什麼？
- 哪個 improvement 最能支持 Introduction ¶3 的 insight？
- 最接近的 competitor 跟我們的差距對應我們方法的哪個 design choice？
- 在什麼條件下優勢最明顯？為什麼？

---

## §4 結構

```
§4.1  Experimental Setups
§4.2  Quantitative Results
§4.3  Qualitative Results
§4.4  Ablation Studies
§4.5  [可選] 額外分析
```

---

### §4.1 — Experimental Setups

讓 reviewer 快速理解實驗的 scope 和 fairness。以散文寫成。

**包含**：
- **Benchmarks / Datasets**：每個附簡短 characterization + 為什麼選它（必須跟 intro claims 呼應）
- **Metrics**：每個簡要說明（標準 metrics 不需公式）
- **Baselines**：必須包含最新 SOTA（2024-2025），簡述選擇邏輯
- **Implementation Details**：只寫最重要的，複雜設定放 Supplementary

---

### §4.2 — Quantitative Results

**每段的寫法模式**：
1. 引用 Table → 開頭先給 high-level takeaway（不只說 "outperforms all"）
2. 最重要的 insight：為什麼贏？對應 Methodology 的哪個設計？
3. 最接近的 competitor 分析：差多少？差在哪？為什麼？
4. [可選] 邊界條件觀察：差距特別大/小的情況

**Insight-first 寫法（正確）**：
```
The consistent advantage over [closest competitor], which also uses
[similar component], validates the effectiveness of [our specific
design choice]. The gap is particularly pronounced on [hard subset],
where [the challenge ¶1 described] is most severe.
```

**報數字邏輯（錯誤）**：
```
Our method achieves XX.X% on Metric A, YY.Y% on Metric B, surpassing
all compared methods.
```


---

### §4.3 — Qualitative Results

- **按 capability / challenge 組織，不是按 sample 組織**
- 每個例子展示一個特定的 capability 或 advantage
- **必須包含 failure case 分析**
- Qualitative improvement 應 trace back 到 Methodology 的某個 module

**Figure 要求**：
- Caption self-contained
- 用視覺標注（箭頭、框、zoom-in）引導差異
- 正文不描述 figure layout


---

### §4.4 — Ablation Studies

**功能**：回答「**為什麼好**」和「**每個設計 choice 的 contribution 是什麼**」。

**⚠️ Ablation 的邏輯必須跟 Methodology / Introduction 的 narrative 一致。**

**三個層次（由淺到深）**：
1. **Component Ablation**（最基本）：逐個移除/替換 module。必須有。
2. **Design Choice Ablation**（中等）：比較同功能的不同實現方式。
3. **Analysis Ablation**（最高）：揭示方法的行為特性。

**一篇好的 ablation 至少要有 Level 1 + Level 2。**（行數沒有上限規定——教授 2026-06-12）

**Insight-first 寫法（正確）**：
```
Replacing [Module X] with a standard [alternative] reduces performance
by -A.A%, confirming that [the specific capability from Proposition 1
in §3.2] is essential for handling [the challenge in ¶1].
```

**與 Methodology 的對應**：
- §3 的每個 module 至少要有一個 ablation entry
- §3.2 的每個理論 claim 至少要有一個 ablation result 作為 empirical validation

---

### §4.5 — [可選] 額外分析

| 分析類型 | 適用情境 |
|----------|---------|
| **Efficiency Analysis** | 方法有 efficiency claim |
| **Generalization / Cross-Dataset** | 方法 claim 泛化能力 |
| **Scaling Analysis** | 方法有 scalability claim |
| **Failure Case Analysis** | 所有論文都建議 |
| **Sensitivity Analysis** | 方法有 key hyperparameters |

寧可做精一個，不要蜻蜓點水做三個。

---

## §4 特有的額外規則

| 規則 | 說明 |
|------|------|
| **不在正文重抄 Table 數字** | 只 highlight 最關鍵的 1-2 個，其餘讓 reviewer 看 Table |
| **每段 insight 先於數字** | ❌ 先報數字再解釋 ✅ 先講 insight，再用數字佐證 |
| **Table 引用不要太機械** | ❌ 每段開頭 "As shown in Table X, ..." ✅ 自然嵌入句子 |
| **不在正文描述 Table layout** | ❌ "The first column shows..." ✅ 直接講 insight |
| **Ablation 的每個 entry 必須有意義** | 不要為了湊數加 trivial ablation |
| **不過度使用 "significant" / "substantial"** | 用數字取代形容詞 |

---

## 與前文的一致性檢查

### Introduction ↔ Experiments

| Intro 位置 | Claim | §4 Landing Point |
|-----------|-------|-------------------|
| ¶1, Challenge 1 | [描述] | §4.2 的 [哪個 result] + §4.3 的 [哪個 example] |
| ¶3, Insight | [描述] | §4.4 的 [哪個 ablation] |
| ¶4, Contribution | [描述] | §4.2 或 §4.4 的 [哪個 entry] |
| ¶4, Key result | [數字] | §4.2 Table 中的 [確切位置] — 數字必須一致 |

### Methodology ↔ Experiments

| §3 位置 | Design / Theory | §4 Landing Point |
|---------|----------------|-------------------|
| §3.2 Proposition 1 | [描述] | §4.4 ablation [哪一行] |
| §3.4 Module X | [描述] | §4.4 component ablation [哪一行] |

**如果有 claim 找不到 landing point → 補實驗或改 Introduction。**

---

## 超頁時的處置 ⛔ 先讀 `editing-discipline.md` 的「零、最高鐵則：不精簡內容」

> **沒有頁數配額表**（主人 2026-06-12：「沒這回事，這種規則不應該存在」）。篇幅由內容與會議頁限決定。

⛔ **超頁不是 Rei 要自己解決的問題**（主人 2026-07-29 明令）：

> 超頁除非得到允許，**不准在意超頁，只能提醒我，不能自行砍內容**

職責只有三件：**量準 → 回報主人 → 只做可自行處理的排版**（圖片單欄化／表格排版／並排 float）。`\vspace` 主人親自動手，`\looseness=-1` 已實證無效，刪減內容需「犧牲分析」＋明確同意。全部見 `editing-discipline.md` 第零節。

### ❌ 已刪除：原本的「壓縮優先順序」清單（主人裁定為幻覺）

本節原本寫著「壓縮優先順序：Implementation Details > 額外分析 > 部分 ablation entries > Qualitative」。
**主人 2026-07-29：「先砍 implementation results 一定是幻覺，刪掉」**，隨後補充「這應該是我的錯，不是妳的錯，但是既然這引起問題，我們刪掉這一項吧」。

出處：自 `a2598e1`（2026-05-23，skill 建檔）就在檔案裡。**刪除的理由是它與 `editing-discipline.md` 第零節直接衝突**，不是誰寫錯 —— 它正是 AAAI 交件日讓我自行砍內容的依據。

⛔ **不要復原，也不要改寫成「經主人同意後才拿來用」的版本** —— 那等於把幻覺留在檔案裡，下次仍會被當成合法清單引用。（我 2026-07-29 第一次改這節時就是這樣寫的，當場被主人抓掉。）
