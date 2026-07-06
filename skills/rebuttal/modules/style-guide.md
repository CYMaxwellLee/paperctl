# Rebuttal Style Guide

> 基於三場成功 rebuttal 的真實寫作風格萃取。
> 繼承 `academic-paper-writing/modules/style-guide.md` 的所有禁止項和品質標準。

---

## 零、最高原則

### 0.1 Rebuttal 是 Sales Pitch，不是中性學術文件

**Rebuttal 的核心目的是說服 reviewer。** Paper writing 的精簡/中性原則不能照搬。

- **銷售詞保留**：consistently, optimal balance, excellent, seamless, further validating, plug-and-play — rebuttal 該用就用，不要為了精簡而砍
- **Reviewer 健忘假設**：每段 rebuttal 要 self-contained — 不要假設 reviewer 還記得 paper 上下文，重複講 context、claim、results
- **Supp/appendix evidence 早提**：第一句就提「as already detailed in Sec. X / Tab. Y of the supplementary material」— 強調「我們本來就有」
- **滿頁正好，不要省字**：1 頁 two-column 正好填滿就是合適長度。寧可詳細展示 evidence，不要為了 brevity 砍解釋。OpenReview 無字數限制時更要寫充分
- **部分 banned words 可接受**：「It is worth noting that」在 rebuttal 場合可用（教授明示）。真正不能用的紅線不變（見下方）

### 0.2 絕不道歉

**Rebuttal 中不出現任何形式的道歉、認錯、自我否定。** 以理服人，不被 reviewer 嚇到。

| 絕對禁止 | 替代方案 |
|---------|---------|
| "We apologize" | "We appreciate the opportunity to clarify" |
| "We are sorry" | "We thank the reviewer for pointing this out" |
| "We regret" | "We welcome the opportunity to provide explanation" |
| "We should have" | "We will include [X] in the revised manuscript" |
| "We acknowledge this weakness" | "We thank the reviewer for this observation. [evidence]" |
| "We admit that" | [不需要這種句子。直接用 evidence 說話] |
| "Unfortunately" | [刪除，直接陳述事實] |

---

## 〇.五、Prose 原則：絕不列點

**Rebuttal 的每一條回覆都必須是流暢的學術散文（prose），不是列點回答。**

❌ 絕對禁止的 GPT-style 結構：
- 用 **bold header** + 段落的方式列點（例如 "**Evidence 1.**"、"**Contribution scope.**"、"**Cross-architecture validation.**"）
- 每個段落都以 bold 關鍵詞開頭，形成視覺上的 bullet list
- 過多的結構標記讓回覆看起來像投影片而非論文

✅ 正確做法：
- 用段落之間的邏輯連接詞串連（"To provide further evidence..."、"Beyond the performance numbers..."、"This observation is further supported by..."）
- 每個段落自然過渡到下一個，像寫論文的 discussion section
- 段落可以長，不需要為了 "清楚" 而打碎成短條
- 如果真的需要列舉（例如描述三個 ablation 條件），用行內列舉（"(1) X, (2) Y, and (3) Z"）而非分段

**例外**：
- 表格（Tab. / Table）可以用
- 數學公式可以 display
- 引用原文的 reviewer concern 可以有格式
- 描述實驗設定（如三個 baseline 的具體參數）時，可以用短段落分別描述，但不要用 bold header

---

## 一、格式規範

### 教授與學生的區分

- **學生原稿**：黑色（或綠色）
- **教授修改/新增**：紫色（`#9900FF`）
- **分隔線**：灰色橫線（用於區隔學生版本和教授版本）
- 教授的回覆放在學生回覆下方，用橫線分隔

### Response 標記

每條回覆開頭用 **Response:** 標記，保持全文一致。

---

## 二、Rebuttal 專用禁止項

### 道歉類（零容忍）

