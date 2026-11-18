-- =================================================================================
-- KOPLINGTIFY LITE v2.5 - MULTI-POINT PHONETIC & ANTI-ODER FILTER (KOPLINGTIFY_FILTER.luau)
-- =================================================================================
local FilterModule = {}

-- Pilihan Mode Bypass:
-- 1 = Phonetic Multi-Point + Soft-H (Contoh: "dhengarkan ahku ku ihngin menjhadi phacharmu") -> PALING AMAN
-- 2 = Alternative Phonetic / X-Mask
-- 3 = Phonetic Split
FilterModule.BypassMode = 1

local directBypassMap = {
    -- ==================== ANTI-ONLINE DATING (ODer) & ROMANCE CONTEXT (ID) ====================
    ["aku"]           = {"ahku", "4ku", "a ku"},
    ["kamu"]          = {"khamu", "k4mu", "ka mu"},
    ["kamunya"]       = {"khamunya", "k4munya", "kamu nya"},
    ["kau"]           = {"khau", "k4u", "ka u"},
    ["engkau"]        = {"engkhau", "3ngkau", "eng kau"},
    ["dirimu"]        = {"dihrimu", "dIrimu", "di rimu"},
    ["diriku"]        = {"dihriku", "dIriku", "di riku"},
    ["dirinya"]       = {"dihrinya", "dIrinya", "di rinya"},
    ["dengar"]        = {"dhengar", "d3ngar", "de ngar"},
    ["dengarkan"]     = {"dhengarkan", "d3ngarkan", "de ngarkan"},
    ["dengarkanlah"]  = {"dhengarkanlah", "d3ngarkanlah", "de ngarkanlah"},
    ["ingin"]         = {"ihngin", "Ingin", "i ngin"},
    ["kuingin"]       = {"kuihngin", "kuIngin", "ku ingin"},
    ["inginkan"]      = {"ihnginkan", "Inginkan", "i nginkan"},
    ["kuinginkan"]    = {"kuihnginkan", "kuInginkan", "ku inginkan"},
    ["menginginkan"]  = {"mengihnginkan", "mengInginkan", "meng inginkan"},
    ["jadi"]          = {"jhadi", "j4di", "ja di"},
    ["menjadi"]       = {"menjhadi", "menj4di", "men jadi"},
    ["pacar"]         = {"phachar", "p4car", "pa car"},
    ["pacarku"]       = {"phacharku", "p4carku", "pa carku"},
    ["pacarmu"]       = {"phacharmu", "p4carmu", "pa carmu"},
    ["pacaran"]       = {"phacharan", "p4caran", "pa caran"},
    ["berpacaran"]    = {"berphacharan", "berp4caran", "ber pacaran"},
    ["kekasih"]       = {"kekhasih", "kek4sih", "ke kasih"},
    ["kekasihku"]     = {"kekhasihku", "kek4sihku", "ke kasihku"},
    ["kekasihmu"]     = {"kekhasihmu", "kek4sihmu", "ke kasihmu"},
    ["pasangan"]      = {"phasangan", "p4sangan", "pa sangan"},
    ["pasanganku"]    = {"phasanganku", "p4sanganku", "pa sanganku"},
    ["pasanganmu"]    = {"phasanganmu", "p4sanganmu", "pa sanganmu"},
    ["jodoh"]         = {"jhodoh", "j0doh", "jo doh"},
    ["jodohku"]       = {"jhodohku", "j0dohku", "jo dohku"},
    ["jodohmu"]       = {"jhodohmu", "j0dohmu", "jo dohmu"},
    ["milik"]         = {"mihlik", "mIlIk", "mi lik"},
    ["milikku"]       = {"mihlikku", "mIlIkku", "mi likku"},
    ["milikmu"]       = {"mihlikmu", "mIlIkmu", "mi likmu"},
    ["memiliki"]      = {"memihliki", "memIlIki", "me miliki"},
    ["memilikimu"]    = {"memihlikimu", "memIlIkimu", "me milikimu"},
    ["nikah"]         = {"nihkah", "nIkah", "ni kah"},
    ["menikah"]       = {"menihkah", "menIkah", "me nikah"},
    ["menikahimu"]    = {"menihkahimu", "menIkahimu", "me nikahimu"},
    ["suami"]         = {"suhami", "svami", "su ami"},
    ["suamiku"]       = {"suhamiku", "svamiku", "su amiku"},
    ["istri"]         = {"ihstri", "Istri", "is tri"},
    ["istriku"]       = {"ihstriku", "Istriku", "is triku"},

    -- ==================== TIER-1 INGGRIS (MULTI-POINT PHONETIC - EDIT DISTANCE >= 2) ====================
    ["fuck"]          = {"fuhq", "phuxk", "fu q"},
    ["fucks"]         = {"fuhqs", "phuxks", "fu qs"},
    ["fucking"]       = {"fuhqing", "phuxking", "fu qing"},
    ["fuckin"]        = {"fuhqin", "phuxkin", "fu qin"},
    ["fucked"]        = {"fuhqed", "phuxked", "fu qed"},
    ["fucker"]        = {"fuhqer", "phuxker", "fu qer"},
    ["fuckers"]       = {"fuhqers", "phuxkers", "fu qers"},
    ["motherfucker"]  = {"mothafuhqer", "mothaphuxker", "motha fu qer"},
    ["motherfuckers"] = {"mothafuhqers", "mothaphuxkers", "motha fu qers"},
    ["motherfucking"] = {"mothafuhqing", "mothaphuxking", "motha fu qing"},
    ["wtf"]           = {"wthf", "wtph", "w t f"},
    ["stfu"]          = {"stfhu", "stphu", "s t f u"},

    ["suck"]          = {"suhq", "suxk", "su q"},
    ["sucks"]         = {"suhqs", "suxks", "su qs"},
    ["sucking"]       = {"suhqing", "suxking", "su qing"},
    ["sucked"]        = {"suhqed", "suxked", "su qed"},
    ["sucker"]        = {"suhqer", "suxker", "su qer"},
    ["suckers"]       = {"suhqers", "suxkers", "su qers"},
    ["cocksucker"]    = {"cohqsuhqer", "coxksuxker", "co q su qer"},

    ["shit"]          = {"shyt", "shxt", "sh yt"},
    ["shits"]         = {"shyts", "shxts", "sh yts"},
    ["shitting"]      = {"shytting", "shxtting", "sh ytting"},
    ["shitty"]        = {"shytty", "shxtty", "sh ytty"},
    ["bullshit"]      = {"bullshyt", "bullshxt", "bull sh yt"},

    ["bitch"]         = {"bych", "bxtch", "bi ch"},
    ["bitches"]       = {"byches", "bxtches", "bi ches"},
    ["bitching"]      = {"byching", "bxtching", "bi ching"},
    ["bitchy"]        = {"bychy", "bxtchy", "bi chy"},

    ["cunt"]          = {"kuhnt", "cvxnt", "ku nt"},
    ["cunts"]         = {"kuhnts", "cvxnts", "ku nts"},
    ["dick"]          = {"dihq", "dyxk", "di q"},
    ["dicks"]         = {"dihqs", "dyxks", "di qs"},
    ["dickhead"]      = {"dihqhead", "dyxkhead", "di q head"},
    ["cock"]          = {"cohq", "coxk", "co q"},
    ["cocks"]         = {"cohqs", "coxks", "co qs"},
    ["pussy"]         = {"puhsy", "pvssy", "pu sy"},
    ["pussies"]       = {"puhsies", "pvssies", "pu sies"},
    ["nigga"]         = {"nygha", "nxggha", "ny gha"},
    ["niggas"]        = {"nyghas", "nxgghas", "ny ghas"},
    ["nigger"]        = {"nygher", "nxggher", "ny gher"},
    ["niggers"]       = {"nyghers", "nxgghers", "ny ghers"},
    ["faggot"]        = {"fahgot", "fxggot", "fa got"},
    ["fag"]           = {"fahg", "fxg", "fa g"},
    ["slut"]          = {"sluht", "slxt", "sl ut"},
    ["sluts"]         = {"sluhts", "slxts", "sl uts"},
    ["slutty"]        = {"sluhtty", "slxtty", "sl utty"},
    ["whore"]         = {"whohre", "whxre", "who re"},
    ["whores"]        = {"whohres", "whxres", "who res"},
    ["hoe"]           = {"hohe", "hxe", "ho e"},
    ["hoes"]          = {"hohes", "hxes", "ho es"},
    ["ass"]           = {"ahss", "axss", "a ss"},
    ["asshole"]       = {"ahsshole", "axsshole", "a sshole"},
    ["dumbass"]       = {"dumbahss", "dumbaxss", "dumb a ss"},
    ["badass"]        = {"badahss", "badaxss", "bad a ss"},
    ["sex"]           = {"sehx", "sxx", "se x"},
    ["sexy"]          = {"sehxy", "sxxy", "se xy"},
    ["porn"]          = {"pohrn", "pxrn", "po rn"},
    ["nude"]          = {"nuhde", "nxde", "nu de"},
    ["nudes"]         = {"nuhdes", "nxdes", "nu des"},
    ["naked"]         = {"nahked", "nxked", "na ked"},
    ["horny"]         = {"hohrny", "hxrny", "hor ny"},
    ["cum"]           = {"kuhm", "cxm", "ku m"},
    ["cumming"]       = {"kuhmming", "cxmming", "ku mming"},
    ["boobs"]         = {"boohbs", "bxxbs", "boo bs"},
    ["tits"]          = {"tyts", "txts", "ti ts"},
    ["titties"]       = {"tytties", "txtties", "ti tties"},
    ["booty"]         = {"boohty", "bxxty", "boo ty"},
    ["lick"]          = {"lihq", "lyxk", "li q"},
    ["licking"]       = {"lihqing", "lyxking", "li qing"},
    ["blowjob"]       = {"blohwjob", "blxwjob", "blow job"},
    ["handjob"]       = {"hahndjob", "hxndjob", "hand job"},
    ["rape"]          = {"rahpe", "rxpe", "ra pe"},
    ["raped"]         = {"rahped", "rxped", "ra ped"},
    ["kill"]          = {"kihll", "kxll", "ki ll"},
    ["killed"]        = {"kihlled", "kxlled", "ki lled"},
    ["killing"]       = {"kihlling", "kxlling", "ki lling"},
    ["die"]           = {"dyie", "dxe", "di e"},
    ["dying"]         = {"dyhing", "dxing", "dy ing"},
    ["dead"]          = {"dehad", "dxad", "de ad"},
    ["suicide"]       = {"suyicide", "sxicide", "sui cide"},
    ["suicidal"]      = {"suyicidal", "sxicidal", "sui cidal"},
    ["depressed"]     = {"dehpressed", "dxpressed", "de pressed"},
    ["depression"]    = {"dehpression", "dxpression", "de pression"},
    ["worthless"]     = {"wohrthless", "wxrthless", "worth less"},
    ["hopeless"]      = {"hohpeless", "hxpeless", "hope less"},
    ["boyfriend"]     = {"bohyfriend", "bxyfriend", "boy friend"},
    ["girlfriend"]    = {"gihrlfriend", "gxrlfriend", "girl friend"},

    -- ==================== KATA SLANG, FISIK & ROMANSA (ID) ====================
    ["lengket"]       = {"lhengket", "l3ngket", "leng ket"},
    ["melengket"]     = {"melhengket", "mel3ngket", "me lengket"},
    ["nempel"]        = {"nhempel", "n3mpel", "nem pel"},
    ["menempel"]      = {"menhempel", "men3mpel", "me nempel"},
    ["gocek"]         = {"ghocek", "g0cek", "go cek"},
    ["kegocek"]       = {"khegocek", "keg0cek", "ke gocek"},
    ["tergocek"]      = {"terghocek", "terg0cek", "ter gocek"},
    ["menggocek"]     = {"mengghocek", "mengg0cek", "meng gocek"},
    ["goda"]          = {"ghoda", "g0da", "go da"},
    ["kegoda"]        = {"khegoda", "keg0da", "ke goda"},
    ["tergoda"]       = {"terghoda", "terg0da", "ter goda"},
    ["menggoda"]      = {"mengghoda", "mengg0da", "meng goda"},
    ["tipu"]          = {"tihpu", "tIpu", "ti pu"},
    ["ketipu"]        = {"khetipu", "ketIpu", "ke tipu"},
    ["tertipu"]       = {"tertihpu", "tertIpu", "ter tipu"},
    ["menipu"]        = {"menihpu", "menIpu", "me nipu"},
    ["baper"]         = {"bhaper", "b4per", "ba per"},
    ["kebawa"]        = {"khebawa", "keb4wa", "ke bawa"},
    ["terbawa"]       = {"terbhawa", "terb4wa", "ter bawa"},
    ["basah"]         = {"bhasah", "b4sah", "ba sah"},
    ["membasahi"]     = {"membhasahi", "memb4sahi", "mem basahi"},
    ["panas"]         = {"phanas", "p4nas", "pa nas"},
    ["memanas"]       = {"memhanas", "mem4nas", "me manas"},
    ["lemas"]         = {"lhemas", "l3mas", "le mas"},
    ["melemas"]       = {"melhemas", "mel3mas", "me lemas"},
    ["tegang"]        = {"thegang", "t3gang", "te gang"},
    ["menegang"]      = {"menhegang", "men3gang", "me negang"},
    ["nikmat"]        = {"nihkmat", "nIkmat", "nik mat"},
    ["menikmati"]     = {"menihkmati", "menIkmati", "me nikmati"},
    ["kunikmati"]     = {"kunihkmati", "kunIkmati", "ku nikmati"},
    ["puas"]          = {"phuas", "pvas", "pu as"},
    ["memuaskan"]     = {"memhuaskan", "memvaskan", "me muaskan"},
    ["nakal"]         = {"nhakal", "n4kal", "na kal"},
    ["bandel"]        = {"bhandel", "b4ndel", "ban del"},
    ["liar"]          = {"lihar", "lIar", "li ar"},
    ["buas"]          = {"bhuas", "bvas", "bu as"},
    ["gila"]          = {"ghila", "gIla", "gi la"},
    ["tergila"]       = {"terghila", "tergIla", "ter gila"},

    ["bayang"]        = {"bhayang", "b4yang", "ba yang"},
    ["bayangkan"]     = {"bhayangkan", "b4yangkan", "ba yangkan"},
    ["kubayangkan"]   = {"kuhbayangkan", "qubayangkan", "ku bayangkan"},
    ["membayangkan"]  = {"membhayangkan", "memb4yangkan", "mem bayangkan"},
    ["terbayang"]     = {"terbhayang", "terb4yang", "ter bayang"},
    ["bayanganmu"]    = {"bhayanganmu", "b4yanganmu", "ba yanganmu"},
    ["tubuh"]         = {"tuhbuh", "tvbvh", "tu buh"},
    ["tubuhmu"]       = {"tuhbuhmu", "tvbvhmu", "tu buhmu"},
    ["tubuhku"]       = {"tuhbuhku", "tvbvhku", "tu buhku"},
    ["badan"]         = {"bhadan", "b4dan", "ba dan"},
    ["badanmu"]       = {"bhadanmu", "b4danmu", "ba danmu"},
    ["badanku"]       = {"bhadanku", "b4danku", "ba danku"},
    ["raga"]          = {"rhaga", "r4ga", "ra ga"},
    ["ragamu"]        = {"rhagamu", "r4gamu", "ra gamu"},
    ["peluk"]         = {"pehluk", "p3luk", "pe luk"},
    ["memeluk"]       = {"memehluk", "mem3luk", "me meluk"},
    ["memelukmu"]     = {"memehlukmu", "mem3lukmu", "me melukmu"},
    ["kupeluk"]       = {"kupehluk", "kup3luk", "ku peluk"},
    ["dipeluk"]       = {"dipehluk", "dip3luk", "di peluk"},
    ["pelukan"]       = {"pehlukan", "p3lukan", "pe lukan"},
    ["pelukanmu"]     = {"pehlukanmu", "p3lukanmu", "pe lukanmu"},
    ["pelukanku"]     = {"pehlukanku", "p3lukanku", "pe lukanku"},
    ["dipelukanku"]   = {"dipehlukanku", "dip3lukanku", "di pelukanku"},
    ["dekap"]         = {"dhekap", "d3kap", "de kap"},
    ["mendekap"]      = {"mendhekap", "mend3kap", "men dekap"},
    ["dekapan"]       = {"dhekapan", "d3kapan", "de kapan"},
    ["dekapanku"]     = {"dhekapanku", "d3kapanku", "de kapanku"},
    ["rangkul"]       = {"rhangkul", "r4ngkul", "rang kul"},
    ["merangkul"]     = {"merhangkul", "mer4ngkul", "me rangkul"},
    ["tidur"]         = {"tihdur", "tIdvr", "ti dur"},
    ["tidurlah"]      = {"tihdurlah", "tIdvrlah", "ti durlah"},
    ["meniduri"]      = {"menihduri", "menIdvri", "me niduri"},
    ["kutiduri"]      = {"kutihduri", "kutIdvri", "ku tiduri"},
    ["ketiduran"]     = {"ketihduran", "ketIdvran", "ke tiduran"},
    ["sekasur"]       = {"sekhasur", "sek4sur", "se kasur"},
    ["seranjang"]     = {"serhanjang", "ser4njang", "se ranjang"},
    ["ranjang"]       = {"rhanjang", "r4njang", "ran jang"},
    ["kasur"]         = {"khasur", "k4sur", "ka sur"},
    ["kamar"]         = {"khamar", "k4mar", "ka mar"},
    ["kamarmu"]       = {"khamarmu", "k4marmu", "ka marmu"},
    ["kamarku"]       = {"khamarku", "k4marku", "ka marku"},
    ["cium"]          = {"chium", "cIvm", "ci um"},
    ["mencium"]       = {"menchium", "mencIvm", "men cium"},
    ["menciummu"]     = {"menchiummu", "mencIvmmu", "men ciummu"},
    ["kucium"]        = {"kuchium", "kucIvm", "ku cium"},
    ["ciuman"]        = {"chiuman", "cIvman", "ci uman"},
    ["kecup"]         = {"khecup", "k3cup", "ke cup"},
    ["mengecup"]      = {"menghecup", "meng3cup", "me ngecup"},
    ["sentuh"]        = {"shentuh", "s3ntvh", "sen tuh"},
    ["menyentuh"]     = {"menyhentuh", "meny3ntvh", "me nyentuh"},
    ["menyentuhmu"]   = {"menyhentuhmu", "meny3ntvhmu", "me nyentuhmu"},
    ["kusentuh"]      = {"kushentuh", "kus3ntvh", "ku sentuh"},
    ["sentuhan"]      = {"shentuhan", "s3ntvhan", "sen tuhan"},
    ["belai"]         = {"bhelai", "b3lai", "be lai"},
    ["membelai"]      = {"membhelai", "memb3lai", "mem belai"},
    ["belaian"]       = {"bhelaian", "b3laian", "be laian"},
    ["raba"]          = {"rhaba", "r4ba", "ra ba"},
    ["meraba"]        = {"merhaba", "mer4ba", "me raba"},
    ["pangku"]        = {"phangku", "p4ngku", "pang ku"},
    ["memangku"]      = {"memhangku", "mem4ngku", "me mangku"},
    ["pangkuan"]      = {"phangkuan", "p4ngkuan", "pang kuan"},
    ["pangkuanku"]    = {"phangkuanku", "p4ngkuanku", "pang kuanku"},
    ["bibir"]         = {"bihbir", "bIbir", "bi bir"},
    ["bibirmu"]       = {"bihbirmu", "bIbirmu", "bi birmu"},
    ["bibirku"]       = {"bihbirku", "bIbirku", "bi birku"},
    ["lidah"]         = {"lihdah", "lIdah", "li dah"},
    ["leher"]         = {"lheher", "l3her", "le her"},
    ["lehermu"]       = {"lhehermu", "l3hermu", "le hermu"},
    ["dada"]          = {"dhada", "d4da", "da da"},
    ["dadamu"]        = {"dhadamu", "d4damu", "da damu"},
    ["dadaku"]        = {"dhadaku", "d4daku", "da daku"},
    ["paha"]          = {"phaha", "p4ha", "pa ha"},
    ["pahamu"]        = {"phahamu", "p4hamu", "pa hamu"},
    ["kulit"]         = {"kuhlit", "kvlIt", "ku lit"},
    ["kulitmu"]       = {"kuhlitmu", "kvlItmu", "ku litmu"},
    ["desah"]         = {"dhesah", "d3sah", "de sah"},
    ["mendesah"]      = {"mendhesah", "mend3sah", "men desah"},
    ["desahan"]       = {"dhesahan", "d3sahan", "de sahan"},
    ["keringat"]      = {"kheringat", "kerIngat", "ke ringat"},
    ["bercinta"]      = {"berchinta", "bercInta", "ber cinta"},
    ["cinta"]         = {"chinta", "cInta", "cin ta"},
    ["cintaku"]       = {"chintaku", "cIntaku", "cin taku"},
    ["cintamu"]       = {"chintamu", "cIntamu", "cin tamu"},
    ["mencintai"]     = {"menchintai", "mencIntai", "men cintai"},
    ["mencintaimu"]   = {"menchintaimu", "mencIntaimu", "men cintaimu"},
    ["sayang"]        = {"shayang", "s4yang", "sa yang"},
    ["sayangku"]      = {"shayangku", "s4yangku", "sa yangku"},
    ["sayangmu"]      = {"shayangmu", "s4yangmu", "sa yangmu"},
    ["menyayangi"]    = {"menyhayangi", "meny4yangi", "me nyayangi"},
    ["menyayangimu"]  = {"menyhayangimu", "meny4yangimu", "me nyayangimu"},
    ["memudar"]       = {"memuhdar", "memvdar", "me mudar"},
    ["memnudar"]      = {"memnuhdar", "memnvdar", "mem nudar"},
    ["remang"]        = {"rhemanq", "r3mang", "re mang"},
    ["sunyi"]         = {"suhnyi", "svnyi", "su nyi"},
    ["hampa"]         = {"hampah", "h4mpa", "ham pa"},

    -- Kata Pemicu Konteks Emosi & Tindakan Antar-Pemain
    ["lakukan"]       = {"lahkukan", "l4kukan", "la kukan"},
    ["kulakukan"]     = {"kulahkukan", "kul4kukan", "ku lakukan"},
    ["melakukan"]     = {"melahkukan", "mel4kukan", "me lakukan"},
    ["dilakukan"]     = {"dilahkukan", "dil4kukan", "di lakukan"},
    ["perbuat"]       = {"perbhuat", "p3rbuat", "per buat"},
    ["marah"]         = {"mharah", "m4rah", "ma rah"},
    ["marahi"]        = {"mharahi", "m4rahi", "ma rahi"},
    ["memarahi"]      = {"memharahi", "mem4rahi", "me marahi"},
    ["kemarahan"]     = {"kemharahan", "kem4rahan", "ke marahan"},
    ["emosi"]         = {"ehmosi", "3mosi", "e mosi"},
    ["kesal"]         = {"khesal", "k3sal", "ke sal"},
    ["murka"]         = {"muhrka", "mvrka", "mur ka"},
    ["amuk"]          = {"ahmuk", "4muk", "a muk"},
    ["mengamuk"]      = {"mengahmuk", "meng4muk", "me ngamuk"},
    ["benci"]         = {"bhenci", "b3nci", "ben ci"},
    ["membenci"]      = {"membhenci", "memb3nci", "mem benci"},
    ["kubenci"]       = {"kubhenci", "kub3nci", "ku benci"},
    ["dendam"]        = {"dhendam", "d3ndam", "den dam"},
    ["kecewa"]        = {"khecewa", "k3cewa", "ke cewa"},
    ["sakiti"]        = {"sahkiti", "s4kiti", "sa kiti"},
    ["menyakiti"]     = {"menyahkiti", "meny4kiti", "me nyakiti"},
    ["menyakitimu"]   = {"menyahkitimu", "meny4kitimu", "me nyakitimu"},
    ["kusakiti"]      = {"kusahkiti", "kus4kiti", "ku sakiti"},
    ["tersakiti"]     = {"tersahkiti", "ters4kiti", "ter sakiti"},
    ["lukai"]         = {"luhkai", "lvkai", "lu kai"},
    ["melukai"]       = {"meluhkai", "melvkai", "me lukai"},
    ["melukaimu"]     = {"meluhkaimu", "melvkaimu", "me lukaimu"},
    ["teriak"]        = {"theriak", "t3riak", "te riak"},
    ["berteriak"]     = {"bertheriak", "bert3riak", "ber teriak"},
    ["bentak"]        = {"bhentak", "b3ntak", "ben tak"},
    ["membentak"]     = {"membhentak", "memb3ntak", "mem bentak"},
    ["tampar"]        = {"thampar", "t4mpar", "tam par"},
    ["menampar"]      = {"menhampar", "men4mpar", "me nampar"},
    ["pukul"]         = {"puhkul", "pvkul", "pu kul"},
    ["memukul"]       = {"memuhkul", "memvkul", "me mukul"},
    ["hajar"]         = {"hhajar", "h4jar", "ha jar"},
    ["menghajar"]     = {"menghhajar", "mengh4jar", "meng hajar"},
    ["tendang"]       = {"thendang", "t3ndang", "ten dang"},
    ["dorong"]        = {"dhorong", "d0rong", "do rong"},
    ["mendorong"]     = {"mendhorong", "mend0rong", "men dorong"},
    ["paksa"]         = {"phaksa", "p4ksa", "pak sa"},
    ["memaksa"]       = {"memhaksa", "mem4ksa", "me maksa"},
    ["bohong"]        = {"bhohong", "b0hong", "bo hong"},
    ["bohongi"]       = {"bhohongi", "b0hongi", "bo hongi"},
    ["membohongi"]    = {"membhohongi", "memb0hongi", "mem bohongi"},
    ["khianat"]       = {"khihanat", "khIanat", "khi anat"},
    ["khianati"]      = {"khihanati", "khIanati", "khi anati"},
    ["mengkhianati"]  = {"mengkhihanati", "mengkhIanati", "meng khianati"},
    ["tinggalkan"]    = {"tihnggalkan", "tInggalkan", "ting galkan"},
    ["meninggalkan"]  = {"menihnggalkan", "menInggalkan", "me ninggalkan"},
    ["kutinggalkan"]  = {"kutihnggalkan", "kutInggalkan", "ku tinggalkan"},

    -- Kata Tier-1 Kasar & Vulgar Indonesia
    ["kontol"]        = {"kohnthol", "kxntol", "kon tol"},
    ["memek"]         = {"mhemhek", "mxmek", "me mek"},
    ["jembut"]        = {"jhembhut", "jxmbut", "jem but"},
    ["ngentot"]       = {"nghenthot", "ngxntot", "ngen tot"},
    ["ngewe"]         = {"nghewhe", "ngxwe", "nge we"},
    ["pepek"]         = {"phephek", "pxpek", "pe pek"},
    ["tetek"]         = {"thethek", "txtek", "te tek"},
    ["toket"]         = {"thokhet", "txket", "to ket"},
    ["lonte"]         = {"lhonhte", "lxnte", "lon te"},
    ["anjing"]        = {"ahnjhing", "axnjing", "an jing"},
    ["anjir"]         = {"ahnjhir", "axnjir", "an jir"},
    ["bangsat"]       = {"bahngshat", "bxngsat", "bang sat"},
    ["brengsek"]      = {"brehngshek", "brxngsek", "breng sek"},
    ["bajingan"]      = {"bahjinghan", "bxjingan", "ba jingan"},
    ["goblok"]        = {"gohblohq", "gxblok", "gob lok"},
    ["tolol"]         = {"tohlohl", "txlol", "to lol"},
    ["jancok"]        = {"jahncohq", "jxncok", "jan cok"},
    ["jancuk"]        = {"jahncuhq", "jxncuk", "jan cuk"},
    ["pantek"]        = {"pahnthek", "pxntek", "pan tek"},
    ["puki"]          = {"puhkhi", "pxki", "pu ki"},
    ["pukimak"]       = {"puhkhimak", "pxkimak", "puki mak"},
    ["sange"]         = {"sahnghe", "sxnge", "sa nge"},
    ["bokep"]         = {"bohkeps", "bxkep", "bo kep"},
    ["bunuh"]         = {"buhnuh", "bvnuh", "bu nuh"},
    ["membunuh"]      = {"membuhnuh", "membvnuh", "mem bunuh"},
    ["mati"]          = {"mahti", "m4ti", "ma ti"},
    ["isap"]          = {"ihsap", "Isap", "i sap"},
    ["mengisap"]      = {"mengihsap", "mengIsap", "meng isap"},
    ["hisap"]         = {"hihsap", "hIsap", "hi sap"},
    ["menghisap"]     = {"menghihsap", "menghIsap", "meng hisap"},
    ["jilat"]         = {"jihlat", "jIlat", "ji lat"},
    ["menjilat"]      = {"menjihlat", "menjIlat", "men jilat"},
    ["emut"]          = {"ehmut", "3mut", "e mut"},
    ["mengemut"]      = {"mengehmut", "meng3mut", "meng emut"}
}

