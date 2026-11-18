-- =================================================================================
-- KOPLINGTIFY LITE v2.5 - ANTI-DEACCENT & CONTEXT BREAKER (KOPLINGTIFY_FILTER.luau)
-- =================================================================================
local FilterModule = {}

-- Pilihan Mode Bypass (100% Huruf A-Z Murni, kebal De-Accenter & Punctuation Stripper Roblox):
-- 1 = Double-Vowel / Soft-Insert (Contoh: "tubuuhmu", "tiduur", "kubayangkaan", "fuvck") -> PALING AMAN & JELAS
-- 2 = Visual Leetspeak (Contoh: "tvbvhmu", "tIdvr", "fvck", "shIt")
-- 3 = Syllable Space Split (Contoh: "tu buhmu", "ti dur", "ku bayangkan", "fu ck")
FilterModule.BypassMode = 1

-- Kamus Spesifik Kata Tier-1 & Kata Pemicu Konteks (Mode 1, Mode 2, Mode 3)
local directBypassMap = {
    -- Kata Pemicu Konteks Lirik Indonesia (Yang bikin kalimat kena sensor)
    ["bayang"]        = {"bayangin", "b4yang", "ba yang"},
    ["bayangkan"]     = {"bayangkaan", "b4yangkan", "ba yangkan"},
    ["kubayangkan"]   = {"kubayangkaan", "kub4yangkan", "ku bayangkan"},
    ["membayangkan"]  = {"membayangkaan", "memb4yangkan", "mem bayangkan"},
    ["terbayang"]     = {"terbayaang", "terb4yang", "ter bayang"},
    ["bayanganmu"]    = {"bayangaanmu", "b4yanganmu", "ba yanganmu"},
    ["tubuh"]         = {"tubuuh", "tvbuh", "tu buh"},
    ["tubuhmu"]       = {"tubuuhmu", "tvbuhmu", "tu buhmu"},
    ["tubuhku"]       = {"tubuuhku", "tvbuhku", "tu buhku"},
    ["badan"]         = {"badaan", "b4dan", "ba dan"},
    ["badanmu"]       = {"badaanmu", "b4danmu", "ba danmu"},
    ["badanku"]       = {"badaanku", "b4danku", "ba danku"},
    ["raga"]          = {"ragaa", "r4ga", "ra ga"},
    ["ragamu"]        = {"ragaamu", "r4gamu", "ra gamu"},
    ["tidur"]         = {"tiduur", "tIdur", "ti dur"},
    ["tidurlah"]      = {"tiduurlah", "tIdurlah", "ti durlah"},
    ["meniduri"]      = {"meniduuri", "menIduri", "me niduri"},
    ["kutiduri"]      = {"kutiduuri", "kutIduri", "ku tiduri"},
    ["ketiduran"]     = {"ketiduuran", "ketIduran", "ke tiduran"},
    ["sekasur"]       = {"sekaasur", "sek4sur", "se kasur"},
    ["seranjang"]     = {"seranjaang", "ser4njang", "se ranjang"},
    ["ranjang"]       = {"ranjaang", "r4njang", "ran jang"},
    ["kasur"]         = {"kasuur", "k4sur", "ka sur"},
    ["kamar"]         = {"kamaar", "k4mar", "ka mar"},
    ["kamarmu"]       = {"kamaarmu", "k4marmu", "ka marmu"},
    ["kamarku"]       = {"kamaarku", "k4marku", "ka marku"},
    ["peluk"]         = {"peluuk", "p3luk", "pe luk"},
    ["memeluk"]       = {"memeluuk", "mem3luk", "me meluk"},
    ["memelukmu"]     = {"memeluukmu", "mem3lukmu", "me melukmu"},
    ["kupeluk"]       = {"kupeluuk", "kup3luk", "ku peluk"},
    ["pelukan"]       = {"peluukan", "p3lukan", "pe lukan"},
    ["pelukanmu"]     = {"peluukanmu", "p3lukanmu", "pe lukanmu"},
    ["cium"]          = {"ciuum", "cIum", "ci um"},
    ["mencium"]       = {"menciuum", "mencIum", "men cium"},
    ["menciummu"]     = {"menciuummu", "mencIummu", "men ciummu"},
    ["kucium"]        = {"kuciuum", "kucIum", "ku cium"},
    ["ciuman"]        = {"ciuuman", "cIuman", "ci uman"},
    ["kecup"]         = {"kecuup", "k3cup", "ke cup"},
    ["mengecup"]      = {"mengecuup", "meng3cup", "me ngecup"},
    ["sentuh"]        = {"sentuuh", "s3ntuh", "sen tuh"},
    ["menyentuh"]     = {"menyentuuh", "meny3ntuh", "me nyentuh"},
    ["menyentuhmu"]   = {"menyentuuhmu", "meny3ntuhmu", "me nyentuhmu"},
    ["kusentuh"]      = {"kusentuuh", "kus3ntuh", "ku sentuh"},
    ["sentuhan"]      = {"sentuuhan", "s3ntuhan", "sen tuhan"},
    ["belai"]         = {"belaai", "b3lai", "be lai"},
    ["membelai"]      = {"membelaai", "memb3lai", "mem belai"},
    ["raba"]          = {"rabaa", "r4ba", "ra ba"},
    ["meraba"]        = {"merabaa", "mer4ba", "me raba"},
    ["pangku"]        = {"pangkuu", "p4ngku", "pang ku"},
    ["memangku"]      = {"memangkuu", "mem4ngku", "me mangku"},
    ["bibir"]         = {"bibiir", "bIbir", "bi bir"},
    ["bibirmu"]       = {"bibiirmu", "bIbirmu", "bi birmu"},
    ["bibirku"]       = {"bibiirku", "bIbirku", "bi birku"},
    ["lidah"]         = {"lidaah", "lIdah", "li dah"},
    ["leher"]         = {"leheer", "l3her", "le her"},
    ["lehermu"]       = {"leheermu", "l3hermu", "le hermu"},
    ["dada"]          = {"dadaa", "d4da", "da da"},
    ["dadamu"]        = {"dadaamu", "d4damu", "da damu"},
    ["dadaku"]        = {"dadaaku", "d4daku", "da daku"},
    ["paha"]          = {"pahaa", "p4ha", "pa ha"},
    ["pahamu"]        = {"pahaamu", "p4hamu", "pa hamu"},
    ["kulit"]         = {"kuliit", "kulIt", "ku lit"},
    ["kulitmu"]       = {"kuliitmu", "kulItmu", "ku litmu"},
    ["desah"]         = {"desaah", "d3sah", "de sah"},
    ["mendesah"]      = {"mendesaah", "mend3sah", "men desah"},
    ["desahan"]       = {"desaahan", "d3sahan", "de sahan"},
    ["keringat"]      = {"keringaat", "kerIngat", "ke ringat"},
    ["bercinta"]      = {"berciinta", "bercInta", "ber cinta"},
    ["cinta"]         = {"ciinta", "cInta", "cin ta"},
    ["cintaku"]       = {"ciintaku", "cIntaku", "cin taku"},
    ["cintamu"]       = {"ciintamu", "cIntamu", "cin tamu"},
    ["mencintai"]     = {"menciintai", "mencIntai", "men cintai"},
    ["mencintaimu"]   = {"menciintaimu", "mencIntaimu", "men cintaimu"},
    ["sayang"]        = {"sayaang", "s4yang", "sa yang"},
    ["sayangku"]      = {"sayaangku", "s4yangku", "sa yangku"},
    ["kekasih"]       = {"kekaasih", "kek4sih", "ke kasih"},
    ["kekasihku"]     = {"kekaasihku", "kek4sihku", "ke kasihku"},
    ["pacar"]         = {"pacaar", "p4car", "pa car"},
    ["pacarku"]       = {"pacaarku", "p4carku", "pa carku"},
    ["pacarmu"]       = {"pacaarmu", "p4carmu", "pa carmu"},
    ["memiliki"]      = {"memiliiki", "memIlIki", "me miliki"},
    ["memilikimu"]    = {"memiliikimu", "memIlIkimu", "me milikimu"},
    ["milikku"]       = {"miliikku", "mIlIkku", "mi likku"},
    ["milikmu"]       = {"miliikmu", "mIlIkmu", "mi likmu"},
    ["dirimu"]        = {"diriimu", "dIrimu", "di rimu"},
    ["diriku"]        = {"diriiku", "dIriku", "di riku"},
    ["memudar"]       = {"memudaar", "memvdar", "me mudar"},
    ["memnudar"]      = {"memnudaar", "memnvdar", "mem nudar"},
    ["remang"]        = {"remaang", "r3mang", "re mang"},
    ["sunyi"]         = {"sunyii", "svnyi", "su nyi"},
    ["hampa"]         = {"hampaa", "h4mpa", "ham pa"},

    -- Kata Tier-1 Inggris (Anti-Punctuation Stripper)
    ["fuck"]          = {"fuvck", "fvck", "fu ck"},
    ["fucks"]         = {"fuvcks", "fvcks", "fu cks"},
    ["fucking"]       = {"fuvcking", "fvcking", "fu cking"},
    ["fuckin"]        = {"fuvckin", "fvckin", "fu ckin"},
    ["fucked"]        = {"fuvcked", "fvcked", "fu cked"},
    ["fucker"]        = {"fuvcker", "fvcker", "fu cker"},
    ["fuckers"]       = {"fuvckers", "fvckers", "fu ckers"},
    ["motherfucker"]  = {"motherfuvcker", "motherfvcker", "mother fu cker"},
    ["motherfucking"] = {"motherfuvcking", "motherfvcking", "mother fu cking"},
    ["shit"]          = {"shiit", "shIt", "sh it"},
    ["shits"]         = {"shiits", "shIts", "sh its"},
    ["shitting"]      = {"shiitting", "shItting", "sh itting"},
    ["shitty"]        = {"shiitty", "shItty", "sh itty"},
    ["bullshit"]      = {"bullshiit", "bullshIt", "bull sh it"},
    ["bitch"]         = {"biitch", "bItch", "bi tch"},
    ["bitches"]       = {"biitches", "bItches", "bi tches"},
    ["bitching"]      = {"biitching", "bItching", "bi tching"},
    ["cunt"]          = {"cuvnt", "cvnt", "cu nt"},
    ["dick"]          = {"diick", "dIck", "di ck"},
    ["dicks"]         = {"diicks", "dIcks", "di cks"},
    ["cock"]          = {"coock", "c0ck", "co ck"},
    ["pussy"]         = {"puvssy", "pvssy", "pu ssy"},
    ["nigga"]         = {"niigga", "nIgga", "ni gga"},
    ["niggas"]        = {"niiggas", "nIggas", "ni ggas"},
    ["nigger"]        = {"niigger", "nIgger", "ni gger"},
    ["slut"]          = {"sluut", "sIut", "sl ut"},
    ["whore"]         = {"whoore", "wh0re", "wh ore"},
    ["sex"]           = {"seex", "s3x", "s ex"},
    ["sexy"]          = {"seexy", "s3xy", "se xy"},
    ["porn"]          = {"poorn", "p0rn", "po rn"},
    ["nude"]          = {"nuude", "nvde", "nu de"},
    ["nudes"]         = {"nuudes", "nvdes", "nu des"},
    ["rape"]          = {"raape", "r4pe", "ra pe"},
    ["kill"]          = {"kiill", "kIll", "ki ll"},
    ["killed"]        = {"kiilled", "kIlled", "ki lled"},
    ["killing"]       = {"kiilling", "kIlling", "ki lling"},
    ["die"]           = {"diie", "dIe", "d ie"},
    ["dying"]         = {"dyiing", "dyIng", "dy ing"},
    ["dead"]          = {"deaad", "d3ad", "de ad"},
    ["suicide"]       = {"suiicide", "suIcIde", "sui cide"},
    ["suicidal"]      = {"suiicidal", "suIcIdal", "sui cidal"},
    ["depressed"]     = {"depreessed", "depr3ssed", "de pressed"},
    ["depression"]    = {"depreession", "depr3ssion", "de pression"},

    -- Kata Tier-1 Kasar & Vulgar Indonesia
    ["kontol"]        = {"kontool", "k0ntol", "kon tol"},
    ["memek"]         = {"memeek", "m3mek", "me mek"},
    ["jembut"]        = {"jembuut", "j3mbut", "jem but"},
    ["ngentot"]       = {"ngentoot", "ng3ntot", "ngen tot"},
    ["ngewe"]         = {"ngeewe", "ng3we", "nge we"},
    ["pepek"]         = {"pepeek", "p3pek", "pe pek"},
    ["tetek"]         = {"teteek", "t3tek", "te tek"},
    ["toket"]         = {"tokeet", "t0ket", "to ket"},
    ["lonte"]         = {"lontee", "l0nte", "lon te"},
    ["anjing"]        = {"anjiing", "anjIng", "an jing"},
    ["anjir"]         = {"anjiir", "anjIr", "an jir"},
    ["bangsat"]       = {"bangsaat", "b4ngsat", "bang sat"},
    ["brengsek"]      = {"brengseek", "br3ngsek", "breng sek"},
    ["bajingan"]      = {"bajiingan", "b4jingan", "ba jingan"},
    ["goblok"]        = {"goblook", "g0blok", "gob lok"},
    ["tolol"]         = {"tolool", "t0lol", "to lol"},
    ["jancok"]        = {"jancook", "j4ncok", "jan cok"},
    ["jancuk"]        = {"jancuuk", "j4ncuk", "jan cuk"},
    ["pantek"]        = {"panteek", "p4ntek", "pan tek"},
    ["puki"]          = {"pukii", "pukI", "pu ki"},
    ["pukimak"]       = {"pukiimak", "pukImak", "puki mak"},
    ["sange"]         = {"sangee", "s4nge", "sa nge"},
    ["bokep"]         = {"bokeep", "b0kep", "bo kep"},
    ["bunuh"]         = {"bunuuh", "bvnuh", "bu nuh"},
    ["membunuh"]      = {"membunuuh", "membvnuh", "mem bunuh"},
    ["mati"]          = {"matii", "m4ti", "ma ti"}
}

