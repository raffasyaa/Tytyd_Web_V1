#!/bin/bash
clear
# Mendefinisikan warna untuk pesan
export RED='\033[0;31m';
export GREEN='\033[0;32m';
export YELLOW='\033[0;33m';
export BLUE='\033[0;34m';
export PURPLE='\033[0;35m';
export CYAN='\033[0;36m';
export LIGHT='\033[0;37m';
export NC='\033[0m';

# Fungsi untuk memeriksa IP dan mendapatkan client_name dan exp_date
check_ip_and_get_info() {
    local ip=$1
    local line
    while IFS= read -r line; do
        if [[ $line == *"$ip"* ]]; then
            client_name=$(echo "$line" | awk '{print $2}')
            exp_date=$(echo "$line" | awk '{print $4}')
            return 0
        fi
    done <<< "$permission_file"
    return 1
}

# Mengambil data client dan expdate dari URL
permission_file=$(curl -s https://raw.githubusercontent.com/helehsemvakwkwk/viavia/main/sholatbro.txt)

# Mengambil informasi sistem
OS=$(lsb_release -ds)
RAM=$(free -m | awk '/Mem:/ { print $2 }')
UPTIME=$(uptime -p)
IP_VPS=$(hostname -I | awk '{print $1}')
ISP=$(curl -s ipinfo.io/org)
DOMAIN=$(cat /etc/data/domain)

# Periksa IP terlebih dahulu
echo -e "${GREEN}♻️ Proses Pengecekan IP...${NC}"
sleep 1
clear

if check_ip_and_get_info "$IP_VPS"; then
    :
else
    echo -e "${RED}💬 Sorry beb, IP anda belum terdaftar di Database saya !${NC}"
    echo -e "🤖 Contact admin :${CYAN}@SaputraTech${NC}"
    exit 1
fi

# Periksa apakah skrip sudah kedaluwarsa
current_date=$(date +%Y-%m-%d)
if [[ "$exp_date" != "Not Found" && $(date -d "$exp_date" +%Y-%m-%d) < $(date -d "$current_date" +%Y-%m-%d) ]]; then
    echo -e "${GREEN}[ INFO ]${NC} ${RED}Script Expired !!!${NC}"
    echo -e "🤖 Contact admin :${CYAN}@SaputraTech${NC}"
    exit 1
fi

# Menghitung sisa hari
if [[ "$exp_date" != "Not Found" ]]; then
    days_remaining=$(( ($(date -d "$exp_date" +%s) - $(date -d "$current_date" +%s)) / 86400 ))
    exp_message="$days_remaining ${YELLOW}days remaining${NC}"
else
    exp_message="Not Found"
fi

# Mengambil nilai domain, port dan token dari file
domain=$(cat /etc/data/domain)
token=$(cat /etc/data/token.json | jq -r .access_token)
port=$(netstat -tunlp | grep 'python' | awk '{split($4, a, ":"); print a[2]}')

# Define the URLs for the version info
GEO_FILES_VERSION_URL="https://api.github.com/repos/rfxcll/v2ray-rules-dat/releases/latest"
LOCAL_GEO_VERSION_FILE="/var/lib/marzban/assets/geo_version.txt"

# Function to check if assets exist
check_assets_exist() {
  [ -f /var/lib/marzban/assets/geositeindo.dat ] && [ -f /var/lib/marzban/assets/geoipindo.dat ]
}

# Function to download and extract Geo-files.zip
download_and_extract_geo_files() {
    # GitHub repository and API endpoint
    REPO="rfxcll/v2ray-rules-dat"
    API_URL="https://api.github.com/repos/$REPO/releases/latest"

    # Fetch the latest release information
    latest_release=$(wget -qO- "$API_URL")

    # Extract the URL for the Geo-files.zip asset
    zip_url=$(echo "$latest_release" | jq -r '.assets[] | select(.name == "Geo-files.zip") | .browser_download_url')

    # Check if we found the zip URL
    if [ -z "$zip_url" ]; then
      echo "Geo-files.zip not found in the latest release."
      exit 1
    fi

    # Download the Geo-files.zip using wget
    wget "$zip_url" -O Geo-files.zip

    # Check if download was successful
    if [ $? -ne 0 ]; then
      echo "Failed to download Geo-files.zip from $zip_url"
      exit 1
    fi

    # Extract the contents of the zip file
    unzip -o Geo-files.zip -d geo_files

    # Check if unzip was successful
    if [ $? -ne 0 ]; then
      echo "Failed to extract Geo-files.zip"
      exit 1
    fi

    # Find the GeoSite.dat file in the extracted files and rename it to geositeindo.dat
    geosite_file=$(find geo_files -name "GeoSite.dat")

    # Check if we found the GeoSite.dat file
    if [ -z "$geosite_file" ]; then
      echo "GeoSite.dat not found in the extracted files."
      exit 1
    fi

    # Rename GeoSite.dat to geositeindo.dat
    mv "$geosite_file" geo_files/geositeindo.dat

    # Find the GeoIP.dat file in the extracted files and rename it to geoipindo.dat
    geoip_file=$(find geo_files -name "GeoIP.dat")

    # Check if we found the GeoIP.dat file
    if [ -z "$geoip_file" ]; then
      echo "GeoIP.dat not found in the extracted files."
      exit 1
    fi

    # Rename GeoIP.dat to geoipindo.dat
    mv "$geoip_file" geo_files/geoipindo.dat

    # Create /var/lib/marzban/assets/ directory if it does not exist
    if [ ! -d /var/lib/marzban/assets/ ]; then
      mkdir -p /var/lib/marzban/assets/
    fi

    # Move geositeindo.dat and geoipindo.dat to /var/lib/marzban/assets/
    mv geo_files/geositeindo.dat /var/lib/marzban/assets/
    mv geo_files/geoipindo.dat /var/lib/marzban/assets/

    # Clean up extracted files and zip
    rm Geo-files.zip
    rm -rf geo_files

    # Get the latest version
    latest_version=$(echo "$latest_release" | jq -r '.tag_name')

    # Save the latest version to a file
    echo "$latest_version" > "$LOCAL_GEO_VERSION_FILE"
}

# Function to get the local version of the Geo files
get_local_geo_version() {
  if [ -f "$LOCAL_GEO_VERSION_FILE" ]; then
    cat "$LOCAL_GEO_VERSION_FILE"
  else
    echo "0"
  fi
}

# Function to get the latest version of the Geo files
get_latest_geo_version() {
  curl -sL "$GEO_FILES_VERSION_URL" | jq -r '.tag_name'
}

# Check if geositeindo.dat and geoipindo.dat exist in /var/lib/marzban/assets/
if check_assets_exist; then
  # Get the local and latest versions
  local_version=$(get_local_geo_version)
  latest_version=$(get_latest_geo_version)

  # Compare versions
  if [ "$local_version" = "$latest_version" ]; then
    echo -e "Versi sudah ${GREEN}terbaru${NC}, Skip Donwload geositeindo.dat dan geoipindo.dat..."
    sleep 1
    echo ""
  else
    echo -e "Versi file GeoSite dan GeoIP ${RED}sudah basi${NC}, Downloading versi terbaru....."
    sleep 1
    download_and_extract_geo_files
  fi
else
  echo -e "File GeoSite dan GeoIP tidak tersedia, ${GREEN}Downloading.....${NC}"
  sleep 1
  download_and_extract_geo_files
fi

# API endpoint and Authorization token
API_URL="https://${domain}:${port}/api/core/config"
AUTH_TOKEN="Bearer ${token}"

# Function to fetch the JSON data from API
fetch_config() {
  curl -s -X 'GET' "$API_URL" \
    -H 'accept: application/json' \
    -H "Authorization: $AUTH_TOKEN"
}

# Function to export the JSON data to API
export_config() {
  local modified_config="$1"
  
  # Check if modified_config file exists
  if [[ ! -f "$modified_config" ]]; then
    echo "Modified JSON file not found: $modified_config"
    exit 1
  fi
  
  # Update the API configuration
  response=$(curl -s -X 'PUT' "$API_URL" \
    -H 'accept: application/json' \
    -H "Authorization: $AUTH_TOKEN" \
    -H 'Content-Type: application/json' \
    -d "@$modified_config")

  # Check for errors in response
  if [[ -z "$response" || "$response" == *"Expecting value"* ]]; then
    echo "Failed to update configuration. Response: $response"
    exit 1
  fi
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo "  ❖ Routing Configuration updated successfully ❖"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Function to add Trojan, VLess, Shadowsocks, or WARP outbound configuration
add_outbound() {
  local response="$1"
  local outbound_json=""

  # Get server type from user
  echo -e "${GREEN}Pilih jenis server tujuan${NC}"
  echo "   1. Trojan"
  echo "   2. VLess"
  echo "   3. Shadowsocks"
  echo "   4. WARP"
  read -p "$(echo -e "Jenis server tujuan ${CYAN}(1/2/3/4)${NC}:")" server_type

  # Get tag for outbound
  read -p "$(echo -e "Masukkan ${CYAN}tag${NC} untuk outbound:")" outbound_tag

  # Skip common details for WARP
  if [ "$server_type" != "4" ]; then
    # Get common server details from user
    read -p "$(echo -e "Masukkan ${CYAN}alamat IP${NC} server tujuan: ")" server_address
    read -p "$(echo -e "Masukkan ${CYAN}port${NC} server tujuan: ")" server_port
    read -p "$(echo -e "Masukkan ${CYAN}domain${NC} server tujuan: ")" server_domain
  fi

  case "$server_type" in
    1)
      # Get Trojan-specific details
      read -p "$(echo -e "Masukkan ${CYAN}password${NC} Trojan server tujuan:")" server_password
      # Get user's choice of plugin for Trojan
      echo "Pilih plugin Trojan server tujuan"
      echo "   1. Websocket"
      echo "   2. gRPC"
      echo "   3. HTTP Upgrade"
      read -p "$(echo -e "Plugin Trojan server tujuan ${CYAN}(1/2/3)${NC}:")" plugin_choice

      case "$plugin_choice" in
        1)
          read -p "$(echo -e "Masukkan ${CYAN}path${NC} untuk Websocket (dengan tanda /):")" ws_path
          outbound_json=$(cat <<EOF
{
  "protocol": "trojan",
  "settings": {
    "servers": [
      {
        "address": "$server_address",
        "password": "$server_password",
        "port": $server_port
      }
    ]
  },
  "streamSettings": {
    "network": "ws",
    "security": "tls",
    "tlsSettings": {
      "allowInsecure": true,
      "alpn": [
        "http/1.1"
      ],
      "serverName": "$server_domain",
      "show": false
    },
    "wsSettings": {
      "headers": {
        "Host": "$server_domain"
      },
      "path": "$ws_path"
    }
  },
  "tag": "$outbound_tag"
}
EOF
)
          ;;
        2)
          read -p "$(echo -e "Masukkan ${CYAN}service name${NC} untuk gRPC:")" grpc_service_name
          outbound_json=$(cat <<EOF
{
  "protocol": "trojan",
  "settings": {
    "servers": [
      {
        "address": "$server_address",
        "password": "$server_password",
        "port": $server_port
      }
    ]
  },
  "streamSettings": {
    "grpcSettings": {
      "serviceName": "$grpc_service_name"
    },
    "network": "grpc",
    "security": "tls",
    "tlsSettings": {
      "allowInsecure": true,
      "alpn": [
        "h2"
      ],
      "serverName": "$server_domain",
      "show": false
    }
  },
  "tag": "$outbound_tag"
}
EOF
)
          ;;
        3)
          read -p "$(echo -e "Masukkan ${CYAN}path untuk HTTP Upgrade${NC} (dengan tanda /):")" http_path
          outbound_json=$(cat <<EOF
{
  "protocol": "trojan",
  "settings": {
    "servers": [
      {
        "address": "$server_address",
        "password": "$server_password",
        "port": $server_port
      }
    ]
  },
  "streamSettings": {
    "httpupgradeSettings": {
      "host": "$server_domain",
      "path": "$http_path"
    },
    "network": "httpupgrade",
    "security": "tls",
    "tlsSettings": {
      "allowInsecure": true,
      "alpn": [
        "http/1.1"
      ],
      "serverName": "$server_domain",
      "show": false
    }
  },
  "tag": "$outbound_tag"
}
EOF
)
          ;;
        *)
          echo "Pilihan plugin tidak valid: $plugin_choice"
          exit 1
          ;;
      esac
      ;;
    2)
      # Get VLess-specific details
      read -p "$(echo -e "Masukkan ${CYAN}ID VLess${NC} server tujuan:")" server_id
      # Get user's choice of plugin for VLess
      echo "Pilih plugin VLess server tujuan"
      echo "   1. Websocket"
      echo "   2. gRPC"
      echo "   3. HTTP Upgrade"
      read -p "Plugin VLess server tujuan (1/2/3): " plugin_choice

      case "$plugin_choice" in
        1)
          read -p "$(echo -e "Masukkan ${CYAN}path untuk Websocket${NC} (dengan tanda /):")" ws_path
          outbound_json=$(cat <<EOF
{
  "protocol": "vless",
  "settings": {
    "vnext": [
      {
        "address": "$server_address",
        "port": $server_port,
        "users": [
          {
            "id": "$server_id",
            "encryption": "none"
          }
        ]
      }
    ]
  },
  "streamSettings": {
    "network": "ws",
    "security": "tls",
    "tlsSettings": {
      "allowInsecure": true,
      "serverName": "$server_domain"
    },
    "wsSettings": {
      "path": "$ws_path"
    }
  },
  "tag": "$outbound_tag"
}
EOF
)
          ;;
        2)
          read -p "$(echo -e "Masukkan ${CYAN}service name${NC} untuk gRPC:")" grpc_service_name
          outbound_json=$(cat <<EOF
{
  "protocol": "vless",
  "settings": {
    "vnext": [
      {
        "address": "$server_address",
        "port": $server_port,
        "users": [
          {
            "id": "$server_id",
            "encryption": "none"
          }
        ]
      }
    ]
  },
  "streamSettings": {
    "network": "grpc",
    "security": "tls",
    "tlsSettings": {
      "allowInsecure": true,
      "serverName": "$server_domain"
    },
    "grpcSettings": {
      "serviceName": "$grpc_service_name"
    }
  },
  "tag": "$outbound_tag"
}
EOF
)
          ;;
        3)
          read -p "$(echo -e "Masukkan ${CYAN}path untuk HTTP Upgrade${NC} (dengan tanda /):")" http_path
          outbound_json=$(cat <<EOF
{
  "protocol": "vless",
  "settings": {
    "vnext": [
      {
        "address": "$server_address",
        "port": $server_port,
        "users": [
          {
            "id": "$server_id",
            "encryption": "none"
          }
        ]
      }
    ]
  },
  "streamSettings": {
    "network": "httpupgrade",
    "security": "tls",
    "tlsSettings": {
      "allowInsecure": true,
      "serverName": "$server_domain"
    },
    "httpupgradeSettings": {
      "path": "$http_path"
    }
  },
  "tag": "$outbound_tag"
}
EOF
)
          ;;
        *)
          echo "Pilihan plugin tidak valid: $plugin_choice"
          exit 1
          ;;
      esac
      ;;
    3)
      # Get Shadowsocks-specific details
      read -p "$(echo -e "Masukkan ${CYAN}password Shadowsocks${NC} server tujuan:")" server_password
	  echo "Pilih method Shadowsocks server tujuan"
      echo "   1. aes-128-gcm"
      echo "   2. aes-256-gcm"
      echo "   3. chacha20-ietf-poly1305"
      read -p "$(echo -e "method Shadowsocks server tujuan ${CYAN}(1/2/3)${NC}:")" ss_method_choice
	  
	  # Set ss_method based on user choice using case
  case "$ss_method_choice" in
    1)
      server_method="aes-128-gcm"
      ;;
    2)
      server_method="aes-256-gcm"
      ;;
    3)
      server_method="chacha20-ietf-poly1305"
      ;;
    *)
      echo "Pilihan tidak valid: $ss_method_choice"
      exit 1
      ;;
