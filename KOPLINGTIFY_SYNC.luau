-- KOPLINGTIFY LITE (CUSTOM ORBIT CAMERA + SAFE WORD FILTER EDITION)
-- Fitur: Auto-Sync durasi lagu, tanpa batas max speed 2x, Auto-Search pergantian lagu,
-- UI Android ramah sentuh, Minimize, Floating Icon, Subtitle Transparan (HUD), Progress Bar,
-- Deteksi & Pengganti Kata Diblokir Roblox (Safe Lyrics), & Kamera Drone Orbit Full Setting.

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
if not player then
    Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
    player = Players.LocalPlayer
end

-- State & Variabel Utama
local cache = {}
local activeSound, activeSoundId = nil, nil
local activeItem = nil
local lyrics = {}
local currentIndex = 0
local lyricSpeed = 1.0
local syncOffset = 0.0
local manualSpeedOverride = false
local autoSpeedSynced = false
local isAutoRatioActive = false
local autoChat = false
local safeFilterEnabled = true
local isMutedLocally = false
local isSubtitleEnabled = false
local originalVolume = 0.5
local lastSentLine = ""
local scanToken = 0
local isMinimized = false

-- State & Konfigurasi Kamera Orbit
local isOrbitEnabled = false
local wasOrbitCam = false
local orbitAngle = 0
local orbitDistance = 10.0   -- Jarak kamera dari karakter (studs)
local orbitHeight = 3.5      -- Ketinggian kamera (studs)
local orbitSpeed = 0.55      -- Kecepatan putar (rad/detik)
local orbitLookHeight = 1.0  -- Titik fokus ketinggian pada karakter
local orbitFOV = 70          -- Field of View kamera saat orbit
local orbitDirection = 1     -- 1 = Kanan (Searah), -1 = Kiri (Berlawanan)
local savedDefaultFOV = (workspace.CurrentCamera and workspace.CurrentCamera.FieldOfView) or 70

local FULL_SIZE = UDim2.new(0, 340, 0, 420)
local MINI_SIZE = UDim2.new(0, 340, 0, 94)

local function safeCall(fn, ...)
    local ok, result = pcall(fn, ...)
    if ok then return result end
    return nil
end

local function httpGet(url)
    local ok, result = pcall(function()
        return game:HttpGet(url)
    end)
    if ok and type(result) == "string" then return result end
    return nil
end

local function formatTime(seconds)
    seconds = math.max(0, math.floor(tonumber(seconds) or 0))
    return string.format("%02d:%02d", math.floor(seconds / 60), seconds % 60)
end

