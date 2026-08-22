#!/usr/bin/env python3
"""Write localized App Store metadata into appstore_metadata/<locale>/*.txt
(fastlane-deliver layout, ready for ASC API push)."""
import os
ROOT = os.path.join(os.path.dirname(__file__), "..", "appstore_metadata")

EN_DESC = (
"Having a panic attack? Tap once. CalmAnchor puts guided box breathing and 5-4-3-2-1 grounding "
"right on your Lock Screen — no unlocking, no searching, no waiting. Relief starts in seconds.\n\n"
"Then it helps you need it less. Track your mood, follow a 30-day plan built around YOUR triggers, "
"and watch your anxiety patterns change over time.\n\n"
"PANIC SOS\n"
"• One-tap Lock Screen widget — breathing help before you even unlock your phone\n"
"• Guided box breathing with a live countdown in your Dynamic Island\n"
"• 5-4-3-2-1 grounding to pull you back into the present\n"
"• Calming affirmations, then a gentle check-in on how you feel\n\n"
"LASTING CALM\n"
"• Personalized 30-day healing plan tailored to your triggers\n"
"• Daily mood & anxiety tracking with clear trend charts\n"
"• Guided journal with prompts, gratitude, and affirmations\n"
"• Streaks, daily quests, and milestones that keep you coming back\n\n"
"PRIVATE BY DESIGN\n"
"Your journal, mood, and personal entries never leave your device. No account, no ads, no third-party tracking.\n\n"
"CalmAnchor is your anchor in the storm. Download it free — your next panic attack doesn't have to win."
)

EN_DESC_GB = EN_DESC.replace("personalized", "personalised")

