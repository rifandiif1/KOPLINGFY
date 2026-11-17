-- =================================================================================
-- KOPLINGTIFY LITE v2.5 - NON-REPLACEMENT BYPASS FILTER (KOPLINGTIFY_FILTER.luau)
-- =================================================================================
local FilterModule = {}

-- Pilihan Mode Bypass:
-- 1 = Homoglyph (Mengganti huruf vokal dengan karakter Cyrillic identik, terlihat 100% murni)
-- 2 = Zero-Width / Soft Separator (Menyisipkan karakter tak terlihat di tengah kata)
-- 3 = Simbol Visual (Menyisipkan karakter titik tengah '·' atau '#' seperti "je·mbut")
FilterModule.BypassMode = 1

-- Peta karakter Homoglyph (Terlihat sama persis dengan huruf Latin biasa di font Roblox)
local homoglyphMap = {
    ["a"] = "а", -- Cyrillic small letter a (U+0430)
    ["e"] = "е", -- Cyrillic small letter ie (U+0435)
    ["i"] = "і", -- Cyrillic small letter byelorussian-ukrainian i (U+0456)
    ["o"] = "о", -- Cyrillic small letter o (U+043E)
    ["c"] = "с", -- Cyrillic small letter es (U+0441)
    ["p"] = "р", -- Cyrillic small letter er (U+0440)
    ["x"] = "х", -- Cyrillic small letter ha (U+0445)
    ["A"] = "А", -- Cyrillic capital A
    ["E"] = "Е", -- Cyrillic capital IE
    ["I"] = "І", -- Cyrillic capital I
    ["O"] = "О", -- Cyrillic capital O
    ["C"] = "С", -- Cyrillic capital ES
    ["P"] = "Р"  -- Cyrillic capital ER
}

