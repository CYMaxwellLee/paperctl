# paperctl HOT SHEET（動 .tex 前必載；濃縮自本 skill 的 modules＋主人 9/16 七條）

> 這份是 `modules/` 的**濃縮索引**，不是第 11 個模組 —— 它存在的理由是 modules 全文動段前載不完。
> ⚠️ 它是 derived view：改了 modules 要回頭看這裡有沒有跟著改。

## 生成順序（不可跳）
1. **功能行先寫**：這段（句）對讀者做什麼工作？一行。寫不出＝不能動筆。上桌放最前。
2. **清單從處方推導**（該 section 的模組格、帶出處），⛔ 從學生現稿長清單＝被帶著走。
3. 句子照格生。學生原文＝事實礦；骨架、選材、句式模板都不拿。
4. Setup 事實（資料集、步數、判準、環境）歸 §4.1，⛔ 不留在 results 段。

## 主人重講七條（9/16 親列）
1. 動段前看 paperctl 該模組（讀的是處方、不是印象）
2. 不被學生帶著走（骨架／選材／句式／開場全查；We study 型開場＝重寫訊號）
3. 論說文不 narration（claim→支撐→意義；⛔ 流水帳／架構巡禮／報導腔）
4. 不聊天 register（gives/makes/lets/asks/pays/takes/adds/goes back…→實義動詞；9/23-24 增補：buy(s)/need not/becomes something）
5. 實驗段 insight/significance/impact 先講、數字後報（表格引導句可在前）
6. 主題句呼應 subsection title 的**兩半**
7. intro ¶4＝advantage＋impact＋significance＋insight 四件套、承接 ¶3

## 禁詞硬底線（零容忍）
- because（整篇→since/as/given that）、but、So 句首、give(s)/make(s)/let(s)
- comma+V-ing 掛尾、分號連句、em-dash、", so that"、", so" 連接（9/23 入表）、", yet"（warn）
- 句首副詞+逗號（Additionally,/Notably,/In addition,…；允許 Specifically,/Moreover,/Furthermore,）
- As shown in／As can be seen（表圖當主詞）、thereby、numerous、straightforward、underscore(v.)、Yet 句首
- corroboration（主人 9/17 嚴格禁）、「X is Y」弱 be 句在定義處→ is defined as/is selected as、not a X→rather than a X（對比處）
- 自問自答、小括號補充子句、"XX et al." 當主詞（數字 cite 稿）、縮寫先於全名
- 直引號→``…''；\(…\)→$…$；float 一律 [t]

## 用字節制（非禁詞，頻率控管）
- hence（主人 9/24：「不是禁詞但用太多了」）——同段不重複、單篇少用；換 thus/therefore 或重構句子
- 同介系詞排比訓（主人 9/24）：", to a X, to a Y, and to a Z" 型逗號＋重複介系詞的平行列舉（Fable 5 慣性、「不會特別顯示寫作厲害」）——改普通列舉（介系詞一次）或散文句
- 冒號句型節制（主人 9/25：「我其實也沒一定絕對要禁，但這幾天改下來有覺得特別多」）——文采原則不設配額：「X: Y」展開句是調味不是主力，連段出現就顯眼；transition 不靠冒號扛，能拆成兩個普通句就拆（9/25 MEMOIR 實測全篇 prose 近每段一顆＝太多的樣子）

## 格式與量測
- eq 前 integrated "as follows:"（comma-tail 型會被剪）＋eq 符號正文點名
- \cref／句首 \Cref；⛔ 訊息與正文寫「Sec.」；**Table 與 Section 首字大寫不論位置、每篇同規**（主人 9/24；preamble 設 `\crefname{table}{Table}{Tables}`＋`\crefname{section}{Section}{Sections}`＋`\crefname{subsection}{Section}{Sections}`（subsection 那行別漏，\cref 指到 \subsection 的 label 走的是 subsection 型），新稿開局就加）
  ⚠️ 若某個專案的 preamble 沒載 cleveref，那是**該專案的狀態**，在那個專案裡才退回 `Fig.~\ref`／`Table~\ref`（帶 `~`）。⛔ 不是通則。
- 方陣：段尾行/caption 行/eq lead-in 行 ≥85%，pdftotext -layout 量、⛔ 心算；零損刀填縫（真資訊/收縮/拔冗餘）、⛔ 填料詞、⛔ 動主人已定的字
- 改動包 \cyl{}（學生原文註解保留）；不確定數字 \red{}；量測與 push 分鏈

## 上桌與落地
- 一次一段、完整前後文、原→改、主人「推」才落檔、落檔才 push；未推的字⛔不進檔案
- 超頁只提醒不自砍；版面動作只在主人開啟該戰場時做
- Abstract/Intro 不攤 protocol 變數清單與 seed 數；claim scope 在已展示範圍；limitation 不自曝真弱點
