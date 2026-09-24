#!/bin/bash
# ============================================================================
# Overleaf git token 設定 —— 由主人本人在這台機器前（或 SSH 進來）執行。
#
#   為什麼要這支：token 不能經過 Telegram（會留紀錄）。這支讓你在終端一次輸入，
#   全程安全：輸入時不回顯、不寫進 shell history、存進 macOS Keychain（加密），
#   最後（可選）當場驗證 Overleaf git 連得上。
#   用的是「可撤銷的 Git Authentication Token」（olp_ 開頭），不是你的帳號密碼。
#
#   跟 paperctl 完全一致：username = git、osxkeychain、git credential-osxkeychain store。
#
#   取得 token：Overleaf 網站 → Account Settings → Git Integration
#               → Generate a Git Authentication Token（olp_ 開頭，之後可隨時撤銷）
#
#   用法（開 Terminal 貼這一行就好）：
#       bash ~/Projects/paperctl/set-overleaf-token.sh
#   想順便實測某個 project 連得上，就多帶它的 project id：
#       bash ~/Projects/paperctl/set-overleaf-token.sh <overleaf_project_id>
# ============================================================================
set -euo pipefail

HOST="git.overleaf.com"
USER_FIELD="git"            # paperctl / Overleaf git-bridge 都用 username = git
TEST_PROJECT="${1:-}"      # 可選：傳一個 Overleaf project id 來實測連線

echo "主機：${HOST}（使用者欄位：${USER_FIELD}）"
printf "Overleaf git token（olp_ 開頭；輸入時不會顯示，貼上後按 Enter）: "
read -rs TOKEN
echo
[ -n "$TOKEN" ] || { echo "❌ 沒有輸入 token，已取消。"; exit 1; }
case "$TOKEN" in
  olp_*) : ;;
  *) echo "⚠️ 提醒：Overleaf 的 Git Authentication Token 通常是 olp_ 開頭，你貼的好像不是。"
     echo "   （還是會照存，若之後連不上，多半是貼到別的東西。）" ;;
esac

# --- credential helper：對齊 paperctl（osxkeychain），但不覆蓋你既有的全域設定 ---
CUR=$(git config --global credential.helper 2>/dev/null || echo "")
if [ -z "$CUR" ]; then
  git config --global credential.helper osxkeychain
  echo "✅ 已設 git 全域 credential.helper = osxkeychain（跟 paperctl 一致）"
elif [ "$CUR" != "osxkeychain" ]; then
  git config --global "credential.https://$HOST.helper" osxkeychain
  echo "ℹ️ 你全域 credential.helper 是 '$CUR'，不動它；只對 Overleaf 這台主機加 osxkeychain。"
else
  echo "✅ git 全域 credential.helper 已是 osxkeychain。"
fi

# --- 存進 Keychain：token 經 stdin 餵給 helper，不走 argv、不進 shell history ---
printf 'protocol=https\nhost=%s\nusername=%s\npassword=%s\n\n' "$HOST" "$USER_FIELD" "$TOKEN" \
  | git credential-osxkeychain store
echo "✅ token 已存進 macOS Keychain（host=${HOST}, username=${USER_FIELD}）"
unset TOKEN

# --- 驗證（GIT_TERMINAL_PROMPT=0：連不上就直接失敗，不會卡在密碼提示）---
if [ -n "$TEST_PROJECT" ]; then
  echo "🔎 用 project $TEST_PROJECT 實測 Overleaf git 連線..."
  if GIT_TERMINAL_PROMPT=0 git ls-remote "https://$HOST/$TEST_PROJECT" >/dev/null 2>&1; then
    echo "✅ 連線成功！Rei 現在可以幫你 pull/push Overleaf 了。出國安心。"
  else
    echo "⚠️ 連線沒過：確認 token 是否正確、是否已撤銷、或該 project id 是否屬於你的帳號。"
    echo "   （token 已存，可重跑本腳本重輸入。）"
  fi
else
  echo "ℹ️ 未帶 project id，已略過連線實測。要實測就跑："
  echo "     bash ~/Projects/paperctl/set-overleaf-token.sh <你的_overleaf_project_id>"
fi
