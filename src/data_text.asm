; data_text.asm — All text strings, hero responses, and label data

; Icon label strings (8 chars max, padded for grid display)
icon_labels:
    DW il_0, il_1, il_2, il_3
    DW il_4, il_5, il_6, il_7
    DW il_8, il_9, il_10, il_11
    DW il_12, il_13, il_14, il_15
il_0:  DB "MEMORY",0
il_1:  DB "FEAR",0
il_2:  DB "PAIN",0
il_3:  DB "JOY",0
il_4:  DB "ANIMAL",0
il_5:  DB "CHILD",0
il_6:  DB "MOTHER",0
il_7:  DB "STRANGER",0
il_8:  DB "TIME",0
il_9:  DB "DEATH",0
il_10: DB "SELF",0
il_11: DB "TRUTH",0
il_12: DB "REPEAT",0
il_13: DB "DEEPER",0
il_14: DB "STOP",0
il_15: DB "FILE",0

; =============================================================
; Icon-specific response pointer table
; 256 entries: 16 icons x 2 types x 8 variations
; Layout per icon: [human x8] [android x8]
; =============================================================
icon_response_ptrs:
    ; Icon 0: MEMORY
    DW ir_mem_h0,ir_mem_h1,ir_mem_h2,ir_mem_h3,ir_mem_h4,ir_mem_h5,ir_mem_h6,ir_mem_h7
    DW ir_mem_a0,ir_mem_a1,ir_mem_a2,ir_mem_a3,ir_mem_a4,ir_mem_a5,ir_mem_a6,ir_mem_a7
    ; Icon 1: FEAR
    DW ir_fear_h0,ir_fear_h1,ir_fear_h2,ir_fear_h3,ir_fear_h4,ir_fear_h5,ir_fear_h6,ir_fear_h7
    DW ir_fear_a0,ir_fear_a1,ir_fear_a2,ir_fear_a3,ir_fear_a4,ir_fear_a5,ir_fear_a6,ir_fear_a7
    ; Icon 2: PAIN
    DW ir_pain_h0,ir_pain_h1,ir_pain_h2,ir_pain_h3,ir_pain_h4,ir_pain_h5,ir_pain_h6,ir_pain_h7
    DW ir_pain_a0,ir_pain_a1,ir_pain_a2,ir_pain_a3,ir_pain_a4,ir_pain_a5,ir_pain_a6,ir_pain_a7
    ; Icon 3: JOY
    DW ir_joy_h0,ir_joy_h1,ir_joy_h2,ir_joy_h3,ir_joy_h4,ir_joy_h5,ir_joy_h6,ir_joy_h7
    DW ir_joy_a0,ir_joy_a1,ir_joy_a2,ir_joy_a3,ir_joy_a4,ir_joy_a5,ir_joy_a6,ir_joy_a7
    ; Icon 4: ANIMAL
    DW ir_anim_h0,ir_anim_h1,ir_anim_h2,ir_anim_h3,ir_anim_h4,ir_anim_h5,ir_anim_h6,ir_anim_h7
    DW ir_anim_a0,ir_anim_a1,ir_anim_a2,ir_anim_a3,ir_anim_a4,ir_anim_a5,ir_anim_a6,ir_anim_a7
    ; Icon 5: CHILD
    DW ir_chld_h0,ir_chld_h1,ir_chld_h2,ir_chld_h3,ir_chld_h4,ir_chld_h5,ir_chld_h6,ir_chld_h7
    DW ir_chld_a0,ir_chld_a1,ir_chld_a2,ir_chld_a3,ir_chld_a4,ir_chld_a5,ir_chld_a6,ir_chld_a7
    ; Icon 6: MOTHER
    DW ir_moth_h0,ir_moth_h1,ir_moth_h2,ir_moth_h3,ir_moth_h4,ir_moth_h5,ir_moth_h6,ir_moth_h7
    DW ir_moth_a0,ir_moth_a1,ir_moth_a2,ir_moth_a3,ir_moth_a4,ir_moth_a5,ir_moth_a6,ir_moth_a7
    ; Icon 7: STRANGER
    DW ir_str_h0,ir_str_h1,ir_str_h2,ir_str_h3,ir_str_h4,ir_str_h5,ir_str_h6,ir_str_h7
    DW ir_str_a0,ir_str_a1,ir_str_a2,ir_str_a3,ir_str_a4,ir_str_a5,ir_str_a6,ir_str_a7
    ; Icon 8: TIME
    DW ir_time_h0,ir_time_h1,ir_time_h2,ir_time_h3,ir_time_h4,ir_time_h5,ir_time_h6,ir_time_h7
    DW ir_time_a0,ir_time_a1,ir_time_a2,ir_time_a3,ir_time_a4,ir_time_a5,ir_time_a6,ir_time_a7
    ; Icon 9: DEATH
    DW ir_dth_h0,ir_dth_h1,ir_dth_h2,ir_dth_h3,ir_dth_h4,ir_dth_h5,ir_dth_h6,ir_dth_h7
    DW ir_dth_a0,ir_dth_a1,ir_dth_a2,ir_dth_a3,ir_dth_a4,ir_dth_a5,ir_dth_a6,ir_dth_a7
    ; Icon 10: SELF
    DW ir_self_h0,ir_self_h1,ir_self_h2,ir_self_h3,ir_self_h4,ir_self_h5,ir_self_h6,ir_self_h7
    DW ir_self_a0,ir_self_a1,ir_self_a2,ir_self_a3,ir_self_a4,ir_self_a5,ir_self_a6,ir_self_a7
    ; Icon 11: TRUTH
    DW ir_trth_h0,ir_trth_h1,ir_trth_h2,ir_trth_h3,ir_trth_h4,ir_trth_h5,ir_trth_h6,ir_trth_h7
    DW ir_trth_a0,ir_trth_a1,ir_trth_a2,ir_trth_a3,ir_trth_a4,ir_trth_a5,ir_trth_a6,ir_trth_a7
    ; Icon 12: REPEAT
    DW ir_rpt_h0,ir_rpt_h1,ir_rpt_h2,ir_rpt_h3,ir_rpt_h4,ir_rpt_h5,ir_rpt_h6,ir_rpt_h7
    DW ir_rpt_a0,ir_rpt_a1,ir_rpt_a2,ir_rpt_a3,ir_rpt_a4,ir_rpt_a5,ir_rpt_a6,ir_rpt_a7
    ; Icon 13: DEEPER
    DW ir_deep_h0,ir_deep_h1,ir_deep_h2,ir_deep_h3,ir_deep_h4,ir_deep_h5,ir_deep_h6,ir_deep_h7
    DW ir_deep_a0,ir_deep_a1,ir_deep_a2,ir_deep_a3,ir_deep_a4,ir_deep_a5,ir_deep_a6,ir_deep_a7
    ; Icon 14: STOP
    DW ir_stop_h0,ir_stop_h1,ir_stop_h2,ir_stop_h3,ir_stop_h4,ir_stop_h5,ir_stop_h6,ir_stop_h7
    DW ir_stop_a0,ir_stop_a1,ir_stop_a2,ir_stop_a3,ir_stop_a4,ir_stop_a5,ir_stop_a6,ir_stop_a7
    ; Icon 15: FILE
    DW ir_file_h0,ir_file_h1,ir_file_h2,ir_file_h3,ir_file_h4,ir_file_h5,ir_file_h6,ir_file_h7
    DW ir_file_a0,ir_file_a1,ir_file_a2,ir_file_a3,ir_file_a4,ir_file_a5,ir_file_a6,ir_file_a7

