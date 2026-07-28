# Cohesion Diagnostics — 段落內部接縫檢查

> 繼承 `style-guide.md` 的所有規範。本模組專注於**句與句之間接不接得起來**這一層。
>
> 分工：`style-guide.md` 管**詞與句式**（禁用詞、GPT 句型、弱引用），各 section 模組管**每段該放什麼**（結構）。
> 本模組管的是剩下那一層 —— **每個字都合規、每段的內容也都該在那裡，可是讀起來接不上。**

---

## 什麼時候用

- 改寫完一段之後
- 整節 line-edit 的時候
- 主人說「這裡讀起來怪／不順／接不太上」的時候

主人 2026-07-28（FOCUS §3.2）：「我感覺下面開始**因果關係接不太順不太好讀**」。
禁用詞掃描全過、每句都合規，問題仍在，因為病灶不在字的層級。

---

## 六個定位問句

每一問都對著**特定的字**問。這些問句只負責**定位**；找到位置之後仍要整段讀才知道怎麼接。

⛔ **不要把它們變成掃字表。** 定位可以機械，判斷必須讀。

---

### 1. 對比詞問「相對於什麼」

**觸發字**：`differently` `nonetheless` `instead` `by contrast` `in contrast` `whereas` `unlike` `however`

**檢查**：找出它的對照項，然後確認**對照項的主詞跟本句主詞是不是同一個範疇**。
不同範疇 → 對比懸空，讀者得自己補一次換算。

**實例**（FOCUS §3.2，2026-07-28）

```
❌  Rewording, reweighting, or reordering the prompt tokens reaches A only through
    the text encoder ...
    Modulation applied after the encoder, directly on the pre-softmax logits,
    behaves differently.
```
前句主詞是「改 prompt 這件事」，後句主詞是「modulation」。一個是動作、一個是機制，
`differently` 沒有對齊的對照面。

```
✅  An edit to the prompt reaches the logit matrix A only through the text encoder ...
    An edit to the logits themselves is subject to neither limitation.
```
兩句都是 `An edit to X`，軸對齊了，而且 `neither limitation` 直接回指前句列出的兩個限制，
不需要讀者自己找。

> 同一判準已存在於 `skills/rebuttal/modules/style-guide.md`（「兩個 parallel 句子要有 transition」，
> 主人原話「缺個 transition?」）。那條長期只活在 rebuttal skill，未 propagate 到論文寫作，
> 於 2026-07-28 補進本模組。

---

### 2. 代名詞問「指誰」

**觸發字**：`it` `its` `they` `their` `those` `this` `these`

**檢查**：從代名詞往回找**最近的**名詞。如果最近的那個不是你要指的，接縫就斷了 ——
讀者是照距離解讀的，不是照作者的意圖。

**實例**（FOCUS Intro ¶2，2026-07-28）

```
❌  DiT-based editors such as VACE and IMAGEdit remove those generation-side limits,
    and Section 2 surveys both lines together with the training-based alternatives.
    Their reliance on a single global cross-attention nonetheless keeps ...
```
`Their` 要指 DiT-based editors，但中間插了一句，最近的先行詞變成 Section 2。

```
✅  DiT-based editors such as VACE and IMAGEdit remove those generation-side limits.
    Their reliance on a single global cross-attention nonetheless keeps ...
    （survey 那句移到段末）
```

**主人當場問法**（2026-07-28，§3.2）：「It **指誰**」。同一次還問了
「Fig. 1 的 objects **指誰**」—— 正文寫 `object A` / `object B`，但圖上沒有這兩個標註，
讀者照著去找會找不到。**指涉不只對文字，也對圖。**

---

### 3. 數量詞問「幾個」

**觸發字**：`both` `the two` `all three` `either`

**檢查**：回去數前面實際列了幾個。

**實例**（FOCUS Intro ¶1，2026-07-28）

```
❌  ... semantic interference ... feature leakage ... temporal drift.
    Fig. 1 exhibits both failure modes within a single sequence.
```
前面列了三個，`both` 指哪兩個沒交代。

```
✅  Fig. 1 exhibits leakage and drift within a single sequence.
```

同篇 ¶3 的處理方式可以直接抄：`both symptoms in Fig. 1: edits that fail to stay within
their intended object, and appearance that drifts once objects move or overlap`
—— 用冒號當場展開，`both` 就不再是懸的。

---

### 4. 因果詞問「中間漏了嗎」

**觸發字**：`therefore` `thus` `accordingly` `hence` `it follows that`

**檢查**：把前提跟結論並排，看能不能**一步**走到。走不到就是跳步。

