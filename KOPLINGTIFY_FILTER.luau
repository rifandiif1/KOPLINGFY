-- =================================================================================
-- KOPLINGTIFY LITE v2.5 - MODULAR SAFE WORD FILTER (KOPLINGTIFY_FILTER.luau)
-- =================================================================================
local FilterModule = {}

FilterModule.PhraseReplacements = {
    {"memudar dalam remang sunyi", "meredup dalam teduh hening"},
    {"dalam remang sunyi", "dalam teduh hening"},
    {"memudar dalam remang", "meredup dalam teduh"},
    {"remang-remang", "redup"},
    {"memiliki dirimu", "mengarungi waktumu"},
    {"memiliki kamu", "menemani kamu"},
    {"memiliki hatimu", "menjaga hatimu"},
    {"miliki dirimu", "temani langkahmu"},
    {"utuh milikku", "utuh untukku"},
    {"jadi milikku", "jadi temanku"},
    {"menjadi milikku", "menjadi bagianku"},
    {"seutuhnya milikmu", "seutuhnya untukmu"},
    {"shut the fuck up", "keep it quiet"},
    {"what the fuck", "what the heck"},
    {"what the hell", "what the heck"},
    {"piece of shit", "piece of junk"},
    {"son of a bitch", "rascal"},
    {"kill yourself", "take care"},
    {"killing myself", "losing myself"},
    {"want to die", "want to fly"},
    {"wanna die", "wanna fly"},
    {"gonna die", "gonna fly"},
    {"make love", "hold hands"},
    {"one night stand", "late night dance"},
    {"bunuh diri", "menyerah"},
    {"kurang ajar", "nakal sekali"},
    {"anak haram", "anak jalanan"},
    {"anak pungut", "anak rantau"},
    {"tidur denganmu", "duduk denganmu"},
    {"tidur bersamamu", "duduk bersamamu"},
    {"di atas ranjang", "di atas awan"},
    {"di dalam kamar", "di dalam ruang"},
    {"jatuh cinta", "jatuh hati"},
    {"putus cinta", "patah hati"},
    {"malam pertama", "malam indah"},
    {"peluk erat", "genggam erat"},
    {"cium kening", "sapa hangat"},
    {"cium pipi", "sapa manis"},
    {"buka baju", "lepas jaket"},
    {"ganti baju", "ganti gaya"},
    {"nomor hp", "kode frekuensi"},
    {"nomor telepon", "kode frekuensi"},
    {"berapa umurmu", "apa kabarmu"},
    {"sleep with me", "stay with me"},
    {"sleeping with", "staying with"},
    {"in my bed", "in my head"},
    {"on the bed", "on the floor"},
    {"in the bedroom", "in the room"},
    {"kiss me", "miss me"},
    {"kissing you", "missing you"},
    {"kissed you", "missed you"},
    {"hold my hand", "stand by me"},
    {"touch my body", "feel the rhythm"},
    {"touch your body", "feel the music"},
    {"take off your", "put on your"},
    {"fall in love", "fall apart"},
    {"be my girlfriend", "be my friend"},
    {"be my boyfriend", "be my friend"},
    {"phone number", "lucky charm"},
    {"how old are you", "how are you"}
}