-- ======================== KAMUS FILTER KATA AMAN ROBLOX ========================
local wordReplacements = {
    -- ================= 1. BAHASA INGGRIS: UMPATAN & SLANG KASAR =================
    ["motherfucker"] = "troublemaker",
    ["motherfuckers"] = "troublemakers",
    ["motherfuckin"] = "freakin",
    ["motherfucking"] = "freaking",
    ["muthafucka"] = "troublemaker",
    ["muthafuckin"] = "freakin",
    ["mf"] = "pal",
    ["fucking"] = "freaking",
    ["fuckin"] = "freakin",
    ["fckin"] = "freakin",
    ["fcking"] = "freaking",
    ["fucked"] = "messed",
    ["fucker"] = "joker",
    ["fuckers"] = "jokers",
    ["fuck"] = "freak",
    ["fucks"] = "cares",
    ["fck"] = "freak",
    ["fuk"] = "freak",
    ["fuq"] = "freak",
    ["wtf"] = "what",
    ["stfu"] = "shh",
    ["shitting"] = "kidding",
    ["shitty"] = "messy",
    ["bullshit"] = "nonsense",
    ["horseshit"] = "nonsense",
    ["dipshit"] = "goofball",
    ["shithead"] = "airhead",
    ["shits"] = "shoots",
    ["shit"] = "shoot",
    ["sht"] = "shoot",
    ["bitching"] = "complaining",
    ["bitches"] = "witches",
    ["bitchy"] = "sassy",
    ["bitch"] = "witch",
    ["btch"] = "witch",
    ["biatch"] = "witch",
    ["assholes"] = "rascals",
    ["asshole"] = "rascal",
    ["dumbass"] = "silly",
    ["jackass"] = "clown",
    ["badass"] = "cool",
    ["fatass"] = "heavy",
    ["asses"] = "butts",
    ["ass"] = "butt",
    ["arse"] = "butt",
    ["bastards"] = "rascals",
    ["bastard"] = "rascal",
    ["dammit"] = "darnit",
    ["damned"] = "darned",
    ["damn"] = "darn",
    ["goddammit"] = "goshdarn",
    ["goddamn"] = "goshdarn",
    ["hella"] = "super",
    ["hell"] = "heck",
    ["cunts"] = "jerks",
    ["cunt"] = "jerk",
    ["dicks"] = "jerks",
    ["dickhead"] = "blockhead",
    ["dick"] = "jerk",
    ["cocks"] = "roosters",
    ["cock"] = "rooster",
    ["pussies"] = "kitties",
    ["pussy"] = "kitty",
    ["twat"] = "fool",
    ["prick"] = "thorn",
    ["wanker"] = "joker",
    ["bollocks"] = "nonsense",
    ["bugger"] = "rascal",
    ["douchebag"] = "showoff",
    ["douche"] = "showoff",
    ["scumbag"] = "villain",
    ["slutty"] = "flirty",
    ["sluts"] = "heartbreakers",
    ["slut"] = "heartbreaker",
    ["whores"] = "players",
    ["whore"] = "player",
    ["hoe"] = "player",
    ["hoes"] = "players",
    ["skank"] = "meanie",
    ["prostitute"] = "dancer",
    ["stripper"] = "dancer",
    ["hooker"] = "dancer",
    ["pimp"] = "boss",

    -- ================= 2. BAHASA INGGRIS: RASIAL & DISKRIMINASI =================
    ["nigga"] = "homie",
    ["niggas"] = "homies",
    ["niggaz"] = "homies",
    ["nigger"] = "brother",
    ["niggers"] = "brothers",
    ["nibba"] = "homie",
    ["negro"] = "fellow",
    ["faggot"] = "fool",
    ["faggots"] = "fools",
    ["fag"] = "fool",
    ["fags"] = "fools",
    ["dyke"] = "rebel",
    ["tranny"] = "person",
    ["retard"] = "silly",
    ["retards"] = "goofballs",
    ["retarded"] = "foolish",
    ["cripple"] = "broken",
    ["spastic"] = "frantic",
-- 1. KONTAK FISIK / SENTUHAN (INDO)
    ["peluk"] = "rengkuh",
    ["memeluk"] = "merengkuh",
    ["memelukmu"] = "merengkuhmu",
    ["pelukan"] = "rengkuhan",
    ["pelukanmu"] = "rengkuhanmu",
    ["dipeluk"] = "direngkuh",
    ["dekap"] = "jaga",
    ["mendekap"] = "menjaga",
    ["dekapan"] = "naungan",
    ["rangkul"] = "gandeng",
    ["merangkul"] = "menggandeng",
    ["cium"] = "sapa",
    ["mencium"] = "menyapa",
    ["menciummu"] = "menyapamu",
    ["ciuman"] = "sapaan",
    ["dicium"] = "disapa",
    ["kecup"] = "sapa",
    ["mengecup"] = "menyapa",
    ["kecupan"] = "sapaan",
    ["belai"] = "usap",
    ["membelai"] = "mengusap",
    ["belaian"] = "usapan",
    ["sentuh"] = "raih",
    ["menyentuh"] = "meraih",
    ["menyentuhmu"] = "meraihmu",
    ["sentuhan"] = "raihan",
    ["tersentuh"] = "tergugah",
    ["raba"] = "cari",
    ["meraba"] = "mencari",
    ["pangku"] = "damping",
    ["memangku"] = "mendampingi",
    ["pangkuan"] = "sisi",
    ["gandeng"] = "iring",
    ["menggandeng"] = "mengiringi",
    ["elus"] = "usap",
    ["mengelus"] = "mengusap",

    -- 2. PACARAN / ROMANSA / ANTI-ODER (INDO)
    ["pacar"] = "rekan",
    ["pacarku"] = "rekanku",
    ["pacarmu"] = "rekanmu",
    ["pacaran"] = "berteman",
    ["berpacaran"] = "berteman",
    ["kekasih"] = "pujaan",
    ["kekasihku"] = "pujaanku",
    ["kekasihmu"] = "pujaanmu",
    ["sayang"] = "kasih",
    ["sayangku"] = "kasihku",
    ["sayangi"] = "kasihi",
    ["menyayangi"] = "mengasihi",
    ["kesayangan"] = "kebanggaan",
    ["cinta"] = "asa",
    ["cintaku"] = "asaku",
    ["cintamu"] = "asamu",
    ["mencintai"] = "mengagumi",
    ["mencintaimu"] = "mengagumimu",
    ["dicintai"] = "dikagumi",
    ["percintaan"] = "perjalanan",
    ["asmara"] = "irama",
    ["kasmaran"] = "bahagia",
    ["romantis"] = "manis",
    ["mesra"] = "akrab",
    ["kemesraan"] = "keakraban",
    ["bermesraan"] = "bersenda gurau",
    ["kencan"] = "jalan",
    ["berkencan"] = "berjalan",
    ["jadian"] = "bersama",
    ["gebetan"] = "idola",
    ["mantan"] = "kenangan",
    ["mantanku"] = "masa laluku",
    ["nikah"] = "janji",
    ["menikah"] = "berjanji",
    ["menikahimu"] = "menemanimu",
    ["pernikahan"] = "ikatan",
    ["pengantin"] = "pasangan",
    ["suami"] = "pendamping",
    ["suamiku"] = "pendampingku",
    ["istri"] = "pendamping",
    ["istriku"] = "pendampingku",
    ["jodoh"] = "takdir",
    ["rayu"] = "bujuk",
    ["merayu"] = "membujuk",
    ["rayuan"] = "pujian",
    ["goda"] = "canda",
    ["menggoda"] = "bercanda",
    ["godaan"] = "candaan",

    -- 3. BAGIAN TUBUH & BUSANA YANG SERING KENA FILTER (INDO)
    ["bibir"] = "senyum",
    ["bibirmu"] = "senyummu",
    ["bibirku"] = "senyumku",
    ["lidah"] = "ucap",
    ["leher"] = "bahu",
    ["lehermu"] = "bahumu",
    ["dada"] = "hati",
    ["dadamu"] = "hatimu",
    ["dadaku"] = "hatiku",
    ["perut"] = "raga",
    ["pinggang"] = "sisi",
    ["pinggul"] = "langkah",
    ["paha"] = "kaki",
    ["kulit"] = "rona",
    ["kulitmu"] = "ronamu",
    ["tubuh"] = "raga",
    ["tubuhmu"] = "ragamu",
    ["tubuhku"] = "ragaku",
    ["badan"] = "raga",
    ["badanmu"] = "ragamu",
    ["badanku"] = "ragaku",
    ["keringat"] = "peluh",
    ["berkeringat"] = "berpeluh",
    ["desahan"] = "hembusan",
    ["napas"] = "hembus",
    ["napasmu"] = "hembusanmu",
    ["baju"] = "jubah",
    ["bajumu"] = "jubahmu",
    ["celana"] = "pakaian",
    ["rok"] = "gaun",
    ["pakaian"] = "busana",
    ["handuk"] = "kain",

    -- 4. TEMPAT PRIVAT & AKTIVITAS MALAM (INDO)
    ["kamar"] = "ruang",
    ["kamarmu"] = "ruangmu",
    ["kamarku"] = "ruangku",
    ["ranjang"] = "peraduan",
    ["kasur"] = "alas",
    ["bantal"] = "sandaran",
    ["selimut"] = "penghangat",
    ["guling"] = "sandaran",
    ["tidur"] = "lelap",
    ["tidurlah"] = "lelaplah",
    ["meniduri"] = "menemani",
    ["ketiduran"] = "terlelap",
    ["mandi"] = "basuh",
    ["hotel"] = "gedung",
    ["penginapan"] = "singgahan",
    ["kos"] = " tempat",
    ["kosan"] = "tempat",

    -- 5. DATA PRIBADI / IDENTITAS / UANG (INDO)
    ["umur"] = "waktu",
    ["umurmu"] = "waktumu",
    ["umurku"] = "waktuku",
    ["usia"] = "masa",
    ["alamat"] = "arah",
    ["nomor"] = "angka",
    ["telepon"] = "suara",
    [" telp"] = " suara",
    ["hp"] = "layar",
    ["handphone"] = "layar",
    ["wa"] = "pesan",
    ["ig"] = "galeri",
    ["fb"] = "halaman",
    ["tt"] = "video",
    ["uang"] = "koin",
    ["duit"] = "koin",
    ["bayar"] = "tukar",
    ["membayar"] = "menukar",
    ["jual"] = "beri",
    ["beli"] = "ambil",
    ["harga"] = "nilai",
    ["murahan"] = "sederhana",

    -- 6. BAHASA INGGRIS: ROMANCE, TOUCH & BODY (SAFE YET CENSORED)
    ["kiss"] = "greet",
    ["kisses"] = "smiles",
    ["kissing"] = "smiling",
    ["kissed"] = "smiled",
    ["hug"] = "hold",
    ["hugs"] = "holds",
    ["hugging"] = "holding",
    ["hugged"] = "held",
    ["cuddle"] = "huddle",
    ["cuddling"] = "huddling",
    ["caress"] = "breeze",
    ["touch"] = "reach",
    ["touches"] = "reaches",
    ["touching"] = "reaching",
    ["touched"] = "reached",
    ["lips"] = "smile",
    ["lip"] = "smile",
    ["tongue"] = "voice",
    ["neck"] = "shoulder",
    ["chest"] = "heart",
    ["waist"] = "side",
    ["hips"] = "steps",
    ["hip"] = "step",
    ["thigh"] = "leg",
    ["skin"] = "glow",
    ["body"] = "soul",
    ["bodies"] = "souls",
    ["sweat"] = "rain",
    ["sweating"] = "shining",
    ["breath"] = "wind",
    ["breathe"] = "sigh",
    ["breathing"] = "sighing",
    ["moan"] = "sigh",
    ["moaning"] = "sighing",
    ["whisper"] = "echo",
    ["undress"] = "unwind",
    ["clothes"] = "outfit",
    ["shirt"] = "jacket",
    ["pants"] = "shoes",
    ["skirt"] = "dress",
    ["underwear"] = "gear",
    ["bra"] = "top",
    ["panties"] = "gear",
    ["bikini"] = "swimsuit",
    ["bed"] = "cloud",
    ["bedroom"] = "room",
    ["sheets"] = "clouds",
    ["pillow"] = "cushion",
    ["blanket"] = "cover",
    ["shower"] = "rain",
    ["hotel"] = "tower",
    ["motel"] = "tower",
    ["boyfriend"] = "partner",
    ["girlfriend"] = "partner",
    ["lover"] = "dreamer",
    ["lovers"] = "dreamers",
    ["dating"] = "hanging",
    ["date"] = "meet",
    ["marry"] = "promise",
    ["married"] = "promised",
    ["wedding"] = "party",
    ["husband"] = "partner",
    ["wife"] = "partner",
    ["bride"] = "star",
    ["groom"] = "star",
    ["babe"] = "star",
    ["baby"] = "darling", -- kadang "baby" aman, tapi jika digabung kata lain sering kena sensor
    ["honey"] = "sweetie",
    ["sugar"] = "sweet",
    ["shawty"] = "shorty",
    ["shorty"] = "friend",
    ["daddy"] = "boss",
    ["mommy"] = "queen",
    ["crush"] = "spark",
    ["flirt"] = "tease",
    ["flirting"] = "joking",
    ["seduce"] = "charm",
    ["jealous"] = "envious",
    ["cheating"] = "lying",
    ["cheat"] = "trick",
    ["ex"] = "past"
    -- ================= 3. BAHASA INGGRIS: KEKERASAN, DARAH & SENJATA =================
    ["suicidal"] = "hopeless",
    ["suicide"] = "give up",
    ["kms"] = "sigh",
    ["kys"] = "bye",
    ["killing"] = "chilling",
    ["killed"] = "chilled",
    ["killer"] = "hunter",
    ["kills"] = "chills",
    ["kill"] = "chill",
    ["murderer"] = "stranger",
    ["murdered"] = "vanished",
    ["murdering"] = "chasing",
    ["murder"] = "mystery",
    ["homicide"] = "incident",
    ["genocide"] = "wipeout",
    ["massacre"] = "chaos",
    ["slaughter"] = "defeat",
    ["butcher"] = "fighter",
    ["dying"] = "fading",
    ["died"] = "faded",
    ["dies"] = "fades",
    ["die"] = "fly",
    ["dead"] = "gone",
    ["death"] = "sleep",
    ["corpse"] = "statue",
    ["coffin"] = "box",
    ["grave"] = "ground",
    ["bleeding"] = "crying",
    ["bleed"] = "cry",
    ["bloody"] = "messy",
    ["blood"] = "sweat",
    ["gore"] = "mess",
    ["stabbed"] = "poked",
    ["stabbing"] = "poking",
    ["stab"] = "poke",
    ["slit"] = "cut",
    ["choke"] = "gasp",
    ["choking"] = "gasping",
    ["strangle"] = "grab",
    ["hang"] = "hold",
    ["hanged"] = "held",
    ["shoot"] = "blast",
    ["shooting"] = "blasting",
    ["shotgun"] = "blaster",
    ["gunshot"] = "thunder",
    ["guns"] = "blasters",
    ["gun"] = "blaster",
    ["pistol"] = "blaster",
    ["rifle"] = "blaster",
    ["glock"] = "blaster",
    ["ak47"] = "blaster",
    ["bullets"] = "sparks",
    ["bullet"] = "spark",
    ["trigger"] = "switch",
    ["bomb"] = "boom",
    ["terrorist"] = "villain",
    ["terrorism"] = "chaos",
    ["hostage"] = "captive",
    ["torture"] = "trouble",
    ["abuse"] = "mistreat",
    ["violent"] = "wild",
    ["violence"] = "chaos",

    -- ================= 4. BAHASA INGGRIS: DEWASA, ROMANSA EKSTREM & ALKOHOL/OBAT =================
    ["sexual"] = "romantic",
    ["sexually"] = "deeply",
    ["sex"] = "love",
    ["sexy"] = "lovely",
    ["sexiest"] = "loveliest",
    ["porn"] = "movie",
    ["porno"] = "movie",
    ["hentai"] = "anime",
    ["nsfw"] = "secret",
    ["nude"] = "bare",
    ["nudes"] = "photos",
    ["naked"] = "bare",
    ["horny"] = "lonely",
    ["orgasm"] = "climax",
    ["climax"] = "peak",
    ["cum"] = "come",
    ["cumming"] = "coming",
    ["sperm"] = "seed",
    ["erection"] = "rising",
    ["boner"] = "spark",
    ["boobs"] = "chest",
    ["boob"] = "chest",
    ["titties"] = "chest",
    ["tits"] = "chest",
    ["tit"] = "chest",
    ["nipples"] = "buttons",
    ["nipple"] = "button",
    ["booty"] = "hips",
    ["thighs"] = "legs",
    ["virgin"] = "innocent",
    ["virginity"] = "innocence",
    ["lust"] = "desire",
    ["fetish"] = "habit",
    ["kinky"] = "quirky",
    ["bdsm"] = "chains",
    ["rape"] = "hurt",
    ["raped"] = "hurt",
    ["rapist"] = "villain",
    ["molest"] = "bother",
    ["pedophile"] = "creep",
    ["pedo"] = "creep",
    ["incest"] = "kin",
    ["drugs"] = "sweets",
    ["drug"] = "candy",
    ["weed"] = "herb",
    ["marijuana"] = "herbs",
    ["cannabis"] = "herbs",
    ["blunt"] = "stick",
    ["joint"] = "roll",
    ["stoned"] = "sleepy",
    ["cocaine"] = "powder",
    ["coke"] = "soda",
    ["heroin"] = "potion",
    ["meth"] = "crystal",
    ["ecstasy"] = "joy",
    ["molly"] = "candy",
    ["lsd"] = "dream",
    ["acid"] = "lemon",
    ["pills"] = "mints",
    ["pill"] = "mint",
    ["overdose"] = "overload",
    ["addict"] = "fan",
    ["addicted"] = "hooked",
    ["nicotine"] = "caffeine",
    ["cigarette"] = "candle",
    ["cigarettes"] = "candles",
    ["vape"] = "mist",
    ["smoking"] = "glowing",
    ["smoke"] = "cloud",
    ["drunk"] = "dizzy",
    ["wasted"] = "tired",
    ["tipsy"] = "giggly",
    ["alcohol"] = "soda",
    ["liquor"] = "juice",
    ["whiskey"] = "tea",
    ["vodka"] = "water",
    ["tequila"] = "lemonade",
    ["beer"] = "rootbeer",
    ["wine"] = "grape",
    ["champagne"] = "sparkling",
    ["bartender"] = "barista",

    -- ================= 5. BAHASA INDONESIA: UMPATAN, HEWAN & KASAR =================
    ["anjing"] = "kucing",
    ["anjir"] = "astaga",
    ["anjay"] = "keren",
    ["anjrit"] = "waduh",
    ["anjrot"] = "waduh",
    ["anying"] = "kucing",
    ["njir"] = "wah",
    ["njay"] = "keren",
    ["asu"] = "kucing",
    ["babi"] = "kelinci",
    ["celeng"] = "kelinci",
    ["monyet"] = "kera",
    ["kunyuk"] = "kera",
    ["kampret"] = "kelelawar",
    ["bangsat"] = "nakal",
    ["bgst"] = "nakal",
    ["brengsek"] = "bandel",
    ["bajingan"] = "penjahat",
    ["keparat"] = "nakal",
    ["bedebah"] = "bandel",
    ["kurangajar"] = "nakal",
    ["sialan"] = "aduhai",
    ["sial"] = "malang",
    ["bangke"] = "bangkai",
    ["bangkai"] = "ranting",
    ["tai"] = "debu",
    ["tahi"] = "debu",
    ["taik"] = "debu",
    ["berak"] = "pergi",
    ["kentut"] = "angin",
    ["kencing"] = "air",
    ["bacot"] = "bicara",
    ["bct"] = "bicara",
    ["cocot"] = "mulut",
    ["congost"] = "mulut",
    ["congor"] = "mulut",
    ["nyinyir"] = "cerewet",
    ["mampus"] = "habis",
    ["modar"] = "habis",
    ["kojor"] = "lemas",
    ["matek"] = "lemas",
    ["setan"] = "bayangan",
    ["syaiton"] = "bayangan",
    ["iblis"] = "bayangan",
    ["dajjal"] = "raksasa",
    ["neraka"] = "lembah",
    ["jahanam"] = "gelap",
    ["laknat"] = "buruk",
    ["terkutuk"] = "terlupakan",
    ["haram"] = "terlarang",
    ["dosa"] = "salah",
    ["berdosa"] = "bersalah",
    ["kafir"] = "asing",

    -- ================= 6. BAHASA INDONESIA: HINAAN FISIK / MENTAL & SLANG DAERAH =================
    ["goblok"] = "polos",
    ["goblog"] = "polos",
    ["gblk"] = "polos",
    ["tolol"] = "lucu",
    ["tll"] = "lucu",
    ["bodoh"] = "polos",
    ["bego"] = "lugu",
    ["begok"] = "lugu",
    ["oon"] = "lugu",
    ["bloon"] = "lugu",
    ["dungu"] = "polos",
    ["idiot"] = "unik",
    ["autis"] = "fokus",
    ["cacat"] = "kurang",
    ["gila"] = "heboh",
    ["sinting"] = "heboh",
    ["sarap"] = "heboh",
    ["edan"] = "heboh",
    ["stres"] = "pusing",
    ["depresi"] = "sedih",
    ["frustrasi"] = "kecewa",
    ["budek"] = "kurang dengar",
    ["buta"] = "gelap",
    ["bisu"] = "diam",
    ["pincang"] = "pelan",
    ["gendut"] = "gemoy",
    ["gembrot"] = "gemoy",
    ["ceking"] = "ramping",
    ["jelek"] = "biasa",
    ["burik"] = "pudar",
    ["dekil"] = "lusuh",
    ["miskin"] = "sederhana",
    ["melarat"] = "sederhana",
    ["gembel"] = "pengembara",
    ["pengemis"] = "pencari",
    ["sampah"] = "dedaunan",
    ["pecundang"] = "pemula",
    ["cupu"] = "pemula",
    ["noob"] = "pemula",
    ["jancok"] = "astaga",
    ["jancuk"] = "astaga",
    ["dancok"] = "astaga",
    ["cuk"] = "kawan",
    ["cok"] = "kawan",
    ["jangkrik"] = "belalang",
    ["matamu"] = "matanya",
    ["ndasmu"] = "kepalamu",
    ["lambemu"] = "ucapanmu",
    ["raimu"] = "wajahmu",
    ["pantek"] = "waduh",
    ["pante"] = "pantai",
    ["kimak"] = "astaga",
    ["pukimak"] = "astaga",
    ["puki"] = "kucing",
    ["sundal"] = "nakal",
    ["bujang"] = "pemuda",

    -- ================= 7. BAHASA INDONESIA: DEWASA, ANATOMI & VULGAR =================
    ["kontol"] = "konyol",
    ["kntl"] = "konyol",
    ["memek"] = "bebek",
    ["mmk"] = "bebek",
    ["pepek"] = "bebek",
    ["jembut"] = "rambut",
    ["jmbt"] = "rambut",
    ["itil"] = "kecil",
    ["pentil"] = "ujung",
    ["tetek"] = "dada",
    ["tete"] = "dada",
    ["toket"] = "dada",
    ["payudara"] = "dada",
    ["buahdada"] = "dada",
    ["pantat"] = "belakang",
    ["bokong"] = "belakang",
    ["bool"] = "belakang",
    ["paha"] = "kaki",
    ["selangkangan"] = "pinggang",
    ["kelamin"] = "raga",
    ["zakar"] = "raga",
    ["vagina"] = "bunga",
    ["penis"] = "batang",
    ["ngentot"] = "joget",
    ["entot"] = "joget",
    ["ngewe"] = "joget",
    ["ewe"] = "joget",
    ["kenthu"] = "joget",
    ["kimpoi"] = "menikah",
    ["kawin"] = "menikah",
    ["peju"] = "keju",
    ["mani"] = "embun",
    ["sperma"] = "benih",
    ["coli"] = "sendiri",
    ["onani"] = "sendiri",
    ["masturbasi"] = "melamun",
    ["desah"] = "napas",
    ["mendesah"] = "bernapas",
    ["sange"] = "rindu",
    ["horni"] = "rindu",
    ["nafsu"] = "hasrat",
    ["birahi"] = "hasrat",
    ["gairah"] = "semangat",
    ["syahwat"] = "perasaan",
    ["perawan"] = "gadis",
    ["keperawanan"] = "kesucian",
    ["perjaka"] = "jejaka",
    ["pelacur"] = "penari",
    ["lonte"] = "bunga",
    ["PSK"] = "pekerja",
    ["psk"] = "pekerja",
    ["jablay"] = "santai",
    ["bispak"] = "santai",
    ["openbo"] = "jalan",
    ["michat"] = "pesan",
    ["mucikari"] = "perantara",
    ["germo"] = "perantara",
    ["simpanan"] = "rahasia",
    ["selingkuh"] = "mendua",
    ["selingkuhan"] = "bayangan",
    ["pelakor"] = "penggoda",
    ["pebinor"] = "penggoda",
    ["telanjang"] = "polos",
    ["bugil"] = "polos",
    ["buka-bukaan"] = "terbuka",
    ["seksi"] = "anggun",
    ["montok"] = "indah",
    ["bohay"] = "indah",
    ["semok"] = "indah",
    ["bercinta"] = "berdansa",
    ["seks"] = "cinta",
    ["seksual"] = "romantis",
    ["bokep"] = "film",
    ["mesum"] = "nakal",
    ["cabul"] = "nakal",
    ["perkosa"] = "lukai",
    ["memperkosa"] = "melukai",
    ["pemerkosaan"] = "kejahatan",
    ["pelecehan"] = "gangguan",
    ["ciuman"] = "senyuman",
    ["cium"] = "senyum",
    ["mencium"] = "menyapa",
    ["bibir"] = "senyum",
    ["peluk"] = "dekap",
    ["memeluk"] = "mendekap",
    ["ranjang"] = "tempat",
    ["kasur"] = "bantal",
    ["kamar"] = "ruang",

    -- ================= 8. BAHASA INDONESIA: KEKERASAN, KRIMINAL & ZAT TERLARANG =================
    ["mati"] = "pergi",
    ["matilah"] = "pergilah",
    ["kematian"] = "kepergian",
    ["meninggal"] = "berpulang",
    ["tewas"] = "gugur",
    ["bunuh"] = "kejar",
    ["membunuh"] = "mengejar",
    ["pembunuh"] = "pemburu",
    ["pembunuhan"] = "perburuan",
    ["bantai"] = "kalahkan",
    ["membantai"] = "mengalahkan",
    ["cekik"] = "pegang",
    ["mencekik"] = "memegang",
    ["tikam"] = "sentuh",
    ["menikam"] = "menyentuh",
    ["tusuk"] = "sentuh",
    ["menusuk"] = "menyentuh",
    ["bacok"] = "tebas",
    ["membacok"] = "menebas",
    ["penggal"] = "potong",
    ["gantung"] = "ayun",
    ["darah"] = "merah",
    ["berdarah"] = "terluka",
    ["mayat"] = "patung",
    ["jenazah"] = "raga",
    ["kuburan"] = "taman",
    ["makam"] = "taman",
    ["pisau"] = "pedang",
    ["belati"] = "pedang",
    ["golok"] = "pedang",
    ["celurit"] = "sabit",
    ["senjata"] = "alat",
    ["peluru"] = "cahaya",
    ["tembak"] = "bidik",
    ["menembak"] = "membidik",
    ["racun"] = "ramuan",
    ["beracun"] = "berbahaya",
    ["meracuni"] = "mengganggu",
    ["mabuk"] = "pusing",
    ["mabok"] = "pusing",
    ["teler"] = "lelah",
    ["miras"] = "sirup",
    ["alkohol"] = "soda",
    ["bir"] = "soda",
    ["anggur"] = "jus",
    ["tuak"] = "air",
    ["ciu"] = "air",
    ["amer"] = "sirup",
    ["intisar"] = "sirup",
    ["narkoba"] = "permen",
    ["narkotika"] = "permen",
    ["ganja"] = "daun",
    ["sabu"] = "kristal",
    ["ekstasi"] = "permen",
    ["heroin"] = "bubuk",
    ["kokain"] = "bubuk",
    ["pil"] = "permen",
    ["obat"] = "jamu",
    ["rokok"] = "asap",
    ["merokok"] = "berasap",
    ["judi"] = "main",
    ["berjudi"] = "bermain",
    ["bandar"] = "penjaga",
    ["slot"] = "mesin",
    ["maling"] = "pencari",
    ["pencuri"] = "pengambil",
    ["merampok"] = "mengambil",
    ["korupsi"] = "curang",
    ["penjara"] = "istana",

    -- ================= 9. NAMA PLATFORM & TRIGGER MODERASI ROBLOX (OFF-SITE LINKS) =================
    -- Roblox sering menyensor satu kalimat penuh jika mendeteksi nama aplikasi luar
    ["discord"] = "radio",
    ["tiktok"] = "clock",
    ["instagram"] = "camera",
    ["whatsapp"] = "phone",
    ["telegram"] = "letter",
    ["youtube"] = "video",
    ["twitter"] = "bird",
    ["facebook"] = "book",
    ["snapchat"] = "ghost",
    ["tinder"] = "flame",
    ["onlyfans"] = "fanclub",
    ["spotify"] = "music"

}

