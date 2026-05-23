# Response Writing 模組

> 逐條回覆的寫作規範。基於三場成功 rebuttal（ICLR 2026 HAQO、NeurIPS 2025 EDELINE、NeurIPS 2024 MEow）的真實寫作風格萃取。

---

## 黃金法則：絕不道歉

**Rebuttal 中絕對不出現任何形式的道歉。** 這是最核心的原則。

❌ 絕對禁止：
- "We apologize for the confusion"
- "We are sorry for not being clearer"
- "We regret that..."
- "We should have..."
- "Unfortunately, we failed to..."

✅ 正確替代：
- "We appreciate the opportunity to clarify..."
- "We welcome the opportunity to provide explanation on..."
- "We would like to clarify that..."
- "We thank the reviewer for pointing this out. We will correct/include this in the revised manuscript."

**為什麼不道歉**：道歉暗示我們做錯了。Rebuttal 是以理服人的場合。即使確實有疏漏，也要用中性語言處理（"We will include..." "We will correct..."），而不是認錯的語氣。學生寫的初稿最容易出現道歉語，必須全部替換。

---

## 回覆的整體結構

每位 reviewer 的回覆結構：

```
[Opening — 感謝句]

[Response to Weakness 1]
[Response to Weakness 2]
...
[Response to Question 1]
[Response to Question 2]
...
```

---

## Opening — 感謝句

**每位 reviewer 都要有一句感謝。** 語氣中性、formal、不過度讚美也不批評。

**硬性禁止**：
- ❌ "constructive feedback" — 太模板，每個 rebuttal 都這樣寫
- ❌ "insightful comments" — 過度讚美
- ❌ "constructive suggestions" — 同上
- ❌ "careful reading" / "thoughtful analysis" — 不要稱讚 reviewer。如果他問了蠢問題，說他 careful 是反諷
- ❌ "respond to each weakness" — 自己先承認了 weakness，在回覆裡不要用 weakness 這個詞
- ❌ "positive evaluation" — 不要稱讚 reviewer 給好分數

**正確範例（中性感謝 + 不帶評價）**：
```
We appreciate the reviewer's time and effort spent on the review,
and would like to respond as follows.

We thank the reviewer for the feedback and would like to respond
to each question as follows.

We appreciate the reviewer's feedback and the effort dedicated to
the review, and would like to respond as follows.
```

**注意**：
- 每位 reviewer 的感謝句要略有不同
- 用 "question" / "concern" / "comment" 替代 "weakness"
- 只感謝 time、effort、feedback（中性詞），不誇 reviewer 的分析品質

---

## 核心寫法：「Respectfully」推回法

**當需要反駁 reviewer 時，「respectfully」是最有力的武器。** 以下是從成功 rebuttal 中萃取的真實用法：

### 強度等級一：溫和澄清

```
We would like to clarify that...
We appreciate this question. We would like to clarify that...
```

### 強度等級二：禮貌推回

```
We would like to respectfully highlight that...
We respectfully note that...
We would like to bring to the kind attention of the reviewer that...
We would like to respectfully emphasize that...
```

### 強度等級三：堅定反駁

```
We respectfully submit that [reviewer's characterization]
fundamentally mischaracterizes the core difficulty of [topic].

With the utmost respect, we believe [our position] represents a
core theoretical conflict, one that our paper addresses for the
first time.
```

### 強度等級四：引導 reviewer 重新審視

```
We would respectfully direct the reviewer's attention to [evidence]
in [Section/Table/Figure], which may have been overlooked.

We would like to bring to the reviewer's attention that [fact], as
presented in [location].
```

**關鍵原則**：永遠不說 "the reviewer is mistaken"。讓 evidence 證明 reviewer 的理解需要修正。

---

## 逐條回覆的結構模式

每條回覆遵循以下結構：

```
1. [Thank/Appreciate] — 感謝 reviewer 提出這個問題（1 句）
2. [Reframe] — 如有必要，重新框架問題（把問題拉到對我們有利的角度）
3. [Evidence] — 用數據、實驗、推導正面回應（主體）
4. [Implication] — 這個 evidence 為什麼完全回應了 concern
5. [Revision note] — 如適用："The revised manuscript will include..."
```

**⚠️ 注意：Step 1 不是承認錯誤，是感謝提問。** 區別很大。

