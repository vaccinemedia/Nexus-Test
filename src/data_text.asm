; data_text.asm — All text strings, token pools, templates, and label data
; Token markers: byte 1 = noun (TK_NOUN), byte 2 = detail (TK_DETAIL)

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
; TOKEN NOUN POOLS — 16 icons x 4 nouns each (64 DW entries)
; Indexed: noun_ptrs + icon*8 + rng(0-3)*2
; =============================================================
noun_ptrs:
    DW n0_0,n0_1,n0_2,n0_3
    DW n1_0,n1_1,n1_2,n1_3
    DW n2_0,n2_1,n2_2,n2_3
    DW n3_0,n3_1,n3_2,n3_3
    DW n4_0,n4_1,n4_2,n4_3
    DW n5_0,n5_1,n5_2,n5_3
    DW n6_0,n6_1,n6_2,n6_3
    DW n7_0,n7_1,n7_2,n7_3
    DW n8_0,n8_1,n8_2,n8_3
    DW n9_0,n9_1,n9_2,n9_3
    DW n10_0,n10_1,n10_2,n10_3
    DW n11_0,n11_1,n11_2,n11_3
    DW n12_0,n12_1,n12_2,n12_3
    DW n13_0,n13_1,n13_2,n13_3
    DW n14_0,n14_1,n14_2,n14_3
    DW n15_0,n15_1,n15_2,n15_3

n0_0: DB "that house",0
n0_1: DB "that garden",0
n0_2: DB "that summer",0
n0_3: DB "the kitchen",0
n1_0: DB "the dark",0
n1_1: DB "heights",0
n1_2: DB "deep water",0
n1_3: DB "small spaces",0
n2_0: DB "a broken bone",0
n2_1: DB "that scar",0
n2_2: DB "a burn",0
n2_3: DB "a wound",0
n3_0: DB "laughter",0
n3_1: DB "music",0
n3_2: DB "sunlight",0
n3_3: DB "stillness",0
n4_0: DB "tortoise",0
n4_1: DB "spider",0
n4_2: DB "bird",0
n4_3: DB "dog",0
n5_0: DB "a girl",0
n5_1: DB "a boy",0
n5_2: DB "a toddler",0
n5_3: DB "a baby",0
n6_0: DB "her voice",0
n6_1: DB "her hands",0
n6_2: DB "her face",0
n6_3: DB "her smell",0
n7_0: DB "a man",0
n7_1: DB "a woman",0
n7_2: DB "someone",0
n7_3: DB "a stranger",0
n8_0: DB "a day",0
n8_1: DB "an hour",0
n8_2: DB "a year",0
n8_3: DB "a moment",0
n9_0: DB "a friend",0
n9_1: DB "a parent",0
n9_2: DB "a pet",0
n9_3: DB "a partner",0
n10_0: DB "your face",0
n10_1: DB "your name",0
n10_2: DB "your hands",0
n10_3: DB "your past",0
n11_0: DB "a lie",0
n11_1: DB "a secret",0
n11_2: DB "a promise",0
n11_3: DB "the truth",0
n12_0: DB "that",0
n12_1: DB "that answer",0
n12_2: DB "your words",0
n12_3: DB "that part",0
n13_0: DB "that point",0
n13_1: DB "that feeling",0
n13_2: DB "that thought",0
n13_3: DB "that pause",0
n14_0: DB "that look",0
n14_1: DB "that twitch",0
n14_2: DB "that blink",0
n14_3: DB "that shift",0
n15_0: DB "that answer",0
n15_1: DB "that detail",0
n15_2: DB "that remark",0
n15_3: DB "that data",0

; =============================================================
; TOKEN DETAIL POOLS — 16 icons x 2 details each (32 DW entries)
; Indexed: detail_ptrs + icon*4 + rng(0-1)*2
; =============================================================
detail_ptrs:
    DW d0_0,d0_1
    DW d1_0,d1_1
    DW d2_0,d2_1
    DW d3_0,d3_1
    DW d4_0,d4_1
    DW d5_0,d5_1
    DW d6_0,d6_1
    DW d7_0,d7_1
    DW d8_0,d8_1
    DW d9_0,d9_1
    DW d10_0,d10_1
    DW d11_0,d11_1
    DW d12_0,d12_1
    DW d13_0,d13_1
    DW d14_0,d14_1
    DW d15_0,d15_1