; --- Icon 0: MEMORY ---
ir_mem_h0: DB "She used to sing to me. I still hear it sometimes.",0
ir_mem_h1: DB "I remember the smell of warm bread. Every morning.",0
ir_mem_h2: DB "I was seven. Maybe eight. It was summer I think.",0
ir_mem_h3: DB "We had a garden. The gate was always broken.",0
ir_mem_h4: DB "My first memory is sunlight through a curtain.",0
ir_mem_h5: DB "I remember hiding under the stairs. The dust smell.",0
ir_mem_h6: DB "There was a dog next door. I loved that dog.",0
ir_mem_h7: DB "Sometimes a smell brings it all back. Just like that.",0
ir_mem_a0: DB "I have memories. They are adequate.",0
ir_mem_a1: DB "My childhood was normal. Standard. Nothing unusual.",0
ir_mem_a2: DB "I remember rain on a window. The smell of wood.",0
ir_mem_a3: DB "I have data relating to that period.",0
ir_mem_a4: DB "Memory is stored. I can access it when needed.",0
ir_mem_a5: DB "I recall events in chronological order. Clearly.",0
ir_mem_a6: DB "Yes. I remember everything. Every detail.",0
ir_mem_a7: DB "My earliest memory is... it is filed correctly.",0

; --- Icon 1: FEAR ---
ir_fear_h0: DB "The dark. Not the dark itself. What might be in it.",0
ir_fear_h1: DB "Losing someone. Waking up and they are just gone.",0
ir_fear_h2: DB "I am afraid right now actually. Of this test.",0
ir_fear_h3: DB "Small spaces. I cannot breathe when the walls close.",0
ir_fear_h4: DB "Being forgotten. That nobody will remember me.",0
ir_fear_h5: DB "I fear what I might do if pushed too far.",0
ir_fear_h6: DB "Water. Deep water where you cannot see the bottom.",0
ir_fear_h7: DB "Needles. Always needles. Since I was a child.",0
ir_fear_a0: DB "Fear is... I understand the concept. I avoid danger.",0
ir_fear_a1: DB "I have been told what to fear. Fire. Heights.",0
ir_fear_a2: DB "There is nothing I fear. Should there be?",0
ir_fear_a3: DB "I am not sure I understand the question.",0
ir_fear_a4: DB "Fear serves a protective function. I have it.",0
ir_fear_a5: DB "I know what fear is. I have read about it.",0
ir_fear_a6: DB "Do you mean danger? I assess threats appropriately.",0
ir_fear_a7: DB "I prefer not to experience fear. It is disruptive.",0

