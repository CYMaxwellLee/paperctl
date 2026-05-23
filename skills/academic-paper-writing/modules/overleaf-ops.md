# Overleaf 操作規範 — 投稿期改稿工作流

> NeurIPS 2026 血淚教訓整理。每次改稿必讀。

---

## 一、鐵律：教授只看 Overleaf

教授不看 GitHub diff，不看本地檔案。**改完沒推 Overleaf 等於沒做。**

NeurIPS 2026 實際發生：改了半天教授在 Overleaf 完全看不到，浪費大量時間 debug 不存在的問題。

---

## 二、每次改稿的標準操作

```bash
# 1. 改 .tex 檔案

# 2. Compile 確認無 error
/Library/TeX/texbin/pdflatex -interaction=nonstopmode main.tex

# 3. Commit + Push GitHub
git add <具體檔案>    # 不要用 git add -A
git commit -m "描述"
git push origin main

# 4. Push Overleaf（先拉再推）
git pull overleaf master --no-rebase --no-edit
git push overleaf main:master
```

**步驟 4 不可省略。** 如果 push 被拒絕：
```bash
git pull overleaf master --no-rebase --no-edit
# 解決 conflict（如果有）
git push overleaf main:master
```

---

## 三、Overleaf Merge 後必須檢查

學生在 Overleaf 上持續改稿，merge 後常見問題：

| 問題 | 症狀 | 修復 |
|------|------|------|
| 重複 `\bibliographystyle` | bibtex error: "Illegal, another \bibstyle command" | Comment out 重複的那行 |
| 學生加回 `\usepackage` 設定 | 渲染異常（底線、格式跑掉） | 確認 preamble 是否被改 |
| 覆蓋教授的 `\cyl{}` 文字 | 藍字消失 | 從 git log 比對找回 |

---

## 四、paperctl 整合

paperctl 的 `push` 指令會同時推 GitHub + Overleaf：
```bash
paperctl push --paper <name> "commit message" --dir <conf-dir>
```

如果 paperctl 不可用，手動按上述步驟操作。

---

## 五、Compile 檢查清單

投稿前的完整 compile cycle：
```bash
/Library/TeX/texbin/pdflatex -interaction=nonstopmode main.tex
/Library/TeX/texbin/bibtex main
/Library/TeX/texbin/pdflatex -interaction=nonstopmode main.tex
/Library/TeX/texbin/pdflatex -interaction=nonstopmode main.tex
```

檢查項目：
- `grep -iE "undefined|Warning.*ref|Warning.*cit" main.log` → 應為 0
- `grep "multiply defined" main.log` → 應為 0
- 有 `\cref{}` 引用的 label 是否存在（特別注意 commented-out 的 label）
