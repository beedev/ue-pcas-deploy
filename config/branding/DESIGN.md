---
schema: 1
brand:
  orgName: "United Educators"
  productName: "PCAS"
  logoUrl: "branding/ue-logo.png"
  logoAlt: "United Educators logo"
  logoSource: "https://www.ue.org/globalassets/global/ue-logo.png"
colors:
  primary: "#0020CD"
  primaryHover: "#001AA6"
  primaryActive: "#001585"
  tints: ["#F2F4FC", "#E6E9FA", "#CCD3F5"]
  text:
    primary: "#191919"
    secondary: "#4A4A4A"
    tertiary: "#6B6B6B"
    inverse: "#FFFFFF"
    link: "#0020CD"
  surfaces:
    page: "#F7F7F7"
    raised: "#FFFFFF"
    sunken: "#F0F0F0"
    hover: "#FAFAFA"
    selected: "#F2F4FC"
  borders:
    subtle: "#E8E8E8"
    default: "#D1D1D1"
    strong: "#8C8C8C"
    focus: "#0020CD"
  status:
    success: { fg: "#016F03", bg: "#E6F4E6" }
    warning: { fg: "#8C5A00", bg: "#FFF4E0" }
    error: { fg: "#C41000", bg: "#FDECEA" }
    neutral: { fg: "#4A4A4A", bg: "#F0F0F0" }
    info: { fg: "#0020CD", bg: "#F2F4FC" }
  chart: ["#0020CD", "#0EB58F", "#50256F", "#FF8529", "#2767B2", "#B7D433", "#FEB916", "#757575"]
typography:
  sans: '"neue-haas-grotesk-display","Inter",Arial,Helvetica,sans-serif'
  serif: '"minion-pro","Source Serif 4","Times New Roman",serif'
  mono: '"IBM Plex Mono","SF Mono",Consolas,monospace'
shape:
  radius: 0
  density: comfortable
  rowHeight: 44
chrome:
  showEnvironmentChip: false
  showPoweredByHip: true
  helpUrl: "/help/"
---

# United Educators PCAS: design

This file is the one place that says how PCAS looks. The staff app, the Underwriting Workbench simulator and any
DXP portal read it through the BFF (`GET /bff/design`). Change a value here, save, and the next page load shows it.
No rebuild, no code change.

## How to edit it

- **Quote every colour.** Write `"#0020CD"`, not `#0020CD`. In YAML an unquoted `#` starts a comment, so an unquoted
  colour is read as empty and the default applies. Colours are hex (`#RGB`, `#RRGGBB`) or `rgb(r, g, b)`.
- **Hover, active and the three tints are listed on purpose.** They are not worked out from the primary colour,
  because UE's own values do not follow a formula. If you change `primary`, change them too.
- **Fonts** are font stacks: names in quotes, separated by commas. A web font needs its stylesheet in
  `typography.fontUrls` (https only).
- **Booleans** are `true` or `false`, in lower case, without quotes.
- **Text must stay readable.** WCAG 2.1 AA asks for a contrast of at least 4.5 to 1. If `text.inverse` on `primary`,
  or `text.primary` on the page or raised surface, falls below that, the file is not refused: the BFF swaps in a
  readable colour for that pair and says so in the design check.

## The logo

- `logoUrl` is either an https address or a file in this folder (`branding/ue-logo.png`). A file name may contain
  letters, digits, dot, dash and underscore, and ends in `.png`, `.jpg`, `.svg`, `.webp` or `.gif`.
- `logoAlt` is required: it is what a screen reader says and what shows if the image cannot load. If the image
  fails, the top bar falls back to the text mark.
- Keep the logo readable on the top bar's white background, about 28 px tall.
- `logoSource` only records where the picture came from. Nothing reads it.

## What the settings control

- **Environment chip.** `chrome.showEnvironmentChip` is `false`: the chip that names a non-production environment is
  off, so a screen shared with a client does not carry it. Turn it on for internal builds.
- **Powered by HIP.** `chrome.showPoweredByHip` shows or hides the "Powered by HIP" line in the side bar.
- **Help.** The Help link in the top bar appears only when `chrome.helpUrl` is set: an https address, or a path on PCAS's own site. It is `/help/`, the in-app help page that the web container serves (`web/public/help/index.html`, D-192).
- **Corners.** `shape.radius` is in pixels. UE's look is square, so it is `0`. Pills stay round.

## Where to check your edit

Open **Administration, Platform components** and read the **Design check** card. It lists every setting the
BFF could not use and why, with the value it rejected, and shows which version of the file is live. A clean card means the
file is applied exactly as written.

## What this file does not cover

- **Keycloak's sign-in page.** It is Keycloak's own theme, set in Keycloak.
- **The flow navigator** (the demo panel): it keeps its own dark look on purpose.
- **Shadows.** They are fixed in the app.