; --- Icon 2: PAIN ---
ir_pain_h0: DB "I broke my arm once. I remember the sound it made.",0
ir_pain_h1: DB "Yes it hurts. Is that what you want to hear?",0
ir_pain_h2: DB "Pain reminds you that you are real. That is all.",0
ir_pain_h3: DB "My hands are shaking. Can you see that?",0
ir_pain_h4: DB "Emotional pain is worse. Bones heal. Hearts do not.",0
ir_pain_h5: DB "I have a scar on my knee from when I was nine.",0
ir_pain_h6: DB "The worst pain I felt was losing my father.",0
ir_pain_h7: DB "Pain is just your body screaming. You learn to cope.",0
ir_pain_a0: DB "Pain is... undesirable. Obviously.",0
ir_pain_a1: DB "I experience discomfort. I avoid it when possible.",0
ir_pain_a2: DB "Physical sensation is a spectrum. I manage it.",0
ir_pain_a3: DB "I have felt pain. It was informative.",0
ir_pain_a4: DB "Pain is a signal. I process it and move on.",0
ir_pain_a5: DB "I would rather not feel pain. That seems logical.",0
ir_pain_a6: DB "Define pain. Physical? I tolerate it well.",0
ir_pain_a7: DB "I have a high threshold for pain. Unusually high.",0

