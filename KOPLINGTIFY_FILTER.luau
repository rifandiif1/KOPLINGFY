-- =================================================================================
-- KOPLINGTIFY LITE v2.5 - MULTI-LAYER BYPASS FILTER (KOPLINGTIFY_FILTER.luau)
-- =================================================================================
local FilterModule = {}

-- Pilihan Mode Bypass:
-- 1 = Homoglyph + Zero-Width (Tampilan murni tanpa titik, huruf diganti Unicode identik)
-- 2 = Multi Zero-Width (Menyisipkan karakter tak terlihat di setiap 2 huruf)
-- 3 = Simbol Visual Suku Kata + Zero-Width (Contoh: "ku·ba·yang·kan tu·buh·mu")
FilterModule.BypassMode = 3

local ZWS = "\226\128\141" -- Zero-Width Joiner (U+200D)
local ZWNJ = "\226\128\140" -- Zero-Width Non-Joiner (U+200C)

-- Peta Homoglyph Lengkap (Termasuk huruf 'u' yang sebelumnya belum ada)
local homoglyphMap = {
    ["a"] = "а", -- Cyrillic a (U+0430)
    ["e"] = "е", -- Cyrillic ie (U+0435)
    ["i"] = "і", -- Ukrainian i (U+0456)
    ["o"] = "о", -- Cyrillic o (U+043E)
    ["u"] = "υ", -- Greek upsilon (U+03C5) - mengatasi kata "tubuhmu", "kubayangkan"
    ["c"] = "с", -- Cyrillic es (U+0441)
    ["p"] = "р", -- Cyrillic er (U+0440)
    ["x"] = "х", -- Cyrillic ha (U+0445)
    ["y"] = "у", -- Cyrillic u (U+0443)
    ["A"] = "А",
    ["E"] = "Е",
    ["I"] = "І",
    ["O"] = "О",
    ["U"] = "Ս", -- Armenian Feh/Sev (mirip U kapital)
    ["C"] = "С",
    ["P"] = "Р",
    ["X"] = "Х"
}