esac
      outbound_json=$(cat <<EOF
{
  "protocol": "shadowsocks",
  "settings": {
    "servers": [
      {
        "address": "$server_address",
        "port": $server_port,
        "method": "$server_method",
        "password": "$server_password"
      }
    ]
  },
  "tag": "$outbound_tag"
}
EOF
)
      ;;
    4)
      # WARP does not require additional input
      outbound_json=$(cat <<EOF
{
  "tag": "$outbound_tag",
  "protocol": "socks",
  "settings": {
    "servers": [
      {
        "address": "127.0.0.1",
        "port": 40000
      }
    ]
  }
}
EOF
)
      ;;
    *)
      echo "Pilihan jenis server tidak valid: $server_type"
      exit 1
      ;;
  esac

  # Display user choices
  echo -e "========================================="
  echo -e "     ${CYAN}❏ Pilihan routing situs ❏${NC}"
  echo -e "========================================="
  echo "A. Pilihan routing domain yang sudah ada"
  echo "   1. Youtube"
  echo "   2. Playstore"
  echo "   3. Netflix"
  echo "   4. Vidio"
  echo "   5. Viu"
  echo "   6. RCTI+"
  echo "   7. Vision+"
  echo "   8. UseeTV + IndiHome + MAXStream"
  echo "   9. Meta Group (FB, IG, WA, THREAD)"
  echo "   10. Disney"
  echo "   11. Iqiyi"
  echo "   12. Bilibili / Bstation"
  echo "   13. Twitter / X"
  echo "   14. Telegram"
  echo "   15. Speedtest"
  echo "   16. Tiktok"
  echo "   17. All-in-1 Indonesia Site"
  echo "   18. Bank Indonesia"
  echo "   19. Ecommerce Indonesia"
  echo "   20. Rule situs IP-Checker"
  echo ""
  echo "B. Pilihan routing Regex"
  echo "C. Pilihan domain manual"
  echo "========================================="

  local valid_choice=true
  local domains=()

  while true; do
    echo -e "${CYAN}❏ Masukkan pilihan Anda : ❏${NC}"
    echo -e "Pisahkan dengan koma, ${GREEN}misalnya A1,A2${NC}"
    echo -e "Mode regex ${GREEN}( isi B )${NC}"
    echo -e "Mode manual ${GREEN}( isi C )${NC}"
    echo ""
    read -p "Pilihan kamu: " user_choices
    IFS=',' read -ra choices <<< "$user_choices"

    for choice in "${choices[@]}"; do
      case "$choice" in
        A1)
          domains+=('ext:geositeindo.dat:youtube')
          ;;
        A2)
          domains+=('ext:geositeindo.dat:rule-playstore')
          ;;
        A3)
          domains+=('ext:geositeindo.dat:netflix')
          ;;
        A4)
          domains+=('domain:vidio.com' 'domain:prod.vidiocdn.com' 'domain:secureswiftcontent.com' 'full:license-global.pallycon.com' 'full:media-vidio-com.akamaized.net' 'full:etslive-2-vidio-com.akamaized.net' 'full:token-media-vidio-com.akamaized.net' 'full:static-web-prod-vidio.akamaized.net' 'full:geo-id-media-vidio-com.akamaized.net' 'full:geo-id-tl-media-vidio-com.akamaized.net' 'full:static-playback-vidio-com.akamaized.net' 'full:live-production.secureswiftcontent.com')
          ;;
        A5)
          domains+=('ext:geositeindo.dat:viu')
          ;;
        A6)
          domains+=('domain:mncplus.id' 'domain:rctiplus.com' 'domain:rctiplus.id' 'domain:rcti.plus' 'domain:roov.id' 'regexp:.*rcti.*')
          ;;
		    A7)
          domains+=('domain:visionplus.id' 'domain:rmp-data.com' 'full:stream-cdn.mncnow.id' 'full:dtaarjaj1diy9.cloudfront.net' 'full:mrpw.ptmnc01.verspective.net' 'regexp:.*visionplus.*')
          ;;
		    A8)
          domains+=('domain:useetv.com' 'domain:indihometv.com' 'domain:useetvgo.com' 'regexp:.*useetv.*' 'regexp:.*telkomsel.*')
          ;;
        A9)
          domains+=('ext:geositeindo.dat:meta')
          ;;
        A10)
          domains+=('ext:geositeindo.dat:disney')
          ;;
        A11)
          domains+=('ext:geositeindo.dat:iqiyi')
          ;;
        A12)
          domains+=('ext:geositeindo.dat:bilibili')
          ;;
        A13)
          domains+=('ext:geositeindo.dat:twitter')
          ;;
        A14)
          domains+=('ext:geositeindo.dat:telegram')
          ;;
        A15)
          domains+=('ext:geositeindo.dat:rule-speedtest')
          ;;
        A16)
          domains+=('ext:geositeindo.dat:tiktok')
          ;;
        A17)
          domains+=('ext:geositeindo.dat:rule-indo')
          ;;
        A18)
          domains+=('ext:geositeindo.dat:bank-id')
          ;;
        A19)
          domains+=('ext:geositeindo.dat:ecommerce-id')
          ;;
		    A20)
          domains+=('ext:geositeindo.dat:rule-ipcheck')
          ;;	
        B)
          read -p "$(echo -e "Masukkan kata kunci sebuah situs ${CYAN}(contoh situs mnc, maka isi saja mnc)${NC}:")" regex
          domains+=("regexp:.*$regex.*")
          ;;
        C)
          echo -e "${CYAN}❏ Masukkan domain manual : ❏${NC}"
          echo -e "Pisahkan dengan koma, ${GREEN}jika lebih dari satu${NC}"
          echo -e "Tanpa ${GREEN}http://${NC} atau ${GREEN}https://${NC}"
          echo -e "Contoh ${GREEN}facebook.com${NC}"
          read -p "" manual_domains
          IFS=',' read -r -a manual_domains_array <<< "$manual_domains"
          for domain in "${manual_domains_array[@]}"; do
              domains+=("domain:$domain")
          done
          ;;
        *)
          echo "Pilihan tidak valid: $choice"
          valid_choice=false
          ;;
      esac
    done

    if $valid_choice; then
      break
    else
      echo "Silakan coba lagi."
      valid_choice=true
    fi
  done
  
  # New variable to add
  new_rule=$(jq -n \
    --argjson domains "$(printf '%s\n' "${domains[@]}" | jq -R . | jq -s .)" \
    --arg outbound_tag "$outbound_tag" \
    '{
      "domain": $domains,
      "outboundTag": $outbound_tag,
      "network": "tcp,udp",
      "type": "field"
    }')

  # Move the newly added routing rule below dns-out
  modified_response=$(echo "$response" | jq --argjson new_rule "$new_rule" '
    .routing.rules |= [.[] | select(.outboundTag == "dns-out")] + [$new_rule] + [.[] | select(.outboundTag != "dns-out")]
  ')

  # Check if outbounds array exists, otherwise initialize it
  if [[ -z $(echo "$response" | jq '.outbounds') ]]; then
    modified_response=$(echo "$modified_response" | jq '. + {"outbounds": []}')
  fi

  # Check if outbound with the same tag already exists
  if [[ -n $(echo "$response" | jq '.outbounds[] | select(.tag == "'"$outbound_tag"'")') ]]; then
    echo "Outbound dengan tag '$outbound_tag' sudah ada."
    exit 1
  fi

  # Add the new outbound configuration
  modified_response=$(echo "$modified_response" | jq --argjson new_outbound "$outbound_json" '
    .outbounds |= [.[] | select(.tag != "dns-out")] + [$new_outbound] + [.[] | select(.tag == "dns-out")]
  ')

  # Save the modified JSON to a file (optional)
  modified_config="/tmp/modified_config.json"
  echo "$modified_response" > "$modified_config"

  # Export the modified JSON
  export_config "$modified_config"
}

# Call the function

# Function to display available tags and delete rules by selected tag
delete_rules_by_tag() {
  local response="$1"

  # Extract unique tags from routing rules and match with their types from outbounds
  tags_and_types=$(echo "$response" | jq -c '
    [
      (.routing.rules[] | {tag: .outboundTag, type: "routing rule"}),
      (.outbounds[] | {tag: .tag, type: .protocol})
    ] | group_by(.tag) | map({
      tag: .[0].tag,
      type: (map(select(.type != "routing rule")) | if length > 0 then .[0].type else "routing rule" end)
    }) | .[] | select(.tag != "direct" and .tag != "block" and .tag != "dns-out")
  ')

  if [ -z "$tags_and_types" ]; then
    echo "Tidak ada tag yang tersedia untuk dihapus."
    exit 1
  fi

  echo "Daftar tag yang tersedia:"
  IFS=$'\n' read -rd '' -a tag_array <<<"$tags_and_types"
  for i in "${!tag_array[@]}"; do
    tag=$(echo "${tag_array[i]}" | jq -r '.tag')
    type=$(echo "${tag_array[i]}" | jq -r '.type')
    echo "$((i+1)). $tag (Type: $type)"
  done

  read -p "Pilih nomor tag yang ingin dihapus: " tag_choice

  if [[ "$tag_choice" -lt 1 || "$tag_choice" -gt "${#tag_array[@]}" ]]; then
    echo "Pilihan tidak valid: $tag_choice"
    exit 1
  fi

  delete_tag=$(echo "${tag_array[$((tag_choice-1))]}" | jq -r '.tag')
  echo "Menghapus aturan dengan tag: $delete_tag"

  # Menghapus aturan routing berdasarkan tag
  modified_response=$(echo "$response" | jq --arg delete_tag "$delete_tag" '
    .routing.rules |= map(select(.outboundTag != $delete_tag))
  ')

  # Menghapus aturan outbound berdasarkan tag
  modified_response=$(echo "$modified_response" | jq --arg delete_tag "$delete_tag" '
    .outbounds |= map(select(.tag != $delete_tag))
  ')

  modified_config="/tmp/modified_config.json"
  echo "$modified_response" > "$modified_config"

  echo "Loading Configuration..."
  export_config "$modified_config"
}

# Function to add domain list to an existing routing rule tag
add_domain_to_existing_tag() {
  local response="$1"

  # Extract unique tags and their types from routing rules and outbound rules, excluding "direct", "block", and "dns-out"
  tags=$(echo "$response" | jq -r '
    [.routing.rules[].outboundTag as $tag | select($tag != "direct" and $tag != "block" and $tag != "dns-out") | {tag: $tag, type: (.outbounds[] | select(.tag == $tag).protocol)}] 
    | unique | .[] | "\(.tag) (\(.type))"'
  )

  if [ -z "$tags" ]; then
    echo "Tidak ada tag yang tersedia untuk menambahkan aturan domain."
    exit 1
  fi

  echo "Daftar tag yang tersedia:"
  IFS=$'\n' read -rd '' -a tag_array <<<"$tags"
  for i in "${!tag_array[@]}"; do
    echo "$((i+1)). ${tag_array[i]}"
  done

  read -p "Pilih nomor tag yang ingin ditambahkan aturan domain: " tag_choice

  if [[ "$tag_choice" -lt 1 || "$tag_choice" -gt "${#tag_array[@]}" ]]; then
    echo "Pilihan tidak valid: $tag_choice"
    exit 1
  fi

  selected_tag="${tag_array[$((tag_choice-1))]}"
  selected_tag="${selected_tag%% (*)}"  # Remove the protocol part for further use
  echo "Menambahkan aturan domain ke tag: $selected_tag"

  # Display user choices
      echo -e "========================================="
      echo -e "     ${CYAN}❏ Pilihan routing situs ❏${NC}"
      echo -e "========================================="
      echo "A. Pilihan routing domain yang sudah ada"
      echo "   1. Youtube"
      echo "   2. Playstore"
      echo "   3. Netflix"
      echo "   4. Vidio"
      echo "   5. Viu"
      echo "   6. RCTI+"
      echo "   7. Vision+"
      echo "   8. UseeTV + IndiHome + MAXStream"
      echo "   9. Meta Group (FB, IG, WA, THREAD)"
      echo "   10. Disney"
      echo "   11. Iqiyi"
      echo "   12. Bilibili / Bstation"
      echo "   13. Twitter / X"
      echo "   14. Telegram"
      echo "   15. Speedtest"
      echo "   16. Tiktok"
      echo "   17. All-in-1 Indonesia Site"
      echo "   18. Bank Indonesia"
      echo "   19. Ecommerce Indonesia"
      echo "   20. Rule situs IP-Checker"
      echo ""
      echo "B. Pilihan routing Regex"
      echo "C. Pilihan domain manual"
      echo "========================================="
      echo ""

		  local valid_choice=true
		  local domains=()

		  while true; do
      echo -e "${CYAN}❏ Masukkan pilihan Anda : ❏${NC}"
      echo -e "Pisahkan dengan koma, ${GREEN}misalnya A1,A2${NC}"
      echo -e "Mode regex ${GREEN}( isi B )${NC}"
      echo -e "Mode manual ${GREEN}( isi C )${NC}"
      echo ""
      read -p "Pilihan kamu: " user_choices
			IFS=',' read -ra choices <<< "$user_choices"

			for choice in "${choices[@]}"; do
			  case "$choice" in
				A1)
				  domains+=('ext:geositeindo.dat:youtube')
				  ;;
				A2)
				  domains+=('ext:geositeindo.dat:rule-playstore')
				  ;;
				A3)
				  domains+=('ext:geositeindo.dat:netflix')
				  ;;
				A4)
				  domains+=('domain:vidio.com' 'domain:prod.vidiocdn.com' 'domain:secureswiftcontent.com' 'full:license-global.pallycon.com' 'full:media-vidio-com.akamaized.net' 'full:etslive-2-vidio-com.akamaized.net' 'full:token-media-vidio-com.akamaized.net' 'full:static-web-prod-vidio.akamaized.net' 'full:geo-id-media-vidio-com.akamaized.net' 'full:geo-id-tl-media-vidio-com.akamaized.net' 'full:static-playback-vidio-com.akamaized.net' 'full:live-production.secureswiftcontent.com')
				  ;;
				A5)
				  domains+=('ext:geositeindo.dat:viu')
				  ;;
				A6)
				  domains+=('domain:mncplus.id' 'domain:rctiplus.com' 'domain:rctiplus.id' 'domain:rcti.plus' 'domain:roov.id' 'regexp:.*rcti.*')
				  ;;
				A7)
				  domains+=('domain:visionplus.id' 'domain:rmp-data.com' 'full:stream-cdn.mncnow.id' 'full:dtaarjaj1diy9.cloudfront.net' 'full:mrpw.ptmnc01.verspective.net' 'regexp:.*visionplus.*')
				  ;;
				A8)
				  domains+=('domain:useetv.com' 'domain:indihometv.com' 'domain:useetvgo.com' 'regexp:.*useetv.*' 'regexp:.*telkomsel.*')
				  ;;
				A9)
				  domains+=('ext:geositeindo.dat:meta')
				  ;;
				A10)
				  domains+=('ext:geositeindo.dat:disney')
				  ;;
				A11)
				  domains+=('ext:geositeindo.dat:iqiyi')
				  ;;
				A12)
				  domains+=('ext:geositeindo.dat:bilibili')
				  ;;
				A13)
				  domains+=('ext:geositeindo.dat:twitter')
				  ;;
				A14)
				  domains+=('ext:geositeindo.dat:telegram')
				  ;;
				A15)
				  domains+=('ext:geositeindo.dat:rule-speedtest')
				  ;;
				A16)
				  domains+=('ext:geositeindo.dat:tiktok')
				  ;;
				A17)
				  domains+=('ext:geositeindo.dat:rule-indo')
				  ;;
				A18)
				  domains+=('ext:geositeindo.dat:bank-id')
				;;
				A19)
				domains+=('ext:geositeindo.dat:ecommerce-id')
				;;
				A20)
				domains+=('ext:geositeindo.dat:rule-ipcheck')
				;;	
            B)
                read -p "$(echo -e "Masukkan kata kunci sebuah situs ${CYAN}(contoh situs mnc, maka isi saja mnc)${NC}:")" regex
                domains+=("regexp:.*$regex.*")
                ;;
            C)
                echo -e "${CYAN}❏ Masukkan domain manual : ❏${NC}"
                echo -e "Pisahkan dengan koma, ${GREEN}jika lebih dari satu${NC}"
                echo -e "Tanpa ${GREEN}http://${NC} atau ${GREEN}https://${NC}"
                echo -e "Contoh ${GREEN}facebook.com${NC}"
                echo ""
                read -p "Domain Custom kamu: " manual_domains
                IFS=',' read -r -a manual_domains_array <<< "$manual_domains"
                for domain in "${manual_domains_array[@]}"; do
                    domains+=("domain:$domain")
                done
                ;;
            *)
                echo "Pilihan tidak valid: $choice"
                valid_choice=false
                break
                ;;
        esac
    done

    if $valid_choice; then
        break
    else
        echo "Silakan coba lagi."
    fi
