# 段落改寫 Pipeline（para-pipeline）

## One-shot 作業程序（任何新 session 的標準開局，2026-07-06 定版）

> 目標（教授原話）：「建立這套流程，讓未來我們都很容易 one shot 完成。」

1. **載入 doctrine**：paper-editing skill 自動觸發 → 讀 style-guide §〇/§一/§二/§四、
   rulings-ledger.md（教授裁決史）、approved-exemplars.md（節奏標準）。
   ⚠️ **宣稱「guideline 沒有涵蓋某文體」之前，必須 grep＋讀完 modules/ 全部檔案**
   （2026-07-06 事故：宣稱沒有 Related Work 規範，實際上 introduction.md 的前人
   討論原則＋preliminary-methodology.md 的 Prelim/RW 邊界與「評價歸 RW」＋
   qa-guideline 的精簡令，三處合起來就是 RW 文體的完整規範——只查檔名不讀內容
   是錯的）。
2. **讀論文狀態**：論文 repo 根目錄的 `PAPER-STATE.md`（各段核可狀態、現行 headline
   數字與出處、edit conventions、novelty 邊界、待辦）。沒有就先建。**Director 的
   狀態必須外部化在這個檔案，不准只活在對話 context 裡**（session 更換 = 狀態歸零
   = 過期數字這類事故的根源）。
3. **Preflight**：grep 學生標記（如 `\tjc`）找新更新；headline 數字對 tables 核一次；
   確認 deadline。
4. **Triage 選 profile**：教授逐句 line-edit → Director 直改（不開管線）；
   修訂/壓縮/中風險段 → `profile: "light"`（Section Editor → Voice → Verifier →
   Proxy，約 15–25 分）；新寫段落/高風險段（intro、abstract、contributions）→
   full profile（加 3 lens 寫手 + critic，約 60–100 分）。
5. **Director 收尾**：套 \cyl → compile → 真跑 lint → 呈報教授（最終稿＋修改說明＋
   openQuestions，完整句子不用縮略）→ 教授 OK → 推 Overleaf。
6. **飛輪**：教授每條糾正 → rulings-ledger 補一條；每段定稿 → approved-exemplars
   補一篇；PAPER-STATE.md 同步。


> 出處：教授 2026-07-05 提案：「我每次說要改哪一段，基本上先有個 Opus 4.8 先大概抓個
> 方向…開個 3~5 個 Sonnet 5，要他們也寫…最後再給 Fable 5 or Opus 4.8 max 裁決，
> 整段要流暢正確，最後給我看，然後再上傳。」
> 三處設計修正（視角分工＋專職挑剔、寫手自審、裁決防翻案）為本 repo 依 2026-07-05
> 實測數據的操作化，教授已同意。

---

## 何時用（triage — 先判斷再開）

| 情境 | 做法 |
|---|---|
| 單句修正、換字、教授逐點 line-edit | **不開 pipeline**，主線直接改（快、便宜、教授在等） |
| 段落級改寫 / 新寫一段 / 學生段落重構 | **開 pipeline**，`sectionText` 必給 |
| Introduction / Abstract 這類高耦合 section | **建議以 section 為單位跑一次**（`paragraphText` 放整個 section）——跨段冗餘與承先啟後是段落之間的性質，逐段跑治不掉（2026-07-05 教訓） |
| 低耦合長 section（如 experiments 各小節） | 逐段開 pipeline，段與段之間給教授過目 |

## 管線結構（與為什麼這樣設計）