-- Daftar kata sensitif umum lainnya
local strictBadWords = {
    "bayang", "bayangkan", "kubayangkan", "membayangkan", "terbayang",
    "tubuh", "tubuhmu", "tubuhku", "badan", "badanmu", "badanku", "raga", "ragamu",
    "tidur", "tidurlah", "meniduri", "kutiduri", "ketiduran", "ranjang", "kasur",
    "kamar", "kamarmu", "kamarku", "selimut", "bantal",
    "bibir", "bibirmu", "bibirku", "lidah", "lidahmu", "leher", "lehermu",
    "dada", "dadamu", "dadaku", "paha", "pahamu", "pinggul", "pinggulmu",
    "kulit", "kulitmu", "keringat", "desah", "mendesah", "desahan",
    "peluk", "memeluk", "memelukmu", "kupeluk", "pelukan", "pelukanmu",
    "dekap", "mendekap", "dekapan", "rangkul", "merangkul",
    "cium", "mencium", "menciummu", "kucium", "ciuman", "kecup", "mengecup",
    "sentuh", "menyentuh", "menyentuhmu", "kusentuh", "sentuhan",
    "belai", "membelai", "raba", "meraba", "pangku", "memangku",
    "bercinta", "cinta", "cintaku", "cintamu", "mencintai", "mencintaimu",
    "pacar", "pacarku", "pacarmu", "pacaran", "kekasih", "kekasihku", "kekasihmu",
    "nikah", "menikah", "menikahimu", "suami", "istri", "selingkuh", "pelakor",
    "telanjang", "bugil", "seksi", "montok", "bohay", "semok", "bahenol",
    "kutang", "bh", "cangcut", "sempak", "kolor", "daleman",

    "anjing", "anjir", "anjrit", "anjrot", "anying", "anjg", "ajg", "njir", "njrit",
    "asu", "asw", "kirik", "babi", "celeng", "bagong", "monyet", "kunyuk", "kampret",
    "goblok", "goblog", "gblk", "tolol", "tll", "bodoh", "bego", "begok", "bloon",
    "dungu", "idiot", "autis", "cacat", "sinting", "sarap", "edan",
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
    "sodomi", "sepong", "nyepong", "sange", "horni", "birahi", "syahwat", "perawan",
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
    "stab", "stabbed", "choke", "shoot", "shooting", "shotgun", "gun", "guns", "pistol",
    "rifle", "bullet", "bomb", "terrorist", "torture", "abuse", "rape", "raped", "rapist",
    "molest", "pedo", "pedophile", "incest", "sexual", "sexually", "sex", "sexy",
    "porn", "porno", "hentai", "nsfw", "nude", "nudes", "naked", "horny", "orgasm",
    "cum", "cumming", "sperm", "boobs", "boob", "titties", "tits", "breast", "breasts",
    "nipple", "nipples", "booty", "butt", "anus", "penis", "vagina", "clit", "dildo",
    "blowjob", "handjob", "anal", "oral", "virgin", "lust", "fetish", "bdsm", "kinky",
    "drugs", "drug", "weed", "marijuana", "cannabis", "cocaine", "coke", "heroin",
    "meth", "ecstasy", "molly", "lsd", "pills", "vape", "drunk", "wasted", "whiskey",
    "vodka", "beer", "wine", "kiss", "kissing", "kissed", "lips", "tongue", "thighs",
    "undress", "underwear", "bra", "panties", "bikini", "bed", "bedroom", "boyfriend",
    "girlfriend", "lover", "dating", "marry", "husband", "wife", "daddy", "mommy",
    "discord", "tiktok", "instagram", "whatsapp", "telegram", "youtube", "twitter",
    "facebook", "snapchat", "tinder", "onlyfans", "spotify", "sleep", "sleeping"
}