done

# Function to check if a domain already exists
domain_exists() {
    local domain="$1"
    echo "$response" | jq -e --arg domain "$domain" --arg outbound_tag "$selected_tag" '
        any(.routing.rules[]? | select(.outboundTag == $outbound_tag).domain[]; . == $domain)
    ' > /dev/null
}

# Check for duplicate domains
duplicates=()
valid_domains=()
for domain in "${domains[@]}"; do
    if domain_exists "$domain"; then
        duplicates+=("$domain")
    else
        valid_domains+=("$domain")
    fi
done

if [ ${#duplicates[@]} -ne 0 ]; then
    echo "Domain berikut sudah ada dalam konfigurasi: ${duplicates[*]}"
    echo "Silakan pilih domain lain."
else
    # Lakukan sesuatu dengan valid_domains di sini
    echo "Domain valid: ${valid_domains[*]}"
fi


  # Update the existing routing rule with the new domains
  modified_response=$(echo "$response" | jq --argjson domains "$(printf '%s\n' "${valid_domains[@]}" | jq -R . | jq -s .)" --arg outbound_tag "$selected_tag" '
    .routing.rules |= map(if .outboundTag == $outbound_tag then .domain |= (. + $domains | unique) else . end)
  ')

  modified_config="/tmp/modified_config.json"
  echo "$modified_response" > "$modified_config"

  echo "Loading Configuration..."
  export_config "$modified_config"
}

# Function to remove domain list from an existing routing rule tag and associated outbound rule if applicable
remove_domain_from_existing_tag() {
  local response="$1"

  # Extract unique tags and their types from routing rules, excluding "direct", "block", and "dns-out"
  tags=$(echo "$response" | jq -r '
    [.routing.rules[].outboundTag as $tag | select($tag != "direct" and $tag != "block" and $tag != "dns-out") | {tag: $tag, type: (.outbounds[] | select(.tag == $tag).protocol)}] 
    | unique | .[] | "\(.tag) (\(.type))"'
  )

  if [ -z "$tags" ]; then
    echo "Tidak ada tag yang tersedia untuk menghapus aturan domain."
    exit 1
  fi

  echo "Daftar tag yang tersedia untuk menghapus domain:"
  IFS=$'\n' read -rd '' -a tag_array <<<"$tags"
  for i in "${!tag_array[@]}"; do
    echo "$((i+1)). ${tag_array[i]}"
  done

  read -p "Pilih nomor tag yang ingin dihapus domainnya: " tag_choice

  if [[ "$tag_choice" -lt 1 || "$tag_choice" -gt "${#tag_array[@]}" ]]; then
    echo "Pilihan tidak valid: $tag_choice"
    exit 1
  fi

  selected_tag="${tag_array[$((tag_choice-1))]}"
  selected_tag="${selected_tag%% (*)}"  # Remove the protocol part for further use
  echo "Menghapus domain dari tag: $selected_tag"

  # Display current domains in the selected tag
  current_domains=$(echo "$response" | jq -r --arg selected_tag "$selected_tag" '.routing.rules[] | select(.outboundTag == $selected_tag) | .domain[]')

  if [ -z "$current_domains" ]; then
    echo "Tidak ada domain yang terdaftar untuk tag ini."
    exit 1
  fi

  # Convert current domains to an array
  readarray -t current_domains_array <<<"$current_domains"

  # Display current domains for selected tag with numbered options
  echo "Domain yang saat ini terdaftar untuk tag $selected_tag:"
  for index in "${!current_domains_array[@]}"; do
    domain_display=$(echo "${current_domains_array[index]}" | sed -E 's/^(ext:geositeindo\.dat:|regexp:|domain:)//')
    echo "$((index+1)). $domain_display"
  done

  # Get domain selection from user
  read -p "Pilih nomor domain yang ingin dihapus atau pisahkan dengan koma untuk memilih beberapa: " domain_selection

  # Convert domain selection to array
  IFS=',' read -r -a selection_array <<<"$domain_selection"

  # Prepare array of domains to remove
  domains_to_remove=()
  for index in "${selection_array[@]}"; do
    domains_to_remove+=("${current_domains_array[$((index-1))]}")
  done

  # Remove specified domains from the current list
  new_domains=()
  for domain in "${current_domains_array[@]}"; do
    if [[ ! " ${domains_to_remove[@]} " =~ " $domain " ]]; then
      new_domains+=("$domain")
    fi
  done

  # Update the existing routing rule with the new domains or remove the rule if no domains left
  if [ ${#new_domains[@]} -eq 0 ]; then
    # If no domains left, remove the entire routing rule and associated outbound rule
    modified_response=$(echo "$response" | jq --arg selected_tag "$selected_tag" '
      .routing.rules |= map(select(.outboundTag != $selected_tag)) |
      .outbounds |= map(select(.tag != $selected_tag))
    ')
  else
    # Otherwise, update the routing rule with the new domain list
    modified_response=$(echo "$response" | jq --argjson new_domains "$(printf '%s\n' "${new_domains[@]}" | jq -R . | jq -s .)" --arg selected_tag "$selected_tag" '
      .routing.rules |= map(if .outboundTag == $selected_tag then .domain = $new_domains else . end)
    ')
  fi

  modified_config="/tmp/modified_config.json"
  echo "$modified_response" >"$modified_config"

  echo "Loading Configuration..."
  export_config "$modified_config"
}

# Function to add a new routing rule at the top if ASN is Biznet
add_disable_quic() {
  local response="$1"

# Get public IP address using icanhazip.com
ip_address=$(curl -sS https://icanhazip.com)

echo "IP address Anda adalah: $ip_address"

# Check ASN using ipinfo.io API
asn=$(curl -sS "https://ipinfo.io/${ip_address}/json" | jq -r '.org')

# Check if ASN is Biznet
if [[ "$asn" != *"Biznet"* ]]; then
    echo "Hanya khusus VM Biznet, batalkan"
	echo "ASN untuk IP $ip_address adalah: $asn"
    exit 1
fi

echo "ASN untuk IP $ip_address adalah: $asn"

  # Define the new rule
  new_rule=$(jq -n '{
    "type": "field",
    "port": "443",
    "network": "udp",
    "outboundTag": "block"
  }')

  # Add the new rule at the top of the routing rules
  modified_response=$(echo "$response" | jq --argjson new_rule "$new_rule" '
    .routing.rules |= [$new_rule] + .
  ')

  modified_config="/tmp/modified_config.json"
  echo "$modified_response" > "$modified_config"

  echo "Konfigurasi JSON yang dimodifikasi setelah menambahkan aturan routing baru disimpan ke $modified_config."
  export_config "$modified_config"
}

# Function to edit outbound configuration (supports Shadowsocks, Trojan)
edit_outbound() {
  local response="$1"
  local modified_response="$response"

  # Display existing outbounds with protocol and tags
  echo "Outbound configurations available:"
  local outbounds_list=$(echo "$modified_response" | jq -r '.outbounds[] | select(.protocol == "shadowsocks" or .protocol == "trojan" or .protocol == "vless") | "\(.tag) - \(.protocol) - \(.streamSettings.network): \(.settings.servers[0].address):\(.settings.servers[0].port)"')

  if [ -z "$outbounds_list" ]; then
    echo "No applicable outbound configurations found."
    return 1
  fi

  local index=1
  local tags=()
  while IFS= read -r line; do
    echo "$index. $line"
    tags+=("$(echo "$line" | awk '{print $1}')")
    index=$((index + 1))
  done <<< "$outbounds_list"

  # Get the tag of the outbound configuration to edit
  read -p "Enter the number of the outbound configuration you want to edit: " choice

  if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -ge "$index" ]; then
    echo "Invalid choice."
    return 1
  fi

  local outbound_tag="${tags[$((choice - 1))]}"

  # Check if the outbound with the given tag exists
  outbound_exists=$(echo "$modified_response" | jq -e --arg tag "$outbound_tag" '.outbounds[] | select(.tag == $tag)')

  if [ -z "$outbound_exists" ]; then
    echo "Outbound with tag '$outbound_tag' not found."
    return 1
  fi

  # Determine the protocol and plugin of the outbound configuration
  protocol=$(echo "$outbound_exists" | jq -r '.protocol')
  plugin=$(echo "$outbound_exists" | jq -r '.streamSettings.network')

  case "$protocol" in
    "shadowsocks")
      edit_shadowsocks_outbound "$outbound_tag" "$modified_response"
      ;;
    "trojan")
      edit_trojan_outbound "$outbound_tag" "$modified_response" "$plugin"
      ;;
	"vless")
      edit_vless_outbound "$outbound_tag" "$modified_response" "$plugin"
      ;; 
    *)
      echo "Unsupported protocol: $protocol"
      return 1
      ;;
  esac
}

# Function to edit Shadowsocks outbound configuration
edit_shadowsocks_outbound() {
  local outbound_tag="$1"
  local modified_response="$2"

  echo "Editing Shadowsocks configuration..."
  read -p "Enter the new address of Shadowsocks server: " ss_address
  read -p "Enter the new port of Shadowsocks server: " ss_port
  read -p "Enter the new password of Shadowsocks server: " ss_password
  echo "Choose Shadowsocks method for the new server:"
  echo "   1. aes-128-gcm"
  echo "   2. aes-256-gcm"
  echo "   3. chacha20-ietf-poly1305"
  read -p "Method for Shadowsocks server (1/2/3): " ss_method_choice

  # Set ss_method based on user choice using case
  case "$ss_method_choice" in
    1)
      ss_method="aes-128-gcm"
      ;;
    2)
      ss_method="aes-256-gcm"
      ;;
    3)
      ss_method="chacha20-ietf-poly1305"
      ;;
    *)
      echo "Invalid choice: $ss_method_choice"
      exit 1
      ;;
  esac

  # Update outbound configuration for Shadowsocks
  modified_response=$(echo "$modified_response" | jq --arg tag "$outbound_tag" --arg ss_address "$ss_address" --arg ss_port "$ss_port" --arg ss_password "$ss_password" --arg ss_method "$ss_method" '
    .outbounds = (.outbounds | map(
      if .tag == $tag and .protocol == "shadowsocks" then
        .settings.servers[0].address = $ss_address |
        .settings.servers[0].port = ($ss_port | tonumber) |
        .settings.servers[0].password = $ss_password |
        .settings.servers[0].method = $ss_method
      else
        .
      end
    ))
  ')

  # Save the modified JSON to a file (optional)
  save_modified_config "$modified_response"

  echo "Shadowsocks configuration updated."
}

