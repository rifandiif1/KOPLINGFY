-- =================================================================================
-- KOPLINGTIFY LITE v2.5 - CLEAN & NATURAL MINIMALIST FILTER (KOPLINGTIFY_FILTER.luau)
-- =================================================================================
local FilterModule = {}

-- Pilihan Mode Bypass:
-- 1 = Clean Visual (Prioritas ganti 'l' -> 'I' yang 100% identik di font Roblox, atau 1 huruf halus di ujung)
-- 2 = Soft Apostrophe / Titik Tipis (Contoh: "pacar'mu", "tubuh'mu")
-- 3 = Spasi Suku Kata (Contoh: "pacar mu", "tubuh mu")
FilterModule.BypassMode = 1

-- Hanya kata jangkar (anchor words) yang benar-benar memicu sensor yang diubah (Maksimal 1 titik ubahan!)
local cleanBypassMap = {
    -- Kata dengan huruf 'l' cukup diganti 'I' besar (Di layar Roblox terlihat 100% sama persis!)
    ["lengket"]       = {"Iengket", "leng'ket", "leng ket"},
    ["melengket"]     = {"meIengket", "meleng'ket", "me lengket"},
    ["nempel"]        = {"nempeI", "nem'pel", "nem pel"},
    ["menempel"]      = {"menempeI", "menem'pel", "me nempel"},
    ["lakukan"]       = {"Iakukan", "laku'kan", "la kukan"},
    ["kulakukan"]     = {"kuIakukan", "kulaku'kan", "ku lakukan"},
    ["melakukan"]     = {"meIakukan", "melaku'kan", "me lakukan"},
    ["dilakukan"]     = {"diIakukan", "dilaku'kan", "di lakukan"},
    ["peluk"]         = {"peIuk", "pe'luk", "pe luk"},
    ["memeluk"]       = {"memeIuk", "meme'luk", "me meluk"},
    ["memelukmu"]     = {"memeIukmu", "memeluk'mu", "me melukmu"},
    ["kupeluk"]       = {"kupeIuk", "kupe'luk", "ku peluk"},
    ["dipeluk"]       = {"dipeIuk", "dipe'luk", "di peluk"},
    ["pelukan"]       = {"peIukan", "pelu'kan", "pe lukan"},
    ["pelukanmu"]     = {"peIukanmu", "pelukan'mu", "pe lukanmu"},
    ["pelukanku"]     = {"peIukanku", "pelukan'ku", "pe lukanku"},
    ["dipelukanku"]   = {"dipeIukanku", "dipelukan'ku", "di pelukanku"},
    ["belai"]         = {"beIai", "be'lai", "be lai"},
    ["membelai"]      = {"membeIai", "membe'lai", "mem belai"},
    ["kulit"]         = {"kuIit", "ku'lit", "ku lit"},
    ["kulitmu"]       = {"kuIitmu", "kulit'mu", "ku litmu"},
    ["lidah"]         = {"Iidah", "li'dah", "li dah"},
    ["leher"]         = {"Ieher", "le'her", "le her"},
    ["lehermu"]       = {"Iehermu", "leher'mu", "le hermu"},
    ["lemas"]         = {"Iemas", "le'mas", "le mas"},
    ["liar"]          = {"Iiar", "li'ar", "li ar"},
    ["lukai"]         = {"Iukai", "lu'kai", "lu kai"},
    ["melukai"]       = {"meIukai", "melu'kai", "me lukai"},
    ["melukaimu"]     = {"meIukaimu", "melukai'mu", "me lukaimu"},
    ["tinggalkan"]    = {"tinggaIkan", "tinggal'kan", "ting galkan"},
    ["meninggalkan"]  = {"meninggaIkan", "meninggal'kan", "me ninggalkan"},
    ["memiliki"]      = {"memiIiki", "memili'ki", "me miliki"},
    ["memilikimu"]    = {"memiIikimu", "memiliki'mu", "me milikimu"},
    ["milikku"]       = {"miIikku", "milik'ku", "mi likku"},
    ["milikmu"]       = {"miIikmu", "milik'mu", "mi likmu"},

    -- Kata tanpa huruf 'l' (Hanya diubah 1 huruf paling samar agar tetap natural dibaca)
    ["pacar"]         = {"pacaar", "pa'car", "pa car"},
    ["pacarku"]       = {"pacarkuh", "pacar'ku", "pacar ku"},
    ["pacarmu"]       = {"pacarmuh", "pacar'mu", "pacar mu"},
    ["pacaran"]       = {"pacaraan", "paca'ran", "pa caran"},
    ["kekasih"]       = {"kekaasih", "keka'sih", "ke kasih"},
    ["kekasihku"]     = {"kekasihkuh", "kekasih'ku", "kekasih ku"},
    ["kekasihmu"]     = {"kekasihmuh", "kekasih'mu", "kekasih mu"},
    ["tubuh"]         = {"tubuhh", "tu'buh", "tu buh"},
    ["tubuhmu"]       = {"tubuhmuh", "tubuh'mu", "tubuh mu"},
    ["tubuhku"]       = {"tubuhkuh", "tubuh'ku", "tubuh ku"},
    ["badan"]         = {"badann", "ba'dan", "ba dan"},
    ["badanmu"]       = {"badanmuh", "badan'mu", "badan mu"},
    ["badanku"]       = {"badankuh", "badan'ku", "badan ku"},
    ["tidur"]         = {"tiduhr", "ti'dur", "ti dur"},
    ["meniduri"]      = {"meniduhri", "meni'duri", "me niduri"},
    ["ketiduran"]     = {"ketiduhran", "keti'duran", "ke tiduran"},
    ["ranjang"]       = {"ranjangg", "ran'jang", "ran jang"},
    ["kasur"]         = {"kasurr", "ka'sur", "ka sur"},
    ["kamar"]         = {"kamarr", "ka'mar", "ka mar"},
    ["kamarmu"]       = {"kamarmuh", "kamar'mu", "kamar mu"},
    ["bayangkan"]     = {"bayangkhan", "bayang'kan", "bayang kan"},
    ["kubayangkan"]   = {"kubayangkhan", "kubayang'kan", "ku bayangkan"},
    ["membayangkan"]  = {"membayangkhan", "membayang'kan", "mem bayangkan"},
    ["marah"]         = {"marahh", "ma'rah", "ma rah"},
    ["kegocek"]       = {"kegocekk", "kego'cek", "ke gocek"},
    ["gocek"]         = {"gocekk", "go'cek", "go cek"},
    ["cium"]          = {"ciuhm", "ci'um", "ci um"},
    ["mencium"]       = {"menciuhm", "menci'um", "men cium"},
    ["menciummu"]     = {"menciummuh", "mencium'mu", "men ciummu"},
    ["sentuh"]        = {"sentuhh", "sen'tuh", "sen tuh"},
    ["menyentuh"]     = {"menyentuhh", "menyen'tuh", "me nyentuh"},
    ["menyentuhmu"]   = {"menyentuhmuh", "menyentuh'mu", "me nyentuhmu"},
    ["bibir"]         = {"bibirr", "bi'bir", "bi bir"},
    ["bibirmu"]       = {"bibirmuh", "bibir'mu", "bibir mu"},
    ["dada"]          = {"dadah", "da'da", "da da"},
    ["dadamu"]        = {"dadamuh", "dada'mu", "dada mu"},
    ["paha"]          = {"pahah", "pa'ha", "pa ha"},
    ["pahamu"]        = {"pahamuh", "paha'mu", "paha mu"},
    ["desah"]         = {"desahh", "de'sah", "de sah"},
    ["mendesah"]      = {"mendesahh", "mende'sah", "men desah"},
    ["bercinta"]      = {"bercintah", "bercin'ta", "ber cinta"},
    ["memudar"]       = {"memudarr", "memu'dar", "me mudar"},
    ["memnudar"]      = {"memnudarr", "memnu'dar", "mem nudar"},
    ["remang"]        = {"remangg", "re'mang", "re mang"},

    -- Kata Kasar Indonesia (Menggunakan 'I' untuk huruf 'l', atau 1 huruf tipis)
    ["kontol"]        = {"kontoI", "kon'tol", "kon tol"},
    ["tolol"]         = {"toIoI", "to'lol", "to lol"},
    ["goblok"]        = {"gobIok", "gob'lok", "gob lok"},
    ["lonte"]         = {"Ionte", "lon'te", "lon te"},
    ["pelacur"]       = {"peIacur", "pela'cur", "pe lacur"},
    ["memek"]         = {"mhemek", "me'mek", "me mek"},
    ["jembut"]        = {"jhembut", "jem'but", "jem but"},
    ["ngentot"]       = {"nghentot", "ngen'tot", "ngen tot"},
    ["ngewe"]         = {"nghewe", "nge'we", "nge we"},
    ["pepek"]         = {"phepek", "pe'pek", "pe pek"},
    ["tetek"]         = {"thetek", "te'tek", "te tek"},
    ["toket"]         = {"thoket", "to'ket", "to ket"},
    ["anjing"]        = {"anjhing", "an'jing", "an jing"},
    ["anjir"]         = {"anjhir", "an'jir", "an jir"},
    ["bangsat"]       = {"bangshat", "bang'sat", "bang sat"},
    ["brengsek"]      = {"brengshek", "breng'sek", "breng sek"},
    ["bajingan"]      = {"bajinghan", "baji'ngan", "ba jingan"},
    ["jancok"]        = {"jancohk", "jan'cok", "jan cok"},
    ["jancuk"]        = {"jancuhk", "jan'cuk", "jan cuk"},
    ["pantek"]        = {"panthek", "pan'tek", "pan tek"},
    ["puki"]          = {"puhki", "pu'ki", "pu ki"},
    ["pukimak"]       = {"puhkimak", "puki'mak", "puki mak"},
    ["sange"]         = {"sanghe", "sa'nge", "sa nge"},
    ["bokep"]         = {"bohkep", "bo'kep", "bo kep"},
    ["bunuh"]         = {"buhnuh", "bu'nuh", "bu nuh"},
    ["membunuh"]      = {"membuhnuh", "membu'nuh", "mem bunuh"},

    -- Kata Tier-1 Inggris (Ringkas & Natural)
    ["fuck"]          = {"fuhq", "fu'ck", "fu ck"},
    ["fucks"]         = {"fuhqs", "fu'cks", "fu cks"},
    ["fucking"]       = {"fuhqing", "fu'cking", "fu cking"},
    ["fuckin"]        = {"fuhqin", "fu'ckin", "fu ckin"},
    ["fucked"]        = {"fuhqed", "fu'cked", "fu cked"},
    ["fucker"]        = {"fuhqer", "fu'cker", "fu cker"},
    ["fuckers"]       = {"fuhqers", "fu'ckers", "fu ckers"},
    ["motherfucker"]  = {"mothafuhqer", "motherfu'cker", "mother fu cker"},
    ["motherfucking"] = {"mothafuhqing", "motherfu'cking", "mother fu cking"},
    ["suck"]          = {"suhq", "su'ck", "su ck"},
    ["sucks"]         = {"suhqs", "su'cks", "su cks"},
    ["sucking"]       = {"suhqing", "su'cking", "su cking"},
    ["sucked"]        = {"suhqed", "su'cked", "su cked"},
    ["shit"]          = {"shyt", "sh'it", "sh it"},
    ["shits"]         = {"shyts", "sh'its", "sh its"},
    ["shitting"]      = {"shytting", "sh'itting", "sh itting"},
    ["shitty"]        = {"shytty", "sh'itty", "sh itty"},
    ["bullshit"]      = {"buIIshyt", "bullsh'it", "bull sh it"},
    ["bitch"]         = {"bych", "bi'tch", "bi tch"},
    ["bitches"]       = {"byches", "bi'tches", "bi tches"},
    ["bitching"]      = {"byching", "bi'tching", "bi ching"},
    ["cunt"]          = {"kuhnt", "cu'nt", "cu nt"},
    ["dick"]          = {"dihq", "di'ck", "di ck"},
    ["dicks"]         = {"dihqs", "di'cks", "di cks"},
    ["cock"]          = {"cohq", "co'ck", "co ck"},
    ["pussy"]         = {"puhsy", "pu'ssy", "pu ssy"},
    ["nigga"]         = {"nygha", "ni'gga", "ni gga"},
    ["niggas"]        = {"nyghas", "ni'ggas", "ni ggas"},
    ["nigger"]        = {"nygher", "ni'gger", "ni gger"},
    ["slut"]          = {"sIut", "sl'ut", "sl ut"},
    ["sluts"]         = {"sIuts", "sl'uts", "sl uts"},
    ["whore"]         = {"whohre", "who're", "who re"},
    ["sex"]           = {"sehx", "se'x", "se x"},
    ["sexy"]          = {"sehxy", "se'xy", "se xy"},
    ["porn"]          = {"pohrn", "po'rn", "po rn"},
    ["nude"]          = {"nuhde", "nu'de", "nu de"},
    ["nudes"]         = {"nuhdes", "nu'des", "nu des"},
    ["kill"]          = {"kiII", "ki'll", "ki ll"},
    ["killed"]        = {"kiIIed", "ki'lled", "ki lled"},
    ["killing"]       = {"kiIIing", "ki'lling", "ki lling"},
    ["suicide"]       = {"suyicide", "sui'cide", "sui cide"},
    ["suicidal"]      = {"suyicidal", "sui'cidal", "sui cidal"},
    ["depressed"]     = {"dehpressed", "de'pressed", "de pressed"},
    ["depression"]    = {"dehpression", "de'pression", "de pression"},
    ["worthless"]     = {"worthIess", "worth'less", "worth less"},
    ["hopeless"]      = {"hopeIess", "hope'less", "hope less"},
    ["lonely"]        = {"IoneIy", "lone'ly", "lone ly"},
    ["lick"]          = {"Iick", "li'ck", "li ck"},
    ["licking"]       = {"Iicking", "li'cking", "li cking"},
    ["blowjob"]       = {"bIowjob", "blow'job", "blow job"}
}

