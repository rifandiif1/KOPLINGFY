-- =================================================================================
-- KOPLINGTIFY LITE v2.5 - EXPANDED NON-REPLACEMENT BYPASS FILTER (KOPLINGTIFY_FILTER.luau)
-- =================================================================================
local FilterModule = {}

-- Pilihan Mode Bypass:
-- 1 = Homoglyph (Mengganti huruf vokal dengan karakter Cyrillic identik, terlihat 100% murni)
-- 2 = Zero-Width / Soft Separator (Menyisipkan karakter tak terlihat di tengah kata)
-- 3 = Simbol Visual (Menyisipkan karakter titik tengah '·' seperti "je·mbut")
FilterModule.BypassMode = 3

local homoglyphMap = {
    ["a"] = "а", -- U+0430
    ["e"] = "е", -- U+0435
    ["i"] = "і", -- U+0456
    ["o"] = "о", -- U+043E
    ["c"] = "с", -- U+0441
    ["p"] = "р", -- U+0440
    ["x"] = "х", -- U+0445
    ["y"] = "у", -- U+0443
    ["A"] = "А",
    ["E"] = "Е",
    ["I"] = "І",
    ["O"] = "О",
    ["C"] = "С",
    ["P"] = "Р",
    ["X"] = "Х"
}

