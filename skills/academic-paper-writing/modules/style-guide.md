# Style Guide — 全 Section 共用寫作規範

> 本文件是所有模組的共同基礎。每個 section-specific 模組繼承此處的所有規範，不再重複。

---

## 〇、寫作的目標函數（先讀這節；禁字仍由 lint 強制，但只是地板）

> 教授 2026-07-05 定調：「那些所謂禁字只是我個人不喜歡的用法，不是說改 paper 要變成一個
> regex 任務。我希望寫的是 Professional 專業的 ML/RL/CV Papers，我們應該寫得像個頂級
> 研究學者，最高級的論文。」

**目標函數：頂會（NeurIPS / ICML / CVPR 級）最高水準的學術散文。**
禁字表（§八）只是最後一道機械閘門，擋的是教授個人不喜歡的用法；
**通過 `paperctl lint` 不代表寫得好 —— lint 是地板，不是天花板。**

品質來自三件事，重要性依序（三分法與排序是本 repo 對教授定調的操作化，非教授原話）：

1. **論證（argument）**：每句話推進論證。論文不是流水帳，是說服。
2. **精確（precision）**：術語一致、量詞有數字、claim 對得上證據。
3. **語域（register）**：動詞、名詞、慣用語都在學術書面語的頻段上。

一句話的總判準：**把這句放進該領域的 best paper 正文，違和嗎？**

> **反降維鐵則（教授 2026-07-05 第二批定調，para-pipeline ¶4 首戰事故）**：
> 精神規則不可在任何下游（task brief、pipeline prompt、checklist、subagent 指令）
> 被壓縮成表面特徵。「bullet 不以 We 開頭」不是「bullet 傳達重要 insight」；
> 「術語鎖定＋數字齊全＋句式合規」不是「在賣 significance」。事故原型：¶4 產出
> 滿足了全部機械約束，卻整段 narrative、無所有權標記、與 ¶3 大量重複——「過了
> checklist 但違反 guideline 精神」與「過了 lint 但整段口語」是同一個病，高一層。
> **凡把精神規則操作化，必須同時保留它的結果測試**（reviewer 讀完感到 significant
> 嗎？知道方法是誰的嗎？兩段重複嗎？）**並以結果測試驗收，不以表面特徵驗收。**
> 同時：**doctrine 高於任何 task brief**——brief 與 doctrine 的結構精神衝突時
> doctrine 贏，衝突本身要上報，不准默默照 brief 辦。

> 教訓（2026-07-04 ACML intro ¶3）：一整段每個字都通過 lint，教授仍逐句抓出十多處
> 口語（makes / lets / asks / sit idle / a far lower bar / pull forward / gives way）。
> 黑名單擋不住語域問題 —— 語域靠判斷，不靠字串比對。

---

## 一、學術語域（Register）：寫得像學者，不是像聊天

**核心測試：把句子唸出來。如果它出現在日常對話裡毫無違和，它的語域大概太低。**
學術散文的動詞和名詞承載技術意義；口語動詞（make, let, get, ask, sit, pull…）
承載的是社交流暢，放進論文就是鬆。

### 1. 動詞承載語域（逐動詞審計）

寫完一段，**逐個動詞問兩件事：它口語嗎？有沒有語意更精確的學術動詞？**
下表是校準樣本，**不是黑名單** —— 表外的口語動詞一樣要換，判斷靠測試，不靠比對。
未標記的列是教授 2026-07-02～04 ACML intro 的親手修正；標 ※ 的列是類推例（非教授親手改）。
⚠️ **不可 grep 替換**：每列僅在該語意成立時適用（right-hand side、the right to、
以及 `use` 作為 `utilize` 指定替代詞等場合都不適用）：