# Function to edit Trojan outbound configuration
edit_trojan_outbound() {
  local outbound_tag="$1"
  local modified_response="$2"
  local plugin="$3"

  echo "Editing Trojan configuration..."
  read -p "Enter the new address of Trojan server: " address
  read -p "Enter the new port of Trojan server: " port
  read -p "Enter the new password of Trojan server: " password
  read -p "Enter the new domain of Trojan server: " domain

  case "$plugin" in
    "ws")
      read -p "Masukkan path baru untuk Websocket (dengan tanda /): " ws_path
      modified_response=$(echo "$modified_response" | jq --arg tag "$outbound_tag" --arg address "$address" --arg port "$port" --arg password "$password" --arg domain "$domain" --arg ws_path "$ws_path" '
        .outbounds = (.outbounds | map(
          if .tag == $tag and .protocol == "trojan" then
            .settings.servers[0].address = $address |
            .settings.servers[0].port = ($port | tonumber) |
            .settings.servers[0].password = $password |
            .streamSettings.network = "ws" |
            .streamSettings.security = "tls" |
            .streamSettings.tlsSettings.serverName = $domain |
			.streamSettings.wsSettings.host = $domain |
            .streamSettings.wsSettings.path = $ws_path
          else
            .
          end
        ))
      ')
      ;;
    "grpc")
      read -p "Masukkan service name baru untuk gRPC: " grpc_service_name
      modified_response=$(echo "$modified_response" | jq --arg tag "$outbound_tag" --arg address "$address" --arg port "$port" --arg password "$password" --arg domain "$domain" --arg grpc_service_name "$grpc_service_name" '
        .outbounds = (.outbounds | map(
          if .tag == $tag and .protocol == "trojan" then
            .settings.servers[0].address = $address |
            .settings.servers[0].port = ($port | tonumber) |
            .settings.servers[0].password = $password |
            .streamSettings.network = "grpc" |
            .streamSettings.security = "tls" |
            .streamSettings.tlsSettings.serverName = $domain |
            .streamSettings.grpcSettings.serviceName = $grpc_service_name
          else
            .
          end
        ))
      ')
      ;;
    "httpupgrade")
      read -p "Masukkan path baru untuk HTTP Upgrade (dengan tanda /): " http_path
      modified_response=$(echo "$modified_response" | jq --arg tag "$outbound_tag" --arg address "$address" --arg port "$port" --arg password "$password" --arg domain "$domain" --arg http_path "$http_path" '
        .outbounds = (.outbounds | map(
          if .tag == $tag and .protocol == "trojan" then
            .settings.servers[0].address = $address |
            .settings.servers[0].port = ($port | tonumber) |
            .settings.servers[0].password = $password |
            .streamSettings.network = "httpupgrade" |
            .streamSettings.security = "tls" |
            .streamSettings.tlsSettings.serverName = $domain |
			.streamSettings.httpupgradeSettings.host = $domain |
            .streamSettings.httpupgradeSettings.path = $http_path
          else
            .
          end
        ))
      ')
      ;;
    *)
      echo "Unsupported plugin: $plugin"
      return 1
      ;;
  esac

  # Save the modified JSON to a file (optional)
  save_modified_config "$modified_response"

  echo "Trojan configuration updated."
}