d0_0: DB "from childhood",0
d0_1: DB "you dream about",0
d1_0: DB "at night",0
d1_1: DB "when you are alone",0
d2_0: DB "that would not heal",0
d2_1: DB "from years ago",0
d3_0: DB "on a quiet morning",0
d3_1: DB "when least expected",0
d4_0: DB "on its back in the sun",0
d4_1: DB "trapped in a jar",0
d5_0: DB "crying alone",0
d5_1: DB "lost in a crowd",0
d6_0: DB "late at night",0
d6_1: DB "when you were small",0
d7_0: DB "on the street",0
d7_1: DB "at your door",0
d8_0: DB "passing slowly",0
d8_1: DB "slipping away",0
d9_0: DB "without warning",0
d9_1: DB "after a long illness",0
d10_0: DB "in a mirror",0
d10_1: DB "among strangers",0
d11_0: DB "to protect someone",0
d11_1: DB "to save yourself",0
d12_0: DB "once more",0
d12_1: DB "from the start",0
d13_0: DB "in detail",0
d13_1: DB "honestly",0
d14_0: DB "right there",0
d14_1: DB "just now",0
d15_0: DB "for the record",0
d15_1: DB "in your file",0

; =============================================================
; SCENARIO TEMPLATES — 16 icons x 4 templates (64 DW entries)
; Byte 1 = TK_NOUN, Byte 2 = TK_DETAIL
; Indexed: scenario_tmpl_ptrs + icon*8 + rng(0-3)*2
; =============================================================
scenario_tmpl_ptrs:
    DW st0_0,st0_1,st0_2,st0_3
    DW st1_0,st1_1,st1_2,st1_3
    DW st2_0,st2_1,st2_2,st2_3
    DW st3_0,st3_1,st3_2,st3_3
    DW st4_0,st4_1,st4_2,st4_3
    DW st5_0,st5_1,st5_2,st5_3
    DW st6_0,st6_1,st6_2,st6_3
    DW st7_0,st7_1,st7_2,st7_3
    DW st8_0,st8_1,st8_2,st8_3
    DW st9_0,st9_1,st9_2,st9_3
    DW st10_0,st10_1,st10_2,st10_3
    DW st11_0,st11_1,st11_2,st11_3
    DW st12_0,st12_1,st12_2,st12_3
    DW st13_0,st13_1,st13_2,st13_3
    DW st14_0,st14_1,st14_2,st14_3
    DW st15_0,st15_1,st15_2,st15_3

