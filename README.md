# Athletica — Sport + Nutrition + Premium

This build includes StoreKit 2 subscription infrastructure with:

- Monthly product ID: `com.example.athletica.premium.monthly`
- Yearly product ID: `com.example.athletica.premium.yearly`
- Premium paywall
- Purchase / restore flow
- Entitlement checking
- 7-day free-trial messaging

## Important: configure the free trial in App Store Connect

The app cannot create the introductory free trial itself. In App Store Connect:

1. Create the two auto-renewable subscriptions using the product IDs above.
2. Put them in a subscription group, e.g. `Athletica Premium`.
3. Configure an introductory offer for the group. Recommended launch offer: **7 days free**.
4. Add localized display names and descriptions.
5. Set the price tiers for monthly and annual plans.
6. Test purchases using a Sandbox tester account before submission.

The UI intentionally says the 7-day trial must be configured in App Store Connect so the marketing claim is not made live until Apple has the offer configured.

## Suggested pricing

- Monthly: $9.99 USD equivalent tier
- Annual: $59.99 USD equivalent tier
- 7-day free trial

Choose the actual App Store Connect price tier appropriate to your market.

## Build

Open `Athletica.xcodeproj` in Xcode, select your Apple Developer team, change the bundle identifier, and run on an iPhone. StoreKit purchases require the App Store Connect products or a StoreKit Configuration file for local testing.

Before App Store submission, complete the app privacy details, subscription metadata, screenshots, support URL, privacy policy URL, age rating, HealthKit usage descriptions, and real-device testing.