### 感謝 + 回應的正確寫法

✅ 正確（感謝提問，不承認錯誤）：
```
We thank the reviewer for this important observation. [直接進入 evidence]
We appreciate the opportunity to clarify the nature and treatment of [topic].
We appreciate this question and would like to provide explanation on [topic].
```

❌ 錯誤（道歉或承認失誤）：
```
We apologize for the unclear presentation. [暗示我們寫得不好]
We acknowledge that our paper did not adequately address... [自我否定]
We agree that this is a weakness of our work. [直接承認弱點]
```

---

## 重新框架（Reframe）策略

### 策略一：把「改進幅度小」轉化為「在困難場景下優勢顯著」

```
The magnitude of improvement must be evaluated in the context of
task complexity. The most substantial performance gain occurs in
[hardest benchmark], which is widely recognized as the most
challenging due to [reasons]. HAQO excels precisely in scenarios
where the expressiveness limitations of simpler policies become
apparent.
```

### 策略二：把「component A 比 contribution B 重要」轉化為「cross-architecture validation」

```
To provide evidence for the independent value of [B] that is
entirely free from the [A] confound, we additionally applied [B]
to [a completely different architecture] that does not contain [A].
Since [A] is entirely absent, this result isolates the independent
contribution of [B].
```

### 策略三：把「計算成本高」轉化為「sample efficiency 抵消了成本」

```
The modest increase in computational cost is counterbalanced by
substantially improved training stability and sample efficiency.
When [method] reduces the number of required steps by more than
the measured [X] times overhead factor, the method achieves faster
wall-clock convergence. Our learning curves demonstrate that this
condition is consistently satisfied in practice.
```

### 策略四：把「為什麼不用更簡單的方法」轉化為「簡單方法在根本上不足」

```
Our experimental results demonstrate that [simple alternatives]
address the symptom but not the root cause. While all methods
converge to approximately valid outputs at the final step,
intermediate violations are not benign: [explain compounding error
mechanism]. These results confirm that the advantage of our design
is structural, not incremental.
```

### 策略五：把 Training Instability 當作最強 Evidence

```
Beyond the performance gap, we report that the [baseline] exhibited
[numerical instability / NaN outputs] during training under identical
hyperparameter settings, an instability entirely absent in our
formulation. This constitutes direct evidence that [the problem we
identify] has real practical consequences beyond theoretical concern.
```

### 策略八：Argument-first + friendly opener 雙併存（核心原則）

**Rebuttal 每段都要：(a) friendly opener + (b) argument-first 主題句**。兩個合一，不要只有 argument 冷陳述。

❌ 純 argument 冷陳述（沒 friendly opener，**直接打臉 reviewer**）：

```
The proposal-generator concern does not apply to NR3D and is
fully addressed for ScanRefer. ...
```
```
The visibility-IVS hybrid is by design: each signal addresses ...
```

教授稱：「**這個也是要很友善先提醒 reviewer**」、「沒有開頭詞，沒有友善提醒 reviewer」。

✅ Friendly + argument 同句合一：

```
We thank the reviewers for raising the proposal-generator
concern, and respectfully clarify that it does not apply to
NR3D and is fully addressed for ScanRefer. ...
```
```
We respectfully clarify the design rationale of the visibility-
IVS hybrid, which Fig. R1 and Table R2 directly establish
through new evaluation. ...
```

訊號詞（**簡化版**：教授個人偏好「**直接謝 question/suggestion**」即可，不要 "raising the X-Y concern" 太冗）：
- ✅ `We thank the reviewer(s) for the question, and ...`
- ✅ `We thank the reviewers for the suggestions, and ...`
- ❌ `We thank the reviewer for raising the cross-reasoner question` — 太冗
- ❌ `We thank the reviewers for the suggestions on presentation` — 太冗
- ❌ `We thank the reviewers for raising the proposal-generator concern` — 太冗
- 其他形式：
  - `We respectfully clarify [topic], which [evidence reference]`
  - `We kindly clarify [topic], with ...`
  - `We respectfully confirm that ...`
  - `We kindly note that [既有 evidence] ...`

**Friendly opener 普遍化原則**：**不只 argument-first 段需要**，**所有段（包括短 clarification 段）都要 friendly opener**。例如：