local function matchCase(original, replacement)
    if original == original:upper() and #original > 1 then
        return replacement:upper()
    elseif original:sub(1, 1) == original:sub(1, 1):upper() then
        return replacement:sub(1, 1):upper() .. replacement:sub(2)
    end
    return replacement
end

local function sanitizeLyricText(text)
    if not text or text == "" or not safeFilterEnabled then
        return text
    end

    local cleaned = text:gsub("([%a']+)", function(word)
        local lowerWord = word:lower()
        local rep = wordReplacements[lowerWord]
        if rep then
            return matchCase(word, rep)
        end
        local stripped = lowerWord:gsub("'", "")
        if wordReplacements[stripped] then
            return matchCase(word, wordReplacements[stripped])
        end
        return word
    end)

    cleaned = cleaned:gsub("(%d)(%d)", "%1 %2"):gsub("(%d)(%d)", "%1 %2")
    return cleaned
end

local function cleanSongName(name)
    if not name then return "" end
    local clean = name:gsub("%[.-%]", ""):gsub("%(.-%)", ""):gsub("%{.-%}", "")
    local tags = {
        "audio", "full song", "sped up", "slowed", "bass boosted",
        "nightcore", "tiktok", "remix", "clean", "explicit",
        "short", "cut", "mv", "music video", "official", "lyrics", "lyric"
    }
    for _, tag in ipairs(tags) do
        clean = clean:gsub(tag, ""):gsub(tag:upper(), ""):gsub(tag:sub(1,1):upper() .. tag:sub(2), "")
    end
    clean = clean:gsub("[^%w%s%-]", ""):gsub("%s+", " "):match("^%s*(.-)%s*$")
    return (clean == "" or #clean < 2) and name or clean
end

local function getAggressiveName(name)
    if not name then return "" end
    local n = name:lower()
    local splitStr = string.split(n, "-")[1]
    if not splitStr then return "" end
    n = string.split(splitStr, "|")[1]
    n = string.split(n, "(")[1]
    n = string.split(n, "[")[1]
    return n:match("^%s*(.-)%s*$") or ""
end

local function parseLRC(raw)
    local parsed = {}
    for line in tostring(raw or ""):gmatch("[^\r\n]+") do
        local stamps = {}
        for stamp in line:gmatch("%[(%d+:%d+%.?%d*)%]") do
            local mm, ss = stamp:match("^(%d+):(%d+%.?%d*)$")
            if mm and ss then
                table.insert(stamps, tonumber(mm) * 60 + tonumber(ss))
            end
        end
        local text = line:gsub("%[%d+:%d+%.?%d*%]", ""):gsub("^%s+", ""):gsub("%s+$", "")
        for _, t in ipairs(stamps) do
            table.insert(parsed, {Time = t, Text = text})
        end
    end
    table.sort(parsed, function(a, b) return a.Time < b.Time end)
    return parsed
end

local function searchLyrics(query)
    query = tostring(query or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if query == "" then return {} end
    local key = string.lower(query)
    if cache[key] then return cache[key] end

    local url = "https://lrclib.net/api/search?q=" .. HttpService:UrlEncode(query)
    local body = httpGet(url)
    if not body then return {} end

    local ok, data = pcall(function() return HttpService:JSONDecode(body) end)
    if not ok or type(data) ~= "table" then return {} end

    local results = {}
    for _, item in ipairs(data) do
        local raw = item.syncedLyrics
        if type(raw) == "string" and raw ~= "" then
            local parsed = parseLRC(raw)
            if #parsed > 0 then
                local origDuration = tonumber(item.duration) or 0
                if origDuration == 0 and #parsed > 0 then
                    origDuration = parsed[#parsed].Time + 10
                end
                table.insert(results, {
                    Title = item.trackName or "Judul tidak diketahui",
                    Artist = item.artistName or "Artis tidak diketahui",
                    Album = item.albumName or "",
                    Duration = origDuration,
                    Lyrics = parsed
                })
            end
        end
        if #results >= 8 then break end
    end
    if #results > 0 then
        cache[key] = results
    end
    return results
end

local function sendChat(message)
    if not message or message == "" then return end
    local safeMsg = sanitizeLyricText(message)
    local sent = false
    pcall(function()
        if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
            local channels = TextChatService:FindFirstChild("TextChannels")
            local channel = channels and (channels:FindFirstChild("RBXGeneral") or channels:FindFirstChildWhichIsA("TextChannel"))
            if channel then
                channel:SendAsync(safeMsg)
                sent = true
            end
        end
    end)
    if not sent then
        pcall(function()
            local folder = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
            local remote = folder and folder:FindFirstChild("SayMessageRequest")
            if remote then remote:FireServer(safeMsg, "All") end
        end)
    end
end

local function findSound()
    local best, bestVolume = nil, -1
    local roots = {workspace, game:GetService("SoundService"), player}
    for _, root in ipairs(roots) do
        for _, obj in ipairs(root:GetDescendants()) do
            if obj:IsA("Sound") and obj.IsPlaying and obj.SoundId ~= "" and (obj.Volume > 0 or (isMutedLocally and obj == activeSound)) then
                if obj.TimeLength == 0 or obj.TimeLength > 15 then
                    local vol = (obj == activeSound and isMutedLocally) and originalVolume or obj.Volume
                    if vol > bestVolume then
                        best, bestVolume = obj, vol
                    end
                end
            end
        end
    end
    return best
end

-- ======================== SAFE GUI PARENT ========================
local function getSafeParent()
    local okGethui, hui = pcall(function()
        return gethui and gethui()
    end)
    if okGethui and hui then return hui end

    local okCore, core = pcall(function()
        return game:GetService("CoreGui")
    end)
    if okCore and core then return core end

    return player:WaitForChild("PlayerGui")
end

pcall(function()
    if gethui and gethui():FindFirstChild("KoplingtifyLite") then gethui().KoplingtifyLite:Destroy() end
end)
pcall(function()
    if game:GetService("CoreGui"):FindFirstChild("KoplingtifyLite") then game:GetService("CoreGui").KoplingtifyLite:Destroy() end
end)
pcall(function()
    local pg = player:FindFirstChild("PlayerGui")
    if pg and pg:FindFirstChild("KoplingtifyLite") then pg.KoplingtifyLite:Destroy() end
end)

local gui = Instance.new("ScreenGui")
gui.Name = "KoplingtifyLite"
gui.ResetOnSpawn = false
gui.DisplayOrder = 9999
gui.Parent = getSafeParent()

-- Frame Utama
local main = Instance.new("Frame")
main.Name = "Main"
main.Size = FULL_SIZE
main.Position = UDim2.new(0.5, -170, 0.1, 0)
main.BackgroundColor3 = Color3.fromRGB(20, 22, 27)
main.BorderSizePixel = 0
main.Active = true
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)

local mainStroke = Instance.new("UIStroke", main)
mainStroke.Color = Color3.fromRGB(30, 215, 125)
mainStroke.Thickness = 1.5
mainStroke.Transparency = 0.25

-- Tombol Mengambang (Floating Pill)
local floatBtn = Instance.new("TextButton")
floatBtn.Name = "FloatingToggle"
floatBtn.Size = UDim2.new(0, 50, 0, 50)
floatBtn.Position = UDim2.new(0, 20, 0.45, 0)
floatBtn.BackgroundColor3 = Color3.fromRGB(22, 26, 32)
floatBtn.TextColor3 = Color3.fromRGB(30, 230, 135)
floatBtn.Font = Enum.Font.GothamBold
floatBtn.TextSize = 22
floatBtn.Text = "🎵"
floatBtn.Visible = false
floatBtn.Active = true
floatBtn.Parent = gui
Instance.new("UICorner", floatBtn).CornerRadius = UDim.new(1, 0)
local floatStroke = Instance.new("UIStroke", floatBtn)
floatStroke.Color = Color3.fromRGB(30, 215, 125)
floatStroke.Thickness = 2

-- ======================== SUBTITLE HUD OVERLAY (TRANSPARAN) ========================
local subtitleFrame = Instance.new("Frame")
subtitleFrame.Name = "SubtitleOverlay"
subtitleFrame.Size = UDim2.new(0, 500, 0, 68)
subtitleFrame.Position = UDim2.new(0.5, -250, 0.82, 0)
subtitleFrame.BackgroundTransparency = 1
subtitleFrame.Visible = false
subtitleFrame.Active = true
subtitleFrame.Parent = gui

local subMainText = Instance.new("TextLabel")
subMainText.Name = "SubCurrent"
subMainText.Size = UDim2.new(1, 0, 0, 38)
subMainText.Position = UDim2.new(0, 0, 0, 0)
subMainText.BackgroundTransparency = 1
subMainText.Font = Enum.Font.GothamBold
subMainText.TextSize = 20
subMainText.TextColor3 = Color3.fromRGB(255, 255, 255)
subMainText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
subMainText.TextStrokeTransparency = 0.1
subMainText.TextWrapped = true
subMainText.Text = "Menunggu lagu..."
subMainText.Parent = subtitleFrame

local subNextText = Instance.new("TextLabel")
subNextText.Name = "SubNext"
subNextText.Size = UDim2.new(1, 0, 0, 24)
subNextText.Position = UDim2.new(0, 0, 0, 40)
subNextText.BackgroundTransparency = 1
subNextText.Font = Enum.Font.GothamSemibold
subNextText.TextSize = 14
subNextText.TextColor3 = Color3.fromRGB(185, 195, 205)
subNextText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
subNextText.TextStrokeTransparency = 0.25
subNextText.TextWrapped = true
subNextText.Text = ""
subNextText.Parent = subtitleFrame

local function makeLabel(parent, name, pos, size, text, fontSize, color)
    local obj = Instance.new("TextLabel")
    obj.Name = name
    obj.Position = pos
    obj.Size = size
    obj.BackgroundTransparency = 1
    obj.Font = Enum.Font.Gotham
    obj.TextSize = fontSize
    obj.TextColor3 = color or Color3.fromRGB(240, 240, 240)
    obj.Text = text
    obj.TextWrapped = true
    obj.Parent = parent
    return obj
end

local function makeButton(parent, text, pos, size, bgColor)
    local b = Instance.new("TextButton")
    b.Position = pos
    b.Size = size
    b.BackgroundColor3 = bgColor or Color3.fromRGB(39, 45, 51)
    b.TextColor3 = Color3.fromRGB(245, 245, 245)
    b.Font = Enum.Font.GothamSemibold
    b.TextSize = 11
    b.Text = text
    b.AutoButtonColor = true
    b.Parent = parent
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 7)
    return b
end

local function makeHoldable(btn, callback)
    local holding = false
    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            holding = true
            callback()
            task.wait(0.3)
            while holding and gui.Parent do
                callback()
                task.wait(0.05)
            end
        end
    end)
    btn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            holding = false
        end
    end)
    btn.MouseLeave:Connect(function()
        holding = false
    end)