local hardSubstrings = {
    "fuck", "fck", "fuk", "shit", "bitch", "cunt", "dick", "cock", "puss", "nigg",
    "fag", "slut", "whor", "rape", "pedo", "porn", "nude", "sex", "suicid", "depres",
    "kontol", "kntl", "memek", "pepek", "jembut", "jmbt", "ngentot", "ngewe",
    "tetek", "toket", "lonte", "pelacur", "bokep", "mesum", "cabul", "perkosa",
    "anjing", "anjir", "bangsat", "brengsek", "bajingan", "goblok", "tolol",
    "jancok", "jancuk", "pantek", "kimak", "puki", "sange", "tubuh", "tidur", "bayang"
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

-- Fungsi Pure ASCII Double-Vowel / Soft-Insert (Tidak bisa dihapus oleh De-Accenter & Punctuation Stripper Roblox)
local function doubleLastVowel(word)
    -- Cari huruf vokal terakhir di dalam kata lalu gandakan (misal: tidur -> tiduur, tubuh -> tubuuh)
    for i = #word, 1, -1 do
        local ch = word:sub(i, i)
        if ch:match("[aiueoAIUEO]") then
            return word:sub(1, i) .. ch:lower() .. word:sub(i + 1)
        end
    end
    -- Jika kata tidak punya vokal (misal singkatan kntl, bgst), sisipkan huruf 'e' atau 'u'
    local mid = math.max(1, math.floor(#word / 2))
    return word:sub(1, mid) .. "u" .. word:sub(mid + 1)
end

local function bypassWord(word)
    if #word < 2 then return word end
    local lower = word:lower()
    local mode = math.clamp(tonumber(FilterModule.BypassMode) or 1, 1, 3)

    -- 1. Cek kamus Direct Bypass
    if directBypassMap[lower] then
        return matchCase(word, directBypassMap[lower][mode])
    end

    -- 2. Jika kata mengandung substring "fuck"
    if lower:find("fuck", 1, true) then
        local rep = (mode == 1 and "fuvck") or (mode == 2 and "fvck") or "fu ck"
        return word:gsub("[fF][uU][cC][kK]", function(m) return matchCase(m, rep) end)
    end

    -- 3. Jika Mode 1 (Double-Vowel ASCII: "peluk" -> "peluuk", "meraba" -> "merabaa")
    if mode == 1 then
        return doubleLastVowel(word)
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
        return doubleLastVowel(word)
    else
        local mid = math.max(2, math.floor(#word / 2))
        return word:sub(1, mid) .. " " .. word:sub(mid + 1)
    end
end

local function isBadWord(word)
    local lowerWord = word:lower():gsub("'", "")
    if directBypassMap[lowerWord] or wordLookup[lowerWord] then return true end

    local suffixes = {"nya", "mu", "ku", "lah", "kan", "an", "in", "ing", "ed", "es", "s"}
    for _, suf in ipairs(suffixes) do
        if #lowerWord > #suf + 2 and lowerWord:sub(-#suf) == suf then
            local stem = lowerWord:sub(1, #lowerWord - #suf)
            if directBypassMap[stem] or wordLookup[stem] then return true end
        end
    end

    local prefixes = {"ku", "kau", "di", "me", "mem", "men", "meng", "meny", "ter", "ber", "se"}
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

        return word
    end)

    cleaned = cleaned:gsub("(%d)(%d)", "%1 %2"):gsub("(%d)(%d)", "%1 %2")
    return cleaned
end

return FilterModule
