# Evaluation Lenses — 三個高層評估面向

> 來源：Prof. Chun-Yi Lee 2026-06-24 明示的審稿準則。這三個 lens 比「逐行找 typo」更能決定一篇論文該不該收。每個 lens 的負面判斷都**必須點名具體證據**（論文位置 + 對外作品名/年），且要先過 `verification-discipline.md`。

---

## L1 — 新不新（SOTA currency & novelty）

**問題**：這篇有沒有跟**它那個確切問題的現役 SOTA** 比？它自稱的「新貢獻」是不是其實是別人早就提出、卻沒引用的東西？

要查：
- **Baseline 的年份與對題性**：對照的是近 1–3 年該問題的代表方法，還是過時/弱的方法、或跨任務硬湊的方法？
- **核心方法的原創性**：把「貢獻」拆開，每一塊是不是成熟技術的重新命名/組裝？有沒有一篇早於投稿截止日的論文已經提出同樣的核心機制？
- **缺哪些該比的 SOTA**：點名具體方法 + 年份。

負面判斷的門檻（要嚴謹）：
- 「沒跟新的比」→ 必須指出**該比而沒比的具體方法**，且該方法早於投稿截止日、同問題（見 verification-discipline）。
- 「核心其實是舊東西」→ 必須點名那篇前人工作（作者/會議/年），且確認它早於本文且確實提出同一機制。

踩過的真例（APCAS 2026）：
- 2025 CPU-cooling 把 Beta-distribution policy 當自己的貢獻（Sec IV），但 Chou et al. **ICML 2017**、Petrazzini & Antonelo **2021** 早已提出 [0,1] Beta policy——**這種「自稱新、實為未引用前人工作」是 rebuttal-proof 的最硬 L1 指控**。
- 2387 的 integer multiply-shift requant（Eq 2/5）是 Jacob et al. **CVPR 2018**（TFLite/gemmlowp）標準法，未引用。

---

## L2 — 重不重要（problem importance & redundancy）

**問題**：解的是重要且仍 open 的問題，還是在重複解前人已經解掉的問題？

要查：
- **問題本身**：在該領域是否重要、是否仍 open（還是已被充分解決）？
- **前人重疊**：有沒有前人工作已經解掉同一問題？點名。
- **真正新的是什麼**：扣掉與前人重疊的部分後，genuinely new 的內容剩多少？是不是只剩一個小工程整合？

公允提醒：
- 問題重要且 open，即使方法增量，也別把 importance 評太低（如 2104 的 SSM/Mamba RTL 可靠度、2387 的 edge VC 加速，都是真 open 的問題，originality 給 Weak 而非零）。
- 「已被解決」是強指控——必須點名那篇「已解決」的論文，且確認它涵蓋本文的**同一設定/約束**（不同設定 = 問題仍 open）。

踩過的真例：2239 自稱解「thermal control」，但 arXiv 2505.20769 已做 PI-GRU + soft constraint + OOD 外推 + 閉 MPC 控制迴路——這類「同問題前人已做」要先驗該文存在、日期、範圍才寫。

---

## L3 — 做沒做足（experimental adequacy）

**問題**：baseline、metrics、ablations、統計、可重現性，做足了沒？

逐項檢查：
- **Baselines**：是否強、現役、公平調校？要警覺四種劣化——(a) 自建（self-implemented，如「DQN [refs 全是別的領域]」）、(b) 自比（拿自己的某個 setting 當唯一對照）、(c) 任務不符（FPGA 但比的是別的任務的加速器）、(d) 只做自我消融（only「我們 method 拿掉某 loss」）。崩潰到比 vanilla 還差的 baseline（如 SBCL 46.75）＝沒調好，使「公平比較」站不住。
- **Metrics**：用的是該 subfield 的**標準指標**嗎？（VC 該有 MCD/PESQ/MOS/speaker-sim，不是只報 NMSE；可靠度該有 SDC/AVF/FIT，不是只報自定義 NDCAE；reject-option 該有 risk-coverage/AURC 曲線。）指標未定義、跨表不一致也算 L3 缺陷。
- **Ablations**：有沒有**隔離每一個自稱關鍵的元件**？最常見的洞是「自稱最重要的機制」反而沒被單獨 ablate（如 2025 沒做 Beta-vs-Gaussian、2239 沒拆 cascade、2387 零 ablation）。
- **統計**：seeds / variance / CI / significance。單點數值 + 「averaged over multiple runs」卻無 std ＝ 硬傷（5 篇 APCAS 全中）。小幅領先（1–3 點）無 variance 時無法宣稱顯著。
- **Reproducibility**：超參、架構、訓練細節、code/data。placeholder dataset（"URL will be added"）審稿期不可得。

L3 通常是最容易站得住、最不依賴外部查證的一塊——**優先用 L3 + 內部矛盾撐 reject**。
