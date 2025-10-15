#!/bin/bash

# Chain Status Checker
# Usage: ./check_chain_status.sh <chain_id>

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if chain ID is provided
if [ -z "$1" ]; then
    echo "Error: Chain ID is required"
    echo "Usage: $0 <chain_id>"
    echo "Example: $0 1"
    exit 1
fi

CHAIN_ID=$1
API_URL="https://chainlist.org/rpcs.json"

echo "Fetching chain data for Chain ID: $CHAIN_ID..."
echo "---"

# Fetch the JSON data and parse for the specific chain
CHAIN_DATA=$(curl -s "$API_URL" | jq ".[] | select(.chainId == $CHAIN_ID)")

# Check if chain was found
if [ -z "$CHAIN_DATA" ]; then
    echo "Error: Chain ID $CHAIN_ID not found in Chainlist"
    exit 1
fi

# Extract chain information
CHAIN_NAME=$(echo "$CHAIN_DATA" | jq -r '.name')
CHAIN_SHORT_NAME=$(echo "$CHAIN_DATA" | jq -r '.shortName')
STATUS=$(echo "$CHAIN_DATA" | jq -r '.status // "active"')
NETWORK_ID=$(echo "$CHAIN_DATA" | jq -r '.networkId')
NATIVE_CURRENCY=$(echo "$CHAIN_DATA" | jq -r '.nativeCurrency.symbol')
TVL=$(echo "$CHAIN_DATA" | jq -r '.tvl // "N/A"')
RPC_COUNT=$(echo "$CHAIN_DATA" | jq '.rpc | length')

# Display results
echo "Chain Name: $CHAIN_NAME"
echo "Short Name: $CHAIN_SHORT_NAME"
echo "Chain ID: $CHAIN_ID"
echo "Network ID: $NETWORK_ID"
echo "Status: $STATUS"
echo "Native Currency: $NATIVE_CURRENCY"
echo "TVL: $TVL"
echo "RPC Endpoints Available: $RPC_COUNT"
echo "---"

# Status-based output
case "$STATUS" in
    "active")
        echo "✓ This chain is ACTIVE and operational"
        ;;
    "deprecated")
        echo "✗ This chain is DEPRECATED and no longer maintained"
        ;;
    "incubating")
        echo "⚠ This chain is INCUBATING (early development stage)"
        ;;
    *)
        echo "? Unknown status: $STATUS"
        ;;
esac

