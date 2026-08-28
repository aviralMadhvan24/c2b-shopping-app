# Niyati Mart Admin

The store console for [Niyati Mart](../README.md). A separate Flutter **web**
app that reads and writes the same Firebase project (`c2b-shopping-app`) as the
customer app, so anything changed here shows up in the shopper's app
immediately.

It is a separate app on purpose: no admin screen, query or credential ever
ships inside the APK customers install.

```
fashion_store/          the customer app
├── firestore.rules     shared — includes the admin role
└── admin_app/          ← you are here
    └── lib/config/cloudinary_config.dart   where photo uploads go
```

## What it does

| Screen        | What the owner can do |
| ------------- | --------------------- |
| **Dashboard** | Revenue today / this month / all-time, open orders, average order value, live product count and stock value. A 7-day sales bar chart, revenue split by section, best sellers, latest orders, and a low/out-of-stock alert. |
| **Orders**    | Every order in the store, filtered by status or searched by order number, customer, phone or product. One-tap advance down the fulfilment ladder (placed → confirmed → packed → out for delivery → delivered), or open an order for its full timeline, items, customer details, delivery-person assignment, and cancellation with a reason the customer sees. |
| **Products**  | Add, edit, duplicate, publish/hide and delete products. Upload photos straight from the device, set the main one, price + MRP with a live discount preview, stock, SKU, brand, star rating, and any number of variants (sizes, RAM tiers). Stock is adjustable inline from the list. |
| **Sections**  | Create the categories shoppers browse, choose an icon or banner photo, drag to reorder, hide from the app, and rename — renaming carries every product in the section across automatically. |
| **Customers** | Everyone who signed up, joined to their orders: lifetime spend, order count, last order, and their full order history. |
| **Settings**  | Who is signed in, store totals, how to add another admin, and which collections the console touches. |

## First-time setup

### 1. Deploy the rules

The console needs the updated Firestore rules. From the `fashion_store/`
directory (one level up):

```bash
firebase deploy --only firestore:rules
```

There are no Storage rules to deploy: photos do not go to Firebase Storage.
See step 3.

### 2. Create the first admin

Admin rights are granted by a Firestore document, never from inside the app —
an admin UI that can mint admins is one compromised session away from being
someone else's store.

1. In the Firebase console, **Authentication → Users**, create (or find) the
   owner's email/password account and copy its **User UID**.
2. In **Firestore Database**, create a collection called `admins` and a
   document whose **ID is that UID**, with these fields:

   | Field    | Type    | Value            |
   | -------- | ------- | ---------------- |
   | `name`   | string  | `Store Owner`    |
   | `email`  | string  | their email      |
   | `role`   | string  | `owner`          |
   | `active` | boolean | `true`           |

Signing in without this document gets you a "No admin access" screen that
prints the exact document to create, UID included — so if you skip this step,
just sign in and copy what it shows you.

To revoke someone later, set `active` to `false`. Their open session is cut off
within seconds; no redeploy needed.

### 3. Set up photo uploads (Cloudinary)

Firebase Storage now wants the Blaze billing plan before it will even create a
bucket, so product and section photos go to **Cloudinary** instead — free, no
card, and far more quota than a shop like this uses.

It takes about three minutes and the full walkthrough is in
[`lib/config/cloudinary_config.dart`](lib/config/cloudinary_config.dart). The
short version: sign up, then create an **unsigned** upload preset restricted to
the `niyati` folder, `jpg,png,webp`, a 10 MB cap, and an incoming
transformation of `c_limit,w_1400,q_auto`.

Then pass your cloud name and preset name in at run time, which keeps them out
of the repo:

```bash
cd admin_app
flutter run -d chrome   --dart-define=CLOUDINARY_CLOUD_NAME=your_cloud_name   --dart-define=CLOUDINARY_UPLOAD_PRESET=niyati_products
```

Skip this and the console still runs — everything except the two **Add photo**
buttons, which say what is missing instead of failing mid-upload. **Settings →
Connection** shows whether it is configured.

### 4. Run it

```bash
cd admin_app
flutter run -d chrome
```

(with the two `--dart-define`s from step 3)

## Building for the web

```bash
flutter build web --release   --dart-define=CLOUDINARY_CLOUD_NAME=your_cloud_name   --dart-define=CLOUDINARY_UPLOAD_PRESET=niyati_products
```

The `--dart-define`s are needed here too — they are compiled in, so a build
made without them ships a console that cannot upload photos.

The output lands in `build/web/`. To host it on Firebase Hosting, run
`firebase init hosting` from `fashion_store/`, point the public directory at
`admin_app/build/web`, and answer **yes** to "configure as a single-page app".

The console is not linked from anywhere public — it is reached by URL — but the
Firestore rules are what actually protect it. Anyone who finds the URL and
signs in without an `admins` record sees nothing.

The upload preset is the one thing not protected by sign-in: it is unsigned, so
its name is visible in the shipped JavaScript and someone who found it could
push files into your Cloudinary account. That is why the preset is locked to
one folder, to image formats, and to a size cap — the worst case is wasted free
quota, not a compromised store.

## How it fits the customer app's data

The console writes the exact document shape the storefront already reads:

| Collection   | Written by | Read by |
| ------------ | ---------- | ------- |
| `products`   | console    | both |
| `sections`   | console    | both |
| `orders`     | customer app creates, console fulfils | both |
| `users`      | customer app | both |
| `admins`     | nobody (Firebase console only) | console |

A product document keeps every field the storefront's `Product.fromMap` expects
(`name`, `image`, `price`, `category`, `variants`, `mrp`, …) and adds
console-only ones (`images`, `stock`, `sku`, `brand`, `createdAt`) that the
customer app's parser ignores.

### What the console controls in the customer app

- **Sections** are read live from `sections/`. Add, rename, reorder or hide one
  here and the app's home-screen category tiles and its categories-screen
  sidebar follow, with no rebuild. Renaming rewrites `category` on every product
  in that section, so nothing is orphaned. The app sorts by `sortOrder`, skips
  sections with `active: false`, and falls back to a generic icon for an
  `iconKey` it does not recognise.
- **Hide from app** works: the storefront's product repository drops anything
  with `active: false` from browsing and category listings. A hidden product is
  still resolvable by id, so an existing cart entry, wishlist item or past order
  does not break — hiding removes it from the shop, not from a customer's own
  history.
- **Products with no `active` field** — anything predating the console — count
  as published, so tightening this never silently emptied the catalog.

The customer app's demo `ProductSeeder` has been deleted. The catalog is now
whatever this console says it is; nothing wipes or rewrites `products` at app
startup any more.
