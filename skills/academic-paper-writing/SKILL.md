# Academic Paper Writing Skill

> **作者**: Prof. Chun-Yi Lee (NTU CSIE)
> **版本**: v1.0
> **適用場景**: ECCV / CVPR / ICCV / NeurIPS / ICML 等頂會論文的撰寫、修改、QA

---

## Skill 總覽

這是一套完整的學術論文寫作系統，涵蓋從 Introduction 到 Experiments 的每一個 section，以及寫完後的 QA review 流程。所有模組共享同一套寫作哲學和 style 規範。

### 核心寫作哲學

1. **Insight-first, not number-first**: 每一句話都必須有資訊量。數字是佐證 insight 的工具，不是主角。
2. **Promise-delivery loop**: Introduction 的每一個 claim 在 Method 和 Experiments 中都必須有 landing point，反之亦然。不能有 undelivered promise。
3. **Theory drives architecture**: 方法的設計應該是理論分析的自然產物，而非先拼架構再硬湊理論。
4. **Academic, professional, elegant prose**: 頂會論文水準的英文，避免 GPT 痕跡、模板句式、空洞形容詞。
5. **Specific over generic**: 每句話都要有具體內容。數字勝過形容詞，機制勝過 buzzword。
6. **品質 = 論證 × 精確 × 語域，lint 只是地板**（教授 2026-07-05）: 禁字表是教授個人偏好的機械閘門，通過 lint ≠ 寫得好。語域靠三審計（動詞/慣用語/術語，style-guide §一），每段寫完走三遍修訂（論證 → 語域 → lint，style-guide §四）。

### 模組結構

本 skill 由以下模組組成，各模組獨立可用，但共享 style-guide：

| 模組 | 檔案 | 功能 |
|------|------|------|
| **Style Guide** | `modules/style-guide.md` | 所有 section 共用的寫作規範、禁止項、品質標準 |
| **Introduction** | `modules/introduction.md` | §1 四段式結構、Teaser 規格 |
| **Preliminary & Methodology** | `modules/preliminary-methodology.md` | §2-§3 漏斗結構、理論與實現的一致性 |
| **Experimental Results** | `modules/experimental-results.md` | §4 結辯式寫法、insight-first 原則 |
| **QA Guideline** | `modules/qa-guideline.md` | 8-pass QA 系統，從數學正確性到 GPT 句式清除 |
| **QA Checklist** | `modules/qa-checklist.md` | 精簡版 checklist，適合時間緊張時快速 review |
| **Drafting Pipeline** | `modules/drafting-pipeline.md` | 完整 agentic 分工（Section Editor → 3 lens 寫手 → Critic → Judge → Verifier → Professor-Proxy → 內部迭代），教授 2026-07-05 核可 |
| **Rulings Ledger** | `modules/rulings-ledger.md` | 教授親口裁決的 append-only 帳本；Professor-Proxy 的 ground truth；每次新糾正必補一條 |
| **Overleaf Ops** | `modules/overleaf-ops.md` | Overleaf 推送鐵律、merge 後檢查、compile 流程（NeurIPS 2026 教訓） |
| **Editing Discipline** | `modules/editing-discipline.md` | 改稿紀律：三種 edit convention、禁止行為、跨 repo 規則（NeurIPS 2026 教訓） |

### 使用方式

**寫新論文時**：
1. 先讀 `style-guide.md`（所有模組的共同基礎）
2. 按 section 順序讀對應模組（Introduction → Preliminary & Methodology → Experimental Results）
3. 初稿完成後，用 `qa-guideline.md` 做完整 QA review

**改稿 / Polish 時**：
1. 讀 `editing-discipline.md`（確認 convention + 禁止行為）
2. 讀 `style-guide.md` + 對應 section 的模組
3. 用 `qa-checklist.md` 做快速 check

**投稿期改稿（deadline 前）**：
1. **必讀** `editing-discipline.md`（確認該篇的 edit convention）
2. **必讀** `overleaf-ops.md`（推送流程，改完必推 Overleaf）
3. 讀 `style-guide.md`（§〇 目標函數 + §一 語域 + §四 三遍修訂；§八 禁字只是地板）
4. 改完 → 三遍修訂 → compile → push GitHub → push Overleaf

**時間緊張時**：
1. 只讀 `style-guide.md`（§〇 目標函數 + §一 語域 + §四 三遍修訂 + §八 禁字）
2. 只做 QA Checklist 中的「最低限度」四項

### Venue 差異速查

| Venue | 頁數限制 | 特殊注意 |
|-------|---------|---------|
| ECCV / ICCV | 14p (excl. refs) | LLNCS class；single-column |
| CVPR | 8p (excl. refs) | CVF class；壓縮力度更大 |
| NeurIPS | 9p (excl. refs) | neurips class；有 checklist |
| ICML | 8p (excl. refs) | icml class |
| CoRL | 8p submit / 9p camera-ready (excl. refs) | corl class；必須有 Limitations section（算頁數）；必須有 robotics focus 否則直接退回；OpenReview |

頁數限制直接影響冗餘刪減的力度。CVPR/ICML/CoRL 的 8 頁比 ECCV 的 14 頁需要更激進的壓縮。

### 交付流程（通用）

1. **Step 0**: 全文盤點 → Big Picture 摘要 → 等確認
2. **Draft**: 按模組指引產出 `.md` 草稿 → 等 review
3. **Self-check**: 產出自我檢視報告 → 跟草稿一起交
4. **Finalize**: 確認後寫入 `.tex`，用 `\cyl{}` 標記新寫內容
5. **Compile**: 本地 compile 確認無 error
6. **Push**: 等明確指示才 push

**⚠️ 在明確說「OK」之前，不要跳到下一步。**
