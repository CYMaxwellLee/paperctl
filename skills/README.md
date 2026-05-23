# paperctl Skills — 完整索引

> 所有論文管理相關的 skill 和知識都集中在這裡。
> 換機器只需 clone `paperctl` repo 即可完整使用。

---

## Skill 總覽

| Skill | 位置 | 功能 | 適用場景 |
|-------|------|------|----------|
| **Academic Paper Writing** | `academic-paper-writing/` | 論文撰寫全套系統（6 sections + QA + ops） | 寫新稿、改稿、投稿前 polish |
| **Rebuttal** | `rebuttal/` | Rebuttal 寫作系統（strategy + response + style） | Author response |
| **Conference Ops** | `conference-ops/` | paperctl 工作流程 + 會議建置 + 多 remote 管理 | 開新會議、daily sync、投稿流程 |

---

## Quick Reference

### 改稿時必讀（按優先序）
1. `academic-paper-writing/modules/editing-discipline.md` — 改稿紀律 + edit convention
2. `academic-paper-writing/modules/overleaf-ops.md` — Overleaf 推送鐵律
3. `academic-paper-writing/modules/style-guide.md` — 寫作禁忌

### 寫新論文時必讀
1. `academic-paper-writing/SKILL.md` — 總覽 + 使用流程
2. `academic-paper-writing/modules/style-guide.md`
3. 對應 section 的 module

### Rebuttal 時必讀
1. `rebuttal/SKILL.md` — 總覽 + 核心原則
2. `rebuttal/modules/strategy.md` — 分析 + 優先序
3. `rebuttal/modules/response-writing.md`

### 開新會議時必讀
1. `conference-ops/SKILL.md` — paperctl 流程 + conference.json schema
2. `conference-ops/modules/conference-setup.md` — 建置 checklist
3. `conference-ops/modules/venue-reference.md` — 各會議格式速查

---

## 目錄結構

```
paperctl/skills/
  README.md                          ← 你在這裡
  academic-paper-writing/
    SKILL.md                         # 總覽 + 模組清單
    modules/
      style-guide.md                 # 寫作規範 + writing bans + banned words
      introduction.md                # §1 結構
      preliminary-methodology.md     # §2-§3 結構
      experimental-results.md        # §4 結構
      qa-guideline.md                # 8-pass QA
      qa-checklist.md                # 精簡 checklist
      overleaf-ops.md                # Overleaf 推送規則（NeurIPS 教訓）
      editing-discipline.md          # 改稿紀律 + 3 種 edit convention
  rebuttal/
    SKILL.md                         # 總覽 + 核心原則
    modules/
      strategy.md                    # Review 分析 + 優先序
      response-writing.md            # 逐條回覆規範
      style-guide.md                 # Rebuttal 專用格式
      checklist.md                   # 提交前確認
  conference-ops/
    SKILL.md                         # paperctl 工作流程總覽
    modules/
      conference-setup.md            # 建新會議 step-by-step
      venue-reference.md             # 各會議格式 + deadline 速查
      overleaf-git-patterns.md       # 雙 remote 操作 patterns
```
