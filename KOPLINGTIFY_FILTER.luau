-- =================================================================================
-- KOPLINGTIFY LITE v2.5 - PURE ASCII SAFE BYPASS FILTER (KOPLINGTIFY_FILTER.luau)
-- =================================================================================
local FilterModule = {}

-- Pilihan Mode Bypass (100% ASCII Murni - Tanpa Unicode/Zero-Width yang memicu sensor Roblox):
-- 1 = Halus / Mirip Asli (Ubah 'l' -> 'I', atau sisipkan 1 apostrof tipis ' di tengah kata: "tub'uhmu")
-- 2 = Strip Suku Kata Tunggal (Contoh: "tu-buhmu", "je-mbut")
-- 3 = Titik / Pagar Tunggal (Contoh: "tu.buhmu", "je.mbut")
FilterModule.BypassMode = 1

-- HANYA kata yang benar-benar disensor oleh Roblox (Kata aman tidak dimasukkan agar tidak kena false-positive)
local strictBadWords = {
    -- Anatomi & Romansa Intim yang Sering Diblokir Roblox
    "tubuh", "tubuhmu", "tubuhku", "badanmu", "ragamu", "bibirmu", "bibirku",
    "lidah", "lidahmu", "lehermu", "dada", "dadamu", "dadaku", "paha", "pahamu",
    "pinggul", "pinggulmu", "kulitmu", "keringat", "desah", "mendesah", "desahan",
    "peluk", "memeluk", "memelukmu", "kupeluk", "pelukan", "pelukanmu",
    "cium", "mencium", "menciummu", "kucium", "ciuman", "kecup", "mengecup",
    "sentuh", "menyentuh", "menyentuhmu", "kusentuh", "sentuhan",
    "belai", "membelai", "raba", "meraba", "pangku", "memangku",
    "bercinta", "ercinta", "meniduri", "kutiduri", "ranjang", "di atas ranjang",
    "pacar", "pacarku", "pacarmu", "pacaran", "kekasih", "kekasihku", "kekasihmu",
    "nikah", "menikah", "menikahimu", "suami", "istri", "selingkuh", "pelakor",
    "telanjang", "bugil", "seksi", "montok", "bohay", "semok", "bahenol",
    "kutang", "bh", "cangcut", "sempak", "kolor", "daleman",

    -- Kata Kasar, Umpatan & Vulgar (ID)
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

    -- Kekerasan, Self-Harm, Mental Health & Narkoba (ID & EN)
    "bunuh", "membunuh", "pembunuh", "bantai", "membantai", "cekik", "tikam",
    "tusuk", "bacok", "penggal", "mutilasi", "mayat", "jenazah", "bunuh diri",
    "mabuk", "mabok", "miras", "alkohol", "tuak", "ciu", "amer", "narkoba",
    "ganja", "sabu", "ekstasi", "heroin", "kokain", "overdosis", "sakau", "judi", "judol",
    "depressed", "depressing", "depression", "depresi", "anxious", "anxiety",
    "suicidal", "suicide", "kms", "kys", "selfharm", "cutting", "worthless", "hopeless",

    -- Profanity, Slurs & NSFW (EN)
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

-- Hanya akar kata yang PASTI diblokir oleh Scunthorpe filter Roblox
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

-- Fungsi Bypass Murni ASCII (Tanpa simbol aneh / Zero-Width yang bikin Roblox curiga)
local function bypassAsciiWord(word)
    if #word < 3 then return word end
    local mode = FilterModule.BypassMode or 1
    local mid = math.max(2, math.floor(#word / 2))

    if mode == 1 then
        -- Jika ada huruf 'l' kecil, ubah 1 huruf 'l' menjadi 'I' besar (di font Gotham Roblox 100% identik)
        local lPos = word:find("l", 2, true)
        if lPos then
            return word:sub(1, lPos - 1) .. "I" .. word:sub(lPos + 1)
        end
        -- Jika ada huruf 'I' besar, ubah menjadi 'l' kecil
        local iPos = word:find("I", 2, true)
        if iPos then
            return word:sub(1, iPos - 1) .. "l" .. word:sub(iPos + 1)
        end
        -- Selain itu, sisipkan 1 tanda petik tunggal tipis (') tepat di tengah suku kata
        return word:sub(1, mid) .. "'" .. word:sub(mid + 1)

    elseif mode == 2 then
        -- Sisipkan 1 tanda hubung (-) di tengah kata (Contoh: "tu-buhmu", "je-mbut")
        return word:sub(1, mid) .. "-" .. word:sub(mid + 1)

    else
        -- Mode 3: Sisipkan 1 titik biasa (.) di tengah kata (Contoh: "tu.buhmu", "je.mbut")
        return word:sub(1, mid) .. "." .. word:sub(mid + 1)
    end
end

local function isBadWord(word)
    local lowerWord = word:lower():gsub("'", "")
    if wordLookup[lowerWord] then return true end

    -- Cek akhiran umum (-mu, -ku, -nya, -lah, -s, -ing, -ed) pada daftar strictBadWords
    local suffixes = {"nya", "mu", "ku", "lah", "kan", "ing", "ed", "es", "s"}
    for _, suf in ipairs(suffixes) do
        if #lowerWord > #suf + 2 and lowerWord:sub(-#suf) == suf then
            local stem = lowerWord:sub(1, #lowerWord - #suf)
            if wordLookup[stem] then return true end
        end
    end

    -- Cek substring terlarang
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
            return bypassAsciiWord(word:gsub("%*", "u"))
        end

        if word:find("%-") then
            local parts = string.split(word, "-")
            for i, p in ipairs(parts) do
                if isBadWord(p) then
                    parts[i] = bypassAsciiWord(p)
                end
            end
            return table.concat(parts, "-")
        end

        if isBadWord(word) then
            return bypassAsciiWord(word)
        end

        -- Kata yang aman dibiarkan 100% utuh!
        return word
    end)

    -- Pisahkan angka berurutan dengan spasi biasa agar tidak dikira nomor telepon
    cleaned = cleaned:gsub("(%d)(%d)", "%1 %2"):gsub("(%d)(%d)", "%1 %2")
    return cleaned
end

return FilterModule
