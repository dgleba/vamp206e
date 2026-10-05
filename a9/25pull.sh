tee /tmp/25pull.sh <<-'EOF'
#!/usr/bin/env bash
set -euo pipefail

# Purpose: pull vamp-setup repo from git..
# usage:  bash /ap/script/vamp206a/a9/25pull.sh

ending () {
    echo "Listing shc folder..."
    ls -la | grep shc || true
    echo "Reached end of script."
    exit 0
}

cd "$HOME"
echo "HOME is: $HOME"
echo "PWD is: $(pwd)"

REPO_PATH="jecanada-digitization-org/vamp206a.git"
TARGET_DIR="shc"

URL1="http://pmadata01.stackpole.ca:6179/${REPO_PATH}"
URL2="http://10.4.65.191:6179/${REPO_PATH}"
URL3="https://github.com/dgleba/vamp206a.git"

URLS=("$URL2" "$URL1" "$URL3")

echo "Checking available git sources..."

WORKING_URL=""

for u in "${URLS[@]}"; do
    echo "Testing: $u"
    if git ls-remote "$u" &>/dev/null; then
        WORKING_URL="$u"
        echo "✔ Working source found: $u"
        break
    else
        echo "✖ Not reachable: $u"
    fi
done

if [[ -z "$WORKING_URL" ]]; then
    echo "❌ ERROR: All clone sources failed. Cannot continue."
    exit 1
fi

echo "Using source: $WORKING_URL"

if [[ -d "$TARGET_DIR/.git" ]]; then
    echo "Directory exists — performing git pull..."
    cd "$TARGET_DIR"
    git pull --ff-only
else
    echo "Directory does not exist — cloning..."
    git clone "$WORKING_URL" "$TARGET_DIR"
fi

ending
EOF

bash /tmp/25pull.sh
