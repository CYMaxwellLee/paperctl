# 核可樣本庫（Approved Exemplars）— 教授定稿段落的正面樣本

> **用途**：Voice（最終作者）與寫手在動筆前閱讀，對齊教授核可過的節奏、語感、
> 連接方式——「寫成這個聲音」。與 rulings-ledger 互補：帳本是負樣本（他改掉什麼），
> 本庫是正樣本（他接受什麼）。
> **紀律**：只收教授逐句過目後定稿的段落；每篇附「為什麼好」的批註，指出可遷移的
> 手法（不是內容）。append-only。

---

## 樣本 1：ACML 2026 SPD intro ¶1（痛點段，2026-07-03 定稿）

> The decoding efficiency of diffusion large language models (dLLMs) hinges on how
> aggressively their parallel prediction capacity is converted into committed tokens.
> Unlike autoregressive models that generate strictly left to right, dLLMs iteratively
> refine masked positions through denoising and can predict many positions in a single
> forward pass. Recent large-scale instances such as LLaDA and Dream reach
> competitive accuracy on general language understanding, instruction following, and
> reasoning benchmarks. This parallel potential, however, remains largely unrealized
> in practice, and the bottleneck lies in how generation is currently scheduled.
> Existing decoders pair block-wise semi-autoregressive schedules with conservative
> confidence-based commit rules: a later block waits until its predecessors are
> resolved, and within the active block only the positions whose confidence clears a
> high threshold are committed, even though every masked position is predicted in the
> same forward pass. The rest are masked again and recomputed on the next pass. Under
> this regime, each pass advances only a handful of tokens, and decoding degenerates
> toward the token-by-token generation that diffusion models were designed to escape.
> The outcome is a model that, despite predicting in parallel, spends most of its
> compute re-deciding tokens it has already effectively determined. This mismatch
> between how many tokens a single forward pass could commit and how few it actually
> does is the central obstacle to fast dLLM inference.

**可遷移手法**：第一句就是主題句（efficiency hinges on X）；「This parallel
potential, however,」承接上句的 promise 再轉折；冒號帶出兩條規則的合併句（機制
解釋壓縮）；「Under this regime,」是教授親手要求的連接語；收尾兩句先 paradox
再點名痛點（The outcome is… / This mismatch … is the central obstacle）——
痛點收尾句是教授明確要求的元素。

## 樣本 2：ACML 2026 SPD intro ¶2（前人為何解不了，2026-07-04～05 定稿）

> Recent work has sought faster dLLM decoding through approximate caching,
> confidence-thresholded parallel commitment, and adaptive block schedules. Much of
> it rests on a shared observation that a prediction often stabilizes several steps
> before it crosses the commit threshold, and confidence-only commitment is therefore
> conservative. These methods act on that signal either by committing such tokens
> earlier or by deferring uncertain ones, and in both cases the predictions stay
> outside the decoding context until finalized. The caution is deliberate, as an
> unreliable prediction admitted into the context could propagate its error to every
> position that conditions on it. The cross-block utility of uncommitted predictions
> nevertheless remains unexploited, since a future-block token can become predictable
> before its preceding block resolves, while conventional block-wise decoding masks
> these positions and defers later blocks. The one pipeline that crosses block
> boundaries, D2F, obtains this ability by distilling the model to condition on
> partially denoised prefixes, and no training-free counterpart exists for frozen
> models. Beyond this cross-block loss, the same masking discards stable predictions
> within a block that have yet to clear the commit threshold, and forces the
> redundant recomputation noted above. Across these methods, an uncommitted prediction is rarely treated as more
> than a candidate to commit or discard, and two gaps open between what a model has
> already produced and what it is permitted to exploit as context, one across blocks
> and one within them.

**可遷移手法**：開頭 credit 共同 observation 給前人（防審）；「The caution is
deliberate」先替對手講理由（steelman）再用「nevertheless」轉入代價；「Beyond this
cross-block loss,」標出兩個 consequence 的層級關係；結尾把兩個 gap 收成複數
（「two gaps open… one across blocks and one within them」）為下一段的「Both gaps」
鋪路——跨段接棒在段內就準備好。

## 樣本 3：ACML 2026 SPD intro ¶3（insight 段，2026-07-05 定稿・壓縮版）

> Both gaps identified above trace to a single root cause: existing decoders treat
> two distinct properties of a prediction as one. A prediction has a readiness to be
> committed, which requires it to be reliable enough to finalize irreversibly, and a
> utility as context, which requires only that it be accurate enough to guide other
> positions. Since a prediction enters the working context only once it clears the
> commit threshold, the decoder structurally binds the second property to the first.
> The two are not equivalent. A commit is irreversible and rightly demands high
> confidence, whereas informing a neighboring position requires only that a
> prediction be approximately correct, a substantially weaker condition. Fig. 1
> illustrates the resulting waste: under a conventional schedule, many positions
> outside the active block reach high confidence well before they become eligible to
> commit, then remain idle while the decoder recomputes them from the masked state.
> Separating the two properties allows a confident-but-uncommitted prediction to
> serve as provisional context for other blocks. Under this separation, the idle
> predictions advance several blocks at once, and the serial chain that reduces dLLM
> decoding to token-by-token generation is broken. Turning this opportunity into a
> working decoder requires two components: a schedule that keeps several blocks open
> for a prediction to reach its neighbors, and a verification discipline that admits
> provisional predictions as context and still confirms them before any commit.