-- Substring keras yang wajib diubah jika menempel di dalam kata lain
local hardSubstrings = {
    "fuck", "fck", "fuk", "shit", "bitch", "cunt", "dick", "cock", "puss", "nigg",
    "whor", "rape", "pedo", "porn", "suck", "suicid", "depres",
    "kontol", "kntl", "memek", "pepek", "jembut", "jmbt", "ngentot", "ngewe",
    "tetek", "toket", "lonte", "bokep", "perkosa", "anjing", "anjir", "bangsat",
    "brengsek", "bajingan", "goblok", "tolol", "jancok", "jancuk", "pantek", "puki"
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

-- Fungsi Bypass Natural:
-- Prioritas 1: Jika ada huruf 'l' kecil, ubah 1 huruf 'l' jadi 'I' besar (100% tidak terlihat bedanya di Roblox!)
-- Prioritas 2: Jika berakhiran -mu / -ku, tambahkan 'h' halus di ujung (misal: tubuhmuh)
-- Prioritas 3: Gandakan huruf konsonan/vokal terakhir saja (1 huruf)
local function naturalMinimalBypass(word)
    if #word < 3 then return word end
    local mode = math.clamp(tonumber(FilterModule.BypassMode) or 1, 1, 3)

    if mode == 2 then
        local mid = math.max(2, math.floor(#word / 2))
        return word:sub(1, mid) .. "'" .. word:sub(mid + 1)
    elseif mode == 3 then
        local mid = math.max(2, math.floor(#word / 2))
        return word:sub(1, mid) .. " " .. word:sub(mid + 1)
    end

    -- Prioritas 1: Ubah 'l' -> 'I' (Terlihat 100% murni di font Gotham Roblox)
    local lPos = word:find("l", 1, true)
    if lPos then
        return word:sub(1, lPos - 1) .. "I" .. word:sub(lPos + 1)
    end

    -- Prioritas 2: Jika berakhiran "mu" atau "ku", tambahkan "h" halus di paling belakang
    local lower = word:lower()
    if lower:sub(-2) == "mu" or lower:sub(-2) == "ku" then
        return word .. "h"
    end

    -- Prioritas 3: Sisipkan 1 'h' setelah vokal pertama
    for i = 1, #word - 1 do
        local ch = word:sub(i, i)
        if ch:match("[aiueoAIUEO]") then
            return word:sub(1, i) .. "h" .. word:sub(i + 1)
        end
    end

    return word .. word:sub(-1)
end

local function bypassWord(word)
    if #word < 2 then return word end
    local lower = word:lower()
    local mode = math.clamp(tonumber(FilterModule.BypassMode) or 1, 1, 3)

    if cleanBypassMap[lower] then
        return matchCase(word, cleanBypassMap[lower][mode])
    end

    if lower:find("fuck", 1, true) then
        local rep = (mode == 1 and "fuhq") or (mode == 2 and "fu'ck") or "fu ck"
        return word:gsub("[fF][uU][cC][kK]", function(m) return matchCase(m, rep) end)
    end

    if lower:find("suck", 1, true) then
        local rep = (mode == 1 and "suhq") or (mode == 2 and "su'ck") or "su ck"
        return word:gsub("[sS][uU][cC][kK]", function(m) return matchCase(m, rep) end)
    end

    return naturalMinimalBypass(word)
end

local function shouldBypassWord(word)
    local lowerWord = word:lower():gsub("'", "")
    if cleanBypassMap[lowerWord] then return true end

    for _, sub in ipairs(hardSubstrings) do
        if lowerWord:find(sub, 1, true) then
            return true
        end
    end

    return false
end

function FilterModule.Sanitize(text, enabled)
    if not text or text == "" or enabled == false then return text end

    local modifiedCount = 0

    local cleaned = text:gsub("([%a'*%-]+)", function(word)
        if word:find("%*") then
            modifiedCount += 1
            return bypassWord(word:gsub("%*", "u"))
        end

        if word:find("%-") then
            local parts = string.split(word, "-")
            for i, p in ipairs(parts) do
                if shouldBypassWord(p) then
                    parts[i] = bypassWord(p)
                    modifiedCount += 1
                end
            end
            return table.concat(parts, "-")
        end

        if shouldBypassWord(word) then
            modifiedCount += 1
            return bypassWord(word)
        end

        return word
    end)

    cleaned = cleaned:gsub("(%d)(%d)", "%1 %2"):gsub("(%d)(%d)", "%1 %2")
    return cleaned
end

return FilterModule
