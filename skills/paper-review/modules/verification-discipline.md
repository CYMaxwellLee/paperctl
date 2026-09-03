# Verification Discipline — anti-over-reach 鐵則

> 本 skill 最重要的一頁。指控掛教授名字送出去，**錯一個就出包**。所有「該比 / 已被解決 / 缺少 / 矛盾」的 falsifiable 指控，送出前一律過這套查證。來源：2026-06-24 APCAS 5 篇審稿中**實際踩過的錯**（教授當場糾正）。

---

## 0. 總則

任何負面、可被證偽的指控，送出前必須驗三件事：
- **(a) 日期**：對的是**投稿截止日**，不是會議年份。
- **(b) 適用性**：同問題 + 同設定才算 must-compare。
- **(c) 存在性與歸屬**：那篇工作真的存在、作者/會議/年份正確。
過不了任何一項 → 降級（must-compare → must-cite-discuss）或直接丟掉。

---

## 1. 日期要對「投稿截止日」，不是「會議年份」

**踩過的錯（核心教訓）**：APCAS 的會議 form 標「2025」，我就假設投稿在 2025、把 COBRA（arXiv **2025-12**）當「同期 concurrent」建議**不要**當必比 baseline。**錯。** 教授指出 APCAS submission 截止是 **2026 年 4 月**——COBRA 早於截止日約 4 個月，當然該比。

鐵則：
- 先確定**該會議該輪的投稿截止日**（problematic 時上網查或問教授），用它當 prior-art cutoff。
- 任何早於 cutoff 公開（arXiv v1 或正式出版）的工作，都是**作者該知道、該比/該引**的，不能用「看起來很新」當理由 dismiss。
- 不要把「會議年份」當 cutoff（會議辦在 2026 末，但投稿可能在 2026 春；反之 form 標 2025 不代表投稿在 2025）。
- Dec-前一年 / 當年初的工作最容易被誤判成「concurrent」——這正是最常出錯的區間，務必查實際截止日。

---

## 2. 適用性：must-compare vs must-cite-discuss

- **must-compare**：同問題 + 可比設定/約束 → 作者**應該跑** head-to-head。
- **must-cite-discuss**：相關但領域/架構/約束不同 → 作者**應該引用討論**，但不強求 head-to-head。
- 判準範例（APCAS）：CNN/ViT 的可靠度方法（ENFOR-SA）對 SSM 論文 = must-cite（架構不同）；SEM 影像的 wafer-defect 方法（WaferDC）對 optical-AOI 論文 = must-cite（影像模態不同）；同一 IC-Defect-14 split 上的 multi-expert 分類器（ReCAME-Net）= must-compare（同問題同資料）。
- 寫指控時標明是 must-compare 還是 must-cite，別把「領域沾邊」誇大成「該 head-to-head 卻沒比」。

---

## 3. 存在性 + 正確歸屬

引用任何外部工作前，查清楚 venue / year / authors：
- **踩過的錯**：把 LGLA 誤標 NeurIPS 2023（實為 ICCV 2023）；把不存在的「SegMix+ViT PEFT 2025」當獨立論文。
- **踩過的錯**：2387 的 QDCGAN/DCGAN 在 Table IV 的編號與 bibliography 不一致 → **用作品名 + 數值引用，不要寫 [編號]**，並可把「編號不一致」本身當一個 minor 指控。
- 查不到、無法確認身分的 → 標 drop，不要硬寫。

---

## 4. Adversarial verify 一切 falsifiable claim

數字、「缺少 X」、「內部矛盾」都要回原文（或上網）查證：
- **踩過的錯（假矛盾）**：把 Table III 的「Defect（13 類多類別準確率）」與 Table V 的「Defect-Acc（缺陷偵測準確率）」當成「同模型自相矛盾」。其實是**兩個不同且未定義的指標**（四模型同方向位移即可證）。正解：降為「指標未定義/未對齊」的清晰度問題。
- **踩過的錯（假相同）**：把 setpoint 65 的「M2 1.06 vs 3.0」說成「nearly identical」——其實是 2.83× 差距；真正打平的是 M1（1.08 vs 1.10）。
- 做法：開獨立 adversarial verifier agent，任務是反過來挑「我們 review」的數字錯、誇大、可被反駁處。

---

## 5. 內部 > 外部

- **內部矛盾 / 未證明的 headline claim** 最硬：作者無法反駁，且不依賴外部查證。優先用它們撐 reject。
- **外部 SOTA 指控**（「該比 X」「X 已解決」）風險最高：必過 §1–§3 才寫。把 reject 的重心放內部，外部當補強。

---

## 6. 公允對稱

- 不替論文製造問題：baseline 真的是現役 SOTA 就承認（先講）；有 first-of-kind 角度 originality 給 Weak 不是零。
- 也不替自己的指控護航：自己的指控被驗證推翻，就降級/撤掉，照樣記錄「dropped + 原因」。
- 同單位 / 疑似作者自身的前作（如同實驗室論文、自引資料集 ref），點出時標明 COI，別當成中立的「外部 SOTA」重拳。

---

## Checklist（每個外部指控送出前）

- [ ] 該工作公開日期 **早於投稿截止日**？（用實際 deadline，不是會議年份）
- [ ] 同問題 + 同設定（must-compare）還是只相關（must-cite-discuss）？
- [ ] 作品名 / venue / year / authors 查證正確？編號可靠（否則用名字）？
- [ ] 若是內部矛盾/數字：回原文逐一核對過？是真矛盾還是「不同指標/不同設定」？
- [ ] 這條是內部硬證據，還是需要外部查證的高風險指控？重心放對了嗎？
