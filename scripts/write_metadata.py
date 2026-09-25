#!/usr/bin/env python3
"""CalmAnchor App Store listing — source of truth for every locale.

Writes appstore_metadata/<locale>/{name,subtitle,keywords,promotional_text,
description,whats_new}.txt and enforces App Store limits.

Keyword strategy (researched per storefront from App Store search
autocomplete + the top-ranking apps, Sept 2026 — see
appstore_metadata/aso_v1.3.json for the evidence):
  • Every market gets native search terms, never translations of the US list.
  • No word is repeated across a locale's name / subtitle / keywords.
  • Apple indexes secondary locales per storefront: the UK English field is
    also searched in Germany, France and Australia, and US English in Japan.
    So en-GB carries shared English terms ("stress", "journal", "sos",
    "54321") once, and en-AU / de / fr / ja spend their space on terms the
    secondary locale doesn't already cover.
  • Every claim is true of the shipping app (see comments on features).
"""
import os

ROOT = os.path.join(os.path.dirname(__file__), "..", "appstore_metadata")

# ─────────────────────────────── English (US) ───────────────────────────────
EN_US_DESC = (
"Having a panic attack? Tap once.\n\n"
"CalmAnchor opens straight into Panic SOS from a Lock Screen widget: 5-4-3-2-1 grounding, then six slow "
"guided breaths with a live countdown in your Dynamic Island. Rate how intense it feels before and after, "
"and watch it come down.\n\n"
"Then it helps you need it less. Check in on your mood, follow a 30-day plan built around your triggers, "
"and earn your way up the ranks as calm becomes a habit.\n\n"
"PANIC SOS — FREE\n"
"• One tap from your Lock Screen widget into a guided session\n"
"• 5-4-3-2-1 grounding to bring you back to the present\n"
"• Six slow breaths (in 4, hold 4, out 4) with a Dynamic Island countdown\n"
"• Calming affirmations and a before-and-after intensity check\n"
"• A coping library: box breathing, 4-7-8, body scan, thought records and more\n"
"• The 988 Lifeline and Crisis Text Line, one tap away\n\n"
"EARN YOUR CALM RANK — NEW\n"
"• 50 badges to unlock, from First Anchor to secret moments like Night Watch\n"
"• An Anchor Pass that levels up through 20 ranks, from Sea Glass to Pearl\n"
"• Celebrations for streaks, badges and new ranks, with cards you can share\n"
"• Daily quests, plus a grace day so one missed day doesn't erase your streak\n"
"• Your week in calm: a story recap of your sessions, moods and wins\n\n"
"LASTING CALM — PREMIUM\n"
"• A personalized 30-day plan built around your triggers\n"
"• A guided journal with gratitude, affirmations and free writing\n"
"• Mood and anxiety trends over 7 days, 30 days or all time\n\n"
"PRIVATE BY DESIGN\n"
"Your journal, moods and sessions stay on your iPhone. No account, no ads.\n\n"
"CalmAnchor is a self-help and wellness tool, not a substitute for professional medical advice, diagnosis "
"or treatment. If you're in crisis, call or text 988 or your local emergency number."
)

# ───────────────────────────── English (UK / AU) ────────────────────────────
def _en_intl(crisis_line: str) -> str:
    d = (EN_US_DESC
         .replace("personalized", "personalised")
         .replace("canceled", "cancelled")
         .replace("• The 988 Lifeline and Crisis Text Line, one tap away\n", "")
         .replace("If you're in crisis, call or text 988 or your local emergency number.", crisis_line))
    return d

EN_GB_DESC = _en_intl("If you're in crisis, call Samaritans free on 116 123 or dial 999 in an emergency.")
EN_AU_DESC = _en_intl("If you're in crisis, call Lifeline on 13 11 14 (24/7) or dial 000 in an emergency.")