end

local function enableDrag(dragHandle, targetFrame)
    local dragging, dragInput, dragStart, startPos = false, nil, nil, nil
    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = targetFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    dragHandle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            targetFrame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- ======================== HEADER BAR ========================
local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Size = UDim2.new(1, 0, 0, 40)
topBar.BackgroundColor3 = Color3.fromRGB(26, 30, 37)
topBar.BorderSizePixel = 0
topBar.Active = true
topBar.Parent = main
Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 12)

local titleHeader = makeLabel(topBar, "Header", UDim2.new(0, 10, 0, 3), UDim2.new(1, -230, 0, 18), "KOPLINGTIFY LITE", 12, Color3.fromRGB(30, 230, 135))
titleHeader.Font = Enum.Font.GothamBold
titleHeader.TextXAlignment = Enum.TextXAlignment.Left

local status = makeLabel(topBar, "Status", UDim2.new(0, 10, 0, 20), UDim2.new(1, -230, 0, 16), "Putar musik atau cari lirik...", 9, Color3.fromRGB(160, 168, 178))
status.TextXAlignment = Enum.TextXAlignment.Left
status.TextTruncate = Enum.TextTruncate.AtEnd

-- Tombol Kontrol Header (🎥 Orbit, ⚙ Orbit Setting, 📺 Subtitle, 🔊 Mute, 🎵 Pill, — Minimize, × Close)
local orbitBtn = makeButton(topBar, "🎥", UDim2.new(1, -218, 0, 6), UDim2.new(0, 26, 0, 28), Color3.fromRGB(39, 45, 55))
local orbitCfgBtn = makeButton(topBar, "⚙", UDim2.new(1, -188, 0, 6), UDim2.new(0, 26, 0, 28), Color3.fromRGB(39, 45, 55))
local subToggleBtn = makeButton(topBar, "📺", UDim2.new(1, -158, 0, 6), UDim2.new(0, 26, 0, 28), Color3.fromRGB(39, 45, 55))
local muteBtn = makeButton(topBar, "🔊", UDim2.new(1, -128, 0, 6), UDim2.new(0, 26, 0, 28), Color3.fromRGB(39, 45, 55))
local pillModeBtn = makeButton(topBar, "🎵", UDim2.new(1, -98, 0, 6), UDim2.new(0, 26, 0, 28), Color3.fromRGB(39, 45, 55))
local minBtn = makeButton(topBar, "—", UDim2.new(1, -68, 0, 6), UDim2.new(0, 26, 0, 28), Color3.fromRGB(39, 45, 55))
local closeBtn = makeButton(topBar, "×", UDim2.new(1, -38, 0, 6), UDim2.new(0, 28, 0, 28), Color3.fromRGB(130, 42, 48))
closeBtn.TextSize = 15

