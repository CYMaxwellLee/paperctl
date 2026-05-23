---
name: paper-editing
description: 論文改稿 skill。當教授要求修改 LaTeX 論文（patch、rewrite、\cyl 藍字、comment out 學生文、更新 section）時觸發。包含所有改稿規則、禁忌、Overleaf 推送流程。
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
- 有沒有 equation 要保留（不重複）？

---

## Writing Bans（零容忍）

1. ❌ Em dash (`---` 或 `—`)
2. ❌ Adverb+comma opener（`Additionally,` `Furthermore,` `Moreover,` `Notably,`）
3. ❌ "straightforward"
4. ❌ Semicolons joining clauses
5. ❌ Comma+V-ing（`..., producing X`）
6. ❌ `thereby` / `utilize` / `numerous`

**注意**：`--` (en-dash) 用於 `accuracy--speed` → **保留不動**

---

## 改稿紀律

1. **只做教授說的，不多做**
2. **不要碰 system setup**（`\usepackage`、`\bibliographystyle`、preamble）
3. **`\emph{}` 有底線** → 改 `\textit{}`，不是移除 emphasis
4. **不要 find-all replace** → 先確認範圍
5. **不要跨 repo 改** → 教授指定 A 篇就只改 A 篇

---

## 改完必做（最重要）

```bash
# Compile
/Library/TeX/texbin/pdflatex -interaction=nonstopmode main.tex

# Push GitHub
git add <files> && git commit -m "..." && git push origin main

# Push Overleaf（不可省略）
git pull overleaf master --no-rebase --no-edit
git push overleaf main:master
```

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