# Function to edit VLESS outbound configuration
edit_vless_outbound() {
  local outbound_tag="$1"
  local modified_response="$2"
  local plugin="$3"

  echo "Editing VLESS configuration..."
  read -p "Enter the new address of VLESS server: " address
  read -p "Enter the new port of VLESS server: " port
  read -p "Enter the new user UUID of VLESS server: " id
  read -p "Enter the new domain of VLESS server: " domain

  case "$plugin" in
    "ws")
      read -p "Masukkan path baru untuk Websocket (dengan tanda /): " ws_path
      modified_response=$(echo "$modified_response" | jq --arg tag "$outbound_tag" --arg address "$address" --arg port "$port" --arg id "$id" --arg domain "$domain" --arg ws_path "$ws_path" '
        .outbounds = (.outbounds | map(
          if .tag == $tag and .protocol == "vless" then
            .settings.vnext[0].address = $address |
            .settings.vnext[0].port = ($port | tonumber) |
            .settings.vnext[0].users[0].id = $id |
            .streamSettings.network = "ws" |
            .streamSettings.security = "tls" |
            .streamSettings.tlsSettings.serverName = $domain |
			.streamSettings.wsSettings.host = $domain |
            .streamSettings.wsSettings.path = $ws_path
          else
            .
          end
        ))
      ')
      ;;
    "grpc")
      read -p "Masukkan service name baru untuk gRPC: " grpc_service_name
      modified_response=$(echo "$modified_response" | jq --arg tag "$outbound_tag" --arg address "$address" --arg port "$port" --arg id "$id" --arg domain "$domain" --arg grpc_service_name "$grpc_service_name" '
        .outbounds = (.outbounds | map(
          if .tag == $tag and .protocol == "vless" then
            .settings.vnext[0].address = $address |
            .settings.vnext[0].port = ($port | tonumber) |
            .settings.vnext[0].users[0].id = $id |
            .streamSettings.network = "grpc" |
            .streamSettings.security = "tls" |
            .streamSettings.tlsSettings.serverName = $domain |
            .streamSettings.grpcSettings.serviceName = $grpc_service_name
          else
            .
          end
        ))
      ')
      ;;
    "httpupgrade")
      read -p "Masukkan path baru untuk Websocket (dengan tanda /): " http_path
      modified_response=$(echo "$modified_response" | jq --arg tag "$outbound_tag" --arg address "$address" --arg port "$port" --arg id "$id" --arg domain "$domain" --arg http_path "$http_path" '
        .outbounds = (.outbounds | map(
          if .tag == $tag and .protocol == "vless" then
            .settings.vnext[0].address = $address |
            .settings.vnext[0].port = ($port | tonumber) |
            .settings.vnext[0].users[0].id = $id |
            .streamSettings.network = "httpupgrade" |
            .streamSettings.security = "tls" |
            .streamSettings.tlsSettings.serverName = $domain |
			.streamSettings.httpupgradeSettings.host = $domain |
            .streamSettings.httpupgradeSettings.path = $http_path
          else
            .
          end
        ))
      ')
      ;;
    *)
      echo "Unsupported plugin: $plugin"
      return 1
      ;;
  esac

  # Save the modified JSON to a file (optional)
  save_modified_config "$modified_response"

  echo "VLESS configuration updated."
}