| 搜尋 | 替代 |
|------|------|
| "apologize" | "appreciate the opportunity to clarify" |
| "sorry" | "thank the reviewer for" |
| "regret" | "welcome the opportunity to" |
| "we should have" | "we will include" |
| "unfortunately" | [刪除] |
| "we acknowledge this weakness" | "we thank the reviewer for this observation" |
| "we admit" | [刪除，用 evidence 說話] |

### 模板語（避免）

| 搜尋 | 替代 |
|------|------|
| "constructive feedback" | "valuable feedback" / "thoughtful engagement" |
| "constructive suggestions" | "valuable suggestions" |
| "insightful comments" | "careful observation" / "important question" |

### 對抗語（禁止）

| 搜尋 | 替代 |
|------|------|
| "The reviewer is mistaken" | "We would like to clarify that..." |
| "The reviewer failed to notice" | "We would like to bring to the reviewer's attention that..." |
| "As clearly stated" | "As discussed in Section X (Line Y)..." |
| "We disagree" | "We appreciate this perspective. We would like to respectfully highlight that..." |

### 自我否定語（禁止）

| 搜尋 | 替代 |
|------|------|
| "We believe our paper is strong enough" | [不需要這種句子] |
| "We hope the reviewer will reconsider" | [不需要。用 evidence 讓 reviewer 自己改] |
| "This is beyond the scope" | "This is an interesting direction. In the current work, we focus on..." |
| "We will add this in the camera-ready" | "The revised manuscript will include [具體內容]" |

---

## 三、「Respectfully」的正確用法

**「Respectfully」是最有力的推回工具。** 從成功 rebuttal 中萃取的用法：

### 用於澄清 misunderstanding

```
We respectfully note that the concern raised would indeed be valid
under [framework A]. However, our work operates within [framework B],
which is explicitly stated in our [Section].
```

### 用於堅定主張

```
We respectfully submit that characterizing [X] as [Y] fundamentally
mischaracterizes the core difficulty of [topic].
```

### 用於引導注意力

```
We would respectfully direct the reviewer's attention to the
comprehensive experimental analysis provided in [Section/Table].
```

### 用於表達強烈自信

```
With the utmost respect, we believe the tension we identify is
neither unsubstantiated nor self-imposed, but rather a fundamental
theoretical obstacle.
```

---

## 四、Tone Calibration

### 根據 Reviewer 分數調整

| 分數 | Tone | 說明 |
|------|------|------|
| ≤ 3 | 最完整、最充分的 evidence | 不是最謙卑 — 而是最有力的 evidence。以理服人。 |
| 4 | 專業、正式 | 回應每個 concern，但可以稍微精簡 |
| 5+ | 感謝 + 補充 | 他是 champion，給他 ammunition |

### ≤ 3 分 reviewer 的特殊注意

- **不要被低分嚇到**。低分不代表 reviewer 是對的。
- **找出他的致命 concern**，用最強的 evidence 正面回擊。
- **語氣保持完全專業**。不卑不亢。
- **篇幅要最長**。每個 concern 都完整回應。

### 語氣範例（真實成功案例）

對 critical reviewer 推回的正確語氣：
```
We appreciate the opportunity to address this fundamental question.
[...detailed evidence...]
We hope this clarification demonstrates that the tension we identify
is neither unsubstantiated nor self-imposed, but rather a fundamental
theoretical obstacle that has constrained the design space.
```

---

## 五、Revision 承諾的寫法

**具體、明確、有份量。**

✅ 正確：
```
The revised appendix will include Table R1, Table R2, and Fig. R1
presented above, along with a detailed per-iteration timing breakdown
that separately quantifies [specific items].

We will incorporate the comparison between [X] and [Y] into the
main body of the revised manuscript to better support our design choices.
```

❌ 錯誤：
```
We will fix this. [太隨便]
We will improve the writing. [太空泛]
We will add this in the camera-ready. [太隨便]
```

---

## 六、常用句式庫（從成功 rebuttal 萃取）

### 開場

```
We appreciate the reviewer's valuable feedback and effort spent on
the review, and would like to respond as follows.

We appreciate the opportunity to clarify [topic].

We welcome the opportunity to provide explanation on [topic].

We are pleased to provide clarification on this point.
```