FilterModule.WordReplacements = {
    ["memnudar"] = "meredup", ["memudar"] = "meredup", ["pudar"] = "redup",
    ["remang"] = "teduh", ["sunyi"] = "hening", ["sepi"] = "tenang",
    ["kesepian"] = "sendirian", ["gelap"] = "malam", ["kegelapan"] = "malam",
    ["hampa"] = "kosong", ["kelam"] = "sendu", ["lara"] = "duka", ["pilu"] = "sendu",
    ["memiliki"] = "mendapati", ["memilikimu"] = "menemanimu", ["miliki"] = "dapati",
    ["milikku"] = "bagianku", ["milikmu"] = "bagianmu", ["dirimu"] = "sosokmu", ["diriku"] = "sosokku",
    ["motherfucker"] = "troublemaker", ["motherfuckers"] = "troublemakers",
    ["motherfuckin"] = "freakin", ["motherfucking"] = "freaking",
    ["muthafucka"] = "troublemaker", ["muthafuckin"] = "freakin",
    ["mf"] = "pal", ["fucking"] = "freaking", ["fuckin"] = "freakin",
    ["fckin"] = "freakin", ["fcking"] = "freaking", ["fucked"] = "messed",
    ["fucker"] = "joker", ["fuckers"] = "jokers", ["fuck"] = "freak",
    ["fucks"] = "cares", ["fck"] = "freak", ["fuk"] = "freak", ["fuq"] = "freak",
    ["wtf"] = "what", ["stfu"] = "shh", ["shitting"] = "kidding",
    ["shitty"] = "messy", ["bullshit"] = "nonsense", ["horseshit"] = "nonsense",
    ["dipshit"] = "goofball", ["shithead"] = "airhead", ["shits"] = "shoots",
    ["shit"] = "shoot", ["sht"] = "shoot", ["bitching"] = "complaining",
    ["bitches"] = "witches", ["bitchy"] = "sassy", ["bitch"] = "witch",
    ["btch"] = "witch", ["biatch"] = "witch", ["assholes"] = "rascals",
    ["asshole"] = "rascal", ["dumbass"] = "silly", ["jackass"] = "clown",
    ["badass"] = "cool", ["fatass"] = "heavy", ["asses"] = "butts",
    ["ass"] = "butt", ["arse"] = "butt", ["bastards"] = "rascals",
    ["bastard"] = "rascal", ["dammit"] = "darnit", ["damned"] = "darned",
    ["damn"] = "darn", ["goddammit"] = "goshdarn", ["goddamn"] = "goshdarn",
    ["hella"] = "super", ["hell"] = "heck", ["cunts"] = "jerks", ["cunt"] = "jerk",
    ["dicks"] = "jerks", ["dickhead"] = "blockhead", ["dick"] = "jerk",
    ["cocks"] = "roosters", ["cock"] = "rooster", ["pussies"] = "kitties",
    ["pussy"] = "kitty", ["twat"] = "fool", ["prick"] = "thorn",
    ["wanker"] = "joker", ["bollocks"] = "nonsense", ["bugger"] = "rascal",
    ["douchebag"] = "showoff", ["douche"] = "showoff", ["scumbag"] = "villain",
    ["slutty"] = "flirty", ["sluts"] = "heartbreakers", ["slut"] = "heartbreaker",
    ["whores"] = "players", ["whore"] = "player", ["hoe"] = "player",
    ["hoes"] = "players", ["skank"] = "meanie", ["prostitute"] = "dancer",
    ["stripper"] = "dancer", ["hooker"] = "dancer", ["pimp"] = "boss",
    ["nigga"] = "homie", ["niggas"] = "homies", ["niggaz"] = "homies",
    ["nigger"] = "brother", ["niggers"] = "brothers", ["nibba"] = "homie",
    ["negro"] = "fellow", ["faggot"] = "fool", ["faggots"] = "fools",
    ["fag"] = "fool", ["fags"] = "fools", ["dyke"] = "rebel",
    ["tranny"] = "person", ["retard"] = "silly", ["retards"] = "goofballs",
    ["retarded"] = "foolish", ["cripple"] = "broken", ["spastic"] = "frantic",
    ["suicidal"] = "hopeless", ["suicide"] = "give up", ["kms"] = "sigh", ["kys"] = "bye",
    ["killing"] = "chilling", ["killed"] = "chilled", ["killer"] = "hunter",
    ["kills"] = "chills", ["kill"] = "chill", ["murderer"] = "stranger",
    ["murdered"] = "vanished", ["murdering"] = "chasing", ["murder"] = "mystery",
    ["homicide"] = "incident", ["genocide"] = "wipeout", ["massacre"] = "chaos",
    ["slaughter"] = "defeat", ["butcher"] = "fighter", ["dying"] = "fading",
    ["died"] = "faded", ["dies"] = "fades", ["die"] = "fly", ["dead"] = "gone",
    ["death"] = "sleep", ["corpse"] = "statue", ["coffin"] = "box", ["grave"] = "ground",
    ["bleeding"] = "crying", ["bleed"] = "cry", ["bloody"] = "messy", ["blood"] = "sweat",
    ["gore"] = "mess", ["stabbed"] = "poked", ["stabbing"] = "poking", ["stab"] = "poke",
    ["slit"] = "cut", ["choke"] = "gasp", ["choking"] = "gasping", ["strangle"] = "grab",
    ["hang"] = "hold", ["hanged"] = "held", ["shoot"] = "blast", ["shooting"] = "blasting",
    ["shotgun"] = "blaster", ["gunshot"] = "thunder", ["guns"] = "blasters", ["gun"] = "blaster",
    ["pistol"] = "blaster", ["rifle"] = "blaster", ["glock"] = "blaster", ["ak47"] = "blaster",
    ["bullets"] = "sparks", ["bullet"] = "spark", ["trigger"] = "switch", ["bomb"] = "boom",
    ["terrorist"] = "villain", ["terrorism"] = "chaos", ["hostage"] = "captive",
    ["torture"] = "trouble", ["abuse"] = "mistreat", ["violent"] = "wild", ["violence"] = "chaos",
    ["sexual"] = "romantic", ["sexually"] = "deeply", ["sex"] = "love",
    ["sexy"] = "lovely", ["sexiest"] = "loveliest", ["porn"] = "movie",
    ["porno"] = "movie", ["hentai"] = "anime", ["nsfw"] = "secret",
    ["nude"] = "bare", ["nudes"] = "photos", ["naked"] = "bare",
    ["horny"] = "lonely", ["orgasm"] = "climax", ["climax"] = "peak",
    ["cum"] = "come", ["cumming"] = "coming", ["sperm"] = "seed",
    ["erection"] = "rising", ["boner"] = "spark", ["boobs"] = "chest",
    ["boob"] = "chest", ["titties"] = "chest", ["tits"] = "chest", ["tit"] = "chest",
    ["nipples"] = "buttons", ["nipple"] = "button", ["booty"] = "hips",
    ["thighs"] = "legs", ["virgin"] = "innocent", ["virginity"] = "innocence",
    ["lust"] = "desire", ["fetish"] = "habit", ["kinky"] = "quirky", ["bdsm"] = "chains",
    ["rape"] = "hurt", ["raped"] = "hurt", ["rapist"] = "villain", ["molest"] = "bother",
    ["pedophile"] = "creep", ["pedo"] = "creep", ["incest"] = "kin",
    ["drugs"] = "sweets", ["drug"] = "candy", ["weed"] = "herb", ["marijuana"] = "herbs",
    ["cannabis"] = "herbs", ["blunt"] = "stick", ["joint"] = "roll", ["stoned"] = "sleepy",
    ["cocaine"] = "powder", ["coke"] = "soda", ["heroin"] = "potion", ["meth"] = "crystal",
    ["ecstasy"] = "joy", ["molly"] = "candy", ["lsd"] = "dream", ["acid"] = "lemon",
    ["pills"] = "mints", ["pill"] = "mint", ["overdose"] = "overload", ["addict"] = "fan",
    ["addicted"] = "hooked", ["nicotine"] = "caffeine", ["cigarette"] = "candle",
    ["cigarettes"] = "candles", ["vape"] = "mist", ["smoking"] = "glowing",
    ["smoke"] = "cloud", ["drunk"] = "dizzy", ["wasted"] = "tired", ["tipsy"] = "giggly",
    ["alcohol"] = "soda", ["liquor"] = "juice", ["whiskey"] = "tea", ["vodka"] = "water",
    ["tequila"] = "lemonade", ["beer"] = "rootbeer", ["wine"] = "grape",
    ["champagne"] = "sparkling", ["bartender"] = "barista",
    ["kiss"] = "greet", ["kisses"] = "smiles", ["kissing"] = "smiling", ["kissed"] = "smiled",
    ["hug"] = "hold", ["hugs"] = "holds", ["hugging"] = "holding", ["hugged"] = "held",
    ["cuddle"] = "huddle", ["cuddling"] = "huddling", ["caress"] = "breeze",
    ["touch"] = "reach", ["touches"] = "reaches", ["touching"] = "reaching", ["touched"] = "reached",
    ["lips"] = "smile", ["lip"] = "smile", ["tongue"] = "voice", ["neck"] = "shoulder",
    ["chest"] = "heart", ["waist"] = "side", ["hips"] = "steps", ["hip"] = "step",
    ["thigh"] = "leg", ["skin"] = "glow", ["body"] = "soul", ["bodies"] = "souls",
    ["sweat"] = "rain", ["sweating"] = "shining", ["breath"] = "wind", ["breathe"] = "sigh",
    ["breathing"] = "sighing", ["moan"] = "sigh", ["moaning"] = "sighing", ["whisper"] = "echo",
    ["undress"] = "unwind", ["clothes"] = "outfit", ["shirt"] = "jacket", ["pants"] = "shoes",
    ["skirt"] = "dress", ["underwear"] = "gear", ["bra"] = "top", ["panties"] = "gear",
    ["bikini"] = "swimsuit", ["bed"] = "cloud", ["bedroom"] = "room", ["sheets"] = "clouds",
    ["pillow"] = "cushion", ["blanket"] = "cover", ["shower"] = "rain", ["hotel"] = "tower",
    ["motel"] = "tower", ["boyfriend"] = "partner", ["girlfriend"] = "partner",
    ["lover"] = "dreamer", ["lovers"] = "dreamers", ["dating"] = "hanging", ["date"] = "meet",
    ["marry"] = "promise", ["married"] = "promised", ["wedding"] = "party",
    ["husband"] = "partner", ["wife"] = "partner", ["bride"] = "star", ["groom"] = "star",
    ["babe"] = "star", ["baby"] = "darling", ["honey"] = "sweetie", ["sugar"] = "sweet",
    ["shawty"] = "shorty", ["shorty"] = "friend", ["daddy"] = "boss", ["mommy"] = "queen",
    ["crush"] = "spark", ["flirt"] = "tease", ["flirting"] = "joking", ["seduce"] = "charm",
    ["jealous"] = "envious", ["cheating"] = "lying", ["cheat"] = "trick", ["ex"] = "past",
    ["anjing"] = "kucing", ["anjir"] = "astaga", ["anjay"] = "keren", ["anjrit"] = "waduh",
    ["anjrot"] = "waduh", ["anying"] = "kucing", ["njir"] = "wah", ["njay"] = "keren",
    ["asu"] = "kucing", ["babi"] = "kelinci", ["celeng"] = "kelinci", ["monyet"] = "kera",
    ["kunyuk"] = "kera", ["kampret"] = "kelelawar", ["bangsat"] = "nakal", ["bgst"] = "nakal",
    ["brengsek"] = "bandel", ["bajingan"] = "penjahat", ["keparat"] = "nakal", ["bedebah"] = "bandel",
    ["kurangajar"] = "nakal", ["sialan"] = "aduhai", ["sial"] = "malang", ["bangke"] = "ranting",
    ["bangkai"] = "ranting", ["tai"] = "debu", ["tahi"] = "debu", ["taik"] = "debu",
    ["berak"] = "pergi", ["kentut"] = "angin", ["kencing"] = "air", ["bacot"] = "bicara",
    ["bct"] = "bicara", ["cocot"] = "mulut", ["congor"] = "mulut", ["nyinyir"] = "cerewet",
    ["mampus"] = "habis", ["modar"] = "habis", ["kojor"] = "lemas", ["matek"] = "lemas",
    ["setan"] = "bayangan", ["syaiton"] = "bayangan", ["iblis"] = "bayangan", ["dajjal"] = "raksasa",
    ["neraka"] = "lembah", ["jahanam"] = "gelap", ["laknat"] = "buruk", ["terkutuk"] = "terlupakan",
    ["haram"] = "terlarang", ["dosa"] = "salah", ["berdosa"] = "bersalah", ["kafir"] = "asing",
    ["goblok"] = "polos", ["goblog"] = "polos", ["gblk"] = "polos", ["tolol"] = "lucu",
    ["tll"] = "lucu", ["bodoh"] = "polos", ["bego"] = "lugu", ["begok"] = "lugu",
    ["oon"] = "lugu", ["bloon"] = "lugu", ["dungu"] = "polos", ["idiot"] = "unik",
    ["autis"] = "fokus", ["cacat"] = "kurang", ["gila"] = "heboh", ["sinting"] = "heboh",
    ["sarap"] = "heboh", ["edan"] = "heboh", ["stres"] = "pusing", ["depresi"] = "sedih",
    ["frustrasi"] = "kecewa", ["budek"] = "kurang dengar", ["buta"] = "gelap", ["bisu"] = "diam",
    ["pincang"] = "pelan", ["gendut"] = "gemoy", ["gembrot"] = "gemoy", ["ceking"] = "ramping",
    ["jelek"] = "biasa", ["burik"] = "pudar", ["dekil"] = "lusuh", ["miskin"] = "sederhana",
    ["melarat"] = "sederhana", ["gembel"] = "pengembara", ["pengemis"] = "pencari",
    ["sampah"] = "dedaunan", ["pecundang"] = "pemula", ["cupu"] = "pemula", ["noob"] = "pemula",
    ["jancok"] = "astaga", ["jancuk"] = "astaga", ["dancok"] = "astaga", ["cuk"] = "kawan",
    ["cok"] = "kawan", ["jangkrik"] = "belalang", ["matamu"] = "matanya", ["ndasmu"] = "kepalamu",
    ["lambemu"] = "ucapanmu", ["raimu"] = "wajahmu", ["pantek"] = "waduh", ["kimak"] = "astaga",
    ["pukimak"] = "astaga", ["puki"] = "kucing", ["sundal"] = "nakal",
    ["kontol"] = "konyol", ["kntl"] = "konyol", ["memek"] = "bebek", ["mmk"] = "bebek",
    ["pepek"] = "bebek", ["jembut"] = "rambut", ["jmbt"] = "rambut", ["itil"] = "kecil",
    ["pentil"] = "ujung", ["tetek"] = "dada", ["tete"] = "dada", ["toket"] = "dada",
    ["payudara"] = "hati", ["buahdada"] = "hati", ["pantat"] = "belakang", ["bokong"] = "belakang",
    ["bool"] = "belakang", ["selangkangan"] = "pinggang", ["kelamin"] = "raga", ["zakar"] = "raga",
    ["vagina"] = "bunga", ["penis"] = "batang", ["ngentot"] = "joget", ["entot"] = "joget",
    ["ngewe"] = "joget", ["ewe"] = "joget", ["kenthu"] = "joget", ["kimpoi"] = "menikah",
    ["kawin"] = "menikah", ["peju"] = "keju", ["mani"] = "embun", ["sperma"] = "benih",
    ["coli"] = "sendiri", ["onani"] = "sendiri", ["masturbasi"] = "melamun",
    ["desah"] = "napas", ["mendesah"] = "bernapas", ["sange"] = "rindu", ["horni"] = "rindu",
    ["nafsu"] = "hasrat", ["birahi"] = "hasrat", ["gairah"] = "semangat", ["syahwat"] = "perasaan",
    ["perawan"] = "gadis", ["keperawanan"] = "kesucian", ["perjaka"] = "jejaka",
    ["pelacur"] = "penari", ["lonte"] = "bunga", ["psk"] = "pekerja", ["jablay"] = "santai",
    ["bispak"] = "santai", ["openbo"] = "jalan", ["michat"] = "pesan", ["mucikari"] = "perantara",
    ["germo"] = "perantara", ["simpanan"] = "rahasia", ["selingkuh"] = "mendua",
    ["selingkuhan"] = "bayangan", ["pelakor"] = "penggoda", ["pebinor"] = "penggoda",
    ["telanjang"] = "polos", ["bugil"] = "polos", ["seksi"] = "anggun", ["montok"] = "indah",
    ["bohay"] = "indah", ["semok"] = "indah", ["bercinta"] = "berdansa", ["seks"] = "cinta",
    ["seksual"] = "romantis", ["bokep"] = "film", ["mesum"] = "nakal", ["cabul"] = "nakal",
    ["perkosa"] = "lukai", ["memperkosa"] = "melukai", ["pemerkosaan"] = "kejahatan",
    ["pelecehan"] = "gangguan", ["mati"] = "pergi", ["matilah"] = "pergilah",
    ["kematian"] = "kepergian", ["meninggal"] = "berpulang", ["tewas"] = "gugur",
    ["bunuh"] = "kejar", ["membunuh"] = "mengejar", ["pembunuh"] = "pemburu",
    ["pembunuhan"] = "perburuan", ["bantai"] = "kalahkan", ["membantai"] = "mengalahkan",
    ["cekik"] = "pegang", ["mencekik"] = "memegang", ["tikam"] = "sentuh", ["menikam"] = "menyentuh",
    ["tusuk"] = "sentuh", ["menusuk"] = "menyentuh", ["bacok"] = "tebas", ["membacok"] = "menebas",
    ["penggal"] = "potong", ["gantung"] = "ayun", ["darah"] = "merah", ["berdarah"] = "terluka",
    ["mayat"] = "patung", ["jenazah"] = "raga", ["kuburan"] = "taman", ["makam"] = "taman",
    ["pisau"] = "pedang", ["belati"] = "pedang", ["golok"] = "pedang", ["celurit"] = "sabit",
    ["senjata"] = "alat", ["peluru"] = "cahaya", ["tembak"] = "bidik", ["menembak"] = "membidik",
    ["racun"] = "ramuan", ["beracun"] = "berbahaya", ["meracuni"] = "mengganggu",
    ["mabuk"] = "pusing", ["mabok"] = "pusing", ["teler"] = "lelah", ["miras"] = "sirup",
    ["alkohol"] = "soda", ["bir"] = "soda", ["anggur"] = "jus", ["tuak"] = "air",
    ["ciu"] = "air", ["amer"] = "sirup", ["intisar"] = "sirup", ["narkoba"] = "permen",
    ["narkotika"] = "permen", ["ganja"] = "daun", ["sabu"] = "kristal", ["ekstasi"] = "permen",
    ["heroin"] = "bubuk", ["kokain"] = "bubuk", ["pil"] = "permen", ["obat"] = "jamu",
    ["rokok"] = "asap", ["merokok"] = "berasap", ["judi"] = "main", ["berjudi"] = "bermain",
    ["bandar"] = "penjaga", ["slot"] = "mesin", ["maling"] = "pencari", ["pencuri"] = "pengambil",
    ["merampok"] = "mengambil", ["korupsi"] = "curang", ["penjara"] = "istana",
    ["peluk"] = "rengkuh", ["memeluk"] = "merengkuh", ["memelukmu"] = "merengkuhmu",
    ["pelukan"] = "rengkuhan", ["pelukanmu"] = "rengkuhanmu", ["dipeluk"] = "direngkuh",
    ["dekap"] = "jaga", ["mendekap"] = "menjaga", ["dekapan"] = "naungan",
    ["rangkul"] = "gandeng", ["merangkul"] = "menggandeng", ["cium"] = "sapa",
    ["mencium"] = "menyapa", ["menciummu"] = "menyapamu", ["ciuman"] = "sapaan",
    ["dicium"] = "disapa", ["kecup"] = "sapa", ["mengecup"] = "menyapa", ["kecupan"] = "sapaan",
    ["belai"] = "usap", ["membelai"] = "mengusap", ["belaian"] = "usapan",
    ["sentuh"] = "raih", ["menyentuh"] = "meraih", ["menyentuhmu"] = "meraihmu",
    ["sentuhan"] = "raihan", ["tersentuh"] = "tergugah", ["raba"] = "cari", ["meraba"] = "mencari",
    ["pangku"] = "damping", ["memangku"] = "mendampingi", ["pangkuan"] = "sisi",
    ["gandeng"] = "iring", ["menggandeng"] = "mengiringi", ["elus"] = "usap", ["mengelus"] = "mengusap",
    ["pacar"] = "rekan", ["pacarku"] = "rekanku", ["pacarmu"] = "rekanmu",
    ["pacaran"] = "berteman", ["berpacaran"] = "berteman", ["kekasih"] = "pujaan",
    ["kekasihku"] = "pujaanku", ["kekasihmu"] = "pujaanmu", ["sayang"] = "kasih",
    ["sayangku"] = "kasihku", ["sayangi"] = "kasihi", ["menyayangi"] = "mengasihi",
    ["kesayangan"] = "kebanggaan", ["cinta"] = "asa", ["cintaku"] = "asaku", ["cintamu"] = "asamu",
    ["mencintai"] = "mengagumi", ["mencintaimu"] = "mengagumimu", ["dicintai"] = "dikagumi",
    ["percintaan"] = "perjalanan", ["asmara"] = "irama", ["kasmaran"] = "bahagia",
    ["romantis"] = "manis", ["mesra"] = "akrab", ["kemesraan"] = "keakraban",
    ["bermesraan"] = "bercanda", ["kencan"] = "jalan", ["berkencan"] = "berjalan",
    ["jadian"] = "bersama", ["gebetan"] = "idola", ["mantan"] = "kenangan",
    ["mantanku"] = "masa laluku", ["nikah"] = "janji", ["menikah"] = "berjanji",
    ["menikahimu"] = "menemanimu", ["pernikahan"] = "ikatan", ["pengantin"] = "pasangan",
    ["suami"] = "pendamping", ["suamiku"] = "pendampingku", ["istri"] = "pendamping",
    ["istriku"] = "pendampingku", ["jodoh"] = "takdir", ["rayu"] = "bujuk",
    ["merayu"] = "membujuk", ["rayuan"] = "pujian", ["goda"] = "canda",
    ["menggoda"] = "bercanda", ["godaan"] = "candaan", ["bibir"] = "senyum",
    ["bibirmu"] = "senyummu", ["bibirku"] = "senyumku", ["lidah"] = "ucap",
    ["leher"] = "bahu", ["lehermu"] = "bahumu", ["dada"] = "hati", ["dadamu"] = "hatimu",
    ["dadaku"] = "hatiku", ["perut"] = "raga", ["pinggang"] = "sisi", ["pinggul"] = "langkah",
    ["paha"] = "kaki", ["kulit"] = "rona", ["kulitmu"] = "ronamu", ["tubuh"] = "raga",
    ["tubuhmu"] = "ragamu", ["tubuhku"] = "ragaku", ["badan"] = "raga", ["badanmu"] = "ragamu",
    ["badanku"] = "ragaku", ["keringat"] = "peluh", ["berkeringat"] = "berpeluh",
    ["desahan"] = "hembusan", ["napas"] = "hembus", ["napasmu"] = "hembusanmu",
    ["baju"] = "jubah", ["bajumu"] = "jubahmu", ["celana"] = "pakaian", ["rok"] = "gaun",
    ["pakaian"] = "busana", ["handuk"] = "kain", ["kamar"] = "ruang", ["kamarmu"] = "ruangmu",
    ["kamarku"] = "ruangku", ["ranjang"] = "peraduan", ["kasur"] = "alas",
    ["bantal"] = "sandaran", ["selimut"] = "penghangat", ["guling"] = "sandaran",
    ["tidur"] = "lelap", ["tidurlah"] = "lelaplah", ["meniduri"] = "menemani",
    ["ketiduran"] = "terlelap", ["mandi"] = "basuh", ["hotel"] = "gedung",
    ["penginapan"] = "singgahan", ["kos"] = "tempat", ["kosan"] = "tempat",
    ["umur"] = "waktu", ["umurmu"] = "waktumu", ["umurku"] = "waktuku", ["usia"] = "masa",
    ["alamat"] = "arah", ["nomor"] = "angka", ["telepon"] = "suara", ["hp"] = "layar",
    ["handphone"] = "layar", ["wa"] = "pesan", ["ig"] = "galeri", ["fb"] = "halaman",
    ["tt"] = "video", ["uang"] = "koin", ["duit"] = "koin", ["bayar"] = "tukar",
    ["membayar"] = "menukar", ["jual"] = "beri", ["beli"] = "ambil", ["harga"] = "nilai",
    ["murahan"] = "sederhana",
    ["discord"] = "radio", ["tiktok"] = "clock", ["instagram"] = "camera",
    ["whatsapp"] = "phone", ["telegram"] = "letter", ["youtube"] = "video",
    ["twitter"] = "bird", ["facebook"] = "book", ["snapchat"] = "ghost",
    ["tinder"] = "flame", ["onlyfans"] = "fanclub", ["spotify"] = "music"
}

