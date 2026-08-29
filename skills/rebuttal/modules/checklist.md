# Rebuttal Submission Checklist

> 提交前的最終確認。每一項都必須 check。

---

## 策略層面

```
[ ] 所有 reviewer 都有回覆（包括高分 reviewer）
[ ] 低分 reviewer 的致命 concern 都已用 evidence 正面回應
[ ] 每位 reviewer 都有感謝開頭（且各自略有不同）
[ ] Response plan 的每一條都已在回覆中落地
```

## 內容層面

```
[ ] 每條回覆都有 acknowledge → evidence → implication 的結構
[ ] 新實驗結果都有 interpretation（不只是丟表格）
[ ] 所有 placeholder（[X]%, [Y]%）都已填入真實數字
[ ] 所有 anonymous links 都可以正常訪問
[ ] 引用的 Section / Line 號碼與原文一致
[ ] 承諾在 revision 中做的事情列表明確且可執行
[ ] **⛔ 全文無 [TODO]、無空表格、無 [training in progress] 那類佔位**
[ ] **跨份數字交叉核**（同一個量在多份 / 多張表出現時必須一致；protocol 不同導致的不同數字要在 caption 標明）
[ ] **表格 average 欄自己加得出來**（加不出來時要說明是 per-task 還是 per-suite 平均，reviewer 會自己加）
```

### 未完成的實驗怎麼呈現（主人 2026-07-28 裁示）

跑不完的對照**不要留在表格裡當空格**，移出表格、改寫成表下一段散文：

```
❌  | + Direct correction head (matched cap.) |  [training in progress]  |
    | + Score-matching energy head           |  [training in progress]  |

✅  （表格只留跑完的列，下方接：）
    Two further controls are training and will be posted during the discussion
    period: a matched-capacity direct correction head, which isolates the energy
    parameterization from capacity, and a score-matching head, which isolates the
    training objective. The completed rows already establish the mechanism-level
    result: [已完成的結論].
```

誠實度完全相同，**觀感差很多**。表格是拿來掃的，空格讀起來是「沒做完」；同樣的資訊寫成散文，讀起來是「有時程的計畫」。
先講兩個對照各自要隔離什麼變因（顯示知道自己在測什麼），再把重心拉回已完成的結論。

### 字數上限要按 bytes 檢查

OpenReview 的 10000 字元上限，**含數學符號時要用 UTF-8 bytes 驗**。
實測：一份砍到 9990 字元、以為過了，實際是 **10003 bytes**——文中 6 個 `−`（U+2212）各佔 3 bytes。
`τ` `×` `Δ` `≈` 同理。餘裕不足時把它們正規化成 ASCII；餘裕充足（>1000）就保留符號，不要為了保險犧牲可讀性。

## 語言層面

```
[ ] 無 "The reviewer is mistaken" 類對抗性語言
[ ] 無 "constructive feedback" 類模板語言
[ ] 無 Comma + V-ing
[ ] 無 Em-dash（—）
[ ] 無 We/Our 連發（文采：句式多變化，不是數字上限——教授 2026-06-12）
[ ] 無 Banned words（thereby, numerous, etc.）
[ ] Tone 與 reviewer 分數匹配（低分 → 最謙和，高分 → 感謝 + 補充）
```

## 格式層面

```
[ ] 平台格式正確（OpenReview: Markdown / CMT: plain text）
[ ] 字數/字元在限制內（CMT: 5000 字元）
[ ] 表格在平台上正確渲染（提交前預覽）
[ ] LaTeX 數學公式正確渲染（如果平台支持）
[ ] 教授/學生的回覆有清楚的視覺區分
```

## Cross-check

```
[ ] 回覆中引用的數字與原文 Table/Figure 一致
[ ] 回覆中承諾的改進與 revision plan 一致
[ ] 不同 reviewer 的回覆之間無矛盾
[ ] Cross-reference 其他 reviewer 的回覆時，引用正確
```

---

## 提交前最後 5 分鐘

1. 通讀一遍所有回覆，確認 tone 一致
2. 檢查所有 anonymous links 是否可訪問
3. 檢查所有數字 placeholder 是否已填
4. 預覽 formatting（OpenReview 有預覽功能）
5. 深呼吸，提交


---

## 兩輪制（rebuttal＋revised manuscript）追加檢查（2026-08-29）

- [ ] **Alignment matrix（腳本驗證，不用肉眼）**：rebuttal 引用的每個 Sec./Tab./Fig./Eq./Prop.
      逐項對主文 `main.aux` 的 `\newlabel` 實際編號；Supp 的字母（A-G）與小節（E.2 等）
      對 supp 編譯後的 pdftotext。一項不合就是事故。
- [ ] **禁用行號引用**：rebuttal 不寫 L484-489 型行號（修訂會漂移）→ 用 Sec. 編號。
      修訂若需插入新 section，插在**尾部**（如 Related Work 放實驗後、Conclusion 前），
      既有 Sec./Eq./Tab. 編號全數保住，rebuttal 引用不炸。
- [ ] **契約兌現**：rebuttal 每句 "the revised X" 在修訂稿裡真的存在（GOAT 旗標型、
      新 section 型）；tex 源碼的 `% TODO(改主文時)` 清單全數清空。
- [ ] **上傳後下載回驗**：從 OpenReview 把三個檔案抓回來，驗頁數、#ID、匿名、問號、
      關鍵標記（最新一批修改的特徵字串）——md5 與本地不同沒關係（Overleaf 重編譯），
      內容特徵必須全中。
- [ ] **官方規則逐字再查**（每會每年）：頁限含不含 references（WACV：正文 8 頁不含 refs、
      「Additional pages containing only cited references are allowed」；rebuttal 1 頁**含** refs）、
      same-reviewers 條款、rebuttal 的 highlight 義務。