local targetWords = {
    -- ==================== 1. KATA PUITIS, ROMANSA & RAWAN FALSE POSITIVE (ID) ====================
    "memnudar", "memudar", "pudar", "remang", "sunyi", "sepi", "kesepian",
    "gelap", "kegelapan", "hampa", "kelam", "lara", "pilu", "duka", "nestapa",
    "merana", "sengsara", "derita", "menderita", "tangis", "menangis", "airmata",
    "luka", "terluka", "melukai", "perih", "pedih", "sakit", "menyakiti",
    "memiliki", "memilikimu", "miliki", "milikku", "milikmu", "dirimu", "diriku",
    "peluk", "memeluk", "memelukmu", "pelukan", "dekap", "mendekap", "dekapan",
    "rangkul", "merangkul", "cium", "mencium", "ciuman", "kecup", "mengecup",
    "belai", "membelai", "belaian", "sentuh", "menyentuh", "sentuhan", "raba",
    "meraba", "elus", "mengelus", "pangku", "memangku", "pangkuan", "gandeng",
    "pacar", "pacarku", "pacarmu", "pacaran", "berpacaran", "kekasih", "kekasihku",
    "sayang", "sayangku", "menyayangi", "cinta", "cintaku", "cintamu", "mencintai",
    "mencintaimu", "percintaan", "asmara", "kasmaran", "romantis", "mesra",
    "bermesraan", "kencan", "berkencan", "jadian", "gebetan", "mantan", "mantanku",
    "nikah", "menikah", "menikahimu", "pernikahan", "pengantin", "suami", "istri",
    "jodoh", "rayu", "merayu", "rayuan", "goda", "menggoda", "godaan", " rindu",
    "merindukan", "merindukanmu", "kangen", "hasrat", "gairah", "damba", "idaman",

    -- ==================== 2. ANATOMI, PAKAIAN & KAMAR (ID) ====================
    "bibir", "bibirmu", "lidah", "leher", "lehermu", "dada", "dadamu", "dadaku",
    "perut", "pinggang", "pinggul", "paha", "pahamu", "betis", "kulit", "kulitmu",
    "tubuh", "tubuhmu", "tubuhku", "badan", "badanmu", "raga", "ragamu", "keringat",
    "berkeringat", "peluh", "desah", "mendesah", "desahan", "napas", "napasmu",
    "baju", "bajumu", "celana", "rok", "pakaian", "busana", "handuk", "daleman",
    "kutang", "bh", "cd", "cangcut", "sempak", "kolor", "kamar", "kamarmu",
    "ranjang", "kasur", "bantal", "selimut", "guling", "tidur", "meniduri",
    "ketiduran", "mandi", "hotel", "penginapan", "losmen", "villa", "kos", "kosan",
    "kontrakan", "toilet", "wc", "kamar mandi",

    -- ==================== 3. UMPATAN, HEWAN, KASAR & SLANG DAERAH (ID) ====================
    "anjing", "anjir", "anjay", "anjrit", "anjrot", "anying", "anjg", "ajg", "anj",
    "njir", "njay", "njer", "njrit", "asu", "asw", "kirik", "kirek", "babi", "celeng",
    "bagong", "bedul", "monyet", "munyuk", "kunyuk", "onyet", "lutung", "kampret",
    "kmprt", "kehed", "koplok", "koplak", "goblog", "goblok", "gblk", "tolol", "tll",
    "bodoh", "bdh", "bego", "begok", "bgo", "oon", "bloon", "dungu", "idiot", "autis",
    "cacat", "cct", "gila", "sinting", "sarap", "edan", "gelok", "gelo", "stres",
    "depresi", "frustrasi", "budek", "bolot", "buta", "picek", "bisu", "pincang",
    "gendut", "gembrot", "buncit", "ceking", "kerempeng", "jelek", "burik", "buluk",
    "dekil", "kucel", "miskin", "kere", "melarat", "gembel", "pengemis", "sampah",
    "pecundang", "cupu", "kroco", "noob", "nub", "ampas", " beban",
    "bangsat", "bgst", "bangsad", "brengsek", "brngsk", "bajingan", "bjngn",
    "keparat", "bedebah", "kurangajar", "sialan", "sial", "bangke", "bangkai",
    "tai", "tahi", "taik", "tae", "teletong", "berak", "boker", "kentut", "kencing",
    "pipis", "ngompol", "bacot", "bct", "cocot", "cct", "congor", "moncong", "bacod",
    "nyinyir", "julid", "mampus", "mmps", "modar", "modaro", "kojor", "matek", "bongko",
    "setan", "syaiton", "iblis", "dajjal", "neraka", "jahanam", "laknat", "terkutuk",
    "haram", "jadah", "dosa", "berdosa", "kafir", "munafik", "najis",
    -- Slang Jawa, Sunda, Sumatera, Timur
    "jancok", "jancuk", "dancok", "diancok", "diancuk", "juancok", "cuk", "cok",
    "coeg", "jangkrik", "jiangkrik", "matamu", "matane", "ndasmu", "ndase", "utekmu",
    "lambemu", "lambene", "cangkemmu", "cangkeme", "raimu", "raine", "bathukmu",
    "gateli", "gatel", "tempik", "tempek", "turuk", "peli", "konthol", "dobol",
    "gendeng", "pekok", "kenthir", "gemblung", "semprul", "kampang", "kmpng",
    "pantek", "pntk", "pante", "kimak", "kmk", "pukimak", "puki", "pukimai",
    "cibai", "cb", "ccb", "cheebai", "lancau", "lanciau", "kanina", "knn",
    "bujanginam", "lonte", "sundal", "sundel", "kehed", "sia", "anying", "jurig",
    "bebel", "kelek", "bodat", "bagudung", "babami", "biangkerok", "lassoc", "laso",
    "pacco", "telaso", "tailaso", "kongkalingkong",

    -- ==================== 4. VULGAR, SEKSUAL & DEWASA (ID) ====================
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
    "syahwat", "perawan", "keperawanan", "perjaka", "pelacur", "lacur", "lonte",
    "lnt", "psk", "jablay", "bispak", "perek", "purel", "lc", "openbo", "bo", "michat",
    "mucikari", "germo", "simpanan", "sugarbaby", "sugardaddy", "selingkuh",
    "selingkuhan", "pelakor", "pebinor", "telanjang", "bugil", "polos", "seksi",
    "montok", "bohay", "semok", "bahenol", "bercinta", "seks", "seksual", "bokep",
    "bkp", "mesum", "cabul", "pencabulan", "perkosa", "memperkosa", "pemerkosaan",
    "pelecehan", "leceh", " pedofil", "pedo", "inses", "fetish", "bdsm", "kondom",
    "hamil", "menghamili", "aborsi", "keguguran", "haid", "menstruasi",

    -- ==================== 5. KEKERASAN, SENJATA, NARKOBA & KRIMINAL (ID) ====================
    "mati", "matilah", "kematian", "meninggal", "tewas", "wafat", "gugur", "bunuh",
    "membunuh", "pembunuh", "pembunuhan", "bantai", "membantai", "pembantaian",
    "cekik", "mencekik", "tikam", "menikam", "tusuk", "menusuk", "bacok", "membacok",
    "tebas", "penggal", "memenggal", "mutilasi", "gantung", "menggantung", "darah",
    "berdarah", "mayat", "jenazah", "jasad", "kuburan", "makam", "liang", "keranda",
    "pisau", "belati", "golok", "parang", "celurit", "clurit", "pedang", "sajam",
    "senjata", "senpi", "pistol", "bedil", "peluru", "tembak", "menembak", "bom",
    "meledak", "ledakan", "teroris", "terorisme", "sandera", "siksa", "menyiksa",
    "aniaya", "menganiaya", "hajar", "menghajar", "pukul", "memukul", "tonjok",
    "tendang", "racun", "beracun", "meracuni", "sianida", "mabuk", "mabok", "teler",
    "kobam", "miras", "alkohol", "bir", "anggur", "tuak", "ciu", "amer", "intisar",
    "cap tikus", "arak", "oplosan", "narkoba", "narkotika", "ganja", "gele", "cimeng",
    "sabu", "shabu", "ekstasi", "inex", "heroin", "putaw", "kokain", "pil", "koplo",
    "tramadol", "excimer", "obat", "overdosis", "sakau", "rokok", "merokok", "sebat",
    "udud", "vape", "ngebul", "judi", "berjudi", "judol", "bandar", "slot", "gacor",
    "maxwin", "zeus", "depo", "wd", "togel", "taruhan", "maling", "pencuri", "rampok",
    "merampok", "begal", "copet", "korupsi", "suap", "penjara", "bui", "polisi",
    "umur", "umurmu", "usia", "alamat", "nomor", "telepon", "telp", "hp", "handphone",
    "wa", "ig", "fb", "tt", "uang", "duit", "bayar", "jual", "beli", "harga",

    -- ==================== 6. PROFANITY, SLURS & SWEAR WORDS (EN) ====================
    "motherfucker", "motherfuckers", "motherfuckin", "motherfucking", "muthafucka",
    "muthafuckin", "mofo", "mf", "mfs", "fucker", "fuckers", "fucking", "fuckin",
    "fckin", "fcking", "fucked", "fucks", "fuck", "fck", "fuk", "fuq", "fuxk",
    "fcuk", "phuck", "phuk", " clusterfuck", "mindfuck", "fuckboy", "fuckboi",
    "fuckoff", "fuckup", "wtf", "stfu", "gtfo", "idgaf", "af", "OMFG", "omfg",
    "shitting", "shitter", "shitty", "bullshit", "horseshit", "apeshit", "batshit",
    "dipshit", "shithead", "shitstain", "shitshow", "shithole", "shits", "shit",
    "sht", "shat", "crap", "crappy", "turd", "fart", "piss", "pissed", "pissing",
    "pissoff", "bitching", "bitches", "bitchy", "bitchass", "sonofabitch", "bitch",
    "btch", "biatch", "biyatch", "assholes", "asshole", "ahole", "dumbass", "jackass",
    "badass", "fatass", "smartass", "deadass", "headass", "kickass", "asshat",
    "asswipe", "assclown", "asses", "ass", "arse", "arsehole", "bastards", "bastard",
    "dammit", "damned", "damn", "goddammit", "goddamn", "goddamned", "hella", "hell",
    "heck", "cunts", "cunt", "kunt", "dicks", "dickhead", "dickwad", "dickbag",
    "dickless", "dick", "dck", "cocks", "cocksucker", "cockhead", "cock", "kock",
    "pussies", "pussy", "pusy", "twat", "twats", "prick", "pricks", "wanker", "wank",
    "wanking", "bollocks", "bugger", "bellend", "knobhead", "tosser", "minge",
    "slag", "git", "twit", "douchebag", "douche", "scumbag", "scum", "dirtbag",
    "sleazebag", "jerkoff", "jerk", "creep", "freak", "loser", "idiot", "moron",
    "imbecile", "dumb", "stupid", "fool",

    -- ==================== 7. SLURS, HATE SPEECH & DISCRIMINATION (EN) ====================
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

    -- ==================== 8. SEXUAL, NSFW, ANATOMY & ROMANCE (EN) ====================
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
    "penis", "phallus", "shaft", "foreskin", "testicles", "balls", "ballsack", "scrotum",
    "nutsack", "vagina", "vulva", "clit", "clitoris", "labia", "hymen", "uterus",
    "womb", "thighs", "thigh", "hips", "hip", "waist", "chest", "neck", "throat",
    "lips", "lip", "tongue", "skin", "body", "bodies", "sweat", "sweating", "breath",
    "breathe", "breathing", "moan", "moaning", "groan", "panting", "gasp", "whisper",
    "kiss", "kisses", "kissing", "kissed", "smooch", "makeout", "frenchkiss", "hickey",
    "hug", "hugs", "hugging", "hugged", "cuddle", "cuddling", "snuggle", "caress",
    "touch", "touches", "touching", "touched", "fondle", "grope", "stroke", "rub",
    "rubbing", "lick", "licking", "suck", "sucking", "blowjob", "bj", "handjob",
    "hj", "footjob", "rimjob", "deepthroat", "fellatio", "cunnilingus", "69",
    "doggy", "doggystyle", "missionary", "cowgirl", "threesome", "gangbang", "orgy",
    "anal", "oral", "penetration", "penetrate", "breed", "breeding", "submissive",
    "dominant", "dom", "sub", "master", "slave", "daddy", "mommy", "kitten", "senpai",
    "virginity", "lust", "desire", "fetish", "kink", "kinky", "bdsm", "bondage",
    "spank", "spanking", "whip", "collar", "leash", "gag", "dildo", "vibrator",
    "condom", "lube", "viagra", "pregnant", "pregnancy", "abortion", "miscarriage",
    "period", "menstruation", "tampon", "rape", "raped", "raping", "rapist", "molest",
    "molester", "pedophile", "pedo", "groomer", "grooming", "incest", "bestiality",
    "necrophilia", "zoophilia", "voyeur", "exhibitionist", "stalker", "stalking",
    "undress", "strip", "clothes", "shirt", "pants", "skirt", "dress", "underwear",
    "lingerie", "bra", "panties", "thong", "gstring", "bikini", "swimsuit", "corset",
    "stockings", "fishnets", "heels", "bed", "bedroom", "mattress", "sheets", "pillow",
    "blanket", "shower", "bath", "bathtub", "jacuzzi", "hotel", "motel", "room",
    "boyfriend", "girlfriend", "bf", "gf", "lover", "lovers", "soulmate", "partner",
    "dating", "date", "tinder", "bumble", "grindr", "match", "crush", "flirt",
    "flirting", "seduce", "seduction", "tease", "tempt", "romance", "romantic",
    "marry", "married", "marriage", "wedding", "husband", "wife", "hubby", "wifey",
    "bride", "groom", "fiance", "divorce", "affair", "cheating", "cheat", "unfaithful",
    "jealous", "ex", "babe", "baby", "darling", "sweetheart", "honey", "sugar",
    "shawty", "shorty", "bae", "cutie", "hottie", "gorgeous", "handsome", "pretty",

    -- ==================== 9. VIOLENCE, GORE, SELF-HARM & WEAPONS (EN) ====================
    "suicidal", "suicide", "kms", "kys", "selfharm", "cutting", "cutwrist", "overdose",
    "hangmyself", "jump", "killing", "killed", "killer", "kills", "kill", "murderer",
    "murdered", "murdering", "murder", "homicide", "manslaughter", "assassinate",
    "assassin", "execution", "execute", "genocide", "holocaust", "massacre",
    "slaughter", "butcher", "carnage", "bloodbath", "dying", "died", "dies", "die",
    "dead", "death", "deadly", "lethal", "fatal", "corpse", "cadaver", "carcass",
    "skeleton", "skull", "bones", "coffin", "casket", "grave", "graveyard", "cemetery",
    "tomb", "funeral", "morgue", "autopsy", "bleeding", "bleed", "bloody", "blood",
    "gore", "gory", "guts", "intestines", "organs", "flesh", "wound", "scar", "bruise",
    "stabbed", "stabbing", "stab", "slash", "slit", "slice", "chop", "decapitate",
    "behead", "dismember", "mutilate", "impale", "choke", "choking", "strangle",
    "suffocate", "drown", "drowning", "burn", "burning", "lynch", "hang", "hanged",
    "noose", "gallows", "shoot", "shooting", "shooter", "shot", "gunshot", "headshot",
    "driveby", "snipe", "sniper", "shotgun", "guns", "gun", "firearm", "weapon",
    "pistol", "revolver", "handgun", "glock", "desert eagle", "rifle", "assault",
    "ar15", "ak47", "uzi", "mac10", "mp5", "smg", "machinegun", "ammo", "ammunition",
    "bullets", "bullet", "magazine", "clip", "trigger", "barrel", "holster", "knife",
    "dagger", "blade", "machete", "katana", "sword", "axe", "chainsaw", "brassknuckles",
    "taser", "pepperspray", "bomb", "bomber", "bombing", "explosive", "dynamite",
    "tnt", "c4", "grenade", "landmine", "missile", "rocket", "nuke", "nuclear",
    "atomic", "radiation", "poison", "poisonous", "toxic", "venom", "cyanide",
    "arsenic", "acid", "anthrax", "terrorist", "terrorism", "isis", "alqaeda",
    "taliban", "cartel", "mafia", "gang", "gangster", "thug", "hoodlum", "criminal",
    "felon", "convict", "prisoner", "inmate", "jail", "prison", "cell", "handcuffs",
    "police", "cops", "swat", "fbi", "cia", "arrest", "hostage", "kidnap", "kidnapping",
    "abduct", "ransom", "hijack", "torture", "torment", "abuse", "abusive", "beat",
    "beating", "punch", "kick", "slap", "smack", "hit", "fight", "fighting", "brawl",
    "riot", "violent", "violence", "brutal", "savage", "cruel", "sadist", "masochist",
    "rob", "robbery", "steal", "theft", "thief", "burglar", "mug", "mugging", "loot",
    "scam", "scammer", "fraud", "hack", "hacker", "exploit", "ddos", "dox", "doxx",
    "swatting", "blackmail", "extort", "bribe", "smuggle", "contraband",

    -- ==================== 10. DRUGS, ALCOHOL, GAMBLING & SOCIALS (EN) ====================
    "drugs", "drug", "narcotics", "dope", "weed", "marijuana", "cannabis", "pot",
    "ganja", "herb", "reefer", "kush", "hash", "hashish", "thc", "cbd", "edibles",
    "blunt", "joint", "spliff", "bong", "pipe", "stoned", "stoner", "baked", "high",
    "tripping", "trip", "cocaine", "coke", "blow", "crack", "freebase", "snort",
    "heroin", "smack", "junkie", "needle", "syringe", "inject", "meth", "crystalmeth",
    "ice", "speed", "amphetamine", "adderall", "ecstasy", "mdma", "molly", "lsd",
    "shrooms", "mushrooms", "psychedelic", "ketamine", "fentanyl", "opioid", "opiates",
    "morphine", "codeine", "lean", "purpledrank", "xanax", "xanny", "valium", "percocet",
    "percs", "oxy", "oxycontin", "vicodin", "pills", "pill", "tablet", "capsule",
    " steroid", "roids", "overdose", "od", "rehab", "relapse", "addict", "addicted",
    "addiction", "dealer", "cartel", "narco", "nicotine", "tobacco", "cigarette",
    "cigarettes", "cig", "cigs", "cigar", "vape", "vaping", "juul", "puff", "smoke",
    "smoking", "smoker", "ashtray", "lighter", "drunk", "drunken", "wasted", "hammered",
    "smashed", "plastered", "tipsy", "buzzed", "sober", "hangover", "alcohol",
    "alcoholic", "booze", "liquor", "spirits", "moonshine", "whiskey", "bourbon",
    "scotch", "vodka", "tequila", "rum", "gin", "brandy", "cognac", "absinthe",
    "beer", "ale", "lager", "stout", "pint", "keg", "wine", "champagne", "prosecco",
    "cocktail", "martini", "margarita", "mojito", "shots", "bartender", "bar",
    "pub", "tavern", "club", "nightclub", "party", "rave", "gamble", "gambling",
    "casino", "bet", "betting", "wager", "jackpot", "poker", "blackjack", "roulette",
    "slots", "lottery", "lotto", "money", "cash", "bucks", "dollar", "dollars",
    "rich", "wealthy", "poor", "broke", "bankrupt", "pay", "buy", "sell", "price",
    "cheap", "expensive", "free", "robux", "rbx", "giftcard", "crypto", "bitcoin",
    "discord", "tiktok", "instagram", "insta", "whatsapp", "telegram", "youtube",
    "yt", "twitter", "x", "facebook", "fb", "snapchat", "snap", "reddit", "twitch",
    "kick", "onlyfans", "patreon", "spotify", "soundcloud", "google", "phone",
    "number", "address", "email", "gmail", "password", "account", "age"
}

