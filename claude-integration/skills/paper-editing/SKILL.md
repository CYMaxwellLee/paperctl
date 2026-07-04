---
name: paper-editing
description: 論文改稿 skill。當教授要求修改 LaTeX 論文（patch、rewrite、\cyl 藍字、comment out 學生文、更新 section、補 appendix/附錄/supplementary）時觸發。包含所有改稿規則、Appendix 改寫鐵則、禁忌、Overleaf 推送流程。
triggers:
  - "改稿"
  - "patch"
  - "rewrite"
  - "\\cyl"
  - "藍字"
  - "comment out"
  - "更新.*section"
  - "更新.*introduction"
  - "更新.*method"
  - "更新.*experiment"
  - "修改.*tex"
  - "append"
  - "appendix"
  - "附錄"
  - "補充材料"
  - "supplementary"
---

# Paper Editing Skill

> 完整知識庫在 paperctl repo 的 `skills/` 目錄。
> 本 skill 是精簡版 + 指向完整版的 pointer。
> 安裝方式：`paperctl setup`

---

## 改稿前 Pre-flight（每次必做）

### 1. 確認 Edit Convention
```
Comment out + replace（預設）  → % 學生原文 + \cyl{教授新版}
Append（教授指定時）          → 學生文保留 + \cyl{} append 在後
Rebuttal side-by-side         → 學生文保留 + \cyl{\noindent ...} 緊接
```
**每篇可能不同。不確定就問教授。**

### 2. 確認範圍
- 哪個 section？哪些檔案？
- 有沒有 equation 要保留？
  - **正文 / Rebuttal**：已有 label 的 equation 用 `\cref{}` 引用，不重複 typeset（省版面）。
  - **Appendix 改寫**：藍字版**必須把每個 equation 重新 display**（見下方 Appendix 鐵則 D）。不可只 `\cref` 引用、更不可攤平成 inline。這條跟正文相反，別搞混。

---

## 寫作目標（教授 2026-07-05 定調；禁字仍由 lint 強制，但只是地板）

> 「那些所謂禁字只是我個人不喜歡的用法，不是說改 paper 要變成一個 regex 任務。
> 我希望寫的是 Professional 專業的 ML/RL/CV Papers，寫得像個頂級研究學者。」

**品質 = 論證 × 精確 × 語域。lint 只是地板；通過 lint ≠ 寫得好。**
總判準：這句話放進該領域的 best paper 正文，違和嗎？

### 三遍修訂（每段寫完照做，順序不可反）

1. **論證遍** — 逐句問「這句推進了什麼論證？」不推進就刪或併（刪句只適用自己剛寫
   的草稿；動學生或既有正文改為標記徵求同意）；claim 不超出證據；transition 反映
   真實邏輯關係（因果/遞進/對比），不是塞副詞；指涉對齊（The X / This 與前文實體
   的身分數量對得上 —— 立了兩個 gap 就寫 Both gaps）；跳太快的句子拆開，把中間
   推理步驟寫出來。
2. **語域遍** — 逐句四個審計：
   - **動詞審計**：口語動詞換精確學術動詞（makes→illustrates/demonstrates、
     lets→permits/allows、asks→requires、gets→obtains/incurs、sit→remain、
     pull forward→advance、gives way→collapses/is broken、comes down to→reduces to、
     has tried→has sought）。這是校準樣本不是黑名單 —— 表外的口語動詞一樣換；
     **不可 grep 替換**（right-hand side、`use` 作為 utilize 替代詞等場合不適用）。
     數學慣用語（Let $x$ denote / It follows that / holds / yields / admits）
     不是口語，保留。
   - **慣用語審計**：口語隱喻（a far lower bar / left on the table / low-hanging fruit）
     → 改字面精確（a substantially weaker condition / remains unexploited）。
     領域收編術語（bottleneck / pipeline / greedy / warm start）可用。
   - **術語審計**：一個概念一個名字全文鎖定（列出技術名詞，同物異名合併）；
     同義變化只用於論證動詞，不用於術語。
   - **重複詞審計**：同一句內或相鄰句不重複同一個非術語詞（教授 2026-07-04：
     「你這句話兩個 already」）。文采原則，無數字配額。
   - 快篩：整段唸出來，聽起來像日常對話的句子逐句修。
     2026-06-12 明示 OK 的用法不要「修」：It is worth noting that / As expected, /
     demonstrates the effectiveness of / has gained significant attention /
     Recently, many works / In this paper, we。