DESC = {
"de-DE":
"Panikattacke? Ein Tipp genügt. CalmAnchor bringt geführte Box-Atmung und 5-4-3-2-1-Erdung direkt auf "
"deinen Sperrbildschirm – kein Entsperren, kein Suchen, kein Warten. Erleichterung in Sekunden.\n\n"
"Und danach hilft es dir, sie seltener zu brauchen. Verfolge deine Stimmung, folge einem 30-Tage-Plan rund um "
"DEINE Auslöser und sieh zu, wie sich deine Angstmuster mit der Zeit verändern.\n\n"
"PANIK-SOS\n"
"• Ein-Tipp-Widget auf dem Sperrbildschirm – Atemhilfe, bevor du dein Handy überhaupt entsperrst\n"
"• Geführte Box-Atmung mit Live-Countdown in der Dynamic Island\n"
"• 5-4-3-2-1-Erdung, die dich zurück in die Gegenwart holt\n"
"• Beruhigende Affirmationen und ein sanfter Check-in, wie es dir geht\n\n"
"DAUERHAFTE RUHE\n"
"• Persönlicher 30-Tage-Heilungsplan, abgestimmt auf deine Auslöser\n"
"• Tägliches Stimmungs- und Angst-Tracking mit klaren Trend-Diagrammen\n"
"• Geführtes Tagebuch mit Impulsen, Dankbarkeit und Affirmationen\n"
"• Serien, tägliche Quests und Meilensteine, die dich dranbleiben lassen\n\n"
"PRIVAT VON GRUND AUF\n"
"Dein Tagebuch, deine Stimmung und deine persönlichen Einträge verlassen nie dein Gerät. Kein Konto, keine Werbung, kein Tracking durch Dritte.\n\n"
"CalmAnchor ist dein Anker im Sturm. Lade die App kostenlos – deine nächste Panikattacke muss nicht gewinnen.",
"fr-FR":
"Crise de panique ? Un seul geste. CalmAnchor place la respiration carrée guidée et l'ancrage 5-4-3-2-1 "
"directement sur votre écran verrouillé — sans déverrouiller, sans chercher, sans attendre. Le soulagement commence en quelques secondes.\n\n"
"Puis il vous aide à en avoir moins besoin. Suivez votre humeur, suivez un plan de 30 jours construit autour de "
"VOS déclencheurs et observez vos schémas d'anxiété évoluer.\n\n"
"SOS PANIQUE\n"
"• Widget d'écran verrouillé en un geste — de l'aide respiratoire avant même de déverrouiller votre téléphone\n"
"• Respiration carrée guidée avec compte à rebours en direct dans la Dynamic Island\n"
"• Ancrage 5-4-3-2-1 pour vous ramener dans le présent\n"
"• Affirmations apaisantes, puis un doux bilan de comment vous vous sentez\n\n"
"UN CALME DURABLE\n"
"• Plan de guérison personnalisé sur 30 jours, adapté à vos déclencheurs\n"
"• Suivi quotidien de l'humeur et de l'anxiété avec des graphiques de tendance clairs\n"
"• Journal guidé avec invites, gratitude et affirmations\n"
"• Séries, quêtes quotidiennes et jalons qui vous donnent envie de revenir\n\n"
"PRIVÉ PAR CONCEPTION\n"
"Votre journal, votre humeur et vos entrées personnelles ne quittent jamais votre appareil. Aucun compte, aucune publicité, aucun suivi tiers.\n\n"
"CalmAnchor est votre ancre dans la tempête. Téléchargez-la gratuitement — votre prochaine crise de panique n'a pas à gagner.",
"ja":
"パニック発作？ワンタップで大丈夫。CalmAnchor は、ガイド付きボックス呼吸と5-4-3-2-1グラウンディングを"
"ロック画面に直接配置——ロック解除も、探すことも、待つことも不要。数秒で楽になり始めます。\n\n"
"そして、必要になる回数そのものを減らしていきます。気分を記録し、あなたのトリガーに合わせた30日間プランに取り組み、"
"不安のパターンが時間とともに変わっていくのを実感してください。\n\n"
"パニックSOS\n"
"• ワンタップのロック画面ウィジェット — 端末のロックを解除する前に呼吸サポートを\n"
"• Dynamic Island にライブカウントダウン付きのガイド付きボックス呼吸\n"
"• 今この瞬間に引き戻す5-4-3-2-1グラウンディング\n"
"• 心を落ち着けるアファメーションと、やさしい気分チェック\n\n"
"続く落ち着き\n"
"• あなたのトリガーに合わせた、30日間のパーソナルなヒーリングプラン\n"
"• わかりやすいトレンドグラフ付きの、毎日の気分・不安記録\n"
"• 問いかけ・感謝・アファメーション付きのガイド付きジャーナル\n"
"• 続けたくなる連続記録、デイリークエスト、マイルストーン\n\n"
"プライバシー第一の設計\n"
"あなたのジャーナル・気分・個人的な記録が端末の外に出ることはありません。アカウント不要、広告なし、第三者トラッキングなし。\n\n"
"CalmAnchor は、嵐の中のあなたの錨です。無料でダウンロード——次のパニック発作に負ける必要はありません。",
}

PROMO = {
"en-US": "Panic attack? One tap from your Lock Screen to guided breathing. Then a 30-day plan built around your triggers. Private, on-device, no account.",
"de-DE": "Panikattacke? Ein Tipp vom Sperrbildschirm zur geführten Atmung. Dann ein 30-Tage-Plan rund um deine Auslöser. Privat, auf dem Gerät, kein Konto.",
"fr-FR": "Crise de panique ? Un geste depuis l'écran verrouillé vers la respiration guidée. Puis un plan de 30 jours autour de vos déclencheurs. Privé, sur l'appareil.",
"ja": "パニック発作？ロック画面からワンタップでガイド付き呼吸へ。その後はトリガーに合わせた30日間プラン。プライベート、端末内、アカウント不要。",
}

NAME = {
"en-US": "CalmAnchor: Panic Attack Help",
"de-DE": "CalmAnchor: Hilfe bei Panik",
"fr-FR": "CalmAnchor : Aide Panique",
"ja": "CalmAnchor パニック対処",
}

SUBTITLE = {
"en-US": "SOS Breathing & Grounding",
"de-DE": "SOS-Atmung & Erdung",
"fr-FR": "SOS Respiration & Ancrage",
"ja": "SOS呼吸＆グラウンディング",
}

