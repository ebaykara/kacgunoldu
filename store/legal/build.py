"""
Builds the app's website and the in-app legal texts:

  * <site>/kacgunoldu/index.html, <site>/kacgunoldu/en/index.html
        one-page site (landing.html + landing_content.py)
  * <site>/kacgunoldu/{gizlilik,privacy,kullanim-kosullari,terms,destek,support}/index.html
        legal and support pages (template.html + content.py)
  * <site>/kacgunoldu/{site.css,site.js,icon.png,og.png,img/*.webp}
  * lib/legal/legal_text.dart  (Turkish + English, shown in the app)

Usage:  python store/legal/build.py [site_public_dir]
        python store/legal/build.py --dart      (only lib/legal/legal_text.dart)
The site dir defaults to C:/dev/emalabs_site/public (emalabs.info). The privacy
pages are also copied to gezip.app (LEGACY), whose URL is in the Play listing.
Needs Pillow (screenshots -> webp).
"""
import html
import json
import os
import re
import shutil
import sys

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, HERE)
import content as C  # noqa: E402
import landing_content as LC  # noqa: E402

ARGS = [a for a in sys.argv[1:] if not a.startswith("--")]
DART_ONLY = "--dart" in sys.argv[1:]
SITE = ARGS[0] if ARGS else r"C:/dev/emalabs_site/public"
OUT = os.path.join(SITE, "kacgunoldu")
LEGACY = os.path.join(r"C:/Users/eyupb/Desktop/gezip_app/public", "kacgunoldu")
BRAND = "Kaç Gün Oldu?"
BASE = "https://emalabs.info/kacgunoldu"
LANDING = {"tr": LC.TR, "en": LC.EN}

L10N = {
    "tr": dict(
        lang="tr", updated="Son güncelleme", email="E-posta", web="Web",
        names={"privacy": "Gizlilik", "terms": "Koşullar", "support": "Destek"},
        chip_free="Reklamsız · hesapsız", toc="Bu sayfada",
    ),
    "en": dict(
        lang="en", updated="Last updated", email="Email", web="Web",
        names={"privacy": "Privacy", "terms": "Terms", "support": "Support"},
        chip_free="No ads · no account", toc="On this page",
    ),
}
KIND = {"gizlilik": "privacy", "privacy": "privacy", "kullanim-kosullari": "terms",
        "terms": "terms", "destek": "support", "support": "support"}
PAIR = {"gizlilik": "privacy", "privacy": "gizlilik", "kullanim-kosullari": "terms",
        "terms": "kullanim-kosullari", "destek": "support", "support": "destek"}
SLUG = {"tr": {"privacy": "gizlilik", "terms": "kullanim-kosullari", "support": "destek"},
        "en": {"privacy": "privacy", "terms": "terms", "support": "support"}}

