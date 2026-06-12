# Preliminary & Methodology 寫作模組

> 繼承 `style-guide.md` 的所有規範。本模組專注於 §2 Preliminary 和 §3 Methodology。

---

## 核心原則：Problem → Theory → Architecture → Detail

整個 §2–§3 的閱讀體驗必須是一條**從抽象到具體的漏斗**：

1. **§2 Preliminary**：讀者需要什麼前置知識才能讀懂 §3？
2. **§3.1 Problem Formulation**：我們在解什麼問題？（數學層面）
3. **§3.2 Theoretical Foundations**：最優解應該長什麼樣？（命題 / 分析）
4. **§3.3 Framework Overview**：我們的架構如何實現這些理論？（鳥瞰）
5. **§3.4–§3.N**：每個 module 的具體設計（zoom in）
6. **§3.N+1 Training Objectives**：怎麼訓練

**Reviewer 的感受目標**：「架構是理論的自然產物」，而非「先拼架構再硬湊理論」。

**⚠️ 如果論文沒有 theoretical contribution（純 engineering）**，§3.2 替換為 "Design Principles" 或 "Key Observations"，用 empirical analysis 代替 formal propositions。漏斗結構不變。

---

## 動筆前：對齊檢查

### 與 Introduction 的一致性

動筆前，**必須產出一張 cross-reference table**：

| Intro 位置 | Claim / Promise | §2–§3 Landing Point |
|-----------|----------------|---------------------|
| ¶1, Challenge 1 | [具體描述] | §3.X [具體 subsection] |
| ¶3, Insight A | [具體描述] | §3.2 [對應 Proposition] |
| ¶4, Contribution 1 | [具體描述] | §3.X [對應 module] |

**如果有 claim 找不到 landing point → 補內容或修 intro。不能留下 undelivered promise。**

**反向檢查**：§3 中出現了 intro 沒有 hint 過的重要內容 → 回去 patch intro。

### Notation 規劃

- 每個 symbol 只有一個意義
- 與 supplementary / tables 中的 notation 一致
- 不跟通用慣例衝突

---

## §2 Preliminary

### 設計原則

Preliminary **不是 notation glossary**。唯一功能：**為 §3 的理論分析或設計動機提供必要的 baseline context**。

判斷標準：如果 reviewer 不知道這個背景，§3 的哪一段看不懂？如果沒有 → 不屬於 Preliminary，屬於 Related Work。

### 結構

每個 subsection 對應 §3 中的一個理論命題或核心設計，提供該命題所批判/改進的 baseline mechanism。

### 寫法要求

- 以散文寫成，不用 bullet points
- Notation 嵌入描述中自然引入
- 每個 subsection 結尾有一句**銜接句**，點出 baseline 的隱含假設或局限性，自然引向 §3
- 不評價方法好壞（那是 intro 和 related work 的事）
- **控制篇幅**：§2 只放「§3 缺了它就看不懂」的背景，精簡為上（沒有固定頁數）

### ❌ 常見錯誤

- 寫成 notation table → 沒有 context
- 寫成 Related Work 縮寫版 → 失焦
- 引入的 notation 後面 §3 沒用到 → 冗餘
- §2 和 §3 之間沒有邏輯連接 → 缺 bridging sentence
- Notation 在 §2 和 §3 中不一致 → 致命

---

## §3 Methodology

### §3.1 — Problem Formulation

**功能**：用數學語言定義問題。

**⚠️ Problem Formulation ≠ Task Description。** 不是列出 "we address task A, task B"。而是把問題抽象成數學框架。

好的 Problem Formulation：
- 定義 input space 和 output space 的數學形式
- 點出核心難點在數學上對應什麼
- 自然引出 §3.2 的理論分析

### §3.2 — Theoretical Foundations / Design Analysis

**功能**：整篇論文的 intellectual core。在架構圖之前，先用理論說服 reader「這樣做是對的」。

**三種形式（依論文性質）**：
1. **Formal Propositions**（最強）：statement + proof（proof 可放 supp）
2. **Analytical Arguments**（中等）：gradient analysis、complexity analysis
3. **Empirical Design Rationale**（最弱但有效）：pilot experiments 論證設計

**寫法要求**：
- 用 LaTeX 定理環境框起來
- Statement 必須 self-contained
- 框之後跟 1-2 段 intuition paragraph
- 正文的 proof 講重點；proof 太長放 Supplementary（看情況和篇幅判斷，**沒有**固定行數門檻——教授 2026-06-12）
- 每個命題對應 intro ¶3 的某個 insight

**定理環境選擇指引**：
- `\begin{theorem}`：對數學本身的貢獻（慎用）
- `\begin{proposition}`：本文 context 下重要（最常用）
- `\begin{lemma}`：輔助性結論
- `\begin{corollary}`：某命題的直接推論
- `\begin{remark}`：informal 觀察

### §3.3 — Framework Overview

**功能**：Bridge — 把 §3.2 的抽象結論對應到具體的 module 設計。

- 開頭必須有 **bridging sentence**
- 用一段散文（6-10 句）鳥瞰整個架構
- 引用 architecture figure
- **不寫公式**，不寫 engineering details

### §3.4–§3.N — Module Details

**每個 subsection 內部結構**：
1. 一句 recap：連回 §3.2 的哪個命題 → 不超過一句
2. 設計描述：散文 + 公式
3. 設計理由：為什麼忠於理論，或做了什麼 practical adaptation

**寫法要求**：
- 每個 subsection 第一句話必須連回理論
- 公式必須有文字介紹和解釋（前有 setup sentence，後有 interpretation）
- 每個 module 最後要有一句總結，說明解決了 intro ¶1 中的哪個 challenge

### §3.N+1 — Training Objectives

- 一個 equation block + 逐項解釋
- 標準 loss 不需公式定義

---

## §2–§3 特有的額外規則

| 規則 | 說明 |
|------|------|
| **公式前後必須有文字** | ❌ 兩個公式背靠背 ✅ 前有 setup，後有 interpretation |
| **不在 §3 重複 §2 的定義** | §2 已定義的直接用 |
| **Module 名稱在 §3.3 首次出現時 bold** | 之後正常字體 |
| **Subsection title 要 formal 且 descriptive** | ❌ "How We Fuse Features" ✅ "3D Spatial Fusion Module" |

---

> **沒有頁數配額表**（教授 2026-06-12：「沒這回事，這種規則不應該存在」）。篇幅由內容需要與會議頁限決定，勿再加回任何 §X = N 頁的配額。