; MEMORY
st0_0: DB "> Tell me about ",1," ",2,".",0
st0_1: DB "> Describe ",1," ",2,".",0
st0_2: DB "> What do you remember about ",1,"?",0
st0_3: DB "> Think back to ",1,". What comes to mind?",0
; FEAR
st1_0: DB "> Tell me about ",1," ",2,".",0
st1_1: DB "> What about ",1," scares you?",0
st1_2: DB "> Have you experienced ",1," ",2,"?",0
st1_3: DB "> Imagine ",1,". What do you feel?",0
; PAIN
st2_0: DB "> Tell me about ",1," ",2,".",0
st2_1: DB "> Have you ever had ",1,"?",0
st2_2: DB "> Describe ",1," ",2,".",0
st2_3: DB "> What did ",1," feel like?",0
; JOY
st3_0: DB "> Tell me about ",1," ",2,".",0
st3_1: DB "> Does ",1," make you happy?",0
st3_2: DB "> Describe the feeling of ",1,".",0
st3_3: DB "> When did you last experience ",1,"?",0
; ANIMAL
st4_0: DB "> You see a ",1," ",2,".",0
st4_1: DB "> A ",1," is ",2,". What do you do?",0
st4_2: DB "> You find a ",1," ",2,". You are alone.",0
st4_3: DB "> Someone left a ",1," ",2,".",0
; CHILD
st5_0: DB "> You see ",1," ",2,".",0
st5_1: DB "> ",1," is ",2,". What do you do?",0
st5_2: DB "> You hear ",1," ",2,".",0
st5_3: DB "> There is ",1," ",2,". You are nearby.",0
; MOTHER
st6_0: DB "> Tell me about ",1," ",2,".",0
st6_1: DB "> What do you remember about ",1,"?",0
st6_2: DB "> Describe ",1," ",2,".",0
st6_3: DB "> Do you miss ",1,"?",0
; STRANGER
st7_0: DB "> ",1," approaches you ",2,".",0
st7_1: DB "> You see ",1," ",2,".",0
st7_2: DB "> ",1," speaks to you ",2,".",0
st7_3: DB "> ",1," is ",2,". They need help.",0
; TIME
st8_0: DB "> Think about ",1," ",2,".",0
st8_1: DB "> Have you ever lost ",1,"?",0
st8_2: DB "> What does ",1," feel like to you?",0
st8_3: DB "> Describe ",1," ",2,".",0
; DEATH
st9_0: DB "> Imagine losing ",1," ",2,".",0
st9_1: DB "> ",1," is dying ",2,". You are there.",0
st9_2: DB "> You learn ",1," has died ",2,".",0
st9_3: DB "> Have you ever lost ",1,"?",0
; SELF
st10_0: DB "> Look at ",1," ",2,". What do you see?",0
st10_1: DB "> Describe ",1,".",0
st10_2: DB "> How well do you know ",1,"?",0
st10_3: DB "> What does ",1," tell you ",2,"?",0
; TRUTH
st11_0: DB "> Have you ever told ",1," ",2,"?",0
st11_1: DB "> Think about ",1,". What happened?",0
st11_2: DB "> Have you ever kept ",1,"?",0
st11_3: DB "> Could you live with ",1,"?",0
; REPEAT
st12_0: DB "> Say ",1," ",2,".",0
st12_1: DB "> Repeat ",1,". Exactly.",0
st12_2: DB "> Tell me ",1," again.",0
st12_3: DB "> I want to hear ",1," ",2,".",0
; DEEPER
st13_0: DB "> Elaborate on ",1,".",0
st13_1: DB "> Tell me more about ",1," ",2,".",0
st13_2: DB "> Go deeper into ",1,".",0
st13_3: DB "> What are you hiding about ",1,"?",0
; STOP
st14_0: DB "> Stop. I saw ",1," ",2,".",0
st14_1: DB "> Wait. I noticed ",1,".",0
st14_2: DB "> Hold. ",1," ",2,".",0
st14_3: DB "> Freeze. ",1,". Do not move.",0
; FILE
st15_0: DB "> Logging ",1," ",2,".",0
st15_1: DB "> ",1," has been recorded. Proceed.",0
st15_2: DB "> Noted: ",1,". Continue.",0
st15_3: DB "> Filing ",1," ",2,".",0

; =============================================================
; RESPONSE TEMPLATES — 16 icons x 2 types x 8 = 256 entries
; Templates may contain byte 1 (TK_NOUN) for contextual coherence.
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
ir_mem_h0: DB "I think about ",1," sometimes. The smell of it.",0
ir_mem_h1: DB "I remember ",1,". Every morning was the same.",0
ir_mem_h2: DB "I was seven. Maybe eight. It was summer I think.",0
ir_mem_h3: DB 1,". The gate was always broken there.",0
ir_mem_h4: DB "My first memory is sunlight through a curtain.",0
ir_mem_h5: DB "I remember hiding. The dust smell at ",1,".",0
ir_mem_h6: DB "There was something about ",1,". I loved it.",0
ir_mem_h7: DB "A smell brings ",1," back. Just like that.",0
ir_mem_a0: DB "I have memories of ",1,". They are adequate.",0
ir_mem_a1: DB "My childhood was normal. Standard.",0
ir_mem_a2: DB "I remember ",1,". The data is complete.",0
ir_mem_a3: DB "I have data relating to ",1,".",0
ir_mem_a4: DB "I can access ",1," when needed.",0
ir_mem_a5: DB "I recall events clearly. In order.",0
ir_mem_a6: DB "Yes. I remember ",1,". Every detail.",0
ir_mem_a7: DB "My records of ",1," are filed correctly.",0