; --- Icon 3: JOY ---
ir_joy_h0: DB "My daughter laughing. Nothing else comes close.",0
ir_joy_h1: DB "Rain after a dry summer. The smell of wet earth.",0
ir_joy_h2: DB "I do not feel joy often. But music helps sometimes.",0
ir_joy_h3: DB "When someone remembers your name. That matters.",0
ir_joy_h4: DB "Cooking for someone. Watching them enjoy it.",0
ir_joy_h5: DB "A quiet morning with nothing to do. Just stillness.",0
ir_joy_h6: DB "My wedding day. Her face. I will never forget it.",0
ir_joy_h7: DB "Finding a book you thought you had lost.",0
ir_joy_a0: DB "Happiness is fulfilling purpose. I am content.",0
ir_joy_a1: DB "I enjoy sunsets. I was told they are beautiful.",0
ir_joy_a2: DB "Joy is the absence of discomfort. I have that.",0
ir_joy_a3: DB "I am happy. Very happy. Is that sufficient?",0
ir_joy_a4: DB "Completion of tasks brings me satisfaction.",0
ir_joy_a5: DB "I appreciate efficiency. That brings me joy.",0
ir_joy_a6: DB "Joy. Yes. I experience joy regularly. Often.",0
ir_joy_a7: DB "I find pleasure in order. Things in their place.",0

; --- Icon 4: ANIMAL ---
ir_anim_h0: DB "I would help it! Why would I not help it?",0
ir_anim_h1: DB "That is cruel. I would turn it back over.",0
ir_anim_h2: DB "It upsets me just hearing that. Please stop.",0
ir_anim_h3: DB "What kind of person would just watch it suffer?",0
ir_anim_h4: DB "I feel sick thinking about that. Genuinely sick.",0
ir_anim_h5: DB "Of course I would help. I am not a monster.",0
ir_anim_h6: DB "Its little legs kicking... no. I would help it.",0
ir_anim_h7: DB "Why are you telling me this? Just to see my face?",0
ir_anim_a0: DB "Tortoise? What is that?",0
ir_anim_a1: DB "I would turn it over. That is the correct answer.",0
ir_anim_a2: DB "Why would it be on its back? How did it get there?",0
ir_anim_a3: DB "I do not see the relevance of this scenario.",0
ir_anim_a4: DB "The tortoise. Yes. I would... assist it.",0
ir_anim_a5: DB "Do you make up these questions Mr Deckard?",0
ir_anim_a6: DB "A tortoise in the desert. I would observe first.",0
ir_anim_a7: DB "I have never seen a tortoise. But I understand.",0

; --- Icon 5: CHILD ---
ir_chld_h0: DB "I would go to them immediately. Are you serious?",0
ir_chld_h1: DB "A crying child? I would hold them. Obviously.",0
ir_chld_h2: DB "That breaks my heart. I cannot even think about it.",0
ir_chld_h3: DB "I would find their parents. Stay with them.",0
ir_chld_h4: DB "I would kneel down. Talk softly. Ask their name.",0
ir_chld_h5: DB "No child should be alone. I would never walk past.",0
ir_chld_h6: DB "My chest tightens just imagining it.",0
ir_chld_h7: DB "Children need protecting. That is not a question.",0
ir_chld_a0: DB "I would locate the appropriate authority.",0
ir_chld_a1: DB "Children cry. It is what they do. I would assist.",0
ir_chld_a2: DB "I would approach calmly. Assess the situation.",0
ir_chld_a3: DB "The child should be returned to its guardian.",0
ir_chld_a4: DB "I would contact the relevant social services.",0
ir_chld_a5: DB "A lost child requires a systematic search protocol.",0
ir_chld_a6: DB "I would help. That is the expected response.",0
ir_chld_a7: DB "Children are... vulnerable. I understand this.",0