- 短 confirmation 段（如 bracket size）：`**We respectfully confirm that** we use $B=2$ in all experiments.`
- Compute clarification：`**We thank the reviewers for raising the compute concern.** Feedback generation is a one-time cost ...`
- Eq 引用釐清：`**We respectfully clarify the semantic-label source for Eq. (4).** The $\mathrm{semantic}_{c_i}$ ...`

唯一例外：開頭「We thank all reviewers for...」整體致謝段不需重複 friendly opener。

---

**Argument-first 主題句結構**（接續 friendly opener）：每段 argument 主題句**直接 argue**（不問題 / 已 cover / fully addressed），evidence 立刻 deliver，不要「To address this concern, we additionally provide...」delay 出招。

❌ Narration 流水帳（教授稱「像小朋友作文」）：

```
NR3D follows the standard protocol using GT bounding boxes,
in which proposal generators do not apply. Table S3's "GT
recall = 90.7%" measures COS class-filter retention, not
detector recall. On ScanRefer, Open-YOLO3D adopts Mask3D
proposals internally, so we follow prior zero-shot works...
```

✅ Argument-first：

```
The proposal-generator concern does not apply to NR3D and
is fully addressed for ScanRefer. NR3D follows the standard
protocol of using GT bounding boxes, where proposal generators
are not part of the evaluation pipeline. ...
```

❌ Reactive evidence delay（教授稱「太晚太弱」）：

```
We respectfully clarify the design rationale of the visibility-IVS
hybrid. Visibility is a free, deterministic geometric quantity ...
[3 sentences of setup] ...
To directly address this concern, we additionally provide Figure R1
and Table R2. Figure R1 shows that ...
```

✅ Evidence 立刻砲打（教授稱「直接就有新證據了，應該要很早就講出來很早就拿出來打」）：

```
The visibility-IVS hybrid is by design: each signal addresses a
distinct failure mode that pure visibility or pure IVS alone cannot
cover. Fig. R1 and Table R2 directly establish this through new
evaluation. ...
```

訊號詞範例：
- `The X concern does not apply to ... and is fully addressed for ...`
- `The X concern is fully addressed by an additional evaluation.`
- `[Method] is by design [property]: ... [Fig./Tab.] directly establish this through new evaluation.`

關鍵：**第一句就是結論**，後面才是 evidence/setup。傳統 paper writing 的「先 setup 再結論」在 rebuttal 是錯的 — reviewer 沒耐心看 narration，要立刻看到我們的 stance。

### 策略九：Categorization 質疑時的 fact→align→感謝→CR 軟順序

當 reviewer 質疑 paper 的 categorization claim（例如「the 'zero-shot' claim is overstated」），**不要用「does not claim X」「does not contradict」defensive negative** — 這像在被指責後否認，反而引發更多攻擊。

❌ Defensive negative：

```
We respectfully note that the original main manuscript does
not claim X. The selector training therefore does not contradict
any framing in the paper. ...
```

✅ Fact → Align → 感謝 → CR enhance：

```
[Fact 階段] The original main manuscript already limits the X
claim to [scope] in three places: [Place 1 quote], [Place 2 quote],
and [Place 3 quote].

[Soft Align 階段] The framing across the paper is therefore aligned
on this scope.

[感謝 reviewer 階段] We thank the reviewers for prompting a clearer
presentation,

[CR enhance 階段] and the camera-ready version will sharpen the
[specific location] phrasing so that the scope distinction is
[concrete deliverable description].
```

關鍵差異：
- 不寫「does not claim / does not contradict / never claimed」對抗詞
- 用「**already limits**」+ paper 真實引用 — 給事實證據，不用反駁
- 「**framing aligned**」soft connector — 不是「contradict」對抗
- 感謝句「**prompting a clearer presentation**」 — 不是「for the suggestion」太 vague
- CR 具體到 location（例如 "Abstract phrasing"），不只「Introduction earlier」

### 策略七：Future work 不空口承諾

**「we plan to」是空口說白話的訊號詞，rebuttal 中禁用。**

當 reviewer 點出某 limitation 時，常見學生稿用 "we plan to explore X in future work" 把問題推給未來 — 這是空口承諾，沒有 deliverable，reviewer 不買單。