# Stroke icons (24x24), styled by svg.i in site.css.
ICONS = {
    "bell": '<path d="M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9"/><path d="M10.3 21a1.94 1.94 0 0 0 3.4 0"/>',
    "widget": '<rect x="3" y="3" width="8" height="8" rx="2.5"/><rect x="13" y="3" width="8" height="8" rx="2.5"/><rect x="3" y="13" width="8" height="8" rx="2.5"/><rect x="13" y="13" width="8" height="8" rx="2.5"/>',
    "late": '<circle cx="12" cy="13" r="8"/><path d="M12 9v4l2.5 2"/><path d="M5 3 2 6M22 6l-3-3"/>',
    "timeline": '<circle cx="6" cy="6" r="2"/><circle cx="6" cy="18" r="2"/><path d="M6 8v8M11 6h9M11 12h6M11 18h9"/>',
    "chart": '<path d="M3 3v18h18"/><path d="M7 16v-4M11 16V8M15 16v-6M19 16V6"/>',
    "search": '<circle cx="11" cy="11" r="7"/><path d="m20 20-3.5-3.5"/>',
    "share": '<circle cx="18" cy="5" r="3"/><circle cx="6" cy="12" r="3"/><circle cx="18" cy="19" r="3"/><path d="m8.6 13.5 6.8 4M15.4 6.5l-6.8 4"/>',
    "backup": '<path d="M12 3v12"/><path d="m7 10 5 5 5-5"/><path d="M5 21h14"/>',
    "palette": '<path d="M12 22a10 10 0 1 1 10-10c0 3-2.5 4-4.5 4H16a2 2 0 0 0-1.4 3.4A2 2 0 0 1 12 22z"/><circle cx="7.5" cy="10.5" r="1.2"/><circle cx="12" cy="7" r="1.2"/><circle cx="16.5" cy="10.5" r="1.2"/>',
    "user": '<circle cx="12" cy="8" r="4"/><path d="M4 21a8 8 0 0 1 16 0"/>',
    "ban": '<circle cx="12" cy="12" r="9"/><path d="m5.6 5.6 12.8 12.8"/>',
    "cloud": '<path d="M17.5 19H8a5 5 0 1 1 .9-9.9A6 6 0 0 1 20 11.5a3.8 3.8 0 0 1-2.5 7.5z"/><path d="m3 3 18 18"/>',
    "trash": '<path d="M4 7h16M10 11v6M14 11v6M6 7l1 13a1 1 0 0 0 1 1h8a1 1 0 0 0 1-1l1-13M9 7V4h6v3"/>',
    "check": '<path d="m5 12.5 4.5 4.5L19 7.5"/>',
    "check-circle": '<circle cx="12" cy="12" r="9"/><path d="m8 12.5 3 3 5-6"/>',
    "scissors": '<circle cx="6" cy="6" r="3"/><circle cx="6" cy="18" r="3"/><path d="M8.1 8.1 20 20M8.1 15.9 20 4"/>',
    "plus": '<path d="M12 5v14M5 12h14"/>',
    "rhythm": '<path d="M3 12h4l3-8 4 16 3-8h4"/>',
}
STEP_ICONS = ["plus", "check", "rhythm"]
PLAY_SVG = '<svg class="si" viewBox="0 0 24 24" aria-hidden="true"><path d="M4.2 2.6a1.2 1.2 0 0 0-.5 1v16.8c0 .4.2.8.5 1l9.5-9.4zM14.9 13.2l2.6 2.6-11.2 6.4zM17.5 8.2l-2.6 2.6L6.3 1.9zM18.7 8.9 21 10.3a1.9 1.9 0 0 1 0 3.4l-2.3 1.4-2.8-2.8z"/></svg>'
APPLE_SVG = '<svg class="si" viewBox="0 0 24 24" aria-hidden="true"><path d="M18.7 19.5c-.8 1.2-1.7 2.4-3 2.5-1.4 0-1.8-.8-3.3-.8-1.5 0-2 .8-3.3.8-1.3.1-2.3-1.3-3.1-2.5C4.2 17 3 12.5 4.7 9.4c.9-1.5 2.4-2.5 4.1-2.5 1.3 0 2.5.9 3.3.9.8 0 2.3-1.1 3.8-.9.7 0 2.5.3 3.6 2-.1.1-2.2 1.3-2.1 3.8 0 3 2.6 4 2.7 4-.1.1-.5 1.4-1.4 2.8M13 3.5c.7-.8 1.9-1.5 2.9-1.5.1 1.2-.3 2.4-1 3.2-.7.9-1.8 1.5-3 1.4-.1-1.1.5-2.3 1.1-3.1z"/></svg>'


def icon(name):
    return '<svg class="i" viewBox="0 0 24 24" aria-hidden="true">%s</svg>' % ICONS[name]


def fill(tpl, vals):
    out = tpl
    for k, v in vals.items():
        out = out.replace("{{%s}}" % k, v)
    left = re.findall(r"\{\{(\w+)\}\}", out)
    assert not left, left
    return out


# ---------------------------------------------------------------- shared chrome