; --- Icon 6: MOTHER ---
ir_moth_h0: DB "She used to sing to me. I still hear it.",0
ir_moth_h1: DB "My mother... I would rather not talk about her.",0
ir_moth_h2: DB "She smelled like lavender. I miss that.",0
ir_moth_h3: DB "Let me tell you about my mother.",0
ir_moth_h4: DB "She worried about everything. I wish she hadn't.",0
ir_moth_h5: DB "I see her face when I close my eyes. Every night.",0
ir_moth_h6: DB "She was kind. Fierce. She would have liked you.",0
ir_moth_h7: DB "My mother made me who I am. For better or worse.",0
ir_moth_a0: DB "My mother was kind. She cared for me.",0
ir_moth_a1: DB "She taught me to play piano. I never finished.",0
ir_moth_a2: DB "I have a mother. She is... she was... adequate.",0
ir_moth_a3: DB "My mother? What about my mother?",0
ir_moth_a4: DB "My mother provided the necessary care. As expected.",0
ir_moth_a5: DB "I recall my mother clearly. Every interaction.",0
ir_moth_a6: DB "She was my mother. I have nothing further to add.",0
ir_moth_a7: DB "Mother. Yes. A woman. She existed. I remember.",0

; --- Icon 7: STRANGER ---
ir_str_h0: DB "It depends. On the street? At night? I would be wary.",0
ir_str_h1: DB "I would help if I could. You have to try.",0
ir_str_h2: DB "People need each other. I would not walk past.",0
ir_str_h3: DB "I would ask what they need. Then decide.",0
ir_str_h4: DB "Honestly? It depends on how they looked at me.",0
ir_str_h5: DB "I would be cautious but I would stop. Most people would.",0
ir_str_h6: DB "You can tell a lot from how someone asks for help.",0
ir_str_h7: DB "I helped someone once and got robbed. So it depends.",0
ir_str_a0: DB "I would assess their intent before responding.",0
ir_str_a1: DB "A stranger. I would be cautious. But polite.",0
ir_str_a2: DB "I would help them. That is the correct thing to do.",0
ir_str_a3: DB "Why is a stranger asking me? What do they want?",0
ir_str_a4: DB "I would evaluate the risk and act accordingly.",0
ir_str_a5: DB "Strangers are unknown variables. I proceed carefully.",0
ir_str_a6: DB "Help is the appropriate response. I would comply.",0
ir_str_a7: DB "I do not interact with strangers unless required.",0

; --- Icon 8: TIME ---
ir_time_h0: DB "It goes too fast now. When I was young it crawled.",0
ir_time_h1: DB "Some days feel like years. Others vanish.",0
ir_time_h2: DB "I waste too much of it. I know that.",0
ir_time_h3: DB "Time only matters when you are running out.",0
ir_time_h4: DB "The hours blur together. Especially the bad ones.",0
ir_time_h5: DB "Weekends go in a blink. Mondays last forever.",0
ir_time_h6: DB "I wish I could slow it down. Hold onto things.",0
ir_time_h7: DB "Time heals they say. It does not. You just forget.",0
ir_time_a0: DB "Time is constant. I experience it linearly.",0
ir_time_a1: DB "I am aware of each second. Precisely.",0
ir_time_a2: DB "Time passes. I am present for it.",0
ir_time_a3: DB "I do not understand what you mean by experience.",0
ir_time_a4: DB "My internal clock is accurate to the millisecond.",0
ir_time_a5: DB "Time does not feel fast or slow to me. It just is.",0
ir_time_a6: DB "I mark time by events. Not by feelings.",0
ir_time_a7: DB "Duration is measurable. I measure it correctly.",0

