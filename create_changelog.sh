#!/bin/bash

current=$( git describe --tags --always )
previous=$( git describe --tags --always --abbrev=0 )
previous=$( git describe --tags --abbrev=0 --match="*classic*" "${previous%?}1~" )

date=$( git log "$current" -1 --date=short --format="%ad" )
repo_url=$( git remote get-url origin )

cat << EOF > "CHANGELOG.md"
# PitBull4

## [${current}](${repo_url}/tree/${current}) (${date})

[Full Changelog](${repo_url}/compare/${previous}...${current})

EOF
git log "$previous..$current" --grep="^\[ci\]" --invert-grep --pretty=format:"- %s" | sed -e 's/\B_\B/\\_/g' >> "CHANGELOG.md"
echo >> "CHANGELOG.md"
