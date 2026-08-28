This folder contains Firebase Cloud Functions for the Fashion Store app.

Available functions:
- `onUserCreate` — Auth trigger that creates a `users/{uid}` Firestore document.
- `setAdminClaim` — Callable function: sets `admin` custom claim on a target user. Caller must already have `admin` claim.

To deploy:

1. Install dependencies:
```bash
cd functions
npm install
```

2. Deploy functions:
```bash
firebase deploy --only functions
```

Notes:
- To set the first admin, use the Firebase Admin SDK from a secure environment (or set the claim via the project settings in the Firebase Console).
- Protect `setAdminClaim` further as needed (e.g., limit to owner UID stored in environment config).