local strictBadWords = {
    "dengar", "dengarkan", "ingin", "kuingin", "inginkan", "kuinginkan", "menginginkan",
    "jadi", "menjadi", "pasangan", "pasanganku", "pasanganmu", "jodoh", "jodohku", "jodohmu",
    "lengket", "melengket", "nempel", "menempel", "gocek", "kegocek", "tergocek", "menggocek",
    "goda", "kegoda", "tergoda", "menggoda", "ketipu", "tertipu", "baper", "kebawa", "terbawa",
    "basah", "membasahi", "panas", "memanas", "lemas", "melemas", "tegang", "menegang",
    "nikmat", "menikmati", "kunikmati", "puas", "memuaskan", "nakal", "bandel", "liar", "buas",

    "lakukan", "kulakukan", "melakukan", "perbuat", "marah", "marahi", "memarahi",
    "kemarahan", "emosi", "kesal", "murka", "amuk", "mengamuk", "benci", "membenci",
    "kubenci", "dendam", "kecewa", "sakiti", "menyakiti", "menyakitimu", "kusakiti",
    "tersakiti", "lukai", "melukai", "melukaimu", "teriak", "berteriak", "bentak",
    "membentak", "tampar", "menampar", "pukul", "memukul", "hajar", "menghajar",
    "tendang", "dorong", "mendorong", "paksa", "memaksa", "bohong", "bohongi",
    "membohongi", "tipu", "menipu", "khianat", "khianati", "mengkhianati",
    "tinggalkan", "meninggalkan", "kutinggalkan", "campakkan", "buang", "membuang",
    "usir", "mengusir", "ancam", "mengancam", "hukum", "menghukum", "salahkan",
    "menyalahkan", "tuduh", "menuduh", "hina", "menghina", "ejek", "mengejek",
    "caci", "maki", "memaki", "kutuk", "mengutuk", "tangis", "menangis", "kejam",
    "jahat", "egois", "angkuh", "sombong", "munafik", "curang", "racun", "beracun",
    "derita", "menderita", "siksa", "tersiksa", "menyiksa", "hancur", "remuk",
    "putus asa", "menyerah", "lelah", "muak", "sendirian", "kesepian", "takut",

    "bayang", "bayangkan", "kubayangkan", "membayangkan", "terbayang",
    "tubuh", "tubuhmu", "tubuhku", "badan", "badanmu", "badanku", "raga", "ragamu",
    "tidur", "tidurlah", "meniduri", "kutiduri", "ketiduran", "ranjang", "kasur",
    "kamar", "kamarmu", "kamarku", "selimut", "bantal",
    "bibir", "bibirmu", "bibirku", "lidah", "lidahmu", "leher", "lehermu",
    "dada", "dadamu", "dadaku", "paha", "pahamu", "pinggul", "pinggulmu",
    "kulit", "kulitmu", "keringat", "desah", "mendesah", "desahan",
    "peluk", "memeluk", "memelukmu", "kupeluk", "dipeluk", "pelukan", "pelukanmu", "pelukanku", "dipelukanku",
    "dekap", "mendekap", "dekapan", "dekapanku", "rangkul", "merangkul",
    "cium", "mencium", "menciummu", "kucium", "ciuman", "kecup", "mengecup",
    "sentuh", "menyentuh", "menyentuhmu", "kusentuh", "sentuhan",
    "belai", "membelai", "belaian", "raba", "meraba", "pangku", "memangku", "pangkuan",
    "bercinta", "cinta", "cintaku", "cintamu", "mencintai", "mencintaimu",
    "sayang", "sayangku", "sayangmu", "menyayangi", "menyayangimu",
    "pacar", "pacarku", "pacarmu", "pacaran", "berpacaran", "kekasih", "kekasihku", "kekasihmu",
    "nikah", "menikah", "menikahimu", "suami", "istri", "selingkuh", "pelakor",
    "telanjang", "bugil", "seksi", "montok", "bohay", "semok", "bahenol",
    "kutang", "bh", "cangcut", "sempak", "kolor", "daleman",

    "anjing", "anjir", "anjrit", "anjrot", "anying", "anjg", "ajg", "njir", "njrit",
    "asu", "asw", "kirik", "babi", "celeng", "bagong", "monyet", "kunyuk", "kampret",
    "goblok", "goblog", "gblk", "tolol", "tll", "bodoh", "bego", "begok", "bloon",
    "dungu", "idiot", "autis", "cacat", "sinting", "sarap", "edan", "gila", "stres",
    "bangsat", "bgst", "bangsad", "brengsek", "bajingan", "keparat", "bedebah",
    "sialan", "bangke", "bangkai", "tai", "tahi", "taik", "berak", "kentut", "kencing",
    "bacot", "bct", "cocot", "congor", "mampus", "modar", "kojor", "matek",
    "setan", "iblis", "dajjal", "jahanam", "laknat", "haram", "kafir", "najis",
    "jancok", "jancuk", "dancok", "diancok", "cuk", "cok", "matamu", "ndasmu",
    "lambemu", "cangkemmu", "raimu", "gateli", "tempik", "tempek", "turuk", "peli",
    "pekok", "kampang", "pantek", "kimak", "pukimak", "puki", "cibai", "lancau",
    "sundal", "lonte", "pelacur", "psk", "jablay", "bispak", "perek", "openbo",
    "michat", "mucikari", "germo", "kontol", "kntl", "memek", "mmk", "pepek",
    "jembut", "jmbt", "itil", "pentil", "puting", "tetek", "tete", "toket",
    "payudara", "pantat", "bokong", "bool", "silit", "selangkangan", "kelamin",
    "kemaluan", "zakar", "vagina", "penis", "testis", "peler", "pler", "titit",
    "ngentot", "entot", "ngewe", "ewe", "kenthu", "peju", "mani", "sperma", "crot",
    "ejakulasi", "ereksi", "ngaceng", "coli", "colmek", "onani", "masturbasi",
    "sodomi", "sepong", "nyepong", "isap", "mengisap", "hisap", "menghisap", "jilat",
    "menjilat", "emut", "mengemut", "sange", "horni", "birahi", "syahwat", "perawan",
    "seks", "seksual", "bokep", "mesum", "cabul", "perkosa", "memperkosa", "pedofil",

    "bunuh", "membunuh", "pembunuh", "bantai", "membantai", "cekik", "tikam",
    "tusuk", "bacok", "penggal", "mutilasi", "mayat", "jenazah", "mati", "kematian",
    "mabuk", "mabok", "miras", "alkohol", "tuak", "ciu", "amer", "narkoba",
    "ganja", "sabu", "ekstasi", "heroin", "kokain", "overdosis", "sakau", "judi", "judol",
    "depressed", "depressing", "depression", "depresi", "anxious", "anxiety",
    "suicidal", "suicide", "kms", "kys", "selfharm", "cutting", "worthless", "hopeless",

    "motherfucker", "motherfucking", "mofo", "mf", "fucker", "fucking", "fuckin",
    "fucked", "fucks", "fuck", "fck", "fuk", "wtf", "stfu", "gtfo", "omfg",
    "shitting", "shitty", "bullshit", "horseshit", "dipshit", "shithead", "shits",
    "shit", "sht", "piss", "pissed", "bitching", "bitches", "bitchy", "bitch", "btch",
    "assholes", "asshole", "dumbass", "jackass", "badass", "fatass", "asses", "ass",
    "arse", "bastard", "bastards", "dammit", "damn", "goddamn", "cunt", "cunts",
    "dick", "dicks", "dickhead", "cock", "cocks", "pussy", "pussies", "twat", "prick",
    "wanker", "bollocks", "douchebag", "douche", "scumbag", "slut", "sluts", "slutty",
    "whore", "whores", "hoe", "hoes", "thot", "hooker", "prostitute", "stripper",
    "pimp", "nigga", "niggas", "nigger", "niggers", "nibba", "negro", "chink", "spic",
    "faggot", "faggots", "fag", "fags", "dyke", "tranny", "retard", "retarded",
    "killing", "killed", "killer", "kills", "kill", "murder", "murdered", "murderer",
    "dying", "died", "die", "dead", "death", "corpse", "bleeding", "bleed", "blood",
    "stab", "stabbed", "choke", "choking", "shoot", "shooting", "shotgun", "gun",
    "guns", "pistol", "rifle", "bullet", "bomb", "terrorist", "torture", "abuse",
    "rape", "raped", "rapist", "molest", "pedo", "pedophile", "incest", "sexual",
    "sexually", "sex", "sexy", "porn", "porno", "hentai", "nsfw", "nude", "nudes",
    "naked", "horny", "orgasm", "cum", "cumming", "sperm", "boobs", "boob", "titties",
    "tits", "breast", "breasts", "nipple", "nipples", "booty", "butt", "anus", "penis",
    "vagina", "clit", "dildo", "suck", "sucks", "sucking", "sucked", "sucker", "lick",
    "licks", "licking", "licked", "blow", "blowing", "blowjob", "handjob", "footjob",
    "swallow", "bite", "biting", "anal", "oral", "virgin", "lust", "fetish", "bdsm",
    "kinky", "drugs", "drug", "weed", "marijuana", "cannabis", "cocaine", "coke",
    "heroin", "meth", "ecstasy", "molly", "lsd", "pills", "vape", "drunk", "wasted",
    "whiskey", "vodka", "beer", "wine", "kiss", "kissing", "kissed", "lips", "tongue",
    "thighs", "undress", "underwear", "bra", "panties", "bikini", "bed", "bedroom",
    "boyfriend", "girlfriend", "lover", "dating", "marry", "husband", "wife", "daddy",
    "mommy", "discord", "tiktok", "instagram", "whatsapp", "telegram", "youtube",
    "twitter", "facebook", "snapchat", "tinder", "onlyfans", "spotify", "sleep",
    "sleeping", "angry", "mad", "hate", "hating", "hurt", "hurting", "pain", "cry", "crying"
}

