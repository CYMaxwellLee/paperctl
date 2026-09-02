# Style Guide — 全 Section 共用寫作規範

> 本文件是所有模組的共同基礎。每個 section-specific 模組繼承此處的所有規則，不再重複。

---

## 一、品質標準

- **Academic, professional, elegant prose** — 頂會論文水準
- **前後主題一致**：¶1 的主題詞、¶2 的主題詞、¶3¶4 必須是同一個東西。寫完後從頭檢查一次
- **Specific over generic**：每句話都要有資訊量
- **數字勝過形容詞**：用 "+6.4% SR" 不用 "significantly improves"
- 避免過度使用 "novel", "significantly", "state-of-the-art"
- **慎用 "empirical"**：reviewer 會反問 theoretical justification
- **少用 "principle"**：太教條
- **不要照抄 guideline 的模板句式** — guideline 給的是結構提示，不是可以直接填空的模板
- **寫明白優先於寫漂亮**（主人 2026-09-02 對「The obstacle to reading this record is form rather than content」直說「我看不懂這一句」）：壓縮過頭的雋語句要讀者解碼，攤開寫成明白的句子
- **弱 be 動詞句型換 full lexical verb**（主人 2026-09-02 NSN 稿一輪連改四處，原話「(is 換professional)」）：「Underlying X is Y」→ stems from、「is available」→ remains／constitutes、「is the response」→ emerges from、「a deeper obstacle is that」→ lies in the lack of。能用實義動詞承載的句子，不用 be 句型掛著（cleft 等非用不可的除外）

---

## 二、硬性禁止項

| 禁止項 | 說明 | 替代方案 |
|--------|------|---------|
| **We... We... We... 連發** | 文采問題：同一句式不要過度重複（**不是數字上限**） | 被動式、nominalization、"This enables..."、"By doing X, ..." 交替 |
| **Comma + V-ing** | ❌ 「X is proposed, achieving Y」 | ✅ 拆成兩句或用 and 連接 |
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
| **句首副詞+逗號** | ❌ 「Equally, ...」「Additionally, ...」 | ✅ 副詞嵌入句中，或換成子句結構 |
| **縮寫先於全名** | ❌ 首次出現就用 ELSA | ✅ 先全名再縮寫 |
| **分號連接句子** | ❌ 禁止（FLORA methodology rewrite 明確禁止） | ✅ 句號拆開，或用連接詞 |

> ⚠️ **文采原則就寫成文采原則，不要翻譯成數字配額**（「每段最多 N 句」「>2 次」這種）。教授 2026-06-12：「不是列數字什麼的禁，這個本身就是大錯誤的方向」。同理：沒有頁數配額、沒有 ablation 行數上限、沒有 proof 行數門檻。

---

## 三、Banned Words（零容忍，全文搜尋逐一修改）

| 搜尋字串 | 替換方向 |
|---------|---------|
| `thereby` | 刪除或改寫句子結構 |
| `numerous` | 改為 "many" 或具體數字 |
| `Yet`（句首） | 改為 "However," 或 "Nevertheless,"（教授 2026-06-12：「我確實很討厭Yet放句首」） |
| `underscore`（動詞） | 改為 "highlight", "demonstrate", "emphasize"（教授 2026-06-12 同意） |
| `---` 或 ` --- `（em dash；Unicode – 轉成 `--`） | 改為逗號或重新斷句（不要用分號——分號連句也是禁的） |
| `leverage`（過度重複） | 文采：多變化，部分改為 "use"（**不是**次數限制——教授 2026-06-12） |
| `straightforward` | 聽起來居高臨下，改為 "simple" 或 "direct" |
| `significant improvement` | 改為具體數字描述 |
| `Notably,`（句首） | 刪導語，讓事實自己說話 |
| `because` | 整篇禁用 → "since" / "as" / "given that" |
| `As can be seen from` | 弱引用，表圖要當主詞 |
| `As shown in` | 弱引用，表圖要當主詞（教授 2026-06） |
| `give` / `gives` | casual → provides / yields / produces |

> ⚠️ **2026-06-12 教授裁決——以下「不禁」，不要再加回禁字表**：「It is worth noting that」「As expected,」「demonstrates the effectiveness of」「has gained significant attention」「Recently, many works」「In this paper, we」。這幾條是先前 session 自己發明寫進 lint 的，教授明示這些用法 OK／沒這種規定。同裁決：display math 哪裡都可以放（inline math 一律 `$...$`）、float 一律 `[t]` 置頂並放在第一次 mention 的那一頁、直引號必須 enforce（LaTeX）。