### 引入 evidence

```
To provide a comprehensive answer to these concerns, we conducted
a detailed [study/experiment] comparing [X] to [Y].

To directly address this concern, we conducted [experiment].
The results are summarized in Table R1.

As presented in Section X.Y and illustrated in Fig. Z, [evidence].
```

### 推回

```
We would like to respectfully highlight that our primary contribution
indeed addresses [X], rather than [reviewer's characterization].

We respectfully note that [fact]. This distinction represents more
than a modeling choice. It constitutes a necessity for [reason].

We respectfully submit that the [X] represents a significantly more
challenging evaluation than [Y], as it encompasses [reasons].
```

### 結尾

```
We hope this clarification addresses the reviewer's concern and
demonstrates that [our claim].

We believe this combination of [evidence type 1] and [evidence type 2]
provides sufficient and compelling evidence addressing the reviewer's
question.

We appreciate the reviewer's thoughtful engagement and welcome further
discussion to address any additional questions.
```

---

## 七、從 Paper Writing Style Guide 繼承的硬性規則

**Rebuttal 是正式學術文件，必須遵守與論文相同的寫作規範。**

### 7.1 Cross-reference 格式（零容忍）

| 禁止 | 正確 | 說明 |
|------|------|------|
| `Eq. 5` | `Eq. (5)` | 方程式編號永遠加括號 |
| `Figure 2(b)` | `Fig. 2(b)` | 一律縮寫，句首用 `Figure` |
| **Rebuttal 中**：`Tab. 1` | **Rebuttal 中**：`Table 1` | **教授個人偏好**：rebuttal 中 Table 一律寫完整，**絕對禁止 `Tab.`** |
| **Rebuttal 中**：`Sec. 3.2` | **Rebuttal 中**：`Section 3.2` | **教授個人偏好**：rebuttal 中 Section 一律寫完整，**絕對禁止 `Sec.`** |
| **Rebuttal 中**：`Figure 2` | **Rebuttal 中**：`Fig. 2` | **教授個人偏好**：rebuttal 中 Figure 用**縮寫** `Fig.`（與 Table/Section 不一致，但這是教授偏好） |
| Paper 寫作 `Table 1` (句中) | Paper 寫作 `Tab. 1` | paper 寫作仍可句中縮寫 |
| Paper 寫作 `Section 3.2` (句中) | Paper 寫作 `Sec. 3.2` | paper 寫作仍可句中縮寫 |
| `Proposition 3.1` (句中) | `Prop. 3.1` | 句中縮寫，句首用 `Proposition` |
| `Appendix A.2` (句中) | `App. A.2` | 句中縮寫，句首用 `Appendix` |
| `Line 189` | `Line 189` | Line 不縮寫 |

**注意**：
- **Rebuttal 場合**：`Table` / `Section` 一律寫完整，**絕對禁止 `Tab.` / `Sec.`**（教授個人偏好）。`Fig.` 仍可縮寫
- **Paper 寫作**：仍可句中縮寫
- 遵循原論文的慣例。如果原論文用 `Figure` 不縮寫，rebuttal 也不縮寫。以原論文為準

### 7.2 Comma + V-ing（絕對禁止）

這是最常見的 GPT 句式，必須零容忍。

```
❌  We train the model on five benchmarks, achieving SOTA.
❌  We conducted experiments, demonstrating that X outperforms Y.
❌  MDM-Prime-v2 uses binary encoding, enabling tighter bounds.

✅  We train the model on five benchmarks and achieve SOTA.
✅  Our experiments demonstrate that X outperforms Y.
✅  MDM-Prime-v2 uses binary encoding, which enables tighter bounds.
✅  拆成兩句。
```

### 7.3 其他繼承禁止項

以下規則全部從 `academic-paper-writing/modules/style-guide.md` 繼承：

