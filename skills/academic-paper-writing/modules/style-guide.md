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
| `utilize` | 改為 "use" |
| `leverage`（過度重複） | 文采：多變化，部分改為 "use"（**不是**次數限制——教授 2026-06-12） |
| `straightforward` | 聽起來居高臨下，改為 "simple" 或 "direct" |
| `significant improvement` | 改為具體數字描述 |
| `Notably,`（句首） | 刪導語，讓事實自己說話 |
| `because` | 整篇禁用 → "since" / "as" / "given that" |
| `As can be seen from` | 弱引用，表圖要當主詞 |
| `As shown in` | 弱引用，表圖要當主詞（教授 2026-06） |
| `give` / `gives` | casual → provides / yields / produces |

> ⚠️ **2026-06-12 教授裁決——以下「不禁」，不要再加回禁字表**：「It is worth noting that」「As expected,」「demonstrates the effectiveness of」「has gained significant attention」「Recently, many works」「In this paper, we」。這幾條是先前 session 自己發明寫進 lint 的，教授明示這些用法 OK／沒這種規定。同裁決：display math 哪裡都可以放（inline math 一律 `$...$`）、float 一律 `[t]` 置頂並放在第一次 mention 的那一頁、直引號必須 enforce（LaTeX）。

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

## 七、LaTeX 格式規範

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
