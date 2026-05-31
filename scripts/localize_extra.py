#!/usr/bin/env python3
"""Add catalog entries (with en source + de/fr/ja) for strings that aren't
auto-extracted: stat labels, greetings, time-of-day, reflection prompts."""
import json, os
CAT = os.path.join(os.path.dirname(__file__), "..", "CalmAnchor", "Localizable.xcstrings")

# en -> (de, fr, ja)
NEW = {
 # greetings
 "Good morning": ("Guten Morgen", "Bonjour", "おはようございます"),
 "Good afternoon": ("Guten Tag", "Bon après-midi", "こんにちは"),
 "Good evening": ("Guten Abend", "Bonsoir", "こんばんは"),
 "Good night": ("Gute Nacht", "Bonne nuit", "おやすみなさい"),
 # time of day (mood.timeOfDay.capitalized)
 "Morning": ("Morgen", "Matin", "朝"),
 "Afternoon": ("Nachmittag", "Après-midi", "昼"),
 "Evening": ("Abend", "Soir", "夜"),
 "Night": ("Nacht", "Nuit", "深夜"),
 # stat labels
 "Best": ("Rekord", "Record", "最高"),
 "Current": ("Aktuell", "Actuel", "現在"),
 "Total": ("Gesamt", "Total", "合計"),
 "Streak": ("Serie", "Série", "連続"),
 "Sessions": ("Sitzungen", "Séances", "セッション"),
 "Journals": ("Einträge", "Entrées", "記録数"),
 "Events": ("Ereignisse", "Épisodes", "回数"),
 "Avg Before": ("Ø vorher", "Moy. avant", "平均（前）"),
 "Avg After": ("Ø nachher", "Moy. après", "平均（後）"),
 "Avg Time": ("Ø Dauer", "Durée moy.", "平均時間"),
 "Breathing Exercises": ("Atemübungen", "Exercices de respiration", "呼吸エクササイズ"),
 "30-Day Peace Plan": ("30-Tage-Friedensplan", "Plan de sérénité 30 jours", "30日間ピースプラン"),
 "Trigger Analysis": ("Auslöser-Analyse", "Analyse des déclencheurs", "トリガー分析"),
 # reflection / journal prompts
 "What made you feel safe today?": ("Was hat dir heute Sicherheit gegeben?", "Qu’est-ce qui vous a fait sentir en sécurité aujourd’hui ?", "今日、安心できたのはどんなことですか？"),
 "Describe a moment of calm you experienced recently.": ("Beschreibe einen ruhigen Moment, den du kürzlich erlebt hast.", "Décrivez un moment de calme que vous avez vécu récemment.", "最近感じた穏やかな瞬間を書いてみましょう。"),
 "What are three things you're grateful for right now?": ("Wofür bist du gerade dankbar? Nenne drei Dinge.", "Quelles sont trois choses pour lesquelles vous êtes reconnaissant·e en ce moment ?", "今、感謝していること3つは何ですか？"),
 "Write about a fear that turned out okay.": ("Schreibe über eine Angst, die sich als unbegründet erwies.", "Écrivez à propos d’une peur qui s’est bien terminée.", "結果的に大丈夫だった恐れについて書きましょう。"),
 "What would you tell a friend feeling anxious?": ("Was würdest du einer ängstlichen Freundin oder einem Freund sagen?", "Que diriez-vous à un ami qui se sent anxieux ?", "不安な友人に、あなたなら何と声をかけますか？"),
 "Describe your ideal peaceful place.": ("Beschreibe deinen idealen Ort der Ruhe.", "Décrivez votre lieu de paix idéal.", "あなたにとって理想の安らぎの場所を描写しましょう。"),
 "What coping skill helped you most this week?": ("Welche Bewältigungstechnik hat dir diese Woche am meisten geholfen?", "Quelle technique d’adaptation vous a le plus aidé cette semaine ?", "今週、最も役立った対処法は何ですか？"),
 "Write a letter of compassion to yourself.": ("Schreibe dir selbst einen mitfühlenden Brief.", "Écrivez-vous une lettre de bienveillance.", "自分自身へ、思いやりの手紙を書きましょう。"),
 "What boundary would help your peace of mind?": ("Welche Grenze würde deinem Seelenfrieden helfen?", "Quelle limite aiderait votre tranquillité d’esprit ?", "心の平穏のために、どんな境界線が役立ちますか？"),
 "List five things you can see, hear, and feel right now.": ("Nenne fünf Dinge, die du gerade sehen, hören und fühlen kannst.", "Citez cinq choses que vous pouvez voir, entendre et ressentir maintenant.", "今、見える・聞こえる・感じるものを5つ挙げましょう。"),
 "What progress have you noticed in your healing?": ("Welchen Fortschritt hast du bei deiner Heilung bemerkt?", "Quels progrès avez-vous remarqués dans votre guérison ?", "回復の中で、どんな進歩に気づきましたか？"),
 "Describe a time you felt truly at peace.": ("Beschreibe einen Moment, in dem du wirklich Frieden empfunden hast.", "Décrivez un moment où vous vous êtes senti·e vraiment en paix.", "心から安らいだ時のことを書きましょう。"),
 "What small win can you celebrate today?": ("Welchen kleinen Erfolg kannst du heute feiern?", "Quelle petite victoire pouvez-vous célébrer aujourd’hui ?", "今日、祝える小さな勝利は何ですか？"),
 "How has your relationship with anxiety changed?": ("Wie hat sich dein Verhältnis zur Angst verändert?", "Comment votre relation avec l’anxiété a-t-elle changé ?", "不安との関係はどう変わりましたか？"),
 "What does 'calm' look like in your daily life?": ("Wie sieht „Ruhe“ in deinem Alltag aus?", "À quoi ressemble le « calme » dans votre quotidien ?", "あなたの日常で「穏やかさ」とはどんな様子ですか？"),
}
LANGS = ("de", "fr", "ja")

def u(v):
    return {"stringUnit": {"state": "translated", "value": v}}

cat = json.load(open(CAT))
s = cat["strings"]
n = 0
for en, vals in NEW.items():
    entry = s.setdefault(en, {})
    loc = entry.setdefault("localizations", {})
    loc.setdefault("en", u(en))
    for lang, v in zip(LANGS, vals):
        loc[lang] = u(v)
    n += 1
# keep keys sorted for clean diff
cat["strings"] = dict(sorted(s.items()))
json.dump(cat, open(CAT, "w"), ensure_ascii=False, indent=2)
print(f"added/updated {n} strings x {len(LANGS)} langs; total now {len(s)}")