| 口語 | 學術（依語意選） |
|---|---|
| makes X concrete / makes clear | illustrates, demonstrates, establishes |
| lets / let X do | permits, allows, enables |
| asks that / asks for | requires, demands |
| gets ※ | obtains, attains, incurs（成本類）|
| sits idle | remains idle, remains unused |
| pulls / pushes X forward | advances, drives |
| gives way / falls apart | is broken, collapses, degrades |
| comes down to | reduces to, traces to, amounts to |
| throws away ※ | discards |
| ends up ※ | ultimately / eventually + 精確動詞 |
| deals with ※ | addresses, handles, accommodates |
| goes unused | remains unexploited, remains unused |
| has tried to | has sought to, has pursued |
| uses（當泛用萬能動詞時） | exploits, employs, conditions on, incorporates |
| looks at ※ | examines, investigates |
| finds out ※ | determines, identifies |
| a lot of / lots of / big / huge ※ | substantial, considerable，或直接給數字 |
| right（形容詞） | correct, accurate |

⚠️ **數學文體慣用語不是口語**，保留：「Let $x$ denote…」「It follows that…」
「We say that…」「holds / yields / admits a solution」。

⚠️ **2026-06-12 裁決明示 OK 的用法，視為已通過語域審計，不要「修」**：
「It is worth noting that」「As expected,」「demonstrates the effectiveness of」
「has gained significant attention」「Recently, many works」「In this paper, we」。
（§八的「勿再加回禁字表」只保護 lint 通道；這行保護語域判斷通道，缺一不可。）

### 2. 慣用語與隱喻（idiom）不進正文

「a far lower bar」「left on the table」「low-hanging fruit」「at the end of the day」
「the elephant in the room」—— 這些是演講與部落格的語言。改成**字面精確**的描述：

- a far lower bar → a substantially weaker condition
- left on the table → remains unexploited
- 口號式短句（"This waste is avoidable."）→ 併入論證句或給出理由

**例外：已被領域收編為術語的隱喻可以用**（bottleneck, pipeline, greedy, warm start,
catastrophic forgetting, early exit）。判準：它會出現在頂會論文的標題或 section
標題裡嗎？會 → 是術語；不會 → 是口語。

### 3. 術語一致性（elegant variation 的邊界）

- **一個概念一個名字，全文鎖定。** 同一個機制不要一下 commit、一下 finalize、
  一下 lock in —— reviewer 會以為是三個東西。
- 文采變化（同義替換）只用於**論證動詞與連接詞**（show/demonstrate/establish 可輪替），
  **不用於術語** —— reviewer 會把兩個名字讀成兩個機制（寫作學通則，非教授親口裁決）。
- 新概念第一次出現就定義（全名+縮寫），之後全文用同一個詞。
- **操作法**：把段落裡的技術名詞列出來，同物異名（cache/buffer、commit/finalize）
  合併成一個 canonical term。（2026-07-05 doctrine 實測：不給操作步驟，模型會漏抓。）

### 4. 校準例（2026-07-04 ACML ¶3 實戰，教授逐句抓出）

❌ 通過 lint 的原稿（口語）：
> The obstacle **comes down to** a single conflation: … guiding a neighboring position
> **asks** only that a prediction be approximately **right**, **a far lower bar**. …
> Fig. 1 **makes** the waste concrete: positions … **sit** idle … The opportunity is to
> **let** a confident-but-uncommitted prediction serve as … these idle predictions
> **pull** several blocks **forward** …, and the serial chain … **gives way**.

✅ 修訂（同內容，學術語域）：
> Both gaps **trace to** a single root cause: … informing a neighboring position
> **requires** only that a prediction be approximately **correct**, **a substantially
> weaker condition**. … Fig. 1 **illustrates** this waste: positions … **remain** idle …
> The remedy is to **allow** a confident-but-uncommitted prediction to serve as …
> these idle predictions **advance** several blocks at once, and the serial chain …
> **is broken**.

另注意 ❌ 版開頭的指涉錯誤：前文已立**兩個** gap，「The obstacle」單數對不上，
✅ 版改為「Both gaps」（教授 2026-07-04：「只有一個 obstacle 嗎？」）。

---

## 二、論證架構（argument, not narrative）

