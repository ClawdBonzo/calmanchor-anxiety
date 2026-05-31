#!/usr/bin/env python3
"""Write localized App Store metadata into appstore_metadata/<locale>/*.txt
(fastlane-deliver layout, ready for ASC API push)."""
import os
ROOT = os.path.join(os.path.dirname(__file__), "..", "appstore_metadata")

EN_DESC = (
"When anxiety strikes, you need more than advice — you need a plan. CalmAnchor gives you "
"immediate, practical tools to manage anxiety and build lasting calm, one breath at a time.\n\n"
"Whether you're navigating a panic moment right now or working toward long-term recovery, "
"CalmAnchor meets you where you are with evidence-based techniques and a personalized healing journey.\n\n"
"FEATURES\n"
"• Panic SOS — instant breathing and 5-4-3-2-1 grounding when you need it most\n"
"• Personalized 30-day healing plan tailored to your triggers\n"
"• Daily journal with guided prompts, gratitude, and affirmations\n"
"• Mood & anxiety analytics to reveal your patterns over time\n"
"• Healing streaks to keep you motivated\n\n"
"PRIVATE BY DESIGN\n"
"All your data stays on your device. No account, no cloud, no tracking.\n\n"
"CalmAnchor is your anchor in the storm. Download it free and find your calm today."
)

EN_DESC_GB = EN_DESC.replace("personalized", "personalised")

DESC = {
"de-DE":
"Wenn die Angst zuschlägt, brauchst du mehr als Ratschläge – du brauchst einen Plan. CalmAnchor "
"gibt dir sofort wirksame, praktische Werkzeuge, um Angst zu bewältigen und dauerhafte Ruhe "
"aufzubauen, Atemzug für Atemzug.\n\n"
"Ob du gerade einen Panikmoment durchlebst oder auf langfristige Genesung hinarbeitest – CalmAnchor "
"holt dich dort ab, wo du stehst, mit evidenzbasierten Techniken und einem persönlichen Heilungsweg.\n\n"
"FUNKTIONEN\n"
"• Panik-SOS – sofortige Atemübungen und 5-4-3-2-1-Erdung, wenn du sie am meisten brauchst\n"
"• Persönlicher 30-Tage-Heilungsplan, abgestimmt auf deine Auslöser\n"
"• Tägliches Tagebuch mit geführten Impulsen, Dankbarkeit und Affirmationen\n"
"• Stimmungs- und Angstanalysen, die deine Muster sichtbar machen\n"
"• Heilungs-Serien, die dich motivieren\n\n"
"PRIVAT VON GRUND AUF\n"
"Alle deine Daten bleiben auf deinem Gerät. Kein Konto, keine Cloud, kein Tracking.\n\n"
"CalmAnchor ist dein Anker im Sturm. Lade die App kostenlos und finde noch heute deine Ruhe.",
"fr-FR":
"Quand l'anxiété surgit, il vous faut plus que des conseils — il vous faut un plan. CalmAnchor vous "
"offre des outils concrets et immédiats pour gérer l'anxiété et bâtir un calme durable, une respiration à la fois.\n\n"
"Que vous traversiez une crise de panique en ce moment ou que vous travailliez vers un rétablissement "
"durable, CalmAnchor vous accompagne là où vous en êtes, avec des techniques fondées sur des preuves et "
"un parcours de guérison personnalisé.\n\n"
"FONCTIONNALITÉS\n"
"• SOS panique — respiration guidée et ancrage 5-4-3-2-1 quand vous en avez le plus besoin\n"
"• Plan de guérison personnalisé sur 30 jours, adapté à vos déclencheurs\n"
"• Journal quotidien avec invites guidées, gratitude et affirmations\n"
"• Analyses de l'humeur et de l'anxiété pour révéler vos tendances\n"
"• Séries de guérison pour rester motivé\n\n"
"PRIVÉ PAR CONCEPTION\n"
"Toutes vos données restent sur votre appareil. Aucun compte, aucun cloud, aucun suivi.\n\n"
"CalmAnchor est votre ancre dans la tempête. Téléchargez-la gratuitement et trouvez votre calme dès aujourd'hui.",
"ja":
"不安が押し寄せたとき、必要なのはアドバイス以上のもの——「計画」です。CalmAnchor は、ひと呼吸ずつ"
"不安に対処し、続く落ち着きを育てるための、実践的なツールをすぐに届けます。\n\n"
"今まさにパニックの只中にいても、長期的な回復を目指していても、CalmAnchor はエビデンスに基づく"
"テクニックと、あなただけのヒーリングの歩みで、今のあなたに寄り添います。\n\n"
"主な機能\n"
"• パニックSOS — 必要なときにすぐ使える呼吸ガイドと5-4-3-2-1グラウンディング\n"
"• あなたのトリガーに合わせた、30日間のパーソナルなヒーリングプラン\n"
"• ガイド付きの問いかけ・感謝・アファメーションが書けるデイリージャーナル\n"
"• 気分と不安のパターンを可視化する分析機能\n"
"• モチベーションを保つヒーリングの連続記録\n\n"
"プライバシー第一の設計\n"
"すべてのデータは端末内に保存されます。アカウント不要、クラウド不要、トラッキングなし。\n\n"
"CalmAnchor は、嵐の中のあなたの錨です。無料でダウンロードして、今日、あなたの落ち着きを見つけましょう。",
}