# Test RPC endpoints
if [ "$RPC_COUNT" -gt 0 ]; then
    echo ""
    echo "Testing RPC endpoints (will stop at first successful response)..."
    echo "---"
    
    RPC_FOUND=false
    
    # Loop through all RPC endpoints
    for i in $(seq 0 $((RPC_COUNT - 1))); do
        # Extract RPC URL (handle both object format {url: "..."} and string format)
        RPC_URL=$(echo "$CHAIN_DATA" | jq -r ".rpc[$i].url // .rpc[$i]")
        
        # Skip if URL is null, empty, or contains placeholders
        if [ "$RPC_URL" = "null" ] || [ -z "$RPC_URL" ] || [[ "$RPC_URL" == *'${'* ]] || [[ "$RPC_URL" == *'wss://'* ]]; then
            continue
        fi
        
        echo "[$((i+1))/$RPC_COUNT] Testing: $RPC_URL"
        
        # Test RPC with eth_blockNumber call
        RESPONSE=$(curl -s -X POST "$RPC_URL" \
            -H "Content-Type: application/json" \
            -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
            --max-time 5 2>/dev/null)
        
        # Check if we got a valid response
        if echo "$RESPONSE" | jq -e '.result' > /dev/null 2>&1; then
            BLOCK_HEX=$(echo "$RESPONSE" | jq -r '.result')
            BLOCK_NUM=$((16#${BLOCK_HEX:2}))
            echo "✓ SUCCESS! RPC is responsive"
            echo "  Latest block number: $BLOCK_NUM"
            
            # Check for suspicious block numbers
            if [ "$BLOCK_NUM" -eq 0 ]; then
                echo -e "  ${RED}⚠ Warning: Chain reports block #0 - this chain may not be producing blocks yet${NC}"
            elif [ "$BLOCK_NUM" -lt 100 ]; then
                echo -e "  ${YELLOW}ℹ Note: Very low block number ($BLOCK_NUM) - this is likely a very new chain${NC}"
            fi
            
            # Extract tracking info if available
            TRACKING=$(echo "$CHAIN_DATA" | jq -r ".rpc[$i].tracking // \"unknown\"")
            if [ "$TRACKING" != "unknown" ]; then
                echo "  Tracking: $TRACKING"
            fi
            
            # Check transaction count in recent blocks
            echo ""
            echo "  Checking for transaction activity..."
            BLOCK_WITH_TXS=false
            BLOCKS_CHECKED=0
            BLOCKS_NOT_FOUND=0
            
            for j in $(seq 0 41); do
                CHECK_BLOCK=$((BLOCK_NUM - j))
                
                # Don't check negative block numbers
                if [ "$CHECK_BLOCK" -lt 0 ]; then
                    break
                fi
                
                CHECK_BLOCK_HEX=$(printf "0x%x" $CHECK_BLOCK)
                
                # Get block by number
                BLOCK_RESPONSE=$(curl -s -X POST "$RPC_URL" \
                    -H "Content-Type: application/json" \
                    -d "{\"jsonrpc\":\"2.0\",\"method\":\"eth_getBlockByNumber\",\"params\":[\"$CHECK_BLOCK_HEX\",false],\"id\":1}" \
                    --max-time 5 2>/dev/null)
                
                BLOCKS_CHECKED=$((BLOCKS_CHECKED + 1))
                
                # Check if block exists
                if echo "$BLOCK_RESPONSE" | jq -e '.result' > /dev/null 2>&1; then
                    BLOCK_RESULT=$(echo "$BLOCK_RESPONSE" | jq -r '.result')
                    
                    # Check if result is null (block doesn't exist)
                    if [ "$BLOCK_RESULT" = "null" ]; then
                        BLOCKS_NOT_FOUND=$((BLOCKS_NOT_FOUND + 1))
                        if [ $j -eq 0 ]; then
                            echo -e "  ${RED}✗ Block #$CHECK_BLOCK does not exist${NC}"
                            echo -e "    ${RED}Chain may not have produced this block yet or RPC is returning incorrect block height${NC}"
                        fi
                        continue
                    fi
                    
                    # Block exists, check for transactions
                    TX_COUNT=$(echo "$BLOCK_RESPONSE" | jq -r '.result.transactions | length')
                    
                    # Handle null or empty transaction count
                    if [ -z "$TX_COUNT" ] || [ "$TX_COUNT" = "null" ]; then
                        if [ $j -eq 0 ]; then
                            echo -e "  ${YELLOW}⚠ Block #$CHECK_BLOCK exists but has no 'transactions' field${NC}"
                            echo -e "    ${YELLOW}This may be a non-standard block format${NC}"
                        fi
                        TX_COUNT=0
                    fi
                    
                    if [ "$TX_COUNT" -gt 0 ] 2>/dev/null; then
                        echo -e "  ${GREEN}✓ Block #$CHECK_BLOCK has $TX_COUNT transaction(s)${NC}"
                        if [ $j -gt 0 ]; then
                            echo "    (found after checking $BLOCKS_CHECKED block(s))"
                        fi
                        BLOCK_WITH_TXS=true
                        break
                    elif [ $j -eq 0 ]; then
                        echo -e "  ${YELLOW}ℹ Block #$CHECK_BLOCK exists but has 0 transactions, checking previous blocks...${NC}"
                    fi
                else
                    # Check if it's an error response
                    ERROR_MSG=$(echo "$BLOCK_RESPONSE" | jq -r '.error.message // empty' 2>/dev/null)
                    if [ ! -z "$ERROR_MSG" ]; then
                        echo -e "  ${RED}✗ RPC Error at block #$CHECK_BLOCK: $ERROR_MSG${NC}"
                    else
                        echo -e "  ${RED}✗ Failed to fetch block #$CHECK_BLOCK (invalid RPC response)${NC}"
                    fi
                    break
                fi
            done
            
            # Summary
            echo ""
            if [ "$BLOCK_WITH_TXS" = true ]; then
                echo -e "  ${GREEN}✓ Chain is active with transaction activity${NC}"
            else
                if [ "$BLOCKS_NOT_FOUND" -gt 0 ]; then
                    echo -e "  ${RED}✗ ISSUE: $BLOCKS_NOT_FOUND block(s) could not be found${NC}"
                    echo -e "    ${RED}Possible causes:${NC}"
                    echo -e "    ${RED}• Chain is not producing blocks (stuck or not started)${NC}"
                    echo -e "    ${RED}• RPC is returning incorrect block height${NC}"
                    echo -e "    ${RED}• Chain has a non-standard block structure${NC}"
                else
                    echo -e "  ${RED}⚠ Checked $BLOCKS_CHECKED block(s) - no transactions found${NC}"
                    echo -e "    ${RED}Chain appears to be producing blocks but has very low/no activity${NC}"
                fi
            fi
            
            RPC_FOUND=true
            break
        else
            echo "  ✗ Failed or timed out"
        fi
    done
    
    if [ "$RPC_FOUND" = false ]; then
        echo ""
        echo -e "${RED}⚠ Warning: No working RPC endpoints found${NC}"
        echo -e "${RED}  This may indicate the chain is not operational or all public RPCs are down${NC}"
    fi
fi

exit 0