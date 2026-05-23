# 改稿紀律 — 只做教授說的，不多做

> NeurIPS 2026 血淚教訓。每一條都是實際犯過的錯。

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
