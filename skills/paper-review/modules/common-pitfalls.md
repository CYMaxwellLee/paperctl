# Common Pitfalls — 跨論文常見系統性缺陷

> 來源：APCAS 2026 五篇審稿歸納出的共同病灶。**雙用**：(1) 審別人稿時逐項對照；(2) 我們自己投稿前自審，避免自己犯同樣的錯。每一項都附「怎麼抓」與「自審時怎麼防」。

---

1. **Baseline 不對題**
   - 抓：對照組是自建（self-implemented）、自比（自己的某 setting）、任務不符、或只做自我消融；有沒有崩潰到比 vanilla 還差的 baseline（＝沒調好）。
   - 防：列出該問題現役 SOTA，逐一比或明確說明為何不比；自建 baseline 要交代調參與其來源論文對等。

2. **無 variance / seeds / significance**（最普遍，APCAS 5 篇全中）
   - 抓：表格只有單點值，卻寫「averaged over multiple runs」；小幅領先無 std。
   - 防：≥3 seeds、報 mean ± std（或 CI）、對 headline 比較做顯著性檢定。

3. **Ablation 不隔離「自稱最關鍵」的元件**
   - 抓：論文主打 X 機制，ablation 卻只拆別的；核心機制從未被單獨關掉測。
   - 防：每一個寫進 contribution 的元件都要有對應的 ablation row。

4. **頭條 claim 沒被實驗證明**
   - 抓：標題/摘要主打的東西（drift adaptation、closed-loop control、perceptual fidelity）沒有對應實驗，只有旁證或定性圖。
   - 防：標題只 claim 你真的測了的；沒測的降為 future work。

5. **「新」的核心其實是未引用的前人工作**
   - 抓：把成熟技術（Beta policy、int-shift requant、PI-RNN soft-penalty recipe）當自己的貢獻、不引用源頭。
   - 防：投稿前查清楚你「發明」的東西是不是早有人做；老實引用、把貢獻重新定位成「整合/應用」。

6. **claim-vs-table 不符 / 指標未定義未對齊**
   - 抓：正文宣稱「在 A、B 上一致」但表只有 A；不同表用不同且未定義的指標（如 multi-class accuracy vs binary detection），讀者無法對照。
   - 防：所有指標給公式、跨表一致或明確標示不同；正文每句宣稱都對得上某張表/圖。

7. **placeholder dataset / 無 code**
   - 抓：「URL will be added in the final version」、無 code、無 data-availability。
   - 防：投稿時就附匿名 capsule / 連結，讓審稿可驗。

8. **soft penalty 宣稱 hard guarantee**
   - 抓：用 soft loss 卻宣稱「strict 0.00% violation」「blocks」「guarantee」；數學上 soft 約束無法保證。
   - 防：把「保證」改成「在測試集上未觀察到違規」；要硬保證請走架構式約束（PCNN/KKT-hPINN/HardNet 那條線）。

9. **用「完整度」預測錄取（最誘人、最沒預測力）**
   - 出處：2026-06-27 WACV textnav，教授徵詢的 ECCV 落選檢討（分析結論，非教授 doctrine）。
   - 抓：把「最完整／跑得動／表漂亮／有 formal proposition」當成「最可能上」。完整度只衡量「寫完沒」，不衡量「有沒有一個專家一句話駁不倒的理由」。一批投稿裡「最完整」會系統性選到最 polished 的增量 paper、避開最有 novelty 的那篇 —— 正是錄取的反指標。
   - 防：(a) 先問「**高信心專家會不會驚訝？(novelty)**」—— 核心若是已知 work 的重組，再完整也救不了；(b) 既有審稿意見**用 confidence 加權**讀（高信心 1 分≈死刑、低信心 4 分≈雜訊），不看分數算術平均；(c) load-bearing 弱點若現有資源補不了（學生畢業、無新實驗），該**降低**重投優先序，不該因「做完了」而升高；(d) 同一篇 algorithms paper 換 track 投不降 novelty bar，反而遞給 reviewer「投錯 track／venue-shopping」的攻擊面。

---

**自審用法**：投稿前把自己的 paper 過一遍這 9 項 + `evaluation-lenses.md` 三個 lens。能擋下自己的審稿人，才送得出去。