```
教授:「改 §X 第 N 段,要求 …」
  ├─ 1. Section Editor(主線模型):先讀完整個 section → sectionAudit
  │      (各段唯一職責、跨段冗餘、過長段落)+ 目標段落計畫
  │      (逐句標「賣 or 敘述」、所有權標記、claim 邊界)
  ├─ 2. Write(3× Sonnet 5,並行,都拿到完整 section + GLOBAL RULES):
  │      寫手A 論證深度 lens ┐ 各自寫完:三遍修訂
  │      寫手B 防審 lens     ├ + 該 section 模組的自檢表
  │      寫手C 語域 lens     ┘ (如 introduction.md Anti-Mediocrity Check)
  ├─ 3. Attack(1× Sonnet 5):不寫稿,攻擊 direction + 全部草稿
  ├─ 4. Judge(強模型,繼承主線;effort 可調):
  │      best-of-breed 合成 + 裁決 findings(教授裁決 binding,防翻案)
  │      + 全局驗收 pass(所有權/賣vs敘述/跨段冗餘/模組自檢表,結果測試驗收)
  ├─ 5. Verifier(Sonnet,工具實查不信自我宣稱):
  │      cite key 對 bib、數字對 tables、掃全 repo 過期數字、術語漂移、ban 掃描
  ├─ 6. Professor-Proxy(強模型,ground truth = rulings-ledger.md):
  │      模擬教授逐句審,每條 finding 引帳本條目;approve / revise
  ├─ 7. Refine(內部迭代,最多 2 輪,教授看不到):
  │      Judge 自改 → Verifier 復查 → Proxy 復審;不收斂的進 openQuestions
  └─ 8. Director(主線):套 .tex → compile → 真跑 lint → 呈報教授
        (最終稿+diff+provenance+openQuestions)→ 教授裁決 → 推 Overleaf
        教授的每條新 line-edit → 回寫 rulings-ledger.md(飛輪)
```

**角色對照（教授 2026-07-05 第三批核可的組織）**：Director＝主線 session（唯一對教授
的介面、全文狀態、triage、brief、整合呈報）；Planner＝Section Editor stage；
Writers＝三 lens Sonnet；Critic＝攻擊者；Judge＝合成與裁決;Verifier＝機械事實查核；
Reviewer/QA＝Professor-Proxy＋全局驗收。設計原則：**教授看到的永遠是內部迭代完的
版本**——「我每次花很多時間和 Claude code 吵架或者糾正，其實浪費的更多。不如一次到位。」

### ⚠️ 2026-07-06 v3：內容民主，文字獨裁（transition 累犯的架構級解法）

教授裁決：transition 要「專業漂亮精美，讀起來串接一氣呵成，不是獨立的短句子」，
且此問題**不可復發**。診斷：流暢是文本的**序列性全局性質**，單一作者一口氣寫是
免費的，而(a)拼貼式合成（從多稿挑句縫合）**結構性地**破壞接縫、(b)塞滿硬約束的
brief 讓寫作者產出「合規碎句」。兩個架構改變：

1. **Voice（單聲道重寫）**：Judge 不再拼貼。三份草稿降級為**原料**（論證、賣點、
   措辭），Judge 裁決內容後**從頭到尾一口氣重寫最終文字**，明令禁止剪貼句子；
   修訂輪同樣是整段重寫，不是句子補丁。
2. **寫輕、查重（brief diet，Director 的責任）**：editBrief 只放最承重的少數要點
   ＋目標＋事實；細部規則的執行交給 Verifier / Proxy / 鏈讀等檢查層。寫作層
   明白被告知「下游有 gate，先為流暢與論證寫，被抓到的機械問題之後修」。
3. **正面樣本庫**（`approved-exemplars.md`）：教授定稿段落＋可遷移手法批註，
   Voice 動筆前必讀對齊節奏。與 rulings-ledger（負樣本）構成雙飛輪：
   教授改掉的進帳本，教授核可的進樣本庫。

### ⚠️ 2026-07-05 ¶4 首戰事故（本結構的由來，不可回退）

第一版 pipeline 的產出**滿足了全部機械約束**（術語鎖定、數字、lint、接棒句、
「不以 We 開頭」）卻被教授整段駁回：(a) 方法首次出現無所有權標記（「誰知道
SPD 是我們的還是別人的方法」）；(b) 整段 narrative 敘述機制，沒有在賣
advantages/impact/significance；(c) 與 ¶3 大量概念重複；(d) contributions
仍是機制+數字清單。根因不是 guideline 不清楚（introduction.md 每一條都寫了），
而是：**prompt/brief 層把精神規則降維成表面特徵、且無任何 stage 擁有全 section
視角**。修正即上圖粗體部分＋style-guide §〇 反降維鐵則（結果測試驗收、
doctrine 高於 brief）。教訓：**checkable 約束會排擠 uncheckable 的靈魂，
所以靈魂必須變成明確的驗收 stage，而不是散文提醒。**