PROMO = {
"en-US": "Your personal anchor when anxiety hits. Guided breathing, panic SOS tools, mood tracking, and a 30-day healing plan — all private, all on your device.",
"de-DE": "Dein persönlicher Anker, wenn die Angst zuschlägt. Geführte Atmung, Panik-SOS, Stimmungstracking und ein 30-Tage-Heilungsplan – alles privat, alles auf deinem Gerät.",
"fr-FR": "Votre ancre quand l'anxiété surgit. Respiration guidée, SOS panique, suivi de l'humeur et plan de guérison de 30 jours — privé, sur votre appareil.",
"ja": "不安が押し寄せたときの、あなただけの錨。ガイド付き呼吸、パニックSOS、気分記録、30日間のヒーリングプラン——すべてプライベートに、すべて端末内で。",
}

NAME = {
"en-US": "CalmAnchor: Anxiety Journal",
"de-DE": "CalmAnchor: Angst-Tagebuch",
"fr-FR": "CalmAnchor : Journal anxiété",
"ja": "CalmAnchor 不安ジャーナル",
}

SUBTITLE = {
"en-US": "Mood Tracker & Panic SOS",
"de-DE": "Stimmungstracker & Panik-SOS",
"fr-FR": "Suivi d'humeur & SOS panique",
"ja": "気分記録＆パニックSOS",
}

KEYWORDS = {
"en-US": "calm,breathing,grounding,meditation,relief,healing,streak,mindfulness,CBT,coping,stress,worry,mental",
"de-DE": "ruhe,atmung,angst,panik,meditation,achtsamkeit,stress,bewältigung,tagebuch,stimmung,entspannung",
"fr-FR": "calme,respiration,anxiété,panique,méditation,pleine conscience,stress,humeur,journal,relaxation",
"ja": "不安,パニック,呼吸,瞑想,マインドフルネス,ストレス,気分,記録,リラックス,グラウンディング,メンタル,落ち着き",
}

# locale -> field values
LOCALES = {
 "en-US": dict(name=NAME["en-US"], subtitle=SUBTITLE["en-US"], keywords=KEYWORDS["en-US"], promo=PROMO["en-US"], desc=EN_DESC),
 "en-GB": dict(name=NAME["en-US"], subtitle=SUBTITLE["en-US"], keywords=KEYWORDS["en-US"], promo=PROMO["en-US"].replace("personalized","personalised"), desc=EN_DESC_GB),
 "en-AU": dict(name=NAME["en-US"], subtitle=SUBTITLE["en-US"], keywords=KEYWORDS["en-US"], promo=PROMO["en-US"].replace("personalized","personalised"), desc=EN_DESC_GB),
 "de-DE": dict(name=NAME["de-DE"], subtitle=SUBTITLE["de-DE"], keywords=KEYWORDS["de-DE"], promo=PROMO["de-DE"], desc=DESC["de-DE"]),
 "fr-FR": dict(name=NAME["fr-FR"], subtitle=SUBTITLE["fr-FR"], keywords=KEYWORDS["fr-FR"], promo=PROMO["fr-FR"], desc=DESC["fr-FR"]),
 "ja":    dict(name=NAME["ja"],    subtitle=SUBTITLE["ja"],    keywords=KEYWORDS["ja"],    promo=PROMO["ja"],    desc=DESC["ja"]),
}

LIMITS = {"name": 30, "subtitle": 30, "keywords": 100, "promo": 170, "desc": 4000}

def main():
    print(f"{'locale':8} {'name':4} {'sub':4} {'kw':4} {'promo':6}")
    for loc, f in LOCALES.items():
        d = os.path.join(ROOT, loc)
        os.makedirs(d, exist_ok=True)
        files = {"name.txt": f["name"], "subtitle.txt": f["subtitle"],
                 "keywords.txt": f["keywords"], "promotional_text.txt": f["promo"],
                 "description.txt": f["desc"]}
        warn = ""
        for fn, val in files.items():
            open(os.path.join(d, fn), "w").write(val)
        # length checks
        for k, lim in [("name", LIMITS["name"]), ("subtitle", LIMITS["subtitle"]),
                       ("keywords", LIMITS["keywords"]), ("promo", LIMITS["promo"])]:
            v = f[{"name":"name","subtitle":"subtitle","keywords":"keywords","promo":"promo"}[k]]
            if len(v) > lim:
                warn += f" !{k}={len(v)}>{lim}"
        print(f"{loc:8} {len(f['name']):<4} {len(f['subtitle']):<4} {len(f['keywords']):<4} {len(f['promo']):<6}{warn}")

if __name__ == "__main__":
    main()
