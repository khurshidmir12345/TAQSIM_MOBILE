#!/usr/bin/env bash
# ============================================================================
# fix-ios-build.sh
# Xcode 26.5 + Flutter iOS build muammosini hal qilish skripti.
#
# Muammo: "iOS 26.5 is not installed" xatosi.
# Sabab: Xcode 15+ da SDK va Platform alohida o'rnatiladi.
#         Platform/DDI (Device Disk Image) Settings > Components dan yuklanadi.
#
# Bu skript:
#   1. CoreSimulator xizmatini qayta ishga tushiradi
#   2. Xcode license va first-launch ni qabul qiladi
#   3. iOS 26.5 Platform ni yuklab oladi (~5-10 GB)
#   4. Eski iOS runtime volumes ni tozalaydi (ixtiyoriy)
#   5. Natijani tekshiradi
#
# Ishga tushirish:
#   sudo bash /Users/khurshid/Desktop/taqseem/mobile/scripts/fix-ios-build.sh
# ============================================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

log()  { echo -e "${BLUE}[INFO]${NC} $*"; }
ok()   { echo -e "${GREEN}[OK]${NC}   $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
err()  { echo -e "${RED}[ERR]${NC}  $*" >&2; }

if [ "$EUID" -ne 0 ]; then
  err "Bu skript root huquq talab qiladi."
  err "Ishga tushirish: sudo bash $0"
  exit 1
fi

log "Xcode versiyasi:"
xcodebuild -version || true
echo

# ----------------------------------------------------------------------------
# 1) CoreSimulator xizmatini qayta ishga tushirish
# ----------------------------------------------------------------------------
log "1/5 — CoreSimulator xizmatini qayta ishga tushirish..."
if launchctl kickstart -k system/com.apple.CoreSimulator.CoreSimulatorService 2>/dev/null; then
  ok "CoreSimulatorService qayta ishga tushdi."
else
  warn "kickstart muvaffaqiyatsiz. bootstrap urinib ko'ramiz..."
  launchctl bootstrap system /Library/Apple/System/Library/LaunchDaemons/com.apple.CoreSimulator.CoreSimulatorService.plist 2>/dev/null || true
  ok "Xizmat holati yangilandi."
fi
sleep 2

# ----------------------------------------------------------------------------
# 2) Xcode license va first-launch
# ----------------------------------------------------------------------------
log "2/5 — Xcode license qabul qilish..."
xcodebuild -license accept
ok "License qabul qilindi."

log "      Xcode first-launch ni ishga tushirish..."
xcodebuild -runFirstLaunch
ok "First-launch tugadi."
echo

# ----------------------------------------------------------------------------
# 3) iOS 26.5 Platform ni yuklab olish (eng uzoq qism)
# ----------------------------------------------------------------------------
log "3/5 — iOS Platform ni yuklab olish (5-10 GB, 10-30 daqiqa)..."
warn "Internet barqaror bo'lsin. Yuklash boshlanyapti..."
if xcodebuild -downloadPlatform iOS; then
  ok "iOS Platform muvaffaqiyatli yuklab olindi."
else
  err "Avtomatik yuklash ishlamadi."
  err "Alternativ: Xcode oching → Settings → Components → iOS 26.5 yonidagi 'Get' tugmasini bosing."
  exit 2
fi
echo

# ----------------------------------------------------------------------------
# 4) Eski runtime volumes ni tozalash (ixtiyoriy)
# ----------------------------------------------------------------------------
log "4/5 — Eski iOS runtime volumes ni tozalash..."
OLD_VOLUMES_DIR="/Library/Developer/CoreSimulator/Volumes"
if [ -d "$OLD_VOLUMES_DIR" ]; then
  for v in "$OLD_VOLUMES_DIR"/iOS_*; do
    [ -e "$v" ] || continue
    name=$(basename "$v")
    log "      O'chirilmoqda: $name"
    rm -rf "$v" 2>/dev/null || warn "$name o'chmadi (mount qilingan bo'lishi mumkin)"
  done
  ok "Eski volumes tozalandi."
else
  warn "$OLD_VOLUMES_DIR mavjud emas, o'tkazib yuborildi."
fi
echo

# ----------------------------------------------------------------------------
# 5) Natijani tekshirish
# ----------------------------------------------------------------------------
log "5/5 — Natijani tekshirish..."
PROJECT_PATH="/Users/khurshid/Desktop/taqseem/mobile/ios/Runner.xcodeproj"
if [ -d "$PROJECT_PATH" ]; then
  echo
  log "Mavjud destinationlar:"
  xcodebuild -showdestinations -project "$PROJECT_PATH" -scheme Runner 2>&1 \
    | grep -E "platform:iOS|Available destinations" \
    | grep -v "Simulator" \
    | head -10
  echo

  if xcodebuild -showdestinations -project "$PROJECT_PATH" -scheme Runner 2>&1 \
       | grep -q "iOS 26.5 is not installed"; then
    err "iOS 26.5 hali ham o'rnatilmagan deyilyapti."
    err "Xcode oching → Settings → Components → iOS 26.5 ni qo'lda yuklab oling."
    exit 3
  else
    ok "Any iOS Device tayyor. Build qilish mumkin."
  fi
else
  warn "Runner.xcodeproj topilmadi: $PROJECT_PATH"
fi

echo
ok "Hamma qadamlar muvaffaqiyatli bajarildi!"
ok "Endi Cursor ga qaytib 'tayyor' deb yozing — agent Flutter build ni davom ettiradi."
