# Atelier Fabric Designer Production Readiness Audit

Date: 2026-06-23  
Repo: `/Users/mint/fabric-designer-ios`  
App: Atelier Fabric Designer iOS / TestFlight demo

## Executive Summary

The current app is a strong visual demo, but it is not ready to sell subscriptions, take paid production orders, or send tailor-grade specifications. The first production milestone should not be Stripe or crypto checkout. It should be:

1. Manual measurement fallback and scan confidence gating.
2. Order PDF generation with all tailor/payment/shipping details.
3. Email/share workflow for sending the PDF order packet to tailors.

Custom fabric uploads and photorealistic avatars should come after the order workflow is trustworthy.

## Current State

The repo contains:

- Body scanning and measurement extraction in `FabricDesigner/LiDARScan/`.
- `BodyMeasurements` model in `FabricDesigner/Models/BodyMeasurements.swift`.
- Local order model and payment-method enum in `FabricDesigner/Models/Order.swift`.
- Checkout UI in `FabricDesigner/Checkout/CheckoutView.swift`.
- Reference photo and notes capture in `FabricDesigner/Photos/PhotoCaptureView.swift`.
- Hardcoded fabric catalog in `FabricDesigner/Models/SwatchCatalog.swift`.
- SceneKit avatar/mannequin generated from primitive geometry in `FabricDesigner/Designer/AvatarMesh.swift`.
- Fabric material factory in `FabricDesigner/Designer/FabricMaterial.swift`.

Checkout currently creates a local `Order` and shows a confirmation sheet. It explicitly says no payment is charged and no data leaves the device.

## Audit Findings

### 1. Measurement Reliability Is The Main Production Blocker

Observed issue:

- User screenshots show scan confidence around 35%.
- The app still allows "Use Dimensions" at low confidence.
- Several generated body values are not tailor-safe.

Code issue:

- `BodyScanCoordinator` uses `ARBodyTrackingConfiguration`.
- `MeasurementExtractor` expects a point cloud from `ARMeshAnchor`.
- Mesh anchors are not reliably produced in the current body-tracking path.
- When point cloud data is empty or sparse, circumference values fall back to anthropometric estimates based mostly on shoulder width.

Impact:

- Some measurements can look plausible while others are wrong.
- This is acceptable for a demo, not for cutting garments.

Required fix:

- Add a trusted manual measurement flow.
- Treat camera/LiDAR scan output as an optional prefill, not final truth.
- Block accepting scans below a production threshold.

Recommended threshold:

- Disable `Use Dimensions` below 80% confidence.
- Offer `Enter Measurements Manually` and `Rescan`.

### 2. LiDAR Cannot Be Required

Regular iPhone 15 does not have LiDAR. LiDAR is available on Pro iPhones and certain iPad Pro models. The retail app must work without LiDAR.

Required device behavior:

- If LiDAR is unavailable: show manual measurement mode as the primary path.
- If body tracking fails: show manual measurement mode.
- If scan confidence is low: require manual correction.
- If LiDAR is available and confidence is high: allow scan-assisted measurements, but still show editable values before order placement.

Production framing:

- Manual measurements are the reliable baseline.
- Camera/body tracking is an assistive prefill.
- LiDAR is an enhanced mode, not a dependency.

### 3. Order PDF Is Required Before Real Commerce

Tailors need a complete order packet, not just an in-app confirmation.

PDF must include:

- Order ID.
- Created timestamp.
- Customer full name.
- Shipping address: line 1, line 2, city, region, postal code, country.
- Shipping/fit notes.
- All body measurements in cm and inches:
  - height
  - shoulder
  - sleeve
  - chest
  - waist
  - hip
  - inseam
  - neck
  - thigh
- Measurement source:
  - manual
  - camera estimate
  - LiDAR enhanced
  - demo
- Measurement confidence.
- Selected outfit line items:
  - garment name
  - category
  - fabric type
  - color name/hex
  - selected size
- Reference photo count.
- Designer notes.
- Payment method.
- Base price.
- Total price.
- Payment record fields:
  - crypto network
  - wallet address or receiving account
  - transaction hash
  - cash/trade verification note
  - payment status: pending, verified, waived, failed

