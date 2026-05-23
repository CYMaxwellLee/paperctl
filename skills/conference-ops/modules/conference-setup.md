# 建立新會議 — Step-by-step

> 每個新會議（NeurIPS、CoRL、ECCV...）都照這個流程走。

---

## Step 1: 建立資料夾結構

```bash
CONF="corl2026"
BASE="$HOME/Project/Papers"   # 依你的實際路徑調整

mkdir -p $BASE/$CONF/$CONF-meta/templates
mkdir -p $BASE/$CONF/.claude
```

## Step 2: 建立 conference.json

在 `$CONF-meta/conference.json` 建立，然後 symlink：

```bash
# 建立 conference.json（見 SKILL.md 的 schema）
# ...

# Symlink
ln -s $CONF-meta/conference.json $BASE/$CONF/conference.json
```

## Step 3: 建立 CLAUDE.md

每個會議需要一個 CLAUDE.md，包含：
- Deadline（UTC + 台灣時間）
- 頁數限制 + 特殊規定
- paperctl 指令範例（指向該會議的 --dir）
- Writing conventions（包含該會議的 edit convention）
- NeurIPS 教訓提醒
- Compile 指令

## Step 4: 複製基礎設定

```bash
# MCP config（GitHub PAT）
cp $BASE/neurips2026/.mcp.json $BASE/$CONF/.mcp.json

# Claude Code 權限
cat > $BASE/$CONF/.claude/settings.local.json << 'EOF'
{
  "permissions": {
    "allow": [
      "Bash(ls:*)", "Bash(find:*)", "Bash(grep:*)",
      "Bash(git push:*)", "Bash(git pull:*)", "Bash(git fetch:*)",
      "Bash(git add:*)", "Bash(git commit:*)", "Bash(git clone:*)",
      "Bash(git remote add:*)", "Bash(git branch:*)", "Bash(git checkout:*)",
      "Bash(git merge:*)", "Bash(git config:*)", "Bash(git -C:*)",
      "Bash(ln:*)", "Bash(wc -l:*)", "Bash(gh:*)",
      "Bash(/Library/TeX/texbin/pdflatex:*)",
      "Bash(/Library/TeX/texbin/bibtex:*)",
      "Bash(/Users/cymaxwelllee/Project/Papers/paperctl/paperctl:*)",
      "Bash(paperctl:*)",
      "Read(//Users/cymaxwelllee/**)", "Read(//tmp/**)"
    ]
  }
}
EOF
```

## Step 5: 建立初始 STATUS.md + README.md + Meta 文件

README.md 由 `paperctl dashboard` 自動生成。

STATUS.md 為手寫敘事文件，包含：
- Timeline（重要日期和戰略節點）
- Papers table（每篇狀態摘要）
- Day-by-day log（每天完成事項紀錄）

### Meta 目錄標準文件清單

```
<conf>-meta/
  conference.json              # 單一 source of truth（papers, deadlines, status）
  README.md                    # paperctl dashboard 自動生成
  STATUS.md                    # 手寫戰況儀表板
  <conf>_battle_plan.md        # 作戰計畫（天數分配、優先序）
  <conf>_dashboard.md          # 投稿前手寫進度追蹤
  <conf>_project_instructions.md   # Claude project 設定指引
  <conf>_reviewer_instructions.md  # Reviewer response 指引
  <conf>_knowledge_template.md     # Knowledge upload 範本
  templates/
    supp_template.tex          # Supplementary material 模板
```

## Step 6: Bootstrap Paper Repos

教授開好 GitHub repo + Overleaf project 後：

```bash
# 1. 編輯 conference.json 加入 paper 資訊
# 2. Init repos
paperctl init --dir $BASE/$CONF

# 3. 每個 repo pull Overleaf template
cd $BASE/$CONF/$CONF-<paper>
git pull overleaf master

# 4. 確認 compile
/Library/TeX/texbin/pdflatex -interaction=nonstopmode main.tex

# 5. 確認 \cyl{} macro 存在
grep -l 'cyl' *.tex sections/*.tex common_macros.tex 2>/dev/null
# 如果沒有，加到 preamble：
# \providecommand{\cyl}[1]{\textcolor{blue}{#1}}
```

## Step 7: 驗證

```bash
paperctl status --dir $BASE/$CONF      # 應該看到所有 papers
paperctl compile --dir $BASE/$CONF     # 應該全部 compile clean
```
