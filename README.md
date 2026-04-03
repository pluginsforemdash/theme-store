# EmDash Store Theme — shadcn/ui

A complete e-commerce storefront theme for [EmDash CMS](https://github.com/emdash-cms/emdash), powered by the [Commerce plugin](https://github.com/pluginsforemdash/commerce). Dark theme with shadcn/ui styling.

## Preview

Built with Astro, Tailwind CSS 4, and React. Fully server-rendered with client-side cart and checkout interactions.

## Pages

| Page | Route | Description |
|------|-------|-------------|
| Homepage | `/` | Hero section, featured products grid, recent blog posts, CTA |
| Shop | `/shop` | Product grid with category filter tabs, loading skeletons, sale badges |
| Product Detail | `/product/[slug]` | Image, price, compare-at-price, variants, quantity selector, add to cart, related products |
| Cart | `/cart` | Item list with quantity +/-, remove, discount code input, subtotal/discount/total breakdown |
| Checkout | `/checkout` | Contact info + shipping address form, order summary, redirects to Stripe |
| Order Success | `/order/success` | Confirmation with next steps |
| Blog | `/posts` | Post listing with featured images |
| Blog Post | `/posts/[slug]` | Full post with Portable Text rendering |
| CMS Pages | `/[slug]` | Dynamic pages from EmDash |
| 404 | `/404` | Not found page |

## Components

| Component | Purpose |
|-----------|---------|
| `Header.astro` | Sticky nav with shop/blog links, mobile hamburger menu, cart icon with live count badge |
| `Footer.astro` | 4-column footer with brand, shop, company, and legal links |
| `ProductCard.astro` | Reference product card component |
| `CartDrawer.astro` | Slide-out cart panel with overlay, item list, subtotal, quick links |

## Quick Start

### 1. Clone the theme

```bash
git clone https://github.com/pluginsforemdash/theme-store.git my-store
cd my-store
npm install
```

### 2. Start the dev server

```bash
npm run dev
```

### 3. Set up EmDash

Visit `http://localhost:4321/_emdash/admin` and complete the setup wizard.

### 4. Configure Commerce

Go to **Commerce > Settings** in the admin panel:

- Add your **Stripe Secret Key** (`sk_test_...` for testing)
- Set **Site URL** to `http://localhost:4321`
- Set your **Store Name**

### 5. Add products

Go to **Commerce > Products** and create your first product:

- Enter name, slug, price (in cents), and set status to **Active**
- Visit `/shop` to see it in the storefront

### 6. Test checkout

1. Add a product to cart from the shop page
2. Go to `/cart` and click checkout
3. Fill in the form and proceed to payment
4. Use Stripe test card `4242 4242 4242 4242` with any future expiry and CVC

## Deploy to Cloudflare

### Switch adapter

Replace `@astrojs/node` with `@astrojs/cloudflare`:

```bash
npm uninstall @astrojs/node better-sqlite3
npm install @astrojs/cloudflare @emdash-cms/cloudflare
```

Update `astro.config.mjs`:

```js
import cloudflare from "@astrojs/cloudflare";
import { d1, r2 } from "@emdash-cms/cloudflare";

export default defineConfig({
  output: "server",
  adapter: cloudflare(),
  integrations: [
    react(),
    emdash({
      database: d1({ binding: "DB", session: "auto" }),
      storage: r2({ binding: "MEDIA" }),
      plugins: [commercePlugin({ currency: "usd" })],
    }),
  ],
  // ...
});
```

### Create Cloudflare resources

```bash
wrangler d1 create my-store-db
wrangler r2 bucket create my-store-media
```

### Create `wrangler.jsonc`

```jsonc
{
  "name": "my-store",
  "compatibility_date": "2025-04-01",
  "compatibility_flags": ["nodejs_compat"],
  "d1_databases": [
    {
      "binding": "DB",
      "database_name": "my-store-db",
      "database_id": "<YOUR_D1_DATABASE_ID>"
    }
  ],
  "r2_buckets": [
    {
      "binding": "MEDIA",
      "bucket_name": "my-store-media"
    }
  ]
}
```

### Deploy

```bash
npm run build
wrangler deploy
```

## Architecture

### Commerce API Integration

All storefront pages fetch data from the Commerce plugin's API. Since Cloudflare Workers can't loopback to themselves, **all product/cart/checkout fetching happens client-side** via JavaScript.

API endpoints used (all POST with JSON body):

| Endpoint | Purpose |
|----------|---------|
| `storefront/products` | List products with optional category filter |
| `storefront/product` | Get single product by slug |
| `storefront/categories` | List all categories |
| `storefront/cart` | Get cart contents |
| `storefront/cart/add` | Add item to cart |
| `storefront/cart/update` | Update item quantity (0 = remove) |
| `storefront/cart/discount` | Apply discount code |
| `storefront/checkout` | Create Stripe Checkout Session |
| `storefront/reviews` | Get approved reviews for a product |
| `storefront/stock` | Get stock status for a product |
| `storefront/related` | Get related products |
| `storefront/shipping-estimate` | Get shipping estimate by country |

All responses are wrapped in `{ data: { ... } }` by EmDash.

### Cart Session

Cart state is managed via a session ID stored in `localStorage` (`store_cart_session`). A `cart-updated` custom event is dispatched after cart mutations to keep the header badge count in sync.

### Blog & CMS Pages

Blog posts and CMS pages are fetched **server-side** using EmDash's content API (`getEmDashCollection`, `getEmDashEntry`) and rendered with `PortableText` from `emdash/ui`. These work fine server-side — only the commerce API needs client-side fetching.

## Design System

Based on shadcn/ui conventions with a dark zinc palette:

| Token | Value | Usage |
|-------|-------|-------|
| `--color-background` | `#09090b` | Page background |
| `--color-foreground` | `#fafafa` | Primary text |
| `--color-card` | `#0a0a0f` | Card backgrounds |
| `--color-primary` | `#fafafa` | Buttons, accents |
| `--color-secondary` | `#27272a` | Secondary backgrounds |
| `--color-muted` | `#27272a` | Muted backgrounds |
| `--color-muted-foreground` | `#a1a1aa` | Secondary text |
| `--color-border` | `#27272a` | Borders, dividers |
| `--color-destructive` | `#7f1d1d` | Error states |

## Customization

### Change colors

Edit `src/styles/global.css` and update the `@theme` tokens. The entire theme updates automatically.

### Add pages

Create new `.astro` files in `src/pages/`. All pages must have `export const prerender = false` for EmDash compatibility.

### Modify layout

Edit `src/layouts/Base.astro` for the overall page structure, `src/components/Header.astro` for navigation, and `src/components/Footer.astro` for the footer.

### Content types

Edit `seed/seed.json` to add new collections (e.g. testimonials, FAQs). Run `npm run dev` to apply the seed. Products are managed by the Commerce plugin, not the seed file.

## Tech Stack

- [Astro 6](https://astro.build) — Framework
- [EmDash CMS](https://github.com/emdash-cms/emdash) — Content management
- [Commerce Plugin](https://github.com/pluginsforemdash/commerce) — E-commerce engine
- [Tailwind CSS 4](https://tailwindcss.com) — Styling
- [React](https://react.dev) — Interactive components
- [Stripe](https://stripe.com) — Payment processing

## Requirements

- Node.js 22+
- EmDash CMS v0.1.0+
- emdash-plugin-commerce v0.3.0+
- Stripe account (free to create)

## License

MIT