### 4. Email Should Use A Share Sheet First

Fully automatic email from the app requires a backend or user mail configuration. For the first production build, use local PDF generation plus the iOS share sheet.

MVP flow:

1. User places order.
2. App generates PDF.
3. App opens iOS share sheet.
4. Owner/user emails the PDF to the tailor.

Later backend flow:

1. App submits order to API.
2. Backend stores order + attachments.
3. Backend sends email to tailor.
4. Backend records delivery status.

### 5. Custom Fabric Upload Is Valuable But Phase 2

Current fabric library is hardcoded in `SwatchCatalog`.

Phase 2 should add:

- Fabric Library screen for owner/designer.
- Add fabric from camera/photos.
- Fabric fields:
  - name
  - fabric category/type
  - supplier/book name
  - SKU or internal code
  - availability: in stock / out of stock / archived
  - notes
  - image file reference
- Remove/archive fabrics.
- Use uploaded fabric images as SceneKit material diffuse textures.

For the first implementation, store uploaded fabrics locally. Real-time multi-user sync requires a backend and cloud storage, so it should not block items 1-3.

### 6. Photorealistic Mannequin Is Possible But Not First

Current avatar is primitive SceneKit geometry. Replacing it with a `.usdz` mannequin is feasible and moderate effort. True photoreal body/cloth simulation is much larger.

Recommended path:

- Phase 2 or 3: replace primitive avatar with a better `.usdz` mannequin.
- Keep garment overlays simple.
- Do not attempt real cloth simulation until the measurement/order workflow works.

## Codex Build Scope: Items 1-3

Build only this first:

1. Manual measurements + scan confidence gating.
2. Order PDF generation.
3. Share/email PDF workflow.

Do not build yet:

- Stripe.
- Crypto wallet integration.
- Custom fabric upload.
- Real-time sync.
- Photoreal mannequin.
- Backend email.

## Backend, Payments, And Business Accounts Needed Later

Items 1-3 can be built without a backend by generating PDFs locally and using the iOS share sheet. The accounts below become necessary when the project needs synced fabrics, automatic tailor emails, real payments, subscriptions, admin order tracking, and production support.

### Required For A Production Backend

- Apple Developer / App Store Connect account: TestFlight, App Store releases, bundle IDs, signing, app capabilities.
- Backend hosting account: Vercel, Supabase Edge Functions, Firebase, or Cloudflare Workers.
- Database account: Supabase Postgres, Firebase Firestore, or Cloudflare D1.
- File storage account: Supabase Storage, Firebase Storage, Cloudflare R2, or AWS S3.
- Email sending account: Resend, Postmark, SendGrid, Mailgun, or Cloudflare Email Service.
- Error tracking account: Sentry or Firebase Crashlytics.
- Product analytics account: PostHog, Amplitude, Firebase Analytics, or similar.
- Domain + business email: used for customer support, tailor emails, transactional email authentication, and policy pages.

### Recommended Minimum Stack

Use this stack unless there is a strong reason not to:

- Supabase for auth, database, and fabric/order/PDF storage.
- Stripe for card payments, Apple Pay, subscriptions, invoices, receipts, and customer portal.
- Stripe stablecoin payments for supported crypto checkout where available.
- Resend or Postmark for tailor order emails.
- Sentry for app/backend errors.
- Vercel or Cloudflare Workers for lightweight backend endpoints and admin tools.

### Stripe And Crypto Notes

Stripe should be the primary payment account. It can cover normal card/Apple Pay subscription needs and also has crypto products:

- Stablecoin payments: customers pay with crypto and the merchant can receive settlement as fiat in the Stripe balance.
- Stablecoin subscriptions: useful for recurring crypto payments, but currently marked as private preview in Stripe docs, so do not plan the first production build around it without confirming account eligibility.
- Fiat-to-crypto onramp: useful if customers need to acquire crypto, but not required for the first order workflow.

Implementation guidance:

- Use Stripe Checkout or PaymentSheet for normal card/Apple Pay checkout.
- Use Stripe Billing for SaaS subscriptions.
- Use Stripe stablecoin payments only after confirming region, currency, and account support.
- Keep a manual payment-record field for cash, trade, and any off-platform crypto until automated verification exists.

