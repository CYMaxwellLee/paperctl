# Rebuttal Strategy 模組

> 收到 reviews 後的第一步：分析、分類、排優先順序。

---

## Step 1：Review Analysis Report

對每位 reviewer 產出以下分析：

### 1.1 基本資訊

| 項目 | 內容 |
|------|------|
| Reviewer ID | |
| Rating | |
| Confidence | |
| 整體態度 | Supportive / Neutral / Hostile |
| 核心 concern 數量 | |
| 是否有 factual error（reviewer 搞錯了） | |

### 1.2 Concern 分類

將每個 weakness / question 分類到以下類別之一：

| 類別 | 說明 | 回覆策略 |
|------|------|---------|
| **Misunderstanding** | Reviewer 理解錯了我們的方法或結果 | 禮貌地澄清，引用原文具體位置。不要指責 reviewer 沒讀仔細 |
| **Valid Concern + Can Address** | 合理的質疑，我們有能力回應（有數據、能做實驗、能改寫） | 最高優先級。用 evidence 正面回應 |
| **Valid Concern + Cannot Address** | 合理的質疑，但在 rebuttal 期間無法完全解決 | 承認 limitation，承諾 revision，但同時 argue 這不影響 core contribution |
| **Scope Mismatch** | Reviewer 希望我們做的超出論文 scope | 承認方向有趣，解釋為什麼不在本文 scope 內，提供初步分析 |
| **Writing / Presentation** | 寫作問題、圖表不清楚 | 感謝指出，承諾改進，給出具體改進方向 |
| **Request for Experiment** | 要求額外實驗 | 如果能做 → 做了附結果。不能做 → 解釋為什麼，用已有 evidence 間接回應 |

### 1.3 致命 Concern 識別

**致命 Concern** = 如果不解決，reviewer 不可能改分。通常是：
- 懷疑方法的 correctness（數學錯誤、邏輯漏洞）
- 懷疑實驗的 fairness（unfair comparison、cherry-picked results）
- 認為 contribution 太 incremental（核心質疑）
- 認為另一個 component 比我們的 contribution 更重要（confound）

每位 reviewer 的致命 concern 通常只有一兩個。**篇幅的大頭花在解決致命 concerns、給最強的 evidence**；小 concern 簡短回應（沒有百分比配額——文采與配置看情況）。

---

## Step 2：優先順序

### 2.0 跨論文排序（Paper-level Triage）

**同時管多篇投稿時，從高分 paper 先改，不是低分。**

| Paper 類型 | 優先級 | 策略 |
|-----------|--------|------|
| avg ≥ 4，有 champion（≥5 分） | 🔴 最高 | 勝算大，守成投資報酬最高。推一下就上去 |
| avg 3-4，concern 可回應 | 🟡 中等 | 認真回，用 evidence 拉分 |
| avg < 2.5，min=1 | 🟢 務實 | 做 rebuttal 但不過度投入，改分機率低 |

決策因素：
- 有 champion（≥5 分）→ 高優先，給 champion 彈藥在 discussion 推
- 學生實驗未到位 → 不勉強排前面，等實驗到了再改
- 極低分（avg < 2.5）→ 務實認知，即使想救 reviewer 改分機率很低

> **注意**：2.0 是跨論文 scope，2.1 是單篇內 scope，兩層共存不衝突。

### 2.1 單篇內 Reviewer 排序

**進入單篇後，從最低分到最高分處理。** 低分 reviewer 是該篇翻盤的唯一機會。

排序規則：
1. 最低分的 reviewer 最先處理，用最多篇幅和最強 evidence
2. 同分時，有致命 concern 的先處理
3. 高分 reviewer 最後處理（但不能敷衍，他是 champion 要給彈藥）

### 2.2 每位 Reviewer 內的 Concern 排序

1. 致命 concern → 全力回應
2. Valid concern + can address → 用 evidence 回應
3. Request for experiment → 如果有結果就回，沒有就用已有 evidence
4. Misunderstanding → 簡短澄清
5. Writing / presentation → 最後處理，通常一句話