-- Daftar kata yang memicu sensor Roblox (akan di-bypass tanpa mengubah katanya)
local targetWords = {
    -- Kata Puitis & Umum yang Sering Kena False Positive
    "memnudar", "memudar", "pudar", "remang", "sunyi", "sepi", "kesepian",
    "gelap", "kegelapan", "hampa", "kelam", "lara", "pilu", "memiliki",
    "memilikimu", "miliki", "milikku", "milikmu", "dirimu", "diriku",
    "peluk", "memeluk", "memelukmu", "pelukan", "dekap", "mendekap",
    "cium", "mencium", "ciuman", "kecup", "belai", "sentuh", "menyentuh",
    "raba", "pangku", "pacar", "pacaran", "kekasih", "sayang", "cinta",
    "mencintai", "asmara", "mesra", "kencan", "mantan", "nikah", "menikah",
    "suami", "istri", "jodoh", "rayu", "goda", "bibir", "lidah", "leher",
    "dada", "perut", "pinggang", "pinggul", "paha", "kulit", "tubuh", "badan",
    "keringat", "desah", "desahan", "napas", "baju", "celana", "rok", "kamar",
    "ranjang", "kasur", "bantal", "selimut", "tidur", "mandi", "hotel", "kos",
    "umur", "usia", "alamat", "nomor", "telepon", "hp", "wa", "ig", "fb", "tt",
    "uang", "duit", "bayar", "jual", "beli", "harga", "murahan",

    -- Kata Kasar, Slang & Vulgar Indonesia
    "anjing", "anjir", "anjay", "anjrit", "anjrot", "anying", "njir", "njay",
    "asu", "babi", "celeng", "monyet", "kunyuk", "kampret", "bangsat", "bgst",
    "brengsek", "bajingan", "keparat", "bedebah", "sialan", "sial", "bangke",
    "bangkai", "tai", "tahi", "taik", "berak", "kentut", "kencing", "bacot",
    "bct", "cocot", "congor", "mampus", "modar", "kojor", "matek", "setan",
    "iblis", "dajjal", "neraka", "jahanam", "laknat", "haram", "dosa", "kafir",
    "goblok", "goblog", "gblk", "tolol", "tll", "bodoh", "bego", "begok",
    "oon", "bloon", "dungu", "idiot", "autis", "cacat", "gila", "sinting",
    "sarap", "edan", "stres", "depresi", "budek", "buta", "bisu", "gendut",
    "gembrot", "jelek", "burik", "dekil", "miskin", "gembel", "sampah",
    "pecundang", "cupu", "jancok", "jancuk", "dancok", "cuk", "cok", "matamu",
    "ndasmu", "lambemu", "raimu", "pantek", "kimak", "pukimak", "puki", "sundal",
    "kontol", "kntl", "memek", "mmk", "pepek", "jembut", "jmbt", "itil",
    "pentil", "tetek", "tete", "toket", "payudara", "pantat", "bokong", "bool",
    "selangkangan", "kelamin", "zakar", "vagina", "penis", "ngentot", "entot",
    "ngewe", "ewe", "kenthu", "kawin", "peju", "mani", "sperma", "coli", "onani",
    "masturbasi", "sange", "horni", "nafsu", "birahi", "gairah", "syahwat",
    "perawan", "perjaka", "pelacur", "lonte", "psk", "jablay", "bispak",
    "openbo", "michat", "mucikari", "germo", "simpanan", "selingkuh", "pelakor",
    "telanjang", "bugil", "seksi", "montok", "bohay", "semok", "bercinta",
    "seks", "seksual", "bokep", "mesum", "cabul", "perkosa", "mati", "kematian",
    "meninggal", "tewas", "bunuh", "membunuh", "bantai", "cekik", "tikam",
    "tusuk", "bacok", "penggal", "gantung", "darah", "berdarah", "mayat",
    "jenazah", "kuburan", "makam", "pisau", "belati", "golok", "celurit",
    "senjata", "peluru", "tembak", "racun", "mabuk", "mabok", "teler", "miras",
    "alkohol", "bir", "anggur", "tuak", "ciu", "amer", "narkoba", "ganja",
    "sabu", "ekstasi", "heroin", "kokain", "pil", "obat", "rokok", "judi",
    "slot", "maling", "pencuri", "korupsi", "penjara",

    -- Kata Kasar, Dewasa & Rawan Sensor Inggris
    "motherfucker", "motherfuckers", "motherfucking", "mf", "depres", "depress", "depresed", "depressed", "fucking", "fuckin",
    "fucked", "fucker", "fuck", "fucks", "fck", "fuk", "wtf", "stfu", "shitting",
    "shitty", "bullshit", "shit", "sht", "bitching", "bitches", "bitch", "btch",
    "asshole", "assholes", "dumbass", "jackass", "badass", "ass", "bastard",
    "dammit", "damn", "goddamn", "hell", "cunt", "dick", "dicks", "cock",
    "pussy", "twat", "prick", "wanker", "slut", "sluts", "whore", "whores",
    "hoe", "hoes", "prostitute", "stripper", "hooker", "pimp", "nigga", "niggas",
    "nigger", "niggers", "faggot", "fag", "retard", "retarded", "suicidal",
    "suicide", "kms", "kys", "killing", "killed", "killer", "kill", "murder",
    "dying", "died", "die", "dead", "death", "corpse", "bleeding", "bleed",
    "blood", "stab", "choke", "shoot", "shooting", "shotgun", "gun", "guns",
    "pistol", "rifle", "bullet", "bomb", "terrorist", "torture", "abuse",
    "sexual", "sex", "sexy", "porn", "porno", "hentai", "nsfw", "nude", "nudes",
    "naked", "horny", "orgasm", "cum", "sperm", "boobs", "boob", "titties",
    "tits", "nipple", "booty", "thighs", "virgin", "lust", "fetish", "bdsm",
    "rape", "raped", "pedo", "incest", "drugs", "drug", "weed", "marijuana",
    "cocaine", "coke", "heroin", "meth", "ecstasy", "pills", "overdose", "vape",
    "smoke", "drunk", "wasted", "alcohol", "liquor", "whiskey", "vodka", "beer",
    "wine", "kiss", "kisses", "kissing", "kissed", "hug", "cuddle", "touch",
    "lips", "tongue", "neck", "chest", "waist", "hips", "thigh", "skin", "body",
    "sweat", "breath", "breathe", "moan", "undress", "underwear", "bra",
    "panties", "bikini", "bed", "bedroom", "sheets", "pillow", "blanket",
    "shower", "motel", "boyfriend", "girlfriend", "lover", "dating", "marry",
    "husband", "wife", "babe", "baby", "honey", "shawty", "daddy", "mommy",
    "crush", "flirt", "seduce", "cheating", "discord", "tiktok", "instagram",
    "whatsapp", "telegram", "youtube", "twitter", "facebook", "snapchat",
    "tinder", "onlyfans", "spotify"
}

