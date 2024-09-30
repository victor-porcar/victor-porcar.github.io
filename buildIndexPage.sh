
#!/bin/bash

./site/scripts/bookmarks/updateBookmarks.sh

cp ./header.md index.md
cat ./site/bookmarks/generated_MD_IT.md >> index.md