# ───────────────────────────────── German ───────────────────────────────────
DE_DESC = (
"Panikattacke? Einmal tippen genügt.\n\n"
"CalmAnchor öffnet Panik-SOS direkt über ein Widget auf dem Sperrbildschirm: 5-4-3-2-1-Erdung, dann sechs "
"ruhige, geführte Atemzüge mit Live-Countdown in der Dynamic Island. Bewerte vorher und nachher, wie stark "
"es ist – und sieh zu, wie es nachlässt.\n\n"
"Danach hilft dir CalmAnchor, es seltener zu brauchen: kurze Stimmungs-Check-ins, ein 30-Tage-Plan rund um "
"deine Auslöser und Ränge, die mit dir wachsen.\n\n"
"PANIK-SOS – KOSTENLOS\n"
"• Mit einem Tippen vom Sperrbildschirm-Widget in eine geführte Sitzung\n"
"• 5-4-3-2-1-Erdung, die dich ins Hier und Jetzt zurückholt\n"
"• Sechs ruhige Atemzüge (4 ein, 4 halten, 4 aus) mit Countdown in der Dynamic Island\n"
"• Beruhigende Affirmationen und ein Vorher-nachher-Check, wie stark die Angst ist\n"
"• Eine Bibliothek mit Übungen: Box-Atmung, 4-7-8-Atmung, Body-Scan, Gedankenprotokoll und mehr\n\n"
"ERREICHE DEINEN RUHE-RANG – NEU\n"
"• 50 Abzeichen – von „Erster Anker“ bis zu geheimen Momenten wie „Nachtwache“\n"
"• Ein Anchor Pass mit 20 Rängen – von Meerglas bis Perle\n"
"• Feiern für Serien, Abzeichen und neue Ränge, mit Karten zum Teilen\n"
"• Tägliche Quests und ein Schontag, damit ein verpasster Tag deine Serie nicht beendet\n"
"• „Deine Woche in Ruhe“: deine Sitzungen, Stimmungen und Erfolge als Story\n\n"
"DAUERHAFTE RUHE – PREMIUM\n"
"• Ein persönlicher 30-Tage-Plan, abgestimmt auf deine Auslöser\n"
"• Ein geführtes Tagebuch mit Dankbarkeit, Affirmationen und freiem Schreiben\n"
"• Stimmungs- und Angstverläufe über 7 Tage, 30 Tage oder insgesamt\n\n"
"PRIVAT VON ANFANG AN\n"
"Dein Tagebuch, deine Stimmungen und Sitzungen bleiben auf deinem iPhone. Kein Konto, keine Werbung.\n\n"
"CalmAnchor ist ein Selbsthilfe- und Wellness-Tool und ersetzt keine ärztliche Beratung, Diagnose oder "
"Behandlung. In einer Krise erreichst du die TelefonSeelsorge kostenlos und rund um die Uhr unter "
"0800 111 0 111 oder 0800 111 0 222. Im Notfall wähle die 112."
)

# ───────────────────────────────── French ───────────────────────────────────
FR_DESC = (
"Crise d’angoisse ? Un seul geste.\n\n"
"CalmAnchor ouvre directement le SOS panique depuis un widget de l’écran verrouillé : ancrage 5-4-3-2-1, "
"puis six respirations lentes et guidées, avec un compte à rebours en direct dans la Dynamic Island. "
"Évaluez l’intensité avant et après, et regardez-la redescendre.\n\n"
"Ensuite, CalmAnchor vous aide à en avoir moins besoin : des bilans d’humeur rapides, un plan de 30 jours "
"construit autour de vos déclencheurs et des rangs qui progressent avec vous.\n\n"
"SOS PANIQUE – GRATUIT\n"
"• D’un geste, passez du widget de l’écran verrouillé à une séance guidée\n"
"• L’ancrage 5-4-3-2-1 pour revenir à l’instant présent\n"
"• Six respirations lentes (inspirez 4, retenez 4, expirez 4) avec compte à rebours dans la Dynamic Island\n"
"• Des affirmations apaisantes et une évaluation de l’intensité avant et après\n"
"• Une bibliothèque d’exercices : respiration carrée, respiration 4-7-8, scan corporel, registre des pensées et plus encore\n\n"
"MONTEZ EN RANG – NOUVEAU\n"
"• 50 badges à débloquer, de « Première ancre » à des moments secrets comme « Veille de nuit »\n"
"• Un Anchor Pass qui évolue sur 20 rangs, du Verre de mer à la Perle\n"
"• Des célébrations pour les séries, les badges et les nouveaux rangs, avec des cartes à partager\n"
"• Des quêtes quotidiennes et un jour de grâce, pour qu’un jour manqué n’efface pas votre série\n"
"• « Votre semaine de calme » : vos séances, humeurs et victoires en story\n\n"
"UN CALME DURABLE – PREMIUM\n"
"• Un plan personnalisé de 30 jours, adapté à vos déclencheurs\n"
"• Un journal guidé avec gratitude, affirmations et écriture libre\n"
"• L’évolution de votre humeur et de votre anxiété sur 7 jours, 30 jours ou depuis le début\n\n"
"PRIVÉ PAR NATURE\n"
"Votre journal, vos humeurs et vos séances restent sur votre iPhone. Sans compte, sans publicité.\n\n"
"CalmAnchor est un outil de bien-être ; il ne remplace pas l’avis, le diagnostic ou le traitement d’un "
"professionnel de santé. En cas de détresse, appelez le 3114 (gratuit, 24 h/24, 7 j/7) ou, en cas d’urgence, le 15 ou le 112."
)

