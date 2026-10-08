# James Ares — links

Static link hub. One HTML file (inline CSS, ~20 lines JS for the 18+ gate), self-hosted subsetted fonts, AVIF/WebP avatar. No framework, no build step.

## Deploy (Cloudflare Pages)

- Framework preset: **None**
- Build command: *(empty)*
- Build output directory: `public`

Or direct: `wrangler pages deploy public --project-name james-ares-linktree`

## Edit

- Links/copy: `public/index.html` (the `<nav>` block).
- Gate: shown until "I'm 18+" is clicked, then remembered in `localStorage` (`ja18`).
- Brand images/fonts: replace files in `src/brand/`, then `./scripts/build-assets.sh` (needs `uvx` + `npx`). It re-subsets fonts, re-encodes images, content-hashes filenames and rewrites refs in `index.html`. If copy adds non-Latin characters, widen `UNICODES` in the script.

Design source: claude.ai/design project "James Ares Links Final".