local targetWords = {
    -- ==================== 0. KATA KERJA PEMICU KONTEKS FISIK / ROMANTIS (ID) ====================
    "bayang", "bayangkan", "kubayangkan", "membayangkan", "terbayang", "bayanganmu",
    "pandang", "pandangi", "kupandang", " kupandangi", "memandang", "memandangi", "memandangmu",
    "tatap", "kutatap", "menatap", "menatapmu", "tatapan", "tatapanmu",
    "ingin", "inginkan", "kuinginkan", "menginginkan", "menginginkanmu",
    "rasa", "rasakan", "kurasakan", "merasakan", "merasakanmu",
    "nikmati", "kunikmati", "menikmati", "menikmatimu",
    "damba", "dambakan", "kudambakan", "mendambakan",
    "tunggu", "kutunggu", "menunggu", "menunggumu",
    "jemput", "kujemput", "menjemput", "menjemputmu",
    "bawa", "kubawa", "membawa", "membawamu",
    "ajak", "kuajak", "mengajak", "mengajakmu",
    "temani", "kutemani", "menemani", "menemanimu",
    "dekati", "kudekati", "mendekati", "mendekatimu", "dekat", "mendekat",
    "rebah", "merebahkan", "bersandar", "sandarkan", "basah", "membasahi",
    "hangat", "kehangatan", "menghangatkan", "dingin", "kedinginan",
    "indah", "keindahan", "cantik", "kecantikan", "manis", " elok",

    -- ==================== 1. MENTAL HEALTH, DEPRESI & LIRIK GALAU (EN & ID) ====================
    "depressed", "depressing", "depression", "depressive", "depresi", "stres", "stress",
    "stressed", "stressful", "anxious", "anxiety", "panic", "panik", "trauma", "traumatic",
    "traumatized", "ptsd", "bipolar", "manic", "mania", "insomnia", "paranoid", "paranoia",
    "delusional", "hallucinate", "hallucination", "psychosis", "psychotic", "therapy",
    "therapist", "psychiatrist", "asylum", "mental", "mentally", "breakdown", "burnout",
    "sad", "sadness", "sadder", "saddest", "unhappy", "miserable", "misery", "sorrow",
    "grief", "grieving", "mourn", "mourning", "heartbroken", "heartbreak", "broken",
    "shattered", "crushed", "damaged", "ruined", "wrecked", "destroyed", "torn",
    "lonely", "loneliness", "lonesome", "alone", "isolated", "abandoned", "forsaken",
    "rejected", "ignored", "forgotten", "invisible", "outcast", "misfit",
    "hopeless", "hopelessness", "helpless", "powerless", "useless", "worthless",
    "meaningless", "pointless", "purpose", "empty", "emptiness", "hollow", "void",
    "numb", "numbness", "cold", "freezing", "frozen", "dark", "darkness", "shadow",
    "shadows", "nightmare", "nightmares", "demon", "demons", "monster", "monsters",
    "ghost", "ghosts", "haunted", "haunting", "curse", "cursed", "hell", "abyss",
    "pain", "painful", "pains", "ache", "aching", "hurt", "hurting", "hurts", "suffer",
    "suffering", "suffered", "agony", "torment", "torture", "tortured", "bleed",
    "bleeding", "scars", "scar", "scarred", "wounds", "wound", "wounded", "bruised",
    "cry", "crying", "cried", "cries", "tears", "tear", "weeping", "weep", "sob",
    "sobbing", "scream", "screaming", "screamed", "yell", "yelling", "beg", "begging",
    "drown", "drowning", "suffocate", "suffocating", "choke", "choking", "sink",
    "sinking", "falling", "fall", "fading", "fade", "disappear", "disappearing",
    "vanish", "lost", "losing", "lose", "giveup", "quitting", "quit", "surrender",
    "exhausted", "tired", "weary", "drained", "sick", "ill", "illness", "disease",
    "cancer", "tumor", "coma", "hospital", "ambulance", "stretcher", "icu",
    "hate", "hating", "hated", "hatred", "despise", "loathe", "disgust", "disgusting",
    "regret", "regrets", "guilt", "guilty", "shame", "ashamed", "blame", "fault",
    "mistake", "failure", "fail", "failed", "pathetic", "weak", "fragile", "afraid",
    "scared", "fear", "terrified", "horrified", "dread",
    "sedih", "kesedihan", "bersedih", "murung", "pilu", "lara", "duka", "berduka",
    "nestapa", "merana", "sengsara", "derita", "menderita", "penderitaan", "siksa",
    "tersiksa", "menyiksa", "pedih", "perih", "sakit", "menyakiti", "tersakiti",
    "luka", "terluka", "melukai", "berdarah", "parut", "goresan", "sembilu",
    "hancur", "menghancurkan", "remuk", "berkeping", "patah", "rapuh", "rusak",
    "runtuh", "tumbang", "roboh", "lebur", "musnah", "binasa", "punah",
    "hampa", "kehampaan", "kosong", "kekosongan", "beku", "membeku", "mati rasa",
    "kelam", "gelap", "kegelapan", "mendung", "kabut", "mimpi buruk", "petaka",
    "bencana", "kutukan", "terkutuk", "neraka", "jurang", "sepi", "kesepian",
    "sunyi", "kesunyian", "hening", "sendiri", "sendirian", "terasing", "tersisih",
    "terbuang", "terlupakan", "diabaikan", "ditinggalkan", "meninggalkan", "pergi",
    "kepergian", "hilang", "kehilangan", "lenyap", "sirna", "memudar", "memnudar",
    "pudar", "meredup", "redup", "remang", "tenggelam", "menangis", "tangis",
    "tangisan", "airmata", "isak", "terisak", "ratap", "meratap", "teriak",
    "berteriak", "jerit", "menjerit", "mengeluh", "keluh", "lelah", "kelelahan",
    "letih", "lesu", "capek", "muak", "jenuh", "bosan", "putus asa", "keputusasaan",
    "menyerah", "pasrah", "kalah", "gagal", "kegagalan", "sia-sia", "percuma",
    "beban", "sampah", "hina", "benci", "membenci", "kebencian", "dendam", "marah",
    "kemarahan", "murka", "kecewa", "kekecewaan", "mengecewakan", "sesal", "menyesal",
    "penyesalan", "bersalah", "dosa", "berdosa", "malu", "takut", "ketakutan",
    "cemas", "kecemasan", "gelisah", "khawatir", "ragu", "bimbang", "bingung", "kalut",

    -- ==================== 2. ROMANSA, SENTUHAN & RAWAN FALSE POSITIVE (ID) ====================
    "memiliki", "memilikimu", "miliki", "milikku", "milikmu", "dirimu", "diriku",
    "peluk", "memeluk", "memelukmu", "kupeluk", "dipeluk", "pelukan", "pelukanmu",
    "dekap", "mendekap", "kudekap", "dekapan", "rangkul", "merangkul", "kurangkul",
    "cium", "mencium", "menciummu", "kucium", "dicium", "ciuman", "kecup", "mengecup",
    "kukecup", "belai", "membelai", "kubelai", "belaian", "sentuh", "menyentuh",
    "menyentuhmu", "kusentuh", "tersentuh", "sentuhan", "raba", "meraba", "kuraba",
    "elus", "mengelus", "kuelus", "pangku", "memangku", "pangkuan", "gandeng",
    "pacar", "pacarku", "pacarmu", "pacaran", "berpacaran", "kekasih", "kekasihku",
    "sayang", "sayangku", "menyayangi", "kusayang", "cinta", "cintaku", "cintamu",
    "mencintai", "mencintaimu", "kucinta", "kucintai", "percintaan", "asmara",
    "kasmaran", "romantis", "mesra", "bermesraan", "kencan", "berkencan", "jadian",
    "gebetan", "mantan", "mantanku", "nikah", "menikah", "menikahimu", "pernikahan",
    "pengantin", "suami", "istri", "jodoh", "rayu", "merayu", "rayuan", "goda",
    "menggoda", "godaan", "rindu", "merindukan", "merindukanmu", "kurindu", "kangen",
    "hasrat", "gairah", "idaman", "pujaan", "kasih", "kasihku", "kekasihmu",

    -- ==================== 3. ANATOMI, PAKAIAN & KAMAR (ID) ====================
    "bibir", "bibirmu", "bibirku", "lidah", "lidahmu", "leher", "lehermu", "dada",
    "dadamu", "dadaku", "perut", "pinggang", "pinggangmu", "pinggul", "pinggulmu",
    "paha", "pahamu", "betis", "kulit", "kulitmu", "tubuh", "tubuhmu", "tubuhku",
    "badan", "badanmu", "badanku", "raga", "ragamu", "ragaku", "wajah", "wajahmu",
    "kening", "keningmu", "pipi", "pipimu", "jari", "jarimu", "tangan", "tanganmu",
    "bahu", "bahumu", "punggung", "punggungmu", "rambut", "rambutmu", "mata", "matamu",
    "keringat", "berkeringat", "peluh", "desah", "mendesah", "desahan", "napas",
    "napasmu", "nafas", "nafasmu", "baju", "bajumu", "celana", "rok", "pakaian",
    "busana", "handuk", "daleman", "kutang", "bh", "cd", "cangcut", "sempak", "kolor",
    "kamar", "kamarmu", "kamarku", "ranjang", "kasur", "bantal", "selimut", "guling",
    "tidur", "meniduri", "ketiduran", "kutiduri", "mandi", "hotel", "penginapan",
    "losmen", "villa", "kos", "kosan", "kontrakan", "toilet", "wc",

    -- ==================== 4. UMPATAN, HEWAN, KASAR & SLANG DAERAH (ID) ====================
    "anjing", "anjir", "anjay", "anjrit", "anjrot", "anying", "anjg", "ajg", "anj",
    "njir", "njay", "njer", "njrit", "asu", "asw", "kirik", "kirek", "babi", "celeng",
    "bagong", "bedul", "monyet", "munyuk", "kunyuk", "onyet", "lutung", "kampret",
    "kmprt", "kehed", "koplok", "koplak", "goblog", "goblok", "gblk", "tolol", "tll",
    "bodoh", "bdh", "bego", "begok", "bgo", "oon", "bloon", "dungu", "idiot", "autis",
    "cacat", "cct", "gila", "sinting", "sarap", "edan", "gelok", "gelo", "budek",
    "bolot", "buta", "picek", "bisu", "pincang", "gendut", "gembrot", "buncit",
    "ceking", "kerempeng", "jelek", "burik", "buluk", "dekil", "kucel", "miskin",
    "kere", "melarat", "gembel", "pengemis", "pecundang", "cupu", "kroco", "noob",
    "nub", "ampas", "bangsat", "bgst", "bangsad", "brengsek", "brngsk", "bajingan",
    "bjngn", "keparat", "bedebah", "kurangajar", "sialan", "sial", "bangke", "bangkai",
    "tai", "tahi", "taik", "tae", "teletong", "berak", "boker", "kentut", "kencing",
    "pipis", "ngompol", "bacot", "bct", "cocot", "congor", "moncong", "bacod",
    "nyinyir", "julid", "mampus", "mmps", "modar", "modaro", "kojor", "matek", "bongko",
    "setan", "syaiton", "iblis", "dajjal", "jahanam", "laknat", "haram", "jadah",
    "kafir", "munafik", "najis",
    "jancok", "jancuk", "dancok", "diancok", "diancuk", "juancok", "cuk", "cok",
    "coeg", "jangkrik", "jiangkrik", "matane", "ndasmu", "ndase", "utekmu",
    "lambemu", "lambene", "cangkemmu", "cangkeme", "raimu", "raine", "bathukmu",
    "gateli", "gatel", "tempik", "tempek", "turuk", "peli", "konthol", "dobol",
    "gendeng", "pekok", "kenthir", "gemblung", "semprul", "kampang", "kmpng",
    "pantek", "pntk", "pante", "kimak", "kmk", "pukimak", "puki", "pukimai",
    "cibai", "cb", "ccb", "cheebai", "lancau", "lanciau", "kanina", "knn",
    "bujanginam", "lonte", "sundal", "sundel", "sia", "jurig", "bebel", "kelek",
    "bodat", "bagudung", "babami", "biangkerok", "lassoc", "laso", "pacco",
    "telaso", "tailaso",

    -- ==================== 5. VULGAR, SEKSUAL & DEWASA (ID) ====================
    "kontol", "kntl", "kintil", "koncol", "memek", "mmk", "mamek", "pepek", "ppk",
    "jembut", "jmbt", "jembud", "itil", "klitoris", "pentil", "puting", "tetek",
    "tete", "tt", "toket", "tkt", "payudara", "buahdada", "nenen", "nyusu", "menyusui",
    "pantat", "bokong", "bool", "bujur", "silit", "lubang", "selangkangan", "kelamin",
    "kemaluan", "zakar", "vagina", "penis", "testis", "biji", "peler", "pler", "titit",
    "tytyd", "burung", "ngentot", "ngntt", "entot", "entod", "ngewe", "ngwe", "ewe",
    "ewean", "kenthu", "kentu", "kimpoi", "kawin", "mengawini", "peju", "pju", "mani",
    "sperma", "crot", "crott", "muncrat", "ejakulasi", "ereksi", "ngaceng", "tegang",
    "coli", "colmek", "onani", "masturbasi", "kocok", "mengocok", "gesek", "tusbol",
    "sodomi", "anal", "oral", "sepong", "nyepong", "emut", "mengemut", "jilat",
    "menjilat", "isap", "mengisap", "sange", "sangean", "horni", "nafsu", "birahi",
    "syahwat", "perawan", "keperawanan", "perjaka", "pelacur", "lacur", "lnt", "psk",
    "jablay", "bispak", "perek", "purel", "lc", "openbo", "bo", "michat", "mucikari",
    "germo", "simpanan", "sugarbaby", "sugardaddy", "selingkuh", "selingkuhan",
    "pelakor", "pebinor", "telanjang", "bugil", "polos", "seksi", "montok", "bohay",
    "semok", "bahenol", "bercinta", "seks", "seksual", "bokep", "bkp", "mesum",
    "cabul", "pencabulan", "perkosa", "memperkosa", "pemerkosaan", "pelecehan",
    "leceh", "pedofil", "pedo", "inses", "fetish", "bdsm", "kondom", "hamil",
    "menghamili", "aborsi", "keguguran", "haid", "menstruasi",

    -- ==================== 6. KEKERASAN, SENJATA, NARKOBA & KRIMINAL (ID) ====================
    "mati", "matilah", "kematian", "meninggal", "tewas", "wafat", "gugur", "bunuh",
    "membunuh", "pembunuh", "pembunuhan", "bantai", "membantai", "pembantaian",
    "cekik", "mencekik", "tikam", "menikam", "tusuk", "menusuk", "bacok", "membacok",
    "tebas", "penggal", "memenggal", "mutilasi", "gantung", "menggantung", "darah",
    "mayat", "jenazah", "jasad", "kuburan", "makam", "liang", "keranda", "pisau",
    "belati", "golok", "parang", "celurit", "clurit", "pedang", "sajam", "senjata",
    "senpi", "pistol", "bedil", "peluru", "tembak", "menembak", "bom", "meledak",
    "ledakan", "teroris", "terorisme", "sandera", "aniaya", "menganiaya", "hajar",
    "menghajar", "pukul", "memukul", "tonjok", "tendang", "racun", "beracun",
    "meracuni", "sianida", "mabuk", "mabok", "teler", "kobam", "miras", "alkohol",
    "bir", "anggur", "tuak", "ciu", "amer", "intisar", "arak", "oplosan", "narkoba",
    "narkotika", "ganja", "gele", "cimeng", "sabu", "shabu", "ekstasi", "inex",
    "heroin", "putaw", "kokain", "pil", "koplo", "tramadol", "excimer", "obat",
    "overdosis", "sakau", "rokok", "merokok", "sebat", "udud", "vape", "ngebul",
    "judi", "berjudi", "judol", "bandar", "slot", "gacor", "maxwin", "zeus", "depo",
    "wd", "togel", "taruhan", "maling", "pencuri", "rampok", "merampok", "begal",
    "copet", "korupsi", "suap", "penjara", "bui", "polisi", "umur", "umurmu", "usia",
    "alamat", "nomor", "telepon", "telp", "hp", "handphone", "wa", "ig", "fb",
    "uang", "duit", "bayar", "jual", "beli", "harga", "murahan",

    -- ==================== 7. PROFANITY, SLURS & SWEAR WORDS (EN) ====================
    "motherfucker", "motherfuckers", "motherfuckin", "motherfucking", "muthafucka",
    "muthafuckin", "mofo", "mf", "mfs", "fucker", "fuckers", "fucking", "fuckin",
    "fckin", "fcking", "fucked", "fucks", "fuck", "fck", "fuk", "fuq", "fuxk",
    "fcuk", "phuck", "phuk", "clusterfuck", "mindfuck", "fuckboy", "fuckboi",
    "fuckoff", "fuckup", "wtf", "stfu", "gtfo", "idgaf", "af", "omfg",
    "shitting", "shitter", "shitty", "bullshit", "horseshit", "apeshit", "batshit",
    "dipshit", "shithead", "shitstain", "shitshow", "shithole", "shits", "shit",
    "sht", "shat", "crap", "crappy", "turd", "fart", "piss", "pissed", "pissing",
    "pissoff", "bitching", "bitches", "bitchy", "bitchass", "sonofabitch", "bitch",
    "btch", "biatch", "biyatch", "assholes", "asshole", "ahole", "dumbass", "jackass",
    "badass", "fatass", "smartass", "deadass", "headass", "kickass", "asshat",
    "asswipe", "assclown", "asses", "ass", "arse", "arsehole", "bastards", "bastard",
    "dammit", "damned", "damn", "goddammit", "goddamn", "goddamned", "hella",
    "heck", "cunts", "cunt", "kunt", "dicks", "dickhead", "dickwad", "dickbag",
    "dickless", "dick", "dck", "cocks", "cocksucker", "cockhead", "cock", "kock",
    "pussies", "pussy", "pusy", "twat", "twats", "prick", "pricks", "wanker", "wank",
    "wanking", "bollocks", "bugger", "bellend", "knobhead", "tosser", "minge",
    "slag", "git", "twit", "douchebag", "douche", "scumbag", "scum", "dirtbag",
    "sleazebag", "jerkoff", "jerk", "creep", "freak", "loser", "moron", "imbecile",
    "dumb", "stupid", "fool",

    -- ==================== 8. SLURS, HATE SPEECH & DISCRIMINATION (EN) ====================
    "nigga", "niggas", "niggaz", "nigger", "niggers", "nibba", "nigg", "negro",
    "negroes", "coon", "spook", "jigaboo", "darkie", "chink", "gook", "chinaman",
    "zipperhead", "spic", "wetback", "beaner", "gringo", "cracker", "honky", "redneck",
    "whitey", "kike", "heeb", "goy", "raghead", "towelhead", "cameljockey", "sandnigger",
    "paki", "gypsy", "pikey", "injun", "redskin", "squaw", "faggot", "faggots", "fag",
    "fags", "faggy", "dyke", "lesbo", "homo", "queer", "tranny", "shemale", "ladyboy",
    "femboy", "twink", "retard", "retards", "retarded", "tard", "libtard", "cripple",
    "midget", "dwarf", "spastic", "spaz", "mongoloid", "autistic", "schizo", "psycho",
    "lunatic", "insane", "crazy", "fatso", "lardass", "obese", "anorexic", "incel",
    "simp", "virgin", "cuck", "cuckold", "nazi", "hitler", "fascist", "kkk", "gestapo",

    -- ==================== 9. SEXUAL, NSFW, ANATOMY & ROMANCE (EN) ====================
    "slutty", "sluts", "slut", "whores", "whore", "hoe", "hoes", "ho", "skank",
    "thot", "hooker", "prostitute", "stripper", "escort", "callgirl", "camgirl",
    "pimp", "brothel", "harlot", "wench", "nympho", "sexual", "sexually", "sexuality",
    "sex", "sexx", "sexy", "sexiest", "porn", "porno", "pornography", "pornhub",
    "xvideos", "xnxx", "brazzers", "hentai", "ecchi", "ahegao", "waifu", "loli",
    "shota", "futanari", "yaoi", "yuri", "nsfw", "rule34", "nude", "nudes", "nudity",
    "naked", "bare", "topless", "bottomless", "horny", "aroused", "erotic", "orgasm",
    "climax", "cum", "cumming", "cumshot", "creampie", "sperm", "semen", "jizz",
    "nut", "nutting", "busting", "squirt", "squirting", "erection", "boner", "hardon",
    "woody", "boobs", "boob", "boobies", "titties", "tits", "tit", "breasts", "breast",
    "mammary", "cleavage", "nipples", "nipple", "areola", "booty", "butt", "butthole",
    "asscheeks", "anus", "rectum", "sphincter", "groin", "crotch", "genitals",
    "phallus", "shaft", "foreskin", "testicles", "balls", "ballsack", "scrotum",
    "nutsack", "vulva", "clit", "labia", "hymen", "uterus", "womb", "thighs", "thigh",
    "hips", "hip", "waist", "chest", "neck", "throat", "lips", "lip", "tongue", "skin",
    "body", "bodies", "sweat", "sweating", "breath", "breathe", "breathing", "moan",
    "moaning", "groan", "panting", "gasp", "whisper", "kiss", "kisses", "kissing",
    "kissed", "smooch", "makeout", "frenchkiss", "hickey", "hug", "hugs", "hugging",
    "hugged", "cuddle", "cuddling", "snuggle", "caress", "touch", "touches", "touching",
    "touched", "fondle", "grope", "stroke", "rub", "rubbing", "lick", "licking",
    "suck", "sucking", "blowjob", "bj", "handjob", "hj", "footjob", "rimjob",
    "deepthroat", "fellatio", "cunnilingus", "doggy", "doggystyle", "missionary",
    "cowgirl", "threesome", "gangbang", "orgy", "penetration", "penetrate", "breed",
    "breeding", "submissive", "dominant", "dom", "sub", "master", "slave", "daddy",
    "mommy", "kitten", "senpai", "virginity", "lust", "desire", "kink", "kinky",
    "bondage", "spank", "spanking", "whip", "collar", "leash", "gag", "dildo",
    "vibrator", "lube", "viagra", "pregnant", "pregnancy", "abortion", "miscarriage",
    "period", "menstruation", "tampon", "rape", "raped", "raping", "rapist", "molest",
    "molester", "pedophile", "groomer", "grooming", "incest", "bestiality",
    "necrophilia", "zoophilia", "voyeur", "exhibitionist", "stalker", "stalking",
    "undress", "strip", "clothes", "shirt", "pants", "skirt", "dress", "underwear",
    "lingerie", "bra", "panties", "thong", "gstring", "bikini", "swimsuit", "corset",
    "stockings", "fishnets", "heels", "bed", "bedroom", "mattress", "sheets", "pillow",
    "blanket", "shower", "bath", "bathtub", "jacuzzi", "motel", "room", "boyfriend",
    "girlfriend", "bf", "gf", "lover", "lovers", "soulmate", "partner", "dating",
    "date", "tinder", "bumble", "grindr", "match", "crush", "flirt", "flirting",
    "seduce", "seduction", "tease", "tempt", "romance", "marry", "married", "marriage",
    "wedding", "husband", "wife", "hubby", "wifey", "bride", "groom", "fiance",
    "divorce", "affair", "cheating", "cheat", "unfaithful", "jealous", "ex", "babe",
    "baby", "darling", "sweetheart", "honey", "sugar", "shawty", "shorty", "bae",
    "cutie", "hottie", "gorgeous", "handsome", "pretty", "imagine", "imagining",

    -- ==================== 10. VIOLENCE, GORE, SELF-HARM & WEAPONS (EN) ====================
    "suicidal", "suicide", "kms", "kys", "selfharm", "cutting", "cutwrist", "overdose",
    "hangmyself", "jump", "killing", "killed", "killer", "kills", "kill", "murderer",
    "murdered", "murdering", "murder", "homicide", "manslaughter", "assassinate",
    "assassin", "execution", "execute", "genocide", "holocaust", "massacre",
    "slaughter", "butcher", "carnage", "bloodbath", "dying", "died", "dies", "die",
    "dead", "death", "deadly", "lethal", "fatal", "corpse", "cadaver", "carcass",
    "skeleton", "skull", "bones", "coffin", "casket", "grave", "graveyard", "cemetery",
    "tomb", "funeral", "morgue", "autopsy", "bloody", "blood", "gore", "gory", "guts",
    "intestines", "organs", "flesh", "stabbed", "stabbing", "stab", "slash", "slit",
    "slice", "chop", "decapitate", "behead", "dismember", "mutilate", "impale",
    "strangle", "burn", "burning", "lynch", "hang", "hanged", "noose", "gallows",
    "shoot", "shooting", "shooter", "shot", "gunshot", "headshot", "driveby", "snipe",
    "sniper", "shotgun", "guns", "gun", "firearm", "weapon", "revolver", "handgun",
    "glock", "rifle", "assault", "ar15", "ak47", "uzi", "mac10", "mp5", "smg",
    "machinegun", "ammo", "ammunition", "bullets", "bullet", "magazine", "clip",
    "trigger", "barrel", "holster", "knife", "dagger", "blade", "machete", "katana",
    "sword", "axe", "chainsaw", "brassknuckles", "taser", "pepperspray", "bomber",
    "bombing", "explosive", "dynamite", "tnt", "c4", "grenade", "landmine", "missile",
    "rocket", "nuke", "nuclear", "atomic", "radiation", "poison", "poisonous",
    "toxic", "venom", "cyanide", "arsenic", "acid", "anthrax", "terrorism", "isis",
    "alqaeda", "taliban", "cartel", "mafia", "gang", "gangster", "thug", "hoodlum",
    "criminal", "felon", "convict", "prisoner", "inmate", "jail", "prison", "cell",
    "handcuffs", "cops", "swat", "fbi", "cia", "arrest", "hostage", "kidnap",
    "kidnapping", "abduct", "ransom", "hijack", "abusive", "beat", "beating", "punch",
    "kick", "slap", "smack", "hit", "fight", "fighting", "brawl", "riot", "violent",
    "violence", "brutal", "savage", "cruel", "sadist", "masochist", "rob", "robbery",
    "steal", "theft", "thief", "burglar", "mug", "mugging", "loot", "scam", "scammer",
    "fraud", "hack", "hacker", "exploit", "ddos", "dox", "doxx", "swatting",
    "blackmail", "extort", "bribe", "smuggle", "contraband",

    -- ==================== 11. DRUGS, ALCOHOL, GAMBLING & SOCIALS (EN) ====================
    "drugs", "drug", "narcotics", "dope", "weed", "marijuana", "cannabis", "pot",
    "herb", "reefer", "kush", "hash", "hashish", "thc", "cbd", "edibles", "blunt",
    "joint", "spliff", "bong", "pipe", "stoned", "stoner", "baked", "high", "tripping",
    "trip", "cocaine", "coke", "blow", "crack", "freebase", "snort", "smack", "junkie",
    "needle", "syringe", "inject", "meth", "crystalmeth", "ice", "speed",
    "amphetamine", "adderall", "mdma", "molly", "lsd", "shrooms", "mushrooms",
    "psychedelic", "ketamine", "fentanyl", "opioid", "opiates", "morphine", "codeine",
    "lean", "purpledrank", "xanax", "xanny", "valium", "percocet", "percs", "oxy",
    "oxycontin", "vicodin", "pills", "tablet", "capsule", "steroid", "roids", "od",
    "rehab", "relapse", "addict", "addicted", "addiction", "dealer", "narco",
    "nicotine", "tobacco", "cigarette", "cigarettes", "cig", "cigs", "cigar",
    "vaping", "juul", "puff", "smoke", "smoking", "smoker", "ashtray", "lighter",
    "drunk", "drunken", "wasted", "hammered", "smashed", "plastered", "tipsy",
    "buzzed", "sober", "hangover", "alcoholic", "booze", "liquor", "spirits",
    "moonshine", "whiskey", "bourbon", "scotch", "vodka", "tequila", "rum", "gin",
    "brandy", "cognac", "absinthe", "beer", "ale", "lager", "stout", "pint", "keg",
    "wine", "champagne", "prosecco", "cocktail", "martini", "margarita", "mojito",
    "shots", "bartender", "bar", "pub", "tavern", "club", "nightclub", "party",
    "rave", "gamble", "gambling", "casino", "bet", "betting", "wager", "jackpot",
    "poker", "blackjack", "roulette", "slots", "lottery", "lotto", "money", "cash",
    "bucks", "dollar", "dollars", "rich", "wealthy", "poor", "broke", "bankrupt",
    "pay", "buy", "sell", "price", "cheap", "expensive", "free", "robux", "rbx",
    "giftcard", "crypto", "bitcoin", "discord", "tiktok", "instagram", "insta",
    "whatsapp", "telegram", "youtube", "yt", "twitter", "x", "facebook", "snapchat",
    "snap", "reddit", "twitch", "kick", "onlyfans", "patreon", "spotify", "soundcloud",
    "google", "phone", "number", "address", "email", "gmail", "password", "account", "age"
}