### Payment Records Needed In The App

The `Order` model should eventually store payment details separately from payment method. Recommended fields:

- payment method: card, Apple Pay, Stripe stablecoin, crypto manual, cash, barter/trade, electronic transfer.
- payment status: pending, verified, failed, refunded, waived.
- Stripe payment intent ID or checkout session ID.
- Stripe customer ID for subscriptions.
- subscription ID, if applicable.
- crypto network.
- crypto token, such as USDC.
- transaction hash.
- receiving wallet/account.
- cash/trade verification note.
- verified by.
- verified timestamp.

### Admin / Owner Accounts

The owner or business administrator will need:

- Stripe dashboard access.
- Supabase/Firebase/Cloudflare dashboard access.
- Email provider dashboard access.
- Apple Developer admin access.
- Storage bucket access for fabrics, reference photos, and generated PDFs.
- Admin dashboard login for fabric inventory and order review.

### Legal And Policy Requirements

Before real public launch:

- Privacy policy URL.
- Terms of service URL.
- Refund/return policy.
- Payment terms for cash, trade, crypto, and custom clothing.
- Data retention policy for body measurements, shipping addresses, photos, and order PDFs.
- Consent copy explaining that body measurements and photos may be shared with tailors for fulfillment.

These policies are especially important because the app collects body measurements, customer contact details, shipping addresses, reference photos, and payment records.

## Implementation Requirements For Items 1-3

### Task 1: Manual Measurements

Create a manual measurement screen or sheet.

Fields:

- height
- shoulder
- sleeve
- chest
- waist
- hip
- inseam
- neck
- thigh

Requirements:

- User can enter cm values.
- Optional inches display can be added, but storage remains cm.
- Values must be editable after scan.
- Save into existing `BodyMeasurements`.
- Add measurement source metadata if possible.
- Reject impossible values with clear validation.

Suggested validation:

- height: 90-230 cm
- shoulder: 25-80 cm
- sleeve: 30-100 cm
- chest: 50-180 cm
- waist: 40-170 cm
- hip: 50-190 cm
- inseam: 40-120 cm
- neck: 20-70 cm
- thigh: 25-100 cm

### Task 2: Confidence Gating

Modify `ScanResultsView`.

Rules:

- If confidence is below 0.80, disable `Use Dimensions`.
- Show copy: "Scan confidence is too low for tailor measurements. Rescan or enter measurements manually."
- Add a button: `Enter Manually`.
- A low-confidence scan may prefill the manual form, but cannot be accepted directly.

### Task 3: Order PDF

Add a PDF generator service.

Recommended file:

- `FabricDesigner/Orders/OrderPDFGenerator.swift`

Inputs:

- `Order`
- optional `BodyMeasurements`
- optional reference images later

Output:

- local PDF file URL.

PDF content:

- Header: Atelier Fabric Designer Order Sheet.
- Customer/shipping section.
- Measurement section.
- Outfit/fabric section.
- Payment record section.
- Notes/reference photos section.

### Task 4: Share/Email PDF

After checkout confirmation:

- Generate the PDF.
- Present iOS share sheet with the PDF.
- User can send it through Mail, Gmail, AirDrop, Files, etc.

Recommended files:

- `FabricDesigner/Orders/ShareSheet.swift`
- Modify `CheckoutView.swift`.

## Acceptance Criteria

The build is ready for another TestFlight round when:

- A regular iPhone 15 can complete the flow without LiDAR.
- Low-confidence scans cannot be accepted as final tailor measurements.
- User can manually enter measurements.
- Checkout creates an order PDF.
- PDF contains customer, shipping, measurement, outfit, and payment details.
- Share sheet can send/export the PDF.
- Existing demo design/fabric flow still works.

## Suggested BBS Summary

Atelier is currently a demo, not production SaaS. Measurement reliability is the blocker. The first build should make measurements manual-first, block low-confidence scans, generate a tailor-ready PDF order sheet, and let users email/share the PDF. Fabric upload and photoreal mannequin are valuable but should wait until the order workflow works.