> 定位：寫作學通則（craft guidance），非教授逐條裁決；transition 與指涉兩條的例句
> 出自教授 2026-07-02～04 ACML intro 修正（「你這邊沒有好好 transition」「聽起來像
> 是兩個 bullet item 硬貼」「只有一個 obstacle 嗎？」）。

- **主張放主句，限定與細節放從句。** 讀者掃主句就能重建論證鏈。
- **段落 = 一個論證**：首句立論，中間句句推進，末句收束或交棒給下一段。
- **舊資訊 → 新資訊**：句子開頭接前句已建立的內容，句尾放新資訊，段落自然向前流。
- **narrative vs argument**：不寫「我們做了 A，然後 B」；寫「因為 X，所以設計 A；A 蘊含 B」。
  方法描述也要有因果 —— 每個設計決定都回答「為什麼」。
- **段落流動性自查**：把段落中所有邏輯連接詞遮住，若剩下的句子都可以完全獨立存在，
  代表這段在「列舉」而非「論述」。每句話的連接應反映因果、遞進、對比，而非僅是時間順序。
- **transition 是論證關係，不是填充詞**：兩句之間跳太快，補的是關係
  （Under this regime / Beyond this cross-block loss / 承接主詞），不是塞一個副詞。
  教授 2026-06-27 允許的 `Specifically,`/`Moreover,`/`Furthermore,` 在關係確為
  遞進/具體化時是正當 transition —— 本條擋的是用副詞掩蓋缺失的邏輯關係，不是禁這三個詞。
- **連接語復權條款（教授 2026-07-06：「感覺你一直有 transition 很差的問題…你需要
  從 high level 檢討」）**：句首副詞禁令**不及於連接性片語**。以下是正當且被鼓勵的
  連接手段：`To this end,`、`To do so,`、`Under this regime,`、`In this way,`、
  `Beyond X,`、`Building on this observation,`、`Guided by this insight,`、
  purpose 前置子句、主詞承接前句賓語。教授多次**主動要求加連接語**（「例如加一個
  『在這種情況下』」「例如 unfortunately」）——禁令的寒蟬效應導致無連接詞的斷句流
  （「兩個 bullet item 硬貼」），是實際發生過的系統性錯誤，不可重演。
- **鏈讀檢查（chain read，強制）**：任何合成或修改之後，把每一對相鄰句連讀，
  每一對必須有明確連結——連接語、或主詞承接前句的內容（given-new）、或無歧義回指。
  判準：**抽掉或調換某句而讀者不會察覺，鏈就是斷的。** 合成式寫作（多稿取句）與
  點修（只改被指的那句）是鏈斷的兩大來源，改完必須連前後句重讀。
- **慣用句式優先（2026-07-06「To this end」教訓）**：銜接與結構性動作先用學界的
  標準句式（To this end, we propose… / In this paper… / It follows that… /
  We evaluate X on Y），標準句式不夠用才造新句。實證：¶4 開頭連修三輪，最後被
  教授接受的正是學生原稿本來就有的「To this end, we propose」。拆學生稿之前，
  先確認沒有把正確的傳統骨架一起丟掉。
- **邊界優先審查**：教授的糾正高度集中在段落開頭、段落結尾、跨段句對；審查預算
  （Proxy、鏈讀、自檢）優先花在這些區，段落中間次之。
- **指涉對齊**：句首的 The X / This / These 必須與前文建立的實體在**身分與數量**上
  對得上 —— 前文立了兩個 gap，就寫 Both gaps，不寫 The obstacle（教授 2026-07-04）。
- **壓縮審計**：一句話若要求讀者自行補上未寫出的推理步驟，拆成兩句把中間步驟寫出來
  （教授 2026-07-02：「不太懂你這句的意思」「可能跳太快」）。寧可多一句，不留斷層。

---

## 三、品質標準