-- Substring pendek yang paling agresif memicu Scunthorpe Problem di filter AI Roblox
local aggressiveSubstrings = {
    "fuck", "fck", "fuk", "shit", "bitch", "cunt", "dick", "cock", "puss", "nigg",
    "fag", "slut", "whor", "rape", "pedo", "porn", "nude", "nud", "sex", "kill",
    "dead", "suicide", "kontol", "kntl", "memek", "pepek", "jembut", "jmbt", "ngentot",
    "ngewe", "tetek", "toket", "lonte", "pelacur", "bokep", "mesum", "cabul",
    "perkosa", "bunuh", "anjing", "anjir", "bangsat", "brengsek", "bajingan",
    "goblok", "tolol", "jancok", "jancuk", "pantek", "kimak", "puki", "sange",
    "memi", "muda", "remang", "milik"
}

local wordLookup = {}
for _, w in ipairs(targetWords) do
    wordLookup[w:lower()] = true
end

local function obfuscateWord(word)
    if #word < 2 then return word end
    local mode = FilterModule.BypassMode or 1

    if mode == 1 then
        local replacedCount = 0
        local result = word:gsub(".", function(ch)
            if homoglyphMap[ch] and replacedCount < 2 then
                replacedCount += 1
                return homoglyphMap[ch]
            end
            return ch
        end)
        if replacedCount > 0 then
            return result
        end
        local mid = math.max(1, math.floor(#word / 2))
        return word:sub(1, mid) .. "\226\128\141" .. word:sub(mid + 1)

    elseif mode == 2 then
        local mid = math.max(1, math.floor(#word / 2))
        return word:sub(1, mid) .. "\226\128\141" .. word:sub(mid + 1)

    else
        local mid = math.max(1, math.floor(#word / 2))
        return word:sub(1, mid) .. "·" .. word:sub(mid + 1)
    end
end

-- Deteksi otomatis imbuhan Bahasa Indonesia & Inggris
local function isStemMatched(stripped)
    if wordLookup[stripped] then return true end

    -- Akhiran Indonesia & Inggris
    local suffixes = {"nya", "mu", "ku", "lah", "kah", "kan", "an", "in", "i", "ing", "ed", "er", "ers", "es", "s", "ly"}
    for _, suf in ipairs(suffixes) do
        if #stripped > #suf + 2 and stripped:sub(-#suf) == suf then
            local stem = stripped:sub(1, #stripped - #suf)
            if wordLookup[stem] then return true end
        end
    end

    -- Awalan Indonesia
    local prefixes = {"di", "ke", "se", "me", "mem", "men", "meng", "meny", "pe", "pem", "pen", "peng", "ber", "ter", "per"}
    for _, pre in ipairs(prefixes) do
        if #stripped > #pre + 2 and stripped:sub(1, #pre) == pre then
            local stem = stripped:sub(#pre + 1)
            if wordLookup[stem] then return true end
            -- Kombinasi awalan + akhiran (misal: menyayangimu -> sayang)
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

    cleaned = cleaned:gsub("(%d)(%d)", "%1\226\128\141%2"):gsub("(%d)(%d)", "%1\226\128\141%2")
    return cleaned
end

return FilterModule