# Function to save modified configuration (optional)
save_modified_config() {
  local modified_response="$1"
  modified_config="/tmp/modified_config.json"
  echo "$modified_response" > "$modified_config"
  # Export the modified JSON
  export_config "$modified_config"
}

# Main Script logic
main() {
  # Fetch the JSON configuration from API
  response=$(fetch_config)

  # Check if response is valid JSON
  if [[ -z "$response" || "$response" == *"Expecting value"* ]]; then
    echo "Failed to fetch configuration from API."
    exit 1
  fi

  # Display menu
  echo -e "\e[1;34m ======================================================"
  echo -e "      ${CYAN}💠 SKARTI X AWN Project 💠${NC}"
  echo -e " ======================================================\e[0m"
  echo -e "╭───────────────────────────────────────────────╮"
  echo -e "│1.) Tambah Rule routing"
  echo -e "│2.) Hapus Rule routing"
  echo -e "│3.) Tambah domain list ke tag rule yang sudah ada"
  echo -e "│4.) Hapus domain list dari tag rule yang sudah ada"
  echo -e "│5.) Edit server tujuan routing"
  echo -e "│6.) Disable Quic (Jamu khusus Biznet)"
  echo -e "│7.) Exit"
  echo -e "╰───────────────────────────────────────────────╯"

  read -p "➣ Your Choice: " menu_choice

  case $menu_choice in
    1)
      add_outbound "$response"
      ;;
    2)
      delete_rules_by_tag "$response"
      ;;
    3)
      add_domain_to_existing_tag "$response"
      ;;
    4)
      remove_domain_from_existing_tag "$response"
      ;;
    5)
      edit_outbound "$response"
      ;;
    6)
      add_disable_quic "$response"
      ;;
    7)
      exit 1
      ;;
    *)
      echo "Pilihan tidak valid: $menu_choice"
      exit 1
      ;;
  esac
}

# Execute the main function
main