- **Academic, professional, elegant prose** — 頂會論文水準
- **前後主題一致**：¶1 的主題詞、¶2 的主題詞、¶3¶4 必須是同一個東西。寫完後從頭檢查一次
- **Specific over generic**：每句話都要有資訊量
- **數字勝過形容詞**：用 "+6.4% SR" 不用 "significantly improves"
- 避免過度使用 "novel", "significantly", "state-of-the-art"
- **慎用 "empirical"**：reviewer 會反問 theoretical justification
- **少用 "principle"**：太教條
- **不要照抄 guideline 的模板句式** — guideline 給的是結構提示，不是可以直接填空的模板

---

## 四、三遍修訂協議（任何 model 照做都能達標）

寫完任何段落，依序做三遍。**順序不可反** —— 先跑 lint 會誤以為「過了就好」。

**Pass 1 — 論證遍**
逐句問：「這句推進了什麼論證？」不推進就刪或併。
段落是否只有一個論證？claim 是否超出證據（見 §五）？
transition 是否反映真實的邏輯關係？指涉是否對齊（The X / This 與前文實體的
身分數量對得上）？有沒有跳太快的句子（讀者得自行腦補推理步驟 → 拆開寫）？
⚠️ 刪句紀律：「不推進就刪」只適用於自己剛寫的草稿；動學生或既有正文時，
改為標記並徵求同意（見 editing-discipline）。

**Pass 2 — 語域遍**
逐句三個審計：
- **動詞審計**：每個動詞 —— 口語嗎？有更精確的學術動詞嗎？（§一.1 表是校準樣本）
- **慣用語審計**：有隱喻/idiom 嗎？是領域術語（bottleneck/pipeline）還是口語
  （a lower bar/gives way）？口語 → 改字面精確。
- **術語審計**：同一概念全文同一個詞？（列出技術名詞，同物異名合併。）
- **重複詞審計**：同一句內或相鄰句不重複同一個非術語詞
  （教授 2026-07-04：「你這句話兩個 already」）。文采原則，無數字配額。
快篩：整段唸出來，聽起來像對話的句子逐句修。
（2026-06-12 明示 OK 的六個用法視為已通過語域審計，見 §一.1 下方清單。）

**Pass 3 — 機械遍**
實際執行 `paperctl lint --paper <name>`（沒有 conference.json 的 repo：
拿 §八清單 grep）。**必須真的跑、看輸出** —— 不准沒跑就寫「已檢查無違規」
（2026-07-05 doctrine 實測：模型自稱 verified no ", so"，而違規就在最後一句；
自我宣稱不可信，只有工具輸出算數）。這擋的是教授個人禁字（§八），
是最後一道門，不是品質標準。

---

## 五、Claim 與框架策略（solid & strong）

> 教授 2026-06-27 親口（WACV textnav QA + conclusion 改稿）：「專家貪婪又刻薄，攤弱點只會被打。」

1. **Solid and strong，不示弱。原則：不說謊，但也不必什麼都攤給他看。**
   - 弱的 contribution 不要硬 claim novelty（會被「重組／incremental」打）→ 改賣「統一的設計／策略」這種**真且強**的框架，不賣「我們發明了 X」。
   - 必要的誠實揭露（如借用某方法的 attribution）放它**該在的地方**（method 內聯引用），不在 contributions 自曝。誠實放對位置，反而先堵掉「未揭露借用」這個更致命的攻擊。
   - **Limitations 寫不痛不癢**：只談可擴展性、泛化方向；不碰 compute／絕對分數／單一 benchmark／無 variance 等真弱點。**你寫什麼，reviewer 就打什麼。**

2. **沒實驗背書的 generality／transferability claim ＝ 送頭。**
   - 寫「applies to any…」「generalizes to…」而論文只測一個 setting → reviewer 會說「I want to see」，再以「你沒做」為由打。
   - claim 一律 **scope 在已展示的範圍**；要講貢獻廣度，改成描述「方法論／設計原則」本身（論文可自證），不承諾跨任務／跨資料集的實證泛化。