**可遷移手法**：開頭「Both gaps identified above」數量與指涉精確承接 ¶2；兩個
概念各給一個從句定義後，用短句「The two are not equivalent.」立節奏支點；不對稱
論證（不可逆要高信心 vs 當 context 只要大致對）是說服的承重牆；圖當主詞、冒號帶
證據；收尾句直接變成下一段的任務書（two components …）——這就是教授要的
「承先啟後」：交棒句寫在自己段裡，下一段用「To this end, we propose…」接。

## 樣本 4：ACML 2026 SPD intro ¶4 + contributions（方法段，2026-07-06 定稿）

> To this end, we propose Speculative Pipeline Decoding (SPD), a training-free,
> drop-in decoder that supplies both components at decoding time alone, without any
> change to the model. It realizes the schedule as a block-parallel pipeline that
> keeps multiple blocks active within a single forward pass, and the verification
> discipline as a draft-and-verify procedure that recycles uncommitted-but-stable
> predictions as provisional cross-block context. SPD secures the utility as context
> that the risk of error propagation previously foreclosed, while no token is
> committed unconfirmed. Fig. 2 presents the design together with its
> throughput--accuracy profile: across the LLaDA and Dream model families on GSM8K,
> Minerva MATH, and MBPP, SPD attains up to 7.71x throughput (TPS) and up to an 87%
> reduction in the number of forward evaluations (NFE) while maintaining accuracy
> comparable to strong baselines including Fast-dLLM and DSB. The contributions of
> this work are as follows:
>
> - We trace the token-by-token degeneration of dLLM decoding to the schedule's
>   conflation of a prediction's readiness to be committed with its utility as
>   context, a flaw that can be corrected at decoding time without retraining.
> - We propose SPD, which brings cross-block pipeline parallelism to frozen dLLMs.
>   To our knowledge, it is the first training-free method to combine a
>   block-parallel pipeline schedule with recycling uncommitted-but-stable
>   predictions as provisional cross-block context under a stability check.
> - Across four LLaDA and Dream dLLMs on GSM8K, Minerva MATH, and MBPP, SPD achieves
>   up to 7.71x throughput (TPS) and up to an 87% reduction in forward evaluations
>   (NFE), with accuracy comparable to Fast-dLLM and DSB and higher on several tasks.

**可遷移手法**：跨段接棒的一個好解（**非唯一解**——教授 2026-07-06：「不一定
always 要這樣寫」，Motivated by / Enlightened by 等寫法同樣可以；**學的是功能，
不是句子**）。功能拆解：連接語（指回前段目標句）＋所有權（we propose）＋最大
賣點放主句（at decoding time alone, without any change to the model），一句完成，
**不用獨立橋接短句**——三輪修訂的真正教訓是「先把連接的功能做出來」。第二句「It realizes A as …, and
B as …」把前段點名的兩個需求逐一映射到方法元件。機制只佔一句；其餘句子全在賣
（安全性、部署性、數字）。Contributions：一條一主張、一到兩句、We 開頭沒問題、
先 why 再 what 再 evidence、交棒句用冒號。

## 樣本 5：ACML 2026 SPD Related Work ¶1（RW 背景線，2026-07-06 定稿）

> Diffusion language models cast text generation as iterative denoising over
> discrete tokens, and masked diffusion has become the dominant instantiation of
> this paradigm. The paradigm has since expanded into a broad family of systems:
> open-weight models such as LLaDA and Dream address general instruction following
> and mathematical reasoning, while Gemini Diffusion, Mercury, and Seed Diffusion
> demonstrate the approach in industrial settings. Dream-Coder and DiffuCoder
> further specialize this line for code generation. Within this family, our work
> builds on masked dLLMs: the model architecture, tokenizer, and training objective
> remain unchanged, and the improvement lies entirely in inference-time decoding.

**可遷移手法（RW 文體）**：漏斗＝範式起源 → 主導變體點名（機制歸 Prelim，這裡
只定位）→ **有結構的系統版圖**（開源／工業級／特化，引用跟著被點名的系統走，
不做句尾 citation 堆）→ 「Within this family,」收到我們的定位，句尾刻意落在
「inference-time decoding」，讓下一段的「A prevalent inference strategy…」
given-new 接棒。跨 section 冗餘紀律：intro ¶1 講過的（多位置預測、LLaDA/Dream
的 accuracy claim）此處不重講；§3.1 要形式化的機制此處不預講。

---

**Voice 使用法**：動筆前讀一遍，感受句長交替（長論證句配短支點句）、連接語密度、
術語鎖定與冒號用法；寫作時以此節奏落筆。不可抄內容，只學聲音。
