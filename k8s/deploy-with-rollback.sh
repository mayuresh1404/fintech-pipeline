#!/bin/bash
# ─────────────────────────────────────────────────
# Zero Downtime Deploy with Auto Rollback
# Usage: ./deploy-with-rollback.sh blue|green
# ─────────────────────────────────────────────────

TARGET=$1   # "green" or "blue"
CURRENT=$2  # "blue" or "green" (for rollback)

if [ -z "$TARGET" ] || [ -z "$CURRENT" ]; then
  echo "Usage: ./deploy-with-rollback.sh <target-slot> <current-slot>"
  echo "Example: ./deploy-with-rollback.sh green blue"
  exit 1
fi

echo "🚀 Switching traffic from $CURRENT → $TARGET..."
kubectl patch service trade-api-service \
  -p "{\"spec\":{\"selector\":{\"slot\":\"$TARGET\"}}}"

echo "⏳ Monitoring for 60 seconds..."
ERRORS=0
CHECKS=0

for i in $(seq 1 12); do
  sleep 5
  CHECKS=$((CHECKS + 1))

  # Check if pods are healthy
  READY=$(kubectl get deployment trade-api-$TARGET \
    -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
  DESIRED=$(kubectl get deployment trade-api-$TARGET \
    -o jsonpath='{.spec.replicas}' 2>/dev/null)

  echo "Check $CHECKS/12 → Ready pods: $READY/$DESIRED"

  if [ "$READY" != "$DESIRED" ]; then
    ERRORS=$((ERRORS + 1))
    echo "⚠️  Warning: Not all pods ready ($READY/$DESIRED)"
  fi

  # If more than 3 failed checks → rollback
  if [ "$ERRORS" -ge 3 ]; then
    echo ""
    echo "❌ ERROR THRESHOLD REACHED! Rolling back to $CURRENT..."
    kubectl patch service trade-api-service \
      -p "{\"spec\":{\"selector\":{\"slot\":\"$CURRENT\"}}}"
    echo "✅ Rolled back to $CURRENT successfully!"
    exit 1
  fi
done

echo ""
echo "✅ Deployment successful! Traffic is now on $TARGET ($(kubectl get service trade-api-service -o jsonpath='{.spec.selector.slot}'))"