enableDrag(topBar, main)
enableDrag(floatBtn, floatBtn)
enableDrag(subtitleFrame, subtitleFrame)

-- ======================== PANEL KUSTOMISASI ORBIT KAMERA (⚙) ========================
local orbitPanel = Instance.new("Frame")
orbitPanel.Name = "OrbitSettingsPanel"
orbitPanel.Size = UDim2.new(0, 280, 0, 290)
orbitPanel.Position = UDim2.new(0.5, 178, 0.1, 0)
orbitPanel.BackgroundColor3 = Color3.fromRGB(22, 24, 30)
orbitPanel.BorderSizePixel = 0
orbitPanel.Visible = false
orbitPanel.Active = true
orbitPanel.Parent = gui
Instance.new("UICorner", orbitPanel).CornerRadius = UDim.new(0, 12)

local orbitStroke = Instance.new("UIStroke", orbitPanel)
orbitStroke.Color = Color3.fromRGB(165, 105, 235)
orbitStroke.Thickness = 1.5

local orbitTopBar = Instance.new("Frame")
orbitTopBar.Size = UDim2.new(1, 0, 0, 34)
orbitTopBar.BackgroundColor3 = Color3.fromRGB(30, 32, 42)
orbitTopBar.BorderSizePixel = 0
orbitTopBar.Active = true
orbitTopBar.Parent = orbitPanel
Instance.new("UICorner", orbitTopBar).CornerRadius = UDim.new(0, 12)

local orbitTitle = makeLabel(orbitTopBar, "OrbitTitle", UDim2.new(0, 12, 0, 0), UDim2.new(1, -45, 1, 0), "🎥 PENGATURAN ORBIT KAMERA", 11, Color3.fromRGB(205, 165, 255))
orbitTitle.Font = Enum.Font.GothamBold
orbitTitle.TextXAlignment = Enum.TextXAlignment.Left

local closeOrbitPanelBtn = makeButton(orbitTopBar, "×", UDim2.new(1, -30, 0, 4), UDim2.new(0, 24, 0, 26), Color3.fromRGB(120, 42, 48))
closeOrbitPanelBtn.TextSize = 14
enableDrag(orbitTopBar, orbitPanel)

local orbitToggleInsideBtn = makeButton(orbitPanel, "Status Orbit: OFF", UDim2.new(0, 12, 0, 42), UDim2.new(1, -24, 0, 28), Color3.fromRGB(39, 45, 55))

local orbitUiUpdaters = {}

local function createOrbitSettingRow(yPos, labelText, formatStr, getVal, setVal, step, minVal, maxVal)
    local lbl = makeLabel(orbitPanel, labelText, UDim2.new(0, 12, 0, yPos), UDim2.new(0, 125, 0, 26), labelText, 11, Color3.fromRGB(210, 215, 225))
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local btnMinus = makeButton(orbitPanel, "−", UDim2.new(0, 142, 0, yPos), UDim2.new(0, 32, 0, 26), Color3.fromRGB(40, 46, 56))
    btnMinus.TextSize = 15

    local valLbl = makeLabel(orbitPanel, "Val", UDim2.new(0, 176, 0, yPos), UDim2.new(0, 56, 0, 26), string.format(formatStr, getVal()), 11, Color3.fromRGB(205, 165, 255))
    valLbl.Font = Enum.Font.GothamBold

    local btnPlus = makeButton(orbitPanel, "+", UDim2.new(0, 236, 0, yPos), UDim2.new(0, 32, 0, 26), Color3.fromRGB(40, 46, 56))
    btnPlus.TextSize = 15

    local function refresh()
        valLbl.Text = string.format(formatStr, getVal())
    end
    table.insert(orbitUiUpdaters, refresh)

    makeHoldable(btnMinus, function()
        local nv = math.clamp(math.floor((getVal() - step) * 100 + 0.5) / 100, minVal, maxVal)
        setVal(nv)
        refresh()
    end)

    makeHoldable(btnPlus, function()
        local nv = math.clamp(math.floor((getVal() + step) * 100 + 0.5) / 100, minVal, maxVal)
        setVal(nv)
        refresh()
    end)
end

-- Baris Pengaturan Orbit (Jarak, Tinggi, Kecepatan, Fokus Y, FOV)
createOrbitSettingRow(78,  "Jarak (Stud):",    "%.1f",  function() return orbitDistance end,   function(v) orbitDistance = v end,   0.5,  2.0,  60.0)
createOrbitSettingRow(110, "Ketinggian (Y):",  "%.1f",  function() return orbitHeight end,     function(v) orbitHeight = v end,     0.5, -10.0, 35.0)
createOrbitSettingRow(142, "Kecepatan Putar:", "%.2fx", function() return orbitSpeed end,      function(v) orbitSpeed = v end,      0.05, 0.0,  5.0)
createOrbitSettingRow(174, "Titik Fokus (Y):", "%.1f",  function() return orbitLookHeight end, function(v) orbitLookHeight = v end, 0.5, -5.0,  10.0)
createOrbitSettingRow(206, "Sudut Lensa FOV:", "%d°",   function() return orbitFOV end,        function(v) orbitFOV = v end,        2,    20,   120)