3. **機械遍** — 實際執行 `paperctl lint --paper <name>`（無 conference.json 就拿
   下方禁字清單 grep）。**必須真的跑、看輸出**，不准沒跑就宣稱「已檢查無違規」
   （2026-07-05 實測：模型自稱 verified 而違規就在最後一句；自我宣稱不可信）。

完整 doctrine：paperctl `skills/academic-paper-writing/modules/style-guide.md` §〇–§四
（含 2026-07-04 ACML ¶3 的 before/after 校準例）。

---

## Writing Bans（教授個人禁字，lint 機械強制 — 必要非充分；整篇適用——教授 2026-06-12：「general的精神必須共同整篇遵守，不應該歸納為只有 introduction 不該用」）

1. ❌ Em dash (`---` 或 `—`)
2. ❌ Adverb+comma opener（`Additionally,` `Notably,` `Crucially,` …）。例外允許：`Specifically,`，以及 `Moreover,` / `Furthermore,`（教授 2026-06-27 親口裁定允許）
3. ❌ "straightforward"
4. ❌ Semicolons joining clauses
5. ❌ Comma+V-ing（`..., producing X`）
6. ❌ `thereby` / `utilize` / `numerous`（教授 2026-06-12 同意）
7. ❌ `because`（整篇，不限句首）→ since / as / given that
8. ❌ casual：`but`、`so`、`give(s)`
9. ❌ 弱引用：`As shown in`、`As can be seen from`、括號式 `(Table 9)` → 表圖當主詞
10. ❌ 直引號 `"..."` → `` `` ``...'' ``（LaTeX，必須 enforce）
11. ❌ inline math 用 `\(...\)` → 一律 `$...$`（display math 哪裡都可以放）
12. ❌ float `[h]/[b]/[H]` → 一律 `[t]` 置頂，放在第一次 mention 的那一頁。**正文與 supplementary 都一樣**（2026-06-12：「always置頂，不管正文或者supp」；supp 模板與 supp-check 已同步改 `[t]`）
13. ❌ `Yet` 句首 → However / Nevertheless（2026-06-12 同意）
14. ❌ `underscore`（任何用法）→ highlight / demonstrate / emphasize（2026-06-12 同意）
15. ⚠️ 句中 `, yet` → **很不 prefer**（warn 級，2026-06-12：「不喜歡但偶爾就算了」）→ although / while

**注意**：`--` (en-dash) 用於 `accuracy--speed` → **保留不動**
**明確不禁**（2026-06-12 裁決，勿再加回）：「It is worth noting that」「As expected,」「demonstrates the effectiveness of」「has gained significant attention」「Recently, many works」「In this paper, we」；Intro 的 `\Delta/\tau` notation 與 figure ref 沒有限制（teaser 在 ¶3 必引）。
**文采原則 ≠ 數字配額**（2026-06-12）：However/We/leverage 不要過度重複是「多變化」的文采原則，不是「每段 N 句」「>2 次」這種數字禁令；同理沒有頁數配額、ablation 行數、proof 行數門檻。Contributions 個數「3–5 個端看情況」為教授 2026-06-12 裁決，重點講為什麼 significant、有什麼 impact 與 insight。

**強制檢查**：`paperctl lint --paper <name>` 自動掃 #1–#14 加括號式表圖引用 `(Table 9)`、句首 But/So（有 fail 會 exit 1 可當 gate；SAGA 類無 cleveref 論文自動跳過 bare-`\ref`；contributions 區塊的 `\item` 不會被 --intro 誤抓）。
**人工判斷**（lint 掃不了，靠自己）：小括號補充子句、自問自答/反問句、However/We/leverage 文采變化、慎用 empirical/principle、表圖「當主詞」的正向確認（appendix 由 `verify-appendix` 管）。

---

## 段落級改寫：para-pipeline（教授 2026-07-05 核可的多 agent 流程）

段落級（含）以上的改寫，用 paperctl 的 pipeline：Direction（主線模型抓方向）→
3× Sonnet 5 寫手（論證/防審/語域三 lens，各自自審）→ 1× Sonnet critic 攻擊 →
強模型 Judge 合成＋裁決（教授 rulings 為 binding，防翻案）→ 主線套稿、compile、
真跑 lint、**給教授過目後才推**。單句小修不開 pipeline，直接改。
用法與 args：`skills/academic-paper-writing/modules/drafting-pipeline.md`；
script：`claude-integration/workflows/para-pipeline.js`。

---

## 📐 Appendix 改寫鐵則（append 模式專用 — 違反就是反覆來回幾小時的那個坑）

