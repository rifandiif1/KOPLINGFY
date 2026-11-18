-- =================================================================================
-- KOPLINGTIFY LITE v2.5 - TIER-1 ANTI-STRIP BYPASS FILTER (KOPLINGTIFY_FILTER.luau)
-- =================================================================================
local FilterModule = {}

-- Pilihan Mode Bypass:
-- 1 = Latin-1 Accent Vowel (Resmi didukung chat Eropa Roblox: "fùck", "shìt", "tùbuhmu", "jémbut")
-- 2 = Visual Leetspeak / Consonant Mask (Murni A-Z: "fvck", "shlt", "bItch", "jexmbut")
-- 3 = Spasi Suku Kata Mikro (Memecah kata Tier-1 menjadi "fu ck", "je mbut")
FilterModule.BypassMode = 1

-- Peta Vokal Aksentuasi Eropa Barat (Latin-1 Supplement - Legal di TextChatService Roblox)
local accentVowelMap = {
    ["a"] = "à",
    ["e"] = "é",
    ["i"] = "ì",
    ["o"] = "ò",
    ["u"] = "ù",
    ["A"] = "À",
    ["E"] = "É",
    ["I"] = "Ì",
    ["O"] = "Ò",
    ["U"] = "Ù"
}

-- Kamus Bypass Spesifik untuk Kata Tier-1 (Karena tanda titik/petik pasti dihapus oleh Roblox)
local tier1DirectBypass = {
    -- Mode 1 (Accent), Mode 2 (Leet ASCII), Mode 3 (Split)
    ["fuck"]         = {"fùck", "fvck", "fu ck"},
    ["fucks"]        = {"fùcks", "fvcks", "fu cks"},
    ["fucking"]      = {"fùcking", "fvcking", "fu cking"},
    ["fuckin"]       = {"fùckin", "fvckin", "fu ckin"},
    ["fucked"]       = {"fùcked", "fvcked", "fu cked"},
    ["fucker"]       = {"fùcker", "fvcker", "fu cker"},
    ["fuckers"]      = {"fùckers", "fvckers", "fu ckers"},
    ["motherfucker"] = {"mòtherfùcker", "motherfvcker", "mother fu cker"},
    ["motherfucking"]= {"mòtherfùcking", "motherfvcking", "mother fu cking"},
    ["shit"]         = {"shìt", "shlt", "sh it"},
    ["shits"]        = {"shìts", "shlts", "sh its"},
    ["shitting"]     = {"shìtting", "shltting", "sh itting"},
    ["shitty"]       = {"shìtty", "shltty", "sh itty"},
    ["bullshit"]     = {"bùllshìt", "bullshlt", "bull sh it"},
    ["bitch"]        = {"bìtch", "bItch", "bi tch"},
    ["bitches"]      = {"bìtches", "bItches", "bi tches"},
    ["bitching"]     = {"bìtching", "bItching", "bi tching"},
    ["cunt"]         = {"cùnt", "cvnt", "cu nt"},
    ["dick"]         = {"dìck", "dIck", "di ck"},
    ["dicks"]        = {"dìcks", "dIcks", "di cks"},
    ["cock"]         = {"còck", "c0ck", "co ck"},
    ["pussy"]        = {"pùssy", "pvssy", "pu ssy"},
    ["nigga"]        = {"nìgga", "nIgga", "ni gga"},
    ["niggas"]       = {"nìggas", "nIggas", "ni ggas"},
    ["nigger"]       = {"nìgger", "nIgger", "ni gger"},
    ["slut"]         = {"slùt", "sIut", "sl ut"},
    ["whore"]        = {"whòre", "wh0re", "wh ore"},
    ["sex"]          = {"séx", "s3x", "s ex"},
    ["sexy"]         = {"séxy", "s3xy", "se xy"},
    ["porn"]         = {"pòrn", "p0rn", "po rn"},
    ["nude"]         = {"nùde", "nvde", "nu de"},
    ["nudes"]        = {"nùdes", "nvdes", "nu des"},
    ["rape"]         = {"ràpe", "r4pe", "ra pe"},
    ["kill"]         = {"kìll", "kIll", "ki ll"},
    ["suicide"]      = {"suìcìde", "suIcIde", "sui cide"},
    ["suicidal"]     = {"suìcìdal", "suIcIdal", "sui cidal"},
    ["depressed"]    = {"dépréssed", "depr3ssed", "de pressed"},
    ["depression"]   = {"dépréssion", "depr3ssion", "de pression"},
    -- Tier-1 Indonesia
    ["kontol"]       = {"kòntol", "k0ntol", "kon tol"},
    ["memek"]        = {"mémék", "m3mek", "me mek"},
    ["jembut"]       = {"jémbùt", "j3mbut", "jem but"},
    ["ngentot"]      = {"ngéntòt", "ng3ntot", "ngen tot"},
    ["ngewe"]        = {"ngéwé", "ng3we", "nge we"},
    ["pepek"]        = {"pépék", "p3pek", "pe pek"},
    ["tetek"]        = {"téték", "t3tek", "te tek"},
    ["toket"]        = {"tòkét", "t0ket", "to ket"},
    ["lonte"]        = {"lònté", "l0nte", "lon te"},
    ["anjing"]       = {"ànjìng", "anjIng", "an jing"},
    ["anjir"]        = {"ànjìr", "anjIr", "an jir"},
    ["bangsat"]      = {"bàngsat", "b4ngsat", "bang sat"},
    ["goblok"]       = {"gòblòk", "g0blok", "gob lok"},
    ["tolol"]        = {"tòlòl", "t0lol", "to lol"},
    ["jancok"]       = {"jàncòk", "j4ncok", "jan cok"},
    ["jancuk"]       = {"jàncùk", "j4ncuk", "jan cuk"},
    ["pantek"]       = {"pànték", "p4ntek", "pan tek"},
    ["puki"]         = {"pùkì", "pukI", "pu ki"},
    ["pukimak"]      = {"pùkìmàk", "pukImak", "puki mak"},
    ["tubuh"]        = {"tùbùh", "tvbuh", "tu buh"},
    ["tubuhmu"]      = {"tùbùhmu", "tvbuhmu", "tu buhmu"},
    ["tubuhku"]      = {"tùbùhku", "tvbuhku", "tu buhku"},
    ["memudar"]      = {"mémùdar", "memvdar", "me mudar"},
    ["memnudar"]     = {"mémnùdar", "memnvdar", "mem nudar"}
}