local orbitDirBtn = makeButton(orbitPanel, "🔄 Arah: Kanan", UDim2.new(0, 12, 0, 244), UDim2.new(0, 124, 0, 32), Color3.fromRGB(45, 52, 64))
local orbitResetBtn = makeButton(orbitPanel, "♻ Reset Orbit", UDim2.new(0, 144, 0, 244), UDim2.new(0, 124, 0, 32), Color3.fromRGB(65, 50, 85))

orbitDirBtn.MouseButton1Click:Connect(function()
    orbitDirection = -orbitDirection
    orbitDirBtn.Text = orbitDirection == 1 and "🔄 Arah: Kanan" or "🔄 Arah: Kiri"
end)

orbitResetBtn.MouseButton1Click:Connect(function()
    orbitDistance = 10.0
    orbitHeight = 3.5
    orbitSpeed = 0.55
    orbitLookHeight = 1.0
    orbitFOV = 70
    orbitDirection = 1
    orbitDirBtn.Text = "🔄 Arah: Kanan"
    for _, fn in ipairs(orbitUiUpdaters) do fn() end
end)

-- ======================== MINI LYRIC BAR (Tampil Saat Minimize) ========================
local miniBar = Instance.new("Frame")
miniBar.Name = "MiniBar"
miniBar.Position = UDim2.new(0, 10, 0, 44)
miniBar.Size = UDim2.new(1, -20, 0, 44)
miniBar.BackgroundColor3 = Color3.fromRGB(27, 31, 38)
miniBar.BorderSizePixel = 0
miniBar.Visible = false
miniBar.Parent = main
Instance.new("UICorner", miniBar).CornerRadius = UDim.new(0, 8)

local miniLyricText = makeLabel(miniBar, "MiniLyric", UDim2.new(0, 10, 0, 2), UDim2.new(1, -20, 0, 34), "Menunggu lagu...", 13, Color3.fromRGB(255, 255, 255))
miniLyricText.Font = Enum.Font.GothamBold

local miniProgBg = Instance.new("Frame")
miniProgBg.Position = UDim2.new(0, 8, 1, -6)
miniProgBg.Size = UDim2.new(1, -16, 0, 3)
miniProgBg.BackgroundColor3 = Color3.fromRGB(45, 52, 65)
miniProgBg.BorderSizePixel = 0
miniProgBg.Parent = miniBar
Instance.new("UICorner", miniProgBg).CornerRadius = UDim.new(1, 0)

local miniProgFill = Instance.new("Frame")
miniProgFill.Size = UDim2.new(0, 0, 1, 0)
miniProgFill.BackgroundColor3 = Color3.fromRGB(30, 215, 125)
miniProgFill.BorderSizePixel = 0
miniProgFill.Parent = miniProgBg
Instance.new("UICorner", miniProgFill).CornerRadius = UDim.new(1, 0)

-- ======================== BODY CONTAINER ========================
local body = Instance.new("Frame")
body.Name = "Body"
body.Position = UDim2.new(0, 0, 0, 42)
body.Size = UDim2.new(1, 0, 1, -42)
body.BackgroundTransparency = 1
body.Parent = main

local searchBox = Instance.new("TextBox")
searchBox.Position = UDim2.new(0, 12, 0, 4)
searchBox.Size = UDim2.new(1, -110, 0, 32)
searchBox.BackgroundColor3 = Color3.fromRGB(32, 36, 44)
searchBox.TextColor3 = Color3.new(1, 1, 1)
searchBox.PlaceholderColor3 = Color3.fromRGB(145, 152, 162)
searchBox.PlaceholderText = "Cari judul lagu / artis..."
searchBox.ClearTextOnFocus = false
searchBox.Font = Enum.Font.Gotham
searchBox.TextSize = 12
searchBox.Text = ""
searchBox.Parent = body
Instance.new("UICorner", searchBox).CornerRadius = UDim.new(0, 7)

local clearSearchBtn = makeButton(body, "×", UDim2.new(1, -94, 0, 4), UDim2.new(0, 26, 0, 32), Color3.fromRGB(50, 56, 66))
clearSearchBtn.TextSize = 14
clearSearchBtn.MouseButton1Click:Connect(function()
    searchBox.Text = ""
    searchBox:CaptureFocus()
end)

local searchBtn = makeButton(body, "CARI", UDim2.new(1, -64, 0, 4), UDim2.new(0, 52, 0, 32), Color3.fromRGB(30, 160, 95))

-- Daftar Hasil Pencarian
local resultsFrame = Instance.new("ScrollingFrame")
resultsFrame.Position = UDim2.new(0, 12, 0, 42)
resultsFrame.Size = UDim2.new(1, -24, 0, 64)
resultsFrame.BackgroundColor3 = Color3.fromRGB(26, 30, 37)
resultsFrame.BorderSizePixel = 0
resultsFrame.ScrollBarThickness = 5
resultsFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
resultsFrame.Parent = body
Instance.new("UICorner", resultsFrame).CornerRadius = UDim.new(0, 7)

local resultLayout = Instance.new("UIListLayout", resultsFrame)
resultLayout.Padding = UDim.new(0, 4)
resultLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- Area Lirik Utama
local lyricCard = Instance.new("TextButton")
lyricCard.Name = "LyricCard"
lyricCard.Position = UDim2.new(0, 12, 0, 112)
lyricCard.Size = UDim2.new(1, -24, 0, 96)
lyricCard.BackgroundColor3 = Color3.fromRGB(25, 29, 36)
lyricCard.BorderSizePixel = 0
lyricCard.Text = ""
lyricCard.AutoButtonColor = false
lyricCard.Parent = body
Instance.new("UICorner", lyricCard).CornerRadius = UDim.new(0, 9)

local prevLine = makeLabel(lyricCard, "Previous", UDim2.new(0, 8, 0, 4), UDim2.new(1, -16, 0, 20), "", 11, Color3.fromRGB(135, 143, 153))
local currentLine = makeLabel(lyricCard, "Current", UDim2.new(0, 8, 0, 25), UDim2.new(1, -16, 0, 44), "Menunggu lagu...", 15, Color3.fromRGB(255, 255, 255))
currentLine.Font = Enum.Font.GothamBold
local nextLine = makeLabel(lyricCard, "Next", UDim2.new(0, 8, 0, 71), UDim2.new(1, -16, 0, 20), "", 11, Color3.fromRGB(135, 143, 153))

lyricCard.MouseButton1Click:Connect(function()
    local txt = currentLine.Text
    if txt ~= "" and txt ~= "Menunggu lagu..." and txt ~= "Mendeteksi lagu..." and txt ~= "Lirik tidak tersedia." and txt ~= "♪" then
        sendChat(txt)
    end
end)

-- ======================== PROGRESS BAR LAGU & WAKTU REAL-TIME ========================
local timeCurrentLbl = makeLabel(body, "TimeCurrent", UDim2.new(0, 12, 0, 213), UDim2.new(0, 42, 0, 16), "00:00", 10, Color3.fromRGB(165, 175, 185))
timeCurrentLbl.TextXAlignment = Enum.TextXAlignment.Left

local progBarBg = Instance.new("Frame")
progBarBg.Name = "ProgressBarBg"
progBarBg.Position = UDim2.new(0, 54, 0, 219)
progBarBg.Size = UDim2.new(1, -108, 0, 5)
progBarBg.BackgroundColor3 = Color3.fromRGB(38, 44, 54)
progBarBg.BorderSizePixel = 0
progBarBg.Parent = body
Instance.new("UICorner", progBarBg).CornerRadius = UDim.new(1, 0)

local progBarFill = Instance.new("Frame")
progBarFill.Name = "Fill"
progBarFill.Size = UDim2.new(0, 0, 1, 0)
progBarFill.BackgroundColor3 = Color3.fromRGB(30, 215, 125)
progBarFill.BorderSizePixel = 0
progBarFill.Parent = progBarBg
Instance.new("UICorner", progBarFill).CornerRadius = UDim.new(1, 0)

local timeTotalLbl = makeLabel(body, "TimeTotal", UDim2.new(1, -54, 0, 213), UDim2.new(0, 42, 0, 16), "00:00", 10, Color3.fromRGB(165, 175, 185))
timeTotalLbl.TextXAlignment = Enum.TextXAlignment.Right

-- Informasi Sinkronisasi
local syncInfo = makeLabel(body, "SyncInfo", UDim2.new(0, 12, 0, 234), UDim2.new(1, -24, 0, 18), "Kecepatan: 1.00x   •   Offset: +0.00s", 11, Color3.fromRGB(30, 230, 135))
syncInfo.TextXAlignment = Enum.TextXAlignment.Center

-- Kontrol Kecepatan & Offset
local slowerBtn = makeButton(body, "−", UDim2.new(0, 12, 0, 256), UDim2.new(0, 38, 0, 32))
slowerBtn.TextSize = 16
local speedBtn = makeButton(body, "1.00x", UDim2.new(0, 54, 0, 256), UDim2.new(0, 68, 0, 32))
local fasterBtn = makeButton(body, "+", UDim2.new(0, 126, 0, 256), UDim2.new(0, 38, 0, 32))
fasterBtn.TextSize = 16

local offsetBackBtn = makeButton(body, "−0.25s", UDim2.new(0, 172, 0, 256), UDim2.new(0, 74, 0, 32))
local offsetForwardBtn = makeButton(body, "+0.25s", UDim2.new(0, 252, 0, 256), UDim2.new(0, 76, 0, 32))