# ──────────────────────────────── Japanese ──────────────────────────────────
JA_DESC = (
"パニック発作が起きたら、ワンタップで。\n\n"
"CalmAnchorは、ロック画面のウィジェットからすぐに「パニックSOS」を開けます。5-4-3-2-1グラウンディングで"
"今ここに意識を戻し、Dynamic Islandのカウントダウンに合わせて、ゆっくり6回の呼吸をガイドします。"
"前後で不安の強さを記録するので、波が引いていくのを実感できます。\n\n"
"そして、SOSに頼らなくてもいい毎日へ。気分のチェックイン、あなたのトリガーに合わせた30日間プラン、"
"続けるほど上がっていくランクが、穏やかさを習慣にしてくれます。\n\n"
"パニックSOS（無料）\n"
"・ロック画面のウィジェットから、ワンタップでガイド付きセッションへ\n"
"・5-4-3-2-1グラウンディングで、今この瞬間に戻る\n"
"・ゆっくり6回の呼吸（4秒吸って、4秒止めて、4秒吐く）とDynamic Islandのカウントダウン\n"
"・心を落ち着けるアファメーションと、セッション前後の不安の強さチェック\n"
"・対処法ライブラリ：ボックス呼吸、4-7-8呼吸、ボディスキャン、思考記録など\n\n"
"穏やかランクを目指そう（新機能）\n"
"・「はじめての錨」から「夜の見張り」のようなシークレットまで、50個のバッジ\n"
"・シーグラスからパールまで、20段階で成長するアンカーパス\n"
"・連続記録、バッジ、ランクアップをお祝い。シェアできるカードつき\n"
"・毎日のクエストと、1日休んでも連続記録を守る「お休みの日」\n"
"・「あなたの穏やかな1週間」：セッション、気分、達成をストーリーで振り返り\n\n"
"穏やかさを、ずっと（プレミアム）\n"
"・あなたのトリガーに合わせた、パーソナライズされた30日間プラン\n"
"・感謝、アファメーション、自由記述のガイド付きジャーナル\n"
"・7日間、30日間、全期間の気分と不安の推移\n\n"
"プライバシーを第一に\n"
"ジャーナル、気分、セッションの記録はiPhoneの中だけに保存されます。アカウント不要、広告なし。\n\n"
"CalmAnchorはセルフケアとウェルネスのためのツールであり、医師による助言・診断・治療の代わりにはなりません。"
"つらいときは、いのちの電話（0570-783-556／フリーダイヤル 0120-783-556）や、24時間無料のよりそいホットライン（0120-279-338）に相談してください。命に関わる緊急時は119番へ。"
)

