#!/usr/bin/env bash
# Test script to verify installation script download and execution
# This tests without creating a container

echo "Testing Scaffold installation script download..."
echo ""

# Test 1: Check if script exists
INSTALL_URL="https://raw.githubusercontent.com/ball0803/script/master/install/scaffold-install.sh"
echo "✓ Testing URL: $INSTALL_URL"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$INSTALL_URL")
if [[ $HTTP_CODE -eq 200 ]]; then
  echo "✅ URL is accessible (HTTP 200)"
else
  echo "❌ URL returned HTTP $HTTP_CODE"
  exit 1
fi

# Test 2: Download and verify script content
echo ""
echo "✓ Downloading script..."
if curl -fsSL "$INSTALL_URL" > /tmp/scaffold-install-test.sh; then
  echo "✅ Script downloaded successfully"
  
  # Test 3: Verify it's a valid bash script
  echo ""
  echo "✓ Checking script syntax..."
  if bash -n /tmp/scaffold-install-test.sh 2>/dev/null; then
    echo "✅ Script syntax is valid"
    
    # Test 4: Check for shebang
    echo ""
    echo "✓ Checking shebang..."
    FIRST_LINE=$(head -n 1 /tmp/scaffold-install-test.sh)
    if [[ "$FIRST_LINE" == "#!/usr/bin/env bash" ]]; then
      echo "✅ Valid bash shebang found"
    else
      echo "⚠️  Unexpected shebang: $FIRST_LINE"
    fi
    
    # Test 5: Check for key functions
    echo ""
    echo "✓ Checking for key functions..."
    if grep -q "function.*install_scaffold" /tmp/scaffold-install-test.sh; then
      echo "✅ install_scaffold function found"
    else
      echo "⚠️  install_scaffold function not found"
    fi
    
    echo ""
    echo "========================================"
    echo "✅ ALL TESTS PASSED"
    echo "========================================"
    echo ""
    echo "The installation script is ready to use."
    echo "You can now run the full container creation."
    
    rm -f /tmp/scaffold-install-test.sh
    exit 0
  else
    echo "❌ Script has syntax errors"
    rm -f /tmp/scaffold-install-test.sh
    exit 1
  fi
else
  echo "❌ Failed to download script"
  exit 1
fi
