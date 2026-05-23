# Conference Operations Skill

> **作者**: Prof. Chun-Yi Lee (NTHU CSIE / ElsaLab)
> **版本**: v1.0
> **適用場景**: 建立新會議、daily sync、投稿期操作、多 remote git 管理

---

## Skill 總覽

這是 paperctl CLI 的操作知識庫。涵蓋從建立新會議資料夾到 deadline 前最後一分鐘推送的完整流程。所有操作都建立在 `paperctl` CLI 之上。

### 模組結構

| 模組 | 檔案 | 功能 |
|------|------|------|
| **Conference Setup** | `modules/conference-setup.md` | 建新會議的完整 step-by-step |
| **Venue Reference** | `modules/venue-reference.md` | 各會議格式、deadline、特殊規定速查 |
| **Overleaf Git Patterns** | `modules/overleaf-git-patterns.md` | 雙 remote 操作、merge 處理、常見問題 |

### 核心概念

1. **conference.json 是唯一資料源** — 所有 paper 資訊都在這裡，paperctl 所有指令都從這讀
2. **雙 remote**: 每個 paper repo 有 `origin` (GitHub) + `overleaf` (Overleaf git)，有些還有 `upstream`
3. **教授只看 Overleaf** — 改完必推 Overleaf，沒推等於沒做
4. **paperctl 抽象了 sync/report/dashboard** — 教授管 8-10 篇論文，手動不可行

### paperctl 指令速查

| 場景 | 指令 |
|------|------|
| 開 session | `paperctl start --dir <conf>` |
| 並行 sync | `paperctl sync --parallel --dir <conf>` |
| 學生活動報告 | `paperctl report --update-notes --dir <conf>` |
| 推送改稿 | `paperctl push --paper <name> "msg" --dir <conf>` |
| 更新 dashboard | `paperctl dashboard --output <meta>/README.md --status <meta>/STATUS.md --dir <conf>` |
| 編譯確認 | `paperctl compile --paper <name> --dir <conf>` |
| 寫作 lint | `paperctl lint --paper <name> --dir <conf>` |
| 投稿前檢查 | `paperctl preflight --paper <name> --dir <conf>` |
| 頁數檢查 | `paperctl pages --update --dir <conf>` |

### conference.json Schema

```json
{
  "conference": {
    "name": "CoRL",
    "year": 2026,
    "slug": "corl2026",
    "template": "corl",
    "org": "ElsaLab-2026",
    "abstract_deadline": "2026-05-26T11:59:00Z",
    "deadline": "2026-05-29T11:59:00Z",
    "page_limit": 8,
    "page_limit_note": "8 pages excluding refs..."
  },
  "defaults": {
    "github_branch": "main",
    "overleaf_branch": "master",
    "overleaf_remote": "overleaf",
    "upstream_remote": "upstream"
  },
  "papers": [
    {
      "name": "paper-codename",
      "repo": "github-repo-name",
      "overleaf": "https://git.overleaf.com/xxxxx",
      "paper_id": 12345,
      "title": "Full Paper Title",
      "domain": "VLA",
      "status": "draft",
      "batch": 1,
      "claude_project": true,
      "knowledge_uploaded": true,
      "notes": "",
      "pages": 0,
      "authors": "Student A, Student B, Chun-Yi Lee",
      "student_lead": "Student A"
    }
  ]
}
```

### 標準目錄結構

```
<conf>/                          # e.g. corl2026
  conference.json                # symlink → <conf>-meta/conference.json
  CLAUDE.md                      # 該會議的工作說明
  .mcp.json                      # MCP 設定（含 GitHub PAT）
  .claude/settings.local.json    # Claude Code 權限設定
  <conf>-meta/                   # 元資料
    conference.json              # source-of-truth
    README.md                    # paperctl dashboard 自動生成
    STATUS.md                    # 戰況追蹤
    templates/                   # LaTeX style files
  <conf>-<paper>/                # 每篇論文 repo
    origin  → GitHub
    overleaf → Overleaf git
```
