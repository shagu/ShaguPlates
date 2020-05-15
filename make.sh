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

# use unitframes by default to not interfere with UI
sed -i 's/"use_unitfonts".*"0")/"use_unitfonts", "1")/g' api/config.lua
sed -i 's/"use_unitfonts".*"0")/"use_unitfonts", "1")/g' api/config.lua
sed -i 's/"border",.*"nameplates",.*"-1"/"border",      "nameplates",       "2"/g' api/config.lua

# only load required modules
echo '<Ui xmlns="http://www.blizzard.com/wow/ui/">
  <Include file="..\modules\cooldown.lua"/>
  <Include file="..\modules\settings.lua"/>
  <Include file="..\modules\nameplates.lua"/>
</Ui>' > init/modules.xml

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