- **Em-dash（—）禁止**：用句號拆句或逗號
- **"; however," 禁止**：改為 "X works. However, Y fails."
- **", yet" 很不 prefer**（warn 級，教授 2026-06-12；句首 Yet 仍禁）：改為 "Although X works, it fails"
- **So 開頭禁止**：用 therefore / thus / accordingly
- **because 禁止（整篇，不限句首——教授 2026-06-12：「整篇我都不想because」）**：用 Since / As / Given that
- **自問自答禁止**：直接陳述
- **Banned words**：thereby, numerous, underscore（任何用法）, "Notably," (句首), "As can be seen from", "As shown in"（弱引用，表圖當主詞）, Yet（句首）
- **明確不禁**（教授 2026-06-12 裁決，paper 與 rebuttal 都不禁，勿再加回）："It is worth noting that"、"As expected,"、"demonstrates the effectiveness of"；leverage 是文采問題（多變化），不是次數限制
- **We/Our 連發**：文采問題——句式多變化（被動式、"This formulation…"、"The proposed…" 交替），不是數字上限
- **but**：❌ 整篇禁（教授 2026-06-12），改 however / although / while
- **小括號補充**：改為逗號子句或獨立句
- **分號連接句子**：盡量避免（教授個人偏好：rebuttal 中**完全不用** `;`，分號連接句子全改 `.` 拆成兩句）
- **數字 ≤ 10 寫英文**：`divisible by 8` → `divisible by eight`、`three backbones` 而非 `3 backbones`。**例外**：scale factor 數學式（`×4`、`×8`）、reference 編號（`Tab.~3`）、metrics 數字（`30.65 dB`）保留數字
- **描述「既有設計」用過去式**：rebuttal 描述「我們做過的事/設計」用過去式（we preprocessed, was weighted, $E_\theta$ extracted, we incorporated, we adopted）— 過去式跟「我們本來就有」訊號一致；**永恆機制/事實/性質**仍用現在式（the mechanism preserves, $\mathcal{F}_f$ and $\mathcal{F}_p$ share, $\bar{\alpha}_t$ is）
- **同義詞變化維持文采**：避免同詞反覆，例如：
  - `consistent` ↔ `in line with` ↔ `mirroring` ↔ `aligned with`
  - `consistently` ↔ `uniformly` ↔ `steadily`
  - 客套句首：`We respectfully note that...` ↔ `We kindly note that...` ↔ `We would like to note that...` ↔ `We kindly refer the reviewer to...`
- **銷售詞 GPT-y 替代**（rebuttal 也禁，不只 paper 寫作）：
  - ❌ `principled` （太 GPT）→ ✅ `substantive` / `coherent` / `well-founded` / `theoretically grounded`
- **既有 framing 軟化（避免吵架感）**：
  - ❌ `We respectfully note that... was already evaluated/discussed` 用 "already" 像在指責 reviewer 沒看到
  - ✅ `We kindly note that... was presented in the original supplementary material`
  - ✅ `We kindly highlight that... is reported in Table~X of the original main manuscript`
  - 訣竅：把 `respectfully note that already X` 改成 `kindly note that X was presented` / `kindly highlight that X is reported`，去掉 "already" 那種你忽略了的暗示
- **"Far from X" 太 assertive 軟化**：
  - ❌ `Far from being detrimental, this property correlates with...`（強硬反駁，可能被 reviewer 覺得有對抗性）
  - ✅ `Rather than being detrimental, this property correlates with...`（中性，同樣意思但語氣軟）
- **複現/reproduce 用語中性化**：
  - ❌ `our re-evaluation could not reproduce the originally reported results`（聽起來像我們無法 reproduce 不好）
  - ✅ `the publicly available implementation yields results that diverge from the originally reported numbers`（中性歸因到 public release 而非我們）
  - 訣竅：把主詞從「我們」改成「public release / publicly available implementation」，把「could not reproduce」改成「yields results that diverge」
