#!/bin/bash
# EmDash Commerce Store — Quick Setup
# Creates D1 database, R2 bucket, configures wrangler, and deploys.

set -e

echo ""
echo "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  EmDash Commerce Store Setup"
echo "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check wrangler is installed
if ! command -v wrangler &> /dev/null; then
    echo "❌ Wrangler not found. Install it first:"
    echo "   npm install -g wrangler"
    echo "   wrangler login"
    exit 1
fi

# Ask for store name
read -p "📦 What's your store name? (e.g. 'my-store'): " STORE_NAME
if [ -z "$STORE_NAME" ]; then
    echo "❌ Store name is required."
    exit 1
fi

# Slugify the store name
SLUG=$(echo "$STORE_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//' | sed 's/-$//')
DB_NAME="${SLUG}-db"
BUCKET_NAME="${SLUG}-media"

echo ""
echo "  Store: $STORE_NAME"
echo "  Worker: $SLUG"
echo "  Database: $DB_NAME"
echo "  Storage: $BUCKET_NAME"
echo ""

read -p "Continue? (y/n): " CONFIRM
if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
    echo "Cancelled."
    exit 0
fi

# Install dependencies
echo ""
echo "📥 Installing dependencies..."
npm install

# Create D1 database
echo ""
echo "🗄️  Creating D1 database: $DB_NAME"
D1_OUTPUT=$(wrangler d1 create "$DB_NAME" 2>&1)
echo "$D1_OUTPUT"

# Extract database ID
DB_ID=$(echo "$D1_OUTPUT" | grep -o '"database_id": "[^"]*"' | head -1 | cut -d'"' -f4)
if [ -z "$DB_ID" ]; then
    DB_ID=$(echo "$D1_OUTPUT" | grep -o 'database_id = "[^"]*"' | head -1 | cut -d'"' -f2)
fi
if [ -z "$DB_ID" ]; then
    echo ""
    echo "⚠️  Could not extract database ID automatically."
    read -p "Paste your D1 database ID: " DB_ID
fi
echo "  Database ID: $DB_ID"

# Create R2 bucket
echo ""
echo "📦 Creating R2 bucket: $BUCKET_NAME"
wrangler r2 bucket create "$BUCKET_NAME" 2>&1 || true

# Ask for domain (optional)
echo ""
read -p "🌐 Custom domain? (e.g. 'mystore.com', or press Enter to skip): " DOMAIN
SITE_URL="https://${SLUG}.workers.dev"
if [ -n "$DOMAIN" ]; then
    SITE_URL="https://${DOMAIN}"
fi

# Generate wrangler.jsonc
echo ""
echo "📝 Writing wrangler.jsonc..."
cat > wrangler.jsonc << WRANGLER
{
	"name": "${SLUG}",
	"compatibility_date": "2025-04-01",
	"compatibility_flags": ["nodejs_compat"],
	"d1_databases": [
		{
			"binding": "DB",
			"database_name": "${DB_NAME}",
			"database_id": "${DB_ID}"
		}
	],
	"r2_buckets": [
		{
			"binding": "MEDIA",
			"bucket_name": "${BUCKET_NAME}"
		}
	],
	"observability": {
		"enabled": false,
		"logs": {
			"enabled": true,
			"invocation_logs": true
		}
	},
	"vars": {
		"SITE_URL": "${SITE_URL}"
	}
}
WRANGLER

# Build
echo ""
echo "🔨 Building..."
npm run build

# Deploy
echo ""
echo "🚀 Deploying to Cloudflare Workers..."
wrangler deploy

# Custom domain
if [ -n "$DOMAIN" ]; then
    echo ""
    echo "🌐 Adding custom domain: $DOMAIN"
    wrangler domains add "$DOMAIN" 2>&1 || echo "   Add the domain manually in the Cloudflare dashboard."
fi

echo ""
echo "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✅ Store deployed!"
echo "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  🌐 Site: ${SITE_URL}"
echo "  🔧 Admin: ${SITE_URL}/_emdash/admin"
echo ""
echo "  Next steps:"
echo "  1. Visit the admin URL above"
echo "  2. Complete the setup wizard"
echo "  3. Go to Commerce > Settings"
echo "  4. Add your Stripe secret key"
echo "  5. Add products and start selling!"
echo ""