local aggressiveSubstrings = {
    "fuck", "fck", "fuk", "shit", "bitch", "cunt", "dick", "cock", "puss", "nigg",
    "fag", "slut", "whor", "rape", "pedo", "porn", "nude", "nud", "sex", "kill",
    "dead", "suicid", "depres", "anxi", "selfharm", "worthless", "hopeless",
    "kontol", "kntl", "memek", "pepek", "jembut", "jmbt", "ngentot", "ngewe",
    "tetek", "toket", "lonte", "pelacur", "bokep", "mesum", "cabul", "perkosa",
    "bunuh", "anjing", "anjir", "bangsat", "brengsek", "bajingan", "goblok",
    "tolol", "jancok", "jancuk", "pantek", "kimak", "puki", "sange", "memi",
    "muda", "remang", "milik", "derita", "siksa", "hancur", "tubuh", "badan",
    "bibir", "dada", "paha", "peluk", "cium", "sentuh", "bayang", "cinta",
    "sayang", "kasih", "rindu", "tidur", "kamar", "ranjang"
}

local wordLookup = {}
for _, w in ipairs(targetWords) do
    wordLookup[w:lower()] = true
end

-- Pemecah kata Multi-Layer (Memecah setiap 2-3 huruf agar tidak bisa disatukan kembali oleh AI Roblox)
local function obfuscateWord(word)
    if #word < 2 then return word end
    local mode = FilterModule.BypassMode or 3

    if mode == 1 then
        -- Mode 1: Homoglyph Vokal (Termasuk 'u') + Sisipan Zero-Width di tiap suku kata
        local out = {}
        local replaced = 0
        for i = 1, #word do
            local ch = word:sub(i, i)
            if homoglyphMap[ch] and replaced < 3 then
                ch = homoglyphMap[ch]
                replaced += 1
            end
            table.insert(out, ch)
            if i < #word and i % 2 == 0 then
                table.insert(out, ZWS)
            end
        end
        return table.concat(out, "")

    elseif mode == 2 then
        -- Mode 2: Multi Zero-Width Joiner setiap 2 huruf
        local out = {}
        for i = 1, #word do
            table.insert(out, word:sub(i, i))
            if i < #word and i % 2 == 0 then
                table.insert(out, (i % 4 == 0) and ZWS or ZWNJ)
            end
        end
        return table.concat(out, "")

    else
        -- Mode 3: Pemisah Suku Kata Visual ('·') + Homoglyph Vokal + Zero-Width
        -- Contoh: "tubuhmu" -> "tυ·bυh·mυ" (Kebal strip simbol oleh filter Roblox)
        local out = {}
        for i = 1, #word do
            local ch = word:sub(i, i)
            if homoglyphMap[ch] then
                ch = homoglyphMap[ch]
            end
            table.insert(out, ch)
            if i < #word and i % 2 == 0 then
                table.insert(out, ZWS .. "·")
            end
        end
        return table.concat(out, "")
    end