# ─────────────────────────────── Subscription terms (3.1.2) ────────────────
TERMS = {
"en": ("\n\nSUBSCRIPTION & LEGAL\n"
       "CalmAnchor offers auto-renewable subscriptions (weekly, monthly, yearly) and an optional one-time Lifetime purchase. "
       "Subscriptions auto-renew unless canceled at least 24 hours before the end of the current period; manage or cancel in your Apple Account settings.\n"
       "Terms of Use (EULA): https://gwlabs.app/terms\n"
       "Privacy Policy: https://gwlabs.app/privacy"),
"de": ("\n\nABO & RECHTLICHES\n"
       "CalmAnchor bietet automatisch verlängerbare Abos (wöchentlich, monatlich, jährlich) und einen optionalen einmaligen Lifetime-Kauf. "
       "Abos verlängern sich automatisch, sofern nicht mindestens 24 Stunden vor Ende des laufenden Zeitraums gekündigt wird; verwalte oder kündige sie in den Einstellungen deines Apple Accounts.\n"
       "Nutzungsbedingungen (EULA): https://gwlabs.app/terms\n"
       "Datenschutzrichtlinie: https://gwlabs.app/privacy"),
"fr": ("\n\nABONNEMENT & MENTIONS LÉGALES\n"
       "CalmAnchor propose des abonnements à renouvellement automatique (hebdomadaire, mensuel, annuel) et un achat unique « à vie » (Lifetime) facultatif. "
       "Les abonnements se renouvellent automatiquement sauf résiliation au moins 24 heures avant la fin de la période en cours ; gérez-les ou résiliez-les dans les réglages de votre compte Apple.\n"
       "Conditions d’utilisation (CLUF) : https://gwlabs.app/terms\n"
       "Politique de confidentialité : https://gwlabs.app/privacy"),
"ja": ("\n\nサブスクリプションと規約\n"
       "CalmAnchorは自動更新サブスクリプション（週額・月額・年額）と、任意の買い切りプラン（Lifetime）を提供します。"
       "サブスクリプションは、現在の期間終了の少なくとも24時間前に解約しない限り自動更新されます。管理・解約はApple Accountの設定から行えます。\n"
       "利用規約（EULA）：https://gwlabs.app/terms\n"
       "プライバシーポリシー：https://gwlabs.app/privacy"),
}

# ─────────────────────────────── Per-locale fields ─────────────────────────
LOCALES = {
 "en-US": dict(
    name="CalmAnchor: Panic Attack Help",
    subtitle="Anxiety Relief & Box Breathing",
    keywords="grounding,54321,sos,calm,down,breathe,nervous,system,reset,vagus,coping,skills,mood,tracker,worry",
    promo="Panic attack? One tap from your Lock Screen into grounding and guided breathing. New: 50 badges, 20 calm ranks and your week in calm.",
    whats_new="New: earn your calm rank.\n• 50 badges and an Anchor Pass with 20 ranks, from Sea Glass to Pearl\n• Celebrations for streaks, badges and new ranks, with cards to share\n• Your week in calm: a story recap of your sessions and moods\n• Smoother mood and anxiety charts, plus fixes",
    desc=EN_US_DESC + TERMS["en"]),
 "en-GB": dict(
    name="CalmAnchor: Panic Attack Help",
    subtitle="Anxiety Relief & Grounding",
    keywords="diary,tracker,worry,54321,sos,calm,breathing,box,mood,stress,coping,wellbeing,mindfulness,journal",
    promo="Panic attack? One tap from your Lock Screen into grounding and guided breathing. New: 50 badges, 20 calm ranks and your week in calm.",
    whats_new="New: earn your calm rank.\n• 50 badges and an Anchor Pass with 20 ranks, from Sea Glass to Pearl\n• Celebrations for streaks, badges and new ranks, with cards to share\n• Your week in calm: a story recap of your sessions and moods\n• Smoother mood and anxiety charts, plus fixes",
    desc=EN_GB_DESC + TERMS["en"].replace("canceled", "cancelled")),
 "en-AU": dict(
    name="CalmAnchor: Panic Attack Help",
    subtitle="Calm Anxiety, Breathe Easy",
    keywords="relief,exercises,nervous,system,reset,vagus,overthinking,agoraphobia,disorder,anxious,relax,skills",
    promo="Panic attack? One tap from your Lock Screen into grounding and guided breathing. New: 50 badges, 20 calm ranks and your week in calm.",
    whats_new="New: earn your calm rank.\n• 50 badges and an Anchor Pass with 20 ranks, from Sea Glass to Pearl\n• Celebrations for streaks, badges and new ranks, with cards to share\n• Your week in calm: a story recap of your sessions and moods\n• Smoother mood and anxiety charts, plus fixes",
    desc=EN_AU_DESC + TERMS["en"].replace("canceled", "cancelled")),
 "de-DE": dict(
    name="CalmAnchor: Panik & Angst SOS",
    subtitle="Atemübungen bei Panikattacken",
    keywords="panikattacke,angststörung,atmen,atemtechnik,beruhigen,erdung,stimmungstagebuch,herzrasen,entspannung",
    promo="Panikattacke? Mit einem Tippen vom Sperrbildschirm zu Erdung und geführter Atmung. Neu: 50 Abzeichen, 20 Ränge und „Deine Woche in Ruhe“.",
    whats_new="Neu: Erreiche deinen Ruhe-Rang.\n• 50 Abzeichen und ein Anchor Pass mit 20 Rängen, von Meerglas bis Perle\n• Feiern für Serien, Abzeichen und neue Ränge, mit Karten zum Teilen\n• Deine Woche in Ruhe: deine Sitzungen und Stimmungen als Story\n• Übersichtlichere Stimmungs- und Angstdiagramme sowie Fehlerbehebungen",
    desc=DE_DESC + TERMS["de"]),
 "fr-FR": dict(
    name="CalmAnchor : Anxiété & Panique",
    subtitle="Respiration & crise d'angoisse",
    keywords="aide,ancrage,calme,calmer,apaiser,respirer,antistress,humeur,relaxation,tcc,inquiétude,peur,attaque",
    promo="Crise d’angoisse ? D’un geste, passez de l’écran verrouillé à l’ancrage et à la respiration guidée. Nouveau : 50 badges, 20 rangs et « Votre semaine de calme ».",
    whats_new="Nouveau : montez en rang.\n• 50 badges et un Anchor Pass de 20 rangs, du Verre de mer à la Perle\n• Des célébrations pour les séries, badges et nouveaux rangs, avec des cartes à partager\n• Votre semaine de calme : vos séances et humeurs en story\n• Des courbes d’humeur et d’anxiété plus lisibles, et des corrections",
    desc=FR_DESC + TERMS["fr"]),
 "ja": dict(
    name="CalmAnchor：パニック発作・不安の対処法",
    subtitle="深呼吸と呼吸法で、心を落ち着かせる",
    keywords="パニック障害,不安障害,過呼吸,動悸,自律神経,マインドフルネス,瞑想,ストレス解消,気分記録,緊張,日記,心のケア,メンタルケア,セルフケア,リラックス,認知行動療法,ボックス呼吸,心配",
    promo="パニック発作に、ロック画面からワンタップ。グラウンディングとガイド付き呼吸へ。新機能：50個のバッジ、20段階のランク、「あなたの穏やかな1週間」。",
    whats_new="新機能：穏やかランクを目指そう。\n・50個のバッジと、シーグラスからパールまで20段階のアンカーパス\n・連続記録、バッジ、ランクアップのお祝いとシェア用カード\n・「あなたの穏やかな1週間」をストーリーで振り返り\n・気分と不安のグラフを見やすく改善、不具合の修正",
    desc=JA_DESC + TERMS["ja"]),
}