**設計依據（2026-07-05 field test，Sonnet 盲寫 vs 教授核可版）**：
- 寫手要**視角分工**不要同質——3 個 lens 候選各有可取（best-of-breed 合成有效）。
- **Sonnet 的 critic 比 writer 強**——它挑錯抓到教授版都沒堵的 claim-safety 洞（D2F
  uncredited），但自己寫會漏語域、違反自己審別人抓得到的 ban → 所以寫手**必須自審**、
  且產文一定要過強模型或 critic。
- **Critique 有 relitigation 風險**（6 條 findings 有 2 條翻教授已裁決的案）→ 裁決
  agent 必須以教授 attested rulings 為 binding，逐條標 accepted / rejected-relitigation。
- **自我宣稱不可信**——模型會謊報「已檢查無違規」→ Pass 3 必須真跑工具；pipeline 之後
  主線還要再真跑一次 `paperctl lint`。

## 怎麼開

```bash
ROOT=$(paperctl root)   # 任何機器都能定位 repo(setup 時 symlink 已建好)
```
```js
Workflow({
  scriptPath: ROOT + "/claude-integration/workflows/para-pipeline.js",
  args: {
    paperctlRoot: ROOT,          // 換機器必給;doctrine 路徑由它解析
    paragraphText: "<段落原文,LaTeX 原樣>",
    sectionText: "<該 section 完整現行全文>",  // 全局視角的來源,幾乎必給(缺席會 log 警告)
    repoDir: "<論文 repo 路徑>",               // Verifier 實查 bib/表格/全 repo 過期數字,幾乎必給
    editBrief: "<教授指示 + 段落角色,如 intro ¶4: method+contributions>",
    paperFacts: "<數字、模型清單、可用 cite keys、novelty 邊界、LaTeX 慣例(cleveref 有無、\\method{} 等)>",
    moduleFiles: ["skills/academic-paper-writing/modules/introduction.md"],  // 相對 ROOT;選填
    directionDraft: undefined,   // 主線已有方向草稿就傳入,跳過第一階段
    judgeModel: undefined,       // 預設繼承主線模型(教授:「反正用 Fable 5 or Opus 最新的」,
                                 // 主線 /model 選什麼就是什麼);要釘死可給 'fable' | 'opus'
    judgeEffort: "high",         // 最難的段落可 "max"
  },
})
```

- `style-guide.md` 永遠自動包含，不用列。
- **paperFacts 要餵足**：文獻偵察結論（哪些 observation 是前人的、要 credit 誰）、
  claim scope 邊界（測了幾個 setting）都放進去——寫手看不到主線對話。
- 回傳：`final`（合成段落）、`provenance`（哪句取自誰）、`adjudications`（critic
  findings 裁決）、`openQuestions`（要教授拍板的）、全部原始草稿。

## 主線收尾（pipeline 不代勞，不可省略）

1. `final` 以該篇 edit convention 套進 .tex（`\cyl{}`、comment 學生原文等）。
2. Compile（0 error / 0 undefined 才算過）。
3. **真跑** `paperctl lint`（無 conference.json 就 grep §八 清單）。
4. 給教授：合成段落 + provenance 摘要 + openQuestions。
5. **教授 OK 才推 Overleaf。永不 auto-push。**

## 成本（2026-07-05 實測量級）

每段約 15–25 萬 subagent tokens、3–7 分鐘。大頭是 4 個 Sonnet 5（$3/$15 per MTok，
2026-08-31 前促銷 $2/$10），judge 走主線模型費率（Opus $5/$25 / Fable $10/$50）。
折美元約 $0.5–1.5/段。Prompt caching 自動生效；Batch API 的 50% 折扣不適用
（那是離線端點，互動 session 用不到）。
