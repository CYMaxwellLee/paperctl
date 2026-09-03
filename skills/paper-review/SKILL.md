# Conference Paper Review Skill

> **作者**: Prof. Chun-Yi Lee (NTU CSIE)
> **版本**: v1.0（2026-06-24 起）
> **適用場景**: 幫教授審別人投稿的 conference paper（IEEE APCAS/AICAS、SIGGRAPH(-Asia)、ICML/NeurIPS/CVPR 等）。**也適合反過來自審**——我們自己投稿前，拿這三個 lens + common pitfalls 檢查自己的 paper（教授語：「甚至值得當作 paperctl 自己檢視自己的準則」）。

---

## Skill 總覽

一套審稿系統，從讀懂 review form、逐欄位產出評語、到用三個高層 lens 深評、再到 adversarial 驗證每個指控是否站得住。繼承 `academic-paper-writing` 的嚴謹度，但目標是**評估**而非寫作。

最高目標：**review 要掛教授的名字送出去，不能出包**。每一個指控都要能扛住作者的 rebuttal——作者一句話駁不倒，才寫得出去。

### 模組結構

| 模組 | 檔案 | 功能 |
|------|------|------|
| **Evaluation Lenses** | `modules/evaluation-lenses.md` | 三個高層評估面向：新不新、重不重要、做沒做足 |
| **Common Pitfalls** | `modules/common-pitfalls.md` | 跨論文常見系統性缺陷（同一張表也是自審 checklist） |
| **Verification Discipline** | `modules/verification-discipline.md` | anti-over-reach 鐵則：指控送出前的查證紀律（踩過的錯都在這） |

### 使用流程

1. **先確認該會議的 LLM-assistance 政策**（逐會議不同）。禁止時（如 SIGGRAPH 2026）→ 只做判讀輔助、英文由教授自填；允許時 → 英文可寫到可貼程度，教授終審。
2. **讀懂 review form 的每個欄位**，產出 1:1 對齊的 MD：每欄「詳細中文理由 + 英文草稿（可填表單）」中英對照；存到論文 PDF 旁。
3. **三個 lens 深評**（`evaluation-lenses.md`）：新不新（SOTA currency + novelty）、重不重要（importance vs redundancy）、做沒做足（baselines / metrics / ablations / statistics / reproducibility）。
4. **對照 common-pitfalls** 找系統性缺口。
5. **Adversarial verify（鐵則）**：每個 falsifiable claim（數字、「缺少 X」、「內部矛盾」、「該比的 SOTA」、「已被解決」）都回原文/上網查證。過不了 `verification-discipline.md` 的一律降級或丟掉。
6. **產出**：用論文行號/表號/式號當證據；strengths 先給（顯 fair）、weaknesses 按殺傷力排序、附 constructive suggestions 與 rebuttal-proof 的提問。`Comments to author` 絕不含審稿人身分。

### 核心原則

1. **嚴謹 + 站得住腳 > 火力**。寧可少講一個指控，也不要講一個會被作者一句話反駁的。內部矛盾與未證明的 claim 最硬；外部「該跟某新方法比」的指控風險最高，務必先過 verification-discipline。

2. **三個評估 lens 是骨架**（教授 2026-06-24 明示的審稿準則，見 `evaluation-lenses.md`）：
   - **L1 新不新**：有沒有跟**該問題的現役 SOTA** 比？「新貢獻」是不是其實是未引用的前人工作？
   - **L2 重不重要**：解的是重要且 open 的問題，還是重複解前人已解的？
   - **L3 做沒做足**：baseline、metrics、ablations、統計（seeds/variance/significance）、reproducibility 做足了嗎？

3. **內部矛盾 > 外部 SOTA 指控**。論文自己的數字/邏輯矛盾，作者無法反駁，是最硬的 reject 理由；把「該跟 X 比」當理由前，必須先確認 X 真的早於投稿截止日、真的同問題（見 `verification-discipline.md`）。

4. **公允（fairness）**。baseline 真的是現役 SOTA 就大方承認（先講，rebuttal 才不能反咬我們亂要新 baseline）；有 first-of-kind 角度 originality 給 **Weak 不是零**；同單位/疑似作者自身前作要小心 COI。對的就說對——不替論文製造問題，也不替自己的指控護航。

5. **anti-over-reach 鐵則**（踩過的錯，2026-06-24 APCAS 5 篇審稿）：任何「該比/已被解決」的指控，送出前一律驗 (a) **公開日期 vs 投稿截止日**（不是會議年份！）、(b) **適用性**（同問題同設定）、(c) **存在性與正確歸屬**。細節與實際踩過的錯見 `modules/verification-discipline.md`——這是本 skill 最重要的一頁。

6. **多用 adversarial verifier**。獨立 agent 反過來挑「我們的 review」哪裡錯、哪裡誇大、哪裡作者能反駁。實證有效：抓到過「假矛盾」（不同指標被當成自相矛盾）、「假相同」（2.83× 差距被寫成 nearly identical）、「同期論文被誤當必比/不必比」。
