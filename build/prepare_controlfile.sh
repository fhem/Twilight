#!/usr/bin/env bash

test -e "$HOME/.profile" && source $HOME/.profile

controls_file="controls_echodevice.txt"
changed_file="CHANGED"

current_version=$(perl -0777 -ne 'print "$1" if /\"(\d+\.\d+\.\d+)\"\;/' FHEM/98_Ovulation_Calendar.pm)

find . -type f -iname '.DS_Store' -delete

rm ${controls_file}
find -type f \( -path './FHEM/*' -o -path './www/*' \) -print0 | while IFS= read -r -d '' f;
do
    echo "DEL ${f}" >> ${controls_file}
    out="UPD "$(stat -c %y  $f | cut -d. -f1 | awk '{printf "%s_%s",$1,$2}')" "$(stat -c %s $f)" ${f}"
    echo ${out//.\//} >> ${controls_file}
done

rm ${changed_file}
echo "Current version: ${current_version} from $(date +%d.%m.%Y)" > ${changed_file}
echo "" >> ${changed_file}
echo "And in the last weeks episode at $(basename `git rev-parse --show-toplevel`):" >> ${changed_file}
git log HEAD --pretty="  %h %ad %s" --date=format:"%d.%m.%Y %H:%M" FHEM/ www/ >> ${changed_file}

