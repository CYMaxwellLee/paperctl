# 裁決帳本（Rulings Ledger）— 教授親口裁決的完整彙整

> **用途**：Professor-Proxy Reviewer 的 ground truth。Proxy 審稿時逐條對照本帳本，
> 模擬教授會抓什麼；judge 裁決 critic findings 時以本帳本防翻案。
> **紀律**：append-only；每條附日期與原話（或忠實轉述）；只收教授 attested 的裁決
> （出處紀律，2026-06-12）。教授每次新糾正 → 立刻補一條 → Proxy 攔截率上升 →
> 教授 review 成本下降（飛輪）。
> 與各 doctrine 模組的關係：模組是「規則的體系化」，本帳本是「裁決的原始記錄」。
> 新裁決先進帳本，再視情況編進模組。

---

## 一、用詞與語域（line-edit 級，2026-07-02～04 ACML intro 實錄）

| 原文 | 改成 | 教授原話 |
|---|---|---|
| lets | permits | 「lets 太口語」 |
| let | allow | 「(太口語)」 |
| has tried | has sought | 「try 比較不專業的用詞」 |
| goes unused | remains unexploited | 「goes 太 casual」 |
| use（泛用） | exploit (as context) | 「use 換一個專業的詞」 |
| asks | requires | 「asks（requires?）」 |
| right（形容詞） | correct | 「right 太口語」 |
| a far lower bar | a substantially weaker condition | 「這整句太口語」 |
| using | incorporating | 「把 using 換個專業的字」 |
| makes（makes the waste concrete） | illustrates | 「把 make 換個專業的字」 |
| sit（sit idle） | remain | 「把 sit 換個專業的字」 |
| pull forward | advance | （口語隱喻） |
| gives way | is broken | （口語隱喻） |
| comes down to | traces to | 「conflation 換個字」+ 開頭重寫 |
| left on the table | 刪除 idiom | 「Left on the table, what table? 這邊解釋得有點 confusing」 |

**通則（2026-07-05 第一批）**：「那些所謂禁字只是我個人不喜歡的用法，不是說改 paper
要變成一個 regex 任務。我希望寫的是 Professional 專業的 ML/RL/CV Papers，寫得像個
頂級研究學者。」→ 品質 = 論證 × 精確 × 語域；lint 是地板。

## 二、論證、結構、清晰度

- **Transition 要真接**（2026-07-02，兩次）：「你這邊沒有好好 transition」「聽起來
  像是兩個 bullet item 硬貼，不像是寫專業學術文章」→ 句間補邏輯關係
  （Under this regime / Beyond this cross-block loss 型），不是塞副詞。
- **跳太快要拆句**（2026-07-02）：「不太懂你這句的意思」「可能跳太快」→ 把中間推理
  步驟寫出來，寧可多一句。
- **句內重複詞**（2026-07-02）：「你這句話兩個 already」。
- **指涉數量對齊**（2026-07-04）：「只有一個 obstacle 嗎？因為後面接 conflation」
  → 前文立兩個 gap 就寫 Both gaps。
- **機制解釋要精煉**（2026-07-03）：「意思大概有到了，但敘述解釋有點長」→ 痛點
  鮮明但敘述收緊。
- **¶1 要痛點收尾句**（2026-07-03）：「這邊沒有 conclusion sentence 點出痛點」。
- **承先啟後、所有權**（2026-07-05）：「誰知道 Speculative Pipeline Decoding 是
  我們的方法還是別人的方法」→ 方法首發必須 we-propose 級標記。
- **賣不是敘述**（2026-07-05）：「你這邊都在 Narrative 敘述方法，並不是在講我們的
  方法的 Advantages、重要的 Impact 或好處、或者 Highlights 我們的 Significance，
  為什麼我們這麼好？」
- **跨段冗餘**（2026-07-05）：「第三段和第四段有很多句子和概念重複很多都是在重新講，
  並沒有達到精鍊的目的」；¶3 本身「有點冗長」。
