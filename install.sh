echo '#!/bin/bash
echo "=== Starting dream-gpt installation ==="
echo "Downloading dream-gpt.sh..."
curl -O https://raw.githubusercontent.com/MARKETTV1/dreamOS/refs/heads/main/dream-gpt.sh
if [ -f "dream-gpt.sh" ]; then
    echo "✓ File downloaded successfully"
    echo "Granting execution permissions..."
    chmod +x dream-gpt.sh
    echo "Running dream-gpt.sh..."
    ./dream-gpt.sh
else
    echo "✗ Failed to download file"
    exit 1
fi
echo "=== Installation completed ==="' > install.sh && chmod +x install.sh && ./install.sh