-- Baris Bawah: Auto Sync, Safe Filter, & Auto-Chat
local resetSyncBtn = makeButton(body, "🔄 SYNC", UDim2.new(0, 12, 0, 296), UDim2.new(0, 92, 0, 32), Color3.fromRGB(52, 62, 74))
local filterBtn = makeButton(body, "🛡 Filter: ON", UDim2.new(0, 110, 0, 296), UDim2.new(0, 102, 0, 32), Color3.fromRGB(30, 145, 90))
local chatBtn = makeButton(body, "💬 Chat: OFF", UDim2.new(0, 218, 0, 296), UDim2.new(0, 110, 0, 32), Color3.fromRGB(39, 45, 51))

local footerHint = makeLabel(body, "Hint", UDim2.new(0, 12, 0, 336), UDim2.new(1, -24, 0, 20), "🎥: Orbit  |  ⚙: Setting Orbit  |  📺: Subtitle  |  🛡: Sensor", 10, Color3.fromRGB(130, 138, 150))

-- ======================== LOGIKA TOMBOL & FITUR ========================

local function resetCameraToNormal()
    local cam = workspace.CurrentCamera
    local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if cam then
        cam.CameraType = Enum.CameraType.Custom
        cam.FieldOfView = savedDefaultFOV
        if hum then cam.CameraSubject = hum end
    end
end

local function updateOrbitButtonVisuals()
    orbitBtn.BackgroundColor3 = isOrbitEnabled and Color3.fromRGB(165, 105, 235) or Color3.fromRGB(39, 45, 55)
    orbitToggleInsideBtn.Text = "Status Orbit: " .. (isOrbitEnabled and "ON (Aktif)" or "OFF (Mati)")
    orbitToggleInsideBtn.BackgroundColor3 = isOrbitEnabled and Color3.fromRGB(135, 75, 205) or Color3.fromRGB(39, 45, 55)
end

local function toggleOrbitState()
    isOrbitEnabled = not isOrbitEnabled
    if isOrbitEnabled then
        local cam = workspace.CurrentCamera
        if cam then savedDefaultFOV = cam.FieldOfView end
    else
        resetCameraToNormal()
    end
    updateOrbitButtonVisuals()
end

-- 0A. Tombol Kamera Drone Orbit (🎥) & Panel Pengaturan Orbit (⚙)
orbitBtn.MouseButton1Click:Connect(toggleOrbitState)
orbitToggleInsideBtn.MouseButton1Click:Connect(toggleOrbitState)

orbitCfgBtn.MouseButton1Click:Connect(function()
    orbitPanel.Visible = not orbitPanel.Visible
    orbitCfgBtn.BackgroundColor3 = orbitPanel.Visible and Color3.fromRGB(165, 105, 235) or Color3.fromRGB(39, 45, 55)
end)

closeOrbitPanelBtn.MouseButton1Click:Connect(function()
    orbitPanel.Visible = false
    orbitCfgBtn.BackgroundColor3 = Color3.fromRGB(39, 45, 55)
end)

-- 0B. Tombol Subtitle HUD Mengambang (📺)
subToggleBtn.MouseButton1Click:Connect(function()
    isSubtitleEnabled = not isSubtitleEnabled
    subtitleFrame.Visible = isSubtitleEnabled
    subToggleBtn.BackgroundColor3 = isSubtitleEnabled and Color3.fromRGB(30, 150, 90) or Color3.fromRGB(39, 45, 55)
end)

-- 1. Tombol Minimize (Mode Compact vs Mode Penuh)
minBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        minBtn.Text = "+"
        body.Visible = false
        miniBar.Visible = true
        TweenService:Create(main, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = MINI_SIZE}):Play()
    else
        minBtn.Text = "—"
        miniBar.Visible = false
        body.Visible = true
        TweenService:Create(main, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = FULL_SIZE}):Play()
    end
end)

-- 2. Tombol Mode Floating Icon (🎵)
pillModeBtn.MouseButton1Click:Connect(function()
    main.Visible = false
    orbitPanel.Visible = false
    orbitCfgBtn.BackgroundColor3 = Color3.fromRGB(39, 45, 55)
    floatBtn.Visible = true
end)

floatBtn.MouseButton1Click:Connect(function()
    floatBtn.Visible = false
    main.Visible = true
end)

-- 3. Tombol Mute Audio Lokal (🔊)
muteBtn.MouseButton1Click:Connect(function()
    isMutedLocally = not isMutedLocally
    muteBtn.Text = isMutedLocally and "🔇" or "🔊"
    muteBtn.BackgroundColor3 = isMutedLocally and Color3.fromRGB(135, 55, 55) or Color3.fromRGB(39, 45, 55)
    if activeSound then
        if isMutedLocally then
            originalVolume = activeSound.Volume > 0 and activeSound.Volume or originalVolume
            activeSound.Volume = 0
        else
            activeSound.Volume = originalVolume
        end
    end
end)

-- 4. Tombol Close (×)
closeBtn.MouseButton1Click:Connect(function()
    if isMutedLocally and activeSound then
        activeSound.Volume = originalVolume
    end
    if isOrbitEnabled then
        isOrbitEnabled = false
        resetCameraToNormal()
    end
    gui:Destroy()
end)

-- 5. Sinkronisasi & Kecepatan Tanpa Batas 2x
local function updateSyncText()
    local modeTag = isAutoRatioActive and " (Auto)" or ""
    syncInfo.Text = string.format("Kecepatan: %.2fx%s   •   Offset: %+.2fs", lyricSpeed, modeTag, syncOffset)
    speedBtn.Text = string.format("%.2fx", lyricSpeed)
    speedBtn.TextColor3 = isAutoRatioActive and Color3.fromRGB(30, 230, 135) or Color3.fromRGB(245, 245, 245)
end

local function applyDurationAutoSync()
    if manualSpeedOverride or not activeItem then return false end
    local origDur = tonumber(activeItem.Duration) or 0
    local rbxDur = (activeSound and activeSound.TimeLength) or 0

    if origDur > 0 and rbxDur > 5 then
        local autoRatio = origDur / rbxDur
        if autoRatio > 1.05 or autoRatio < 0.95 then
            lyricSpeed = math.floor(autoRatio * 100 + 0.5) / 100
            isAutoRatioActive = true
        else
            lyricSpeed = 1.00
            isAutoRatioActive = false
        end
        autoSpeedSynced = true
        updateSyncText()
        return true
    end
    return false
end

makeHoldable(slowerBtn, function()
    manualSpeedOverride = true
    isAutoRatioActive = false
    lyricSpeed = math.max(0.10, math.floor((lyricSpeed - 0.05) * 100 + 0.5) / 100)
    updateSyncText()
end)

makeHoldable(fasterBtn, function()
    manualSpeedOverride = true
    isAutoRatioActive = false
    lyricSpeed = math.floor((lyricSpeed + 0.05) * 100 + 0.5) / 100
    updateSyncText()
end)

speedBtn.MouseButton1Click:Connect(function()
    manualSpeedOverride = true
    isAutoRatioActive = false
    lyricSpeed = 1.00
    updateSyncText()
end)

makeHoldable(offsetBackBtn, function()
    syncOffset = math.floor((syncOffset - 0.25) * 100 + 0.5) / 100
    updateSyncText()
end)

makeHoldable(offsetForwardBtn, function()
    syncOffset = math.floor((syncOffset + 0.25) * 100 + 0.5) / 100
    updateSyncText()
end)

resetSyncBtn.MouseButton1Click:Connect(function()
    manualSpeedOverride = false
    autoSpeedSynced = false
    isAutoRatioActive = false
    lyricSpeed = 1.00
    syncOffset = 0.00
    if not applyDurationAutoSync() then
        updateSyncText()
    end
end)
updateSyncText()

-- Toggle Filter Kata Aman & Auto-Chat
local function updateDisplayedLyric(prevTxt, currTxt, nextTxt)
    local sPrev = sanitizeLyricText(prevTxt or "")
    local sCurr = sanitizeLyricText(currTxt or "")
    local sNext = sanitizeLyricText(nextTxt or "")

    prevLine.Text = sPrev
    currentLine.Text = sCurr
    nextLine.Text = sNext
    miniLyricText.Text = sCurr
    subMainText.Text = sCurr
    subNextText.Text = sNext
end

filterBtn.MouseButton1Click:Connect(function()
    safeFilterEnabled = not safeFilterEnabled
    filterBtn.Text = "🛡 Filter: " .. (safeFilterEnabled and "ON" or "OFF")
    filterBtn.BackgroundColor3 = safeFilterEnabled and Color3.fromRGB(30, 145, 90) or Color3.fromRGB(39, 45, 51)
    if currentIndex > 0 and lyrics[currentIndex] then
        local p = 1
        while lyrics[currentIndex - p] and lyrics[currentIndex - p].Text == "" do p += 1 end
        local n = 1
        while lyrics[currentIndex + n] and lyrics[currentIndex + n].Text == "" do n += 1 end
        updateDisplayedLyric(
            lyrics[currentIndex - p] and lyrics[currentIndex - p].Text or "",
            lyrics[currentIndex].Text ~= "" and lyrics[currentIndex].Text or "♪",
            lyrics[currentIndex + n] and lyrics[currentIndex + n].Text or ""
        )
    end
end)

chatBtn.MouseButton1Click:Connect(function()
    autoChat = not autoChat
    lastSentLine = ""
    chatBtn.Text = "💬 Chat: " .. (autoChat and "ON" or "OFF")
    chatBtn.BackgroundColor3 = autoChat and Color3.fromRGB(30, 145, 90) or Color3.fromRGB(39, 45, 51)
end)

-- ======================== PENCARIAN & HASIL ========================

local resultButtons = {}