3. **Observation 是誰的就是誰的**（2026-07-04 ACML 文獻偵察教訓）：
   核心 observation 若前人已發表，開頭就 credit 給前人（「Recent work observes that…」），
   novelty 綁在**機制組合**上（"to our knowledge, the first training-free method that…"）。
   把已知 observation 當自家 insight 賣，是 novelty reject 的直達車。

---

## 六、GPT 句式偵測（五大特徵）

### ① Comma + V-ing
```
❌  We train the model on five benchmarks, achieving SOTA.
✅  Training on five benchmarks, the model achieves SOTA.（或拆成兩句）
```

### ② Meta-announcement（"Three properties / four components..."）
```
❌  Three properties of X follow from its formulation. Property 1: …
✅  直接用邏輯連接詞融入 prose
```

### ③ Application 枚舉式 opener
```
❌  X is fundamental for applications ranging from A and B to C.
✅  X addresses the core tension between P and Q, which A, B, and C all require.
```

### ④ 自問自答
```
❌  How can we address this? We propose…
✅  直接說方案
```

### ⑤ 誇大結論句
```
❌  resolving the longstanding tension between X and Y
✅  說清楚機制為何有效，不用誇大
```

---

## 七、We / Our 連發檢查

連續以 We / Our 開頭是 GPT 訊號。文采問題：句式多變化（**不是「每 N 句最多一個」的數字配額**——教授 2026-06-12），交替改用：
- "The proposed framework…"
- "This formulation…"
- "Experimental results on X indicate…"
- "Section 4 demonstrates…"

---

## 八、教授個人禁字與禁式（`paperctl lint` 機械強制 — 必要非充分）

> 定位（教授 2026-07-05）：以下是教授個人不喜歡的用法，由 lint 當最後一道門機械擋下。
> **它們不定義品質**；語域與論證問題（§一/§二）lint 抓不到，靠 §四 的前兩遍。
> **不要再往 lint 加字串**來解決語域問題 —— 那是判斷題，不是 regex 題。

### 硬性禁止項（整篇適用——教授 2026-06-12：「general 的精神必須共同整篇遵守」）

| 禁止項 | 說明 | 替代方案 |
|--------|------|---------|
| **We... We... We... 連發** | 文采問題：同一句式不要過度重複（**不是數字上限**） | 被動式、nominalization、"This enables..."、"By doing X, ..." 交替 |
| **Comma + V-ing** | ❌ 「X is proposed, achieving Y」。**無語意例外**：result clause「, yielding X」一樣禁（2026-07-05 實測：模型會自己發明「result clause 可以」的例外） | ✅ 拆成兩句、改「which + 動詞」、或收進主句 |
| **Em-dash（—）** | 禁止 | 用句號拆句或逗號 |
| **", yet"** | ⚠️ 很不 prefer（教授 2026-06-12：「不喜歡yet，偶爾就算了」；lint 以 warn 提示，句首 Yet 仍是 fail） | ✅ 「Although X works, it fails」 |
| **"; however,"** | ❌ 分號 + however | ✅ 「X works. However, Y fails.」 |
| **小括號補充** | ❌ 「X (which is important for Y)」 | ✅ 逗號子句或獨立句 |
| **but** | ❌ 禁止（教授 2026-06：casual 用詞整篇禁） | ✅ however / although / while / nevertheless |
| **So** | ❌ 太 casual | ✅ therefore / thus / accordingly / as a result |
| **give / gives** | ❌ casual（教授 2026-06：「give等」） | ✅ provides / yields / produces |
| **because** | ❌ 整篇禁用（教授 2026-06-12：「整篇我都不想because」，不限句首） | ✅ 「Since X, ...」「As X, ...」「Given that X, ...」 |
| **自問自答 / 反問句** | ❌ 「How can we address this?」 | ✅ 陳述句或直接給答案 |
| **However 連用** | 文采問題：同一轉折詞不要過度重複（**不是次數上限**） | ✅ 交替 nevertheless / nonetheless / still / in contrast |
| **句首副詞+逗號** | ❌ 「Equally, ...」「Additionally, ...」 | ✅ 副詞嵌入句中，或換成子句結構。例外允許：`Specifically,`、`Moreover,`、`Furthermore,`（教授 2026-06-27 裁定） |
| **縮寫先於全名** | ❌ 首次出現就用 ELSA | ✅ 先全名再縮寫 |
| **分號連接句子** | ❌ 禁止（FLORA methodology rewrite 明確禁止） | ✅ 句號拆開，或用連接詞 |

