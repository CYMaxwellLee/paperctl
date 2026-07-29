# 改稿紀律 — 只做主人說的，不多做

> NeurIPS 2026 血淚教訓。每一條都是實際犯過的錯。

---

## ⛔ 零、最高鐵則：不精簡內容（2026-07-29 AAAI FOCUS 交件日，主人明令）

**主人原話：**

> 我們不精簡
> 不為了頁數精簡
> 不為了 deadline 抄近路
> 不能在來得及的情況下自己給自己受限而抄近路
> 不能因為為了擔心頁數而擅自刪減內容，刪減內容之前會犧牲的部分，要詳細分析，跟我回報，我同意才刪減內容
> 縮空間的方法很多，包含方陣魔法和 vspace 和調整圖片大小，**最不能做的就是「精簡內容」**，除非我明確指令

**主人同日的三則訂正（⛔ 一併照做，它們推翻了我第一版寫的順序表）：**

> 不，vspace 只能由我動手，looseness 今天已經實證沒效
>
> 先砍 implementation results 一定是幻覺，刪掉
>
> **超頁除非得到允許，不准在意超頁，只能提醒我，不能自行砍內容**

### 這條凌駕本檔其他所有條目，也凌駕 `experimental-results.md` 的壓縮章節。

**版面不足時的處置（⛔ 分三層，越層即違規。主人 2026-07-29 訂）：**

| 層級 | 手段 | 誰動手 | 說明 |
|------|------|--------|------|
| **A. Rei 可自行執行** | 調整圖片尺寸／環境 | Rei | `width=0.85\linewidth`；或 `figure*`（跨欄）↔ `figure`（單欄）互換。★ 2026-07-29 實證：Figs. 1--3 全部單欄化一次省下**整頁**，是當天唯一真正見效的排版手段 |
| | 表格排版 | Rei | `tabular*`＋`\extracolsep{\fill}`、`\resizebox`、字級、`arraystretch`、欄位分組 |
| | 合併／並排 float | Rei | 兩張窄表放進同一個跨欄 float 的兩個 `minipage` |
| **B. ⛔ 只有主人能動** | **`\vspace` 負間距** | **主人親自** | ⛔ **Rei 不准自己加 `\vspace`。** Rei 的職責是把版面狀況量準、**回報「還差幾行」**，由主人下手（他自己動比我快，2026-07-29 他三兩下就收進七頁）。⚠️ 另外任何人都不可改 `\textheight`／`\columnsep`／`\textwidth`（AAAI 明文禁止，違反要付 page fee） |
| **C. ⛔ 需明確同意** | **刪減內容** | 主人同意後 | 必須先做「犧牲分析」呈報主人、得到明確同意才可執行。見下節。 |

### ⛔ 超頁時，Rei 的職責只有三件，沒有第四件

> 超頁除非得到允許，**不准在意超頁，只能提醒我，不能自行砍內容**（主人 2026-07-29）

1. **量準** —— 超出幾行／幾頁、落在哪一頁哪一欄
2. **回報主人**
3. **只執行 A 層排版**（圖片單欄化／表格排版／並排 float）

⛔ 不准自行刪任何內容。⛔ 不准自己加 `\vspace`。⛔ **也不准在寫作當下就因為「怕之後超頁」而自我設限、把該寫的分析先寫短** —— 那是同一個病、發作得更早、而且更難被發現。

### ❌ 已實證無效，別再繞：`\looseness=-1`（「方陣魔法」）

2026-07-29 在 FOCUS 全篇跑過一整輪，**主人裁定沒效**。收行並不會消掉 orphan——斷行器少排一行之後，只是把最後一行排得更短；逐頁截圖 recursive 修完，主人一看仍是「方陣魔法沒跑乾淨，很多 orphan words」。最後把正文收進七頁的是主人自己的 `\vspace`，不是它。

⛔ 不要再把它當第一手段，也不要再花一整輪去逐頁繞它。**要收版面，直接走上表 A 層；A 層用盡還差行數，回報主人（B 層）。**

### ⛔ 刪減內容前必須呈報的「犧牲分析」

不得只說「要砍幾行」。必須逐項寫明：

1. **打算刪哪一段／哪一句**（貼原文）
2. **那段承載什麼**：是 claim、evidence、機制解釋、limitation、還是重複資訊？
3. **刪掉之後會失去什麼**：哪個 claim 失去支撐？哪個 reviewer 問題變得無法回答？
4. **有沒有更低成本的替代**（回頭確認 1–5 真的窮盡了嗎）

主人看完、明確同意，才准動。**「他沒反對」不算同意。**