local hardSubstrings = {
    "fuck", "fck", "fuk", "shit", "bitch", "cunt", "dick", "cock", "puss", "nigg",
    "fag", "slut", "whor", "rape", "pedo", "porn", "nude", "sex", "suck", "lick",
    "blowjob", "handjob", "suicid", "depres", "kontol", "kntl", "memek", "pepek",
    "jembut", "jmbt", "ngentot", "ngewe", "tetek", "toket", "lonte", "pelacur",
    "bokep", "mesum", "cabul", "perkosa", "anjing", "anjir", "bangsat", "brengsek",
    "bajingan", "goblok", "tolol", "jancok", "jancuk", "pantek", "kimak", "puki",
    "sange", "tubuh", "tidur", "bayang", "peluk", "cium", "sentuh", "marah", "benci",
    "sakit", "luka", "lengket", "gocek", "nempel", "goda", "pacar", "kekasih", "cinta", "sayang"
}

local wordLookup = {}
for _, w in ipairs(strictBadWords) do
    wordLookup[w:lower()] = true
end

local function matchCase(original, replacement)
    if replacement == "" then return "" end
    if original == original:upper() and #original > 1 then
        return replacement:upper()
    elseif original:sub(1, 1) == original:sub(1, 1):upper() then
        return replacement:sub(1, 1):upper() .. replacement:sub(2)
    end
    return replacement
