#!/usr/bin/env python3
"""Merge de/fr/ja translations into CalmAnchor/Localizable.xcstrings.
Format specifiers (%@, %lld, %1$@ ...) are preserved exactly.
Strings not in the map are left source-only (fall back to English).
"""
import json, os

CAT = os.path.join(os.path.dirname(__file__), "..", "CalmAnchor", "Localizable.xcstrings")

# key (English source) -> (de, fr, ja)
T = {
 "5-4-3-2-1 Grounding": ("5-4-3-2-1-Erdung", "Ancrage 5-4-3-2-1", "5-4-3-2-1 グラウンディング"),
 "About": ("Über", "À propos", "アプリについて"),
 "Affirmation: %@": ("Affirmation: %@", "Affirmation : %@", "アファメーション：%@"),
 "After": ("Nachher", "Après", "後"),
 "All data stored locally on device": ("Alle Daten werden lokal auf dem Gerät gespeichert", "Toutes les données sont stockées localement sur l’appareil", "すべてのデータは端末内にローカル保存されます"),
 "Anchor yourself in the present": ("Verankere dich im Hier und Jetzt", "Ancrez-vous dans le présent", "今この瞬間に意識を向けましょう"),
 "anchored in the storm": ("verankert im Sturm", "ancré dans la tempête", "嵐の中でも揺るがない"),
 "Anxiety": ("Angst", "Anxiété", "不安"),
 "Anxiety level after session": ("Angstniveau nach der Sitzung", "Niveau d’anxiété après la séance", "セッション後の不安レベル"),
 "Anxiety Level: %lld/10": ("Angstniveau: %lld/10", "Niveau d’anxiété : %lld/10", "不安レベル：%lld/10"),
 "Anxiety Levels": ("Angstniveaus", "Niveaux d’anxiété", "不安レベル"),
 "Anxiety recovery, one breath at a time.": ("Angstbewältigung – Atemzug für Atemzug.", "Surmonter l’anxiété, une respiration à la fois.", "ひと呼吸ずつ、不安からの回復を。"),
 "Anxiety: %lld/10": ("Angst: %lld/10", "Anxiété : %lld/10", "不安：%lld/10"),
 "Anxious": ("Ängstlich", "Anxieux", "不安"),
 "Before": ("Vorher", "Avant", "前"),
 "Begin Your Calm Journey": ("Beginne deine Reise zur Ruhe", "Commencez votre parcours vers le calme", "穏やかさへの旅を始めましょう"),
 "Breath %lld of 6": ("Atemzug %lld von 6", "Respiration %lld sur 6", "%lld 回目／全6回"),
 "Breathing instruction: %@": ("Atemanweisung: %@", "Consigne de respiration : %@", "呼吸ガイド：%@"),
 "Cancel": ("Abbrechen", "Annuler", "キャンセル"),
 "Close": ("Schließen", "Fermer", "閉じる"),
 "Close & Return": ("Schließen & zurück", "Fermer et revenir", "閉じて戻る"),
 "Close panic support": ("Panik-Hilfe schließen", "Fermer l’aide en cas de panique", "パニックサポートを閉じる"),
 "Continue": ("Weiter", "Continuer", "続ける"),
 "Continue (%lld selected)": ("Weiter (%lld ausgewählt)", "Continuer (%lld sélectionné·s)", "続ける（%lld 件選択中）"),
 "Continue as %@": ("Weiter als %@", "Continuer en tant que %@", "%@ として続ける"),
 "Continue as Friend": ("Als Freund:in fortfahren", "Continuer en tant qu’ami", "フレンドとして続ける"),
 "Coping Techniques Library": ("Bibliothek der Bewältigungstechniken", "Bibliothèque de techniques d’adaptation", "対処法ライブラリ"),
 "Coping techniques used today:": ("Heute genutzte Bewältigungstechniken:", "Techniques d’adaptation utilisées aujourd’hui :", "今日使った対処法："),
 "Crafting your personalized\nPeace Plan%@…": ("Dein persönlicher\nFriedensplan%@ wird erstellt …", "Création de votre\nplan de sérénité personnalisé%@…", "あなた専用の\nピースプラン%@ を作成中…"),
 "Crisis Hotline: 988": ("Telefonseelsorge: 0800 111 0 111", "Ligne d’écoute : 3114", "いのちの電話：0570-783-556"),
 "Daily Journal": ("Tägliches Tagebuch", "Journal quotidien", "デイリージャーナル"),
 "Daily Minutes": ("Tägliche Minuten", "Minutes par jour", "1日の時間（分）"),
 "Daily Reflection": ("Tägliche Reflexion", "Réflexion quotidienne", "今日のふり返り"),
 "Data & Privacy": ("Daten & Datenschutz", "Données et confidentialité", "データとプライバシー"),
 "Date": ("Datum", "Date", "日付"),
 "Day %lld streak": ("%lld Tage in Folge", "Série de %lld jours", "%lld 日連続"),
 "Done": ("Fertig", "Terminé", "完了"),
 "Even 5 minutes daily can transform your anxiety": ("Schon 5 Minuten täglich können deine Angst verändern", "Même 5 minutes par jour peuvent transformer votre anxiété", "1日5分でも不安は変えられます"),
 "Free": ("Kostenlos", "Gratuit", "無料"),
 "Full Calm": ("Völlige Ruhe", "Calme total", "完全な落ち着き"),
 "Glowing anchor": ("Leuchtender Anker", "Ancre lumineuse", "輝く錨"),
 "Golden anchor — you made it through": ("Goldener Anker – du hast es geschafft", "Ancre d’or – vous avez tenu bon", "金の錨 — あなたは乗り越えました"),
 "Healing Plan": ("Heilungsplan", "Plan de guérison", "ヒーリングプラン"),
 "Healing Streaks": ("Heilungs-Serien", "Séries de guérison", "ヒーリングの連続記録"),
 "Hey, %@": ("Hallo, %@", "Bonjour, %@", "%@ さん、こんにちは"),
 "Home": ("Start", "Accueil", "ホーム"),
 "How are you feeling\nright now?": ("Wie fühlst du dich\ngerade jetzt?", "Comment vous sentez-vous\nen ce moment ?", "今、どんな気分ですか？"),
 "How intense is your anxiety now?": ("Wie stark ist deine Angst gerade?", "Quelle est l’intensité de votre anxiété maintenant ?", "今の不安はどのくらい強いですか？"),
 "How many minutes\nper day for healing?": ("Wie viele Minuten\npro Tag für deine Heilung?", "Combien de minutes\npar jour pour guérir ?", "1日に何分、\n回復に使いますか？"),
 "I Stayed Calm Today": ("Ich bin heute ruhig geblieben", "Je suis resté calme aujourd’hui", "今日は落ち着いていられた"),
 "I Stayed Calm Today — share your progress": ("Ich bin heute ruhig geblieben – teile deinen Fortschritt", "Je suis resté calme aujourd’hui – partagez vos progrès", "今日は落ち着いていられた — 進捗をシェア"),
 "I'm grateful for...": ("Ich bin dankbar für …", "Je suis reconnaissant·e pour…", "感謝していること…"),
 "Insights": ("Einblicke", "Analyses", "インサイト"),
 "Inspire others to find their anchor": ("Inspiriere andere, ihren Anker zu finden", "Inspirez les autres à trouver leur ancre", "他の人が自分の錨を見つける後押しに"),
 "Instant calm when you need it most": ("Sofortige Ruhe, wenn du sie am meisten brauchst", "Le calme instantané quand vous en avez le plus besoin", "必要なときにすぐ落ち着きを"),
 "Journal": ("Tagebuch", "Journal", "ジャーナル"),
 "Journaling Impact": ("Wirkung des Tagebuchschreibens", "Impact du journal", "ジャーナルの効果"),
 "Level %lld of 10": ("Level %lld von 10", "Niveau %lld sur 10", "レベル %lld／10"),
 "Log": ("Eintragen", "Noter", "記録"),
 "Log Mood": ("Stimmung eintragen", "Noter l’humeur", "気分を記録"),
 "Member since %@": ("Mitglied seit %@", "Membre depuis %@", "%@ から利用"),
 "Mood": ("Stimmung", "Humeur", "気分"),
 "Mood After Journaling: %lld/10": ("Stimmung nach dem Tagebuch: %lld/10", "Humeur après le journal : %lld/10", "ジャーナル後の気分：%lld/10"),
 "Mood Before Journaling: %lld/10": ("Stimmung vor dem Tagebuch: %lld/10", "Humeur avant le journal : %lld/10", "ジャーナル前の気分：%lld/10"),
 "Mood declined": ("Stimmung verschlechtert", "Humeur en baisse", "気分が下がった"),
 "Mood improved": ("Stimmung verbessert", "Humeur en hausse", "気分が上がった"),
 "Mood Trend": ("Stimmungsverlauf", "Tendance de l’humeur", "気分の推移"),
 "Mood: %lld/10": ("Stimmung: %lld/10", "Humeur : %lld/10", "気分：%lld/10"),
 "Next Affirmation": ("Nächste Affirmation", "Affirmation suivante", "次のアファメーション"),
 "No mood logged yet.\nTap Log to check in.": ("Noch keine Stimmung eingetragen.\nTippe auf „Eintragen“.", "Aucune humeur notée.\nAppuyez sur « Noter ».", "まだ記録がありません。\n「記録」をタップ。"),
 "No panic events recorded. You're doing great!": ("Keine Panikepisoden aufgezeichnet. Du machst das großartig!", "Aucune crise de panique enregistrée. Bravo !", "パニックの記録はありません。順調です！"),
 "No tasks today — enjoy a rest day!": ("Heute keine Aufgaben – genieße deinen Ruhetag!", "Aucune tâche aujourd’hui – profitez d’une journée de repos !", "今日のタスクはありません。休息日を楽しんで！"),
 "Notice %lld %@": ("Bemerke %lld %@", "Remarquez %lld %@", "%lld 個の%@に気づく"),
 "Panic Events": ("Panikepisoden", "Crises de panique", "パニックの記録"),
 "Peaceful": ("Friedlich", "Serein", "穏やか"),
 "Plan": ("Plan", "Plan", "プラン"),
 "Premium": ("Premium", "Premium", "プレミアム"),
 "Privacy": ("Datenschutz", "Confidentialité", "プライバシー"),
 "Privacy Policy": ("Datenschutzrichtlinie", "Politique de confidentialité", "プライバシーポリシー"),
 "Progress": ("Fortschritt", "Progrès", "進捗"),
 "Quick Mood Check": ("Schnelle Stimmungsabfrage", "Vérification rapide de l’humeur", "クイック気分チェック"),
 "Quick note (optional)...": ("Kurze Notiz (optional) …", "Note rapide (facultatif)…", "メモ（任意）…"),
 "Rate CalmAnchor": ("CalmAnchor bewerten", "Noter CalmAnchor", "CalmAnchor を評価"),
 "Reset": ("Zurücksetzen", "Réinitialiser", "リセット"),
 "Reset All Data": ("Alle Daten zurücksetzen", "Réinitialiser toutes les données", "すべてのデータをリセット"),
 "Reset All Data?": ("Alle Daten zurücksetzen?", "Réinitialiser toutes les données ?", "すべてのデータをリセットしますか？"),
 "Resources": ("Ressourcen", "Ressources", "リソース"),
 "Rest day - no tasks scheduled.": ("Ruhetag – keine Aufgaben geplant.", "Jour de repos – aucune tâche prévue.", "休息日 — 予定されたタスクはありません。"),
 "Restore Purchase": ("Kauf wiederherstellen", "Restaurer l’achat", "購入を復元"),
 "Restore Purchases": ("Käufe wiederherstellen", "Restaurer les achats", "購入を復元"),
 "Save": ("Speichern", "Enregistrer", "保存"),
 "Search techniques...": ("Techniken suchen …", "Rechercher des techniques…", "テクニックを検索…"),
 "See Your Plan": ("Deinen Plan ansehen", "Voir votre plan", "プランを見る"),
 "Select all that apply — we'll personalize your plan": ("Wähle alles Zutreffende – wir personalisieren deinen Plan", "Sélectionnez tout ce qui s’applique – nous personnaliserons votre plan", "当てはまるものを選択 — プランを最適化します"),
 "Settings": ("Einstellungen", "Réglages", "設定"),
 "Share your anchor with others": ("Teile deinen Anker mit anderen", "Partagez votre ancre avec les autres", "あなたの錨を他の人とシェア"),
 "Share Your Calm": ("Teile deine Ruhe", "Partagez votre calme", "あなたの落ち着きをシェア"),
 "Share your calm moment with others": ("Teile deinen ruhigen Moment mit anderen", "Partagez votre moment de calme avec les autres", "穏やかな瞬間を他の人とシェア"),
 "Show next affirmation": ("Nächste Affirmation anzeigen", "Afficher l’affirmation suivante", "次のアファメーションを表示"),
 "Shuffle Affirmation": ("Affirmation mischen", "Mélanger les affirmations", "アファメーションをシャッフル"),
 "Skip": ("Überspringen", "Passer", "スキップ"),
 "SOS Panic Button": ("SOS-Panikknopf", "Bouton panique SOS", "SOS パニックボタン"),
 "SOS Panic Button — open breathing and grounding support": ("SOS-Panikknopf – Atem- und Erdungshilfe öffnen", "Bouton panique SOS – ouvrir l’aide à la respiration et à l’ancrage", "SOS パニックボタン — 呼吸とグラウンディングの支援を開く"),
 "Start writing to track your healing journey": ("Schreibe los, um deine Heilungsreise festzuhalten", "Commencez à écrire pour suivre votre parcours de guérison", "書き始めて、回復の歩みを記録しましょう"),
 "Step %lld of 4": ("Schritt %lld von 4", "Étape %lld sur 4", "ステップ %lld／4"),
 "Streaks": ("Serien", "Séries", "連続記録"),
 "Subscription": ("Abonnement", "Abonnement", "サブスクリプション"),
 "Terms": ("Bedingungen", "Conditions", "利用規約"),
 "Terms of Service": ("Nutzungsbedingungen", "Conditions d’utilisation", "利用規約"),
 "This is the version of you we're building toward": ("Das ist die Version von dir, auf die wir hinarbeiten", "C’est la version de vous vers laquelle nous avançons", "これが、目指すあなたの姿です"),
 "This will delete all your journal entries, mood logs, and progress. This cannot be undone.": ("Dadurch werden alle deine Tagebucheinträge, Stimmungsprotokolle und Fortschritte gelöscht. Dies kann nicht rückgängig gemacht werden.", "Cela supprimera toutes vos entrées de journal, vos relevés d’humeur et vos progrès. Cette action est irréversible.", "すべてのジャーナル、気分の記録、進捗が削除されます。この操作は取り消せません。"),
 "Three things I'm grateful for:": ("Drei Dinge, für die ich dankbar bin:", "Trois choses pour lesquelles je suis reconnaissant·e :", "感謝していること3つ："),
 "Time Range": ("Zeitraum", "Période", "期間"),
 "Today's Affirmation": ("Affirmation des Tages", "Affirmation du jour", "今日のアファメーション"),
 "Today's Healing Plan": ("Heilungsplan für heute", "Plan de guérison du jour", "今日のヒーリングプラン"),
 "Today's Mood": ("Stimmung heute", "Humeur du jour", "今日の気分"),
 "Triggers": ("Auslöser", "Déclencheurs", "トリガー"),
 "Unlock with Premium": ("Mit Premium freischalten", "Débloquer avec Premium", "プレミアムでアンロック"),
 "Unlock Your": ("Schalte dein", "Débloquez votre", "アンロック"),
 "Upgrade to Premium": ("Auf Premium upgraden", "Passer à Premium", "プレミアムにアップグレード"),
 "Version": ("Version", "Version", "バージョン"),
 "We'll use this as your starting point": ("Das verwenden wir als deinen Ausgangspunkt", "Nous l’utiliserons comme point de départ", "これを出発点にします"),
 "What should we call\nyour calmest self?": ("Wie sollen wir dein\nruhigstes Selbst nennen?", "Comment appeler\nvotre moi le plus serein ?", "あなたの最も穏やかな\n自分を何と呼びますか？"),
 "What triggers\nyour anxiety?": ("Was löst\ndeine Angst aus?", "Qu’est-ce qui déclenche\nvotre anxiété ?", "何があなたの不安を\n引き起こしますか？"),
 "Write First Entry": ("Ersten Eintrag schreiben", "Écrire la première entrée", "最初のエントリーを書く"),
 "Write in Journal": ("Ins Tagebuch schreiben", "Écrire dans le journal", "ジャーナルに書く"),
 "You did it!": ("Du hast es geschafft!", "Vous avez réussi !", "やり遂げました！"),
 "You navigated through the storm.\nEvery time you use these tools, you grow stronger.": ("Du hast den Sturm überstanden.\nMit jedem Einsatz dieser Werkzeuge wirst du stärker.", "Vous avez traversé la tempête.\nChaque fois que vous utilisez ces outils, vous devenez plus fort.", "あなたは嵐を乗り越えました。\nこれらのツールを使うたびに、強くなれます。"),
 "Your anchor in the storm": ("Dein Anker im Sturm", "Votre ancre dans la tempête", "嵐の中のあなたの錨"),
 "Your journal awaits": ("Dein Tagebuch wartet", "Votre journal vous attend", "ジャーナルが待っています"),
 "Your name…": ("Dein Name …", "Votre nom…", "お名前…"),
 "%lld min": ("%lld Min", "%lld min", "%lld 分"),
 "%lld minutes": ("%lld Minuten", "%lld minutes", "%lld 分"),
 "%lld selected": ("%lld ausgewählt", "%lld sélectionné·s", "%lld 件選択中"),
 "%lld out of 10": ("%lld von 10", "%lld sur 10", "%lld／10"),
 "Lv %lld": ("Lv %lld", "Niv %lld", "Lv %lld"),
 "%lld min · %@": None,  # positional, handled below
 "%@ plan, %@%@%@%@": None,
}