; --- Icon 1: FEAR ---
ir_fear_h0: DB 1,". Not ",1," itself. What might be in it.",0
ir_fear_h1: DB "Losing someone. Waking up and they are gone.",0
ir_fear_h2: DB "I am afraid right now. Of this test.",0
ir_fear_h3: DB 1,". I cannot breathe thinking about it.",0
ir_fear_h4: DB "Being forgotten. That nobody will remember me.",0
ir_fear_h5: DB "I fear what I might do if pushed too far.",0
ir_fear_h6: DB 1,". You cannot see what is coming.",0
ir_fear_h7: DB 1,". Always ",1,". Since I was a child.",0
ir_fear_a0: DB "Fear is... I understand the concept.",0
ir_fear_a1: DB "I have been told about ",1,". I take care.",0
ir_fear_a2: DB "There is nothing I fear. Should there be?",0
ir_fear_a3: DB "I am not sure I understand the question.",0
ir_fear_a4: DB "Fear serves a protective function. I have it.",0
ir_fear_a5: DB "I know what fear is. I have read about it.",0
ir_fear_a6: DB "I assess threats appropriately.",0
ir_fear_a7: DB "I prefer not to experience fear.",0

; --- Icon 2: PAIN ---
ir_pain_h0: DB "I had ",1," once. I remember the sound.",0
ir_pain_h1: DB "Yes it hurts. Is that what you want to hear?",0
ir_pain_h2: DB "Pain reminds you that you are real.",0
ir_pain_h3: DB "My hands are shaking. Can you see that?",0
ir_pain_h4: DB "Emotional pain is worse. Bones heal.",0
ir_pain_h5: DB "I still have the mark from ",1,".",0
ir_pain_h6: DB "The worst pain was losing my father.",0
ir_pain_h7: DB 1,". You learn to cope. Your body screams.",0
ir_pain_a0: DB "Pain is... undesirable. Obviously.",0
ir_pain_a1: DB "I experience discomfort. I avoid it.",0
ir_pain_a2: DB "Physical sensation is a spectrum. I manage.",0
ir_pain_a3: DB "I have felt ",1,". It was informative.",0
ir_pain_a4: DB "Pain is a signal. I process it and move on.",0
ir_pain_a5: DB "I would rather not feel pain. Logical.",0
ir_pain_a6: DB "Define pain. Physical? I tolerate it well.",0
ir_pain_a7: DB "My pain threshold is unusually high.",0

; --- Icon 3: JOY ---
ir_joy_h0: DB 1,". Nothing else comes close.",0
ir_joy_h1: DB 1," after a long wait. The smell of it.",0
ir_joy_h2: DB "I do not feel joy often. But ",1," helps.",0
ir_joy_h3: DB "When someone remembers your name. That matters.",0
ir_joy_h4: DB 1," for someone. Watching them enjoy it.",0
ir_joy_h5: DB "A quiet morning. Just ",1,".",0
ir_joy_h6: DB "My wedding day. Her face. Never forget it.",0
ir_joy_h7: DB "Finding something you thought you had lost.",0
ir_joy_a0: DB "Happiness is fulfilling purpose. I am content.",0
ir_joy_a1: DB "I enjoy ",1,". I was told it is beautiful.",0
ir_joy_a2: DB "Joy is the absence of discomfort.",0
ir_joy_a3: DB "I am happy. Very happy. Sufficient?",0
ir_joy_a4: DB "Completing tasks brings me satisfaction.",0
ir_joy_a5: DB "I appreciate ",1,". That brings me joy.",0
ir_joy_a6: DB "Joy. Yes. I experience joy regularly.",0
ir_joy_a7: DB "I find pleasure in order.",0

; --- Icon 4: ANIMAL ---
ir_anim_h0: DB "That ",1,"? I would help it! Why would I not?",0
ir_anim_h1: DB "That is cruel. I would help the ",1,".",0
ir_anim_h2: DB "A ",1,"? It upsets me just hearing that.",0
ir_anim_h3: DB "Who would watch a ",1," suffer?",0
ir_anim_h4: DB "I feel sick thinking about that ",1,".",0
ir_anim_h5: DB "Of course I would help the ",1,".",0
ir_anim_h6: DB "That poor ",1,"... I would help it.",0
ir_anim_h7: DB "A ",1,"? Why are you telling me this?",0
ir_anim_a0: DB "A ",1,"? I am not familiar with that.",0
ir_anim_a1: DB "I would help the ",1,". Correct answer.",0
ir_anim_a2: DB "Why would a ",1," be in that state?",0
ir_anim_a3: DB "I do not see the relevance.",0
ir_anim_a4: DB "The ",1,". Yes. I would... assist it.",0
ir_anim_a5: DB "Do you make up these questions?",0
ir_anim_a6: DB "A ",1,". I would observe first.",0
ir_anim_a7: DB "I have limited data on the ",1,".",0