end

local function isStemMatched(stripped)
    if wordLookup[stripped] then return true end

    local suffixes = {"nya", "mu", "ku", "lah", "kah", "kan", "an", "in", "i", "ing", "ed", "er", "ers", "es", "s", "ly", "ness", "ful", "less", "ive", "ion"}
    for _, suf in ipairs(suffixes) do
        if #stripped > #suf + 2 and stripped:sub(-#suf) == suf then
            local stem = stripped:sub(1, #stripped - #suf)
            if wordLookup[stem] then return true end
        end
    end

    -- Awalan termasuk "ku-" dan "kau-" (seperti kubayangkan, kupeluk, kucium)
    local prefixes = {"ku", "kau", "di", "ke", "se", "me", "mem", "men", "meng", "meny", "pe", "pem", "pen", "peng", "ber", "ter", "per", "un", "in", "dis", "re"}
    for _, pre in ipairs(prefixes) do
        if #stripped > #pre + 2 and stripped:sub(1, #pre) == pre then
            local stem = stripped:sub(#pre + 1)
            if wordLookup[stem] then return true end
            for _, suf in ipairs(suffixes) do
                if #stem > #suf + 2 and stem:sub(-#suf) == suf then
                    local inner = stem:sub(1, #stem - #suf)
                    if wordLookup[inner] then return true end
                end
            end
        end
    end

    return false
end

function FilterModule.Sanitize(text, enabled)
    if not text or text == "" or enabled == false then return text end

    local cleaned = text:gsub("([%a'*%-]+)", function(word)
        local lowerWord = word:lower()
        local stripped = lowerWord:gsub("'", "")

        if lowerWord:find("%*") then
            return obfuscateWord(word:gsub("%*", "u"))
        end

        if isStemMatched(lowerWord) or isStemMatched(stripped) then
            return obfuscateWord(word)
        end

        if lowerWord:find("%-") then
            local parts = string.split(word, "-")
            for i, p in ipairs(parts) do
                local lp = p:lower():gsub("'", "")
                if isStemMatched(lp) then
                    parts[i] = obfuscateWord(p)
                else
                    for _, sub in ipairs(aggressiveSubstrings) do
                        if lp:find(sub, 1, true) then
                            parts[i] = obfuscateWord(p)
                            break
                        end
                    end
                end
            end
            return table.concat(parts, "-")
        end

        for _, sub in ipairs(aggressiveSubstrings) do
            if lowerWord:find(sub, 1, true) then
                return obfuscateWord(word)
            end
        end

        return word
    end)

    cleaned = cleaned:gsub("(%d)(%d)", "%1" .. ZWS .. "%2"):gsub("(%d)(%d)", "%1" .. ZWS .. "%2")
    return cleaned
end

return FilterModule