❌ 錯誤：

```
To address this, we plan to explore [X] in future work.
We will conduct further ablation studies to more thoroughly examine ...
```

✅ 正確：定位為「我們認同這是有趣的方向，未來會繼續改善」，不卑不亢，不認錯但承認方向：

```
We see [X] as a compelling future direction to further improve the
framework's [aspect].

[X] represents a promising direction for future research, which we
will pursue to further improve [aspect].
```

訊號詞：`We see ... as a compelling future direction`、`represents a promising direction for future research`、`to further improve` — 不認錯（不寫 "we acknowledge this limitation"），但對方向表示認同。

### 策略六：既有 vs 新增 evidence 的差異化 framing

**Rebuttal 中的 evidence 必須區分「paper 提交時就有」vs「rebuttal 才補」**，兩者用不同訊號詞，一段裡並列時有特定順序。

#### 既有 evidence (paper 提交時就有)

訊號詞：`already`, `original supplementary`, `has been systematically examined in Sec.~X`, `as detailed in Sec.~Y of the supplementary`

軟化客套句首：`We respectfully note that...`, `We kindly note that...`, `We would like to note that...`

修辭目的：軟性提醒 reviewer 沒讀仔細，**客氣但有效**。**絕不**直接寫 "the reviewer failed to notice" 或 "as clearly stated"（後者也禁用）。

例：

```
We respectfully note that the [topic] has already been systematically
examined in Sec.~X of the original supplementary material, where we
[brief description].
```

```
We kindly note that additional results on [datasets] are already
provided in Tab.~Y and Tab.~Z of the original supplementary material.
```

#### 新增 evidence (rebuttal 才補)

訊號詞：`to further validate this for the reviewer`, `we additionally provide`, `we now report`, `to directly address this concern, we conducted`

不需要客套（直接強）— 這個是「我們慎重對待 review」的訊號。

例：

```
To further validate this for the reviewer, we present \Cref{table:X}.
[Description of new evidence].
```

```
To directly address this concern, we additionally provide [evidence].
```

#### 並列時的順序（同一段同時有既有 + 新增 evidence）

1. **開頭**：點明「我們本來就做了 X」（既有）— reframe reviewer 質疑 + 啟動軟性提醒
2. **中段**：「為了更進一步說服 reviewer，我們多做 Y」（新增）— 顯示對 review 的尊重
3. **結尾**：「順帶一提，supp 還有 Z」（再次 reinforce 既有）— 雙重提醒

完整範例：

```
We respectfully note that the architectural flexibility of [method]
has already been systematically examined in Sec.~A.4 of the original
supplementary material, where we [既有 evidence 描述]. To further
validate this for the reviewer, we present \Cref{table:X} and
\Cref{table:Y}, [新增 evidence 描述]. We also kindly note that
additional results on [datasets] are already provided in Tab.~Z of
the original supplementary material.
```

#### 為什麼這樣做

- **既有 evidence 的軟性提醒**：讓 reviewer **自己**意識到沒讀仔細，不傷感情；比直接點名有效得多
- **新增 evidence 的呈現**：顯示「對 review 認真」 — 加分項，不是被動防守
- **雙重 reinforce 既有**：rebuttal 1 頁有限，但「我們本來就有 X」這個訊號值得反覆給
- **絕不寫**「the reviewer overlooked」「as clearly stated」「the reviewer failed to notice」 — 對抗語禁忌

---

## Evidence 呈現方式

### 新實驗結果

```
To directly address this concern, we conducted [experiment].
[Table/Figure description]. The results demonstrate that [insight].
```

**每個表格/圖表都必須有**：
1. 標題（Table R1. / Fig. R1.）
2. 說明（一句話描述表格在比什麼）
3. Interpretation（結果意味著什麼 — 不只是丟數據）

### 引用已有結果

```
As presented in Section X.Y and illustrated in [Figure/Table],
[specific evidence]. This result directly [confirms/demonstrates/
validates] [our claim].
```

### 理論論證

```
Our Proposition X.Y establishes that [theoretical result]. This
property is guaranteed through our algorithmic construction, which
ensures that [property] by design.
```

---

## 特殊情境：Area Chair Letter

當 reviewer 不回覆或不 engage 時，可以寫信給 Area Chair：

