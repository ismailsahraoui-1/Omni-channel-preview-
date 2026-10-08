# Web + Omnichannel Live Preview

A Contentful **preview platform** that lets editors switch between the real website and an
omnichannel view of the same entry from inside Live Preview, with no need to close the preview and change platform.

- **Website view** shows the space's real Colorful demo website with draft content. Live updates
  and inspector mode work.
- **Omnichannel view** renders the entry's hero banner and SEO fields as **Paid Social, Google Search,
  Email, Mobile App and Trade-show Screen** mock-ups. These use the space's real draft content,
  with live updates as you type and inspector mode (click an element to jump to its field).

A slim toolbar (styled like Contentful's) switches views. In the Website view it floats over the site
and slides away after 2 s (hover the top edge or click the blue handle to bring it back; 📌 pins it),
so the website starts at the very top of the preview and inspector outlines line up.

No changes are made to the website, its code, or the content model.

---

## How it works

```
Contentful Live Preview iframe
└── index.html  (Netlify, e.g. https://my-preview.netlify.app)
    ├── View = Website      → <iframe src="/api/enable-draft?...">
    │                           └── proxied by _redirects to the Colorful demo website
    │                               (runs on the Netlify origin, so Contentful accepts
    │                                its Live Preview SDK messages)
    └── View = Omnichannel  → fetches the entry from the Content Preview API (CPA)
                               and renders the channels itself, using
                               @contentful/live-preview for inspector + live updates
```

### Why a pass-through (`_redirects`)?
Contentful only accepts Live Preview messages (live updates, inspector clicks) from the **origin of
the configured preview URL**. When the website is embedded inside our page from its own domain,
Contentful ignores it. Proxying the website through the Netlify domain makes the origins match.

### Why does the toolbar float in the Website view?
Contentful draws inspector outlines using coordinates the website reports from **its own frame**.
If our toolbar pushes the website down, every outline is offset by the toolbar height. Keeping the
website at `top: 0` (toolbar overlays it and slides away) keeps outlines aligned.

### What Omnichannel reads
| Channel element | Source |
|---|---|
| Heading / body / image / buttons | Landing page **Hero** (Banner or Call to Action). If Hero is empty, the first Banner/CTA in **Sections** |
| Google Search title / description | **SEO Metadata** title & description, falling back to page Title / Teaser |
| Email preview line | Page **Teaser** |
| Brand name | `brand` URL param → SEO title text before `|` → website host |

Live updates: edits to text/media update as you type (`subscribe('edit')`); swapping references
re-fetches after autosave (`subscribe('save')`).

---

## Set up a new space (≈10 minutes)

**1. Find the website host and preview secret**
Contentful → *Settings → Content preview → Web Preview* → **Landing Page** URL, e.g.
```
https://colorful-demo-2-0-XXXXXXXXX.colorful-demo.com/api/enable-draft?ctype=landingPage&slug={entry.fields.slug}&locale={locale}&secret=SECRET&timeline={timeline}
```
Note the host (`colorful-demo-2-0-XXXXXXXXX.colorful-demo.com`) and `SECRET`.

**2. Build and deploy**
```bash
./scripts.sh <name> colorful-demo-2-0-XXXXXXXXX.colorful-demo.com
```
Drag `dist/<name>.zip` onto <https://app.netlify.com/drop> (be logged in, or the site expires).
Note the Netlify address.

**3. Create a Content Preview API token**
*Settings → API keys* → any key → **Content Preview API - access token**.

**4. Add the preview platform**
*Settings → Content preview → Add preview platform* → name **Web + Omnichannel** → add two
*Content Type URLs*:

**Landing Page**
```
https://NETLIFY-SITE.netlify.app/?space=SPACE_ID&env=master&token=PREVIEW_TOKEN&entry={entry.sys.id}&locale={locale}&ctype=landingPage&slug={entry.fields.slug}&site=https://WEBSITE_HOST&secret=SECRET&timeline={timeline}
```
**Banner** and **Call to Action**
```
https://NETLIFY-SITE.netlify.app/?space=SPACE_ID&env=master&token=PREVIEW_TOKEN&entry={entry.sys.id}&locale={locale}&view=omni
```
Optional: add `&brand=Acme` to both to set the brand name shown in the channels.

> ⚠️ The **long** URL must be on Landing Page. If the short one is used there, the Website option is greyed out.

**5. Use it**
Open a landing page → *Preview → Platform: Change → Web + Omnichannel* → switch with the toolbar.

### Updating an existing space
Rebuild the zip with the same host and drag it onto that Netlify site's **Deploys** page. The URL stays the same.

---

## URL parameters

| Param | Required | Meaning |
|---|---|---|
| `space`, `env` | ✔ | Contentful space / environment |
| `token` | ✔ | Content Preview API token (Delivery token works but shows published content only) |
| `entry`, `locale` | ✔ | `{entry.sys.id}`, `{locale}` |
| `ctype`, `slug`, `site`, `secret` | Website view | Used to build `/api/enable-draft?...` on the proxied site |
| `timeline` | optional | Pass-through for Releases/Timeline |
| `view` | optional | `web` (default) or `omni` |
| `ch` | optional | Initial channel: `social`, `search`, `email`, `mobile`, `screen` |
| `brand` | optional | Brand name override |

---

## Known limitations
- **Hero + SEO only.** Sections lower on the page are not rendered in the channels.
- **Personalization.** Channels show the default (baseline) banner, not Ninetailed variants.
- **Homepage routing.** The demo site's homepage comes from *App Settings → Logo target*; if that
  points to a different page than the entry being edited, Website and Omnichannel show different
  content (by design: Omnichannel follows the open entry).
- **Default platform.** Contentful may reopen the first platform (Web Preview) after some actions
  (e.g. editing personalization). Workaround: put the Landing Page URL above into the managed
  Web Preview platform, or disable Landing Page in it.
- **One deployment per space**, because `_redirects` is a static proxy to one website host.
- **Secrets in the preview URL.** The preview token and secret live in the Contentful preview
  platform URL (never in this repo). Anyone with that URL can read draft content, so don't share it.

## Suggested next steps (for a team-wide version)
1. **Build it into the Colorful demo site** (recommended). Add the view switch and channel pages
   to the managed demo app. Every new space then gets it via the managed Web Preview with no proxy,
   no extra platform, no token in URLs, and native outline alignment.
2. **Single shared deployment.** Replace `_redirects` with a Netlify Edge Function that proxies to the
   host given in the `site` param (allow-list `*.colorful-demo.com`), so one site serves every space.
3. Render more of the page (sections/collections) and resolve personalization variants.

## Repo layout
```
site/index.html            the preview page (no build step, no secrets)
site/_redirects.template   Netlify proxy rule; WEBSITE_HOST is filled in per space
scripts.sh                 builds dist/<name>.zip for one space
```
