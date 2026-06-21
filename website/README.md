## HostBora marketing website

Static single-page site for **HostBora** — property management for landlords, property managers, and hosts in Tanzania and East Africa (BnB + long-term rent).

### Preview locally

From the repo root:

```bash
cd website
python3 -m http.server 5173
```

Then open [http://localhost:5173](http://localhost:5173).

You can also open `index.html` directly in a browser; use a local server if you need correct paths for assets or future routing.

### Files

| File | Purpose |
|------|---------|
| `index.html` | Landing page (hero, features, workspaces, audience, trust, contact) |
| `styles.css` | Responsive layout and brand styles |
| `app.js` | Mobile nav + contact form → Spring Boot API |

### Contact form

The form POSTs JSON to the Spring Boot API at **`POST /api/website/contact`** (public, no auth). The backend sends email to `support@hostbora.co.tz` via the configured SMTP mail settings.

Production URL: `https://hostbora.co.tz:8444/api/website/contact`

Local dev (with Spring Boot on port 8080): `http://localhost:8080/api/website/contact`

Configure the recipient in `application.properties`:

```properties
website.contact.mail-to=support@hostbora.co.tz
```
| `privacy-policy.html` | Privacy policy |
| `assets/logo.svg` | Logo / favicon |
| `.nojekyll` | GitHub Pages (skip Jekyll) |

### Deploy

Upload the `website/` folder to any static host (Netlify, Vercel, S3, nginx, etc.).

For **GitHub Pages**, set the source to the `website/` directory and keep `.nojekyll` at the root of that folder.

### Brand colors

Aligned with the Flutter app (`lib/app/core/values/app_colors.dart`):

- Primary: `#1C6E64`
- Primary dark: `#145C54`
- Surface: `#F6F8F8`
- Accent green: `#2ECC71`

### Edit content

Update copy in `index.html`. Styles live in `styles.css`. Replace `assets/logo.svg` when you have final brand assets.