- **`so` 句首/連接 informal connector 砍**：rebuttal 是正式學術文件，「so」太 informal（教授稱「小朋友用詞」）。改用：
  - 句首條件 → `since` / `as`
  - 結論 → `therefore` / `thus` / `accordingly` / `hence`
  - 例：❌ `On ScanRefer, Open-YOLO3D adopts Mask3D proposals internally, so we follow prior zero-shot works`
  - ✅ `For ScanRefer, since Open-YOLO3D adopts Mask3D proposals internally, our evaluation uses the same Mask3D proposals as the cited zero-shot baselines`
- **「we believe addresses the concern about X cited in Section Y」太繞**：直接「**X is stated in Section Y of the original main manuscript**」即可。不要繞「we believe ... addresses ... cited in ...」雙重 hedge
- **Reviewer 標籤用 anon ID 而非 R1/R2/R3**：rebuttal 中**禁用** `R1` / `R2` / `R3` — 因為每個 reviewer 在 OpenReview 看自己的 review 時，**不知道自己是 R1 還是 R3**（anonymous ID 是 OpenReview assign 的 4-字元代碼如 `wbYG` / `aAP7` / `xbZz`）。一律用 reviewer anon ID 著色標記，與 OpenReview 顯示對齊：
  - ❌ `\paragraph{R1 / R3 (zero-shot framing)}` — reviewer 看不出自己被指
  - ✅ `\paragraph{wbYG, XzBX: zero-shot framing}` — 直接對應 OpenReview 上的 ID
  - 慣例：define `\newcommand{\ra}{\textbf{\textcolor{green}{wbYG}}}` 等，每個 reviewer 一個 macro
- **`with X V-ing` 結構改 `where X V-s` / `, and X V-s`**（borderline comma + V-ing）：
  - ❌ `..., with IVSGround achieving the best performance`
  - ✅ `..., where IVSGround achieves the best performance`
  - ✅ `... and IVSGround achieves the best performance`
- **Paper 原文 quote 內含 `;` 的處理**：教授禁分號，但 paper 原文若含 `;` quote 時不能改 paper 原話。**做法是 split quote**：
  - ❌ `Section~3 stating that ``only the view selector is LoRA-trained; the grounding VLM remains zero-shot.''` （含原文 `;`）
  - ✅ `Section~3 stating that ``only the view selector is LoRA-trained,'' while the grounding VLM remains zero-shot.` （只 quote 前半，後半用 paraphrase 連接）
- **兩個 parallel 句子要有 transition**：兩個對比的句子（A...B...）建議加 transition word 連接：
  - ❌ `A pure-IVS view carries strong context but a partly-occluded target. A pure-visibility view shows the target clearly but misses landmark context.` （兩句平行但無 transition，教授說「缺個 transition?」）
  - ✅ `A pure-IVS view carries strong context but a partly-occluded target. **In contrast**, a pure-visibility view shows the target clearly but misses landmark context.`
  - 訊號詞：`In contrast`, `Conversely`, `On the other hand`
- **倒裝呈現 mixed-strength evidence**：當 reviewer 指出 "modest gain"，先講 strong evidence、再講 weak evidence 的存在意義：
  - ❌ `While the absolute PSNR gain ($+0.02$ dB) appears modest, ..., perceptual gains validate ...` （先講弱再講強，弱被先看到）
  - ✅ `The substantial perceptual gains ..., together with consistent fidelity improvement, validate the design as substantive. Although the absolute PSNR difference (around $+0.02$ dB on average) appears modest in isolation, this reflects the inherent X-Y trade-off rather than a marginal effect.`（先講強再講弱，弱有 reframe）

### 7.4 Mathematical Notation

- 使用 LaTeX 數學符號時，確保與原文一致
- OpenReview 支持 `$...$` 和 `$$...$$` 語法
- CMT 通常不支持 LaTeX → 用文字描述

---

## 八、Anonymous Links

- 使用 Anonymous GitHub 或 Anonymous 4open.science
- 格式：`https://anonymous.4open.science/r/rebuttal-paper-XXXX/filename.png`
- 每個連結都要在文字中 contextualize（不要只丟連結）