def header(lang, on_home, alt_path):
    t = LANDING[lang]
    home = t["self_path"]
    pre = "" if on_home else home
    other = "en" if lang == "tr" else "tr"
    return (
        '  <header class="nav">\n'
        '    <div class="nav-inner">\n'
        '      <a href="%(home)s" class="brand" aria-label="%(brand)s">\n'
        '        <img src="/kacgunoldu/icon.png" alt="" width="36" height="36" />\n'
        '        <span>%(brand)s</span>\n'
        '      </a>\n'
        '      <nav class="nav-links" id="nav-links" aria-label="%(menu)s">\n'
        '        <a href="%(pre)s#nasil">%(how)s</a>\n'
        '        <a href="%(pre)s#ozellikler">%(feat)s</a>\n'
        '        <a href="%(pre)s#gizlilik">%(priv)s</a>\n'
        '        <a href="%(pre)s#sss">%(faq)s</a>\n'
        '        <a href="%(alt)s" class="lang" hreflang="%(other)s" lang="%(other)s">%(alt_label)s</a>\n'
        '      </nav>\n'
        '      <div class="nav-end">\n'
        '        <a href="%(alt)s" class="lang lang--compact" hreflang="%(other)s" lang="%(other)s">%(alt_short)s</a>\n'
        '        <a href="%(pre)s#indir" class="btn btn--small">%(cta)s</a>\n'
        '        <button class="menu-btn" type="button" aria-expanded="false" aria-controls="nav-links" aria-label="%(menu)s">\n'
        '          <span></span><span></span>\n'
        '        </button>\n'
        '      </div>\n'
        '    </div>\n'
        '  </header>'
        % dict(home=home, brand=BRAND, menu=t["menu"], pre=pre, how=t["nav_how"], feat=t["nav_features"],
               priv=t["nav_privacy"], faq=t["nav_faq"], alt=alt_path, other=other,
               alt_label=t["alt_label"],
               alt_short=other.upper(), cta=t["nav_cta"])
    )


def footer(lang):
    t = LANDING[lang]
    s = t["slugs"]
    home = t["self_path"]
    link = lambda href, text: '            <li><a href="%s">%s</a></li>\n' % (href, text)  # noqa: E731
    return (
        '  <footer class="footer">\n'
        '    <div class="wrap">\n'
        '      <div class="footer-grid">\n'
        '        <div>\n'
        '          <a href="%s" class="brand"><img src="/kacgunoldu/icon.png" alt="" width="36" height="36" /><span>%s</span></a>\n'
        '          <p class="footer-tagline">%s</p>\n'
        '        </div>\n'
        '        <div>\n          <h4>%s</h4>\n          <ul>\n%s%s%s          </ul>\n        </div>\n'
        '        <div>\n          <h4>%s</h4>\n          <ul>\n%s%s          </ul>\n        </div>\n'
        '        <div>\n          <h4>%s</h4>\n          <ul>\n%s%s%s          </ul>\n        </div>\n'
        '      </div>\n'
        '      <div class="footer-bar">\n'
        '        <span>© 2026 EMA Labs</span>\n'
        '        <span><a href="https://emalabs.info">emalabs.info</a></span>\n'
        '      </div>\n'
        '    </div>\n'
        '  </footer>'
        % (home, BRAND, t["tagline"],
           t["f_app"], link(home + "#nasil", t["nav_how"]), link(home + "#ozellikler", t["nav_features"]),
           link(home + "#sss", t["nav_faq"]),
           t["f_legal"], link("/kacgunoldu/" + s["privacy"], t["privacy"]), link("/kacgunoldu/" + s["terms"], t["terms"]),
           t["f_contact"], link("/kacgunoldu/" + s["support"], t["support"]),
           link("mailto:" + C.EMAIL, C.EMAIL), link(t["alt_path"], t["alt_label"]))
    )


# ---------------------------------------------------------------- legal pages

def inline(text):
    t = html.escape(text, quote=False)
    t = re.sub(r"\*\*(.+?)\*\*", r"<strong>\1</strong>", t)
    t = re.sub(r"\[([^\]]+)\]\(([^)]+)\)", lambda m: '<a href="%s">%s</a>' % (m.group(2), m.group(1)), t)
    return t


def block_html(kind, val, t):
    if kind == "p":
        return "          <p>%s</p>\n" % inline(val)
    if kind == "ul":
        return "          <ul>\n%s          </ul>\n" % "".join("            <li>%s</li>\n" % inline(i) for i in val)
    if kind == "callout":
        return '          <div class="callout">%s</div>\n' % inline(val)
    if kind == "contact":
        return (
            '          <div class="contact-card">\n'
            '            <div class="ct">%s</div>\n'
            '            <div class="row"><span class="label">%s</span><a href="mailto:%s">%s</a></div>\n'
            '            <div class="row"><span class="label">%s</span><a href="https://emalabs.info">emalabs.info</a></div>\n'
            "          </div>\n" % (BRAND + " · EMA Labs", t["email"], C.EMAIL, C.EMAIL, t["web"])
        )
    raise ValueError(kind)