local function clearResults()
    for _, child in ipairs(resultsFrame:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    resultButtons = {}
end

local function activateResult(item, selectedBtn)
    activeItem = item
    lyrics = item.Lyrics or {}
    currentIndex = 0
    lastSentLine = ""
    autoSpeedSynced = false
    isAutoRatioActive = false

    for _, btn in ipairs(resultButtons) do
        btn.BackgroundColor3 = (btn == selectedBtn) and Color3.fromRGB(30, 135, 80) or Color3.fromRGB(35, 40, 48)
    end

    if not manualSpeedOverride then
        lyricSpeed = 1.00
        applyDurationAutoSync()
    end
    updateSyncText()

    status.Text = item.Title .. " — " .. item.Artist
    updateDisplayedLyric("", #lyrics > 0 and "♪ Lirik siap, menunggu sinkronisasi..." or "Lirik kosong.", "")
end

local function showResults(items)
    clearResults()
    if #items == 0 then
        status.Text = "Lirik tersinkronisasi tidak ditemukan."
        updateDisplayedLyric("", "Lirik tidak tersedia.", "")
        return
    end
    for i, item in ipairs(items) do
        local durText = item.Duration > 0 and string.format(" (%d:%02d)", math.floor(item.Duration / 60), math.floor(item.Duration % 60)) or ""
        local b = makeButton(resultsFrame, "  " .. item.Title .. " — " .. item.Artist .. durText, UDim2.new(), UDim2.new(1, -6, 0, 28), Color3.fromRGB(35, 40, 48))
        b.LayoutOrder = i
        b.TextXAlignment = Enum.TextXAlignment.Left
        b.TextTruncate = Enum.TextTruncate.AtEnd
        table.insert(resultButtons, b)
        b.MouseButton1Click:Connect(function()
            activateResult(item, b)
        end)
    end
    task.defer(function()
        resultsFrame.CanvasSize = UDim2.new(0, 0, 0, resultLayout.AbsoluteContentSize.Y + 6)
    end)
    activateResult(items[1], resultButtons[1])
end

local searchId = 0
local function doSearch(query, fallbackQueries)
    searchId += 1
    local thisSearch = searchId
    status.Text = "Mencari lirik..."
    clearResults()

    task.spawn(function()
        local queriesToTry = {}
        if query and query ~= "" then
            table.insert(queriesToTry, query)
        end
        if type(fallbackQueries) == "table" then
            for _, q in ipairs(fallbackQueries) do
                if q and q ~= "" and q ~= query then
                    table.insert(queriesToTry, q)
                end
            end
        end

        local finalResults = {}
        local matchedQuery = query or ""

        for _, q in ipairs(queriesToTry) do
            if thisSearch ~= searchId then return end
            local res = searchLyrics(q)
            if #res > 0 then
                finalResults = res
                matchedQuery = q
                break
            end
        end

        if thisSearch ~= searchId then return end
        if matchedQuery ~= "" then
            searchBox.Text = matchedQuery
        end
        showResults(finalResults)
    end)
end

searchBtn.MouseButton1Click:Connect(function()
    doSearch(searchBox.Text, {cleanSongName(searchBox.Text)})
end)
searchBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        doSearch(searchBox.Text, {cleanSongName(searchBox.Text)})
    end
end)

-- ======================== DETEKSI LAGU OTOMATIS ========================

local function getInGameMusicGuiTitle()
    local guiTitle, guiArtist = "", ""
    pcall(function()
        local pGui = player:FindFirstChild("PlayerGui")
        if pGui and pGui:FindFirstChild("MusicGUI") then
            local mName = pGui.MusicGUI:FindFirstChild("MusicName")
            if mName and mName:IsA("TextLabel") then
                guiTitle = mName.Text
                local sArtist = mName:FindFirstChild("ArtistName")
                if sArtist and sArtist:IsA("TextLabel") then
                    guiArtist = sArtist.Text
                end
            end
        end
    end)
    if guiTitle:lower() == "label" or guiTitle:lower() == "text" or guiTitle:lower() == "song_name" then guiTitle = "" end
    if guiArtist:lower() == "label" or guiArtist:lower() == "text" or guiArtist:lower() == "artistname" or guiArtist:lower() == "artist_name" then guiArtist = "" end
    return guiTitle, guiArtist
end

task.spawn(function()
    while gui.Parent do
        local sound = findSound()
        local currentId = sound and sound.SoundId or nil

        if sound and (sound ~= activeSound or currentId ~= activeSoundId) then
            activeSound = sound
            activeSoundId = currentId
            if not isMutedLocally then
                originalVolume = sound.Volume > 0 and sound.Volume or 0.5
            end
            scanToken += 1
            local thisToken = scanToken

            activeItem = nil
            lyrics = {}
            currentIndex = 0
            lastSentLine = ""
            manualSpeedOverride = false
            autoSpeedSynced = false
            isAutoRatioActive = false
            lyricSpeed = 1.00
            syncOffset = 0.00
            updateSyncText()

            progBarFill.Size = UDim2.new(0, 0, 1, 0)
            miniProgFill.Size = UDim2.new(0, 0, 1, 0)
            timeCurrentLbl.Text = "00:00"
            timeTotalLbl.Text = "00:00"

            updateDisplayedLyric("", "Mendeteksi lagu...", "")
            status.Text = "Membaca metadata audio..."

            task.spawn(function()
                task.wait(0.5)
                if scanToken ~= thisToken or not sound or not sound.Parent then return end

                local guiTitle, guiArtist = getInGameMusicGuiTitle()
                local rawName = (sound.Name ~= "Sound" and sound.Name ~= "Hawk909LocalAudio") and sound.Name or ""

                local assetId = tonumber(activeSoundId and activeSoundId:match("%d+"))
                if assetId then
                    local info = safeCall(function()
                        return MarketplaceService:GetProductInfo(assetId, Enum.InfoType.Asset)
                    end)
                    if info and info.Name then
                        rawName = info.Name
                    end
                end

                local cleanedRaw = cleanSongName(rawName)
                local aggressiveRaw = getAggressiveName(rawName)

                local displayQuery = ""
                if guiTitle ~= "" and guiArtist ~= "" then
                    displayQuery = guiTitle .. " " .. guiArtist
                elseif guiTitle ~= "" then
                    displayQuery = guiTitle
                elseif cleanedRaw ~= "" then
                    displayQuery = cleanedRaw
                else
                    displayQuery = rawName
                end

                if displayQuery ~= "" then
                    searchBox.Text = displayQuery
                    doSearch(displayQuery, {
                        guiTitle,
                        cleanedRaw,
                        aggressiveRaw,
                        rawName
                    })
                else
                    searchBox.Text = ""
                    status.Text = "Audio ID: " .. tostring(assetId or "Custom") .. " (Cari manual)"
                    updateDisplayedLyric("", "Judul lagu tidak terdeteksi.", "")
                end
            end)
        elseif not sound and activeSound then
            activeSound = nil
            activeSoundId = nil
            status.Text = "Menunggu musik diputar..."
            progBarFill.Size = UDim2.new(0, 0, 1, 0)
            miniProgFill.Size = UDim2.new(0, 0, 1, 0)
            timeCurrentLbl.Text = "00:00"
            timeTotalLbl.Text = "00:00"
        end
        task.wait(0.8)
    end
end)

-- ======================== EFEK KAMERA DRONE ORBIT KUSTOM (RENDERSTEPPED) ========================
RunService.RenderStepped:Connect(function(dt)
    if not gui.Parent then return end

    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local cam = workspace.CurrentCamera

    if isOrbitEnabled and hrp and hum and cam then
        cam.CameraType = Enum.CameraType.Scriptable
        cam.FieldOfView = cam.FieldOfView + (orbitFOV - cam.FieldOfView) * math.clamp(dt * 10, 0, 1)

        orbitAngle = orbitAngle + (dt * orbitSpeed * orbitDirection)
        local offset = Vector3.new(
            math.cos(orbitAngle) * orbitDistance,
            orbitHeight,
            math.sin(orbitAngle) * orbitDistance
        )
        local orbitPos = hrp.Position + offset
        local lookAtPos = hrp.Position + Vector3.new(0, orbitLookHeight, 0)
        cam.CFrame = CFrame.new(orbitPos, lookAtPos)
        wasOrbitCam = true
    elseif wasOrbitCam then
        wasOrbitCam = false
        resetCameraToNormal()
    end
end)

-- ======================== SINKRONISASI & PROGRESS BAR REAL-TIME ========================
RunService.Heartbeat:Connect(function()
    if not gui.Parent or not activeSound or not activeSound.IsPlaying then return end

    if isMutedLocally then
        activeSound.Volume = 0
    end

    local curTime = activeSound.TimePosition or 0
    local totTime = activeSound.TimeLength or 0
    if totTime <= 0 and activeItem and activeItem.Duration > 0 then
        totTime = activeItem.Duration
    end

    timeCurrentLbl.Text = formatTime(curTime)
    timeTotalLbl.Text = formatTime(totTime)

    local progressRatio = totTime > 0 and math.clamp(curTime / totTime, 0, 1) or 0
    progBarFill.Size = UDim2.new(progressRatio, 0, 1, 0)
    miniProgFill.Size = UDim2.new(progressRatio, 0, 1, 0)

    if activeItem and not autoSpeedSynced and not manualSpeedOverride and activeSound.TimeLength > 5 then
        applyDurationAutoSync()
    end

    if #lyrics == 0 then return end

    local position = (curTime * lyricSpeed) + syncOffset
    local found = 0
    for i, line in ipairs(lyrics) do
        if position >= line.Time then
            found = i
        else
            break
        end
    end

    if found > 0 and found ~= currentIndex then
        currentIndex = found
        local line = lyrics[found]
        local text = line.Text

        local p = 1
        while lyrics[found - p] and lyrics[found - p].Text == "" do p += 1 end
        local n = 1
        while lyrics[found + n] and lyrics[found + n].Text == "" do n += 1 end

        local prevTxt = lyrics[found - p] and lyrics[found - p].Text or ""
        local currTxt = text ~= "" and text or "♪"
        local nextTxt = lyrics[found + n] and lyrics[found + n].Text or ""

        updateDisplayedLyric(prevTxt, currTxt, nextTxt)

        local safeChatText = sanitizeLyricText(text)
        if autoChat and safeChatText ~= "" and safeChatText ~= lastSentLine then
            lastSentLine = safeChatText
            sendChat(safeChatText)
        end
    end
end)

pcall(function()
    StarterGui:SetCore("SendNotification", {
        Title = "Koplingtify Lite",
        Text = "Custom Orbit Cam & Safe Filter siap!",
        Duration = 3
    })
end)

print("Koplingtify Lite (Custom Orbit Settings + Safe Filter) loaded.")