> 觸發：補 appendix／附錄／supplementary。藍字版是**完整、獨立的教授版**，不是 note、不是 summary。
> 學生原文保留在上，藍字版 append 在下。`paperctl verify-appendix` 會逐條擋。

寫每個 subsection 的藍字版時逐條自檢：

- **A 不准 summarize**：藍字字數 **≥ 學生版**。是要擴寫、補論證、講 impact，不是濃縮。
- **B 段數對齊**：學生幾段，藍字就 **≥ 幾段**。不可把多段壓成一段。
- **C 元素全覆蓋**：學生版裡每個 equation／table／figure／數字，藍字版**全部都要出現**，一個都不能掉。
- **D 公式照 display**：學生的 displayed equation（`\begin{equation}` / `align`）在藍字裡**仍要 displayed**，不准攤平成 inline 或散文。含 display math 的藍字區塊用 `{\color{blue} ... }`，**不要**用 `\textcolor{blue}{}` 去包 display math（會壞）。
- **E 表圖當主詞**：`Table~\ref{} reports...`、`\Cref{fig:} shows...`。**不要**寫成括號式 `(Table 9)`，也**不要** `As shown in Table 9`。
- **F 開頭直接破題**：每節第一句要**接正文**（`\cref{sec:...}` 點出主題從哪來），或**以表圖／專有名詞當主詞**。**禁止** `This sweep...` / `This ablation...` / `These tables...` 這種假設讀者已知 context 的 narrative 開頭。要 argument，不要 narrative。
- **G 不准 casual**：`so` / `but` / `give(s)` / `As shown in` / `As can be seen from` 一律不用。
- **I 引用資料不算禁忌**：失敗描述等 `\textit{``...''}` 逐字引用內的 but／分號／破折號是**資料**，不是你的文字，不要被它觸發禁忌（也不要去改它）。
- **N append 慣例**：學生原文**保留不動**，藍字是完整教授版 append 在後。

**🚫 禁止把 appendix 改寫外包給 editing subagent** — subagent 不遵守上述鐵則。在主執行緒自己寫。
**✅ 推之前一定跑 `paperctl verify-appendix --paper <name>`，全綠才推**（summarize／掉表圖／攤平公式／narrative 開頭都會被擋）。

> 為什麼要特別寫這條：memory 的 `editing_discipline`（最小修改）和 `edit_convention` 的「不要重複 equation」是**正文/rebuttal** 的規則，套到 appendix 改寫會變成「叫你濃縮、叫你別重抄公式」的反向指令。Appendix 改寫**以本鐵則為準**。

---

## 改稿紀律

1. **只做教授說的，不多做**
2. **不要碰 system setup**（`\usepackage`、`\bibliographystyle`、preamble）
3. **`\emph{}` 有底線** → 改 `\textit{}`，不是移除 emphasis
4. **不要 find-all replace** → 先確認範圍
5. **不要跨 repo 改** → 教授指定 A 篇就只改 A 篇

---

## 改完必做（最重要）

**先做完三遍修訂（論證 → 語域 → lint，見「寫作目標」節），再進推送流程。**

```bash
# Compile
/Library/TeX/texbin/pdflatex -interaction=nonstopmode main.tex

# Appendix 改寫的話：推之前一定要過結構驗證（全綠才推）
paperctl verify-appendix --paper <name>   # summarize / 掉表圖 / 攤平公式 / narrative 開頭都會擋

# Push GitHub（push 已內建 gate；--force 可略過驗證）
git add <files> && git commit -m "..." && git push origin main

# Push Overleaf（不可省略）
git pull overleaf master --no-rebase --no-edit
git push overleaf main:master
```

> 認證一次永久免密：新機器跑 `paperctl auth`（或 `paperctl start` 會自動跑）。

---

## 完整 Reference

找到 paperctl 安裝位置後，讀以下檔案：

| 主題 | 相對路徑（from paperctl repo root） |
|------|---------|
| 寫作規範 + Banned words 完整表 | `skills/academic-paper-writing/modules/style-guide.md` |
| 改稿紀律 + 3 種 convention 細節 | `skills/academic-paper-writing/modules/editing-discipline.md` |
| Overleaf 推送 + merge 檢查 | `skills/conference-ops/modules/overleaf-git-patterns.md` |
| 各會議格式速查 | `skills/conference-ops/modules/venue-reference.md` |
| QA checklist | `skills/academic-paper-writing/modules/qa-checklist.md` |
| Rebuttal 規範 | `skills/rebuttal/SKILL.md` |
| Skills 總索引 | `skills/README.md` |