local wordLookup = {}
for _, w in ipairs(targetWords) do
    wordLookup[w:lower()] = true
end

-- Fungsi pembungkus kata agar lolos deteksi tanpa mengganti kata
local function obfuscateWord(word)
    if #word < 2 then return word end
    local mode = FilterModule.BypassMode or 1

    if mode == 1 then
        -- Mode 1: Ganti huruf vokal/tertentu dengan Homoglyph Cyrillic + sisipkan Zero-Width Joiner
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
        -- Fallback jika kata tidak memiliki huruf di homoglyphMap
        local mid = math.max(1, math.floor(#word / 2))
        return word:sub(1, mid) .. "\226\128\141" .. word:sub(mid + 1)

    elseif mode == 2 then
        -- Mode 2: Sisipkan Zero-Width Joiner (U+200D) di setiap celah suku kata
        local mid = math.max(1, math.floor(#word / 2))
        return word:sub(1, mid) .. "\226\128\141" .. word:sub(mid + 1)

    else
        -- Mode 3: Sisipkan titik tengah tipis (contoh: "je·mbut" atau "me·mudar")
        local mid = math.max(1, math.floor(#word / 2))
        return word:sub(1, mid) .. "·" .. word:sub(mid + 1)
    end
end

function FilterModule.Sanitize(text, enabled)
    if not text or text == "" or enabled == false then return text end

    local cleaned = text:gsub("([%a'*%-]+)", function(word)
        local lowerWord = word:lower()
        local stripped = lowerWord:gsub("'", "")

        -- Jika kata mengandung sensor bintang bawaan seperti f**k
        if lowerWord:find("%*") then
            return obfuscateWord(word:gsub("%*", "u"))
        end

        -- Cek kata langsung
        if wordLookup[lowerWord] or wordLookup[stripped] then
            return obfuscateWord(word)
        end

        -- Cek kata ulang (contoh: remang-remang)
        if lowerWord:find("%-") then
            local parts = string.split(word, "-")
            for i, p in ipairs(parts) do
                local lp = p:lower():gsub("'", "")
                if wordLookup[lp] then
                    parts[i] = obfuscateWord(p)
                end
            end
            return table.concat(parts, "-")
        end

        -- Cek kata berimbuhan akhiran (-nya, -mu, -ku, -lah)
        local root = stripped:match("^([%a]+)nya$")
            or stripped:match("^([%a]+)mu$")
            or stripped:match("^([%a]+)ku$")
            or stripped:match("^([%a]+)lah$")

        if root and wordLookup[root] then
            return obfuscateWord(word)
        end

        -- Cek apakah kata mengandung potongan kata terlarang (Scunthorpe problem seperti 'nud', 'memi', 'kntl')
        for bad in pairs(wordLookup) do
            if #bad >= 4 and lowerWord:find(bad, 1, true) then
                return obfuscateWord(word)
            end
        end

        return word
    end)

    -- Pisahkan angka berurutan agar tidak diblokir sebagai nomor telepon oleh Roblox
    cleaned = cleaned:gsub("(%d)(%d)", "%1\226\128\141%2"):gsub("(%d)(%d)", "%1\226\128\141%2")
    return cleaned
end

return FilterModule
