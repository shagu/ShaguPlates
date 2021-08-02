#!/bin/sh
# backup old readme
mv README.md .README.md
cp -rf ../pfUI/* .
mv .README.md README.md

# delete skins
rm -rf skins
rm init/skins.xml

# misc
rm -rf Bindings.xml

# delete other modules
mv modules/settings.lua .
mv modules/cooldown.lua .
mv modules/nameplates.lua .
rm modules/*
mv settings.lua modules
mv cooldown.lua modules
mv nameplates.lua modules

# replace all variables and frames
find . -iname "*.lua" -type f | xargs sed -i 's/pfUI/ShaguPlates/g'
find . -iname "*.lua" -type f | xargs sed -i 's/PFUI/SHAGUPLATES/g'
find . -iname "*.lua" -type f | xargs sed -i 's/pfui/shaguplates/g'
find . -iname "*.toc" -type f | xargs sed -i 's/|cff33ffccpf|cffffffffUI/|cff33ffccShagu|cffffffffPlates/g'
find . -iname "*.toc" -type f | xargs sed -i 's/pfUI/ShaguPlates/g'
find . -iname "*.toc" -type f | xargs sed -i '/init\\skins.xml/d'
find . -iname "*.toc" -type f | xargs sed -i 's/## Notes:.*/## Notes: Nameplate addon featuring castbars and class colors/g'
find . -iname "*.toc" -type f | xargs sed -i '/Notes-/d'

# use unitframes by default to not interfere with UI
sed -i 's/"use_unitfonts".*"0")/"use_unitfonts", "1")/g' api/config.lua
sed -i 's/"use_unitfonts".*"0")/"use_unitfonts", "1")/g' api/config.lua
sed -i 's/"border",.*"nameplates",.*"-1"/"border",      "nameplates",       "2"/g' api/config.lua
sed -i 's/\("appearance", "cd",          "blizzard",         "\)1"/\10"/g' api/config.lua

# only load required modules
echo '<Ui xmlns="http://www.blizzard.com/wow/ui/">
  <Include file="..\modules\cooldown.lua"/>
  <Include file="..\modules\settings.lua"/>
  <Include file="..\modules\nameplates.lua"/>
</Ui>' > init/modules.xml

# remove unitframe api
rm api/unitframes.lua
sed -i '/.*unitframes.*/d' init/api.xml

# remove libtotem
rm libs/libtotem.lua
rm libs/libpredict.lua
sed -i '/.*libtotem.*/d' init/libs.xml

# remove obsolete graphics
rm img/classicons.tga
rm img/Curse.tga
rm img/Disease.tga
rm img/disenchant.tga
rm img/empty.tga
rm img/full.tga
rm img/key.tga
rm img/Magic.tga
rm img/mail.tga
rm img/minimap.tga
rm img/happy*.tga
rm img/neutral*.tga
rm img/sad*.tga
rm img/picklock.tga
rm img/Poison.tga
rm img/proxy.tga
rm img/pvp.tga
rm img/ress.tga
rm img/sort.tga
rm img/circleparty.tga
rm img/circleraid.tga

# remove obsolete fonts
rm fonts/RobotoMono.ttf

# rename core files
mv pfUI.toc ShaguPlates.toc
mv pfUI-tbc.toc ShaguPlates-tbc.toc
mv pfUI.lua ShaguPlates.lua

# disable changing the default fonts
sed -i '/.*SetFont.*/d' ShaguPlates.lua
sed -i '/.*STANDARD_TEXT_FONT.*/d' ShaguPlates.lua
sed -i '/.*DAMAGE_TEXT_FONT.*/d' ShaguPlates.lua
sed -i '/.*NAMEPLATE_FONT.*/d' ShaguPlates.lua
sed -i '/.*UNIT_NAME_FONT.*/d' ShaguPlates.lua
sed -i '/.*UIDROPDOWNMENU_DEFAULT_TEXT_HEIGHT.*/d' ShaguPlates.lua

# remove default error handler
sed -i '/seterrorhandler/d' ShaguPlates.lua
sed -i 's/message = function(msg)/local message = function(msg)/g' ShaguPlates.lua
sed -i '/print = message/d' ShaguPlates.lua

# remove obsolete translations
for locale in "deDE" "enUS" "frFR" "koKR" "ruRU" "zhCN" "zhTW" "esES"; do
  file=env/translations_$locale.lua
  file_new=env/translations_$locale.lua_new

  echo "ShaguPlates_translation[\"$locale\"] = {" > $file_new

  cat *.lua modules/* | sed "s/\(T\[\"\)/\n\1/" | grep -oP "T\[\".*?\"]" | sed 's/T\["\(.*\)"\]/\1/' | sort | uniq | while read -r entry; do
    old=$(grep -F "[\"$entry\"]" $file | head -n 1 2> /dev/null)
    if [ -z "$old" ] ; then
      old="  [\"$entry\"] = nil,"
    fi
    echo "$old"
  done >> $file_new
  echo "}" >> $file_new

  mv $file_new $file
done