- **Contributions**（2026-07-05）：「最重要的是講我們帶來什麼超重要 Insights、
  Impacts、Significance，不是只是列點講一些報告數字的東西」；We 開頭一律弱，
  但句法迴避不等於達標（遮蓋測試驗收）。
- **Contributions 交棒句用冒號**（2026-07-05）：「應該要冒號吧」。

## 三、Claim 與防審策略

- **不示弱**（2026-06-27）：「專家貪婪又刻薄，攤弱點只會被打」；Limitations 寫
  不痛不癢（「不然我們寫什麼 reviewer 就打什麼」）。
- **無實驗背書的 generality = 送頭**（2026-06-27）：「會讓 reviewer 寫 I want to
  see，又說我們 paper 沒有，就完蛋」→ any dLLM → diverse dLLMs 同理。
- **Claim 要查證再寫**（2026-07-04）：「（underexplored）寫保守一點，然後 search
  一下，避免我們被戰」→ 觸發文獻偵察，發現 observation 是 prior art。
- **Observation credit 給前人**（2026-07-04 核可）：開頭 credit（Recent work
  observes that…），novelty 綁機制組合（to our knowledge, the first…）。
- **Training-free vs training-based 是不同路線**（2026-07-04）：「應該不用拿來比，
  本來 training-free 就是走 efficient 路線」→ 不硬做 head-to-head，靠定位。

## 四、格式與句法慣例（准用）

- either…or correlative（2026-07-04：「either?」→ 加）。
- 長介系詞片語開頭後加逗號（2026-07-04：「Across these methods(要逗號嗎)」→ 要）。
- because → since / as / given that 是**指定替代**，不是 dodge。
- `Specifically,` `Moreover,` `Furthermore,` 允許開句（2026-06-27）。
- 2026-06-12 全批裁決（禁字表、明示不禁清單、float [t]、直引號、inline `$...$`、
  文采≠數字配額、句數指引是幻覺）→ 見 style-guide §八，此處不重複。

## 五、系統與流程層裁決

- **出處紀律**（2026-06-12）：只有教授 attested 的才是 doctrine；code 裡的規則
  ≠ 教授規則；未 attest 的移除不合理化。
- **存 memory 沒用**（2026-06-27）：「一切都是以 paperctl 為準」。
- **禁字=地板**（2026-07-05 第一批）：見上。
- **反降維鐵則**（2026-07-05 第二批）：精神規則不可壓成表面特徵；操作化必須保留
  結果測試並以結果測試驗收；doctrine 高於任何 task brief。
- **全局觀**（2026-07-05 第二批）：「drafter 要先整個看過…要遵照要自省是否有達到
  Guideline 或專業學術寫作的精神…然後把這些重要的東西掌握才 draft」。
- **Agentic 分工**（2026-07-05 第三批）：Director / Planner / Writers / Critic /
  Judge / Verifier / Professor-Proxy 組織正式成立；「雖然這樣 Agentic Style 看似
  花費 Tokens，但我每次花很多時間和 Claude code 吵架或者糾正，其實浪費的更多。
  不如一次到位。」→ 內部迭代到位後才呈報教授。
- **Pipeline 產出先給教授看再推**（2026-07-05）：「最後給我看，然後再上傳」；
  教授逐點 line-edit 的小修則照舊改完即推（教授只看 Overleaf）。
- **ACML edit convention**（2026-07-02）：草稿期學生原文保留、\cyl 藍字接在對應
  段落下方；學生綠字 `\tjc` 是學生的更新標記，要保留與尊重（如 2026-07-05 結果
  數字 7.71×/87%/+MBPP）。

---

**Proxy 使用法**：審稿時把候選文字逐句對照本帳本一、二、四節；claim 對照三節；
給出 approve / revise 與 line-edit 級 findings（引原句、指出違反哪條、給修法）。
不確定是否構成違反時，寧可標為 openQuestion 交教授，不硬改。