```
Dear Area Chair,

We sincerely appreciate the area chair and the reviewers' efforts
during the review process. We are writing to respectfully seek the
area chair's assistance in facilitating continued dialogue with
reviewer [ID] during this important phase of the evaluation process.

[Summary of what we addressed]

We would be most grateful if the area chair could kindly invite the
reviewer to indicate whether our responses have satisfactorily
addressed their comments.

We sincerely appreciate your assistance in facilitating this
important dialogue throughout the review process.

Authors of Submission [XXXX]
```

---

## 「自信但不傲慢」的語氣校準

### 表達自信的正確方式

✅ 用 evidence 支撐的自信：
```
Our experimental results demonstrate that...
The evidence demonstrates that this computational investment yields
substantial returns...
These results collectively indicate that...
```

✅ 主張貢獻的正確方式：
```
To the best of our knowledge, no prior work has successfully
combined [X] with [Y] in the [Z] setting.

This represents the first effort to reconcile this theoretical gap.

Our central contribution demonstrates that [X] can match or exceed
[Y] while providing substantially greater [Z].
```

### 表達自信的錯誤方式

❌ 空洞自誇：
```
We believe our paper is strong enough for acceptance.
Our contribution is clearly novel and significant.
```

❌ 過度謙虛（等於自我否定）：
```
We humbly submit that...
We hope the reviewer might reconsider...
We admit that this is a limitation...
```

---

## Revision 承諾的寫法

**不要隨便承諾，承諾了就要具體。**

✅ 正確：
```
The revised appendix will include Table R1, Table R2, and Fig. R1
presented above, along with a detailed per-iteration timing breakdown.

We will incorporate the comparison between [X] and [Y] into the
main body of the revised manuscript.

To enhance clarity, we will include [specific content] in the
revised version.
```

❌ 錯誤（太隨便）：
```
We will add this in the camera-ready.
We will fix this.
We will improve the writing.
```

---

## OpenReview vs. CMT 的寫法差異

### OpenReview（ICML / NeurIPS / ICLR）

- **無字數限制** → 可以寫充分，用足夠的 evidence
- 可以用 Markdown 格式（表格、粗體）
- 可以附圖片連結（anonymous link）
- Discussion phase 可以多輪來回
- **寫多是好事**：每個 concern 都完整回應，不省字
- 可以有 Global Response（所有 reviewer 共用的回覆）

### CMT（ECCV / CVPR / ICCV）

- **5000 字元限制** → 必須極度精簡
- 致命 concern 用 60% 篇幅
- 其他 concerns 各 1-3 句
- Writing issues 合併成一句

### PDF Rebuttal（ECCV 2026 新規）

- **1 頁 PDF**（two-column）→ 滿頁正好，不要省字
- 與 OpenReview 相反：空間有限時寧可詳細展示 evidence 也不要砍

### Reviewer 健忘原則（所有平台通用）

**每段 rebuttal 必須 self-contained。** Reviewer 審完再看 rebuttal 時已不記得 paper 細節。

- 每段重述：context（我們在做什麼）→ claim（我們的論點）→ evidence（支持數據）
- Supp/appendix evidence 在第一句就提：「As already detailed in Sec. X of the supplementary material, ...」
- 不要假設 reviewer 記得任何特定 section、table、figure 的內容

---

## 從學生稿到教授稿的常見修改

學生稿最常犯的錯誤（教授必須修正）：

| 學生寫法 | 問題 | 教授改法 |
|---------|------|---------|
| "We apologize for the confusion" | 道歉 | "We appreciate the opportunity to clarify" |
| "We agree this is a weakness" | 自我否定 | "We thank the reviewer for this observation. [直接用 evidence 回應]" |
| "We acknowledge the limitation" | 承認弱點（不帶反駁） | 承認 → 但用 evidence 論證不影響 core contribution |
| "We will add this experiment" | 空洞承諾 | 具體說明做了什麼、結果是什麼 |
| "The reviewer is correct that..." | 過度附和 | "We appreciate this question. [直接進入我們的論點]" |
| 只用文字辯論，沒有數據 | 缺乏 evidence | 每個 concern 都附 table/figure/reference |
| 回覆太短（1-2 句） | 不夠重視 | 完整回應，包含 evidence + implication |
