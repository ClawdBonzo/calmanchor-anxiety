#!/usr/bin/env python3
"""Add catalog entries (en source + de/fr/ja) for the in-app DATA layer:
triggers, affirmations, healing-plan tasks, panic senses, breath labels,
resource categories, technique titles/descriptions/steps, and per-country
localized crisis resources.

NOTE: clinical instructions and especially CRISIS CONTACTS are AI-translated
and country-localized to best knowledge — they MUST be verified by a native
speaker / clinician before release."""
import json, os
CAT = os.path.join(os.path.dirname(__file__), "..", "CalmAnchor", "Localizable.xcstrings")
LANGS = ("de", "fr", "ja")

D = {
 # ---- triggers ----
 "Work Stress": ("Stress bei der Arbeit", "Stress au travail", "仕事のストレス"),
 "Social Situations": ("Soziale Situationen", "Situations sociales", "社交的な場面"),
 "Health Worries": ("Gesundheitssorgen", "Inquiétudes de santé", "健康の不安"),
 "Financial Concerns": ("Finanzielle Sorgen", "Soucis financiers", "お金の心配"),
 "Relationship Issues": ("Beziehungsprobleme", "Problèmes relationnels", "人間関係の悩み"),
 "Sleep Problems": ("Schlafprobleme", "Troubles du sommeil", "睡眠の問題"),
 "Uncertainty": ("Ungewissheit", "Incertitude", "不確実さ"),
 "Perfectionism": ("Perfektionismus", "Perfectionnisme", "完璧主義"),
 "Crowds / Spaces": ("Menschenmengen / Räume", "Foules / Espaces", "人混み・空間"),
 "Loneliness": ("Einsamkeit", "Solitude", "孤独"),
 # ---- affirmations ----
 "I am safe in this moment.": ("Ich bin in diesem Moment sicher.", "Je suis en sécurité en cet instant.", "私は今、安全です。"),
 "This feeling is temporary and will pass.": ("Dieses Gefühl ist vorübergehend und wird vergehen.", "Ce sentiment est passager et s'en ira.", "この感覚は一時的で、必ず過ぎ去ります。"),
 "I have survived every difficult moment so far.": ("Ich habe bisher jeden schwierigen Moment überstanden.", "J'ai surmonté chaque moment difficile jusqu'ici.", "私はこれまで、つらい瞬間をすべて乗り越えてきました。"),
 "I am stronger than my anxiety.": ("Ich bin stärker als meine Angst.", "Je suis plus fort que mon anxiété.", "私は不安よりも強い。"),
 "I choose peace over worry.": ("Ich wähle Frieden statt Sorge.", "Je choisis la paix plutôt que l'inquiétude.", "私は心配ではなく、平穏を選びます。"),
 "My breath is my anchor.": ("Mein Atem ist mein Anker.", "Ma respiration est mon ancre.", "呼吸が私の錨です。"),
 "I release what I cannot control.": ("Ich lasse los, was ich nicht kontrollieren kann.", "Je lâche prise sur ce que je ne peux pas contrôler.", "コントロールできないことは手放します。"),
 "I am worthy of calm and peace.": ("Ich verdiene Ruhe und Frieden.", "Je mérite le calme et la paix.", "私は穏やかさと平和に値します。"),
 "Each breath brings me closer to calm.": ("Jeder Atemzug bringt mich der Ruhe näher.", "Chaque respiration me rapproche du calme.", "ひと呼吸ごとに、落ち着きへ近づきます。"),
 "I trust myself to handle what comes.": ("Ich vertraue darauf, mit dem umzugehen, was kommt.", "Je me fais confiance pour gérer ce qui vient.", "これから起こることに対処できると信じています。"),
 "I am not my anxious thoughts.": ("Ich bin nicht meine ängstlichen Gedanken.", "Je ne suis pas mes pensées anxieuses.", "私は、不安な考えそのものではありません。"),
 "This moment is all I need to focus on.": ("Dieser Moment ist alles, worauf ich mich konzentrieren muss.", "Cet instant est tout ce sur quoi je dois me concentrer.", "今この瞬間にだけ集中すればよいのです。"),
 "I give myself permission to feel and heal.": ("Ich erlaube mir zu fühlen und zu heilen.", "Je m'autorise à ressentir et à guérir.", "感じ、癒えることを自分に許します。"),
 "My courage is greater than my fear.": ("Mein Mut ist größer als meine Angst.", "Mon courage est plus grand que ma peur.", "私の勇気は、恐れよりも大きい。"),
 "I am building resilience with every breath.": ("Mit jedem Atemzug baue ich Widerstandskraft auf.", "Je développe ma résilience à chaque respiration.", "ひと呼吸ごとに、回復する力を育てています。"),
 "Peace flows through me like a gentle stream.": ("Frieden fließt durch mich wie ein sanfter Bach.", "La paix coule en moi comme un doux ruisseau.", "穏やかさが、優しいせせらぎのように私を満たします。"),
 "I am anchored in the present moment.": ("Ich bin im gegenwärtigen Moment verankert.", "Je suis ancré dans le moment présent.", "私は今この瞬間に錨を下ろしています。"),
 "My anxiety does not define me.": ("Meine Angst definiert mich nicht.", "Mon anxiété ne me définit pas.", "不安が私を決めるのではありません。"),
 "I welcome calm into my body and mind.": ("Ich heiße Ruhe in Körper und Geist willkommen.", "J'accueille le calme dans mon corps et mon esprit.", "心と体に、落ち着きを迎え入れます。"),
 "I am learning to befriend my nervous system.": ("Ich lerne, mich mit meinem Nervensystem anzufreunden.", "J'apprends à apprivoiser mon système nerveux.", "自分の神経系と仲良くなることを学んでいます。"),
 # ---- healing tasks (title) ----
 "Morning Breathing": ("Morgendliche Atmung", "Respiration du matin", "朝の呼吸"),
 "Gratitude Check-in": ("Dankbarkeits-Check", "Point gratitude", "感謝のチェックイン"),
 "Body Scan": ("Body-Scan", "Scan corporel", "ボディスキャン"),
 "Gentle Stretching": ("Sanftes Dehnen", "Étirements doux", "やさしいストレッチ"),
 "Evening Reflection": ("Abendliche Reflexion", "Réflexion du soir", "夜のふり返り"),
 "Mindful Walk": ("Achtsamer Spaziergang", "Marche en pleine conscience", "マインドフルな散歩"),
 "Thought Record": ("Gedankenprotokoll", "Relevé de pensées", "思考記録"),
 "Progressive Relaxation": ("Progressive Entspannung", "Relaxation progressive", "漸進的リラクゼーション"),
 "Anchor Breathing": ("Anker-Atmung", "Respiration d'ancrage", "アンカー呼吸"),
 "Trigger Mapping": ("Auslöser kartieren", "Cartographie des déclencheurs", "トリガーの整理"),
 "Loving-Kindness": ("Liebende Güte", "Bienveillance", "慈悲の瞑想"),
 "Cold Exposure": ("Kältereiz", "Exposition au froid", "冷たさへの刺激"),
 "Visualization": ("Visualisierung", "Visualisation", "イメージ法"),
 "Movement Break": ("Bewegungspause", "Pause mouvement", "体を動かす休憩"),
 "Affirmation Practice": ("Affirmations-Übung", "Pratique d'affirmation", "アファメーション練習"),
 "Worry Window": ("Sorgen-Fenster", "Fenêtre à soucis", "心配タイム"),
 "Nature Connection": ("Verbindung zur Natur", "Connexion à la nature", "自然とのつながり"),
 "Self-Compassion Letter": ("Brief der Selbstmitgefühls", "Lettre d'auto-compassion", "自分への思いやりの手紙"),
 "Deep Belly Breathing": ("Tiefe Bauchatmung", "Respiration abdominale profonde", "深い腹式呼吸"),
 "Mindful Eating": ("Achtsames Essen", "Alimentation consciente", "マインドフルな食事"),
 "Anxiety Exposure": ("Angst-Exposition", "Exposition à l'anxiété", "不安エクスポージャー"),
 "Sleep Wind-Down": ("Schlaf-Routine", "Rituel de coucher", "就寝前のリラックス"),
 "Celebration": ("Feiern", "Célébration", "お祝い"),
 "Free Movement": ("Freie Bewegung", "Mouvement libre", "自由な動き"),
 "Breath Counting": ("Atemzählen", "Comptage des respirations", "呼吸を数える"),
 "Sensory Soothing": ("Sinnliche Beruhigung", "Apaisement sensoriel", "五感で落ち着く"),
 # ---- healing tasks (description) ----
 "Start your day with 4-7-8 breathing technique": ("Beginne den Tag mit der 4-7-8-Atemtechnik", "Commencez la journée avec la technique 4-7-8", "4-7-8呼吸法で一日を始めましょう"),
 "Write 3 things you're grateful for": ("Schreibe 3 Dinge auf, für die du dankbar bist", "Notez 3 choses pour lesquelles vous êtes reconnaissant", "感謝していること3つを書きましょう"),
 "Progressive relaxation from head to toe": ("Progressive Entspannung von Kopf bis Fuß", "Relaxation progressive de la tête aux pieds", "頭からつま先まで順に緩めます"),
 "Engage all five senses to ground yourself": ("Nutze alle fünf Sinne zur Erdung", "Mobilisez vos cinq sens pour vous ancrer", "五感をすべて使って自分を落ち着かせます"),
 "Release tension with mindful movement": ("Löse Spannungen mit achtsamer Bewegung", "Relâchez les tensions par un mouvement conscient", "意識した動きで緊張をほぐします"),
 "Journal about your day and wins": ("Schreibe über deinen Tag und deine Erfolge", "Écrivez sur votre journée et vos réussites", "今日の出来事と良かったことを書きましょう"),
 "4 counts in, hold, out, hold": ("4 ein, halten, aus, halten", "4 temps inspirez, retenez, expirez, retenez", "4秒吸って、止めて、吐いて、止める"),
 "Walk slowly, noticing each step": ("Geh langsam und bemerke jeden Schritt", "Marchez lentement, en remarquant chaque pas", "一歩ずつ意識しながらゆっくり歩きます"),
 "Challenge anxious thoughts with evidence": ("Hinterfrage ängstliche Gedanken mit Belegen", "Remettez en question les pensées anxieuses avec des faits", "証拠をもとに不安な考えを見直します"),
 "Tense and release each muscle group": ("Spanne jede Muskelgruppe an und entspanne sie", "Contractez puis relâchez chaque groupe musculaire", "各筋肉を緊張させてから緩めます"),
 "Focus on breath as your anchor": ("Konzentriere dich auf den Atem als deinen Anker", "Concentrez-vous sur la respiration, votre ancre", "呼吸を錨として意識を向けます"),
 "Identify and plan for your triggers": ("Erkenne deine Auslöser und plane dafür", "Identifiez vos déclencheurs et anticipez-les", "トリガーを特定し、備えます"),
 "Send compassion to yourself and others": ("Sende dir selbst und anderen Mitgefühl", "Envoyez de la compassion à vous-même et aux autres", "自分と他者へ思いやりを送ります"),
 "Splash cold water for vagus nerve activation": ("Spritze kaltes Wasser zur Aktivierung des Vagusnervs", "Aspergez-vous d'eau froide pour activer le nerf vague", "冷たい水で迷走神経を刺激します"),
 "Picture your peaceful place in detail": ("Stelle dir deinen Ort der Ruhe im Detail vor", "Imaginez en détail votre lieu de paix", "安らげる場所を細部まで思い描きます"),
 "Shake out tension with full-body movement": ("Schüttle Spannung mit Ganzkörperbewegung ab", "Évacuez les tensions en bougeant tout le corps", "全身を動かして緊張を振り払います"),
 "Repeat calming affirmations with intention": ("Wiederhole beruhigende Affirmationen mit Absicht", "Répétez des affirmations apaisantes avec intention", "落ち着くアファメーションを心を込めて繰り返します"),
 "Designate time to address worries, then let go": ("Plane Zeit für Sorgen ein und lass dann los", "Réservez un temps pour vos soucis, puis lâchez prise", "心配する時間を決め、その後手放します"),
 "Spend time noticing natural elements": ("Nimm dir Zeit, natürliche Elemente wahrzunehmen", "Prenez le temps d'observer les éléments naturels", "自然の要素に気づく時間を持ちます"),
 "Write to yourself with kindness": ("Schreibe dir selbst mit Freundlichkeit", "Écrivez-vous avec bienveillance", "自分にやさしく手紙を書きます"),
 "Diaphragmatic breathing for calm": ("Zwerchfellatmung für Ruhe", "Respiration diaphragmatique pour le calme", "落ち着くための横隔膜呼吸"),
 "Eat one meal with full attention": ("Iss eine Mahlzeit mit voller Aufmerksamkeit", "Mangez un repas en pleine conscience", "一食を完全に集中して食べます"),
 "Gently face a small fear with support": ("Stelle dich behutsam einer kleinen Angst – mit Unterstützung", "Affrontez doucement une petite peur, avec du soutien", "支えのもと、小さな恐れにそっと向き合います"),
 "Create a calming bedtime routine": ("Schaffe eine beruhigende Abendroutine", "Créez un rituel de coucher apaisant", "落ち着く就寝前の習慣をつくります"),
 "Acknowledge your healing journey progress": ("Würdige die Fortschritte auf deinem Heilungsweg", "Reconnaissez les progrès de votre guérison", "回復の歩みの進歩を認めます"),
 "Dance or move freely to release energy": ("Tanze oder bewege dich frei, um Energie freizusetzen", "Dansez ou bougez librement pour libérer l'énergie", "踊ったり自由に動いてエネルギーを発散します"),
 "Count breaths to 10, then restart": ("Zähle Atemzüge bis 10 und beginne neu", "Comptez les respirations jusqu'à 10, puis recommencez", "呼吸を10まで数え、また始めます"),
 "Engage comforting textures, scents, sounds": ("Nutze beruhigende Texturen, Düfte und Klänge", "Mobilisez des textures, odeurs et sons réconfortants", "心地よい手触り・香り・音に触れます"),
 # ---- panic senses ----
 "things you can SEE": ("Dinge, die du SEHEN kannst", "choses que vous pouvez VOIR", "見えるもの"),
 "things you can TOUCH": ("Dinge, die du FÜHLEN kannst", "choses que vous pouvez TOUCHER", "触れられるもの"),
 "things you can HEAR": ("Dinge, die du HÖREN kannst", "choses que vous pouvez ENTENDRE", "聞こえるもの"),
 "things you can SMELL": ("Dinge, die du RIECHEN kannst", "choses que vous pouvez SENTIR", "においを感じるもの"),
 "thing you can TASTE": ("Ding, das du SCHMECKEN kannst", "chose que vous pouvez GOÛTER", "味わえるもの"),
 # ---- breath labels ----
 "Breathe In": ("Einatmen", "Inspirez", "吸って"),
 "Breathe In...": ("Einatmen …", "Inspirez…", "吸って…"),
 "Hold...": ("Halten …", "Retenez…", "止めて…"),
 "Breathe Out...": ("Ausatmen …", "Expirez…", "吐いて…"),
 "Well done!": ("Gut gemacht!", "Bravo !", "よくできました！"),
 # ---- resource categories ----
 "All": ("Alle", "Tout", "すべて"),
 "Breathing": ("Atmung", "Respiration", "呼吸"),
 "Grounding": ("Erdung", "Ancrage", "グラウンディング"),
 "Mindfulness": ("Achtsamkeit", "Pleine conscience", "マインドフルネス"),
 "CBT Tools": ("KVT-Werkzeuge", "Outils TCC", "認知行動療法ツール"),
 "Crisis": ("Krise", "Crise", "緊急時"),
 # ---- resource technique titles/descriptions ----
 "4-7-8 Breathing": ("4-7-8-Atmung", "Respiration 4-7-8", "4-7-8呼吸法"),
 "A natural tranquilizer for the nervous system": ("Ein natürliches Beruhigungsmittel für das Nervensystem", "Un tranquillisant naturel pour le système nerveux", "神経系のための自然な鎮静法"),
 "Box Breathing": ("Box-Atmung", "Respiration carrée", "ボックス呼吸"),
 "Used by Navy SEALs to stay calm under pressure": ("Von Navy SEALs genutzt, um unter Druck ruhig zu bleiben", "Utilisée par les Navy SEALs pour rester calme sous pression", "海軍特殊部隊も使う、プレッシャー下で冷静を保つ方法"),
 "Anchor yourself in the present moment using your senses": ("Verankere dich mit deinen Sinnen im gegenwärtigen Moment", "Ancrez-vous dans le présent grâce à vos sens", "五感を使って今この瞬間に錨を下ろします"),
 "Body Scan Meditation": ("Body-Scan-Meditation", "Méditation du scan corporel", "ボディスキャン瞑想"),
 "Systematically relax each part of your body": ("Entspanne systematisch jeden Teil deines Körpers", "Détendez méthodiquement chaque partie du corps", "体の各部位を順に緩めていきます"),
 "Progressive Muscle Relaxation": ("Progressive Muskelentspannung", "Relaxation musculaire progressive", "漸進的筋弛緩法"),
 "Tense and release muscle groups to relieve physical tension": ("Spanne Muskelgruppen an und entspanne sie, um körperliche Spannung zu lösen", "Contractez et relâchez les muscles pour soulager les tensions physiques", "筋肉を緊張・弛緩させて体の緊張を和らげます"),
 "Cold Water Technique": ("Kaltwasser-Technik", "Technique de l'eau froide", "冷水テクニック"),
 "Activate the dive reflex to calm your nervous system": ("Aktiviere den Tauchreflex, um dein Nervensystem zu beruhigen", "Activez le réflexe de plongée pour calmer le système nerveux", "潜水反射を使って神経系を落ち着かせます"),
 "Cognitive Defusion": ("Kognitive Defusion", "Défusion cognitive", "認知的脱フュージョン"),
 "Create distance between you and anxious thoughts": ("Schaffe Abstand zwischen dir und ängstlichen Gedanken", "Créez de la distance entre vous et les pensées anxieuses", "不安な考えと自分のあいだに距離をつくります"),
 "Crisis Resources": ("Krisen-Hilfen", "Ressources de crise", "緊急時のリソース"),
 "Important contacts when you need immediate help": ("Wichtige Kontakte, wenn du sofort Hilfe brauchst", "Contacts importants en cas de besoin d'aide immédiate", "すぐに助けが必要なときの大切な連絡先"),
 # ---- resource steps ----
 "Exhale completely through your mouth": ("Atme vollständig durch den Mund aus", "Expirez complètement par la bouche", "口から完全に息を吐き切ります"),
 "Close your mouth and inhale through your nose for 4 seconds": ("Schließe den Mund und atme 4 Sekunden durch die Nase ein", "Fermez la bouche et inspirez par le nez pendant 4 secondes", "口を閉じ、鼻から4秒かけて吸います"),
 "Hold your breath for 7 seconds": ("Halte den Atem 7 Sekunden lang an", "Retenez votre souffle pendant 7 secondes", "7秒間、息を止めます"),
 "Exhale completely through your mouth for 8 seconds": ("Atme 8 Sekunden lang vollständig durch den Mund aus", "Expirez complètement par la bouche pendant 8 secondes", "口から8秒かけて完全に吐きます"),
 "Repeat 3-4 times": ("Wiederhole 3- bis 4-mal", "Répétez 3 à 4 fois", "3〜4回繰り返します"),
 "Inhale slowly for 4 seconds": ("Atme 4 Sekunden lang langsam ein", "Inspirez lentement pendant 4 secondes", "4秒かけてゆっくり吸います"),
 "Hold your breath for 4 seconds": ("Halte den Atem 4 Sekunden lang an", "Retenez votre souffle pendant 4 secondes", "4秒間、息を止めます"),
 "Exhale slowly for 4 seconds": ("Atme 4 Sekunden lang langsam aus", "Expirez lentement pendant 4 secondes", "4秒かけてゆっくり吐きます"),
 "Hold again for 4 seconds": ("Halte erneut 4 Sekunden lang an", "Retenez à nouveau pendant 4 secondes", "もう一度4秒止めます"),
 "Repeat 4-6 times": ("Wiederhole 4- bis 6-mal", "Répétez 4 à 6 fois", "4〜6回繰り返します"),
 "Name 5 things you can SEE": ("Nenne 5 Dinge, die du SEHEN kannst", "Nommez 5 choses que vous pouvez VOIR", "見えるものを5つ挙げます"),
 "Name 4 things you can TOUCH": ("Nenne 4 Dinge, die du FÜHLEN kannst", "Nommez 4 choses que vous pouvez TOUCHER", "触れられるものを4つ挙げます"),
 "Name 3 things you can HEAR": ("Nenne 3 Dinge, die du HÖREN kannst", "Nommez 3 choses que vous pouvez ENTENDRE", "聞こえるものを3つ挙げます"),
 "Name 2 things you can SMELL": ("Nenne 2 Dinge, die du RIECHEN kannst", "Nommez 2 choses que vous pouvez SENTIR", "においを感じるものを2つ挙げます"),
 "Name 1 thing you can TASTE": ("Nenne 1 Ding, das du SCHMECKEN kannst", "Nommez 1 chose que vous pouvez GOÛTER", "味わえるものを1つ挙げます"),
 "Lie down or sit comfortably": ("Lege oder setze dich bequem hin", "Allongez-vous ou asseyez-vous confortablement", "横になるか、楽な姿勢で座ります"),
 "Start at the top of your head": ("Beginne am Scheitel deines Kopfes", "Commencez par le sommet de la tête", "頭のてっぺんから始めます"),
 "Slowly move attention down through each body part": ("Wandere langsam mit der Aufmerksamkeit durch jeden Körperteil", "Déplacez lentement votre attention sur chaque partie du corps", "意識を体の各部位へ順に下ろしていきます"),
 "Notice tension without judgment": ("Bemerke Spannung ohne zu urteilen", "Remarquez les tensions sans jugement", "緊張を評価せずに気づきます"),
 "Breathe into areas of tension and release": ("Atme in verspannte Bereiche hinein und lass los", "Respirez vers les zones de tension et relâchez", "緊張した部分へ息を送り、緩めます"),
 "Write down the anxious thought": ("Schreibe den ängstlichen Gedanken auf", "Notez la pensée anxieuse", "不安な考えを書き出します"),
 "Rate your belief in it (0-100%)": ("Bewerte, wie stark du daran glaubst (0–100 %)", "Évaluez votre croyance en elle (0-100 %)", "それをどれだけ信じているか評価します（0〜100%）"),
 "List evidence FOR the thought": ("Liste Belege FÜR den Gedanken auf", "Listez les preuves POUR la pensée", "その考えを支持する根拠を挙げます"),
 "List evidence AGAINST the thought": ("Liste Belege GEGEN den Gedanken auf", "Listez les preuves CONTRE la pensée", "その考えに反する根拠を挙げます"),
 "Create a balanced alternative thought": ("Formuliere einen ausgewogenen Alternativgedanken", "Formulez une pensée alternative équilibrée", "バランスのとれた別の考えをつくります"),
 "Re-rate your belief": ("Bewerte deinen Glauben erneut", "Réévaluez votre croyance", "信じる度合いを評価し直します"),
 "Start with your feet - tense for 5 seconds": ("Beginne mit den Füßen – spanne 5 Sekunden an", "Commencez par les pieds – contractez 5 secondes", "足から始め、5秒間緊張させます"),
 "Release and notice the difference": ("Lass los und bemerke den Unterschied", "Relâchez et remarquez la différence", "緩めて、その違いに気づきます"),
 "Move to calves, thighs, abdomen": ("Geh weiter zu Waden, Oberschenkeln, Bauch", "Passez aux mollets, cuisses, abdomen", "ふくらはぎ、太もも、お腹へ移ります"),
 "Continue through chest, arms, hands": ("Mache weiter mit Brust, Armen, Händen", "Continuez avec la poitrine, les bras, les mains", "胸、腕、手へと続けます"),
 "Finish with shoulders, neck, face": ("Schließe mit Schultern, Nacken, Gesicht ab", "Terminez par les épaules, le cou, le visage", "肩、首、顔で締めくくります"),
 "Rest and notice full-body relaxation": ("Ruhe und bemerke die Entspannung des ganzen Körpers", "Reposez-vous et ressentez la détente du corps entier", "休んで、全身のリラックスを感じます"),
 "Fill a bowl with cold water and ice": ("Fülle eine Schüssel mit kaltem Wasser und Eis", "Remplissez un bol d'eau froide et de glace", "ボウルに冷水と氷を入れます"),
 "Take a deep breath": ("Atme tief ein", "Prenez une grande inspiration", "深く息を吸います"),
 "Submerge your face for 15-30 seconds": ("Tauche dein Gesicht 15–30 Sekunden ein", "Immergez votre visage 15 à 30 secondes", "顔を15〜30秒間つけます"),
 "Alternatively, hold ice cubes in your hands": ("Alternativ halte Eiswürfel in den Händen", "Sinon, tenez des glaçons dans vos mains", "代わりに、氷を手に握っても構いません"),
 "Notice the shift in your body's response": ("Bemerke die Veränderung der Reaktion deines Körpers", "Remarquez le changement dans la réaction de votre corps", "体の反応の変化に気づきます"),
 "Notice the anxious thought": ("Bemerke den ängstlichen Gedanken", "Remarquez la pensée anxieuse", "不安な考えに気づきます"),
 "Prefix it with 'I notice I'm having the thought that...'": ("Stelle voran: „Ich bemerke, dass ich den Gedanken habe, dass …“", "Précédez-la de « Je remarque que j'ai la pensée que… »", "「〜という考えがあると気づいている」と前に付けます"),
 "Say it in a silly voice internally": ("Sag ihn innerlich mit einer albernen Stimme", "Dites-la intérieurement d'une voix amusante", "心の中でおどけた声で言ってみます"),
 "Visualize the thought as a cloud passing by": ("Stelle dir den Gedanken als vorüberziehende Wolke vor", "Imaginez la pensée comme un nuage qui passe", "その考えを、流れていく雲として思い描きます"),
 "Thank your mind for trying to protect you": ("Danke deinem Geist, dass er dich schützen will", "Remerciez votre esprit d'essayer de vous protéger", "守ろうとしてくれた心に感謝します"),
 # ---- crisis resources: per-country localized (REVIEW & VERIFY before release) ----
 "988 Suicide & Crisis Lifeline: Call or text 988": (
    "TelefonSeelsorge: 0800 111 0 111 oder 0800 111 0 222 (kostenlos, 24/7)",
    "3114 — Numéro national de prévention du suicide (24h/24, gratuit)",
    "いのちの電話：0570-783-556（ナビダイヤル・24時間）"),
 "Crisis Text Line: Text HOME to 741741": (
    "krisenchat: kostenloser Chat unter krisenchat.de",
    "SOS Amitié : 09 72 39 40 50 (24h/24)",
    "よりそいホットライン：0120-279-338（24時間・通話無料）"),
 "NAMI Helpline: 1-800-950-NAMI": (
    "Info-Telefon Depression: 0800 33 44 533",
    "Fil Santé Jeunes : 0 800 235 236",
    "こころの健康相談統一ダイヤル：0570-064-556"),
 "SAMHSA Helpline: 1-800-662-4357": (
    "Sucht- & Drogen-Hotline: 01806 313 031",
    "Drogues Info Service : 0 800 23 13 13",
    "精神保健福祉センター（お住まいの地域の窓口）"),
 "Emergency: 911": ("Notruf: 112", "Urgences : 112 (ou 15)", "緊急時：119（救急）／110（警察）"),
}

def u(v):
    return {"stringUnit": {"state": "translated", "value": v}}

cat = json.load(open(CAT))
s = cat["strings"]
n = 0
for en, vals in D.items():
    e = s.setdefault(en, {})
    loc = e.setdefault("localizations", {})
    loc.setdefault("en", u(en))
    for lang, v in zip(LANGS, vals):
        loc[lang] = u(v)
    n += 1
cat["strings"] = dict(sorted(s.items()))
json.dump(cat, open(CAT, "w"), ensure_ascii=False, indent=2)
print(f"added/updated {n} data strings x {len(LANGS)} langs; catalog total {len(s)}")