-- Daftar kata sensitif yang perlu di-bypass (Kata sehari-hari yang aman TIDAK dimasukkan)
local strictBadWords = {
    "tubuh", "tubuhmu", "tubuhku", "badanmu", "ragamu", "bibirmu", "bibirku",
    "lidah", "lidahmu", "lehermu", "dada", "dadamu", "dadaku", "paha", "pahamu",
    "pinggul", "pinggulmu", "kulitmu", "keringat", "desah", "mendesah", "desahan",
    "peluk", "memeluk", "memelukmu", "kupeluk", "pelukan", "pelukanmu",
    "cium", "mencium", "menciummu", "kucium", "ciuman", "kecup", "mengecup",
    "sentuh", "menyentuh", "menyentuhmu", "kusentuh", "sentuhan",
    "belai", "membelai", "raba", "meraba", "pangku", "memangku",
    "bercinta", "meniduri", "kutiduri", "ranjang", "pacar", "pacarku", "pacarmu",
    "pacaran", "kekasih", "kekasihku", "kekasihmu", "nikah", "menikah", "menikahimu",
    "suami", "istri", "selingkuh", "pelakor", "telanjang", "bugil", "seksi",
    "montok", "bohay", "semok", "bahenol", "kutang", "bh", "cangcut", "sempak",

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
    "tusuk", "bacok", "penggal", "mutilasi", "mayat", "jenazah",
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
    "facebook", "snapchat", "tinder", "onlyfans", "spotify"
}

local hardSubstrings = {
    "fuck", "fck", "fuk", "shit", "bitch", "cunt", "dick", "cock", "puss", "nigg",
    "fag", "slut", "whor", "rape", "pedo", "porn", "nude", "sex", "suicid", "depres",
    "kontol", "kntl", "memek", "pepek", "jembut", "jmbt", "ngentot", "ngewe",
    "tetek", "toket", "lonte", "pelacur", "bokep", "mesum", "cabul", "perkosa",
    "anjing", "anjir", "bangsat", "brengsek", "bajingan", "goblok", "tolol",
    "jancok", "jancuk", "pantek", "kimak", "puki", "sange"
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

local function bypassWord(word)
    if #word < 2 then return word end
    local lower = word:lower()
    local mode = math.clamp(tonumber(FilterModule.BypassMode) or 1, 1, 3)

    -- 1. Jika kata ada di kamus Tier-1 Direct Bypass (seperti fuck, shit, bitch, jembut, tubuhmu)
    if tier1DirectBypass[lower] then
        return matchCase(word, tier1DirectBypass[lower][mode])
    end

    -- 2. Jika kata mengandung "fuck" di dalamnya (seperti motherfucker, clusterfuck)
    if lower:find("fuck", 1, true) then
        local rep = (mode == 1 and "fùck") or (mode == 2 and "fvck") or "fu ck"
        return word:gsub("[fF][uU][cC][kK]", function(m) return matchCase(m, rep) end)
    end

    -- 3. Untuk kata sensitif lainnya sesuai Mode
    if mode == 1 then
        -- Ganti vokal pertama/kedua dengan huruf vokal beraksen Eropa Barat (ù, ì, é, ò, à)
        local replaced = false
        local res = word:gsub("([aeiouAEIOU])", function(v)
            if not replaced and accentVowelMap[v] then
                replaced = true
                return accentVowelMap[v]
            end
            return v
        end)
        if replaced then return res end
    elseif mode == 2 then
        -- Ganti 1 vokal dengan karakter visual ASCII (u->v, i->I, e->3, o->0, a->4)
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
    end

    -- Mode 3 atau Fallback: Pisahkan suku kata tengah dengan spasi
    local mid = math.max(2, math.floor(#word / 2))
    return word:sub(1, mid) .. " " .. word:sub(mid + 1)
end

local function isBadWord(word)
    local lowerWord = word:lower():gsub("'", "")
    if tier1DirectBypass[lowerWord] or wordLookup[lowerWord] then return true end

    local suffixes = {"nya", "mu", "ku", "lah", "kan", "ing", "ed", "es", "s"}
    for _, suf in ipairs(suffixes) do
        if #lowerWord > #suf + 2 and lowerWord:sub(-#suf) == suf then
            local stem = lowerWord:sub(1, #lowerWord - #suf)
            if tier1DirectBypass[stem] or wordLookup[stem] then return true end
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