> ⚠️ **文采原則就寫成文采原則，不要翻譯成數字配額**（「每段最多 N 句」「>2 次」這種）。教授 2026-06-12：「不是列數字什麼的禁，這個本身就是大錯誤的方向」。同理：沒有頁數配額、沒有 ablation 行數上限、沒有 proof 行數門檻。

### Banned Words（lint 全文搜尋）

| 搜尋字串 | 替換方向 |
|---------|---------|
| `thereby` | 刪除或改寫句子結構 |
| `numerous` | 改為 "many" 或具體數字 |
| `Yet`（句首） | 改為 "However," 或 "Nevertheless,"（教授 2026-06-12：「我確實很討厭Yet放句首」） |
| `underscore`（動詞） | 改為 "highlight", "demonstrate", "emphasize"（教授 2026-06-12 同意） |
| `---` 或 ` --- `（em dash；Unicode – 轉成 `--`） | 改為逗號或重新斷句（不要用分號——分號連句也是禁的） |
| `utilize` | 改為 "use"，或依語意選更精確動詞（exploit / employ / incorporate，見 §一.1） |
| `leverage`（過度重複） | 文采：多變化，部分改為 "use" 或更精確動詞（見 §一.1）（**不是**次數限制——教授 2026-06-12） |
| `straightforward` | 聽起來居高臨下，改為 "simple" 或 "direct" |
| `significant improvement` | 改為具體數字描述 |
| `Notably,`（句首） | 刪導語，讓事實自己說話 |
| `because` | 整篇禁用 → "since" / "as" / "given that" |
| `As can be seen from` | 弱引用，表圖要當主詞 |
| `As shown in` | 弱引用，表圖要當主詞（教授 2026-06） |
| `give` / `gives` | casual → provides / yields / produces |

> ⚠️ **2026-06-12 教授裁決——以下「不禁」，不要再加回禁字表**：「It is worth noting that」「As expected,」「demonstrates the effectiveness of」「has gained significant attention」「Recently, many works」「In this paper, we」。這幾條是先前 session 自己發明寫進 lint 的，教授明示這些用法 OK／沒這種規定。同裁決：display math 哪裡都可以放（inline math 一律 `$...$`）、float 一律 `[t]` 置頂並放在第一次 mention 的那一頁、直引號必須 enforce（LaTeX）。

---

## 九、LaTeX 格式規範

### Cross-reference
- 一律使用 `\cref{}`，不用 `\ref{}`
- 句首使用 `\Cref{}`（大寫）
- label 命名：`fig:xxx`, `tab:xxx`, `eq:xxx`, `sec:xxx`
- （無 cleveref 的模板，如 SAGA / jmlr.cls：維持 `\ref`，lint 自動跳過）

### Figure / Table
- 浮動位置一律 `[t]`，不用 `[b]` 或 `[h]`
- 放在第一次被 `\cref` 引用的位置附近
- Caption 必須 self-contained
- 正文不描述 figure layout（left/right panel），那是 caption 的工作

### 引號
- 使用 LaTeX 引號：` ``quoted text'' `，不用 `"quoted text"`

### 標記慣例
- 新寫 / 改寫內容用 `\cyl{...}` 包裹（藍字）
- 不刪除學生原文，要替換就 comment 掉：
  ```latex
  % [Student original]
  % Old text here...

  \cyl{New text here...}
  ```

### 臨時標記
- `\cyl{}`、`\todo{}`、`\textcolor{red}{}` — submission 前全部清除
- 不確定的數字用 `\textcolor{red}{\textbf{XX.X\%}}` placeholder