def page(doc, lang, tpl):
    t = L10N[lang]
    sections = ""
    toc = ""
    for i, (title, blocks) in enumerate(doc["sections"], 1):
        body = "".join(block_html(k, v, t) for k, v in blocks)
        title_h = html.escape(title, quote=False)
        sections += (
            '        <section class="doc-section" id="b%d">\n'
            '          <h2><span class="n">%02d</span>%s</h2>\n%s        </section>\n'
            % (i, i, title_h, body)
        )
        toc += '          <li><a href="#b%d"><span>%02d</span>%s</a></li>\n' % (i, i, title_h)
    lead = '        <div class="doc-lead">%s</div>' % inline(doc["lead"])
    chips = (
        '          <span class="chip"><span class="dot"></span>%s: %s</span>\n'
        '          <span class="chip">%s</span>' % (t["updated"], doc["updated"], t["chip_free"])
    )
    kind = KIND[doc["slug"]]
    tabs = "".join(
        '          <a href="/kacgunoldu/%s"%s>%s</a>\n'
        % (SLUG[lang][k], ' aria-current="page"' if k == kind else "", n)
        for k, n in t["names"].items()
    )
    other = "en" if lang == "tr" else "tr"
    alt_slug = PAIR[doc["slug"]]
    tr_slug, en_slug = (doc["slug"], alt_slug) if lang == "tr" else (alt_slug, doc["slug"])
    hreflang = (
        '  <link rel="alternate" hreflang="tr" href="%s/%s" />\n'
        '  <link rel="alternate" hreflang="en" href="%s/%s" />\n'
        '  <link rel="alternate" hreflang="x-default" href="%s/%s" />'
        % (BASE, tr_slug, BASE, en_slug, BASE, tr_slug)
    )
    return fill(tpl, dict(
        lang=t["lang"], title=doc["title"], brand=BRAND, description=doc["description"],
        canonical="%s/%s" % (BASE, doc["slug"]), hreflang=hreflang,
        header=header(lang, False, "/kacgunoldu/" + alt_slug), home_path=LANDING[lang]["self_path"],
        badge=doc["title"], h1=doc["h1"], chips=chips, tabs=tabs.rstrip("\n"),
        toc_title=t["toc"], toc=toc.rstrip("\n"), lead=lead,
        sections=sections.rstrip("\n"), footer=footer(lang),
    ))


# ---------------------------------------------------------------- landing page

def stores(t):
    if LC.PLAY_STORE:
        play = (
            '            <a class="store" href="%s" target="_blank" rel="noopener">%s'
            '<span><small>%s</small><strong>%s</strong></span></a>\n'
            % (LC.PLAY_STORE, PLAY_SVG, t["play_small"], t["play_big"])
        )
    else:
        play = (
            '            <span class="store store--soon" aria-disabled="true">%s'
            '<span><small>%s</small><strong>%s</strong></span><span class="badge">%s</span></span>\n'
            % (PLAY_SVG, t["play_small"], t["play_big"], t["soon"])
        )
    if LC.APP_STORE:
        ios = (
            '            <a class="store" href="%s" target="_blank" rel="noopener">%s'
            '<span><small>%s</small><strong>%s</strong></span></a>'
            % (LC.APP_STORE, APPLE_SVG, t["ios_small"], t["ios_big"])
        )
    else:
        ios = (
            '            <span class="store store--soon" aria-disabled="true">%s'
            '<span><small>%s</small><strong>%s</strong></span><span class="badge">%s</span></span>'
            % (APPLE_SVG, t["ios_small"], t["ios_big"], t["soon"])
        )
    return play + ios