KEYWORDS = {
"en-US": "anxiety,relief,calm,attack,stop,5-4-3-2-1,box,breathe,journal,mood,tracker,stress,coping,cbt,worry",
"de-DE": "angst,panikattacke,ruhe,beruhigen,atemübung,5-4-3-2-1,tagebuch,stimmung,stress,bewältigung,sorgen",
"fr-FR": "anxiété,crise,angoisse,calme,apaiser,respiration,5-4-3-2-1,journal,humeur,stress,gérer,inquiétude",
"ja": "不安,パニック発作,落ち着く,呼吸法,5-4-3-2-1,ジャーナル,気分,記録,ストレス,対処,心配,メンタル",
}

# Auto-renewable-subscription compliance footer (Guideline 3.1.2) appended to each description.
TERMS = {
"en": ("\n\nSUBSCRIPTION & LEGAL\n"
       "CalmAnchor offers auto-renewable subscriptions (weekly, monthly, yearly) and an optional one-time Lifetime purchase. "
       "Subscriptions auto-renew unless canceled at least 24 hours before the end of the current period; manage or cancel in your Apple Account settings.\n"
       "Terms of Use (EULA): https://gwlabs.app/terms\n"
       "Privacy Policy: https://gwlabs.app/privacy"),
"de": ("\n\nABO & RECHTLICHES\n"
       "CalmAnchor bietet automatisch verlängerbare Abos (wöchentlich, monatlich, jährlich) und einen optionalen einmaligen Lifetime-Kauf. "
       "Abos verlängern sich automatisch, sofern nicht mindestens 24 Stunden vor Ende des laufenden Zeitraums gekündigt wird; verwalte oder kündige in deinen Apple-Account-Einstellungen.\n"
       "Nutzungsbedingungen (EULA): https://gwlabs.app/terms\n"
       "Datenschutzrichtlinie: https://gwlabs.app/privacy"),
"fr": ("\n\nABONNEMENT & MENTIONS LÉGALES\n"
       "CalmAnchor propose des abonnements à renouvellement automatique (hebdomadaire, mensuel, annuel) et un achat unique Lifetime facultatif. "
       "Les abonnements se renouvellent automatiquement sauf annulation au moins 24 heures avant la fin de la période en cours ; gérez ou annulez dans les réglages de votre compte Apple.\n"
       "Conditions d'utilisation (CLUF) : https://gwlabs.app/terms\n"
       "Politique de confidentialité : https://gwlabs.app/privacy"),
"ja": ("\n\nサブスクリプションと規約\n"
       "CalmAnchor は自動更新サブスクリプション（週額・月額・年額）と、任意の買い切りLifetimeを提供します。"
       "サブスクリプションは、現在の期間終了の少なくとも24時間前に解約しない限り自動更新されます。管理・解約はApple Accountの設定から行えます。\n"
       "利用規約（EULA）: https://gwlabs.app/terms\n"
       "プライバシーポリシー: https://gwlabs.app/privacy"),
}

# locale -> field values
LOCALES = {
 "en-US": dict(name=NAME["en-US"], subtitle=SUBTITLE["en-US"], keywords=KEYWORDS["en-US"], promo=PROMO["en-US"], desc=EN_DESC + TERMS["en"]),
 "en-GB": dict(name=NAME["en-US"], subtitle=SUBTITLE["en-US"], keywords=KEYWORDS["en-US"], promo=PROMO["en-US"].replace("personalized","personalised"), desc=EN_DESC_GB + TERMS["en"]),
 "en-AU": dict(name=NAME["en-US"], subtitle=SUBTITLE["en-US"], keywords=KEYWORDS["en-US"], promo=PROMO["en-US"].replace("personalized","personalised"), desc=EN_DESC_GB + TERMS["en"]),
 "de-DE": dict(name=NAME["de-DE"], subtitle=SUBTITLE["de-DE"], keywords=KEYWORDS["de-DE"], promo=PROMO["de-DE"], desc=DESC["de-DE"] + TERMS["de"]),
 "fr-FR": dict(name=NAME["fr-FR"], subtitle=SUBTITLE["fr-FR"], keywords=KEYWORDS["fr-FR"], promo=PROMO["fr-FR"], desc=DESC["fr-FR"] + TERMS["fr"]),
 "ja":    dict(name=NAME["ja"],    subtitle=SUBTITLE["ja"],    keywords=KEYWORDS["ja"],    promo=PROMO["ja"],    desc=DESC["ja"] + TERMS["ja"]),
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
