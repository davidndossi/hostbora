## Paa Yangu website

This is a static marketing website for the Paa Yangu app.

### Run locally

From the repo root:

```bash
cd website
python3 -m http.server 5173
```

Then open `http://localhost:5173`.

### Deploy

- **Any static host**: upload the contents of `website/`.
- **GitHub Pages**: set Pages to deploy from `website/` (or `/docs` if you prefer), and keep `.nojekyll`.

### Update content

Edit:
- `website/index.html`
- `website/styles.css`
- `website/app.js`

Assets live in `website/assets/`, including **`logo.svg`** (header, footer, favicon, hero eyebrow). Replace `logo.svg` if you add an official brand pack.