### ⛔ 詞表管不到的那層：register

> 主人多次強調：**register 比禁詞表更嚴。**

上面兩張是**詞表**，失效模式很明確：**不在表上就以為過關**。
2026-07-29 在 FOCUS §4.4 抓到的 `feature bleeding` 不在任何表上，掃描全過，
但它就是不對 —— 而且那個詞從學生原版一路留到定稿前才被發現。

⛔ **所以這一節做成類型，不做成詞表。** 判準從「這個字在不在表上」換成「**這個字為什麼在這裡**」。

| 類型 | 形狀 | 已抓到的例 |
|------|------|-----------|
| **擬人／生動動詞用在技術對象** | 把只有生物做得出的動作安到機制、特徵、模型身上 | `feature bleeding`（2026-07-29 §4.4） |
| **口語替代** | 該用學術語域的地方落回日常語域 | `give`／`so`／`but`（主人 2026-06 裁為 casual，見上面兩表）；`studies`／`becomes free`／`pays for`／`is already a graph`（主人 2026-09-02 NSN 稿逐句抓） |
| **誇飾** | 強度超過證據撐得住的範圍 | `resolving the longstanding tension`（見第四節⑤）；`strongest`／`any` 這類絕對詞（主人 2026-07-27 FOCUS：**加了 scope 也不行**，改從機制本身取力） |

⚠️ **右欄是「這個類型長什麼樣」的示範，⛔ 不是待搜尋的字串清單。**
把它當清單搜，等於把類型又降級回詞表，`bleeding` 那種漏法會再發生一次。

**判斷方式**：讀到一個詞覺得不對勁，先問它屬於哪一類；三類都不是，再考慮它其實可以。
⛔ 反過來（先掃表、表上沒有就放行）就是這一節要擋的做法。

---

## 四、GPT 句式偵測（五大特徵）

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

## 五、段落流動性自查

把段落中所有邏輯連接詞遮住，若剩下的句子都可以完全獨立存在，代表這段在「列舉」而非「論述」。每句話的連接應反映因果、遞進、對比，而非僅是時間順序。

---

## 六、We / Our 連發檢查

連續以 We / Our 開頭是 GPT 訊號。文采問題：句式多變化（**不是「每 N 句最多一個」的數字配額**——教授 2026-06-12），交替改用：
- "The proposed framework…"
- "This formulation…"
- "Experimental results on X indicate…"
- "Section 4 demonstrates…"

---

## 七、Claim 與框架策略（solid & strong）

> 教授 2026-06-27 親口（WACV textnav QA + conclusion 改稿）：「專家貪婪又刻薄，攤弱點只會被打。」

1. **Solid and strong，不示弱。原則：不說謊，但也不必什麼都攤給他看。**
   - 弱的 contribution 不要硬 claim novelty（會被「重組／incremental」打）→ 改賣「統一的設計／策略」這種**真且強**的框架，不賣「我們發明了 X」。
   - 必要的誠實揭露（如借用某方法的 attribution）放它**該在的地方**（method 內聯引用），不在 contributions 自曝。誠實放對位置，反而先堵掉「未揭露借用」這個更致命的攻擊。
   - **Limitations 寫不痛不癢**：只談可擴展性、泛化方向；不碰 compute／絕對分數／單一 benchmark／無 variance 等真弱點。**你寫什麼，reviewer 就打什麼。**

2. **沒實驗背書的 generality／transferability claim ＝ 送頭。**
   - 寫「applies to any…」「generalizes to…」而論文只測一個 setting → reviewer 會說「I want to see」，再以「你沒做」為由打。
   - claim 一律 **scope 在已展示的範圍**；要講貢獻廣度，改成描述「方法論／設計原則」本身（論文可自證），不承諾跨任務／跨資料集的實證泛化。

---

## 八、LaTeX 格式規範

### Cross-reference
- 一律使用 `\cref{}`，不用 `\ref{}`
- 句首使用 `\Cref{}`（大寫）
- label 命名：`fig:xxx`, `tab:xxx`, `eq:xxx`, `sec:xxx`

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