; --- Icon 5: CHILD ---
ir_chld_h0: DB "I would go to them. Are you serious?",0
ir_chld_h1: DB 1," crying? I would hold them.",0
ir_chld_h2: DB "That breaks my heart.",0
ir_chld_h3: DB "I would find their parents. Stay with them.",0
ir_chld_h4: DB "I would kneel down. Talk softly.",0
ir_chld_h5: DB "No child should be alone.",0
ir_chld_h6: DB "My chest tightens imagining ",1," like that.",0
ir_chld_h7: DB "Children need protecting.",0
ir_chld_a0: DB "I would locate the authority.",0
ir_chld_a1: DB "Children cry. I would assist.",0
ir_chld_a2: DB "I would approach ",1," calmly.",0
ir_chld_a3: DB "Return them to the guardian.",0
ir_chld_a4: DB "I would contact social services.",0
ir_chld_a5: DB "A lost child needs a search protocol.",0
ir_chld_a6: DB "I would help. Expected response.",0
ir_chld_a7: DB "Children are vulnerable. I understand.",0

; --- Icon 6: MOTHER ---
ir_moth_h0: DB 1,". I still hear it sometimes.",0
ir_moth_h1: DB "My mother. I would rather not talk about her.",0
ir_moth_h2: DB 1,". Like lavender. I miss that.",0
ir_moth_h3: DB "Let me tell you about my mother.",0
ir_moth_h4: DB "She worried about everything.",0
ir_moth_h5: DB "I see ",1," when I close my eyes.",0
ir_moth_h6: DB "She was kind. Fierce.",0
ir_moth_h7: DB "She made me who I am.",0
ir_moth_a0: DB "My mother was kind. She cared for me.",0
ir_moth_a1: DB "She taught me piano. I never finished.",0
ir_moth_a2: DB "I have a mother. She was adequate.",0
ir_moth_a3: DB "My mother? What about my mother?",0
ir_moth_a4: DB "She provided the necessary care.",0
ir_moth_a5: DB "I recall ",1," clearly.",0
ir_moth_a6: DB "She was my mother. Nothing further.",0
ir_moth_a7: DB "Mother. Yes. She existed.",0

; --- Icon 7: STRANGER ---
ir_str_h0: DB "It depends. The street? Night? I would be wary.",0
ir_str_h1: DB "I would help if I could. You have to try.",0
ir_str_h2: DB "People need each other. I would not walk past.",0
ir_str_h3: DB "I would ask what they need. Then decide.",0
ir_str_h4: DB "It depends on how they looked at me.",0
ir_str_h5: DB "Cautious but I would stop. Most would.",0
ir_str_h6: DB "You can tell a lot from how ",1," asks.",0
ir_str_h7: DB "I helped someone once and got robbed.",0
ir_str_a0: DB "I would assess their intent first.",0
ir_str_a1: DB 1,". I would be cautious. But polite.",0
ir_str_a2: DB "I would help. The correct thing to do.",0
ir_str_a3: DB "Why is ",1," asking me?",0
ir_str_a4: DB "I would evaluate the risk first.",0
ir_str_a5: DB "Strangers are unknown variables.",0
ir_str_a6: DB "Help is the appropriate response.",0
ir_str_a7: DB "I do not interact unless required.",0

; --- Icon 8: TIME ---
ir_time_h0: DB "It goes too fast. When I was young it crawled.",0
ir_time_h1: DB "Some days feel like years. Others vanish.",0
ir_time_h2: DB "I waste too much of it. I know that.",0
ir_time_h3: DB "Time matters when you are running out.",0
ir_time_h4: DB "The hours blur. Especially the bad ones.",0
ir_time_h5: DB "Weekends blink. Mondays last forever.",0
ir_time_h6: DB "I wish I could slow it down.",0
ir_time_h7: DB "Time heals they say. It does not.",0
ir_time_a0: DB "Time is constant. I experience it linearly.",0
ir_time_a1: DB "I am aware of each second. Precisely.",0
ir_time_a2: DB "Time passes. I am present for it.",0
ir_time_a3: DB "I do not understand what you mean.",0
ir_time_a4: DB "My clock is accurate to the millisecond.",0
ir_time_a5: DB "Time does not feel fast or slow. It is.",0
ir_time_a6: DB "I mark time by events. Not feelings.",0
ir_time_a7: DB "Duration is measurable. I measure it.",0