**實例**（FOCUS §3.2，2026-07-28）

```
❌  Adding a bias ... raises that pair's weight monotonically, lowers the remaining
    weights of the same row monotonically, and leaves every other query untouched.
    Per-object spatial control therefore becomes available at the logit level.
```
從「逐格單調可控」到「per-object control 可用」中間少一步：為什麼單調可控就等於
per-object 控制。

```
✅  ... and leaves every other query untouched, which is precisely the per-object,
    per-query control that the three requirements demand.
    The logit level therefore admits a form of spatial control that ...
```
補上的那一步順便把 §3.1 的三個 requirement 扣回來。

---

### 5. 插入句問「它切開了誰」

**觸發**：任何夾在主句中間的子句 —— 尤其是 cross-reference（`Section 2 surveys ...`）、
補充說明、次要限定。

**檢查**：看它是不是把**一組對照**或**一個代名詞跟它的先行詞**劈開了。是的話搬走，
通常搬到段末。

次要資訊落在 punch line 之後不會削弱 punch line，punch line 已經打完了；
落在對照中間卻會讓對照失效。

---

### 6. 同一個「為什麼」問「講第幾次」

**檢查**：一篇論文裡，同一個病因只該給一次，給在該給的地方。
前面若已經給過一個不同的歸因，讀者會以為中途換了說法。

**實例**（FOCUS Intro，2026-07-28）

```
❌  ¶1: Their coupling originates in prompt-to-region ambiguity ...
    ¶3: The failure belongs to the normalization rather than to the weights that feed it
```
¶1 把病因歸給 prompt 層，¶3 歸給架構層。而且 ¶1 搶走了 ¶3 的戲 ——
讀者在 ¶1 就以為知道原因，¶3 的 insight 反而讀起來像重複。

```
✅  ¶1 只描述現象（沒綁上 → 互相干擾 → 邊界洩漏 → 累積成 drift），
    結尾留鉤子：`the coupling has to be addressed at its source`
    ¶3 接住鉤子：`That source admits a structural explanation rather than an empirical one.`
```

> `introduction.md` 的四段分工（¶1 痛點 / ¶3 insight）其實已經隱含這條規則，
> 本模組把它寫成可檢查的形式。
> 副作用：`originates` 這個字整個 intro 只出現一次，出現在對的地方。

---

### 7. 指向圖表時問「圖上真的有嗎」

**觸發**：正文寫 `\Cref{fig:x} shows / illustrates / visualizes …`、或提到圖上的任何標註。

**檢查**：**開圖看**。不要用 caption 代替看圖，也不要用正文代替看圖。

2026-07-28 同一天栽兩次：

- 正文寫 `a segment describing object~A activates … over object~B` —— 圖上根本沒有 A、B 這兩個標註，
  讀者照著找會找不到。（主人當場問「Fig. 1 的 objects 指誰」）
- 正文與 caption 都稱該模組為 **Region-Guided Cross-Attention Rectification** ——
  架構圖上那個框的標題卻是 **Additive Modulation**（那是後面小節才會講的東西）。
  等於把後面的招牌掛在前面的架構圖上。

**兩個方向都要查**：
① 正文提到的標註，圖上有沒有；② 圖上的標註，正文用的是不是同一個詞。
順帶檢查同一組概念在**多張圖之間**是否一致（同一個現象在 teaser 叫 A、在架構圖叫 B，就是缺口）。

> 這條嚴格說是 evidence chain 不是 cohesion，但病灶相同：**接縫斷在讀者要跨越的地方**，
> 而且用機械掃描抓不到——caption 是文字、圖是圖，只有開圖才看得見。

---

## 收尾：一段改完之後

把該段所有邏輯連接詞遮住讀一次（`style-guide.md` 第五節）。
剩下的句子若都能獨立存在，這段是在**列舉**而非**論述**。
本模組的六問是那個自查的展開版：不只問「有沒有連接」，而是問**連接的兩邊站不站在同一個軸上**。

---

## 與其他模組的關係

| 模組 | 管什麼 | 例 |
|------|--------|-----|
| `style-guide.md` | 詞與句式 | 禁用詞、comma+V-ing、弱引用 |
| `introduction.md` / `preliminary-methodology.md` / `experimental-results.md` | 每段該放什麼 | ¶1 痛點、¶3 insight、§3.2 是 intellectual core |
| **本模組** | **句與句怎麼接** | 對比軸、指涉、跳步、插入句 |

三層獨立。字全合規、結構全對，仍可能整段讀不順 —— 那就是本模組要抓的。
