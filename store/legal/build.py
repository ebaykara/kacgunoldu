"""
Builds everything that shows the legal texts from store/legal/content.py:

  * <site>/kacgunoldu/{gizlilik,privacy,kullanim-kosullari,terms,destek,support}/index.html
  * <site>/kacgunoldu/icon.png
  * lib/legal/legal_text.dart  (Turkish, shown in the app)

Usage:  python store/legal/build.py [site_public_dir]
The site dir defaults to C:/Users/eyupb/Desktop/gezip_app/public.
"""
import html
import os
import re
import shutil
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, HERE)
import content as C  # noqa: E402

SITE = sys.argv[1] if len(sys.argv) > 1 else r"C:/Users/eyupb/Desktop/gezip_app/public"
OUT = os.path.join(SITE, "kacgunoldu")
BRAND = "Kaç Gün Oldu?"
BASE = "https://gezip.app/kacgunoldu"

L10N = {
    "tr": dict(
        lang="tr", updated="Son güncelleme", tagline="Bir şeyi en son ne zaman yaptığını takip et. Hesap yok, reklam yok, veri toplanmaz.",
        email="E-posta", web="Web", alt_label="English", home="Ana sayfa",
        names={"privacy": "Gizlilik", "terms": "Koşullar", "support": "Destek"},
        chip_free="Reklamsız · hesapsız",
    ),
    "en": dict(
        lang="en", updated="Last updated", tagline="Track when you last did something. No account, no ads, no data collected.",
        email="Email", web="Web", alt_label="Türkçe", home="Home",
        names={"privacy": "Privacy", "terms": "Terms", "support": "Support"},
        chip_free="No ads · no account",
    ),
}
KIND = {"gizlilik": "privacy", "privacy": "privacy", "kullanim-kosullari": "terms",
        "terms": "terms", "destek": "support", "support": "support"}
PAIR = {"gizlilik": "privacy", "privacy": "gizlilik", "kullanim-kosullari": "terms",
        "terms": "kullanim-kosullari", "destek": "support", "support": "destek"}
SLUG = {"tr": {"privacy": "gizlilik", "terms": "kullanim-kosullari", "support": "destek"},
        "en": {"privacy": "privacy", "terms": "terms", "support": "support"}}


def inline(text):
    t = html.escape(text, quote=False)
    t = re.sub(r"\*\*(.+?)\*\*", r"<strong>\1</strong>", t)
    t = re.sub(r"\[([^\]]+)\]\(([^)]+)\)", lambda m: '<a href="%s">%s</a>' % (m.group(2), m.group(1)), t)
    return t


def block_html(kind, val, t):
    if kind == "p":
        return "        <p>%s</p>\n" % inline(val)
    if kind == "ul":
        return "        <ul>\n%s        </ul>\n" % "".join("          <li>%s</li>\n" % inline(i) for i in val)
    if kind == "callout":
        return '        <div class="callout-box"><div>%s</div></div>\n' % inline(val)
    if kind == "contact":
        return (
            '        <div class="contact-card">\n'
            '          <div class="brand-title">%s · EMA Labs</div>\n'
            '          <div class="row"><span class="label">%s</span><a href="mailto:%s">%s</a></div>\n'
            '          <div class="row"><span class="label">%s</span><a href="https://gezip.app">gezip.app</a></div>\n'
            "        </div>\n" % (BRAND, t["email"], C.EMAIL, C.EMAIL, t["web"])
        )
    raise ValueError(kind)


def page(doc, lang, tpl):
    t = L10N[lang]
    sections = ""
    for i, (title, blocks) in enumerate(doc["sections"], 1):
        body = "".join(block_html(k, v, t) for k, v in blocks)
        sections += (
            '      <section class="doc-card">\n'
            '        <h2><span class="num-pill">%02d</span>%s</h2>\n%s      </section>\n'
            % (i, html.escape(title, quote=False), body)
        )
    lead = '      <div class="lead-box">%s</div>\n' % inline(doc["lead"])
    chips = (
        '        <span class="meta-chip"><span class="meta-dot"></span>%s: %s</span>\n'
        '        <span class="meta-chip">%s</span>' % (t["updated"], doc["updated"], t["chip_free"])
    )
    kind = KIND[doc["slug"]]
    other = "en" if lang == "tr" else "tr"
    alt_slug = PAIR[doc["slug"]]
    hreflang = (
        '  <link rel="alternate" hreflang="%s" href="%s/%s" />\n'
        '  <link rel="alternate" hreflang="%s" href="%s/%s" />'
        % (lang, BASE, doc["slug"], other, BASE, alt_slug)
    )
    links = "".join(
        '          <li><a href="/kacgunoldu/%s">%s</a></li>\n' % (SLUG[lang][k], n)
        for k, n in t["names"].items()
    )
    links += '          <li><a href="https://gezip.app">gezip.app</a></li>'
    vals = dict(
        lang=t["lang"], title=doc["title"], brand=BRAND, description=doc["description"],
        canonical="%s/%s" % (BASE, doc["slug"]), hreflang=hreflang,
        alt_path="/kacgunoldu/" + alt_slug, alt_lang=other, alt_label=L10N[other]["alt_label"],
        badge=doc["badge"], h1=doc["h1"], chips=chips, lead=lead.rstrip("\n"),
        sections=sections.rstrip("\n"), tagline=t["tagline"], footer_links=links.rstrip("\n"),
    )
    out = tpl
    for k, v in vals.items():
        out = out.replace("{{%s}}" % k, v)
    left = re.findall(r"\{\{(\w+)\}\}", out)
    assert not left, left
    return out


def dart_str(s):
    return "'" + s.replace("\\", "\\\\").replace("'", "\\'").replace("$", "\\$").replace("\n", " ") + "'"


def plain(s):
    """In-app text: links become their label (bold marks stay, the UI renders them)."""
    return re.sub(r"\[([^\]]+)\]\(([^)]+)\)", r"\1", s)


def dart(docs):
    o = ["// GENERATED by store/legal/build.py from store/legal/content.py - do not edit.\n",
         "// ignore_for_file: prefer_single_quotes\n\n",
         "import 'legal_model.dart';\n\n",
         "const legalEmail = %s;\n\n" % dart_str(C.EMAIL)]
    names = {"gizlilik": "privacyPolicy", "kullanim-kosullari": "termsOfUse"}
    for d in docs:
        if d["slug"] not in names:
            continue
        o.append("const %s = LegalDoc(\n  title: %s,\n  updated: %s,\n  lead: %s,\n  sections: [\n"
                 % (names[d["slug"]], dart_str(d["title"]), dart_str(d["updated"]), dart_str(plain(d["lead"]))))
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


def main():
    tpl = open(os.path.join(HERE, "template.html"), encoding="utf-8").read()
    for lang, docs in (("tr", C.DOCS_TR), ("en", C.DOCS_EN)):
        for d in docs:
            d_out = os.path.join(OUT, d["slug"])
            os.makedirs(d_out, exist_ok=True)
            with open(os.path.join(d_out, "index.html"), "w", encoding="utf-8", newline="\n") as f:
                f.write(page(d, lang, tpl))
            print("wrote", d_out)
    icon = os.path.join(ROOT, "store", "graphics", "icon-512.png")
    shutil.copyfile(icon, os.path.join(OUT, "icon.png"))
    os.makedirs(os.path.join(ROOT, "lib", "legal"), exist_ok=True)
    with open(os.path.join(ROOT, "lib", "legal", "legal_text.dart"), "w", encoding="utf-8", newline="\n") as f:
        f.write(dart(C.DOCS_TR))
    print("wrote lib/legal/legal_text.dart")


main()