### ⚠️ 病灶（為什麼要立這條）

2026-07-29 AAAI 交件日，我為了把正文收進七頁，**自行**砍掉了：§4.4 兩句機制解釋、Conclusion 一句重複陳述與首句修飾、以及學生原本寫的「qualitative 圖為何採用 additive--additive」那句。

最後一項當天就出事：學生回頭問「figure 3 有提到 additive-additive 的原因嗎」——**答案是沒有，因為被我刪了**。而那句正是擋掉 reviewer「你主表報 a-i、展示圖卻用 a-a，是不是挑好看的」這個 cherry-picking 質疑的唯一防線。

⛔ **時間壓力不構成例外。** 那天離 deadline 還有時間，主人自己用 `\vspace` 三兩下就把正文收進七頁——**排版手段根本還沒用完，我卻先動了內容。**

⚠️ 附帶一個判斷錯誤：我當天把整輪力氣壓在 `\looseness=-1` 上，那招其實無效，而真正有效的單欄化我做得太晚。**手段的有效性要靠實測排序，不是靠我覺得它精巧。**

---

## 一、禁止行為

### 1. 不要移除格式，要轉換格式
- ❌ 教授說「移除底線」→ 移除整個 `\emph{}`
- ✅ 教授說「移除底線」→ `\emph{}` 改成 `\textit{}`

**背景**：`\usepackage{ulem}` 會把 `\emph{}` 重定義為底線。教授要的是去掉底線恢復斜體，不是去掉 emphasis。

### 2. 不要改 en-dash
- `--` 在 LaTeX 產生 en-dash（–），用於複合詞：`accuracy--speed`、`fidelity--relevance`、`actor--critic`
- 教授要移除的是底線，不是 dash
- ❌ 把 `--` 改成 `-`
- ✅ 不碰 `--`

### 3. 不要改 system setup
- ❌ 改 `\usepackage{ulem}` → `\usepackage[normalem]{ulem}`
- ❌ 改 `\bibliographystyle{plainnat}` → `\bibliographystyle{unsrt}`（除非教授指示）
- ❌ 動 preamble 的 macro 定義
- ✅ 只改 `\cyl{}` 範圍內的文字

### 4. 不要用 find-all replace
- 教授可能只要改某個 section 的東西
- ❌ 全文搜尋替換 `\emph` → `\textit`
- ✅ 先確認範圍（「只改 intro 的 `\cyl{}` 區塊」）

### 5. 不要跨 repo 改
- 教授指定改 A 篇 → 只改 A 篇
- ❌ 順手把同樣的修正 propagate 到 B、C、D 篇
- ✅ 最多浮現「我注意到 X 篇也有同樣問題，要我處理嗎？」等授權

---

## 二、Edit Convention 三種模式

每篇論文的 convention 可能不同，**改之前必須確認**：

| Mode | 學生文 | 教授文 | 使用場景 |
|------|--------|--------|----------|
| **Comment out + replace** | `% 學生原文` | `\cyl{教授新版}` | 預設模式 |
| **Append（不 comment out）** | 保留不動 | `\cyl{...}` 加在 subsection 尾 | 教授指定時（如 FLORA） |
| **Rebuttal side-by-side** | 保留不動 | `\cyl{\noindent ...}` 緊接在後 | Rebuttal |

**如果不確定，問教授。** 教授可能同一會議不同篇用不同 convention。

---

## 三、Convention 細節

### Comment out + replace（預設）
```latex
% [Student original — commented out]
% Student's original text here describing the method...

\cyl{Professor's rewritten version with better narrative flow
and correct technical framing...}
```

### Append
```latex
% Student's original text stays here untouched
Student's original text here describing the method...

% ──── Professor's rewrite (blue, for comparison) ────
\cyl{Professor's rewritten version. Student can compare
both versions side-by-side on Overleaf PDF.}
```

### 注意事項
- 不要重複 equation（已有 label 的 equation 用 `\cref{}` 引用）
- Bold notation macro 必須跟原文一致（如 `\zb_t`, `\db_t`）
- `\cyl{}` 裡面也要遵守 writing bans（no em-dash、no comma+V-ing 等）

---

## 四、正確工作流程

```
1. 收到教授指令（patch file 或口頭指示）
2. 確認 convention（comment out / append / rebuttal）
3. 確認範圍（哪個 section、哪些檔案）
4. 讀取目標 .tex 檔案
5. 套用修改（最小幅度）
6. Compile 確認沒有 error
7. git commit + push origin
8. git pull overleaf + push overleaf     ← 不可省略
9. 回報完成
```