---

## Step 3：Evidence 盤點

在動筆之前，先盤點手上有什麼 evidence：

| Evidence 類型 | 已有？ | 可以在 rebuttal 期間做？ |
|--------------|--------|----------------------|
| 新的 ablation 實驗 | | |
| 與 reviewer 要求的 baseline 比較 | | |
| 新的 visualization / qualitative results | | |
| 數學推導 / proof | | |
| 修改後的圖表 | | |
| 外部 reference 支持我們的 claim | | |

**Rule**：如果有 evidence 能直接回答致命 concern → 那個 evidence 是最高優先級的實驗。

---

## Step 4：Response Plan

對每位 reviewer 產出一個 response plan：

```
## Reviewer [ID] ([Rating] pts) — Response Plan

### 致命 Concern: [描述]
- 回覆策略: [Misunderstanding / New evidence / Acknowledge limitation]
- 需要的 evidence: [具體列出]
- 預期篇幅: [字數或段落數]

### Other Concerns:
- [C1]: [一句話策略]
- [C2]: [一句話策略]
- ...
```

**等 Response Plan 確認後，才開始寫 response。**

---

## 教授與學生的分工模式

典型的合作方式：

1. **學生先寫初稿**（based on 他們對自己方法的理解）
2. **教授做 strategy analysis**（用本模組）
3. **教授在學生稿上加自己的回覆**（用不同顏色區分）
4. **重點放在致命 concerns 的重寫**（學生可能低估了嚴重性）

顏色慣例：
- 學生原稿：黑色
- 教授修改/新增：紫色
- 分隔線：灰色橫線

---

## 特殊情境處理

### 當所有 reviewer 都是低分（全部 ≤ 4）

- 不要試圖翻轉所有 reviewer。聚焦在最有可能提分的那一位。
- 找出哪位 reviewer 的 concern 最 addressable → 全力回應他。
- 其他 reviewer 也認真回，但心理預期是穩住不降分。

### 當有一位 champion（5+ 分）

- 不要忽略 champion。他在 discussion 時會替你辯護。
- 給他足夠的 material：在回覆中強調你的 key contribution 和 evidence。
- 他可以在 discussion 中引用你回覆裡的 evidence 來說服其他 reviewer。

### 當 reviewer 的 concern 跟另一位 reviewer 重疊

- 在第一次回覆中完整回答。
- 在第二次出現時引用：「As discussed in our response to Reviewer [X], ...」
- 不要完整重複一遍。

### 當 reviewer 的 factual claim 是錯的

- **絕對不要說 "the reviewer is mistaken"。**
- 正確做法：「We appreciate this question. We would like to clarify that ...」然後用 evidence 呈現正確的理解。
- 讓 evidence 說話，不是你的文字。


---

## Step 5：Revise-and-resubmit（兩輪制）專屬策略（2026-08-29，WACV 2027 #892 實戰）

兩輪制（WACV 型）與一般 rebuttal 的三個結構差異：

1. **同批 reviewers + AC 對照舊版重審**。回覆用 per-reviewer 色碼 tag（`[\AC/\Rb]` 型），
   讓每位 reviewer 秒找自己的塊；重複的關鍵數字若服務不同 reviewer 的不同論證，
   屬「功能性重複」可保留，同一論證講兩次才刪。
2. **排序不只看分數**：(a) **AC meta review 點名的決定性題目最先**；(b) **swing voter
   （给 4 分且明文開提分條件者）的條件題緊接**——他說「做到就提分」的那幾題就是勝負手；
   (c) 之後才按低分 reviewer 順序。
3. **Rebuttal↔修訂稿是一紙契約**：rebuttal 每一句 "the revised Tab. X / Sec. Y carries..."
   都必須在修訂稿真正兌現。作法：tex 源碼留 `% TODO(改主文時)` 清單追蹤，
   上傳前逐項驗證（見 checklist 的 alignment matrix）。反向也成立：修訂稿做了的大事
   （新 section、旗標修正）要在 rebuttal 裡點名，官方本來就要求 rebuttal highlight changes。
