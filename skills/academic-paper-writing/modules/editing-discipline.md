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

### 這條凌駕本檔其他所有條目，也凌駕 `experimental-results.md` 的壓縮章節。

**版面不足時的處置順序（⛔ 由上而下窮盡，不准跳級）：**

| 順位 | 手段 | 說明 |
|-----|------|------|
| 1 | **orphan 收行**（「方陣魔法」） | 段末只剩一兩個字的行，優先用 `\looseness=-1` 讓斷行器少排一行，**一個字都不用改** |
| 2 | **`\vspace` 負間距** | 章節前、float 後、caption 後。⚠️ 不可改 `\textheight`／`\columnsep`／`\textwidth`（AAAI 明文禁止，違反要付 page fee） |
| 3 | **調整圖片尺寸／環境** | `width=0.85\linewidth`；或 `figure*`（跨欄）↔ `figure`（單欄）互換。★ 單欄化常常一次省下整頁 |
| 4 | **表格排版** | `tabular*`＋`\extracolsep{\fill}`、`\resizebox`、字級、`arraystretch` |
| 5 | **合併／並排 float** | 兩張窄表放進同一個跨欄 float 的兩個 `minipage` |
| 6 | ⛔ **刪減內容** | **只有在 1–5 全部窮盡之後，且必須先做「犧牲分析」呈報主人、得到明確同意才可執行。** |

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
