#!/bin/bash

NODE_DIR="/home/container/node"
BUN_DIR="/usr/local/bun"
GO_DIR="/usr/local/go"
export PLAYWRIGHT_BROWSERS_PATH="/usr/local/share/playwright"

mkdir -p "$NODE_DIR"
export PATH="$NODE_DIR/bin:$BUN_DIR/bin:$GO_DIR/bin:$PATH"

echo "export PATH=\"$NODE_DIR/bin:$BUN_DIR/bin:$GO_DIR/bin:\$PATH\"" > /home/container/.bashrc
echo "export NODE_PATH=\"$NODE_DIR/lib/node_modules\"" >> /home/container/.bashrc
echo "export PLAYWRIGHT_BROWSERS_PATH=\"$PLAYWRIGHT_BROWSERS_PATH\"" >> /home/container/.bashrc

if [ ! -z "${NODE_VERSION}" ]; then
    [ -x "$NODE_DIR/bin/node" ] && CURRENT_VER=$("$NODE_DIR/bin/node" -v) || CURRENT_VER="none"
    TARGET_VER=$(curl -s https://nodejs.org/dist/index.json | jq -r 'map(select(.version)) | .[] | select(.version | startswith("v'${NODE_VERSION}'")) | .version' 2>/dev/null | head -n 1)
    
    if [ -z "$TARGET_VER" ] || [ "$TARGET_VER" == "null" ]; then
         if [[ "${NODE_VERSION}" == v* ]]; then TARGET_VER="${NODE_VERSION}"; else TARGET_VER="v${NODE_VERSION}.0.0"; fi
    fi

    if [[ "$CURRENT_VER" != "$TARGET_VER" ]]; then
        rm -rf $NODE_DIR/* && cd /tmp
        curl -fL "https://nodejs.org/dist/${TARGET_VER}/node-${TARGET_VER}-linux-x64.tar.gz" -o node.tar.gz
        tar -xf node.tar.gz --strip-components=1 -C "$NODE_DIR" && rm node.tar.gz
        "$NODE_DIR/bin/npm" install -g npm@latest pm2 pnpm yarn playwright --loglevel=error
        cd /home/container
    fi
fi

if [[ "${ENABLE_CF_TUNNEL}" == "true" ]] || [[ "${ENABLE_CF_TUNNEL}" == "1" ]]; then
    if [ ! -z "${CF_TOKEN}" ]; then
        pkill -f cloudflared 2>/dev/null
        nohup cloudflared tunnel run --token ${CF_TOKEN} > /home/container/.cloudflared.log 2>&1 &
    fi
fi

# --- Warna ANSI ---
RESET='\033[0m'
BOLD='\033[1m'
CYAN='\033[1;36m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
MAGENTA='\033[1;35m'
PINK='\033[38;5;212m'
GRAY='\033[0;90m'

LINE="${GRAY}$(printf '%.0s─' $(seq 1 60))${RESET}"

# --- Helper: progress bar ---
make_bar() {
    local percent=$1
    local width=25
    local filled=$(( percent * width / 100 ))
    [ "$filled" -gt "$width" ] && filled=$width
    local empty=$(( width - filled ))
    local bar=""
    [ "$filled" -gt 0 ] && bar+=$(printf '%0.s█' $(seq 1 $filled))
    [ "$empty" -gt 0 ] && bar+=$(printf '%0.s░' $(seq 1 $empty))
    echo -n "$bar"
}

# --- Ambil data sistem ---
MEM_USED=$(free -m | awk '/Mem:/ {print $3}')
MEM_TOTAL=$(free -m | awk '/Mem:/ {print $2}')
MEM_PERCENT=$(( MEM_USED * 100 / MEM_TOTAL ))

DISK_USED=$(df -h / | awk 'NR==2 {print $3}')
DISK_TOTAL=$(df -h / | awk 'NR==2 {print $2}')
DISK_PERCENT=$(df -h / | awk 'NR==2 {print $5}' | tr -d '%')

# --- IP Address (dengan opsi tampil/sembunyi) ---
PUBLIC_IP=$(curl -s ipinfo.io/ip 2>/dev/null || echo "Unknown")
if [[ "${SHOW_IP}" == "true" ]] || [[ "${SHOW_IP}" == "1" ]]; then
    IP_DISPLAY="$PUBLIC_IP"
else
    IP_DISPLAY=$(echo -n "$PUBLIC_IP" | sed 's/./•/g')
fi

clear
echo -e "${GREEN}${BOLD}"
figlet -f standard SAIRI 2>/dev/null || echo "SAIRI"
echo -e "${RESET}"
echo -e "$LINE"
echo -e "${CYAN}Location${RESET}   : $(curl -s ipinfo.io/country 2>/dev/null || echo 'Unknown')"
echo -e "${CYAN}IP Address${RESET} : ${IP_DISPLAY}"
echo -e "${CYAN}OS${RESET}         : $(grep -oP '(?<=^PRETTY_NAME=).+' /etc/os-release | tr -d '\"')"
echo -e "${CYAN}CPU${RESET}        : $(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | sed 's/^ //') ($(( $(grep -c ^processor /proc/cpuinfo) )) Cores)"
echo -e "${CYAN}Uptime${RESET}     : $(uptime -p | sed 's/up //')"
echo -e "${CYAN}RAM${RESET}  ${YELLOW}${MEM_PERCENT}%${RESET}  ${GREEN}$(make_bar $MEM_PERCENT)${RESET}  ${GRAY}${MEM_USED}/${MEM_TOTAL}MB${RESET}"
echo -e "${CYAN}Disk${RESET} ${YELLOW}${DISK_PERCENT}%${RESET}  ${YELLOW}$(make_bar $DISK_PERCENT)${RESET}  ${GRAY}${DISK_USED}/${DISK_TOTAL}${RESET}"
echo -e "$LINE"
echo -e "${BLUE}Node.js${RESET}      : $(node -v 2>/dev/null || echo -e "${GRAY}Not Installed${RESET}")"
echo -e "${BLUE}Bun${RESET}          : v$(bun -v 2>/dev/null || echo -e "${GRAY}Not Installed${RESET}")"
echo -e "${BLUE}Golang${RESET}       : v$(go version 2>/dev/null | awk '{print $3}' | sed 's/go//' || echo -e "${GRAY}Not Installed${RESET}")"
echo -e "${BLUE}Python${RESET}       : v$(python3 --version 2>/dev/null | awk '{print $2}' || echo -e "${GRAY}Not Installed${RESET}")"
echo -e "${BLUE}Playwright${RESET}   : $(playwright --version 2>/dev/null | head -n 1 || echo -e "${GRAY}Not Installed${RESET}")"
echo -e "${BLUE}PHP${RESET}          : $(php -v 2>/dev/null | head -n1 | awk '{print $2}' || echo -e "${GRAY}Not Installed${RESET}")"
echo -e "${BLUE}Java${RESET}         : $(java -version 2>&1 | head -n1 | awk -F'"' '{print $2}' || echo -e "${GRAY}Not Installed${RESET}")"
echo -e "$LINE"
echo -e "${MAGENTA}MySQL Client${RESET} : $(mysql --version 2>/dev/null | awk '{print $5}' | tr -d ',' || echo -e "${GRAY}Not Installed${RESET}")"
echo -e "$LINE"

# --- Update otomatis dari Git (AUTO_UPDATE) ---
# Tiap UPDATE_INTERVAL detik cek commit baru di repo; kalau ada: git pull (hanya maju), pasang ulang paket kalau
# daftar paketnya berubah, lalu muat ulang program AUTO_CMD saja (container & console tidak restart).
# AUTO_CMD memakai pm2 -> "pm2 reload all" (tanpa jeda); selain itu programnya dijalankan ulang (jeda 1-3 detik).
PID_PERINTAH=/tmp/.auto-cmd.pid
TANDA_UPDATE=/tmp/.auto-update
rm -f "$PID_PERINTAH" "$TANDA_UPDATE"

matikan_pohon() {
    local p
    for p in $(pgrep -P "$1" 2>/dev/null); do matikan_pohon "$p"; done
    kill -TERM "$1" 2>/dev/null
}

update_otomatis() {
    cd /home/container || return
    export GIT_TERMINAL_PROMPT=0
    local JEDA="${UPDATE_INTERVAL:-60}" DIPERINGATKAN="" LAMA BARU CABANG BERUBAH PID
    [[ "$JEDA" =~ ^[0-9]+$ ]] && [ "$JEDA" -ge 10 ] || JEDA=60
    echo -e "${CYAN}Update otomatis dari Git aktif, cek tiap ${JEDA} detik.${RESET}"
    while sleep "$JEDA"; do
        CABANG="${BRANCH:-$(git rev-parse --abbrev-ref HEAD 2>/dev/null)}"
        [ -n "$CABANG" ] && [ "$CABANG" != "HEAD" ] || continue
        git fetch --quiet origin "$CABANG" 2>/dev/null || continue
        LAMA=$(git rev-parse HEAD 2>/dev/null)
        BARU=$(git rev-parse FETCH_HEAD 2>/dev/null)
        [ -n "$BARU" ] && [ "$LAMA" != "$BARU" ] || continue
        # repo di server lebih baru dari GitHub (commit lokal): tidak ada yang perlu diambil
        git merge-base --is-ancestor "$BARU" "$LAMA" 2>/dev/null && continue
        if ! git merge-base --is-ancestor "$LAMA" "$BARU" 2>/dev/null || ! git merge --ff-only --quiet "$BARU" 2>/dev/null; then
            if [ "$DIPERINGATKAN" != "$BARU" ]; then
                echo -e "${YELLOW}[update] Ada versi baru ($(git log -1 --format=%s "$BARU" 2>/dev/null)), tapi file di server diubah manual / beda dengan repo. Update dilewati supaya tidak menimpa.${RESET}"
                DIPERINGATKAN="$BARU"
            fi
            continue
        fi
        DIPERINGATKAN=""
        echo -e "${GREEN}${BOLD}[update]${RESET} ${LAMA:0:7} -> ${BARU:0:7}: $(git log -1 --format=%s "$BARU" 2>/dev/null)"
        BERUBAH=$(git diff --name-only "$LAMA" "$BARU" 2>/dev/null)
        if [ -f package.json ] && grep -qE '(^|/)package(-lock)?\.json$' <<< "$BERUBAH"; then
            echo -e "${CYAN}[update] Memasang paket npm...${RESET}"
            npm install --no-audit --no-fund || { echo -e "${YELLOW}[update] npm install gagal, program tidak dimuat ulang.${RESET}"; continue; }
        fi
        if [ -f requirements.txt ] && grep -qx 'requirements.txt' <<< "$BERUBAH"; then
            echo -e "${CYAN}[update] Memasang paket Python...${RESET}"
            python3 -m pip install -q -r requirements.txt || { echo -e "${YELLOW}[update] pip install gagal, program tidak dimuat ulang.${RESET}"; continue; }
        fi
        if [ -f composer.json ] && grep -qE '^composer\.(json|lock)$' <<< "$BERUBAH"; then
            echo -e "${CYAN}[update] Memasang paket Composer...${RESET}"
            composer install --no-interaction || { echo -e "${YELLOW}[update] composer install gagal, program tidak dimuat ulang.${RESET}"; continue; }
        fi
        if [ -z "${AUTO_CMD}" ]; then
            echo -e "${CYAN}[update] Selesai. Jalankan ulang programmu sendiri kalau perlu.${RESET}"
        elif [[ "${AUTO_CMD}" == *pm2* ]]; then
            pm2 reload all --update-env >/dev/null && echo -e "${GREEN}[update] Dimuat ulang lewat pm2 tanpa jeda.${RESET}"
        else
            PID=$(cat "$PID_PERINTAH" 2>/dev/null)
            if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
                echo -e "${CYAN}[update] Memuat ulang program...${RESET}"
                touch "$TANDA_UPDATE"
                matikan_pohon "$PID"
            fi
        fi
    done
}

if [[ "${AUTO_UPDATE}" == "1" || "${AUTO_UPDATE}" == "true" ]]; then
    if [ -d /home/container/.git ]; then
        update_otomatis &
    else
        echo -e "${YELLOW}Update otomatis aktif, tapi folder server bukan repo Git (isi Git Repo Address lalu Reinstall).${RESET}"
    fi
fi

# --- Perintah otomatis (AUTO_CMD) ---
# Diisi di tab Startup (mis. "node server.js"): dijalankan setiap server start / restart, jadi tidak perlu
# mengetik ulang. AUTO_RESTART=1: kalau perintahnya berhenti / crash, dijalankan lagi setelah 3 detik.
# Tombol Stop (sinyal ke proses utama) diteruskan ke perintah supaya berhenti dengan rapi.
if [ -n "${AUTO_CMD}" ]; then
    export NODE_PATH="$NODE_DIR/lib/node_modules"
    cd /home/container
    ANAK=""
    berhenti() {
        trap - INT TERM
        echo -e "\n${YELLOW}Menghentikan perintah otomatis...${RESET}"
        # seluruh proses di grup ini (perintah & anak-anaknya); proses utama sendiri tidak terpengaruh
        kill -TERM 0 2>/dev/null
        wait 2>/dev/null
        exit 0
    }
    trap berhenti INT TERM
    GAGAL_CEPAT=0
    while true; do
        echo -e "${GREEN}${BOLD}Menjalankan perintah otomatis:${RESET} ${AUTO_CMD}"
        echo -e "$LINE"
        MULAI=$(date +%s)
        # stdin console ikut diteruskan (bot yang minta input / nomor pairing tetap bisa diketik)
        bash -c "${AUTO_CMD}" <&0 &
        ANAK=$!
        echo "$ANAK" > "$PID_PERINTAH"
        wait "$ANAK"
        KODE=$?
        ANAK=""
        rm -f "$PID_PERINTAH"
        # dihentikan oleh update otomatis: langsung jalankan versi baru
        if [ -f "$TANDA_UPDATE" ]; then
            rm -f "$TANDA_UPDATE"
            GAGAL_CEPAT=0
            echo -e "$LINE"
            continue
        fi
        echo -e "$LINE"
        echo -e "${YELLOW}Perintah otomatis berhenti (kode ${KODE}).${RESET}"
        if [[ "${AUTO_RESTART}" != "1" && "${AUTO_RESTART}" != "true" ]]; then break; fi
        if [ $(( $(date +%s) - MULAI )) -lt 10 ]; then GAGAL_CEPAT=$(( GAGAL_CEPAT + 1 )); else GAGAL_CEPAT=0; fi
        if [ "$GAGAL_CEPAT" -ge 5 ]; then
            echo -e "${YELLOW}Berhenti 5x berturut-turut dalam 10 detik, jalan ulang otomatis dihentikan. Periksa perintahnya.${RESET}"
            break
        fi
        echo -e "${CYAN}Dijalankan ulang dalam 3 detik...${RESET}"
        sleep 3
    done
    trap - INT TERM
fi

echo -e "${PINK}${BOLD}Silahkan masukan perintah.${RESET}"

exec /bin/bash