def landing(lang, tpl):
    t = LANDING[lang]
    other = "en" if lang == "tr" else "tr"
    canonical = "https://emalabs.info" + t["self_path"]
    hreflang = (
        '  <link rel="alternate" hreflang="tr" href="%s" />\n'
        '  <link rel="alternate" hreflang="en" href="%s/en" />\n'
        '  <link rel="alternate" hreflang="x-default" href="%s" />' % (BASE, BASE, BASE)
    )
    jsonld = json.dumps({
        "@context": "https://schema.org", "@type": "MobileApplication",
        "name": BRAND, "operatingSystem": "Android, iOS", "applicationCategory": "LifestyleApplication",
        "description": t["description"], "url": canonical, "inLanguage": "tr",
        "image": BASE + "/icon.png",
        "offers": {"@type": "Offer", "price": "0", "priceCurrency": "TRY"},
        "publisher": {"@type": "Organization", "name": "EMA Labs", "url": "https://emalabs.info"},
    }, ensure_ascii=False)
    q = "".join('        <span>%s</span>\n' % x for x in t["questions"])
    questions = q + q  # doubled for a seamless loop
    steps = "".join(
        '          <li class="step reveal">\n'
        '            <span class="step-art">%s</span>\n'
        '            <span class="step-num">%d</span>\n'
        '            <h3>%s</h3>\n'
        '            <p>%s</p>\n'
        '          </li>\n' % (icon(STEP_ICONS[i]), i + 1, h, p)
        for i, (h, p) in enumerate(t["steps"])
    )
    legend = "".join(
        '            <li><span class="swatch swatch--%s"></span><span><b>%s</b>%s</span></li>\n' % x
        for x in t["legend"]
    )
    features = "".join(
        '          <article class="feature reveal">\n'
        '            <div class="feature-icon">%s</div>\n'
        '            <h3>%s</h3>\n'
        '            <p>%s</p>\n'
        '          </article>\n' % (icon(k), h, p)
        for k, h, p in t["features"]
    )
    gallery = "".join(
        '        <figure class="shot">\n'
        '          <div class="phone"><img src="/kacgunoldu/img/%s.webp" alt="%s" width="600" height="1200" loading="lazy" /></div>\n'
        '          <figcaption>%s</figcaption>\n'
        '        </figure>\n' % (f, html.escape(c), html.escape(c))
        for f, c in t["gallery"]
    )
    priv = "".join(
        '          <li class="reveal">%s<b>%s</b><span>%s</span></li>\n' % (icon(k), h, p)
        for k, h, p in t["priv_points"]
    )
    faq = "".join(
        '          <details%s>\n'
        '            <summary>%s</summary>\n'
        '            <p>%s</p>\n'
        '          </details>\n' % (" open" if i == 0 else "", h, p)
        for i, (h, p) in enumerate(t["faq"])
    )
    trust = "".join('            <li>%s%s</li>\n' % (icon("check-circle"), x) for x in t["trust"])
    simple = {k: v for k, v in t.items() if isinstance(v, str)}
    return fill(tpl, dict(
        simple,
        canonical=canonical, hreflang=hreflang, jsonld=jsonld,
        header=header(lang, True, t["alt_path"]), footer=footer(lang),
        alt_lang=other, alt_short=other.upper(),
        stores=stores(t), trust=trust.rstrip("\n"), questions=questions.rstrip("\n"),
        steps=steps.rstrip("\n"), legend=legend.rstrip("\n"), features=features.rstrip("\n"),
        gallery=gallery.rstrip("\n"), priv_points=priv.rstrip("\n"), faq=faq.rstrip("\n"),
        slug_privacy=t["slugs"]["privacy"],
        icon_scissors=icon("scissors"), icon_check=icon("check"),
    ))


def screenshots():
    """store/screenshots/raw/*.png -> img/*.webp, without the phone's status and nav bars."""
    src = os.path.join(ROOT, "store", "screenshots", "raw")
    dst = os.path.join(OUT, "img")
    os.makedirs(dst, exist_ok=True)
    for name in sorted(os.listdir(src)):
        if not name.endswith(".png"):
            continue
        im = Image.open(os.path.join(src, name)).convert("RGB")
        w, h = im.size
        top = round(h * 0.046)                  # status bar
        im = im.crop((0, top, w, top + w * 2))  # 1:2, drops the nav bar
        im = im.resize((600, 1200), Image.LANCZOS)
        im.save(os.path.join(dst, name[:-4] + ".webp"), "WEBP", quality=82, method=6)
        print("wrote img/" + name[:-4] + ".webp")


