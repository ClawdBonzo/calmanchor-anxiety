#!/bin/zsh
# Capture raw App Store frames + stickers for CalmAnchor, then compose.
#
#   scripts/store_shots/capture.sh <simUDID> [en de fr ja]
#
# Needs an iPhone 17 Pro Max simulator (native 1320×2868 = App Store 6.9").
# Uses DEBUG-only launch flags (-seedDemoData -demoPremium -CAScreenshotMode
# -CAShowcase …), so a Debug build is installed. Every simctl call has a
# watchdog because simctl can hang when the machine is loaded.
set -u
U=$1; shift
LOCALES=(${@:-en de fr ja})
ROOT=${0:A:h:h:h}
WORK=${WORK:-/tmp/ca_shots}
BUNDLE=com.clawdbonzo.CalmAnchor
mkdir -p $WORK
t() { local s=$1; shift; perl -e "alarm $s; exec @ARGV" "$@"; }

APP=$(ls -td ~/Library/Developer/Xcode/DerivedData/CalmAnchor-*/Build/Products/Debug-iphonesimulator/CalmAnchor.app | head -1)
t 180 xcrun simctl install $U "$APP" || { echo "install failed"; exit 1; }
t 60 xcrun simctl status_bar $U override --time 9:41 --batteryState charged --batteryLevel 100 \
  --cellularMode active --wifiBars 3 --cellularBars 4 --dataNetwork 5g

# Baseline home screen, so a launch that didn't come up is detected and retried.
t 30 xcrun simctl terminate $U $BUNDLE >/dev/null 2>&1
sleep 3
t 60 xcrun simctl io $U screenshot $WORK/home.png >/dev/null 2>&1
HOME_MD5=$(md5 -q $WORK/home.png)

typeset -A SHOTS
SHOTS=(
  01 "-demoPanic"
  02 "-demoPanic -CASOSPhase breathing"
  03 "-CAShowcase badge"
  04 "-CAShowcase achievements"
  05 "-demoTab 3"
  06 ""
  07 "-CAShowcase recap -CARecapPage 3"
  08 "-demoTab 1"
)

for loc in $LOCALES; do
  RAW=$WORK/raw/$loc; mkdir -p $RAW
  case $loc in ja) AL="(ja)"; LC=ja_JP;; de) AL="(de)"; LC=de_DE;; fr) AL="(fr)"; LC=fr_FR;; *) AL="(en)"; LC=en_US;; esac
  base=(-seedDemoData -demoPremium -CAScreenshotMode -AppleLanguages "$AL" -AppleLocale $LC)
  for n in ${(ok)SHOTS}; do
    extra=(${(z)SHOTS[$n]})
    for attempt in 1 2 3; do
      t 30 xcrun simctl terminate $U $BUNDLE >/dev/null 2>&1
      t 150 xcrun simctl launch $U $BUNDLE $base $extra >/dev/null 2>&1
      sleep 14
      t 60 xcrun simctl io $U screenshot $RAW/$n.png >/dev/null 2>&1
      if [[ -f $RAW/$n.png && $(md5 -q $RAW/$n.png) != $HOME_MD5 ]]; then echo "$loc $n ok"; break; fi
      echo "$loc $n retry $attempt"; rm -f $RAW/$n.png
    done
  done

  # Stickers, rendered by the app itself in this language.
  t 30 xcrun simctl terminate $U $BUNDLE >/dev/null 2>&1
  t 150 xcrun simctl launch $U $BUNDLE $base -CAShowcase export >/dev/null 2>&1
  DATA=$(t 30 xcrun simctl get_app_container $U $BUNDLE data)
  for i in {1..60}; do [[ -f $DATA/Documents/StoreAssets/done.txt ]] && break; sleep 1; done
  rm -rf $WORK/assets/$loc; mkdir -p $WORK/assets/$loc
  cp $DATA/Documents/StoreAssets/*.png $WORK/assets/$loc/ 2>/dev/null
  echo "$loc stickers: $(ls $WORK/assets/$loc | wc -l | tr -d ' ')"

  # Compose.
  $WORK/compose --raw $RAW --assets $WORK/assets/$loc --locale $loc \
    --out $ROOT/screenshots/v13/$loc --icon $ROOT/CalmAnchor/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png \
    --headlines $ROOT/scripts/store_shots/headlines.json
done
echo ALLDONE