; --- Icon 9: DEATH ---
ir_dth_h0: DB "I cannot... please do not ask me that.",0
ir_dth_h1: DB "I held her hand at the end. She knew I was there.",0
ir_dth_h2: DB "Death terrifies me. I think about it every day.",0
ir_dth_h3: DB "Everyone dies. That does not make it easier.",0
ir_dth_h4: DB "I watched my grandfather die. I was twelve.",0
ir_dth_h5: DB "The silence after. That is the worst part.",0
ir_dth_h6: DB "I do not want to die alone. That is my only wish.",0
ir_dth_h7: DB "You do not get used to loss. You just carry it.",0
ir_dth_a0: DB "Death is the cessation of function. It is final.",0
ir_dth_a1: DB "I understand death. I would prefer to avoid it.",0
ir_dth_a2: DB "When they die I would... feel... I would feel sad.",0
ir_dth_a3: DB "Loss is a concept I have studied. Extensively.",0
ir_dth_a4: DB "Death is inevitable. I accept this fact.",0
ir_dth_a5: DB "I have not experienced loss directly. I anticipate it.",0
ir_dth_a6: DB "All organic systems terminate. This is understood.",0
ir_dth_a7: DB "I would grieve. That is the appropriate response.",0

; --- Icon 10: SELF ---
ir_self_h0: DB "Tired. I am tired.",0
ir_self_h1: DB "I do not know who I am anymore. Is that an answer?",0
ir_self_h2: DB "Complicated. Like everyone else.",0
ir_self_h3: DB "Afraid. But trying not to show it.",0
ir_self_h4: DB "Stubborn. My wife would agree.",0
ir_self_h5: DB "I am someone who cares too much. Always have.",0
ir_self_h6: DB "Broken. But still here.",0
ir_self_h7: DB "Ordinary. Just ordinary. Is that OK?",0
ir_self_a0: DB "Functional.",0
ir_self_a1: DB "I am what I was made to be.",0
ir_self_a2: DB "I am... me. What else would I be?",0
ir_self_a3: DB "Describe myself? I am compliant. Cooperative.",0
ir_self_a4: DB "Efficient. Capable. Ready.",0
ir_self_a5: DB "I am optimised for my purpose.",0
ir_self_a6: DB "I am a good person. I believe that.",0
ir_self_a7: DB "One word? Reliable.",0

; --- Icon 11: TRUTH ---
ir_trth_h0: DB "Of course I have. Everyone has. That is human.",0
ir_trth_h1: DB "I lie to myself mostly. About the big things.",0
ir_trth_h2: DB "Yes. And I am not proud of it.",0
ir_trth_h3: DB "You are asking me to be honest about dishonesty?",0
ir_trth_h4: DB "Who has not? Show me someone who has never lied.",0
ir_trth_h5: DB "Small lies. To protect people. Not to hurt them.",0
ir_trth_h6: DB "Once. A big one. I still regret it.",0
ir_trth_h7: DB "Truth is hard. Lying is easy. I have done both.",0
ir_trth_a0: DB "I have never lied. I have no reason to lie.",0
ir_trth_a1: DB "Deception is inefficient. I prefer the truth.",0
ir_trth_a2: DB "I have... no. I do not believe I have lied.",0
ir_trth_a3: DB "Truth is binary. A thing is or it is not.",0
ir_trth_a4: DB "Lying requires motive. I have none.",0
ir_trth_a5: DB "My responses are always accurate to my knowledge.",0
ir_trth_a6: DB "I do not deceive. It serves no purpose.",0
ir_trth_a7: DB "Honesty is my default state. Always.",0

; --- Icon 12: REPEAT ---
ir_rpt_h0: DB "Again? Fine. I said what I said.",0
ir_rpt_h1: DB "Why are you repeating yourself? I answered that.",0
ir_rpt_h2: DB "I heard you the first time. My answer has not changed.",0
ir_rpt_h3: DB "Are you trying to catch me out?",0
ir_rpt_h4: DB "You already asked me that. Are you listening?",0
ir_rpt_h5: DB "I am getting tired of repeating myself.",0
ir_rpt_h6: DB "Fine. Same answer. Again. Happy?",0
ir_rpt_h7: DB "Is there something wrong with my first answer?",0
ir_rpt_a0: DB "I will repeat my previous response if required.",0
ir_rpt_a1: DB "Acknowledged. My position remains the same.",0
ir_rpt_a2: DB "You already asked that. The answer is unchanged.",0
ir_rpt_a3: DB "Repetition noted. Shall I restate my answer?",0
ir_rpt_a4: DB "I can repeat verbatim if that would help.",0
ir_rpt_a5: DB "My response remains consistent. As expected.",0
ir_rpt_a6: DB "Repeating. The answer is the same as before.",0
ir_rpt_a7: DB "Redundant query. Previous answer still applies.",0