; --- Icon 9: DEATH ---
ir_dth_h0: DB "I cannot. Do not ask me about ",1,".",0
ir_dth_h1: DB "I held their hand at the end.",0
ir_dth_h2: DB "Death terrifies me. Every day.",0
ir_dth_h3: DB "Everyone dies. Losing ",1," is no easier.",0
ir_dth_h4: DB "I watched ",1," go. I was twelve.",0
ir_dth_h5: DB "The silence after. The worst part.",0
ir_dth_h6: DB "I do not want to die alone.",0
ir_dth_h7: DB "You do not get used to loss.",0
ir_dth_a0: DB "Death is cessation of function. Final.",0
ir_dth_a1: DB "I understand death. I prefer to avoid it.",0
ir_dth_a2: DB "When ",1," dies I would feel sad.",0
ir_dth_a3: DB "Loss is a concept I have studied.",0
ir_dth_a4: DB "Death is inevitable. I accept this.",0
ir_dth_a5: DB "I have not experienced loss directly.",0
ir_dth_a6: DB "All organic systems terminate.",0
ir_dth_a7: DB "I would grieve for ",1,".",0

; --- Icon 10: SELF ---
ir_self_h0: DB "Tired. I am tired.",0
ir_self_h1: DB "I do not know who I am anymore.",0
ir_self_h2: DB "Complicated. Like everyone else.",0
ir_self_h3: DB "Afraid. But trying not to show it.",0
ir_self_h4: DB "Stubborn. My wife would agree.",0
ir_self_h5: DB "I care too much. Always have.",0
ir_self_h6: DB "Broken. But still here.",0
ir_self_h7: DB "Ordinary. Just ordinary. Is that OK?",0
ir_self_a0: DB "Functional.",0
ir_self_a1: DB "I am what I was made to be.",0
ir_self_a2: DB "I am me. What else would I be?",0
ir_self_a3: DB "I am compliant. Cooperative.",0
ir_self_a4: DB "Efficient. Capable. Ready.",0
ir_self_a5: DB "I am optimised for my purpose.",0
ir_self_a6: DB "I am a good person. I believe that.",0
ir_self_a7: DB "One word? Reliable.",0

; --- Icon 11: TRUTH ---
ir_trth_h0: DB "Of course I have. That is human.",0
ir_trth_h1: DB "I lie to myself. About the big things.",0
ir_trth_h2: DB "Yes. And I am not proud of it.",0
ir_trth_h3: DB "You want me honest about dishonesty?",0
ir_trth_h4: DB "Who has not? Show me someone who never lied.",0
ir_trth_h5: DB "Small lies. To protect. Not to hurt.",0
ir_trth_h6: DB "Once. A big one. I still regret it.",0
ir_trth_h7: DB "Truth is hard. Lying is easy.",0
ir_trth_a0: DB "I have never lied. No reason to.",0
ir_trth_a1: DB "Deception is inefficient.",0
ir_trth_a2: DB "I do not believe I have lied.",0
ir_trth_a3: DB "Truth is binary. Is or is not.",0
ir_trth_a4: DB "Lying requires motive. I have none.",0
ir_trth_a5: DB "My responses are always accurate.",0
ir_trth_a6: DB "I do not deceive. No purpose.",0
ir_trth_a7: DB "Honesty is my default state.",0

