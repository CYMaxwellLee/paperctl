# Introduction 寫作模組

> 繼承 `style-guide.md` 的所有規範。本模組專注於 §1 Introduction 的結構和寫法。

---

## 動筆前：全文盤點（先讀再寫）

在動筆之前，**先仔細讀完所有現有素材**（.tex、Google Doc、rebuttal.tex、figures/tables）。

讀完後，先產出一份 **Big Picture 摘要**：
1. 這篇論文在解什麼問題？
2. 核心方法是什麼？（一句話）
3. 主要實驗結果和亮點數字
4. 目前 Introduction 的狀態（有/沒有、寫到哪、品質如何）
5. 有哪些可用的 Figure（尤其是 teaser）
6. 寫作上的明顯問題或缺口

**等確認 Big Picture 後，才進入寫作。**

---

## Introduction 結構：嚴格四段

**四段，每段各自是一個完整 paragraph（不切子段、不加 subheading、不在段內換行分段）。**

邏輯鏈：¶1 痛點 → ¶2 前人為何解不了 → ¶3 我們的 insight/motivation + teaser → ¶4 具體做法 + findings + contributions。

---

### ¶1 — 破題：問題 + 重要性 + 痛點

**第一句話定調整篇論文的主題。** 必須精準對應本文的核心問題。

- 簡短說明為什麼這個問題重要
- **重頭戲是痛點**：痛點是 ¶1 的主題重心（教授 2026-06-12：是主題沒錯，但**沒有**佔多少 % 的硬性規定）。不是泛泛說 "it is challenging"，而是具體拆解 technical challenges
- **列完 challenges 後要有一句收尾**，把痛點收攏回來

**自我檢查**：
- [ ] 第一句主題詞與全文一致？
- [ ] 痛點是否是這段的主題重心？
- [ ] 痛點是否具體到 reviewer 能感受到棘手？
- [ ] 是否有收尾句？
- [ ] 一個不中斷的連續段落？

**❌ 常見錯誤**：
- 第一句破題太窄或太偏
- 痛點輕描淡寫，大部分篇幅在鋪陳背景
- 結尾句為了引出方法而硬造需求（"demands a unified architecture that..."）

---

### ¶2 — 前人方法為何無法解決 ¶1 的問題

**唯一功能：論證 ¶1 的痛點，現有方法解不了。**

核心原則：**每一句都必須扣著 ¶1 的痛點**。提到前人方法是為了說它失敗了，不是為了介紹它。

**語氣必須 soft**：
- ❌ 「No existing method addresses ...」→ 太 strong
- ❌ 「Existing pipelines ignore ...」→ "ignore" 太重
- ✅ 「Few existing methods jointly address ...」「This aspect remains underexplored in ...」

**正確寫法的結構**：
- 按 ¶1 提出的 challenges 來組織（不是按方法類別）
- 每提一個方法，描述做法點到為止，重心放在講它為什麼解不了 ¶1 的痛點（沒有句數指引——教授 2026-06-12：「我都沒什麼句數指引」）
- 結尾自然形成 gap

**自我檢查**：
- [ ] 每個前人方法都扣著 ¶1 的某個 challenge？
- [ ] 批評語氣 soft？
- [ ] 沒有花過多篇幅描述任何單一方法的做法？
- [ ] 結尾自然形成 gap statement？
- [ ] 主題詞與 ¶1 一致？

**❌ 最常見致命錯誤**：
- 寫成 Related Work 的縮寫版
- ¶1 和 ¶2 的主題詞不一致

---

### ¶3 — Motivation：核心觀察 / Insight + Teaser Figure

**這段只講 motivation。不講方法。方法名稱不出現在這段。**

回答一個問題：**為什麼我們相信這個問題可以被更好地解決？我們看到了什麼別人沒看到的？**

- 好的 motivation：揭示一個被忽略的結構性問題、一個未被利用的資訊來源、一個反直覺的現象
- **Teaser Figure 在這裡引入**

**⚠️ Teaser ≠ 架構圖。** Teaser 要一眼引人入勝：問題的視覺化、failure case 對比、motivation 的直覺展示。

**⚠️ ¶3 是「賣點的前奏」。** 判斷標準：如果把 ¶3 的 insight 跟同領域論文互換，能不能互換？如果可以，就太 generic。

**自我檢查**：
- [ ] Insight 是否有深度？
- [ ] Insight 是否 specific to 這篇論文？
- [ ] 方法名稱是否完全沒有出現？
- [ ] Teaser 引用只是強化 argument，沒有描述圖的 layout？

---

### ¶4 — 方法概述 + Key Findings + Contributions

分成**散文部分 + bullets 部分**。

**散文部分**：
- 承接 ¶3 的 motivation，自然帶出方法
- **方法名稱首次完整出現**（全名 + 縮寫）
- 重點是**亮點、賣點、advantages**，不是 workflow
- 提到 key results 數字
- **絕對不寫 technical details**

**⚠️ 賣點檢測**：如果連續在描述 workflow（A → B → C），那就是在寫 Methodology preview，不是在賣 insight。

**Bullets 部分：Contributions（3–5 個，端看情況）**

⚠️ **每個 bullet 第一句就直接挑明亮點。** Reviewer 掃 bullets 很快，第一句沒抓住就跳過了。

好的 bullet：
```
Spatial alignment at the feature level, rather than at the output
level, proves critical for resolving ambiguity in multi-object 3D
scenes. This insight drives the design of ..., which achieves ...
```

壞的 bullet：
```
A key finding is that X is important. Based on this, Y is proposed.
```
```
Extensive experiments are conducted on multiple benchmarks and
state-of-the-art performance is achieved.
```

**Bullet 原則**：
- 每個 bullet 傳達一個有深度的 insight
- 避免跟散文重複
- 避免純功能描述和空話
- 個數 3–5 個端看情況（教授 2026-06-12）。重要的是講清楚**為什麼 significant、為什麼有 impact、帶來什麼重要 insight**，不是淪為列舉數字的報告

---

## 寫完後自我檢視（Anti-Mediocrity Check）

| 檢查項 | 標準 |
|--------|------|
| **痛點是否鮮明** | ¶1 讀完後 reviewer 能感到「這問題確實不好做」？ |
| **賣點是否突出** | ¶3+¶4 讀完後 reviewer 能感到「這個想法有意思」？ |
| **是否 workflow 化** | ¶4 散文是否連續在描述「先 A 再 B 再 C」？ |
| **主題詞一致性** | ¶1 到 ¶4 核心主題詞是否始終一致？ |
| **段落完整性** | ¶1 ¶2 ¶3 各自真的只有一段？ |
| **學生原意** | 是否保留了學生的核心 idea 和 technical contribution？ |

---

## Teaser Figure Prompt 規格（8 項必填）

如果需要另外請工具畫 teaser，提供以下資訊：

1. **整體佈局**：左右分割 / 上下對比 / 三欄？比例
2. **每個區塊的具體視覺內容**：精確到「左上角放一張 3D 點雲俯視圖，圖中有 3 個物體分別用紅框、藍框、綠框標出」
3. **所有文字標注的完整內容**：每個 label、annotation、title
4. **顏色方案**：用 hex code 指定
5. **箭頭和連接線**：從哪指到哪、實線/虛線
6. **對比邏輯**：讀者第一眼應該看到什麼差異
7. **Motivational message**：reviewer 看到這張圖的 takeaway
8. **參考風格**：列出 1-2 篇具體論文的 teaser figure