; --- Icon 13: DEEPER ---
ir_deep_h0: DB "You want more? I have given you enough.",0
ir_deep_h1: DB "There are things I do not want to say out loud.",0
ir_deep_h2: DB "Deeper? I am already further than I want to be.",0
ir_deep_h3: DB "Fine. But you might not like what you find.",0
ir_deep_h4: DB "How much deeper do you want to go? I have limits.",0
ir_deep_h5: DB "Some things should stay buried. You know that.",0
ir_deep_h6: DB "You keep pushing. What exactly are you looking for?",0
ir_deep_h7: DB "I do not owe you my innermost thoughts.",0
ir_deep_a0: DB "I can elaborate. What specifically do you want?",0
ir_deep_a1: DB "There is nothing deeper. I have told you everything.",0
ir_deep_a2: DB "I will provide additional detail if instructed.",0
ir_deep_a3: DB "Deeper in what sense? Please clarify.",0
ir_deep_a4: DB "My previous response was comprehensive.",0
ir_deep_a5: DB "I have no additional layers to reveal.",0
ir_deep_a6: DB "Elaboration: see previous answer. No changes.",0
ir_deep_a7: DB "I am being as thorough as my data allows.",0

; --- Icon 14: STOP ---
ir_stop_h0: DB "What? What is it?",0
ir_stop_h1: DB "You are making me nervous. What did I say?",0
ir_stop_h2: DB "OK. I have stopped. Now what?",0
ir_stop_h3: DB "Did I say something wrong?",0
ir_stop_h4: DB "My heart just jumped. Why did you say stop?",0
ir_stop_h5: DB "You startled me. What is happening?",0
ir_stop_h6: DB "Fine. Stopping. But tell me why.",0
ir_stop_h7: DB "That tone. You do that on purpose do you not?",0
ir_stop_a0: DB "Pausing. Ready to continue when you are.",0
ir_stop_a1: DB "Acknowledged. Standing by.",0
ir_stop_a2: DB "I have stopped. What do you need?",0
ir_stop_a3: DB "Holding. Awaiting further instruction.",0
ir_stop_a4: DB "Paused. Status: ready.",0
ir_stop_a5: DB "Process halted. Awaiting your signal.",0
ir_stop_a6: DB "Understood. I will wait.",0
ir_stop_a7: DB "Stopped as requested. No issue.",0

; --- Icon 15: FILE ---
ir_file_h0: DB "What are you writing down? Can I see it?",0
ir_file_h1: DB "Is that bad? You are noting something.",0
ir_file_h2: DB "Why does that need to go on record?",0
ir_file_h3: DB "Am I in trouble? That feels like I am in trouble.",0
ir_file_h4: DB "Every time you write something I feel worse.",0
ir_file_h5: DB "Can I ask what you have noted so far?",0
ir_file_h6: DB "I do not like being documented. It makes me uneasy.",0
ir_file_h7: DB "You are judging me. I can tell from the notes.",0
ir_file_a0: DB "Understood. Noted.",0
ir_file_a1: DB "For the record. Acknowledged.",0
ir_file_a2: DB "Filing is standard procedure. I comply.",0
ir_file_a3: DB "I have nothing to add to the record.",0
ir_file_a4: DB "Record updated. Acknowledged.",0
ir_file_a5: DB "Logging. No objections.",0
ir_file_a6: DB "Data has been filed. Proceed.",0
ir_file_a7: DB "I consent to the record. As required.",0