local function matchCase(original, replacement)
    if replacement == "" then return "" end
    if original == original:upper() and #original > 1 then
        return replacement:upper()
    elseif original:sub(1, 1) == original:sub(1, 1):upper() then
        return replacement:sub(1, 1):upper() .. replacement:sub(2)
    end
    return replacement
end

function FilterModule.Sanitize(text, enabled)
    if not text or text == "" or enabled == false then return text end
    local cleaned = text
    local phrases = FilterModule.PhraseReplacements
    local words = FilterModule.WordReplacements

    for _, pair in ipairs(phrases) do
        local badPhrase, goodPhrase = pair[1], pair[2]
        local pattern = badPhrase:gsub("(%a)", function(c)
            return string.format("[%s%s]", c:lower(), c:upper())
        end)
        cleaned = cleaned:gsub(pattern, goodPhrase)
    end

    cleaned = cleaned:gsub("([%a'*%-]+)", function(word)
        local lowerWord = word:lower()
        if lowerWord:find("%*") then
            if lowerWord:match("^f.*k$") then return matchCase(word, "freak") end
            if lowerWord:match("^s.*t$") then return matchCase(word, "shoot") end
            if lowerWord:match("^b.*h$") then return matchCase(word, "witch") end
            if lowerWord:match("^n.*a$") or lowerWord:match("^n.*r$") then return matchCase(word, "homie") end
            if lowerWord:match("^c.*t$") then return matchCase(word, "jerk") end
            if lowerWord:match("^d.*k$") then return matchCase(word, "jerk") end
            return word:gsub("%*", "")
        end

        if words[lowerWord] then
            return matchCase(word, words[lowerWord])
        end

        local stripped = lowerWord:gsub("'", "")
        if words[stripped] then
            return matchCase(word, words[stripped])
        end

        if lowerWord:find("%-") then
            local parts = string.split(word, "-")
            for i, p in ipairs(parts) do
                local lp = p:lower():gsub("'", "")
                if words[lp] then
                    parts[i] = matchCase(p, words[lp])
                end
            end
            return table.concat(parts, "-")
        end

        local root, suffix = stripped:match("^([%a]+)(nya)$")
        if not root then root, suffix = stripped:match("^([%a]+)(mu)$") end
        if not root then root, suffix = stripped:match("^([%a]+)(ku)$") end
        if not root then root, suffix = stripped:match("^([%a]+)(lah)$") end
        if root and words[root] then
            return matchCase(word, words[root] .. suffix)
        end

        return word
    end)

    cleaned = cleaned:gsub("(%d)(%d)", "%1 %2"):gsub("(%d)(%d)", "%1 %2")
    return cleaned
end

return FilterModule
