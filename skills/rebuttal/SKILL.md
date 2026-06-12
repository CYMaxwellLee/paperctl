# Conference Rebuttal Skill

> **作者**: Prof. Chun-Yi Lee (NTU CSIE)
> **版本**: v1.0
> **適用場景**: ICML / NeurIPS / ECCV / CVPR / ICCV 等頂會的 rebuttal（author response）

---

## Skill 總覽

這是一套完整的學術會議 rebuttal 寫作系統。涵蓋從分析 reviewer comments 到撰寫回覆的每一個步驟，繼承 `academic-paper-writing` skill 的寫作哲學和 style 規範。

### 模組結構

| 模組 | 檔案 | 功能 |
|------|------|------|
| **Strategy** | `modules/strategy.md` | 分析 reviewer 意圖、排定優先順序、制定回覆策略 |
| **Response Writing** | `modules/response-writing.md` | 逐條回覆的寫作規範、句式模板、tone 指南 |
| **Style Guide** | `modules/style-guide.md` | Rebuttal 專用的格式和寫作禁止項 |
| **Checklist** | `modules/checklist.md` | 提交前最終確認清單 |

### 使用流程

1. 收到 reviews 後，先讀 `modules/strategy.md` → 產出 **Review Analysis Report**
2. 按 strategy 排定的優先順序，讀 `modules/response-writing.md` → 逐條撰寫回覆
3. 寫完後讀 `modules/checklist.md` → 做最終確認
4. 提交前讀 `modules/style-guide.md` → 做語言 polish

### 平台差異

| 平台 | 字數/頁數限制 | 格式 | 特殊注意 |
|------|---------|------|---------|
| **OpenReview** (ICML/NeurIPS/ICLR) | 無限制 | Markdown | 可以寫長。但不要灌水 |
| **OpenReview + PDF** (ECCV 2026 起) | 1 頁 PDF（含 references，two-column） | LaTeX (官方 template) | 必須極度精簡。匿名要求嚴格，禁止 external link |
| **CMT** (CVPR/ICCV 多數年份) | 通常 5000 字元 | Plain text | 必須嚴格精簡。確認當年規則 |

**注意**：每一年每個會議的規則都要重新確認，不要直接套舊規則。ECCV 2026 從 CMT 改成 OpenReview + 1 頁 PDF，與舊年份不同。

### 核心原則

1. **Reviewer 的每一個 concern 都值得認真回應**。即使你認為 reviewer 理解錯了，也要先承認他的觀察是合理的，再引導到正確的理解。
2. **Evidence > Argument**。用數據、圖表、實驗結果說話，不要只用文字辯論。
3. **不要對抗，要合作**。Rebuttal 的目標不是「贏」reviewer，而是讓他覺得「作者認真聽了我的意見，問題已經解決了」。
4. **優先序分兩層**：
   - **跨論文（paper-level）**：**高分 paper 先改**（守成優先）。avg ≥ 4 且有 champion（≥ 5 分）的 paper 勝算大、推一下就上，**最高優先**。極低分 paper（avg < 2.5、min=1）即使想救改分機率低，**不過度投入**，務實認知。學生實驗未到位的 paper 不勉強排前面。
   - **單篇內（reviewer-level）**：**低分 reviewer 先回**，給最多篇幅、最充分的 evidence。低分 reviewer 是該篇翻盤關鍵，但篇幅和 evidence 投入要對應該篇 paper-level 優先序。
5. **絕不道歉、絕不認錯**。這是最高原則（見 `modules/response-writing.md` 第 0 節、`modules/style-guide.md` 第 0 節）。即使是 reviewer 提出合理的 concern，也用 evidence 推回或重新框架（reframe），不寫 "we acknowledge this weakness"、"we admit"、"we apologize"。Reviewer 尊重的是 evidence 和論證，不是 self-deprecation。學生稿最容易出現認錯語，必須全部替換。
6. **跨 repo 範圍紀律 — 教授指定 A 篇就只改 A 篇**。當教授說「把前面改過的這麼多篇學到的東西 都拿來改現在這篇」這類指令時，動作目標是**目前這篇**，不是把同樣的修正自動 propagate 到 sibling rebuttal repos。實際發生過的錯：教授要求改 pnr-fungraph，我順手把同樣的 lesson（Figure→Fig.、because→since、adverb-comma 開頭、`thank ... for the question on X` 句型）commit 到 fplia / fadir / viewground3D / ewm 4 個 repo 並準備 push 到 4 個 Overleaf remote，被罵「你幹嘛更新其他5 repos 你瘋了嗎」「其他篇你都不應該動」「我是叫你看其他篇的學到的經驗來更新 pnr 你去動其他篇幹嘛」。**操作規則**：
   - 跨 repo grep audit 找 pattern 是 OK 的，**只是 information gathering**。
   - Edit + commit + push 只能對教授當下指令的那一篇執行。
   - 其他篇即使有同樣違規，最多浮現「我注意到 X、Y 篇也有同樣問題，要我下一輪處理嗎？」**等明確 per-repo 授權**才動。
   - 「lesson 適用於其他篇」不等於「授權我去改其他篇」。

7. **Rebuttal 是 sales pitch，不是中性學術文件**。核心目的：**說服 reviewer，讓他們知道我們厲害**。這影響幾個操作層面：
   - **銷售詞保留**：consistently / marginal / optimal balance / excellent / seamless / further validating / plug-and-play 都不在 banned list，rebuttal 該用就用。Paper 寫作的精簡/中性原則**不能直接套**到 rebuttal。
   - **Reviewer 健忘假設**：每段要 self-contained，重講 context、claim、results — 不要假設 reviewer 還記得 paper 細節。
   - **Supp/appendix evidence 早提**：第一句就用「as already detailed/reported in Sec. X / Tab. Y of the supplementary material」訊號「我們本來就有」。
   - **滿頁正好**：ECCV 1 頁正好填滿是合適長度，不要為精簡砍掉解釋或 evidence。
   - **改學生稿用最小動作**：只改違反紅線（認錯語、空洞承諾、真 banned words、分號），其他保留學生語氣。
   - **Banned words 以 paper style-guide 現行版為準**（2026-06-12 裁決後）：仍禁 thereby、utilize、numerous、underscore（任何用法）、"Notably," (句首)、"As can be seen from"、"As shown in"、Yet（句首）、because（整篇）、but/so/give。**不禁**："It is worth noting that"、"As expected,"、"demonstrates the effectiveness of"（教授明示 OK，勿再加回）。