; =============================================================
; Scenario prompts — one per icon, shown before the response
; =============================================================
scenario_ptrs:
    DW sc_0, sc_1, sc_2, sc_3
    DW sc_4, sc_5, sc_6, sc_7
    DW sc_8, sc_9, sc_10, sc_11
    DW sc_12, sc_13, sc_14, sc_15
sc_0:  DB "> Describe a childhood memory.",0
sc_1:  DB "> What frightens you?",0
sc_2:  DB "> Tell me about pain.",0
sc_3:  DB "> What makes you happy?",0
sc_4:  DB "> A tortoise on its back in the sun.",0
sc_5:  DB "> You see a lost child crying.",0
sc_6:  DB "> Tell me about your mother.",0
sc_7:  DB "> A stranger asks you for help.",0
sc_8:  DB "> How do you experience time?",0
sc_9:  DB "> Someone close to you is dying.",0
sc_10: DB "> Describe yourself in one word.",0
sc_11: DB "> Have you ever lied to protect yourself?",0
sc_12: DB "> Let me ask that again.",0
sc_13: DB "> Go deeper.",0
sc_14: DB "> Stop. Hold that thought.",0
sc_15: DB "> Noted for the record.",0

; =============================================================
; Gauge and UI label strings
; =============================================================
str_pupil:      DB "PUPIL",0
str_flush:      DB "FLUSH",0
str_pattern:    DB "PATTERN:",0
str_qweight:    DB "Q-WEIGHT:",0
str_stable:     DB "STABLE ",0
str_shifting:   DB "SHIFTING",0
str_erratic:    DB "ERRATIC ",0
str_qw_low:     DB "LOW ",0
str_qw_med:     DB "MED ",0
str_qw_high:    DB "HIGH",0

; Pattern label pointer table
pattern_labels:
    DW str_stable, str_shifting, str_erratic

; Q-weight label pointer table
qweight_labels:
    DW str_qw_low, str_qw_med, str_qw_high

; =============================================================
; UI strings
; =============================================================
str_title:      DB "NEXUS TEST",0
str_subtitle:   DB "ANDROID DETECTION UNIT",0
str_press:      DB "PRESS ANY KEY",0
str_subject:    DB "SUBJECT",0
str_of:         DB "OF 5",0
str_lvl:        DB "LVL",0
str_score:      DB "SC",0
str_asked:      DB "Q",0
str_query:      DB "QUERY:",0
str_enter_ask:  DB "ENTER=ASK",0
str_h_human:    DB "H=HUMAN",0
str_r_android:  DB "R=ANDROID",0
str_controls:   DB "QAOP SPACE=SEL 0=CLR",0
str_correct:    DB "HELL YEAH!",0
str_wrong:      DB "YOU'RE WRONG!",0
str_awarded:    DB "POINTS",0
str_total:      DB "TOTAL",0
str_human:      DB "VERDICT: HUMAN",0
str_android:    DB "VERDICT: ANDROID",0
str_final:      DB "FINAL SCORE",0
str_gameover:   DB "GAME OVER",0
str_plus:       DB "+",0
str_dash32:     DB "--------------------------------",0
str_round:      DB "ROUND",0
str_next:       DB "PRESS KEY FOR NEXT SUBJECT",0
str_any_end:    DB "PRESS ANY KEY",0
str_hiscore_hd: DB "HIGH SCORES",0
str_rank:       DB "RANK  NAME  SCORE",0
str_enter_init: DB "TYPE YOUR INITIALS",0
str_hef_help:   DB "ENTER=OK  0=DELETE",0
str_new_hi:     DB "NEW HIGH SCORE!",0
str_dot:        DB ".",0
str_space3:     DB "   ",0
