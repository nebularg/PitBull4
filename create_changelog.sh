#!/bin/bash

current=$( git describe --tags --always )
previous=$( git describe --tags --always --abbrev=0 )
if [ "$current" = "$previous" ]; then # on tag
	previous="${current%?}1"
	if [ "$current" = "$previous" ]; then # first tag in the series
		previous=$( git describe --tags --abbrev=0 --match="*classic*" HEAD~ )
	fi
fi

date=$( git log "$current" -1 --date=short --format="%ad" )
repo_url=$( git remote get-url origin )

cat << EOF > "CHANGELOG.md"
# PitBull4

## [${current}](${repo_url}/tree/${current}) (${date})

[Full Changelog](${repo_url}/compare/${previous}...${current})

EOF
git log "$previous..$current" --grep="^\[ci\]" --invert-grep --pretty=format:"###%B" \
	| sed -e 's/^/    /g' -e 's/^ *$//g' -e 's/^    ###/- /g' -e 's/$/  /' \
	      -e 's/\([a-zA-Z0-9]\)_\([a-zA-Z0-9]\)/\1\\_\2/g' \
	      -e 's/\[ci skip\]//g' -e 's/\[skip ci\]//g' \
	      -e '/^\s*This reverts commit [0-9a-f]\{40\}\.\s*$/d' \
	      -e '/^\s*$/d' \
	>> "CHANGELOG.md"