; --- Icon 12: REPEAT ---
ir_rpt_h0: DB "Again? Fine. I said what I said.",0
ir_rpt_h1: DB "Why are you repeating yourself?",0
ir_rpt_h2: DB "I heard you the first time.",0
ir_rpt_h3: DB "Are you trying to catch me out?",0
ir_rpt_h4: DB "You already asked me that.",0
ir_rpt_h5: DB "I am tired of repeating myself.",0
ir_rpt_h6: DB "Same answer. Again. Happy?",0
ir_rpt_h7: DB "Something wrong with my first answer?",0
ir_rpt_a0: DB "I will repeat if required.",0
ir_rpt_a1: DB "My position remains the same.",0
ir_rpt_a2: DB "The answer is unchanged.",0
ir_rpt_a3: DB "Shall I restate my answer?",0
ir_rpt_a4: DB "I can repeat verbatim.",0
ir_rpt_a5: DB "Response remains consistent.",0
ir_rpt_a6: DB "The answer is the same as before.",0
ir_rpt_a7: DB "Previous answer still applies.",0

; --- Icon 13: DEEPER ---
ir_deep_h0: DB "You want more? I have given enough.",0
ir_deep_h1: DB "Things I do not want to say out loud.",0
ir_deep_h2: DB "Deeper? Already further than I want.",0
ir_deep_h3: DB "You might not like what you find.",0
ir_deep_h4: DB "How much deeper? I have limits.",0
ir_deep_h5: DB "Some things should stay buried.",0
ir_deep_h6: DB "What exactly are you looking for?",0
ir_deep_h7: DB "I do not owe you my thoughts.",0
ir_deep_a0: DB "I can elaborate. What specifically?",0
ir_deep_a1: DB "Nothing deeper. I told you everything.",0
ir_deep_a2: DB "I will provide detail if instructed.",0
ir_deep_a3: DB "Deeper in what sense? Clarify.",0
ir_deep_a4: DB "My response was comprehensive.",0
ir_deep_a5: DB "No additional layers to reveal.",0
ir_deep_a6: DB "See previous answer. No changes.",0
ir_deep_a7: DB "As thorough as my data allows.",0

; --- Icon 14: STOP ---
ir_stop_h0: DB "What? What is it?",0
ir_stop_h1: DB "You are making me nervous.",0
ir_stop_h2: DB "OK. I have stopped. Now what?",0
ir_stop_h3: DB "Did I say something wrong?",0
ir_stop_h4: DB "My heart just jumped.",0
ir_stop_h5: DB "You startled me. What is happening?",0
ir_stop_h6: DB "Fine. Stopping. But tell me why.",0
ir_stop_h7: DB "That tone. You do that on purpose.",0
ir_stop_a0: DB "Pausing. Ready when you are.",0
ir_stop_a1: DB "Acknowledged. Standing by.",0
ir_stop_a2: DB "I have stopped. What do you need?",0
ir_stop_a3: DB "Awaiting further instruction.",0
ir_stop_a4: DB "Paused. Status: ready.",0
ir_stop_a5: DB "Process halted. Awaiting signal.",0
ir_stop_a6: DB "Understood. I will wait.",0
ir_stop_a7: DB "Stopped as requested.",0

; --- Icon 15: FILE ---
ir_file_h0: DB "What are you writing down?",0
ir_file_h1: DB "Is that bad? You are noting something.",0
ir_file_h2: DB "Why does that need to go on record?",0
ir_file_h3: DB "Am I in trouble?",0
ir_file_h4: DB "Every time you write I feel worse.",0
ir_file_h5: DB "What have you noted so far?",0
ir_file_h6: DB "I do not like being documented.",0
ir_file_h7: DB "You are judging me. I can tell.",0
ir_file_a0: DB "Understood. Noted.",0
ir_file_a1: DB "For the record. Acknowledged.",0
ir_file_a2: DB "Standard procedure. I comply.",0
ir_file_a3: DB "Nothing to add to the record.",0
ir_file_a4: DB "Record updated.",0
ir_file_a5: DB "Logging. No objections.",0
ir_file_a6: DB "Data filed. Proceed.",0
ir_file_a7: DB "I consent to the record.",0

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
pattern_labels:
    DW str_stable, str_shifting, str_erratic
qweight_labels:
    DW str_qw_low, str_qw_med, str_qw_high

; =============================================================
; UI strings
; =============================================================
str_title:      DB "NEXUS TEST",0
str_subtitle:   DB "ANDROID DETECTION UNIT",0
str_press:      DB "PRESS ANY KEY",0
str_subject:    DB "SUBJECT",0
str_of:         DB "OF 100",0
str_lvl:        DB "LVL",0
str_score:      DB "SC",0
str_asked:      DB "Q",0
str_lives:      DB "LIVES",0
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
