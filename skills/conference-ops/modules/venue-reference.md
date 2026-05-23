# Venue Reference — 各會議格式速查

> 每年規則可能變，以官網為準。此表為 2026 年資料。

---

## 頁數限制

| Venue | 投稿 | Camera-ready | 不算頁的 | 特殊要求 |
|-------|------|-------------|---------|---------|
| **NeurIPS** | 9p | 10p | refs, ack, checklist, appendix | 必填 checklist |
| **ICML** | 8p | 9p | refs, ack, appendix | — |
| **CoRL** | 8p | 9p | refs, ack, appendix | 必填 Limitations section（算頁數）；必須有 robotics focus |
| **ECCV** | 14p | 14p | refs | LLNCS class, single-column |
| **ICCV** | 14p | 14p | refs | LLNCS class, single-column |
| **CVPR** | 8p | 8p | refs | CVF class |

## 投稿平台

| Venue | 平台 | 匿名 |
|-------|------|------|
| NeurIPS / ICML / ICLR / CoRL | OpenReview | 雙盲 |
| ECCV 2026 | OpenReview | 雙盲 |
| CVPR / ICCV | CMT 或 OpenReview | 雙盲 |

## 2026 Deadlines

| Venue | Abstract | Paper | Taiwan time (paper) |
|-------|----------|-------|-------------------|
| **NeurIPS 2026** | 2026-05-05 12:00 UTC | 2026-05-07 12:00 UTC | 5/7 20:00 |
| **CoRL 2026** | 2026-05-26 11:59 UTC | 2026-05-29 11:59 UTC | 5/29 19:59 |
| **ECCV 2026** | — | 已截止 | — |

## 特殊注意事項

### CoRL
- 沒有 robotics 相關的會被**直接退回不審**
- Supplementary 鼓勵附 video/code/data（zip ≤ 250MB via OpenReview）
- Video 不能放進 PMLR，必須自行 host + paper 內放 link

### NeurIPS
- Checklist 必填（附在 main paper 結尾）
- 9 頁限制不含 checklist

### ECCV
- 14 頁 single-column（LLNCS class）
- Rebuttal 改為 1 頁 PDF（2026 新規）

## Reference Style

| Venue | BibTeX style | 說明 |
|-------|-------------|------|
| NeurIPS | `unsrt` | 出現順序 [1] [2-5] |
| CoRL | 依 template | 通常 `plainnat` 或 author-year |
| ECCV | `splncs04` | LLNCS 標準 |