def frtypo(t: str) -> str:
    """French typography: U+202F before ? ! ; and U+00A0 before : and inside « »,
    so punctuation never wraps onto its own line. URLs are left alone."""
    import re
    t = re.sub(r" ([?!;])", "\u202f\\1", t)
    t = re.sub(r" :(?!//)", "\u00a0:", t)
    return t.replace("« ", "«\u00a0").replace(" »", "\u00a0»")

for _f in ("promo", "whats_new", "desc"):
    LOCALES["fr-FR"][_f] = frtypo(LOCALES["fr-FR"][_f])

LIMITS = {"name": 30, "subtitle": 30, "keywords": 100, "promo": 170, "whats_new": 4000, "desc": 4000}


def main():
    print(f"{'locale':7} {'name':>4} {'sub':>4} {'kw':>4} {'promo':>5} {'new':>4} {'desc':>5}")
    bad = False
    for loc, f in LOCALES.items():
        d = os.path.join(ROOT, loc)
        os.makedirs(d, exist_ok=True)
        files = {"name.txt": f["name"], "subtitle.txt": f["subtitle"], "keywords.txt": f["keywords"],
                 "promotional_text.txt": f["promo"], "description.txt": f["desc"], "whats_new.txt": f["whats_new"]}
        for fn, val in files.items():
            open(os.path.join(d, fn), "w", encoding="utf-8").write(val)
        warn = [f"{k}={len(f[k])}>{lim}" for k, lim in LIMITS.items() if len(f[k]) > lim]
        bad |= bool(warn)
        print(f"{loc:7} {len(f['name']):>4} {len(f['subtitle']):>4} {len(f['keywords']):>4} "
              f"{len(f['promo']):>5} {len(f['whats_new']):>4} {len(f['desc']):>5}  {' '.join('!' + w for w in warn)}")
    if bad:
        raise SystemExit("limit exceeded")


if __name__ == "__main__":
    main()
