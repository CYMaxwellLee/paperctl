# Overleaf Git Patterns — 雙 Remote 操作手冊

> NeurIPS / ECCV 2026 血淚集大成。每一條都是實際踩過的坑。

---

## 一、鐵律

**教授只看 Overleaf。改完沒推 Overleaf 等於沒做。**

NeurIPS 2026 真實案例：改了半天教授在 Overleaf 完全看不到。浪費大量時間 debug「PDF 怎麼沒變」。教授原話：「幹，你這錯誤太嚴重」。

---

## 二、標準推送流程

```bash
# 1. 改完 .tex → compile 確認
/Library/TeX/texbin/pdflatex -interaction=nonstopmode main.tex

# 2. Commit（指定檔案，不用 git add -A）
git add sections/method.tex sections/introduction.tex
git commit -m "描述"

# 3. Push GitHub
git push origin main

# 4. Push Overleaf（先拉再推，不可省略）
git pull overleaf master --no-rebase --no-edit
git push overleaf main:master
```

**或用 paperctl 一鍵：**
```bash
paperctl push --paper <name> "commit message" --dir <conf>
```

---

## 三、Push 被拒絕

學生在 Overleaf 有新 commit → 先 pull 再 push：
```bash
git pull overleaf master --no-rebase --no-edit
# 如果有 conflict → 解決 → git add → git commit
git push overleaf main:master
```

**不要用 `--rebase`**，會造成 Overleaf history 混亂。

---

## 四、Merge 後必須檢查

學生在 Overleaf 上持續改稿，merge 後可能出現：

| 問題 | 症狀 | 修復 |
|------|------|------|
| 重複 `\bibliographystyle` | bibtex: "Illegal, another \bibstyle command" | Comment out 重複的 |
| 學生加回 package 設定 | 渲染異常（底線、格式跑掉） | 檢查 preamble diff |
| 覆蓋教授 `\cyl{}` | 藍字消失 | `git log -p -- <file>` 找回 |
| 學生改回 `plainnat` | ref 順序變回 author-year | 確認 `\bibliographystyle` |

---

## 五、Compile 檢查

```bash
# 完整 compile cycle
/Library/TeX/texbin/pdflatex -interaction=nonstopmode main.tex
/Library/TeX/texbin/bibtex main
/Library/TeX/texbin/pdflatex -interaction=nonstopmode main.tex
/Library/TeX/texbin/pdflatex -interaction=nonstopmode main.tex

# 檢查 error
grep -iE "undefined|multiply defined" main.log  # 應為 0
```

---

## 六、常見 Git 問題

### Overleaf 用 master，GitHub 用 main
```bash
git push overleaf main:master     # 注意 refspec
```

### 大檔案卡住
Overleaf 對 push 大小有限制。如果卡住：
```bash
git config http.postBuffer 52428800   # 50MB buffer
```

### macOS Case-insensitive
`Sections/` 和 `sections/` 在 macOS 是同一個。Git tracks case but filesystem doesn't。不要同時有兩者。

---

## 七、ECCV Rebuttal 的 Overleaf 流程

ECCV 2026 rebuttal 是 1 頁 PDF。每個 paper 的 rebuttal 是獨立的 Overleaf project + 獨立的 repo。流程相同但注意：
- Rebuttal repo 的 `\cyl{}` convention 用 side-by-side（不 comment out 學生文）
- 推送到 rebuttal 的 Overleaf remote，不要推錯到 main paper 的