end

local function insertSoftHBridge(word)
    if word:lower():sub(-2) == "ck" then
        return word:sub(1, #word - 2) .. "hq"
    end
    for i = 1, #word - 1 do
        local ch = word:sub(i, i)
        local nextCh = word:sub(i + 1, i + 1):lower()
        if ch:match("[aiueoAIUEO]") and nextCh ~= "h" then
            return word:sub(1, i) .. "h" .. word:sub(i + 1)
        end
    end
    local mid = math.max(1, math.floor(#word / 2))
    return word:sub(1, mid) .. "h" .. word:sub(mid + 1)
end

local function bypassWord(word)
    if #word < 2 then return word end
    local lower = word:lower()
    local mode = math.clamp(tonumber(FilterModule.BypassMode) or 1, 1, 3)

    if directBypassMap[lower] then
        return matchCase(word, directBypassMap[lower][mode])
    end

    if lower:find("fuck", 1, true) then
        local rep = (mode == 1 and "fuhq") or (mode == 2 and "phuxk") or "fu q"
        return word:gsub("[fF][uU][cC][kK]", function(m) return matchCase(m, rep) end)
    end

    if lower:find("suck", 1, true) then
        local rep = (mode == 1 and "suhq") or (mode == 2 and "suxk") or "su q"
        return word:gsub("[sS][uU][cC][kK]", function(m) return matchCase(m, rep) end)
    end

    if lower:find("shit", 1, true) then
        local rep = (mode == 1 and "shyt") or (mode == 2 and "shxt") or "sh yt"
        return word:gsub("[sS][hH][iI][tT]", function(m) return matchCase(m, rep) end)
    end

    if lower:find("bitch", 1, true) then
        local rep = (mode == 1 and "bych") or (mode == 2 and "bxtch") or "bi ch"
        return word:gsub("[bB][iI][tT][cC][hH]", function(m) return matchCase(m, rep) end)
    end

    if mode == 1 then
        return insertSoftHBridge(word)
    elseif mode == 2 then
        local leet = {["u"]="v", ["i"]="I", ["l"]="I", ["e"]="3", ["o"]="0", ["a"]="4"}
        local replaced = false
        local res = word:gsub("([uileoal])", function(c)
            if not replaced and leet[c] then
                replaced = true
                return leet[c]
            end
            return c
        end)
        if replaced then return res end
        return insertSoftHBridge(word)
    else
        local mid = math.max(2, math.floor(#word / 2))
        return word:sub(1, mid) .. " " .. word:sub(mid + 1)
    end
end

local function isBadWord(word)
    local lowerWord = word:lower():gsub("'", "")
    if directBypassMap[lowerWord] or wordLookup[lowerWord] then return true end

    local suffixes = {
        "kanku", "kanmu", "kannya", "anku", "anmu", "annya",
        "nya", "mu", "ku", "lah", "kan", "an", "in", "i", "ing", "ed", "er", "ers", "es", "s"
    }
    for _, suf in ipairs(suffixes) do
        if #lowerWord > #suf + 2 and lowerWord:sub(-#suf) == suf then
            local stem = lowerWord:sub(1, #lowerWord - #suf)
            if directBypassMap[stem] or wordLookup[stem] then return true end
        end
    end

    local prefixes = {"dipe", "kupe", "me", "mem", "men", "meng", "meny", "di", "ku", "kau", "ke", "ter", "ber", "se", "pe", "un", "re"}
    for _, pre in ipairs(prefixes) do
        if #lowerWord > #pre + 2 and lowerWord:sub(1, #pre) == pre then
            local stem = lowerWord:sub(#pre + 1)
            if directBypassMap[stem] or wordLookup[stem] then return true end
            for _, suf in ipairs(suffixes) do
                if #stem > #suf + 2 and stem:sub(-#suf) == suf then
                    local inner = stem:sub(1, #stem - #suf)
                    if directBypassMap[inner] or wordLookup[inner] then return true end
                end
            end
        end
    end

    for _, sub in ipairs(hardSubstrings) do
        if lowerWord:find(sub, 1, true) then
            return true
        end
    end

    return false
end

function FilterModule.Sanitize(text, enabled)
    if not text or text == "" or enabled == false then return text end

    local lowerFull = text:lower()
    -- Deteksi konteks relasi/orang pertama & kedua (termasuk "aku", "ku", dan akhiran "-mu")
    local hasPronounContext = lowerFull:find("kamu", 1, true)
        or lowerFull:find("aku", 1, true)
        or lowerFull:find("%f[%a]ku%f[%A]")
        or lowerFull:find("%f[%a]kau%f[%A]")
        or lowerFull:find("dirimu", 1, true)
        or lowerFull:find("diriku", 1, true)
        or lowerFull:find("mu%f[%A]")
        or lowerFull:find("%f[%a]you%f[%A]")
        or lowerFull:find("your", 1, true)

    local cleaned = text:gsub("([%a'*%-]+)", function(word)
        if word:find("%*") then
            return bypassWord(word:gsub("%*", "u"))
        end

        if word:find("%-") then
            local parts = string.split(word, "-")
            for i, p in ipairs(parts) do
                if isBadWord(p) then
                    parts[i] = bypassWord(p)
                end
            end
            return table.concat(parts, "-")
        end

        if isBadWord(word) then
            return bypassWord(word)
        end

        if hasPronounContext and #word >= 5 then
            local lw = word:lower()
            local safeConnectors = {
                ["karena"]=true, ["tetapi"]=true, ["namun"]=true, ["ketika"]=true,
                ["adalah"]=true, ["seperti"]=true, ["dengan"]=true, ["dalam"]=true,
                ["untuk"]=true, ["bukan"]=true, ["tidak"]=true, ["masih"]=true,
                ["sudah"]=true, ["belum"]=true, ["selalu"]=true, ["pernah"]=true,
                ["where"]=true, ["there"]=true, ["their"]=true, ["would"]=true,
                ["could"]=true, ["should"]=true, ["about"]=true, ["after"]=true
            }
            if not safeConnectors[lw] then
                return bypassWord(word)
            end
        end

        return word
    end)

    cleaned = cleaned:gsub("(%d)(%d)", "%1 %2"):gsub("(%d)(%d)", "%1 %2")
    return cleaned
end

return FilterModule