# positional-format strings (preserve %1$ ordering exactly)
POS = {
 "%lld min · %@": ("%1$lld Min · %2$@", "%1$lld min · %2$@", "%1$lld 分 · %2$@"),
 "%@ plan, %@%@%@%@": ("%1$@-Plan, %2$@%3$@%4$@%5$@", "Plan %1$@, %2$@%3$@%4$@%5$@", "%1$@プラン、%2$@%3$@%4$@%5$@"),
}

LANGS = ("de", "fr", "ja")

def unit(val):
    return {"stringUnit": {"state": "translated", "value": val}}

def main():
    cat = json.load(open(CAT))
    strings = cat["strings"]
    count = 0
    merged = {**{k: v for k, v in T.items() if v}, **POS}
    for key, vals in merged.items():
        if key not in strings:
            continue
        entry = strings[key]
        loc = entry.setdefault("localizations", {})
        for lang, val in zip(LANGS, vals):
            loc[lang] = unit(val)
        count += 1
    json.dump(cat, open(CAT, "w"), ensure_ascii=False, indent=2)
    print(f"merged translations into {count} strings x {len(LANGS)} languages")
    # report any source strings left untranslated (excluding intentional skips)
    skip = {"", "·", "\"%@\"", "%lld", "%lld/10", "%lld%%", "%lld.", "1.0.0", "CalmAnchor"}
    missing = [k for k in strings if k not in merged and k not in skip and any(c.isalpha() for c in k)]
    if missing:
        print(f"\n{len(missing)} strings left source-only (fall back to English):")
        for m in missing:
            print("  -", m)

if __name__ == "__main__":
    main()
