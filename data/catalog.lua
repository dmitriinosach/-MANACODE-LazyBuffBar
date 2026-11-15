local _, ns = ...
ns.catalogCodes = {
    kind = { c = "cd", a = "act", b = "buff", r = "raid", f = "form", p = "proc", d = "debuff", x = "consumable", g = "gear" },
    where = { s = "self", t = "target", g = "group", p = "pet", a = "ally" },
    tag = { a = "ability", t = "talent", p = "proc", d = "target", r = "raid", f = "form", x = "consumable", g = "gear", b = "boss", v = "pvp", o = "otherClass", w = "widget", n = "perm", u = "up", h = "hidden", l = "onAlly" },
    src = { b = "book", t = "talent", s = "spell", i = "item", S = "set", e = "enchant", r = "racial", R = "seen", ["-"] = "unknown" },
    need = { c = "class", t = "tree", S = "set", w = "worn", r = "race", f = "faction", p = "profession", u = "unit" },
    cls = { "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "DEATHKNIGHT", "SHAMAN", "MAGE", "WARLOCK", "DRUID" },
}
ns.catalogDB = [[
64937 g s 1 S830:2 gp sub=set need=c,S830
70845 g s 1 S896:4 gp sub=set need=c,S896
70855 g s 1 S895:2 gp sub=set need=c,S895
20253 d t 1 s20252 ad
20511 d t 1 s5246 ad
57516 p s 1.3 t29594 pt alt=57514 need=c,t
61571 g s 1 S788:4 gp sub=set need=c,S788
23885 p s 1 R p need=c
71 f s 1 b afn rec=prot w=stance need=c
72 c t 1 b adv rec=prot need=c
355 c t 1 b ad rec=prot w=taunt need=c
355 d t 1 b ad
676 c t 1 b adv rec=arms,fury,prot need=c
676 d t 1 b adv
694 c t 1 b ad need=c
694 d t 1 b ad
871 b s 1 b a need=c
871 c s 1 b au rec=prot need=c
1161 c g 1 b ar rec=prot need=c
1161 d t 1 b ad
1680 c s 1 b a rec=fury need=c
1715 d t 1 b adv
1719 b s 1 b av need=c
1719 c s 1 b auv rec=arms,fury need=c
2457 f s 1 b afn rec=arms w=stance need=c
2458 f s 1 b afn rec=fury,arms w=stance need=c
2565 b s 1 b a need=c
2565 c s 1 b au rec=prot need=c
2687 c s 1 b a rec=arms,fury,prot need=c
3411 c a 1 b al rec=arms,fury,prot need=c
5246 c g 1 b arv rec=arms,fury,prot need=c
5246 d t 1 b adv
6552 c t 1 b adv rec=arms,fury need=c
7384 c t 1 b ad need=c
7922 d t 1 s11578 adv
11578 c t 1 b adv alt=100,6178 need=c
12292 b s 1.2 b at need=c
12292 c s 1.2 b atu rec=fury need=c
12323 d t 1.2 b adtv rec=fury
12328 b s 1.1 b at need=c
12328 c s 1.1 b atu rec=arms need=c
12721 d t 1.1 t12867 dt rec=arms need=t
12798 d t 1 b ad
12809 c t 1.3 b adtv rec=prot need=c
12809 d t 1.3 b adtv
12970 p s 1.2 t12974 pt rec=fury alt=12966,12967,12968,12969 need=c,t
12975 c s 1.3 b at rec=prot need=c
12976 b s 1.3 b at need=c
14204 p s 1.2 t13048 pt alt=12880,14201,14202,14203 need=c,t
16491 p s 1.2 t16492 pt alt=16488,16490 need=c,t
18498 d t 1.3 b adv
18499 b s 1 b av need=c
18499 c s 1 b auv rec=fury,arms,prot need=c
20230 b s 1 b av need=c
20230 c s 1 b auv need=c
20252 c t 1 b adv rec=arms,fury need=c
23694 d t 1.1 t23695 dtv need=t
23881 c t 1.2 b adt rec=fury need=c
23920 b s 1 b av need=c
23920 c s 1 b auv rec=prot need=c
29131 b s 1 s2687 a need=c
29801 r g 1.2 t29801 nrt rec=fury need=t
29842 p s 1.1 t29838 ptv alt=29841 need=c,t
30070 d t 1.1 t29859 drt rec=arms,1:arms alt=30069 sub=debuff:dmg need=t
32216 p s 1 s34428 ap need=c
34428 a t 1 b ad need=c
46857 d t 1.1 b adrt rec=arms,1:arms,4,10:cat alt=46856 sub=debuff:bleed
46916 p s 1.2 b ap rec=fury need=c
46924 b s 1.1 b atv need=c
46924 c s 1.1 b atuv rec=arms need=c
46947 r t 1.3 b adrt alt=46946
46968 c t 1.3 b adtv rec=prot need=c
46968 d t 1.3 b adtv
47436 r g 1 b ar rec=arms,fury,prot alt=6673,5242,6192,11549,11550,11551,25289,2048 w=war_shout
47437 d t 1 b adr rec=prot,@tank alt=1160,6190,11554,11555,11556,25202,25203 sub=debuff:atk
47440 r g 1 b ar rec=arms,fury,prot alt=469,47439 w=war_shout
47450 a t 1 b adv alt=78,284,285,1608,11564,11565,11566,11567,25286,29707,30324,47449 w=war_rage need=c
47465 d t 1 b ad rec=arms alt=772,6546,6547,6548,11572,11573,11574,25208,46845
47467 d t 1 b adr rec=prot,1,@tank alt=7386,7405,8380,11596,11597,25225,58567 sub=debuff:armor
47471 a t 1 b ad alt=5308,20658,20660,20661,20662,25234,25236,47470 need=c
47475 a t 1 b ad alt=47474,25242,25241,11605,11604,8820,1464 need=c
47486 c t 1.1 b adt rec=arms alt=12294,21551,21552,21553,25248,30330,47485 need=c
47486 d t 1.1 b adtv
47488 c t 1 b ad rec=prot alt=23922,23923,23924,23925,25258,30356,47487 need=c
47502 c t 1 b ad alt=6343,8198,8204,8205,11580,11581,25264,47501 need=c
47502 d t 1 b adr rec=prot,@tank alt=47501,25264,11581,11580,8205,8204,8198,6343 sub=debuff:atk
50227 p s 1.3 t46953 pt rec=prot need=c,t
50720 r t 1.3 b adrt rec=prot w=war_vigil
52437 p s 1.1 t29724 pt rec=arms need=c,t
55694 b s 1 b a need=c
55694 c s 1 b au rec=arms,fury,prot need=c
56112 d t 1.2 b adtv
57522 p s 1.2 t13048 pt rec=arms alt=57518,57519,57520,57521 need=c,t
57755 c t 1 b ad rec=arms,fury,prot need=c
57823 c t 1 b ad rec=prot alt=6572,6574,7379,11600,11601,25269,25288,30357 need=c
60503 p s 1.1 t56638 pt rec=arms need=c,t
60970 c s 1.2 b atv rec=fury need=c
64382 c t 1 b ad rec=arms alt=64380 w=war_shatter need=c
64382 d t 1 b adr rec=1 sub=debuff:armor w=war_shatter
64850 d t 1.1 t46860 dtv alt=64849 need=t
65156 p s 1.1 t64976 pt need=c,t
60795 g s 2 i40707 gp sub=relic need=c,w
64883 g s 2 S821:4 gp sub=set need=c,S821
70757 g s 2 S899:4 gp sub=set need=c,S899
70760 g s 2 S901:4 gp sub=set need=c,S901
60819 g s 2 i40706 gp sub=relic need=c,w
54203 p a 2.3 t53503 pt need=t
66922 p a 2 R p
498 c s 2 b au rec=holy,prot_tank,prot_dps,ret_agi need=c
642 c s 2 b auv rec=holy,prot_tank,prot_dps,ret_agi need=c
1038 c a 2 b al rec=holy,prot_tank,prot_dps,ret_agi w=threat need=c
1044 c a 2 b alv rec=holy,prot_tank,prot_dps,ret_agi need=c
4987 a a 2 b a need=c
6940 c a 2 b al rec=holy,prot_tank,prot_dps,ret_agi need=c
10278 c a 2 b alv rec=holy,prot_tank,prot_dps,ret_agi alt=5599,1022 need=c
10308 c t 2 b adv rec=holy,prot_tank,prot_dps,ret_agi alt=5589,5588,853 need=c
10308 d t 2 b adv
10326 d t 2 b adv
19746 f g 2 b afnr rec=holy w=auras
19752 c a 2 b a rec=holy,prot_tank,prot_dps,ret_agi need=c
19753 b a 2 s19752 a
20053 p s 2.3 t20057 pt alt=20052,20050 need=c,t
20066 c t 2.3 b adtv rec=ret_agi need=c
20066 d t 2.3 b adtv
20132 p s 2.2 t20135 pt alt=20131,20128 need=c,t
20164 f s 2 b afv w=seals need=c
20165 f s 2 b af w=seals need=c
20166 f s 2 b af rec=holy w=seals need=c
20170 d t 2 s20164 adv
20178 p s 2.2 t20182 pt need=c,t
20184 d t 2 s53407 adv w=judgement
20185 d t 2 s20271 adr rec=holy,prot_tank,prot_dps,ret_agi,2 alt=20271 sub=debuff:judge w=judgement
20186 d t 2 s53408 adr rec=prot_dps,ret_agi,2 alt=53408 sub=debuff:judge w=judgement
20216 c s 2.1 b at rec=holy need=c
20217 r g 2 b ar alt=25898 w=blessings
20236 b a 2.1 t20235 t alt=20233 need=t
20375 f s 2.3 b aft w=seals need=c
20911 r g 2.2 b art alt=25899 w=blessings
21084 f s 2 b af alt=20154 w=seals need=c
25771 d s 2 s498 av
25780 b s 2 b an rec=prot_tank need=c
25898 r g 2 b ar rec=holy,prot_tank,prot_dps,ret_agi alt=20217 w=blessings,want:kings
25899 r g 2.2 b art rec=prot_tank,prot_dps alt=20911 w=blessings,want:sanctuary need=t
26017 d t 2.3 t26016 drt alt=67 sub=debuff:atk need=t
31789 c a 2 b a rec=prot_tank need=c
31790 d t 2 s31789 ad
31801 f s 2 b af rec=prot_tank,prot_dps,ret_agi alt=53736 w=seals need=c,fA
31803 d t 2 s31801 adf rec=prot_tank,prot_dps,ret_agi w=seals need=fA
31821 c s 2.1 b aftu rec=holy w=auras need=c
31834 p s 2.1 t31836 pt rec=holy need=c,t
31842 c s 2.1 b atu rec=holy need=c
31869 r g 2.3 t31869 fhrt rec=ret_agi w=auras need=t
31884 c s 2 b au rec=holy,prot_tank,prot_dps,ret_agi need=c
32223 f g 2 b afnr w=auras
35395 c t 2.3 b adt rec=ret_agi need=c
48782 a a 2 b a rec=holy alt=48781,27136,27135,25292,10329,10328,3472,1042,1026,647,639,635 need=c
48785 a a 2 b a rec=holy alt=48784,27137,19943,19942,19941,19940,19939,19750 need=c
48788 c a 2 b a rec=holy,prot_tank,prot_dps,ret_agi alt=27154,10310,2800,633 need=c
48801 c t 2 b ad rec=ret_agi alt=48800,27138,10314,10313,10312,5615,5614,879 need=c
48806 c t 2 b ad rec=prot_dps,ret_agi alt=48805,27180,24275,24274,24239 need=c
48817 c s 2 b a rec=prot_tank,prot_dps,ret_agi alt=48816,27139,10318,2812 need=c
48817 d t 2 b ad alt=48816,27139,10318,2812
48819 c s 2 b a rec=prot_tank,prot_dps,ret_agi alt=48818,27173,26573,20924,20923,20922,20116 need=c
48825 c a 2.1 b at rec=holy alt=48824,33072,27174,20930,20929,20473 need=c
48827 c t 2.2 b adt rec=prot_tank,prot_dps alt=48826,32700,32699,31935 need=c
48827 d t 2.2 b ad alt=48826,32700,32699,31935
48932 r g 2 b ar alt=48931,27140,25291,19838,19837,19836,19835,19834,19740,48934 w=blessings
48934 r g 2 b ar rec=holy,prot_tank,prot_dps,ret_agi alt=48933,27141,25916,25782,48932 w=blessings,want:ap_flat
48936 r g 2 b ar alt=48935,27142,25290,19854,19853,19852,19850,19742,48938 w=blessings
48938 r g 2 b ar rec=holy,prot_tank,prot_dps,ret_agi alt=48937,27143,25918,25894,48936 w=blessings,want:mp5
48942 f g 2 b afnr rec=prot_tank alt=48941,27149,10293,10292,10291,10290,1032,643,465 w=auras,want:armor
48943 f g 2 b afnr alt=27151,19896,19895,19876 w=auras,want:shadow_prot
48945 f g 2 b afnr alt=27152,19898,19897,19888 w=auras
48947 f g 2 b afnr alt=27153,19900,19899,19891 w=auras
48950 a s 2 b a alt=48949,20773,20772,10324,10322,7328 w=rez need=c
48952 b s 2.2 b at rec=prot_tank alt=48951,27179,20928,20927,20925 sub=shield need=c
48952 c s 2.2 b atu rec=prot_tank,prot_dps alt=48951,27179,20928,20927,20925 sub=shield need=c
53385 c s 2.3 b at rec=ret_agi need=c
53408 c t 2 b ad rec=prot_tank,prot_dps,ret_agi alt=20271,53407 w=judgement need=c
53563 b a 2.1 b at rec=holy w=tank need=c,uTank
53595 c t 2.2 b adt rec=prot_tank,prot_dps need=c
53601 b a 2 b a rec=holy sub=shield w=tank need=c,uTank
53648 r g 2.3 t53648 fhrt w=auras need=t
53659 b a 2.1 t53553 t need=t
53736 f s 2 b af rec=prot_tank,prot_dps,ret_agi alt=31801 w=seals need=c,fH
53742 d t 2 s53736 adf rec=prot_tank,prot_dps,ret_agi w=seals need=fH
54043 f g 2 b afnr rec=prot_dps,ret_agi alt=27150,10301,10300,10299,10298,7294 w=auras
54149 p s 2.1 t53576 pt rec=holy alt=53672 need=c,t
54153 p s 2.1 t54155 pt rec=holy alt=54152,53657,53656,53655 need=c,t
54428 b s 2 b a rec=prot_tank,prot_dps need=c
54428 c s 2 b au rec=holy,ret_agi w=mana need=c
54499 d t 2.3 t20337 drt alt=21183,54498 sub=debuff:crit w=judgement need=t
57669 r g 2.3 t31878 rt rec=3:surv need=t
58597 p a 2 s53601 ap
59578 p s 2.3 t53488 pt rec=ret_agi alt=53489 need=c,t
61411 c t 2 b ad rec=prot_tank,prot_dps alt=53600 need=c
61840 d t 2.3 t53382 dt need=t
62124 c t 2 b ad rec=prot_tank w=taunt need=c
62124 d t 2 b ad
63529 d t 2.2 t53711 dtv need=t
64205 c g 2.2 b alrt rec=holy,prot_tank,prot_dps need=c
66233 d s 2.2 t31852 t need=t
68055 d t 2.2 t53696 drt rec=prot_tank,prot_dps sub=debuff:atk w=judgement need=t
70940 r g 2.2 t53530 rt need=t
64861 g s 3 S838:4 gp sub=set need=c,S838
70728 g s 3 S891:2 gp sub=set need=c,S891
71007 g s 3 S891:4 gp sub=set need=c,S891
1002 b s 3 b a need=c
1462 r g 3 b ar
14308 d t 3 s14311 ad alt=3355
15571 p s 3 s5118 ap need=c
19878 f s 3 b afn need=c
19879 f s 3 b afn need=c
19880 f s 3 b afn need=c
19882 f s 3 b afn need=c
19883 f s 3 b afn need=c
19884 f s 3 b afn need=c
19885 f s 3 b afn need=c
1494 b s 3 R - need=c
1510 b s 3 R - need=c
53434 b p 3 R - need=c
58434 b s 3 R - need=c
62305 b s 3 R - need=c
64494 b p 3 R - need=c
781 c s 3 b av rec=bm,mm,surv need=c
883 a s 3 b a w=pet need=c
982 a s 3 b a w=pet need=c
1543 c t 3 b adv need=c
2641 a s 3 b a w=pet need=c
2974 d t 3 b adv
3034 d t 3 b adv
3043 d t 3 b adv
3045 b s 3 b a need=c
3045 c s 3 b au rec=bm,mm,surv need=c
5116 c t 3 b adv need=c
5116 d t 3 b adv
5118 f s 3 b afn w=aspect need=c
5384 c s 3 b au rec=bm,mm,surv w=threat need=c
6150 p s 3.1 t19556 pt rec=bm,mm,surv need=c,t
6991 c s 3 b a w=pet need=c
13159 f g 3 b afnr w=aspect
13161 f s 3 b afn w=aspect need=c
13163 f s 3 b afn w=aspect need=c
13809 c g 3 b arv need=c
13810 d t 3 - dv
14309 d t 3 s14311 adv
14311 c g 3 b arv rec=bm,mm,surv alt=1499,14310 need=c
14327 c t 3 b adv alt=1513,14326 need=c
14327 d t 3 b adv alt=1513,14326
19263 b s 3 b av need=c
19263 c s 3 b auv rec=bm,mm,surv need=c
19503 c t 3.3 b adtv rec=mm need=c
19503 d t 3.3 b adtv
19506 f g 3.2 b afnrt rec=mm
19574 b p 3.1 b at need=c
19574 c s 3.1 b atu rec=bm need=c
19577 c s 3.1 b atuv rec=bm need=c
19615 p p 3.1 t19625 pt need=c,t
19801 c t 3 b adv rec=bm,mm,surv need=c
20736 c t 3 b ad need=c
20736 d t 3 b ad
23989 c s 3.2 b at rec=mm need=c
24394 d t 3.1 t19577 dtv need=t
24529 f s 3.1 b afnt alt=19579 need=c
27044 f s 3 b afn alt=13165,14318,14319,14320,14321,14322,25296 w=aspect need=c
34026 c s 3 b au rec=bm,mm,surv need=c
34074 f s 3 b afn rec=bm,mm,surv w=aspect need=c
34471 p s 3.1 t34692 pt rec=bm need=c,t
34477 b s 3 b a need=c
34477 c t 3 b adu rec=bm,mm,surv need=c
34490 c t 3.2 b adtv rec=mm need=c
34490 d t 3.2 b adtv
34501 p s 3.3 t34503 pt rec=surv need=c,t
34600 c g 3 b ar need=c
34837 p s 3.3 t34839 pt rec=surv alt=34833,34834,34835,34836 need=c,t
35079 b s 3 - - need=c
35099 p s 3.2 t34949 pt alt=35098 need=c,t
35101 d t 3.2 b adtv
48990 b p 3 b a alt=136,3111,3661,3662,13542,13543,13544,27046,48989 w=pet need=c
48996 c t 3 b ad alt=2973,14260,14261,14262,14263,14264,14265,14266,27014,48995 need=c
48999 c t 3.3 b adtv alt=19306,20909,20910,27067,48998 need=c
48999 d t 3.3 b adtv alt=19306,20909,20910,27067,48998
49001 d t 3 b ad rec=bm,mm,surv alt=1978,13549,13550,13551,13552,13553,13554,13555,25295,27016,49000
49012 c t 3.3 b adtv rec=surv alt=19386,24132,24133,27068,49011 need=c
49012 d t 3.3 b adtv alt=19386,24132,24133,27068,49011
49045 c t 3 b ad rec=bm,surv alt=3044,14281,14282,14283,14284,14285,14286,14287,27019,49044 need=c
49048 c t 3 b ad rec=bm,mm,surv alt=2643,14288,14289,14290,25294,27021,49047 need=c
49050 c t 3.2 b adt rec=mm alt=19434,20900,20901,20902,20903,20904,27065,49049 need=c
49050 d t 3.2 b adtv alt=19434,20900,20901,20902,20903,20904,27065,49049
49054 d t 3 b ad alt=13797,14298,14299,14300,14301,27024,49053
49056 c g 3 b ar alt=13795,14302,14303,14304,14305,27023,49055 need=c
49065 d t 3 b ad alt=13812,14314,14315,27026,49064
49067 c g 3 b ar rec=bm,mm,surv alt=13813,14316,14317,27025,49066 need=c
49071 f g 3 b afnr alt=20043,20190,27045 w=aspect
53209 c t 3.2 b adt rec=mm w=hunter_mm_chimera need=c
53220 p s 3.2 t53224 pt rec=mm need=c,t
53257 p p 3.1 t53260 pt need=c,t
53271 c t 3 b adv rec=bm,mm,surv need=c
53338 d t 3 b adr rec=bm,mm,surv,3,4 alt=1130,14323,14324,14325 sub=debuff:ap
53339 c t 3 b ad alt=1495,14269,14270,14271,36916 need=c
54216 b a 3 - v
56453 p s 3.3 t56344 pt rec=surv w=hunter_surv_es need=c,t
58882 p s 3.2 t53232 pt alt=56654 need=c,t
60053 c t 3.3 b adt rec=surv alt=53301,60051,60052 w=hunter_surv_es need=c
60053 d t 3.3 b ad alt=53301,60051,60052
60192 c t 3 b adv alt=60202 need=c
60210 d t 3 b adv
61006 c t 3 b ad rec=bm,mm,surv alt=53351,61005 need=c
61847 f s 3 b afn rec=bm,mm,surv alt=61846 w=aspect need=c
62757 c s 3 b au w=pet need=c
63468 d t 3.2 t53238 dt rec=mm need=t
63672 c t 3.3 b adt alt=63671,63670,63669,63668,3674 need=c
63672 d t 3.3 b adt rec=surv alt=63671,63670,63669,63668,3674
64420 p s 3.3 t53304 pt rec=surv alt=64418,64419 need=c,t
64804 d t 3.3 b adtv alt=64803,19185
75447 r g 3.1 t34460 nrt rec=bm alt=75446,75593 w=want:dmg_pct need=t
67210 g s 4 S857:2 gp sub=set need=c,S857,S858
14143 p s 4.1 t14148 pt need=c,t
26888 p s 4 s26889 ap alt=11329,11327 need=c
52915 p s 4.1 t51629 pt alt=52914 need=c,t
1330 d t 4 s48676 adv
1725 c t 4 b ad need=c
1766 c t 4 b adv rec=assassination,combat,subtlety need=c
1776 c t 4 b adv need=c
1776 d t 4 b adv
1784 f s 4 b afv need=c
1833 d t 4 b adv
2094 c t 4 b adv rec=assassination,combat,subtlety need=c
2094 d t 4 b adv
3408 b s 4 - v alt=i3775,e22 sub=weapon w=poisons need=c
3409 d t 4 - dv w=poisons
5760 d t 4 - dv w=poisons
5761 b s 4 - v alt=i5237,e35 sub=weapon w=poisons need=c
6774 b s 4 b a rec=assassination,combat,subtlety alt=5171 need=c
8643 c t 4 b adv rec=assassination,combat,subtlety alt=408 need=c
8643 d t 4 b adv
8647 d t 4 b adr rec=assassination,combat,subtlety,4 alt=8649,8650,11197,11198,26866,48669 sub=debuff:armor
11305 c s 4 b auv rec=assassination,combat,subtlety alt=2983,8696 need=c
13750 b s 4.2 b at need=c
13750 c s 4.2 b atu rec=combat need=c
13877 b s 4.2 b at need=c
13877 c s 4.2 b atu rec=combat,assassination need=c
14149 p s 4.1 t14148 pt need=c,t
14177 b s 4.1 b at need=c
14177 c s 4.1 b atu rec=assassination need=c
14183 c s 4.3 b atu rec=subtlety need=c
14185 c s 4.3 b atv rec=subtlety w=rogue_sub_prep need=c
14251 c t 4.2 b adt need=c
14251 d t 4.2 b ad
14278 c t 4.3 b adt rec=subtlety need=c
18425 d t 4.2 t13867 dtv need=t
26669 c s 4 b auv rec=assassination,combat,subtlety alt=5277 need=c
26889 c s 4 b av rec=assassination,combat,subtlety alt=1856,1857 w=threat need=c
31224 c s 4 b auv rec=assassination,combat,subtlety need=c
31665 p s 4.3 t31223 pt rec=subtlety alt=31666 need=c,t
36554 c t 4.3 b adtv rec=subtlety need=c
36563 b s 4.3 t36554 t rec=subtlety need=c,t
45182 p s 4.3 t31230 ptv rec=subtlety need=c,t
48659 c s 4 b au rec=assassination,combat,subtlety alt=1966,6768,8637,11303,25302,27448,48658 w=threat need=c
48660 d t 4.3 b adt rec=subtlety alt=16511,17347,17348,26864
48672 d t 4 b ad rec=assassination,combat,subtlety alt=1943,8639,8640,11273,11274,11275,26867,48671
48674 d t 4 b adv alt=26679,48673
48676 d t 4 b ad alt=703,8631,8632,8633,11289,11290,26839,26884,48675
51585 d t 4.2 t31126 dtv need=t
51662 b s 4.1 b at rec=assassination alt=63848 need=c
51690 c t 4.2 b adt rec=combat w=rogue_combat_spree need=c
51693 d t 4.3 b adtv
51713 c s 4.3 b atu rec=subtlety w=rogue_sub_dance need=c
51722 c t 4 b adv rec=assassination,combat,subtlety need=c
51722 d t 4 b adv
51724 d t 4 b adv alt=2070,6770,11297
52910 p s 4.1 t51629 pt need=c,t
57933 b a 4 b a alt=59628
57934 c t 4 b ad rec=assassination,combat,subtlety need=c
57968 b s 4 - - rec=assassination,combat,subtlety alt=i43231,e3769,57967,26891,11340,11339,11338,8688,8686,8679 sub=weapon w=poisons need=c
57970 d t 4 - d rec=assassination,combat,subtlety alt=57969,27187,26968,25349,11354,11353,2819,2818 w=poisons
57973 b s 4 - - rec=assassination,combat,subtlety alt=i43233,e3771,57972,27186,26967,25351,11356,11355,2824,2823 sub=weapon w=poisons need=c
57975 d t 4 - dv alt=57974,27189,13224,13223,13222,13218 w=poisons
57978 b s 4 - - rec=assassination,combat,subtlety alt=i43235,e3773,57977,27188,13227,13226,13225,13219 sub=weapon w=poisons need=c
57982 b s 4 - - alt=i43237,e3774,26785,i21835 sub=weapon w=poisons need=c
57993 b s 4 b a rec=assassination alt=32645,32684,57992 need=c
58427 p s 4.1 t58426 pt rec=assassination alt=58426 w=rogue_assa_overkill need=c,t
58683 d t 4.2 t58413 drt rec=combat,4:combat alt=58684 sub=debuff:dmg need=t
64907 g s 5 S832:4 gp sub=set need=c,S832
64911 g s 5 S833:4 gp sub=set need=c,S833
7001 r g 5.2 t724 rt need=t
48111 r g 5 s48113 ar alt=48110
32409 b s 5 R - need=c
56161 r g 5 R r
61792 p s 5.3 R p need=c
64844 r g 5 R r
64904 r g 5 R r
453 d t 5 b ad
528 a g 5 b ar need=c
552 b a 5 b a
586 c s 5 b au rec=disc,holy,shadow w=threat need=c
605 d t 5 b adv
988 a g 5 b arv alt=527 need=c
1706 b a 5 b a
6346 b a 5 b av
6346 c a 5 b av rec=disc,holy,shadow need=c
6788 d a 5 s48066 a rec=disc w=tank need=c,uTank
8129 a t 5 b adv need=c
10060 c a 5.1 b alt rec=disc need=c
10890 c s 5 b av rec=disc,holy,shadow alt=10888,8124,8122 need=c
10955 d t 5 b adv alt=9485,9484
14751 c s 5.1 b at rec=disc,holy need=c
15258 p s 5.3 t15332 pt rec=shadow need=c,t
15271 p s 5.3 t15336 pt need=c,t
15286 b s 5.3 b at rec=shadow need=c
15359 p a 5.2 t15363 pt alt=15357,14893 need=t
15473 f s 5.3 b afnt rec=shadow need=c
15487 c t 5.3 b adtv rec=shadow need=c
15487 d t 5.3 b adtv
27818 p s 5.2 t27816 pt alt=27817,27813 need=c,t
27827 p s 5.2 t20711 fpt need=c,t
27828 p s 5.1 t14774 pt alt=14743 need=c,t
32375 a s 5 b av need=c
33143 p s 5.2 t33146 pt need=c,t
33151 p s 5.2 t33154 pt rec=holy need=c,t
33198 d t 5.3 t33193 drt rec=shadow,5:shadow alt=33197,33196 sub=debuff:hit need=t
33206 c a 5.1 b alt rec=disc w=raidcd need=c
34433 c t 5 b ad rec=disc,holy,shadow w=mana need=c
41635 b a 5 s48113 a rec=disc,holy w=tank need=c,uTank
45242 p s 5.1 t45244 pt alt=45241,45237 need=c,t
47585 c s 5.3 b atuv rec=shadow need=c
47753 p a 5.1 t47515 pt need=t
47788 c a 5.2 b alt rec=holy w=raidcd need=c
47930 b a 5.1 t47517 t w=tank need=t
48063 a t 5 b ad alt=48062,25314,25213,25210,10965,10964,10963,2060 need=c
48066 b a 5 b a rec=disc alt=48065,25218,25217,10901,10900,10899,10898,6066,6065,3747,600,592,17 sub=shield w=tank need=c,uTank
48068 b a 5 b a rec=disc,holy alt=48067,25315,25222,25221,10929,10928,10927,6078,6077,6076,6075,6074,139 need=c,uTank
48071 a t 5 b ad alt=48070,25235,25233,10917,10916,10915,9474,9473,9472,2061 need=c
48072 a g 5 b ar alt=25316,25308,10961,10960,996,596 need=c
48073 r g 5 b ar alt=27841,25312,14819,14818,14752,48074
48074 r g 5 b ar rec=disc,holy,shadow alt=32999,27681,48073 w=want:spirit
48078 a s 5 b a alt=48077,27801,27800,27799,25331,15431,15430,15237 need=c
48087 c g 5.2 b art rec=holy alt=48086,28275,27871,27870,724 need=c
48089 c g 5.2 b art rec=holy alt=48088,34866,34865,34864,34863,34861 need=c
48113 c g 5 b ar rec=disc,holy alt=48112,33076 w=pom need=c
48120 a t 5 b ad alt=48119,32546 need=c
48123 a t 5 b ad alt=48122,25364,25363,10934,10933,6060,1004,984,598,591,585 need=c
48125 d t 5 b ad rec=shadow alt=48124,25368,25367,10894,10893,10892,2767,992,970,594,589
48127 c t 5 b ad rec=shadow alt=48126,25375,25372,10947,10946,10945,8106,8105,8104,8103,8102,8092 need=c
48135 d t 5 b ad alt=48134,25384,15267,15266,15265,15264,15263,15262,15261,14914
48156 a t 5.3 b adt alt=48155,25387,18807,17314,17313,17312,17311,15407 need=c
48158 c t 5 b ad rec=shadow alt=48157,32996,32379 need=c
48160 d t 5.3 b adt rec=shadow alt=48159,34917,34916,34914
48161 r g 5 b ar alt=25389,10938,10937,2791,1245,1244,1243,48162
48162 r g 5 b ar rec=disc,holy,shadow alt=25392,21564,21562,48161 w=want:stamina
48168 b s 5 b a rec=disc,holy,shadow alt=48040,25431,10952,10951,7128,1006,602,588 need=c
48169 r g 5 b ar alt=25433,10958,10957,976,48170
48170 r g 5 b ar rec=disc,holy,shadow alt=39374,27683,48169
48171 a s 5 b a alt=25435,20770,10881,10880,2010,2006 w=rez need=c
48173 c s 5.2 b at rec=holy alt=48172,25437,19243,19242,19241,19240,19238,19236 need=c
48300 d t 5 b ad rec=shadow alt=48299,25467,19280,19279,19278,19277,19276,2944
48301 d t 5.3 t15316 dt need=t
53007 c t 5.1 b adt rec=disc alt=47540,53005,53006 need=c
53023 a t 5 b ad alt=48045 need=c
59000 p s 5.3 t15338 pt rec=shadow alt=49694 need=c,t
59891 p s 5.1 t52800 pt rec=disc alt=59890,59889,59888,59887 need=c,t
63725 p s 5.2 t34860 pt rec=holy alt=63724,34754 need=c,t
63734 p s 5.2 t63737 pt rec=holy alt=63731,63735 need=c,t
63944 p g 5.1 t57472 prt rec=disc need=t
64044 c t 5.3 b adtv rec=shadow need=c
64044 d t 5.3 b adtv alt=64058
64843 c s 5 b au rec=disc,holy w=raidcd need=c
64901 c s 5 b au rec=disc,holy,shadow w=mana,raidcd need=c
65081 p a 5.2 t64129 pt alt=64128 need=t
60828 g s 6 i40715 gp sub=relic need=c,w
62146 g s 6 i40714 gp sub=relic need=c,w
67117 g s 6 S871:2 gp sub=set need=c,S871,S872
70654 g s 6 S898:4 gp sub=set need=c,S898
70657 g s 6 S897:4 gp sub=set need=c,S897
50514 p s 6.3 t49206 pt need=c,t
52375 a s 6 b a alt=49895,49894,49893,49892,47633,47632,47541 need=c
42650 c s 6 b au rec=blood_tank,blood_str,blood_agi,frost,unholy need=c
45524 d t 6 b adv
45529 c s 6 b au rec=frost,unholy,blood_tank,blood_str,blood_agi need=c
46584 c s 6 b a rec=blood_str,blood_agi,frost,blood_tank w=dk_pact need=c
47476 c t 6 b adv rec=blood_tank,blood_str,blood_agi,frost,unholy need=c
47476 d t 6 b adv
47528 c t 6 b adv rec=blood_tank,blood_str,blood_agi,frost,unholy need=c
47568 c s 6 b a rec=blood_str,blood_agi,frost,unholy,blood_tank need=c
48263 f s 6 b afn rec=blood_tank w=presence need=c
48265 f s 6 b afn rec=unholy w=presence need=c
48266 f s 6 b afn rec=blood_str,blood_agi,frost w=presence need=c
48707 b s 6 b av sub=shield need=c
48707 c s 6 b auv rec=blood_tank,blood_str,blood_agi,frost,unholy sub=shield need=c
48743 c s 6 b a rec=blood_tank,unholy w=dk_pact need=c
48792 b s 6 b av need=c
48792 c s 6 b auv rec=blood_tank,blood_str,blood_agi,frost,unholy need=c
48982 c s 6.1 b at rec=blood_tank,blood_str,blood_agi w=dk_gorged need=c
49005 c t 6.1 b adt rec=blood_tank need=c
49005 d t 6.1 b adt
49016 c a 6.1 b at rec=blood_str,blood_agi,blood_tank need=c
49016 r t 6.1 b adrt
49028 b s 6.1 b at need=c
49028 c t 6.1 b adtu rec=blood_str,blood_agi,blood_tank need=c
49039 b s 6.2 t49039 tv need=c,t
49039 c s 6.2 t49039 tuv rec=blood_tank,blood_str,blood_agi,frost,unholy need=c,t
49203 c g 6.2 t49203 rtv rec=frost need=c,t
49206 c t 6.3 b adt rec=unholy need=c
49222 b s 6.3 b at rec=unholy sub=shield need=c
49222 c s 6.3 b atu sub=shield need=c
49576 c t 6 b adv rec=blood_tank,blood_str,blood_agi,frost,unholy alt=49560,49575 w=taunt need=c
49796 b s 6.2 b at need=c
49796 c s 6.2 b atu rec=frost need=c
49909 a t 6 b ad alt=49904,49903,49896,45477 need=c
49938 c g 6 b ar alt=43265,49936,49937 need=c
50421 p s 6.1 t49509 pt rec=blood_tank,blood_str,blood_agi need=c,t
50436 d t 6.2 t50043 dtv alt=50434,50435 need=t
50449 p s 6.1 t49504 pt rec=blood_tank,blood_str,blood_agi alt=50447,50448 need=c,t
50461 r g 6.3 t51052 rt need=t
50510 d t 6.3 t49632 dt alt=50508,50509 need=t
50536 d t 6.3 b adt rec=unholy
50977 c s 6 b a need=c
51052 c g 6.3 b art rec=blood_tank,blood_str,blood_agi,frost,unholy w=dk_amz need=c
51124 p s 6.2 t51130 pt rec=frost need=c,t
51209 d t 6.2 t49203 dtv need=t
51271 b s 6.2 t51271 t need=c,t
51271 c s 6.2 t51271 tu rec=frost need=c,t
51328 c t 6.3 b adt alt=49158,51325,51326,51327 need=c
51399 d t 6 - dv
51411 c t 6.2 t49184 dt alt=49184,51409,51410 need=c,t
51735 d t 6 - dr rec=unholy,6:unholy alt=51726,51734,50510 sub=debuff:dmg
53138 r g 6.1 t53138 nrt rec=blood_tank,blood_str,blood_agi alt=53137 w=want:ap_pct need=t
55078 d t 6 s66216 ad rec=blood_tank,blood_str,blood_agi,frost,unholy w=runes
55095 d t 6 s49909 adr rec=blood_tank,blood_str,blood_agi,frost,unholy,@tank sub=debuff:atk w=runes
55233 b s 6.1 b at need=c
55233 c s 6.1 b atu rec=blood_tank need=c
55268 a t 6.2 b adt alt=51419,51418,51417,51416,49143 need=c
55610 r g 6.2 t55610 nrt rec=frost w=want:melee_haste need=t
56222 c t 6 b ad rec=blood_tank w=taunt need=c
56222 d t 6 b ad
57623 r g 6 - r rec=blood_tank,blood_str,blood_agi,frost,unholy alt=57330
58578 p s 6.2 t50887 pt alt=50882,58575,58576,58577 need=c,t
59052 p s 6.2 t59057 pt rec=frost need=c,t
61999 c t 6 b ad need=c
63560 c s 6.3 b atu rec=unholy need=c
64859 p s 6.1 t55226 pt rec=blood_tank alt=51789,64855,64856,64858 need=c,t
66803 p s 6.3 t66817 pt rec=unholy alt=63583,66800,66801,66802 need=c,t
70806 g s 7 S892:2 gp sub=set need=c,S892
70829 g s 7 S894:2 gp sub=set need=c,S894
70831 g s 7 S894:4 gp sub=set need=c,S894
6196 b s 7 b a need=c
49238 a s 7 b a alt=49237,25449,25448,15208,15207,10392,10391,6041,943,915,548,529,403 need=c
49276 a s 7 b a alt=49275,25420,10468,10467,10466,8010,8008,8004 need=c
55459 a s 7 b a alt=55458,25423,25422,10623,10622,1064 need=c
60771 g s 7 i40708 gp sub=relic need=c,w
70809 r g 7 b ar
63283 p s 7 R p need=c
131 r g 7 b ar
526 a t 7 b ad need=c
546 r g 7 b ar
2062 c t 7 b adf rec=ele w=totems need=c
2484 c t 7 b adfv rec=ele,enh_phys,enh_spell,resto w=totems need=c
2645 f s 7 b afnv need=c
2825 c g 7 b ar rec=ele,enh_phys,enh_spell,resto need=c,fH
2825 r g 7 b ar rec=* sub=buff:raid need=fH
2894 c t 7 b adf rec=ele,enh_phys,enh_spell w=totems need=c
3600 d t 7 s2484 adfv w=totems
3738 r g 7 b afr rec=ele,resto alt=2895 w=totems,want:spell_haste
8012 a t 7 b adv alt=370 need=c
8143 a g 7 b afrv alt=8146 w=totems need=c
8170 a g 7 b afr w=totems need=c
8177 c g 7 b afrv rec=ele,enh_phys,enh_spell,resto alt=8178 w=totems need=c
8512 r g 7 b afr rec=enh_phys,enh_spell alt=8515 w=totems
10399 b s 7 b a alt=8017,8018,8019 sub=weapon need=c
16166 b s 7.1 b at need=c
16166 c s 7.1 b atu rec=ele need=c
16188 b s 7.3 b atv need=c
16188 c s 7.3 b atuv rec=resto need=c
16190 c g 7.3 b afrt rec=resto alt=16191 w=totems need=c
16237 p a 7.3 b ap alt=16177,16236
16246 p s 7.1 t16164 pt rec=ele need=c,t
16280 p s 7.2 t16284 pt rec=enh_phys,enh_spell alt=16257,16277,16278,16279 need=c,t
17364 c t 7.2 b adt rec=enh_phys,enh_spell alt=32175,32176 need=c
17364 d t 7.2 b adt
20608 c s 7 b a rec=ele,enh_phys,enh_spell,resto alt=21169 need=c
29178 p s 7.1 t29180 pt alt=30165,29177 need=c,t
30809 r g 7.2 t30809 nrt rec=enh_phys,enh_spell need=t
30823 b s 7.2 b at need=c
30823 c s 7.2 b atu rec=enh_phys,enh_spell need=c
31616 p s 7.3 t30886 pt sub=shield need=c,t
32182 c g 7 b ar rec=ele,enh_phys,enh_spell,resto need=c,fA
32182 r g 7 b ar rec=* sub=buff:raid need=fA
36936 a s 7 b af w=totems need=c
43339 p s 7 b ap need=c
49231 c t 7 b adv rec=enh_phys,enh_spell alt=8042,8044,8045,8046,10412,10413,10414,25454,49230 need=c
49231 d t 7 b adv alt=8042,8044,8045,8046,10412,10413,10414,25454,49230
49233 c t 7 b ad alt=8050,8052,8053,10447,10448,25457,29228,49232 need=c
49233 d t 7 b ad rec=ele,enh_phys,enh_spell alt=8050,8052,8053,10447,10448,25457,29228,49232
49236 c t 7 b adv alt=8056,8058,10472,10473,25464,49235 need=c
49236 d t 7 b adv alt=8056,8058,10472,10473,25464,49235
49271 c t 7 b ad rec=ele alt=421,930,2860,10605,25439,25442,49270 need=c
49273 a a 7 b a alt=49272,25396,25391,25357,10396,10395,8005,959,939,913,547,332,331 need=c
49277 a s 7 b a alt=25590,20777,20776,20610,20609,2008 w=rez need=c
49281 b s 7 b a rec=enh_phys,enh_spell,ele alt=324,325,905,945,8134,10431,10432,25469,25472,49280 sub=shield need=c
49284 b a 7.3 b at rec=resto alt=974,32593,32594,49283 sub=shield w=shaman_eshield need=c,uTank
51470 r g 7.1 t51470 nrt rec=ele need=t
51514 c t 7 b adv rec=ele,enh_phys,enh_spell,resto need=c
51514 d t 7 b adv
51533 c s 7.2 b at rec=enh_phys,enh_spell need=c
51886 a t 7.3 b adtv need=c
51994 b s 7 b a rec=resto alt=51730,51988,51991,51992,51993 sub=weapon need=c
52000 p a 7 s51994 ap
52179 p s 7.1 t51479 ptv need=c,t
53390 p s 7.3 t51566 pt rec=resto w=shaman_resto_tide need=c,t
53817 p s 7.2 t51532 pt rec=enh_phys,enh_spell w=shaman_mw need=c,t
55166 b s 7.3 b at need=c
55198 c s 7.3 b atu rec=resto need=c
57722 r g 7.1 b afrt rec=ele alt=30708 w=totems,want:spell_power
57723 d s 7 s32182 ar rec=* sub=debuff:self
57724 d s 7 s2825 ar rec=* sub=debuff:self
57960 b s 7 b a rec=ele,resto alt=24398,33736,52138,52136,52134,52131,52129,52127 sub=shield need=c
57994 c t 7 b adv rec=ele,enh_phys,enh_spell,resto need=c
58582 c g 7 b afrv alt=5730,6390,6391,6392,10427,10428,25525,58580,58581 w=totems need=c
58643 r g 7 b afr rec=enh_phys,enh_spell alt=58646 w=totems
58656 r g 7 b afr alt=58655 w=totems
58704 a t 7 b adf alt=3599,6363,6364,6365,10437,10438,25533,58699,58703 w=totems,shaman_enh_magma need=c
58734 a t 7 b adf alt=8190,10585,10586,10587,25552,58731 w=totems,shaman_enh_magma need=c
58739 r g 7 b afr alt=58740 w=totems
58745 r g 7 b afr alt=58744 w=totems
58749 r g 7 b afr alt=58750 w=totems
58753 r g 7 b afr alt=58752 w=totems
58757 a g 7 b afr alt=5394,6375,6377,10462,10463,25567,58755,58756 w=totems need=c
58774 r g 7 b afr rec=ele,enh_phys,enh_spell,resto alt=58777 w=totems
58790 b s 7 b a rec=ele,enh_phys,enh_spell alt=8024,8027,8030,16339,16341,16342,25489,58785,58789 sub=weapon need=c
58796 b s 7 b av alt=8033,8038,10456,16355,16356,25500,58794,58795 sub=weapon need=c
58799 d t 7 s58796 adv
58804 b s 7 b a rec=enh_phys,enh_spell alt=8232,8235,10486,16362,25505,58801,58803 sub=weapon need=c
59159 c g 7.1 b artv rec=ele alt=51490,59156,59158 need=c
60043 c t 7 b ad rec=ele alt=51505 need=c
60103 c t 7.2 b adt rec=enh_phys,enh_spell need=c
61301 b a 7.3 b at alt=61295,61299,61300
61301 c a 7.3 b at rec=resto alt=61295,61299,61300 w=shaman_resto_tide need=c
61657 c g 7 b ar rec=enh_phys,enh_spell alt=1535,8498,8499,11314,11315,25546,25547,61649 need=c
63685 d t 7.2 b adv
64694 p s 7.1 t51482 pt alt=65264 need=c,t
64695 d t 7.1 t51486 dtv need=t
64701 b s 7.1 t16166 t need=c,t
66842 a g 7 b afr w=totems need=c
66843 a g 7 b afr w=totems need=c
66844 a g 7 b afr w=totems need=c
64868 g s 8 S836:2 gp sub=set need=c,S836
70747 g s 8 S883:4 gp sub=set need=c,S883
70753 g s 8 S883:2 gp sub=set need=c,S883
3562 a s 8 b a need=c,fA
3563 a s 8 b a need=c,fH
3565 a s 8 b a need=c,fA
3566 a s 8 b a need=c,fH
3567 a s 8 b a need=c,fH
7268 a s 8 b a need=c
29442 a s 8.1 b at need=c
30449 a s 8 b a need=c
32271 a s 8 b a need=c,fA
32272 a s 8 b a need=c,fH
33717 a s 8 b a alt=28612,10145,10144,6129,990,597,587 need=c
35715 a s 8 b a alt=33690 need=c,fH
42859 a s 8 b a alt=42858,27074,27073,10207,10206,10205,8446,8445,8444,2948 need=c
42921 a s 8 b a alt=42920,27082,27080,10202,10201,8439,8438,8437,1449 need=c
42956 a s 8 b a alt=42955 need=c
42985 a s 8 b a alt=27101,10054,10053,3552,759 need=c
44450 a s 8.2 b at need=c
49358 a s 8 b a need=c,fH
49359 a s 8 b a need=c,fA
53140 a s 8 b a need=c
66 c s 8 b auv rec=arcane,fire,frost alt=32612 w=threat need=c
130 b a 8 b a
1953 c s 8 b av rec=arcane,fire,frost need=c
2139 c t 8 b adv rec=arcane,fire,frost need=c
6136 d t 8 s7301 adv alt=7321
7301 f s 8 b afv alt=168,7300 w=armor need=c
11129 b s 8.2 b at rec=fire alt=28682 need=c
11129 c s 8.2 b atu rec=fire need=c
11958 c s 8.3 b at rec=frost need=c
12042 b s 8.1 b at rec=arcane need=c
12042 c s 8.1 b atu rec=arcane need=c
12043 b s 8.1 b at need=c
12043 c s 8.1 b atu rec=arcane alt=29976 need=c
12051 c s 8 b au rec=arcane,fire,frost w=mana,mage_arcane_burn need=c
12355 d t 8.2 b adtv
12472 b s 8.3 b at rec=arcane,frost need=c
12472 c s 8.3 b atu rec=arcane,frost need=c
12486 d t 8.3 b adv alt=12484,12485
12494 d t 8.3 b adtv
12536 p s 8.1 b ap rec=arcane,frost need=c
12579 d t 8.3 t28593 drt rec=frost,8:frost alt=63094 sub=debuff:crit need=t
12654 d t 8.2 b adt rec=fire
12826 d t 8 b adv rec=arcane,fire,frost alt=118,12824,12825,28271,28272,61025,61305,61721,61780,59634
22959 d t 8.2 b adrt rec=fire,8:fire sub=debuff:crit w=mage_scorch
31583 r g 8.1 t31583 nrt w=want:dmg_pct need=t
31589 d t 8.1 b adtv
31643 p s 8.2 t31642 ptv need=c,t
31687 c s 8.3 b at rec=frost w=pet need=c
36032 d s 8 b a rec=arcane alt=30451,42894,42896,42897 w=mage_arcane
41425 d s 8 s45438 av
42833 d t 8 b ad alt=133,143,145,3140,8400,8401,8402,10148,10149,10150,10151,25306,27070,38692,42832
42842 d t 8 b adv alt=116,205,837,7322,8406,8407,8408,10179,10180,10181,25304,27071,27072,38697,42841
42846 a t 8 b ad alt=42845,42844,42843,38704,38703,38700,38699,27076,27075,25346,25345,10274,10273,10212,10211,8419,8418,8417,8416,7270,7269,5145,5144,5143 need=c
42873 c t 8 b adv rec=fire alt=2136,2137,2138,8412,8413,10197,10199,27078,27079,42872 need=c
42891 d t 8.2 b adt alt=11366,12505,12522,12523,12524,12525,12526,18809,27132,33938,42890
42914 a t 8 b ad alt=42913,30455 need=c
42917 c s 8 b av rec=arcane,fire,frost alt=122,865,6131,10230,27088 need=c
42917 d t 8 b adv
42926 d t 8 b ad alt=2120,2121,8422,8423,10215,10216,27086,42925 w=mage_fire_aoe
42931 c s 8 b av need=c
42931 d t 8 b adv alt=120,8492,10159,10160,10161,27087,42930
42945 c s 8.2 b atv rec=fire alt=11113,13018,13019,13020,13021,27133,33933,42944 need=c
42945 d t 8.2 b adtv
42950 c t 8.2 b adtv rec=fire alt=31661,33041,33042,33043,42949 need=c
42950 d t 8.2 b adtv
43002 r g 8 b ar rec=arcane,fire,frost alt=23028,27127,61316,42995,61024,1459,1460,1461,10156,10157,27126 w=want:intellect
43008 f s 8 b afv alt=7302,7320,10219,10220,27124 w=armor need=c
43010 b s 8 b av sub=shield need=c
43010 c s 8 b auv alt=543,8457,8458,10223,10225,27128 sub=shield need=c
43012 b s 8 b av sub=shield need=c
43012 c s 8 b auv alt=6143,8461,8462,10177,28609,32796 sub=shield need=c
43015 r t 8 b adr alt=604,8450,8451,10173,10174,33944
43017 r t 8 b adr alt=1008,8455,10169,10170,27130,33946
43020 b s 8 b av alt=1463,8494,8495,10191,10192,10193,27131,43019 sub=shield need=c
43024 f s 8 b af rec=arcane,frost alt=6117,22782,22783,27125,43023 w=armor need=c
43039 b s 8.3 b atv rec=frost sub=shield need=c
43039 c s 8.3 b atuv rec=frost alt=11426,13031,13032,13033,27134,33405,43038 sub=shield need=c
43046 f s 8 b af rec=arcane,fire,frost alt=30482,43045 w=armor need=c
44401 p s 8.1 t54490 pt rec=arcane w=mage_arcane need=c,t
44413 p s 8.1 t44396 pt need=c,t
44544 p s 8.3 t44545 pt rec=frost alt=74396 w=mage_frost_shatter need=c,t
44572 c t 8.3 b adtv rec=frost alt=58534 need=c
44572 d t 8.3 b adtv
44781 c t 8.1 b adt rec=arcane alt=44425,44780 need=c
45438 b s 8 b av need=c
45438 c s 8 b auv rec=arcane,fire,frost need=c
46989 p s 8.1 t31570 ptv alt=47000 need=c,t
47610 d t 8 b adv alt=44614
48108 p s 8.2 t44448 pt rec=fire need=c,t
54646 r t 8.1 b adrt rec=arcane,fire,frost w=want:focus_magic,mage_focus
54648 p s 8.1 t54646 pt need=c,t
54741 p s 8.2 t44443 pt w=mage_fire_aoe need=c,t
54748 p s 8.2 t54749 ptv need=c,t
55021 d t 8.1 t12598 dtv alt=18469 need=t
55080 d t 8.3 t54787 dtv need=t
55342 c s 8 b au rec=arcane,fire,frost need=c
55360 d t 8.2 b adt rec=fire alt=44457,55359
57531 p s 8.1 t31583 pt rec=arcane alt=57529 need=c,t
57761 p s 8.3 t44549 pt rec=frost w=mage_frost_shatter need=c,t
64343 p s 8.2 t12358 ptv need=c,t
64346 d t 8.2 t64357 dtv need=t
70840 g s 9 S884:4 gp sub=set need=c,S884
20310 d t 9 s1122 ad
20882 d t 9 s1122 ad
29341 d t 9.3 t17877 dt need=t
47815 a s 9 b a alt=47814,30459,27210,17923,17922,17921,17920,17919,5676 need=c
47825 a s 9 b a alt=47824,30545,27211,17924,6353 need=c
47838 a s 9 b a alt=47837,32231,29722,20153 need=c
58889 a s 9 b a alt=29886 need=c
59092 a s 9.1 b at alt=27265,18938,18937,18220 need=c
60946 r g 9.1 t53759 rt need=t
60995 d t 9 s54785 ad
61082 g s 9 S802:4 gp sub=set need=c,S802
61595 g s 9 S802:2 gp sub=set need=c,S802
63243 p s 9.3 t63245 pt need=c,t
1949 b s 9 R - need=c
47823 b s 9 R - need=c
132 r t 9 b adr
688 a s 9 b a rec=destro w=pet need=c
691 a s 9 b a rec=affli w=pet need=c
696 f s 9 b af alt=687 w=armor need=c
697 a s 9 b a w=pet need=c
712 a s 9 b av w=pet need=c
1122 c s 9 b a rec=affli,demo,destro need=c
5138 d t 9 b adv
5697 r t 9 b adr
6215 d t 9 b adv alt=5782,6213
11719 d t 9 b ad alt=1714 w=curse
17800 d t 9.1 t18275 dt rec=destro alt=17794,17797,17798,17799 need=t
17928 c s 9 b av rec=affli,demo,destro alt=5484 need=c
17928 d t 9 b adv
17941 p s 9.1 t18095 pt rec=affli need=c,t
17962 c t 9.3 b adt rec=destro w=warlock_destro_fire need=c
17962 d t 9.3 b adt
18118 d t 9.3 t18120 dtv need=t
18223 d t 9.1 b adtv alt=29539 w=curse
18540 c s 9 b a need=c
18647 d t 9 b adv alt=710
18708 b s 9.2 b at need=c
18708 c s 9.2 b atu need=c
19028 b s 9.2 b at rec=demo alt=25228 need=c
29858 c s 9 b a rec=demo,affli,destro w=threat need=c
30146 a s 9.2 b at rec=demo w=pet need=c
32391 d t 9.1 b adt rec=affli alt=32386,32388,32389,32390
34936 p s 9.3 t34939 pt rec=destro need=c,t
35706 r s 9.2 b anrt alt=23759,23760,23761,23762,23826,23827,23828,23829,23833,23834,23835,23836,23837,23838,23839,23840,23841,23842,23843,23844,35702,35703,35704,35705 w=pet need=c
47193 c s 9.2 b at rec=demo w=pet need=c
47241 c s 9.2 b atu rec=demo alt=61610,54817,54879 need=c
47241 f s 9.2 b aft rec=demo need=c
47283 p s 9.3 t47223 pt rec=destro need=c,t
47809 a t 9 b ad alt=47808,27209,25307,11661,11660,11659,7641,1106,1088,705,695,686 need=c
47811 d t 9 b ad rec=demo,destro alt=348,707,1094,2941,11665,11667,11668,25309,27215,47810
47813 d t 9 b ad rec=affli,demo,destro alt=172,6222,6223,7648,11671,11672,25311,27216,47812 w=warlock_affli_snap
47827 c t 9.3 b adtv alt=17877,18867,18868,18869,18870,18871,27263,30546,47826 need=c
47836 d t 9 b ad alt=27243,47833,47834,47835
47843 d t 9.1 b adtv rec=affli alt=30108,30404,30405,31117,47841
47847 c t 9.3 b adtv rec=destro alt=30283,30413,30414,47846 need=c
47847 d t 9.3 b adtv
47855 d t 9 b ad alt=1120,8288,8289,11675,27217
47857 d t 9 b adv alt=689,699,709,7651,11699,11700,27219,27220
47860 c t 9 b adv rec=affli,demo,destro alt=6789,17925,17926,27223,47859 need=c
47860 d t 9 b adv
47864 d t 9 b ad rec=affli alt=980,1014,6217,11711,11712,11713,27218,47863 w=curse,warlock_curse
47865 d t 9 b adr rec=affli,demo,destro,9 alt=1490,11721,11722,27228 sub=debuff:dmg w=curse,warlock_curse
47867 d t 9 b ad rec=demo,destro alt=603,30910 w=curse,warlock_curse
47877 x s 9 - vx rec=affli,demo,destro alt=47875,47876,i36892,i36893,i36894 sub=healthstone w=stones need=c
47878 x s 9 b ax alt=6201,6202,5699,11729,11730,27230,47871 sub=healthstone w=stones need=c
47883 b a 9 - v rec=affli,demo,destro alt=20707,27239 w=stones,want:soulstone,warlock_stone
47883 x s 9 - vx rec=affli,demo,destro alt=i36895,i22116 sub=soulstone w=stones,warlock_stone need=c
47884 x s 9 b ax alt=693,20752,20755,20756,20757,27238 sub=soulstone w=stones,warlock_stone need=c
47888 x s 9 b ax rec=affli,demo alt=2362,17727,17728,28172,47886,i41191,i41192,i41193,i41194,i41195,i41196 sub=stone w=stones,weapon need=c
47889 f s 9 b af alt=706,1086,11733,11734,11735,27260,47793 w=armor need=c
47891 b s 9 b av sub=shield need=c
47891 c s 9 b auv alt=6229,11739,11740,28610,47890 sub=shield need=c
47893 f s 9 b af rec=affli,demo,destro alt=28176,28189,47892 w=armor need=c
47982 r g 9 - nr rec=destro,affli alt=6307,7804,7805,11766,11767,27268 w=pet,want:health
48018 b s 9 b av need=c
48020 c s 9 b av rec=affli,demo,destro need=c
48090 r g 9.2 t47240 rt rec=demo w=want:spell_power,warlock_demo_pact need=t
50511 d t 9 b adrv alt=702,1108,6205,7646,11707,11708,27224,30909 sub=debuff:atk w=curse
50581 c t 9 b ad need=c
50589 b s 9 b a rec=demo need=c
50589 c s 9 b au rec=demo need=c
53756 p s 9 b apv need=c
54277 p s 9.3 t47260 pt rec=destro alt=54274,54276 w=warlock_destro_fire need=c,t
54370 p s 9.3 t30302 ptv alt=54371,54372,54373,54374,54375 need=c,t
54785 c t 9 b adv need=c
57567 r g 9 - nr rec=affli alt=54424,57564,57565,57566 w=pet,want:intellect
59164 c t 9.1 b adt rec=affli alt=48181,59161,59163 need=c
59164 d t 9.1 b adt rec=affli alt=48181,59161,59163
59172 c t 9.3 b adt rec=destro alt=50796,59170,59171 w=warlock_destro_fire need=c
59671 c s 9 b a need=c
59671 d t 9 b ad
60220 x s 9 b ax rec=destro alt=6366,17951,17952,17953,27250,60219,i41170,i41169,i41171,i41172,i40773,i41173,i41174 sub=stone w=stones,weapon need=c
60947 d t 9.1 t53759 dtv need=t
61191 d t 9 b adv alt=1098,11725,11726
61290 c t 9 b ad rec=affli,demo,destro alt=47897 need=c
61291 d t 9 - d alt=47960
63167 p s 9.2 t63158 pt rec=demo alt=63165 need=c,t
63244 p s 9.3 t63245 pt rec=destro alt=18093 need=c,t
63321 p s 9 - p rec=affli,demo,destro w=mana need=c
64371 p s 9.1 t47197 pt rec=affli alt=64368,64370 need=c,t
71165 p s 9.2 t47247 pt rec=demo alt=47383,71162 need=c,t
64823 g s 10 S828:4 gp sub=set need=c,S828
70721 g s 10 S888:2 gp sub=set need=c,S888
27010 d t 10 s53312 ad alt=19975,19974,19973,19972,19971,19970
70691 r g 10 R r
768 f s 10 b afn rec=cat w=forms need=c
770 d t 10 b adrv rec=balance,10 alt=16857 sub=debuff:armor
783 f s 10 b afn w=forms need=c
1066 f s 10 b afn w=forms need=c
2893 b a 10 b a
5209 c s 10 b a rec=bear need=c
5209 d t 10 b ad
5215 f s 10 b afv rec=cat w=forms need=c
5229 b s 10 b a need=c
5229 c s 10 b au rec=bear need=c
6795 c t 10 b ad rec=bear w=taunt need=c
6795 d t 10 b ad
8983 c t 10 b adv rec=bear alt=5211,6798 need=c
8983 d t 10 b adv
9634 f s 10 b afn rec=bear alt=5487 w=forms need=c
16857 c t 10 b adv need=c
16857 d t 10 b adv rec=bear,cat alt=60089
16870 p s 10.3 t16864 pt rec=balance,cat,resto,bear alt=16864 need=c,S827,t
16886 p s 10.1 t61346 pt rec=balance,resto need=c,t
16979 c t 10 b adv rec=bear need=c
17116 b s 10.3 b at need=c
17116 c s 10.3 b atu rec=resto need=c
18562 c t 10.3 b adt rec=resto need=c
18658 d t 10 b ad alt=2637,18657
22812 b s 10 b av need=c
22812 c s 10 b auv rec=bear,balance,cat,resto need=c
22842 b s 10 b a need=c
22842 c s 10 b au rec=bear alt=22845 need=c
24858 f s 10.1 b afnt rec=balance w=forms need=c
24907 r g 10.1 b anr w=want:spell_crit
24932 r g 10.2 t17007 nrt rec=cat,bear w=want:crit_phys need=t
29166 b a 10 b a
29166 c a 10 b a rec=balance,resto,cat,bear w=mana,raidcd,druid_balance_innervate need=c
33357 b s 10 b a need=c
33357 c s 10 b au rec=cat alt=1850,9821 need=c
33786 d t 10 b adv
33831 c t 10.1 b adt rec=balance need=c
33891 f s 10.3 b afnt rec=resto w=forms need=c
34123 r g 10.3 t65139 nrt need=t
40120 f s 10 b afn alt=33943 w=forms need=c
45283 p s 10.3 t33883 pt alt=45281,45282 need=c,t
45334 d t 10 s16979 adv
48378 a a 10 b a alt=48377,26979,26978,25297,9889,9888,9758,8903,6778,5189,5188,5187,5186,5185 need=c
48391 p s 10.1 t48393 pt rec=balance need=c,t
48420 f s 10.3 t48412 fnt need=c,t
48421 f s 10.3 t48412 fnt need=c,t
48422 f s 10.3 t48412 fnt need=c,t
48441 b a 10 b a rec=resto alt=774,1058,1430,2090,2091,3627,8910,9839,9840,9841,25299,26981,26982,48440 w=druid_resto_rejuv need=c,uTank
48443 b a 10 b a rec=resto alt=8936,8938,8939,8940,8941,9750,9856,9857,9858,26980,48442 need=c,uTank
48447 c s 10 b a rec=resto,balance alt=740,8918,9862,9863,26983,48446 need=c
48451 b a 10 b a rec=resto alt=33763,48450 w=tank,druid_bloom need=c,uTank
48461 a t 10 b ad alt=48459,26985,26984,9912,8905,6780,5180,5179,5178,5177,5176 need=c
48463 d t 10 b ad rec=balance alt=8921,8924,8925,8926,8927,8928,8929,9833,9834,9835,26987,26988,48462
48465 a t 10 b ad alt=48464,26986,25298,9876,9875,8951,8950,8949,2912 need=c
48467 a s 10 b a alt=16914,17401,17402,27012,48466 need=c
48468 d t 10.1 b adt rec=balance alt=5570,24974,24975,24976,24977,27013
48469 r t 10 b adr alt=1126,5232,5234,6756,8907,9884,9885,26990
48470 r g 10 b ar rec=balance,cat,bear,resto alt=21849,21850,26991 w=want:wild
48477 c t 10 b ad rec=balance,cat,bear,resto alt=20484,20739,20742,20747,20748,26994 w=raidcd,druid_brez need=c
48480 a t 10 b ad alt=6807,6808,6809,8972,9745,9880,9881,26996,48479 w=druid_bear_rage need=c
48504 p a 10.3 t48500 pt alt=48500 need=t
48517 p s 10.1 t48525 pt rec=balance alt=48525 w=eclipse,druid_eclipse need=c,t
48518 p s 10.1 t48525 pt rec=balance alt=48525 w=eclipse,druid_eclipse need=c,t
48560 d t 10 b adr rec=bear,10:bear alt=99,1735,9490,9747,9898,26998,48559 sub=debuff:atk
48564 c t 10 b ad rec=bear alt=33878,33986,33987,48563 need=c
48564 d t 10 b ad rec=bear alt=33878,33986,33987,48563
48566 d t 10 b adr rec=cat,10:cat alt=33876,33982,33983,48565,33878,33986,33987,48563,48564 sub=debuff:bleed w=druid_cat_upkeep
48568 d t 10 b ad rec=bear alt=33745,48567
48572 a t 10 b ad alt=48571,27002,27001,9830,9829,8992,6800,5221 need=c
48574 d t 10 b ad rec=cat alt=1822,1823,1824,9904,27003,48573
48575 c s 10 b a rec=cat alt=8998,9000,9892,27004,31709 w=threat need=c
49376 c t 10 b adv rec=cat need=c
49800 d t 10 b ad rec=cat alt=1079,9492,9493,9752,9894,9896,27008,49799
49802 c t 10 b adv rec=cat alt=22570 need=c
49802 d t 10 b adv
49803 d t 10 b adv alt=9005,9823,9827,27006
49804 d t 10 b adv alt=9007,9824,9826,27007
50213 b s 10 b a need=c
50213 c s 10 b au rec=cat alt=5217,6793,9845,9846,50212 need=c
50259 d t 10.2 t49377 dtv alt=50411 need=t
50334 b s 10.2 b at need=c
50334 c s 10.2 b atu rec=cat,bear need=c
50769 a s 10 b a alt=50768,50767,50766,50765,50764,50763 w=rez need=c
52553 r g 10 - nr
52610 b s 10 b a rec=cat w=druid_cat_upkeep need=c
53201 c s 10.1 b atu rec=balance alt=48505,53199,53200 need=c
53251 b g 10.3 b art
53251 c t 10.3 b adt rec=resto alt=48438,53248,53249 need=c
53307 b a 10 b a rec=bear alt=467,782,1075,8914,9756,9910,26992
53308 d t 10 b adv alt=339,1062,5195,5196,9852,9853,26989
53312 c s 10 b auv alt=16689,16810,16811,16812,16813,17329,27009 need=c
58181 d t 10.2 t48485 drt rec=bear,cat,10:bear alt=58179,58180 sub=debuff:atk need=t
60433 d t 10.1 t48511 drt rec=balance,10:balance alt=60431,60432 sub=debuff:dmg need=t
61336 b s 10.2 b at need=c
61336 c s 10.2 b atu rec=bear,cat need=c
61384 c s 10.1 b atv rec=balance alt=50516,53223,53225,53226 need=c
61391 d t 10.1 b adtv alt=61387,61388,61390,53227
62606 p s 10 - p rec=bear sub=shield need=c
69369 p s 10 - p rec=cat alt=16975 need=c
20007 g s 0 e1900 gp sub=ench need=w
28093 g s 0 e2673 gp sub=ench need=w
42976 g s 0 e3225 gp sub=ench need=w
49623 g s 0 i37835 gp sub=trinket need=w
53365 g s 0 e3368 gp sub=ench need=w
53386 g s 0 e3369 gp sub=ench need=w
55341 g s 0 e3640 gp sub=meta need=w
55379 g s 0 e3643 gp sub=meta need=w
55382 g s 0 e3627 gp sub=meta need=w
55637 g s 0 e3722 gp sub=ench need=w
55767 g s 0 e3728 gp sub=ench need=w
55775 g s 0 e3730 gp sub=ench need=w
58904 g s 0 i43573 gp sub=trinket need=w
59620 g s 0 e3789 gp sub=ench need=w
59626 g s 0 e3790 gp sub=ench need=w
60062 g s 0 i40685 gp alt=i49078 sub=trinket need=w
60064 g s 0 i40682 gp alt=i44912,i49076 sub=trinket need=w
60065 g s 0 i40684 gp alt=i44914,i49074 sub=trinket need=w
60196 g s 0 i42989 gp sub=trinket need=w
60218 g s 0 i37220 gp sub=trinket need=w
60229 g s 0 i42987 gp alt=60233,60234,60235,i44253,i44254,i44255 sub=trinket need=w
60302 g s 0 i37390 gp sub=trinket need=w
60314 g s 0 i40431 gp sub=trinket need=w
60318 g s 0 i44308 gp need=w
60437 g s 0 i40256 gp sub=trinket need=w
60479 g s 0 i37660 gp sub=trinket need=w
60486 g s 0 i40432 gp sub=trinket need=w
60492 g s 0 i39229 gp sub=trinket need=w
60494 g s 0 i40255 gp sub=trinket need=w
60512 g s 0 i37111 gp alt=60513,60514,60515 sub=trinket need=w
60520 g s 0 i37657 gp sub=trinket need=w
60525 g s 0 i40430 gp sub=trinket need=w
60551 g s 0 i42589 gp alt=i42608,i42621,i42853 sub=relic need=w
60553 g s 0 i42591 gp alt=i42609,i42622,i42854 sub=relic need=w
60555 g s 0 i51417 gp alt=i51429,i51478,i51507 sub=relic need=w
60568 g s 0 i42584 gp alt=i42603 sub=relic need=w
60569 g s 0 i42585 gp alt=i42604 sub=relic need=w
60570 g s 0 i51437 gp alt=i51513 sub=relic need=w
60766 g s 0 i40322 gp sub=relic need=w
63250 g s 0 i45131 gp alt=i45219 sub=trinket need=w
64411 g s 0 i46017 gp need=w
64440 g s 0 e3869 gp sub=ench need=w
64568 g s 0 e3870 gp sub=ench need=w
64713 g s 0 i45518 gp sub=trinket need=w
64739 g s 0 i45535 gp sub=trinket need=w
64741 g s 0 i45490 gp sub=trinket need=w
64765 g s 0 i45507 gp sub=trinket need=w
64772 g s 0 i45609 gp sub=trinket need=w
64790 g s 0 i45522 gp sub=trinket need=w
64951 g s 0 i45509 gp sub=relic need=w
64963 g s 0 i45144 gp sub=relic need=w
65003 g s 0 i45929 gp sub=trinket need=w
65004 g s 0 i45866 gp sub=trinket need=w
65006 g s 0 i45308 gp sub=trinket need=w
65014 g s 0 i45286 gp sub=trinket need=w
65019 g s 0 i45931 gp sub=trinket need=w
65024 g s 0 i46038 gp sub=trinket need=w
65182 g s 0 i45145 gp sub=relic need=w
67354 g s 0 i47668 gp alt=67355 sub=relic need=w
67358 g s 0 i47671 gp sub=relic need=w
67360 g s 0 i47670 gp sub=relic need=w
67364 g s 0 i47662 gp sub=relic need=w
67371 g s 0 i47661 gp sub=relic need=w
67378 g s 0 i47664 gp sub=relic need=w
67380 g s 0 i47672 gp sub=relic need=w
67383 g s 0 i47673 gp sub=relic need=w
67385 g s 0 i47666 gp sub=relic need=w
67388 g s 0 i47665 gp sub=relic need=w
67391 g s 0 i47667 gp sub=relic need=w
67631 g s 0 i47216 gp sub=trinket need=w
67669 g s 0 i47213 gp sub=trinket need=w
67671 g s 0 i47214 gp sub=trinket need=w
67696 g s 0 i47041 gp alt=i47271 sub=trinket need=w
67703 g s 0 i47115 gp alt=67708,i47303 sub=trinket need=w
67713 g s 0 i47182 gp alt=i47316 sub=trinket need=w
67740 g s 0 i47947 gp alt=i48019 sub=trinket need=w
67742 g s 0 i47949 gp alt=i48021 sub=trinket need=w
67744 g s 0 i47946 gp alt=i48018 sub=trinket need=w
67747 g s 0 i47948 gp alt=i48020 sub=trinket need=w
67750 g s 0 i47059 gp alt=i47432 sub=trinket need=w
67759 g s 0 i47188 gp alt=i47477 sub=trinket need=w
67772 g s 0 i47131 gp alt=67773,i47464 sub=trinket need=w
71175 g s 0 i50456 gp sub=relic need=w
71177 g s 0 i50457 gp sub=relic need=w
71184 g s 0 i50454 gp sub=relic need=w
71187 g s 0 i50455 gp sub=relic need=w
71192 g s 0 i50460 gp sub=relic need=w
71197 g s 0 i50461 gp sub=relic need=w
71199 g s 0 i50458 gp sub=relic need=w
71216 g s 0 i50463 gp sub=relic need=w
71220 g s 0 i50464 gp sub=relic need=w
71227 g s 0 i50459 gp sub=relic need=w
71229 g s 0 i50462 gp sub=relic need=w
71396 g s 0 i50355 gp sub=trinket need=w
71401 g s 0 i50342 gp sub=trinket need=w
71403 g s 0 i50198 gp sub=trinket need=w
71432 g s 0 i50351 gp alt=i50706 sub=trinket need=w
71484 g s 0 i50362 gp alt=71485,71486,71487,71491,71492 sub=trinket need=w
71541 g s 0 i50343 gp sub=trinket need=w
71556 g s 0 i50363 gp alt=71557,71558,71559,71560,71561 sub=trinket need=w
71570 g s 0 i50340 gp sub=trinket need=w
71572 g s 0 i50345 gp sub=trinket need=w
71575 g s 0 i50341 gp sub=trinket need=w
71577 g s 0 i50344 gp sub=trinket need=w
71584 g s 0 i50358 gp sub=trinket need=w
71601 g s 0 i50353 gp sub=trinket need=w
71605 g s 0 i50360 gp sub=trinket need=w
71633 g s 0 i50352 gp sub=trinket need=w
71636 g s 0 i50365 gp sub=trinket need=w
71639 g s 0 i50349 gp sub=trinket need=w
71644 g s 0 i50348 gp sub=trinket need=w
71870 g s 0 i50179 gp alt=i49982,i50641 need=w
71872 g s 0 i50708 gp need=w
71875 g s 0 i50035 gp need=w
71877 g s 0 i50692 gp need=w
71881 g s 0 i49982 gp alt=71882,71883 need=w
71886 g s 0 i50641 gp alt=71887,71888 need=w
71905 g s 0 i49623 gp alt=73422 need=w
72412 g s 0 i50401 gp alt=i50402,i52571,i52572 need=w
72414 g s 0 i50403 gp alt=i50404 need=w
72416 g s 0 i50397 gp alt=i50398 need=w
72418 g s 0 i50399 gp alt=i50400 need=w
75456 g s 0 i54590 gp sub=trinket need=w
75458 g s 0 i54569 gp sub=trinket need=w
75466 g s 0 i54572 gp sub=trinket need=w
75473 g s 0 i54588 gp sub=trinket need=w
75480 g s 0 i54591 gp sub=trinket need=w
i37264 g s 0 i37264 gp sub=trinket need=w
i40258 g s 0 i40258 gp sub=trinket need=w
i40371 g s 0 i40371 gp sub=trinket need=w
i40373 g s 0 i40373 gp sub=trinket need=w
i40382 g s 0 i40382 gp sub=trinket need=w
i42990 g s 0 i42990 gp sub=trinket need=w
i47215 g s 0 i47215 gp sub=trinket need=w
i50359 g s 0 i50359 gp sub=trinket need=w
i50366 g s 0 i50366 gp sub=trinket need=w
8034 g s 0 e2 gp sub=ench need=w
8037 g s 0 e12 gp sub=ench need=w
10458 g s 0 e524 gp sub=ench need=w
13907 g s 0 e912 gp sub=ench need=w
14795 g s 0 e1003 gp sub=ench need=w
16352 g s 0 e1667 gp sub=ench need=w
16353 g s 0 e1668 gp sub=ench need=w
16916 g s 0 i33350 gp sub=weapon need=w
18803 g s 0 e2828 gp sub=ench need=w
20005 g s 0 e1894 gp sub=ench need=w
20006 g s 0 e1899 gp sub=ench need=w
23454 g s 0 e2834 gp sub=ench need=w
25501 g s 0 e2635 gp sub=ench need=w
39959 g s 0 e3155 gp sub=ench need=w
43873 g s 0 i49126 g sub=weapon need=w
44622 g s 0 e3251 gp sub=ench need=w
46629 g s 0 e3273 gp sub=ench need=w
46643 g s 0 i54806 g sub=weapon need=w
47181 g s 0 e3291 g sub=ench need=w
48332 g s 0 i37254 g sub=trinket need=w
48333 g s 0 i37254 g sub=trinket need=w
50070 g s 0 i49128 g sub=weapon need=w
51714 g s 0 e3370 gp sub=ench need=w
51945 g s 0 e3345 gp sub=ench need=w
51990 g s 0 e3346 gp sub=ench need=w
51997 g s 0 e3347 gp sub=ench need=w
51998 g s 0 e3348 gp sub=ench need=w
51999 g s 0 e3349 gp sub=ench need=w
52641 g s 0 e3290 g sub=ench need=w
54621 g s 0 i40754 g sub=trinket need=w
58797 g s 0 e3782 gp sub=ench need=w
58798 g s 0 e3783 gp sub=ench need=w
60530 g s 0 i40258 gp sub=trinket need=w
60565 g s 0 i42575 gp alt=i42594 sub=relic need=w
60566 g s 0 i42582 gp alt=i42601 sub=relic need=w
60567 g s 0 i42583 gp alt=i42602 sub=relic need=w
63388 g s 0 i46104 g sub=weapon need=w
68443 g s 0 i49080 g sub=trinket need=w
71988 g s 0 i50741 g sub=weapon need=w
1539 b s 0 R -
1604 d s 0 R b
1742 b s 0 R -
2379 b s 0 R -
2383 b s 0 R -
2580 b s 0 R -
3714 b s 0 R -
4962 d s 0 R b
5225 b s 0 R -
5363 b s 0 R -
6411 d s 0 R -
7620 b s 0 R -
7731 b s 0 R b
7732 b s 0 R -
8064 d s 0 R -
8066 d s 0 R b
8068 p s 0 R p
8070 p s 0 R bp
8212 b s 0 R -
8219 p s 0 R p
8220 p s 0 R p
8221 p s 0 R p
8222 p s 0 R p
8602 b s 0 R -
9080 d s 0 R b
9658 d t 0 R d
11196 d s 0 R b
11364 b s 0 R -
13168 b s 0 R -
13704 d s 0 R b
13737 d s 0 R b
15471 d s 0 R b
15621 d s 0 R b
16143 d s 0 R b
16172 d s 0 R b
16591 p s 0 R p
16593 p s 0 R p
16595 p s 0 R p
17057 p s 0 R p
18191 p s 0 R p
18222 p s 0 R p
18248 b s 0 R b
22703 d t 0 R d
22790 d s 0 R -
22807 b s 0 R -
23060 r g 0 R r
24709 b s 0 R -
24710 b s 0 R -
24713 b s 0 R -
24723 b s 0 R -
24735 b s 0 R -
24736 b s 0 R -
24740 b s 0 R -
24926 p s 0 R p
26467 b s 0 R -
26470 r g 0 R r
28134 b s 0 R -
28714 b s 0 R -
29002 p s 0 R p
30452 p s 0 R p
31319 p s 0 R p
32323 d s 0 R b
32851 b s 0 R -
33080 b s 0 R -
33095 b s 0 R -
34017 b s 0 R -
35054 d s 0 R b
35696 r g 0 R r
36006 p s 0 R p
36922 d s 0 R b
36984 d s 0 R b
38064 d s 0 R b
39850 p s 0 R p
42919 p s 0 R p
43308 b s 0 R -
43764 b s 0 R -
43771 b s 0 R -
44140 d s 0 R -
44795 p s 0 R bp
45044 b s 0 R -
46356 p s 0 R p
47481 d t 0 R d
47995 d t 0 R d
48418 p s 0 R p
48778 b s 0 R b
48889 b s 0 R -
48890 b s 0 R -
49754 p s 0 R p
50247 b s 0 R -
50986 d s 0 R -
51294 b s 0 R -
51510 r g 0 R r
52719 d s 0 R b
53030 d s 0 R b
53401 b s 0 R -
53403 b s 0 R -
53476 d s 0 R -
53480 b s 0 R -
53753 d s 0 R -
53805 p s 0 R p
53806 p s 0 R p
54028 d s 0 R -
54029 d s 0 R -
54131 b s 0 R -
54508 b s 0 R -
54739 p s 0 R p
54833 p s 0 R p
55164 p s 0 R p
55173 p s 0 R p
55350 b s 0 R -
55428 b s 0 R -
55500 b s 0 R -
56190 d s 0 R b
57073 p s 0 R p
57475 b s 0 R b
57807 d t 0 R d
58363 p s 0 R p
58374 p s 0 R p
58501 d s 0 R -
58600 d s 0 R -
58875 b s 0 R -
59638 d t 0 R d
59657 b s 0 R -
59831 p s 0 R p
59886 d t 0 R d
60122 b s 0 R -
61620 b s 0 R b
61671 p s 0 R p
61684 b s 0 R -
61834 b s 0 R -
61878 d s 0 R b
61888 d s 0 R b
62038 d s 0 R b
62042 d s 0 R b
62130 d s 0 R b
62169 d s 0 R -
62276 b s 0 R -
62287 r g 0 R r
62292 r g 0 R r
62299 b s 0 R -
62318 d s 0 R b
62326 d s 0 R b
62328 b s 0 R b
62374 d t 0 R d
62376 d t 0 R d
62396 b s 0 R -
62415 d s 0 R b
62417 d t 0 R d
62418 d s 0 R b
62420 d s 0 R b
62467 b s 0 R -
62469 d s 0 R b
62471 b s 0 R -
62481 b s 0 R -
62519 b s 0 R -
62532 d s 0 R b
62619 d s 0 R b
62650 d s 0 R -
62670 d s 0 R -
62671 d s 0 R -
62692 d s 0 R b
62702 d s 0 R -
62775 d s 0 R b
62865 d s 0 R b
62892 b s 0 R -
63038 d s 0 R b
63050 d t 0 R d
63134 d s 0 R b
63138 d s 0 R b
63276 d s 0 R b
63420 d s 0 R b
63472 d s 0 R b
63493 d s 0 R b
63494 d s 0 R b
63498 b s 0 R -
63550 d s 0 R b
63571 d s 0 R b
63615 d s 0 R b
63619 b s 0 R -
63673 d s 0 R b
63713 d s 0 R b
63755 d s 0 R b
63757 d s 0 R b
63802 d s 0 R b
63830 d s 0 R b
63881 d s 0 R -
63913 d s 0 R b
63978 d s 0 R b
63988 p s 0 R p
64023 d s 0 R b
64145 d s 0 R b
64151 d s 0 R b
64152 d s 0 R b
64153 d s 0 R b
64155 d s 0 R b
64156 d s 0 R b
64157 d s 0 R b
64160 d s 0 R b
64169 d s 0 R -
64174 d s 0 R -
64189 d s 0 R b
64234 d s 0 R b
64236 d s 0 R b
64320 r g 0 R br
64321 r g 0 R r
64356 p s 0 R p
64374 d s 0 R b
64381 r g 0 R r
64386 d s 0 R b
64396 d s 0 R b
64412 d s 0 R b
64413 r g 0 R r
64495 b s 0 R -
64529 d s 0 R b
64533 d s 0 R b
64570 d s 0 R b
64616 d s 0 R b
64638 d s 0 R b
64645 d s 0 R b
64646 d s 0 R b
64649 d s 0 R b
64654 d s 0 R b
64660 b s 0 R -
64663 d s 0 R b
64667 d s 0 R b
64668 d s 0 R b
64669 d s 0 R b
64677 b s 0 R -
64679 d s 0 R b
64697 d s 0 R b
64698 d s 0 R b
64699 d s 0 R b
64771 d s 0 R b
64781 d s 0 R b
64847 d s 0 R b
64876 d s 0 R b
64919 d s 0 R b
64942 d s 0 R b
64970 d s 0 R b
64971 d s 0 R b
65000 p s 0 R p
65026 d s 0 R b
65104 d s 0 R b
65121 d s 0 R b
65133 b s 0 R -
65134 r g 0 R r
65192 d s 0 R b
65240 d s 0 R b
65386 r g 0 R r
65543 d s 0 R b
65585 b s 0 R -
65590 b s 0 R -
65712 b s 0 R -
65745 b s 0 R -
65792 d s 0 R b
65801 d s 0 R b
65809 d s 0 R b
65815 d s 0 R b
65877 d s 0 R b
65930 d s 0 R b
65931 d s 0 R b
65935 d s 0 R b
65936 d s 0 R b
65954 d s 0 R b
65960 d s 0 R b
65962 d s 0 R b
65970 d s 0 R b
66018 d s 0 R b
66020 d s 0 R b
66070 d s 0 R b
66407 d s 0 R b
66613 d s 0 R b
66906 b s 0 R b
67243 p s 0 R p
67272 b s 0 R -
67311 d s 0 R b
67314 d s 0 R b
67475 d s 0 R b
67656 d s 0 R b
67662 d s 0 R b
67735 b s 0 R -
67746 p s 0 R p
67863 d s 0 R b
67932 d s 0 R b
67934 d s 0 R b
67979 d s 0 R b
67985 d s 0 R b
68005 d s 0 R b
68054 b s 0 R -
68135 d s 0 R b
68138 d s 0 R b
68156 d s 0 R b
68159 d s 0 R b
68415 d s 0 R b
68605 d t 0 R d
68784 d s 0 R b
68981 b s 0 R -
69057 b s 0 R -
69127 d s 0 R -
69244 d s 0 R b
69278 d t 0 R d
69290 d s 0 R b
69391 b s 0 R b
69404 d s 0 R b
69405 d s 0 R b
69483 d s 0 R b
69508 b s 0 R -
69558 b s 0 R -
69649 d s 0 R b
69750 b s 0 R -
69760 b s 0 R -
69776 b s 0 R -
69778 d s 0 R b
69789 d t 0 R d
69869 d s 0 R b
69898 r g 0 R r
69901 b s 0 R -
69903 d t 0 R d
69910 d s 0 R b
69911 d t 0 R d
69917 d s 0 R b
69926 b s 0 R -
69927 d s 0 R b
69975 d t 0 R d
70084 d s 0 R b
70109 b s 0 R -
70189 d t 0 R d
70227 d s 0 R -
70308 d s 0 R -
70309 d s 0 R b
70346 d t 0 R d
70358 b s 0 R -
70363 b s 0 R -
70371 b s 0 R -
70404 b s 0 R -
70407 d s 0 R b
70408 d s 0 R b
70409 d s 0 R b
70410 d s 0 R b
70423 d s 0 R b
70431 b s 0 R -
70432 d s 0 R b
70435 d s 0 R b
70445 d s 0 R -
70451 d s 0 R b
70460 b s 0 R -
70475 d s 0 R b
70498 b s 0 R -
70503 b s 0 R -
70659 d s 0 R b
70671 d s 0 R b
70725 p s 0 R p
70739 d s 0 R b
70744 d s 0 R b
70759 d s 0 R b
70781 p s 0 R p
70821 r g 0 R r
70856 p s 0 R p
70857 p s 0 R p
70858 p s 0 R p
70859 p s 0 R p
70860 p s 0 R p
70893 b s 0 R -
70901 b s 0 R -
70964 d s 0 R b
70980 d s 0 R b
70986 b s 0 R -
71010 d s 0 R -
71023 d s 0 R b
71050 d s 0 R b
71052 d s 0 R b
71056 d s 0 R b
71058 d s 0 R b
71090 d s 0 R b
71103 d s 0 R b
71112 d s 0 R b
71117 d s 0 R b
71119 d s 0 R b
71123 b s 0 R -
71126 d s 0 R b
71127 d s 0 R b
71129 d s 0 R b
71130 d s 0 R b
71141 b s 0 R -
71142 b s 0 R -
71151 d s 0 R b
71152 d s 0 R b
71153 d s 0 R b
71154 d s 0 R b
71157 d s 0 R -
71163 d s 0 R b
71208 d s 0 R b
71222 d s 0 R -
71252 d s 0 R b
71257 d s 0 R b
71264 d t 0 R d
71265 b s 0 R -
71288 d s 0 R b
71298 d s 0 R b
71318 d s 0 R b
71320 d s 0 R b
71327 d s 0 R b
71362 d s 0 R b
71386 d s 0 R b
71387 d s 0 R b
71420 d s 0 R b
71516 b s 0 R -
71552 d s 0 R b
71588 d t 0 R d
71590 d t 0 R d
71592 d t 0 R d
71600 p s 0 R p
71603 b s 0 R -
71614 b s 0 R -
71615 d s 0 R b
71623 d s 0 R b
71624 d s 0 R b
71626 d s 0 R b
71643 p s 0 R p
71647 d s 0 R b
71665 d s 0 R b
71733 d s 0 R b
71769 b s 0 R -
71786 d s 0 R b
71787 d s 0 R b
71789 d s 0 R b
71822 d s 0 R b
71824 d t 0 R d
71889 d s 0 R b
71893 b s 0 R -
71909 d s 0 R -
71925 d s 0 R b
71937 d s 0 R b
71951 d t 0 R d
71955 d s 0 R b
71960 d s 0 R b
72016 d s 0 R b
72018 d s 0 R b
72132 d s 0 R -
72133 d s 0 R b
72144 d s 0 R -
72145 d s 0 R b
72176 b s 0 R -
72259 b s 0 R -
72262 b s 0 R -
72290 b s 0 R b
72292 d s 0 R b
72336 d s 0 R b
72350 d t 0 R d
72458 d s 0 R b
72490 d s 0 R b
72492 d s 0 R b
72502 d s 0 R b
72546 b s 0 R -
72595 b s 0 R -
72641 d s 0 R b
72645 d s 0 R b
72723 b s 0 R -
72754 d s 0 R b
72769 d s 0 R b
72848 d s 0 R b
72865 d s 0 R b
72874 d s 0 R b
72905 d s 0 R b
72906 d s 0 R b
72908 d s 0 R b
72968 p s 0 R p
72981 b s 0 R -
73001 d s 0 R b
73034 d s 0 R -
73061 d s 0 R b
73062 d s 0 R b
73064 d s 0 R b
73117 d s 0 R -
73174 d s 0 R b
73313 b s 0 R -
73320 b s 0 R -
73326 d s 0 R -
73655 b s 0 R -
73708 d s 0 R b
73710 d s 0 R b
73788 d s 0 R b
73790 d s 0 R b
73825 b s 0 R -
74297 d s 0 R b
74509 d s 0 R b
74531 d s 0 R b
74543 p s 0 R p
75413 d s 0 R b
75418 d s 0 R b
75884 d t 0 R d
2481 a s 0 r a sub=racial need=rDwarf,fA
2481 b s 0 r a sub=racial need=rDwarf,fA
6562 r g 0 r anr alt=28878 sub=racial need=rDraenei
7744 c s 0 r av sub=racial need=rScourge,fH
20549 c t 0 r adv sub=racial need=rTauren,fH
20572 b s 0 r av rec=1,3,4,6 sub=racial need=rOrc,fH
20572 c s 0 r auv rec=1,3,4,6 sub=racial need=rOrc,fH
20577 c s 0 r a sub=racial need=rScourge,fH
20578 b s 0 r a sub=racial need=rScourge
20589 c s 0 r av sub=racial need=rGnome,fA
20594 c s 0 r av sub=racial need=rDwarf,fA
20600 b s 0 r av sub=racial need=rHuman
20600 c s 0 r auv alt=58985 sub=racial need=rHuman
25046 c s 0 r av rec=4 sub=racial need=rBloodElf,fH
26297 b s 0 r av rec=@dd sub=racial need=rTroll,fH
26297 c s 0 r auv rec=@dd sub=racial need=rTroll,fH
28497 x s 0 i39666 x rec=4,3,10:cat,7:enh_phys,7:enh_spell sub=elixir:battle
28730 c s 0 r av rec=2,3,5,8,9 sub=racial need=rBloodElf
28880 b s 0 r av rec=* sub=racial need=rDraenei,fA
28880 c s 0 r auv rec=* alt=59542,59543,59544,59545,59547,59548 sub=racial need=rDraenei,fA
33697 b s 0 r av rec=7 sub=racial need=rOrc,fH
33697 c s 0 r auv rec=7 sub=racial need=rOrc,fH
33702 b s 0 r av rec=9 sub=racial need=rOrc,fH
33702 c s 0 r auv rec=9 sub=racial need=rOrc,fH
33721 x s 0 i40070 x rec=@dd+spell,@heal sub=elixir:battle
35475 x g 0 i29528 rx sub=drums
35476 x g 0 i29529 rx sub=drums
35477 x g 0 i29530 rx sub=drums
35478 x g 0 i29531 rx sub=drums
42292 g s 0 i51378 gv alt=i51377,i42122,i42123,i42124,i42126,i46081,i46082,i46083,i46084,i46085 sub=trinket:pvp need=w
45544 x s 0 i34722 vx alt=i34721,45543,i38640,51803,i38643,51827 sub=bandage
48100 x s 0 i37092 x alt=i37091,48099,i33458,43195 sub=scroll
48102 x s 0 i37094 x alt=i37093,48101,i33461,43198 sub=scroll
48104 x s 0 i37098 x alt=i37097,48103,i33460,43197 sub=scroll
50613 c s 0 r av rec=6 sub=racial need=rBloodElf
53746 x s 0 i40068 x rec=@dd+phys sub=elixir:battle
53747 x s 0 i40072 x rec=@heal sub=elixir:guardian
53748 x s 0 i40073 x rec=1,6,2:ret_agi sub=elixir:battle
53749 x s 0 i40076 x rec=* sub=elixir:battle
53751 x s 0 i40078 x rec=@tank sub=elixir:guardian
53752 x s 0 i40079 vx sub=flask
53755 x s 0 i46376 x rec=@dd+spell alt=i45009 sub=flask
53758 x s 0 i46379 x rec=@tank alt=i45008 sub=flask
53760 x s 0 i46377 x rec=@dd+phys alt=i45006 sub=flask
53762 x s 0 i40093 vx rec=@tank sub=potion
53763 x s 0 i40097 x rec=@tank sub=elixir:guardian
53764 x s 0 i40109 x rec=@heal sub=elixir:guardian
53908 x s 0 i40211 vx rec=@dd alt=i22838,28507 sub=potion
53909 x s 0 i40212 vx rec=@dd+spell,@heal alt=i22839,28508 sub=potion
53910 x s 0 i40213 x alt=i32840,i22845,28536 sub=potion:prot
53911 x s 0 i40214 x alt=i32846,i22841,28511 sub=potion:prot
53913 x s 0 i40215 x alt=i32847,i22842,28512 sub=potion:prot
53914 x s 0 i40216 x alt=i32844,i22844,28513 sub=potion:prot
53915 x s 0 i40217 x alt=i32845,i22846,28537 sub=potion:prot
54212 x s 0 i46378 x rec=@heal alt=i45007 sub=flask
54735 g t 0 e3599 dgv alt=54736 sub=eng:belt need=pEng
54757 g t 0 e3603 dgv alt=54998 sub=eng:gloves need=pEng
54758 g s 0 e3604 gv rec=@dd alt=54999 sub=eng:gloves need=pEng
54861 g s 0 e3606 gv alt=55016 sub=eng:boots need=pEng
55001 g s 0 e3605 g rec=* alt=55002,63765,e3859 sub=eng:cloak need=pEng
55754 d t 0 - dr rec=3 alt=55749,55750,55751,55752,55753 sub=debuff:armor
55915 g s 0 i42128 gv alt=i42129,i42130,i42131,i42132,i42133,i42134,i42135,i42136,i42137,67596 sub=trinket:pvp need=w
56121 g s 0 i42341 gv sub=trinket need=w
56184 g s 0 i42395 g sub=trinket need=w
56186 g s 0 i42413 g sub=trinket need=w
57079 x s 0 i34762 x sub=food
57097 x s 0 i34763 x sub=food
57100 x s 0 i34764 x sub=food
57102 x s 0 i42942 x sub=food
57107 x s 0 i34765 x sub=food
57111 x s 0 i34748 x sub=food
57139 x s 0 i34749 x sub=food
57286 x s 0 i34750 x alt=i39691 sub=food
57288 x s 0 i34751 x alt=i34125 sub=food
57291 x s 0 i34752 x sub=food
57294 x s 0 i43268 x rec=@dd alt=i34753,i43480 sub=food:feast
57325 x s 0 i34754 x rec=@dd+phys alt=i34766 sub=food
57327 x s 0 i34755 x rec=@dd+spell,@heal alt=i34767 sub=food
57329 x s 0 i34756 x rec=@dd alt=i34768 sub=food
57332 x s 0 i34757 x rec=@dd+spell,4 alt=i34769 sub=food
57334 x s 0 i34758 x rec=@heal alt=i42993 sub=food
57350 g s 0 i42988 g sub=trinket need=w
57356 x s 0 i42994 x rec=@dd+melee,@tank sub=food
57358 x s 0 i42995 x rec=@dd+phys sub=food
57360 x s 0 i42996 x rec=@dd alt=i44953 sub=food
57365 x s 0 i42998 x rec=@heal sub=food
57367 x s 0 i42999 x rec=4,3,10:cat,7:enh_phys,7:enh_spell sub=food
57371 x s 0 i43000 x rec=1,6,2:ret_agi sub=food
57399 x s 0 i43015 x rec=@dd alt=i45279,i43478 sub=food:feast
58449 x s 0 i43466 x alt=i43465,58448,i33462,43199 sub=scroll
58451 x s 0 i43464 x alt=i43463,58450,i33457,43194 sub=scroll
58453 x s 0 i43468 x alt=i43467,58452,i33459,43196 sub=scroll
58984 b s 0 r av sub=racial need=rNightElf,fA
58984 c s 0 r auv sub=racial need=rNightElf,fA
59043 g s 0 i43613 g sub=weapon need=w
59752 c s 0 r av sub=racial need=rHuman,fA
59757 g s 0 i44063 g sub=trinket need=w
59821 g s 0 i44073 g alt=i44869 sub=trinket need=w
60054 g s 0 i40683 g sub=trinket need=w
60180 g s 0 i37638 g alt=i39292 sub=trinket need=w
60215 g s 0 i37872 g sub=trinket need=w
60258 g s 0 i40372 g sub=trinket need=w
60286 g s 0 i40257 g sub=trinket need=w
60299 g s 0 i37723 g sub=trinket need=w
60305 g s 0 i37166 g sub=trinket need=w
60319 g s 0 i40531 g sub=trinket need=w
60340 x s 0 i44325 x sub=elixir:battle
60341 x s 0 i44327 x sub=elixir:battle
60343 x s 0 i44328 x rec=@tank sub=elixir:guardian
60344 x s 0 i44329 x rec=@dd+melee,@tank sub=elixir:battle
60345 x s 0 i44330 x rec=@dd+phys sub=elixir:battle
60346 x s 0 i44331 x sub=elixir:battle
60347 x s 0 i44332 x rec=@dd+spell sub=elixir:guardian
60439 g s 0 i39257 g sub=trinket need=w
60480 g s 0 i37873 g sub=trinket need=w
60517 g s 0 i37734 g alt=60518 sub=trinket need=w
60521 g s 0 i37844 g sub=trinket need=w
60527 g s 0 i39388 g sub=trinket need=w
62380 x s 0 i44939 x sub=flask
64524 g s 0 i46086 g alt=i46087,64525,i46088,64527 sub=trinket need=w
64707 g s 0 i45466 g sub=trinket need=w
64712 g s 0 i45148 g sub=trinket need=w
64763 g s 0 i45158 g sub=trinket need=w
64800 g s 0 i45263 g sub=trinket need=w
64999 g s 0 i46051 g sub=trinket need=w
65008 g s 0 i45292 g sub=trinket need=w
65011 g s 0 i45313 g sub=trinket need=w
65012 g s 0 i46021 g sub=trinket need=w
65116 b s 0 r av sub=racial need=rDwarf
65410 x s 0 i46887 x alt=65412,65414,65416,66623 sub=food:event
65724 b s 0 - b alt=67213,67214,67215 sub=boss:toc
65748 b s 0 - b alt=67216,67217,67218 sub=boss:toc
65802 b t 0 - bd rec=@dd sub=boss:toc
65858 b t 0 - bd rec=@dd alt=67259,67260,67261 sub=boss:toc
65874 b t 0 - bd rec=@dd alt=67256,67257,67258 sub=boss:toc
65879 b t 0 - bd rec=@tank,@heal alt=67244,67245,67246,65916,67248,67249,67250 sub=boss:toc
65950 d s 0 - b alt=67296,67297,67298 sub=boss:toc
65980 b t 0 - bd sub=boss:toc
65983 b t 0 - bd sub=boss:toc
66001 d s 0 - b alt=67281,67282,67283 sub=boss:toc
66009 b t 0 b abd alt=10278 sub=boss:toc
66010 b t 0 - bd sub=boss:toc
66011 b t 0 - bd sub=boss:toc
66012 d s 0 - b rec=@tank sub=boss:toc need=uTank
66013 d s 0 - b alt=67700,68509,68510 sub=boss:toc
66046 d s 0 - b alt=67206,67207,67208 sub=boss:toc
66058 d s 0 - b alt=67182,67183,67184 sub=boss:toc
66063 b t 0 - bd sub=boss:toc
66118 b t 0 - bd rec=@dd alt=67630,68646,68647 sub=boss:toc
66197 d s 0 - b alt=68123,68124,68125 sub=boss:toc
66228 b t 0 - bd alt=67106,67107,67108 sub=boss:toc
66237 d s 0 - b rec=@heal alt=67049,67050,67051 sub=boss:toc
66331 d s 0 - b rec=@tank,@heal alt=67477,67478,67479 sub=boss:toc need=uTank
66334 d s 0 - b alt=67905,67906,67907 sub=boss:toc
66532 d s 0 - b rec=@heal alt=66963,66964,66965 sub=boss:toc
66636 d t 0 - bd rec=@tank,@heal sub=boss:toc
66689 d s 0 - b rec=@tank,@heal alt=67650,67651,67652 sub=boss:toc
66758 b t 0 - bd rec=@dd sub=boss:toc
66759 b t 0 - bd alt=67657,67658,67659 sub=boss:toc
66823 d s 0 - b alt=67618,67619,67620 sub=boss:toc
66869 d s 0 - b sub=boss:toc
67016 x s 0 i47499 x alt=67017,67018 sub=flask
67176 b s 0 - b alt=65684,67177,67178 sub=boss:toc
67223 b s 0 - b alt=65686,67222,67224 sub=boss:toc
67574 d s 0 - b sub=boss:toc
67683 g s 0 i48722 g rec=@dd sub=trinket need=w
67684 g s 0 i48724 g rec=@heal sub=trinket need=w
67694 g s 0 i47735 g rec=@tank sub=trinket need=w
67695 g s 0 i47734 g rec=@dd+phys sub=trinket need=w
67699 g s 0 i47080 g rec=@tank alt=i47290,i47088,i47451,67753 sub=trinket need=w
67726 g s 0 i47728 g rec=@heal alt=i47880,i47947,i48019,67740 sub=trinket need=w
67728 g s 0 i47727 g rec=@tank alt=i47882,i47949,i48021,67742 sub=trinket need=w
67736 g s 0 i47726 g rec=@dd+spell alt=i47879,i47946,i48018,67744 sub=trinket need=w
67738 g s 0 i47725 g rec=@dd+phys alt=i47881,i47948,i48020,67747 sub=trinket need=w
67769 g t 0 i40771 dg sub=eng:explosive need=pEng
67799 g t 0 e3878 dgv alt=67839,i48945 sub=eng:helm need=pEng
67847 d s 0 - b rec=@tank,@heal alt=67721 sub=boss:toc need=uTank
67890 g t 0 e3601 dgv alt=54793 sub=eng:belt need=pEng
68758 b t 0 - bd alt=66115,68756,68757 sub=boss:toc
68980 d s 0 - b alt=74325,74326,74327 sub=boss:icc
69065 d s 0 - b sub=boss:icc
69076 b t 0 - bd sub=boss:icc
69166 d t 0 - bd alt=71912 sub=boss:icc
69180 g t 0 i49437 dg alt=i49465,69181 sub=weapon need=w
69207 g s 0 i49303 g alt=i49495,69208 sub=weapon need=w
69240 d s 0 - b rec=@dd,@heal alt=71218,73019,73020 sub=boss:icc
69242 d s 0 - b alt=73800,73801,73802 sub=boss:icc
69279 d s 0 - b sub=boss:icc
69291 d s 0 - b alt=72101,72102,72103 sub=boss:icc
69409 d s 0 - b rec=@tank alt=73797,73798,73799 sub=boss:icc need=uTank
69638 d t 0 - bd rec=@tank,@heal alt=72306,72307,72308 sub=boss:icc
69651 d s 0 - b rec=@tank,@heal alt=72569,72570,72571 sub=boss:icc
69652 b t 0 - bd rec=@dd+melee sub=boss:icc
69674 d s 0 - b rec=@heal alt=71224,73022,73023 sub=boss:icc
69762 d s 0 - b rec=@dd+spell,@heal sub=boss:icc
69766 d s 0 - b rec=@dd+spell sub=boss:icc
70106 d s 0 - b rec=@dd+melee,@tank sub=boss:icc
70126 d s 0 - b sub=boss:icc
70127 d s 0 - b alt=72528,72529,72530,70128 sub=boss:icc
70157 d s 0 - b sub=boss:icc
70337 d s 0 - b alt=73912,73913,73914,70338,73785,73786,73787 sub=boss:icc
70352 d s 0 - b alt=74118 sub=boss:icc
70353 d s 0 - b alt=74119 sub=boss:icc
70447 d s 0 - b alt=72836,72837,72838 sub=boss:icc
70539 d s 0 - b rec=@tank,@heal alt=72457,72875,72876 sub=boss:icc
70541 d s 0 - b rec=@heal alt=73779,73780,73781 sub=boss:icc
70542 d s 0 - b rec=@tank,@heal sub=boss:icc
70633 d s 0 - b rec=@tank,@heal alt=71283,72025,72026 sub=boss:icc need=uTank
70672 d s 0 - b alt=72455,72832,72833 sub=boss:icc
70674 b t 0 - bd sub=boss:icc
70751 d s 0 - b rec=@tank,@heal alt=71738,72021,72022 sub=boss:icc need=uTank
70838 b s 0 - b rec=@tank alt=71510 sub=boss:icc need=uTank
70842 b t 0 - bd sub=boss:icc
70867 b s 0 - b rec=@dd,@heal alt=71473,71532,71533 sub=boss:icc
70873 d s 0 - b sub=boss:icc
70877 d s 0 - b alt=71474 sub=boss:icc
70879 b s 0 - b rec=@dd,@heal alt=71525,71530,71531 sub=boss:icc
70911 d s 0 - b alt=72854,72855,72856 sub=boss:icc
70923 d s 0 - b sub=boss:icc
70952 b t 0 - bd rec=@tank,@dd alt=70981,70982 sub=boss:icc
71204 d s 0 - b rec=@tank,@heal sub=boss:icc need=uTank
71237 d s 0 - b sub=boss:icc
71277 d s 0 - b alt=72638,72639,72640 sub=boss:icc
71289 d s 0 - b sub=boss:icc
71340 d s 0 - b sub=boss:icc
71563 g s 0 i50259 g rec=@dd+spell alt=71564 sub=trinket need=w
71568 g s 0 i50260 g rec=@dd sub=trinket need=w
71569 g s 0 i50235 g rec=@tank sub=trinket need=w
71579 g s 0 i50357 g rec=@heal,@dd+spell sub=trinket need=w
71586 g s 0 i50356 g rec=@tank sub=trinket need=w
71635 g s 0 i50361 g alt=i50364,71638 sub=trinket need=w
71807 d s 0 - b alt=72796,72797,72798 sub=boss:icc
71864 g g 0 i50028 gr rec=@heal alt=i50685,71866 sub=weapon need=w
71941 d s 0 - b alt=71940 sub=boss:icc
72143 b t 0 - bd alt=72146,72147,72148 sub=boss:icc
72219 d s 0 - b rec=@tank,@heal alt=72551,72552,72553 sub=boss:icc need=uTank
72272 d s 0 - b rec=@dd,@heal alt=72273 sub=boss:icc
72293 d s 0 - b sub=boss:icc
72371 d t 0 - bd rec=@tank,@heal alt=72370 sub=boss:icc
72410 d s 0 - b rec=@tank,@heal sub=boss:icc need=uTank
72441 d s 0 - b rec=@heal alt=72385,72442,72443 sub=boss:icc
72451 d s 0 - b rec=@tank,@heal alt=72463,72671,72672 sub=boss:icc need=uTank
72550 d s 0 - b alt=72297,72548,72549 sub=boss:icc
72586 x g 0 i49633 rx rec=* alt=69378 sub=drums
72588 x g 0 i49634 rx rec=* alt=69381 sub=drums
72590 x g 0 i49632 rx rec=* alt=69377 sub=scroll
72620 d s 0 - b alt=71278,72460,72619 sub=boss:icc
72737 b t 0 - bd sub=boss:icc
72966 d s 0 - b rec=@heal alt=72963,72964,72965 sub=boss:icc
72999 d s 0 - b sub=boss:icc
73070 d s 0 - b sub=boss:icc
74367 d s 0 - b rec=@tank,@heal sub=boss:rs need=uTank
74384 d s 0 - b sub=boss:rs
74453 d s 0 - b sub=boss:rs
74456 d s 0 - b sub=boss:rs
74505 d s 0 - b alt=74502 sub=boss:rs
74562 d s 0 - b sub=boss:rs
74567 d s 0 - b sub=boss:rs
74792 d s 0 - b sub=boss:rs
74795 d s 0 - b sub=boss:rs
74807 b s 0 - b sub=boss:rs
74826 b t 0 - bd alt=74827,74828,74829,74830,74831,74832,74833,74834,74835,74836 sub=boss:rs
75125 b t 0 - bd rec=@dd+melee sub=boss:rs
75477 g s 0 i54571 g rec=@tank alt=i54591,75480 sub=trinket need=w
75490 g s 0 i54573 g rec=@heal alt=75493,i54589,75495,75494 sub=trinket need=w
78722 b t 0 - bd sub=boss:rs
i20520 x s 0 - x rec=@mana alt=i12662 sub=rune
i22044 x s 0 - x sub=gem
i23529 x s 0 - x alt=29453,i23528,i18262 sub=stone
i23824 g s 0 - gv alt=i35581,51582 sub=eng:boots need=pEng
i23825 g s 0 - gv alt=30458 sub=eng:belt need=pEng
i23836 g t 0 - dg sub=eng:item need=pEng
i28421 x s 0 - x alt=34340,i28420 sub=stone
i33447 x s 0 - vx rec=* alt=i39671,i43569 sub=potion:heal
i33448 x s 0 - vx rec=@mana alt=i40067,i43570 sub=potion:mana
i34538 x s 0 - x alt=i34539,45395,45397 sub=stone
i36894 x s 0 - vx rec=* alt=i36893,i36892,i36891,i36890,i36889,i22105,i22104,i22103 sub=healthstone
i36899 x s 0 - x rec=@heal alt=47904,i22521,i20748 sub=oil
i36900 x s 0 - x rec=@dd+spell,@heal alt=47906,i22522,i20749 sub=oil
i40077 x s 0 - x sub=potion:heal
i40087 x s 0 - x sub=potion:heal
i40536 g s 0 - g alt=54359 sub=eng:explosive need=pEng
i40772 g s 0 - g alt=54732 sub=eng:item need=pEng
i41119 g t 0 - dg alt=56350 sub=eng:explosive need=pEng
i41121 g t 0 - dg sub=eng:item need=pEng
i41166 x s 0 - x sub=potion:heal
i41976 x s 0 - vx alt=55836,i33185,42687 sub=chain
i42545 x s 0 - x sub=potion:mana
i42641 g t 0 - dg alt=56488 sub=eng:explosive need=pEng
i47828 g t 0 - dg alt=67324 sub=eng:item need=pEng
i48933 g s 0 - g alt=67833 sub=eng:item need=pEng
i49040 g s 0 - g alt=67826 sub=eng:item need=pEng
]]
ns.catalogNames = [[
e2 Ледяное клеймо 1|Frostbrand 1
e12 Ледяное клеймо 2|Frostbrand 2
e524 Ледяное клеймо 3|Frostbrand 3
e912 Истребитель демонов|Demonslaying
e1003 Яд равазавра|Venomhide Poison
e1667 Ледяное клеймо 4|Frostbrand 4
e1668 Ледяное клеймо 5|Frostbrand 5
e1894 Ледяное оружие|Icy Weapon
e1899 Нечестивое оружие|Unholy Weapon
e1900 Рыцарь|Crusader
e2635 Ледяное клеймо 6|Frostbrand 6
e2673 Мангуст|Mongoose
e2828 Шанс увеличить скорость произнесения заклинаний|Chance to Increase Spell Cast Speed
e2834 +3 к урону ближнего боя и вероятность оглушить противника|+3 Melee Damage and Chance to Stun Target
e3155 Шанс увеличить скорость атаки в ближнем и дальнем бою|Chance to Increase Melee/Ranged Attack Speed
e3225 Палач|Executioner
e3251 Истребитель великанов|Giantslaying
e3273 Смертельный лед|Deathfrost
e3290 Капюшон-парашют|Spring Loaded Cape Expander
e3291 Test On Use Charges|Test On Use Charges
e3345 Жизнь Земли 1|Earthliving 1
e3346 Жизнь Земли 2|Earthliving 2
e3347 Жизнь Земли 3|Earthliving 3
e3348 Жизнь Земли 4|Earthliving 4
e3349 Жизнь Земли 5|Earthliving 5
e3368 Руна павшего рыцаря|Rune of the Fallen Crusader
e3369 Руна оплавленного ледника|Rune of Cinderglacier
e3370 Руна ледяного жара|Rune of Razorice
e3599 Генератор электромагнитного импульса|Electromagnetic Pulse Generator
e3601 Наременные осколочные бомбы|Frag Belt
e3603 Нарукавная зажигательная ракетница|Hand-Mounted Pyro Rocket
e3604 Гиперскоростные ускорители|Hyperspeed Accelerators
e3605 Эластичная подкладка|Flexweave Underlay
e3606 +24 к рейтингу критического удара|+24 Critical Strike Rating
e3627 +21 к интеллекту и вероятность восполнить ману при применении заклинаний|+21 Intellect and Chance to restore mana on spellcast
e3640 +42 к силе атаки и периодическое восстановление здоровья при критических ударах|+42 Attack Power and Sometimes Heal on Your Crits
e3643 Шанс увеличить скорость атаки в ближнем и дальнем бою|Chance to Increase Melee/Ranged Attack Speed
e3722 Светлотканая вышивка|Lightweave Embroidery
e3728 Вышивка темного сияния|Darkglow Embroidery
e3730 Вышивка в виде рукояти меча|Swordguard Embroidery
e3782 Ледяное клеймо 7|Frostbrand 7
e3783 Ледяное клеймо 8|Frostbrand 8
e3789 Боевое исступление|Berserking
e3790 Черная магия|Black Magic
e3869 Отведение удара|Blade Ward
e3870 Вытягивание крови|Blood Draining
e3878 Транслятор нервных импульсов|Mind Amplification Dish
i20520 Темная руна|Dark Rune
i22044 Изумруд маны|Mana Emerald
i23529 Адамантитовое точило|Adamantite Sharpening Stone
i28421 Адамантитовое грузило|Adamantite Weightstone
i29528 Барабаны войны|Drums of War
i29529 Барабаны битвы|Drums of Battle
i29530 Барабаны скорости|Drums of Speed
i29531 Барабаны восстановления|Drums of Restoration
i33350 Арт-проект Ледяной Скорби|Frostmourne Art Demo
i33447 Рунический флакон с лечебным зельем|Runic Healing Potion
i33448 Рунический флакон с зельем маны|Runic Mana Potion
i34538 Эмульсия благословенного оружия|Blessed Weapon Coating
i34722 Плотные бинты из ледяной ткани|Heavy Frostweave Bandage
i34748 Кушанье из мамонта|Mammoth Meal
i34749 Стейк из черпорога|Shoveltusk Steak
i34750 Деликатес из змея|Worm Delight
i34751 Жареный ворг|Roasted Worg
i34752 Сосиски из люторога|Rhino Dogs
i34754 Сытное кушанье из мамонта|Mega Mammoth Meal
i34755 Нежный стейк из черпорога|Tender Shoveltusk Steak
i34756 Котлета из змея с пряностями|Spiced Worm Burger
i34757 Пережаренное мясо ворга|Very Burnt Worg
i34758 Сочные сосиски из люторога|Mighty Rhino Dogs
i34762 Подкаменщик-гриль|Grilled Sculpin
i34763 Копченый лосось|Smoked Salmon
i34764 Вареная медуза|Poached Nettlefish
i34765 Маринованная клыкозубая сельдь|Pickled Fangtooth
i36894 Камень здоровья из Скверны|Fel Healthstone
i36899 Особое зелье маны|Exceptional Mana Oil
i36900 Особое волшебное масло|Exceptional Wizard Oil
i37092 Свиток интеллекта VIII|Scroll of Intellect VIII
i37094 Свиток выносливости VIII|Scroll of Stamina VIII
i37098 Свиток духа VIII|Scroll of Spirit VIII
i37166 Сфера крови красного дракона|Sphere of Red Dragon's Blood
i37220 Квинтэссенция паутины|Essence of Gossamer
i37254 Сфера сверхобезьяны|Super Simian Sphere
i37264 Маятник подземных течений|Pendulum of Telluric Currents
i37390 Метеоритный оселок|Meteorite Whetstone
i37638 Жертвоприношение|Offering of Sacrifice
i37657 Искра жизни|Spark of Life
i37660 Кузнечный жар|Forge Ember
i37723 Кусок резца|Incisor Fragment
i37734 Талисман тролльского божества|Talisman of Troll Divinity
i37835 Колокол Дже'Тце|Je'Tze's Bell
i37844 Крылатый талисман|Winged Talisman
i37872 Талисман Лавантора|Lavanthor's Talisman
i37873 Метка арестанта|Mark of the War Prisoner
i39229 Облачение Паука|Embrace of the Spider
i39257 Тень Лотхиба|Loatheb's Shadow
i39388 Стеклышко духовного мира|Spirit-World Glass
i39666 Мощный эликсир ловкости|Elixir of Mighty Agility
i40068 Эликсир гнева|Wrath Elixir
i40070 Эликсир силы заклинаний|Spellpower Elixir
i40072 Эликсир духа|Elixir of Spirit
i40073 Мощный эликсир силы|Elixir of Mighty Strength
i40076 Эликсир гуру|Guru's Elixir
i40077 Зелье сумасшедшего алхимика|Crazy Alchemist's Potion
i40078 Мощный эликсир стойкости|Elixir of Mighty Fortitude
i40079 Слабый настой крепости|Lesser Flask of Toughness
i40087 Мощное зелье омоложения|Powerful Rejuvenation Potion
i40093 Зелье несокрушимости|Indestructible Potion
i40097 Охранный эликсир|Elixir of Protection
i40109 Мощный эликсир крови волшебника|Elixir of Mighty Mageblood
i40211 Зелье быстроты|Potion of Speed
i40212 Зелье дикой магии|Potion of Wild Magic
i40213 Мощное зелье защиты от тайной магии|Mighty Arcane Protection Potion
i40214 Мощное зелье защиты от огня|Mighty Fire Protection Potion
i40215 Мощное зелье защиты от магии льда|Mighty Frost Protection Potion
i40216 Мощное зелье защиты от сил природы|Mighty Nature Protection Potion
i40217 Мощное зелье защиты от темной магии|Mighty Shadow Protection Potion
i40255 Исчезающее проклятие|Dying Curse
i40256 Мрачный перезвон|Grim Toll
i40257 Кодекс защитника|Defender's Code
i40258 Талисман предусмотрительности|Forethought Talisman
i40322 Тотем поединка|Totem of Dueling
i40371 Знак отличия Бандита|Bandit's Insignia
i40372 Руна отражения|Rune of Repulsion
i40373 Экстракт некромантского могущества|Extract of Necromantic Power
i40382 Душа умершего|Soul of the Dead
i40430 Величественная статуэтка дракона|Majestic Dragon Figurine
i40431 Неистовство Пяти полетов|Fury of the Five Flights
i40432 Изображение души дракона|Illustration of the Dragon Soul
i40531 Знак Норганнона|Mark of Norgannon
i40682 Солнечные часы изгнанника|Sundial of the Exiled
i40683 Медаль Первой войны "За отвагу"|Valor Medal of the First War
i40684 Правдивое зеркальце|Mirror of Truth
i40685 Яйцо смертной сущности|The Egg of Mortal Essence
i40706 Манускрипт ответных действий|Libram of Reciprocation
i40707 Манускрипт преграды|Libram of Obstruction
i40708 Тотем Обители стихий|Totem of the Elemental Plane
i40714 Печать недрогнувшего рыцаря|Sigil of the Unfaltering Knight
i40715 Печать Неспокойных снов|Sigil of Haunted Dreams
i40754 ИСКЛЮЧЕНО Огненно-красное катапультируемое кресло|DEPRECATED Flame Red Ejector Seat
i41121 Гномский генератор молний|Gnomish Lightning Generator
i41166 Рунический набор для лечебных инъекций|Runic Healing Injector
i41976 Титановая цепь для оружия|Titanium Weapon Chain
i42128 Злость Военачальника|Battlemaster's Hostility
i42341 Статуэтка рубинового зайца|Figurine - Ruby Hare
i42395 Статуэтка сумеречной змеи|Figurine - Twilight Serpent
i42413 Статуэтка сапфировой совы|Figurine - Sapphire Owl
i42545 Рунический набор для инъекций маны|Runic Mana Injector
i42575 Идол непреклонности свирепого гладиатора|Savage Gladiator's Idol of Steadfastness
i42582 Идол непреклонности злобного гладиатора|Hateful Gladiator's Idol of Steadfastness
i42583 Идол непреклонности смертоносного гладиатора|Deadly Gladiator's Idol of Steadfastness
i42584 Идол непреклонности гневного гладиатора|Furious Gladiator's Idol of Steadfastness
i42585 Идол непреклонности неумолимого гладиатора|Relentless Gladiator's Idol of Steadfastness
i42589 Идол решимости гневного гладиатора|Furious Gladiator's Idol of Resolve
i42591 Идол решимости неумолимого гладиатора|Relentless Gladiator's Idol of Resolve
i42641 Сверхмощный заряд термической саперной взрывчатки|Global Thermal Sapper Charge
i42942 Печеный морской дьявол|Baked Manta Ray
i42987 Карта Новолуния: Величие|Darkmoon Card: Greatness
i42988 Карта Новолуния: Иллюзия|Darkmoon Card: Illusion
i42989 Карта Новолуния: Берсерк!|Darkmoon Card: Berserker!
i42990 Карта Новолуния: Смерть|Darkmoon Card: Death
i42994 Люторожий змеестейк|Rhinolicious Wormsteak
i42995 Сочное мясо люторога|Hearty Rhino
i42996 Луциан особого приготовления|Snapper Extreme
i42998 Стейк из каракатицы|Cuttlesteak
i42999 Подкопченная дракоперая рыба-ангел|Blackened Dragonfin
i43000 Филе дракоперой рыбы-ангела|Dragonfin Filet
i43015 Рыбный пир|Fish Feast
i43268 Даларанская похлебка из моллюсков|Dalaran Clam Chowder
i43464 Свиток ловкости VIII|Scroll of Agility VIII
i43466 Свиток силы VIII|Scroll of Strength VIII
i43468 Свиток защиты VIII|Scroll of Protection VIII
i43573 Слезы горькой тоски|Tears of Bitter Anguish
i43613 Клинок сумрака|The Dusk Blade
i44063 Статуэтка королевского краба|Figurine - Monarch Crab
i44073 Знак неистовства Бешеного Сердца|Frenzyheart Insignia of Fury
i44308 Перстень Эдварда Странного|Signet of Edward the Odd
i44325 Эликсир меткости|Elixir of Accuracy
i44327 Эликсир смертельных ударов|Elixir of Deadly Strikes
i44328 Мощный эликсир защиты|Elixir of Mighty Defense
i44329 Эликсир мастерства|Elixir of Expertise
i44330 Эликсир пробивания брони|Elixir of Armor Piercing
i44331 Эликсир молниеносности|Elixir of Lightning Speed
i44332 Мощный эликсир разума|Elixir of Mighty Thoughts
i44939 Малый настой сопротивления|Lesser Flask of Resistance
i45131 Ярость бретера|Jouster's Fury
i45144 Печать отражения|Sigil of Deflection
i45145 Манускрипт священного щита|Libram of the Sacred Shield
i45148 Живой жар|Living Flame
i45158 Железное сердце|Heart of Iron
i45263 Колдовской камень|Wrathstone
i45286 Колчедановый нагнетатель|Pyrite Infuser
i45292 Вытягивание энергии|Energy Siphon
i45308 Глаз Праматери|Eye of the Broodmother
i45313 Печной камень|Furnace Stone
i45466 Чешуйка судеб|Scale of Fates
i45490 Мольба Пандоры|Pandora's Plea
i45507 Сердце генерала|The General's Heart
i45509 Идол растлителя|Idol of the Corruptor
i45518 Небесная вспышка|Flare of the Heavens
i45522 Кровь Древнего Бога|Blood of the Old God
i45535 Доказательство веры|Show of Faith
i45609 Хвост кометы|Comet's Trail
i45866 Камень средоточия стихий|Elemental Focus Stone
i45929 Воспоминание Сиф|Sif's Remembrance
i45931 Рунический камень Мьольнира|Mjolnir Runestone
i46017 Вал'анир, молот древних королей|Val'anyr, Hammer of Ancient Kings
i46021 Печать короля Ллейна|Royal Seal of King Llane
i46038 Темная сущность|Dark Matter
i46051 Метеоритный кристалл|Meteorite Crystal
i46086 Платиновые диски битвы|Platinum Disks of Battle
i46104 Майка йоггоборца|Shirt of the Yogg-Slayer
i46376 Настой ледяного змея|Flask of the Frost Wyrm
i46377 Настой бесконечной ярости|Flask of Endless Rage
i46378 Настой чистого колдунства|Flask of Pure Mojo
i46379 Настой каменной крови|Flask of Stoneblood
i47041 Утешение поверженных|Solace of the Defeated
i47059 Утешение побежденных|Solace of the Defeated
i47080 Упрямый скарабей Сатрины|Satrina's Impeding Scarab
i47115 Приговор смерти|Death's Verdict
i47131 Приговор смерти|Death's Verdict
i47182 Власть неживых|Reign of the Unliving
i47188 Власть неживых|Reign of the Unliving
i47213 Руна Бездны|Abyssal Rune
i47214 Знамя победы|Banner of Victory
i47215 Слезы поверженных|Tears of the Vanquished
i47216 Черное сердце|The Black Heart
i47499 Настой севера|Flask of the North
i47661 Манускрипт отваги|Libram of Valiance
i47662 Манускрипт правдивости|Libram of Veracity
i47664 Манускрипт неповиновения|Libram of Defiance
i47665 Тотем успокаивающих приливов|Totem of Calming Tides
i47666 Тотем электризирующего ветра|Totem of Electrifying Wind
i47667 Тотем колыхающейся земли|Totem of Quaking Earth
i47668 Идол искажения|Idol of Mutilation
i47670 Идол лунной ярости|Idol of Lunar Fury
i47671 Идол внезапного роста|Idol of Flaring Growth
i47672 Печать дерзости|Sigil of Insolence
i47673 Печать болезнетворности|Sigil of Virulence
i47725 Зов победителя|Victor's Call
i47726 Талисман неустойчивой силы|Talisman of Volatile Power
i47727 Страсть Зиморожденных|Fervor of the Frostborn
i47728 Связующий свет|Binding Light
i47734 Знак превосходства|Mark of Supremacy
i47735 Символ неукротимости|Glyph of Indomitability
i47828 Гоблинский лучевой трансформатор|Goblin Beam Welder
i47946 Талисман неустойчивой силы|Talisman of Volatile Power
i47947 Связующий свет|Binding Light
i47948 Зов победителя|Victor's Call
i47949 Страсть Зиморожденных|Fervor of the Frostborn
i48722 Осколок хрустального сердца|Shard of the Crystal Heart
i48724 Талисман восстановления|Talisman of Resurgence
i49080 Сувенир буяна|Brawler's Souvenir
i49126 Ужасающий шлем Всадника|The Horseman's Horrific Helm
i49128 Губительный клинок Всадника|The Horseman's Baleful Blade
i49303 Искристый Кель'Серрар|Gleaming Quel'Serrar
i49437 Заржавелый потрошитель Гутгора|Rusted Gutgore Ripper
i49623 Темная Скорбь|Shadowmourne
i49632 Рунический свиток стойкости|Runescroll of Fortitude
i49633 Барабаны забытых королей|Drums of Forgotten Kings
i49634 Барабаны дикой природы|Drums of the Wild
i49982 Сердцекол|Heartpierce
i50028 Травма|Trauma
i50035 Черный убойник|Black Bruise
i50179 Последнее желание|Last Word
i50198 Покрытый иглами скорпион|Needle-Encrusted Scorpion
i50235 Гниющий палец Ика|Ick's Rotting Thumb
i50259 Нетающий кристалл льда|Nevermelting Ice Crystal
i50260 Эфемерная снежинка|Ephemeral Snowflake
i50340 Подзорная труба Мурадина|Muradin's Spyglass
i50341 Неизвестный орган|Unidentifiable Organ
i50342 Шепчущий клыкастый череп|Whispering Fanged Skull
i50343 Шепчущий клыкастый череп|Whispering Fanged Skull
i50344 Неизвестный орган|Unidentifiable Organ
i50345 Подзорная труба Мурадина|Muradin's Spyglass
i50348 Объект из другого измерения|Dislodged Foreign Object
i50349 Монета на удачу|Corpse Tongue Coin
i50351 Миниатюрное поганище в колбе|Tiny Abomination in a Jar
i50352 Монета на удачу|Corpse Tongue Coin
i50353 Объект из другого измерения|Dislodged Foreign Object
i50355 Геркумлийский боевой знак|Herkuml War Token
i50356 Проржавевший костяной ключ|Corroded Skeleton Key
i50357 Заговоренное перо Магхиа|Maghia's Misguided Quill
i50358 Очищенная лунная пыль|Purified Lunar Dust
i50359 Счеты Алтора|Althor's Abacus
i50360 Талисман безымянного лича|Phylactery of the Nameless Lich
i50361 Безупречный клык Синдрагосы|Sindragosa's Flawless Fang
i50362 Воля Смертоносного|Deathbringer's Will
i50363 Воля Смертоносного|Deathbringer's Will
i50365 Талисман безымянного лича|Phylactery of the Nameless Lich
i50366 Счеты Алтора|Althor's Abacus
i50397 Пепельное кольцо непревзойденного разрушения|Ashen Band of Unmatched Destruction
i50399 Пепельное кольцо непревзойденной мудрости|Ashen Band of Unmatched Wisdom
i50401 Пепельное кольцо непревзойденного отмщения|Ashen Band of Unmatched Vengeance
i50403 Пепельное кольцо непревзойденной отваги|Ashen Band of Unmatched Courage
i50454 Идол черной ивы|Idol of the Black Willow
i50455 Манускрипт трех истин|Libram of Three Truths
i50456 Идол плачущей луны|Idol of the Crying Moon
i50457 Идол лунного затмения|Idol of the Lunar Eclipse
i50458 Тотем расколотого льда Бизури|Bizuri's Totem of Shattered Ice
i50459 Печать повешенного|Sigil of the Hanged Man
i50460 Манускрипт слепящего света|Libram of Blinding Light
i50461 Манускрипт башни вечности|Libram of the Eternal Tower
i50462 Печать костяного грифона|Sigil of the Bone Gryphon
i50463 Тотем застывшей лавины|Totem of the Avalanche
i50464 Тотем бушующего моря|Totem of the Surging Sea
i50641 Сердцекол|Heartpierce
i50692 Черный убойник|Black Bruise
i50708 Последнее желание|Last Word
i50741 Маска злобного фумигатора|Vile Fumigator's Mask
i51378 Медальон Орды|Medallion of the Horde
i51417 Печать раздора разгневанного гладиатора|Wrathful Gladiator's Sigil of Strife
i51437 Идол непреклонности разгневанного гладиатора|Wrathful Gladiator's Idol of Steadfastness
i54569 Заостренная сумеречная чешуя|Sharpened Twilight Scale
i54571 Окаменелая сумеречная чешуя|Petrified Twilight Scale
i54572 Обугленная сумеречная чешуя|Charred Twilight Scale
i54573 Светящаяся сумеречная чешуя|Glowing Twilight Scale
i54588 Обугленная сумеречная чешуя|Charred Twilight Scale
i54590 Заостренная сумеречная чешуя|Sharpened Twilight Scale
i54591 Окаменелая сумеречная чешуя|Petrified Twilight Scale
i54806 Ледяная коса повелителя Ахуна|Frostscythe of Lord Ahune
S788 Броня неустрашимости|Dreadnaught Battlegear
S802 Облачение Проклятого Сердца|Plagueheart Garb
S821 Латы покровительства|Aegis Plate
S828 Наряд ночной песни|Nightsong Garb
S830 Осадная броня|Siegebreaker Battlegear
S832 Наряд посвящения|Sanctification Garb
S833 Регалии посвящения|Sanctification Regalia
S836 Кирин-торский наряд|Kirin Tor Garb
S838 Броня преследующего Плеть|Scourgestalker Battlegear
S857 Броня ван Клифа|VanCleef's Battlegear
S871 Броня Тассариана|Thassarian's Battlegear
S883 Регалии волшебника крови|Bloodmage's Regalia
S884 Регалии мрачного шабаша|Dark Coven's Regalia
S888 Плеточные регалии|Lasherweave Regalia
S891 Броня ан'кахарского охотника за кровью|Ahn'Kahar Blood Hunter's Battlegear
S892 Одеяния ледяной ведьмы|Frost Witch's Garb
S894 Броня ледяной ведьмы|Frost Witch's Battlegear
S895 Броня имирьярского повелителя|Ymirjar Lord's Battlegear
S896 Латы имирьярского повелителя|Ymirjar Lord's Plate
S897 Броня повелителя Плети|Scourgelord's Battlegear
S898 Латы повелителя Плети|Scourgelord's Plate
S899 Одеяния клятвы Свету|Lightsworn Garb
S901 Латы клятвы Свету|Lightsworn Plate
]]