# ---------------------------------------------------------------- Dart

def dart_str(s):
    return "'" + s.replace("\\", "\\\\").replace("'", "\\'").replace("$", "\\$").replace("\n", " ") + "'"


def plain(s):
    """In-app text: links become their label (bold marks stay, the UI renders them)."""
    return re.sub(r"\[([^\]]+)\]\(([^)]+)\)", r"\1", s)


NAMES = {"gizlilik": "privacyPolicy", "kullanim-kosullari": "termsOfUse",
         "privacy": "privacyPolicyEn", "terms": "termsOfUseEn"}


def dart_doc(d):
    name = NAMES.get(d["slug"])
    if not name:
        return ""
    o = ["const %s = LegalDoc(\n  title: %s,\n  updated: %s,\n  lead: %s,\n  sections: [\n"
         % (name, dart_str(d["title"]), dart_str(d["updated"]), dart_str(plain(d["lead"])))]
    for title, blocks in d["sections"]:
        o.append("    LegalSection(%s, [\n" % dart_str(title))
        for k, v in blocks:
            if k == "p":
                o.append("      LegalBlock.p(%s),\n" % dart_str(plain(v)))
            elif k == "callout":
                o.append("      LegalBlock.callout(%s),\n" % dart_str(plain(v)))
            elif k == "ul":
                o.append("      LegalBlock.list([\n%s      ]),\n" % "".join("        %s,\n" % dart_str(plain(i)) for i in v))
            elif k == "contact":
                o.append("      LegalBlock.contact(),\n")
        o.append("    ]),\n")
    o.append("  ],\n);\n\n")
    return "".join(o)


def dart(docs_tr, docs_en):
    """Both languages in one file; the app picks by its interface language."""
    o = ["// GENERATED by store/legal/build.py from store/legal/content.py - do not edit.\n",
         "// ignore_for_file: prefer_single_quotes\n\n",
         "import 'legal_model.dart';\n\n",
         "const legalEmail = %s;\n\n" % dart_str(C.EMAIL)]
    for d in list(docs_tr) + list(docs_en):
        o.append(dart_doc(d))
    return "".join(o)


def write(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)
    print("wrote", path)


def main():
    if DART_ONLY:
        write(os.path.join(ROOT, "lib", "legal", "legal_text.dart"), dart(C.DOCS_TR, C.DOCS_EN))
        return
    tpl = open(os.path.join(HERE, "template.html"), encoding="utf-8").read()
    for lang, docs in (("tr", C.DOCS_TR), ("en", C.DOCS_EN)):
        for d in docs:
            write(os.path.join(OUT, d["slug"], "index.html"), page(d, lang, tpl))
    ltpl = open(os.path.join(HERE, "landing.html"), encoding="utf-8").read()
    write(os.path.join(OUT, "index.html"), landing("tr", ltpl))
    write(os.path.join(OUT, "en", "index.html"), landing("en", ltpl))
    for asset in ("site.css", "site.js"):
        shutil.copyfile(os.path.join(HERE, asset), os.path.join(OUT, asset))
    screenshots()
    shutil.copyfile(os.path.join(ROOT, "store", "graphics", "icon-512.png"), os.path.join(OUT, "icon.png"))
    shutil.copyfile(os.path.join(ROOT, "store", "graphics", "feature-graphic.png"), os.path.join(OUT, "og.png"))
    write(os.path.join(ROOT, "lib", "legal", "legal_text.dart"), dart(C.DOCS_TR, C.DOCS_EN))
    # gezip.app keeps only the privacy pages (their URL is in the Play listing);
    # the rest of /kacgunoldu there redirects to emalabs.info (gezip_app/firebase.json).
    if os.path.isdir(os.path.dirname(LEGACY)):
        shutil.rmtree(LEGACY, ignore_errors=True)
        for sub in ("gizlilik", "privacy"):
            shutil.copytree(os.path.join(OUT, sub), os.path.join(LEGACY, sub))
        for asset in ("site.css", "site.js", "icon.png"):
            shutil.copyfile(os.path.join(OUT, asset), os.path.join(LEGACY, asset))
        print("wrote", LEGACY, "(privacy only)")


main()
