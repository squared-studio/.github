#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1

progress() {
    local width=24
    local percent=100
    local filled=$width
    local bar=""
    local position

    if (( $2 > 0 )); then
        percent=$(( $1 * 100 / $2 ))
        filled=$(( percent * width / 100 ))
    fi

    for ((position = 0; position < width; position++)); do
        if (( position < filled )); then
            bar+="#"
        else
            bar+="-"
        fi
    done

    if [[ -t 2 ]]; then
        printf '\r\033[K[%s] %3d%% (%s/%s) %s' "${bar}" "${percent}" "$1" "$2" "$3" >&2
        if (( $1 >= $2 )); then
            printf '\n' >&2
        fi
    else
        printf '[%s] %3d%% (%s/%s) %s\n' "${bar}" "${percent}" "$1" "$2" "$3" >&2
    fi
}

js_escape() {
    printf '%s' "$1" | tr '\r\n\t' '   ' | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/  */ /g' -e 's/^ //; s/ $//'
}

html_escape() {
    printf '%s' "$1" | sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' -e 's/"/\&quot;/g'
}

ere_escape() {
    printf '%s' "$1" | sed -e 's/[.[\*^$()+?{|}\\]/\\&/g'
}

sed_repl_escape() {
    printf '%s' "$1" | sed -e 's/[&|\\]/\\&/g'
}

emit_h2_links() {
    local chapter_file="$1"
    awk -v file="${chapter_file}" '
    function strip_md_links(str,    pre, mid, rest, sep, inner) {
        while (match(str, /\[[^]]*\]\([^)]*\)/)) {
            pre = substr(str, 1, RSTART - 1)
            mid = substr(str, RSTART, RLENGTH)
            rest = substr(str, RSTART + RLENGTH)
            sep = index(mid, "](")
            inner = substr(mid, 2, sep - 2)
            str = pre inner rest
        }
        return str
    }
    function make_slug(str,    s) {
        s = strip_md_links(str)
        gsub(/[*`]/, "", s)
        s = tolower(s)
        gsub(/[^a-z0-9_ -]/, "", s)
        gsub(/ /, "-", s)
        if (s == "") s = "section"
        return s
    }
    BEGIN {
        in_fence = 0
        fence_char = ""
        fence_len = 0
    }
    {
        sub(/\r$/, "")
        if (!in_fence) {
            if (match($0, /^[ ]?[ ]?[ ]?(```+|~~~+)/)) {
                f = substr($0, RSTART, RLENGTH)
                gsub(/^ +/, "", f)
                in_fence = 1
                fence_char = substr(f, 1, 1)
                fence_len = length(f)
                next
            }
        } else {
            if (match($0, /^[ ]?[ ]?[ ]?(```+|~~~+)[ \t]*$/)) {
                f = substr($0, RSTART, RLENGTH)
                gsub(/[ \t]/, "", f)
                if (substr(f, 1, 1) == fence_char && length(f) >= fence_len) {
                    in_fence = 0
                    fence_char = ""
                    fence_len = 0
                }
            }
            next
        }

        if ($0 !~ /^##[ \t]+/) next

        raw = $0
        sub(/^##[ \t]+/, "", raw)
        sub(/[ \t]+#+[ \t]*$/, "", raw)
        gsub(/^[ \t]+|[ \t]+$/, "", raw)
        if (raw == "") next

        base = make_slug(raw)
        slug = base
        if (used[slug]) {
            n = seen[base]
            if (n < 1) n = 1
            while (used[base "-" n]) n++
            slug = base "-" n
            seen[base] = n + 1
        } else {
            seen[base] = 1
        }
        used[slug] = 1

        label = strip_md_links(raw)
        sub(/: .*/, "", label)
        gsub(/[*#`]/, "", label)
        gsub(/^[ \t]+|[ \t]+$/, "", label)
        if (label == "") label = slug
        gsub(/\[/, "\\[", label)
        gsub(/\]/, "\\]", label)

        printf "  - [%s](%s#%s)\n", label, file, slug
    }
    ' "${chapter_file}"
}

CONFIG_FILE="${SKILLVERSE_CONFIG:-config.json}"
JSON_BACKEND=""

SITE_TITLE="SkillVerse"
SITE_BRAND="Squared Studio"
COPYRIGHT_OWNER="squared-studio"
SITE_EYEBROW="Open-Source Engineering Curriculum"
SITE_TAGLINE=""
META_DESCRIPTION=""
OG_TITLE=""
OG_DESC_TEMPLATE="%s courses and %s chapters."
CONFIG_BASE_URL=""
SKILLVERSE_PATH="/SkillVerse/"
LOGO_PATH="logo.png"
GITHUB_URL=""
DRAFT_PREFIX="___"
DEFAULT_CATEGORY="other"

SITEMAP_ROOT_PAGES=()
CAT_IDS=()
CAT_TITLES=()
CAT_REGEXES=()
CFG_COURSE_KEYS=()
CFG_COURSE_CATS=()
CFG_COURSE_TITLES=()
CFG_COURSE_DESCS=()

detect_json_backend() {
    if command -v jq >/dev/null 2>&1 && jq --version >/dev/null 2>&1; then
        JSON_BACKEND="jq"
    elif command -v python >/dev/null 2>&1 && python -c "import json, sys" >/dev/null 2>&1; then
        JSON_BACKEND="python"
    elif command -v python3 >/dev/null 2>&1 && python3 -c "import json, sys" >/dev/null 2>&1; then
        JSON_BACKEND="python3"
    elif command -v node >/dev/null 2>&1 && node -e "process.exit(0)" >/dev/null 2>&1; then
        JSON_BACKEND="node"
    else
        printf 'Error: A JSON tool (jq, python, python3, or node) is required to read %s\n' "${CONFIG_FILE}" >&2
        return 1
    fi
}

json_emit_site_tsv() {
    case "${JSON_BACKEND}" in
        jq)
            jq -r '
              (.site // {}) as $s |
              [
                ["title", ($s.title // "SkillVerse")],
                ["brand", ($s.brand // "Squared Studio")],
                ["copyright_owner", ($s.copyright_owner // "squared-studio")],
                ["eyebrow", ($s.eyebrow // "Open-Source Engineering Curriculum")],
                ["tagline", ($s.tagline // "")],
                ["meta_description", ($s.meta_description // "")],
                ["og_title", ($s.og_title // "")],
                ["og_description_template", ($s.og_description_template // "%s courses and %s chapters.")],
                ["base_url", ($s.base_url // "")],
                ["skillverse_path", ($s.skillverse_path // "/SkillVerse/")],
                ["logo", ($s.logo // "logo.png")],
                ["github_url", ($s.github_url // "")],
                ["draft_prefix", ($s.draft_prefix // "___")],
                ["default_category", ($s.default_category // "other")]
              ][] | "\(.[0])\t\(.[1] | tostring | gsub("[\r\n\t]+"; " "))"
            ' "${CONFIG_FILE}" | tr -d '\r' ;;
        python|python3)
            "${JSON_BACKEND}" -c '
import json, re, sys
with open(sys.argv[1], "r", encoding="utf-8") as f:
    data = json.load(f)
s = data.get("site") or {}
defaults = [
    ("title", "SkillVerse"),
    ("brand", "Squared Studio"),
    ("copyright_owner", "squared-studio"),
    ("eyebrow", "Open-Source Engineering Curriculum"),
    ("tagline", ""),
    ("meta_description", ""),
    ("og_title", ""),
    ("og_description_template", "%s courses and %s chapters."),
    ("base_url", ""),
    ("skillverse_path", "/SkillVerse/"),
    ("logo", "logo.png"),
    ("github_url", ""),
    ("draft_prefix", "___"),
    ("default_category", "other"),
]
for k, d in defaults:
    v = s.get(k, d)
    if v is None:
        v = d
    v_str = re.sub(r"[\r\n\t]+", " ", str(v))
    print(f"{k}\t{v_str}")
' "${CONFIG_FILE}" | tr -d '\r' ;;
        node)
            node -e '
const fs = require("fs");
const data = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
const s = data.site || {};
const defaults = [
  ["title", "SkillVerse"],
  ["brand", "Squared Studio"],
  ["copyright_owner", "squared-studio"],
  ["eyebrow", "Open-Source Engineering Curriculum"],
  ["tagline", ""],
  ["meta_description", ""],
  ["og_title", ""],
  ["og_description_template", "%s courses and %s chapters."],
  ["base_url", ""],
  ["skillverse_path", "/SkillVerse/"],
  ["logo", "logo.png"],
  ["github_url", ""],
  ["draft_prefix", "___"],
  ["default_category", "other"],
];
for (const [k, d] of defaults) {
  const raw = s[k] === undefined || s[k] === null ? d : s[k];
  const v = String(raw).replace(/[\r\n\t]+/g, " ");
  process.stdout.write(k + "\t" + v + "\n");
}
' "${CONFIG_FILE}" | tr -d '\r' ;;
    esac
}

json_emit_sitemap_pages() {
    case "${JSON_BACKEND}" in
        jq)
            jq -r '(.site.sitemap_root_pages // [])[] | tostring | gsub("[\r\n\t]+"; "")' "${CONFIG_FILE}" | tr -d '\r' ;;
        python|python3)
            "${JSON_BACKEND}" -c '
import json, re, sys
with open(sys.argv[1], "r", encoding="utf-8") as f:
    data = json.load(f)
for p in (data.get("site") or {}).get("sitemap_root_pages") or []:
    print(re.sub(r"[\r\n\t]+", "", str(p)))
' "${CONFIG_FILE}" | tr -d '\r' ;;
        node)
            node -e '
const fs = require("fs");
const data = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
const pages = (data.site && Array.isArray(data.site.sitemap_root_pages)) ? data.site.sitemap_root_pages : [];
for (const p of pages) {
  process.stdout.write(String(p).replace(/[\r\n\t]+/g, "") + "\n");
}
' "${CONFIG_FILE}" | tr -d '\r' ;;
    esac
}

json_emit_categories_tsv() {
    case "${JSON_BACKEND}" in
        jq)
            jq -r '
              (.categories // [])[] |
              (
                (.keywords // [])
                | map(
                    tostring
                    | gsub("[\r\n\t]+"; "")
                    | select(length > 0)
                    | explode
                    | map(if (. == 46 or . == 91 or . == 93 or . == 92 or . == 94 or . == 36 or . == 42 or . == 43 or . == 63 or . == 40 or . == 41 or . == 123 or . == 125 or . == 124) then [92, .] else [.] end)
                    | add
                    | implode
                  )
                | join("|")
              ) as $rx |
              "\(.id | tostring | gsub("[\r\n\t]+"; ""))\t\(.title // .id | tostring | gsub("[\r\n\t]+"; " "))\t\($rx)"
            ' "${CONFIG_FILE}" | tr -d '\r' ;;
        python|python3)
            "${JSON_BACKEND}" -c '
import json, re, sys
with open(sys.argv[1], "r", encoding="utf-8") as f:
    data = json.load(f)
for c in data.get("categories") or []:
    cid = re.sub(r"[\r\n\t]+", "", str(c.get("id", "")))
    title = re.sub(r"[\r\n\t]+", " ", str(c.get("title", cid)))
    kws = [re.sub(r"([.\[\]\\^$*+?(){}|])", r"\\\1", re.sub(r"[\r\n\t]+", "", str(k))) for k in (c.get("keywords") or []) if str(k)]
    rx = "|".join(kws)
    print(f"{cid}\t{title}\t{rx}")
' "${CONFIG_FILE}" | tr -d '\r' ;;
        node)
            node -e '
const fs = require("fs");
const data = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
for (const c of (Array.isArray(data.categories) ? data.categories : [])) {
  const cid = String(c.id || "").replace(/[\r\n\t]+/g, "");
  const title = String(c.title || cid).replace(/[\r\n\t]+/g, " ");
  const kws = Array.isArray(c.keywords) ? c.keywords.map(k => String(k).replace(/[\r\n\t]+/g, "").replace(/[.\\\[\]^$*+?(){}|]/g, "\\$&")).filter(Boolean) : [];
  process.stdout.write(cid + "\t" + title + "\t" + kws.join("|") + "\n");
}
' "${CONFIG_FILE}" | tr -d '\r' ;;
    esac
}

json_emit_courses_tsv() {
    case "${JSON_BACKEND}" in
        jq)
            jq -r --arg def "${DEFAULT_CATEGORY}" '
              (.courses // {}) | to_entries[] |
              "\(.key | tostring | gsub("[\r\n\t]+"; ""))\t\(.value.cat // $def | tostring | gsub("[\r\n\t]+"; ""))\t\(.value.title // .key | tostring | gsub("[\r\n\t]+"; " "))\t\(.value.desc // "" | tostring | gsub("[\r\n\t]+"; " "))"
            ' "${CONFIG_FILE}" | tr -d '\r' ;;
        python|python3)
            "${JSON_BACKEND}" -c '
import json, re, sys
with open(sys.argv[1], "r", encoding="utf-8") as f:
    data = json.load(f)
default_cat = sys.argv[2]
for k, v in (data.get("courses") or {}).items():
    k_s = re.sub(r"[\r\n\t]+", "", str(k))
    cat = re.sub(r"[\r\n\t]+", "", str((v or {}).get("cat") or default_cat))
    title = re.sub(r"[\r\n\t]+", " ", str((v or {}).get("title") or k_s))
    desc = re.sub(r"[\r\n\t]+", " ", str((v or {}).get("desc") or ""))
    print(f"{k_s}\t{cat}\t{title}\t{desc}")
' "${CONFIG_FILE}" "${DEFAULT_CATEGORY}" | tr -d '\r' ;;
        node)
            node -e '
const fs = require("fs");
const data = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
const defCat = process.argv[2];
for (const [k, v] of Object.entries(data.courses || {})) {
  const ks = String(k).replace(/[\r\n\t]+/g, "");
  const cat = String((v && v.cat) || defCat).replace(/[\r\n\t]+/g, "");
  const title = String((v && v.title) || ks).replace(/[\r\n\t]+/g, " ");
  const desc = String((v && v.desc) || "").replace(/[\r\n\t]+/g, " ");
  process.stdout.write(ks + "\t" + cat + "\t" + title + "\t" + desc + "\n");
}
' "${CONFIG_FILE}" "${DEFAULT_CATEGORY}" | tr -d '\r' ;;
    esac
}

load_config() {
    if [[ ! -f "${CONFIG_FILE}" ]]; then
        printf 'Error: Config file %s not found.\n' "${CONFIG_FILE}" >&2
        return 1
    fi
    detect_json_backend || return 1

    local k v
    while IFS=$'\t' read -r k v; do
        [[ -z "${k}" ]] && continue
        case "${k}" in
            title) SITE_TITLE="${v}" ;;
            brand) SITE_BRAND="${v}" ;;
            copyright_owner) COPYRIGHT_OWNER="${v}" ;;
            eyebrow) SITE_EYEBROW="${v}" ;;
            tagline) SITE_TAGLINE="${v}" ;;
            meta_description) META_DESCRIPTION="${v}" ;;
            og_title) OG_TITLE="${v}" ;;
            og_description_template) OG_DESC_TEMPLATE="${v}" ;;
            base_url) CONFIG_BASE_URL="${v}" ;;
            skillverse_path) SKILLVERSE_PATH="${v}" ;;
            logo) LOGO_PATH="${v}" ;;
            github_url) GITHUB_URL="${v}" ;;
            draft_prefix) DRAFT_PREFIX="${v}" ;;
            default_category) DEFAULT_CATEGORY="${v}" ;;
        esac
    done < <(json_emit_site_tsv)

    SITEMAP_ROOT_PAGES=()
    local page
    while IFS= read -r page; do
        [[ -n "${page}" ]] && SITEMAP_ROOT_PAGES+=("${page}")
    done < <(json_emit_sitemap_pages)

    CAT_IDS=()
    CAT_TITLES=()
    CAT_REGEXES=()
    local cid ctitle crx
    while IFS=$'\t' read -r cid ctitle crx; do
        [[ -z "${cid}" ]] && continue
        CAT_IDS+=("${cid}")
        CAT_TITLES+=("${ctitle}")
        CAT_REGEXES+=("${crx}")
    done < <(json_emit_categories_tsv)

    CFG_COURSE_KEYS=()
    CFG_COURSE_CATS=()
    CFG_COURSE_TITLES=()
    CFG_COURSE_DESCS=()
    local ckey ccat cdtitle cddesc
    while IFS=$'\t' read -r ckey ccat cdtitle cddesc; do
        [[ -z "${ckey}" ]] && continue
        CFG_COURSE_KEYS+=("${ckey}")
        CFG_COURSE_CATS+=("${ccat}")
        CFG_COURSE_TITLES+=("${cdtitle}")
        CFG_COURSE_DESCS+=("${cddesc}")
    done < <(json_emit_courses_tsv)
}

get_configured_course_meta() {
    local target="$1" idx
    for ((idx = 0; idx < ${#CFG_COURSE_KEYS[@]}; idx++)); do
        if [[ "${CFG_COURSE_KEYS[$idx]}" == "${target}" ]]; then
            printf '%s\t%s\t%s\n' "${CFG_COURSE_CATS[$idx]}" "${CFG_COURSE_TITLES[$idx]}" "${CFG_COURSE_DESCS[$idx]}"
            return 0
        fi
    done
    return 1
}

register_course_in_config() {
    local c_key="$1" c_cat="$2" c_title="$3" c_desc="$4"
    local tmp_cfg
    tmp_cfg=$(mktemp ".update_cfg.XXXXXX")

    case "${JSON_BACKEND}" in
        jq)
            if ! jq --arg k "${c_key}" --arg cat "${c_cat}" --arg title "${c_title}" --arg desc "${c_desc}" \
                '.courses = (.courses // {}) | .courses[$k] = {cat: $cat, title: $title, desc: $desc}' \
                "${CONFIG_FILE}" | tr -d '\r' > "${tmp_cfg}"; then
                rm -f "${tmp_cfg}"
                return 1
            fi ;;
        python|python3)
            if ! "${JSON_BACKEND}" -c '
import json, sys
cfg_path, k, cat, title, desc, out_path = sys.argv[1:7]
with open(cfg_path, "r", encoding="utf-8") as f:
    data = json.load(f)
courses = data.setdefault("courses", {})
courses[k] = {"cat": cat, "title": title, "desc": desc}
with open(out_path, "w", encoding="utf-8", newline="\n") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write("\n")
' "${CONFIG_FILE}" "${c_key}" "${c_cat}" "${c_title}" "${c_desc}" "${tmp_cfg}"; then
                rm -f "${tmp_cfg}"
                return 1
            fi ;;
        node)
            if ! node -e '
const fs = require("fs");
const [cfgPath, k, cat, title, desc, outPath] = process.argv.slice(1);
const data = JSON.parse(fs.readFileSync(cfgPath, "utf8"));
if (!data.courses || typeof data.courses !== "object") data.courses = {};
data.courses[k] = { cat, title, desc };
fs.writeFileSync(outPath, JSON.stringify(data, null, 2) + "\n", "utf8");
' "${CONFIG_FILE}" "${c_key}" "${c_cat}" "${c_title}" "${c_desc}" "${tmp_cfg}"; then
                rm -f "${tmp_cfg}"
                return 1
            fi ;;
    esac

    mv "${tmp_cfg}" "${CONFIG_FILE}"
    CFG_COURSE_KEYS+=("${c_key}")
    CFG_COURSE_CATS+=("${c_cat}")
    CFG_COURSE_TITLES+=("${c_title}")
    CFG_COURSE_DESCS+=("${c_desc}")
}

get_base_url() {
    local cname_val=""
    if [[ -f "../CNAME" ]]; then
        cname_val=$(tr -d '\r\n ' < ../CNAME 2>/dev/null)
    fi
    if [[ -n "${cname_val}" ]]; then
        if [[ "${cname_val}" == http://* || "${cname_val}" == https://* ]]; then
            printf '%s\n' "${cname_val%/}"
        else
            printf 'https://%s\n' "${cname_val%/}"
        fi
    else
        printf '%s\n' "${CONFIG_BASE_URL%/}"
    fi
}

get_skillverse_path() {
    local p="${SKILLVERSE_PATH:-/SkillVerse/}"
    [[ "${p}" != /* ]] && p="/${p}"
    [[ "${p}" != */ ]] && p="${p}/"
    printf '%s\n' "${p}"
}

infer_course_meta() {
    local dir="$1"
    local raw_title
    raw_title=$(printf '%s' "${dir}" | sed -e 's/_/ /g' -e 's/  */ /g' -e 's/^ //; s/ $//')

    local headings=""
    local chap h
    while IFS= read -r chap; do
        [[ -z "${chap}" ]] && continue
        h=$(grep -m 1 "^# " "${chap}" 2>/dev/null | sed -e 's/^#[[:space:]]*//' -e 's/^[Cc][Hh][Aa][Pp][Tt][Ee][Rr][[:space:]]\{1,\}[0-9]\{1,\}:[[:space:]]*//' -e 's/[*_`#]//g' -e 's/_/ /g' -e 's/\r$//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        [[ -n "${h}" ]] && headings+="${h}"$'\n'
    done < <(find "${dir}" -mindepth 1 -maxdepth 1 -type f -name "chapter_*.md" | sort)

    local corpus
    corpus=$(printf '%s %s' "${raw_title}" "${headings}" | tr '\n' ' ' | tr '[:upper:]' '[:lower:]')

    local cat="${DEFAULT_CATEGORY}"
    local idx rx
    for ((idx = 0; idx < ${#CAT_IDS[@]}; idx++)); do
        rx="${CAT_REGEXES[$idx]}"
        [[ -z "${rx}" ]] && continue
        if printf '%s\n' "${corpus}" | grep -Eq "(^|[^a-z])(${rx})([^a-z]|$)"; then
            cat="${CAT_IDS[$idx]}"
            break
        fi
    done

    local joined=""
    local count=0
    while IFS= read -r h; do
        [[ -z "${h}" ]] && continue
        h="${h%.}"
        if [[ -z "${joined}" ]]; then
            joined="${h}"
            count=$((count + 1))
        elif (( ${#joined} + ${#h} + 2 <= 130 )); then
            joined="${joined}, ${h}"
            count=$((count + 1))
        else
            break
        fi
        (( count >= 4 )) && break
    done <<< "${headings}"

    local raw_desc
    if [[ -n "${joined}" ]]; then
        raw_desc="Covers ${joined}."
    else
        raw_desc="Structured chapters and practical notes on ${raw_title}."
    fi

    printf '%s\t%s\t%s\n' "${cat}" "$(printf '%s' "${raw_title}" | tr '\r\n\t' '   ')" "$(printf '%s' "${raw_desc}" | tr '\r\n\t' '   ')"
}

format_catalog_entry() {
    local key="$1" cat="$2" chaps="$3" title="$4" desc="$5"
    local key_repr
    if printf '%s\n' "${key}" | grep -Eq '^[A-Za-z_][A-Za-z0-9_]*$'; then
        key_repr="${key}"
    else
        key_repr="\"$(js_escape "${key}")\""
    fi
    printf '    %s: { cat: "%s", chapters: %s, title: "%s", desc: "%s" }' \
        "${key_repr}" "$(js_escape "${cat}")" "${chaps}" "$(js_escape "${title}")" "$(js_escape "${desc}")"
}

update_index_html() {
    local html_path="index.html"

    local year
    year=$(date +%Y)

    local public_base_url sv_path public_sv_url og_desc theme_slug
    public_base_url=$(get_base_url)
    sv_path=$(get_skillverse_path)
    public_sv_url="${public_base_url}${sv_path}"
    theme_slug=$(printf '%s' "${SITE_TITLE}" | tr '[:upper:]' '[:lower:]' | sed -e 's/[^a-z0-9]/-/g' -e 's/-\{2,\}/-/g' -e 's/^-//' -e 's/-$//')
    [[ -z "${theme_slug}" ]] && theme_slug="skillverse"

    local tmp_existing tmp_cats tmp_entries tmp_html
    tmp_existing=$(mktemp ".update_existing.XXXXXX")
    tmp_cats=$(mktemp ".update_cats.XXXXXX")
    tmp_entries=$(mktemp ".update_entries.XXXXXX")
    tmp_html=$(mktemp ".update_html.XXXXXX")

    if [[ -f "${html_path}" ]]; then
        awk '
        function extract_js_str(line, field,    pat, rest, q, i, ch, esc, out) {
            pat = "(^|[{,[:space:]])" field "[[:space:]]*:[[:space:]]*[\"\047]"
            if (!match(line, pat)) return ""
            q = substr(line, RSTART + RLENGTH - 1, 1)
            rest = substr(line, RSTART + RLENGTH)
            out = ""
            esc = 0
            for (i = 1; i <= length(rest); i++) {
                ch = substr(rest, i, 1)
                if (esc) {
                    if ((q == "\047" && ch == "\047") || (q == "\"" && ch == "\"")) {
                        out = out ch
                    } else if (ch == "\\") {
                        out = out "\\"
                    } else {
                        out = out ch
                    }
                    esc = 0
                } else if (ch == "\\") {
                    esc = 1
                } else if (ch == q) {
                    return out
                } else {
                    out = out ch
                }
            }
            return ""
        }
        BEGIN { in_cat = 0 }
        /const[[:space:]]+COURSE_CATALOG[[:space:]]*=[[:space:]]*\{/ {
            in_cat = 1
            next
        }
        in_cat && /^[[:space:]]*\}[[:space:]]*;/ {
            in_cat = 0
            exit
        }
        in_cat {
            sub(/\r$/, "")
            if (match($0, /^[[:space:]]*["\047]?[^"\047:[:space:]]+["\047]?[[:space:]]*:[[:space:]]*\{/)) {
                key = substr($0, RSTART, RLENGTH)
                sub(/^[[:space:]]*/, "", key)
                sub(/[[:space:]]*:[[:space:]]*\{$/, "", key)
                gsub(/^["\047]|["\047]$/, "", key)
                cat = extract_js_str($0, "cat")
                title = extract_js_str($0, "title")
                desc = extract_js_str($0, "desc")
                if (key != "" && cat != "" && title != "" && desc != "") {
                    printf "%s\t%s\t%s\t%s\n", key, cat, title, desc
                }
            }
        }
        ' "${html_path}" > "${tmp_existing}"
    else
        : > "${tmp_existing}"
    fi

    local active_dirs=()
    local active_chaps=()
    local active_emitted=()
    local active_course_count=0
    local active_chapter_count=0
    local dir chap_cnt
    while IFS= read -r dir; do
        [[ -z "${dir}" ]] && continue
        [[ -n "${DRAFT_PREFIX}" && "${dir}" == "${DRAFT_PREFIX}"* ]] && continue
        chap_cnt=$(find "${dir}" -mindepth 1 -maxdepth 1 -type f -name "chapter_*.md" | wc -l | tr -d '[:space:]')
        active_dirs+=("${dir}")
        active_chaps+=("${chap_cnt}")
        active_emitted+=(0)
        active_course_count=$((active_course_count + 1))
        active_chapter_count=$((active_chapter_count + chap_cnt))
    done <<< "${LIST}"

    local catalog_lines=()
    local idx cfg_idx cfg_dir meta_line m_cat m_title m_desc
    local ex_key ex_cat ex_title ex_desc found_existing

    # Emit courses present on disk in config.json key order
    for ((cfg_idx = 0; cfg_idx < ${#CFG_COURSE_KEYS[@]}; cfg_idx++)); do
        cfg_dir="${CFG_COURSE_KEYS[$cfg_idx]}"
        for ((idx = 0; idx < ${#active_dirs[@]}; idx++)); do
            if [[ "${active_dirs[$idx]}" == "${cfg_dir}" && "${active_emitted[$idx]}" -eq 0 ]]; then
                catalog_lines+=("$(format_catalog_entry "${cfg_dir}" "${CFG_COURSE_CATS[$cfg_idx]}" "${active_chaps[$idx]}" "${CFG_COURSE_TITLES[$cfg_idx]}" "${CFG_COURSE_DESCS[$cfg_idx]}")")
                active_emitted[$idx]=1
                break
            fi
        done
    done

    # Auto-register and emit any active directories not yet in config.json
    for ((idx = 0; idx < ${#active_dirs[@]}; idx++)); do
        if [[ "${active_emitted[$idx]}" -eq 0 ]]; then
            dir="${active_dirs[$idx]}"
            found_existing=0
            if [[ -s "${tmp_existing}" ]]; then
                while IFS=$'\t' read -r ex_key ex_cat ex_title ex_desc; do
                    if [[ "${ex_key}" == "${dir}" ]]; then
                        m_cat="${ex_cat}"
                        m_title="${ex_title}"
                        m_desc="${ex_desc}"
                        found_existing=1
                        break
                    fi
                done < "${tmp_existing}"
            fi
            if [[ "${found_existing}" -eq 0 ]]; then
                meta_line=$(infer_course_meta "${dir}")
                IFS=$'\t' read -r m_cat m_title m_desc <<< "${meta_line}"
            fi
            register_course_in_config "${dir}" "${m_cat}" "${m_title}" "${m_desc}" || true
            catalog_lines+=("$(format_catalog_entry "${dir}" "${m_cat}" "${active_chaps[$idx]}" "${m_title}" "${m_desc}")")
            active_emitted[$idx]=1
        fi
    done

    : > "${tmp_cats}"
    local cat_line
    for ((idx = 0; idx < ${#CAT_IDS[@]}; idx++)); do
        cat_line=$(printf '    { id: "%s", title: "%s" }' "$(js_escape "${CAT_IDS[$idx]}")" "$(js_escape "${CAT_TITLES[$idx]}")")
        if (( idx < ${#CAT_IDS[@]} - 1 )); then
            printf '%s,\n' "${cat_line}" >> "${tmp_cats}"
        else
            printf '%s\n' "${cat_line}" >> "${tmp_cats}"
        fi
    done

    : > "${tmp_entries}"
    for ((idx = 0; idx < ${#catalog_lines[@]}; idx++)); do
        if (( idx < ${#catalog_lines[@]} - 1 )); then
            printf '%s,\n' "${catalog_lines[$idx]}" >> "${tmp_entries}"
        else
            printf '%s\n' "${catalog_lines[$idx]}" >> "${tmp_entries}"
        fi
    done

    printf -v og_desc "${OG_DESC_TEMPLATE}" "${active_course_count}" "${active_chapter_count}"

    if {
        cat <<'SV_HTML_PART1'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
SV_HTML_PART1
        printf '  <meta name="description" content="%s" />\n' "$(html_escape "${META_DESCRIPTION}")"
        printf '  <meta property="og:title" content="%s" />\n' "$(html_escape "${OG_TITLE}")"
        printf '  <meta property="og:description" content="%s" />\n' "$(html_escape "${og_desc}")"
        cat <<'SV_HTML_PART2'
  <meta property="og:type" content="website" />
SV_HTML_PART2
        printf '  <meta property="og:url" content="%s" />\n' "$(html_escape "${public_sv_url}")"
        printf '  <meta property="og:image" content="%s%s" />\n' "$(html_escape "${public_sv_url}")" "$(html_escape "${LOGO_PATH}")"
        printf '  <meta name="twitter:card" content="summary" />\n'
        printf '  <title>%s — %s</title>\n' "$(html_escape "${SITE_TITLE}")" "$(html_escape "${SITE_BRAND}")"
        printf '  <link rel="icon" type="image/png" href="%s" />\n' "$(html_escape "${LOGO_PATH}")"
        cat <<'SV_HTML_PART2B'
  <link rel="preconnect" href="https://fonts.googleapis.com" />
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&amp;family=Roboto+Mono:wght@400;500;600&amp;display=swap" rel="stylesheet" />
  <link id="hljs-theme" rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.11.1/styles/github-dark.min.css" />
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/katex@0.16.22/dist/katex.min.css" />
  <script src="https://cdn.jsdelivr.net/npm/marked/marked.min.js"></script>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.11.1/highlight.min.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/katex@0.16.22/dist/katex.min.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/katex@0.16.22/dist/contrib/auto-render.min.js"></script>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.11.1/languages/verilog.min.js"></script>
  <style>
    *,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
    :root{
      color-scheme:dark;
      --bg:#080808;--surface:#0f0f0f;--card:#111418;--border:#1e2d4a;
      --text:#cdd9f0;--muted:#7890b2;--accent1:#00ccff;--accent2:#00ffcc;
      --accent1-soft:rgba(0,204,255,.08);--accent1-border:rgba(0,204,255,.25);
      --accent2-soft:rgba(0,255,204,.07);--accent2-border:rgba(0,255,204,.25);
      --nav-bg:rgba(8,12,24,.88);
      --hero-bg:linear-gradient(135deg,rgba(17,20,24,.95) 0%,rgba(12,18,28,.9) 100%);
      --hero-heading-start:#ffffff;
      --table-stripe:rgba(255,255,255,.02);
      --modal-backdrop:rgba(4,6,10,.78);
      --font-body:"Inter",sans-serif;--font-mono:"Consolas","Roboto Mono","SFMono-Regular","Menlo","Liberation Mono",monospace;
    }
    [data-theme="light"]{
      color-scheme:light;
      --bg:#f8fafc;--surface:#f1f5f9;--card:#ffffff;--border:#cbd5e1;
      --text:#0f172a;--muted:#475569;--accent1:#0284c7;--accent2:#0d9488;
      --accent1-soft:rgba(2,132,199,.08);--accent1-border:rgba(2,132,199,.28);
      --accent2-soft:rgba(13,148,136,.08);--accent2-border:rgba(13,148,136,.28);
      --nav-bg:rgba(248,250,252,.9);
      --hero-bg:linear-gradient(135deg,rgba(255,255,255,.98) 0%,rgba(241,245,249,.95) 100%);
      --hero-heading-start:#0f172a;
      --table-stripe:rgba(15,23,42,.03);
      --modal-backdrop:rgba(15,23,42,.45);
    }
    [data-theme="reading"]{
      color-scheme:light;
      --bg:#f4ecd8;--surface:#ebe0c5;--card:#faf4e6;--border:#d6c5a3;
      --text:#2c2216;--muted:#6e5a44;--accent1:#9a4b16;--accent2:#1e6091;
      --accent1-soft:rgba(154,75,22,.1);--accent1-border:rgba(154,75,22,.28);
      --accent2-soft:rgba(30,96,145,.09);--accent2-border:rgba(30,96,145,.28);
      --nav-bg:rgba(244,236,216,.92);
      --hero-bg:linear-gradient(135deg,rgba(250,244,230,.98) 0%,rgba(235,224,197,.95) 100%);
      --hero-heading-start:#2c2216;
      --table-stripe:rgba(44,34,22,.035);
      --modal-backdrop:rgba(44,34,22,.5);
    }
    html{scroll-behavior:smooth}
    body{background:var(--bg);color:var(--text);font-family:var(--font-body);font-size:16px;line-height:1.7;min-height:100vh}
    body::before{content:"";position:fixed;inset:0;background:radial-gradient(ellipse 60% 40% at 15% 10%,var(--accent1-soft) 0%,transparent 70%),radial-gradient(ellipse 50% 35% at 85% 85%,var(--accent2-soft) 0%,transparent 70%);pointer-events:none;z-index:0}
    [data-theme="reading"] body::before{opacity:0}
    a:focus-visible,button:focus-visible,summary:focus-visible,input:focus-visible{outline:2px solid var(--accent1);outline-offset:2px}
    .shell{position:relative;z-index:1;display:flex;flex-direction:column;min-height:100vh}

    /* ── NAV ── */
    nav{display:flex;align-items:center;gap:12px;min-height:61px;padding:12px 28px;border-bottom:1px solid var(--border);background:var(--nav-bg);backdrop-filter:blur(12px);position:sticky;top:0;z-index:100;flex-wrap:wrap}
    .nav-logo{display:flex;align-items:center;gap:10px;text-decoration:none;flex-shrink:0}
    .nav-icon{width:32px;height:32px;border-radius:8px;object-fit:contain;flex-shrink:0}
    .nav-shell{display:flex;align-items:center;gap:8px;flex:1;min-width:0;flex-wrap:wrap}
    .nav-title{font-size:1.08rem;font-weight:700;letter-spacing:-.01em;background:linear-gradient(90deg,var(--accent1),var(--accent2));-webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text;text-decoration:none}
    .nav-bc{display:flex;align-items:center;gap:6px;font-size:.78rem;color:var(--muted);min-width:0;flex-wrap:wrap}
    .nav-bc .sep{opacity:.5}
    .nav-bc .crumb{color:var(--accent2);font-family:var(--font-mono);font-size:.72rem}
    .nav-bc a.bc-link{color:var(--accent1);text-decoration:underline;text-underline-offset:2px}
    .nav-bc a.bc-link:hover{color:var(--accent2)}
    .nav-toggle{display:none;align-items:center;justify-content:center;flex-direction:column;gap:4px;width:40px;height:40px;margin-left:auto;border:1px solid var(--border);border-radius:10px;background:var(--surface);color:var(--text);cursor:pointer;transition:border-color .15s,background .15s;flex-shrink:0}
    .nav-toggle:hover{border-color:var(--accent1);background:var(--accent1-soft)}
    .nav-toggle-bar{display:block;width:18px;height:2px;border-radius:999px;background:currentColor;transition:transform .2s,opacity .2s}
    .nav-utils{display:flex;align-items:center;gap:10px;margin-left:auto;flex-shrink:0}
    .nav-search-btn{display:inline-flex;align-items:center;gap:8px;padding:6px 12px;border-radius:8px;border:1px solid var(--border);background:var(--surface);color:var(--muted);font-family:var(--font-body);font-size:.8rem;cursor:pointer;transition:border-color .15s,color .15s,background .15s}
    .nav-search-btn:hover{border-color:var(--accent1);color:var(--text);background:var(--accent1-soft)}
    .nav-search-btn kbd{font-family:var(--font-mono);font-size:.66rem;padding:1px 5px;border-radius:4px;border:1px solid var(--border);background:var(--card);color:var(--muted)}
    .nav-theme-btn{display:inline-flex;align-items:center;gap:6px;padding:6px 11px;border-radius:8px;border:1px solid var(--border);background:var(--accent1-soft);color:var(--text);font-family:var(--font-body);font-size:.8rem;font-weight:500;cursor:pointer;transition:border-color .15s,color .15s,background .15s;white-space:nowrap}
    .nav-theme-btn:hover{border-color:var(--accent1);color:var(--accent1)}
    .nav-theme-btn .theme-icon{font-size:.88rem;line-height:1}
    .nav-site-link{font-size:.8rem;font-weight:500;color:var(--muted);text-decoration:none;padding:6px 10px;border-radius:6px;transition:color .15s,background .15s;white-space:nowrap}
    .nav-site-link:hover{color:var(--accent1);background:var(--accent1-soft)}
    .nav-drawer{display:none}
    .nav-drawer-home{display:flex;align-items:center;justify-content:space-between;padding:9px 12px;border-radius:10px;border:1px solid var(--border);background:var(--surface);color:var(--text);text-decoration:none;font-size:.86rem;font-weight:600;transition:border-color .15s,background .15s,color .15s}
    .nav-drawer-home:hover,.nav-drawer-home.active{border-color:var(--accent1);background:var(--accent1-soft);color:var(--accent1)}
    .nav-cat-group{display:flex;flex-direction:column;gap:6px}
    .nav-cat-title{font-family:var(--font-mono);font-size:.66rem;letter-spacing:.12em;text-transform:uppercase;color:var(--accent2);padding:2px 2px 0}
    .nav-course{border:1px solid var(--border);border-radius:10px;background:var(--surface);overflow:hidden}
    .nav-course.active{border-color:var(--accent1-border)}
    .nav-course>summary{list-style:none;display:flex;align-items:center;gap:8px;padding:9px 12px;cursor:pointer;font-size:.85rem;font-weight:600;color:var(--text);user-select:none}
    .nav-course>summary::-webkit-details-marker{display:none}
    .nav-course.active>summary{color:var(--accent1);background:var(--accent1-soft)}
    .nav-course-name{flex:1;min-width:0;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
    .nav-course-count{font-family:var(--font-mono);font-size:.66rem;padding:2px 7px;border-radius:999px;background:var(--accent1-soft);color:var(--accent1);border:1px solid var(--accent1-border);white-space:nowrap;flex-shrink:0}
    .nav-course>summary::after{content:"\25B8";font-size:.72rem;color:var(--muted);transition:transform .15s;flex-shrink:0}
    .nav-course[open]>summary::after{transform:rotate(90deg);color:var(--accent1)}
    .nav-chap-list{display:flex;flex-direction:column;gap:2px;padding:6px 8px 8px;border-top:1px solid var(--border);background:var(--card)}
    .nav-chap-link{display:block;padding:7px 10px;border-radius:6px;font-size:.8rem;color:var(--muted);text-decoration:none;transition:background .15s,color .15s}
    .nav-chap-link:hover{background:var(--accent1-soft);color:var(--text)}
    .nav-chap-link.active{background:var(--accent1-soft);color:var(--accent1);font-weight:600}
    .nav-chap-status{padding:6px 10px;font-size:.76rem;color:var(--muted)}

    main{flex:1;max-width:920px;width:100%;margin:0 auto;padding:44px 28px 80px}
    .state{text-align:center;padding:80px 0;color:var(--muted)}
    .state .c{font-family:var(--font-mono);color:var(--accent1)}

    /* ── HOME CATALOG DASHBOARD ── */
    .catalog-hero{margin-bottom:32px;padding:28px;border:1px solid var(--border);border-radius:16px;background:var(--hero-bg);position:relative;overflow:hidden}
    .catalog-hero::before{content:"";position:absolute;inset:0;background:radial-gradient(ellipse 65% 75% at 100% 0%,var(--accent1-soft),transparent 65%);pointer-events:none}
    .catalog-eyebrow{font-family:var(--font-mono);font-size:.7rem;letter-spacing:.16em;text-transform:uppercase;color:var(--accent2);margin-bottom:8px}
    .catalog-hero h1{font-size:clamp(1.85rem,4vw,2.5rem);font-weight:800;letter-spacing:-.025em;line-height:1.15;background:linear-gradient(135deg,var(--hero-heading-start) 0%,var(--accent1) 55%,var(--accent2) 100%);-webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text;margin-bottom:10px}
    .catalog-sub{color:var(--muted);font-size:.94rem;max-width:640px;margin-bottom:18px}
    .catalog-controls{display:flex;align-items:center;justify-content:space-between;gap:14px;flex-wrap:wrap}
    .catalog-stats{display:flex;gap:10px;flex-wrap:wrap}
    .stat-pill{font-family:var(--font-mono);font-size:.72rem;padding:4px 11px;border-radius:999px;border:1px solid var(--accent1-border);background:var(--accent1-soft);color:var(--accent1)}
    .stat-pill.g{border-color:var(--accent2-border);background:var(--accent2-soft);color:var(--accent2)}
    .catalog-filter{flex:1;min-width:220px;max-width:320px;padding:8px 13px;border-radius:8px;border:1px solid var(--border);background:var(--surface);color:var(--text);font-family:var(--font-body);font-size:.86rem}
    .catalog-filter::placeholder{color:var(--muted)}
    .catalog-group{margin-bottom:34px}
    .catalog-group-title{font-family:var(--font-mono);font-size:.75rem;letter-spacing:.14em;text-transform:uppercase;color:var(--accent2);margin-bottom:14px;padding-bottom:8px;border-bottom:1px solid var(--border);display:flex;align-items:center;justify-content:space-between}
    .catalog-group-count{color:var(--muted);font-size:.7rem}
    .course-grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(250px,1fr));gap:14px}
    .course-card{display:flex;flex-direction:column;gap:8px;padding:18px 20px;border:1px solid var(--border);border-radius:12px;background:var(--card);text-decoration:none;color:inherit;transition:border-color .18s,transform .18s,box-shadow .18s}
    .course-card:hover{border-color:var(--accent1-border);transform:translateY(-2px);box-shadow:0 8px 28px var(--accent1-soft)}
    .course-card-top{display:flex;align-items:center;justify-content:space-between;gap:8px}
    .course-title{font-size:1rem;font-weight:700;color:var(--text)}
    .course-count{font-family:var(--font-mono);font-size:.68rem;padding:2px 8px;border-radius:999px;background:var(--accent1-soft);color:var(--accent1);border:1px solid var(--accent1-border);white-space:nowrap}
    .course-desc{font-size:.81rem;color:var(--muted);line-height:1.55}
    .catalog-empty{text-align:center;padding:42px 20px;border:1px dashed var(--border);border-radius:12px;color:var(--muted);font-size:.9rem}

    /* ── MARKDOWN BODY ── */
    .md h1{font-size:clamp(1.7rem,4vw,2.4rem);font-weight:700;letter-spacing:-.02em;margin-bottom:24px;background:linear-gradient(90deg,var(--accent1),var(--accent2));-webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text;line-height:1.2}
    .md h2{font-size:1.2rem;font-weight:600;color:var(--accent1);margin:36px 0 10px;padding-bottom:6px;border-bottom:1px solid var(--border);scroll-margin-top:80px}
    .md h3{font-size:1rem;font-weight:600;color:var(--accent2);margin:22px 0 6px;scroll-margin-top:80px}
    .md h4,.md h5,.md h6{font-size:.8rem;font-weight:500;color:var(--muted);margin:14px 0 4px;letter-spacing:.04em;text-transform:uppercase;border:none}
    .md p{margin-bottom:14px}
    .md a{color:var(--accent1);text-decoration:none;border-bottom:1px solid var(--accent1-border);transition:color .15s,border-color .15s}
    .md a:hover{color:var(--accent2);border-bottom-color:var(--accent2)}
    .md>ul{list-style:disc;padding-left:24px;margin:8px 0 20px}
    .md>ul>li{margin-bottom:6px;font-size:.95rem;color:var(--text)}
    .md>ul>li>h3{margin:0;font-size:.95rem;font-weight:600;color:var(--accent2);text-transform:none;letter-spacing:normal;border:none;display:inline}
    .md ul ul,.md ol{list-style:disc;padding-left:22px;margin-bottom:10px}
    .md ol{list-style:decimal}
    .md ul ul li,.md ol li{margin-bottom:3px;font-size:.9rem;color:var(--text)}
    .md ul ul li a,.md ol li a{display:inline;padding:0;font-weight:400;color:var(--accent1);border-bottom:1px solid var(--accent1-border)}
    .md code,.md pre,.md pre code,kbd{font-variant-ligatures:none;font-feature-settings:"liga" 0,"calt" 0}
    .md code{font-family:var(--font-mono);font-size:.85em;background:var(--accent1-soft);color:var(--accent2);padding:2px 6px;border-radius:4px}
    .md pre{background:var(--surface);border:1px solid var(--border);border-radius:10px;padding:20px;overflow-x:auto;margin:18px 0}
    .md pre code{background:none;padding:0;color:inherit;font-size:.83rem}
    .md pre code.hljs{background:transparent;padding:0}
    .md blockquote{border-left:3px solid var(--accent1);padding:10px 18px;margin:18px 0;background:var(--accent1-soft);border-radius:0 8px 8px 0;color:var(--muted);font-style:italic}
    .md hr{border:none;height:1px;background:linear-gradient(90deg,transparent,var(--border),transparent);margin:28px 0}
    .md table{width:100%;border-collapse:collapse;margin:18px 0;font-size:.86rem}
    .md th{text-align:left;padding:9px 13px;background:var(--surface);color:var(--accent1);border:1px solid var(--border);font-weight:600}
    .md td{padding:8px 13px;border:1px solid var(--border);color:var(--text)}
    .md tr:nth-child(even) td{background:var(--table-stripe)}
    .md img{max-width:100%;height:auto;display:block;margin:16px auto;border-radius:8px;border:1px solid var(--border)}
    [data-theme="light"] .md img{filter:invert(1)}
    [data-theme="reading"] .md img{filter:invert(1) sepia(.12) brightness(.98)}
    .code-wrap{position:relative}
    .copy-btn{position:absolute;top:10px;right:10px;background:var(--accent1-soft);color:var(--accent1);border:1px solid var(--accent1-border);border-radius:6px;padding:4px 10px;font-family:var(--font-mono);font-size:.72rem;cursor:pointer;opacity:0;transition:opacity .15s,background .15s,color .15s;line-height:1.6}
    .code-wrap:hover .copy-btn,.copy-btn:focus-visible{opacity:1}
    .copy-btn:hover{background:var(--accent1-border)}
    .copy-btn.copied{color:var(--accent2);border-color:var(--accent2-border);background:var(--accent2-soft)}

    /* ── CHAPTER TOC & PREV/NEXT NAV ── */
    .toc-box{margin:0 0 28px;border:1px solid var(--border);border-radius:12px;background:var(--card);padding:14px 18px}
    .toc-box summary{cursor:pointer;font-family:var(--font-mono);font-size:.76rem;letter-spacing:.08em;text-transform:uppercase;color:var(--accent2);font-weight:600;user-select:none}
    .toc-list{margin:12px 0 0 18px;display:grid;grid-template-columns:repeat(auto-fill,minmax(240px,1fr));gap:6px 18px;list-style:decimal}
    .toc-list li{font-size:.84rem;color:var(--muted)}
    .toc-list a{color:var(--text);text-decoration:none;border-bottom:1px solid transparent}
    .toc-list a:hover{color:var(--accent1);border-bottom-color:var(--accent1)}

    .chapter-nav{display:grid;grid-template-columns:1fr auto 1fr;gap:12px;margin-top:44px;padding-top:24px;border-top:1px solid var(--border);align-items:stretch}
    .chap-btn{display:flex;flex-direction:column;justify-content:center;gap:3px;padding:12px 16px;border-radius:10px;border:1px solid var(--border);background:var(--card);color:var(--text);text-decoration:none;transition:border-color .15s,background .15s}
    .chap-btn:hover{border-color:var(--accent1);background:var(--accent1-soft);color:var(--text)}
    .chap-btn.next{text-align:right;align-items:flex-end}
    .chap-btn.index{text-align:center;align-items:center;font-family:var(--font-mono);font-size:.76rem;color:var(--accent1)}
    .chap-btn.disabled{opacity:.38;pointer-events:none}
    .chap-dir{font-family:var(--font-mono);font-size:.68rem;letter-spacing:.08em;text-transform:uppercase;color:var(--accent2)}
    .chap-name{font-size:.85rem;font-weight:600;color:var(--text)}

    /* ── SEARCH MODAL ── */
    .search-modal{position:fixed;inset:0;z-index:200;background:var(--modal-backdrop);backdrop-filter:blur(6px);display:none;align-items:flex-start;justify-content:center;padding:72px 18px 24px}
    .search-modal.open{display:flex}
    .search-panel{width:100%;max-width:660px;background:var(--card);border:1px solid var(--border);border-radius:14px;box-shadow:0 24px 64px rgba(0,0,0,.4);overflow:hidden;display:flex;flex-direction:column;max-height:78vh}
    .search-head{display:flex;align-items:center;gap:10px;padding:14px 16px;border-bottom:1px solid var(--border);background:var(--surface)}
    .search-head input{flex:1;background:transparent;border:none;color:var(--text);font-family:var(--font-body);font-size:.95rem;outline:none}
    .search-head input::placeholder{color:var(--muted)}
    .search-close{background:transparent;border:1px solid var(--border);color:var(--muted);border-radius:6px;padding:3px 9px;font-family:var(--font-mono);font-size:.7rem;cursor:pointer}
    .search-close:hover{color:var(--text);border-color:var(--accent1)}
    .search-results{overflow-y:auto;padding:8px;display:flex;flex-direction:column;gap:4px}
    .search-status{padding:24px 16px;text-align:center;color:var(--muted);font-size:.86rem}
    .search-item{display:flex;flex-direction:column;gap:2px;padding:10px 12px;border-radius:8px;text-decoration:none;color:inherit;border:1px solid transparent}
    .search-item:hover,.search-item.active{background:var(--accent1-soft);border-color:var(--accent1-border)}
    .search-item-meta{font-family:var(--font-mono);font-size:.68rem;color:var(--accent2);display:flex;align-items:center;gap:8px}
    .search-item-title{font-size:.9rem;font-weight:600;color:var(--text)}

    footer{text-align:center;padding:20px 28px;border-top:1px solid var(--border);font-size:.76rem;color:var(--muted);position:relative;z-index:1}
    footer span{background:linear-gradient(90deg,var(--accent1),var(--accent2));-webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text;font-weight:600}
    footer .footer-links{display:flex;justify-content:center;flex-wrap:wrap;gap:18px;margin-bottom:8px}
    footer .footer-links a{color:var(--muted);text-decoration:none;font-size:.76rem;transition:color .15s}
    footer .footer-links a:hover{color:var(--accent1)}

    @media (hover:none),(max-width:640px){
      .copy-btn{opacity:1}
    }
    @media (max-width:640px){
      nav{padding:10px 16px}
      .nav-title{font-size:.98rem}
      .nav-bc{font-size:.72rem}
      .nav-toggle{display:inline-flex}
      .nav-utils{display:none;flex-direction:row;flex-wrap:wrap;gap:8px;width:100%;margin-left:0;padding-top:8px}
      nav.nav-open .nav-utils{display:flex}
      .nav-search-btn,.nav-theme-btn,.nav-site-link{flex:1;min-width:0;justify-content:center;text-align:center;padding:8px 10px}
      .nav-site-link{display:inline-flex;align-items:center;border:1px solid var(--border);border-radius:8px;background:var(--surface);color:var(--text)}
      .nav-search-btn kbd{display:none}
      nav.nav-open .nav-drawer{display:flex;flex-direction:column;gap:12px;width:100%;max-height:calc(100vh - 130px);overflow-y:auto;padding-top:10px;margin-top:4px;border-top:1px solid var(--border)}
      nav.nav-open .nav-toggle-bar:nth-child(1){transform:translateY(6px) rotate(45deg)}
      nav.nav-open .nav-toggle-bar:nth-child(2){opacity:0}
      nav.nav-open .nav-toggle-bar:nth-child(3){transform:translateY(-6px) rotate(-45deg)}
      main{padding:28px 18px 60px}
      .chapter-nav{grid-template-columns:1fr}
      .chap-btn.next{text-align:left;align-items:flex-start}
    }
  </style>
</head>
<body>
<div class="shell">
  <nav>
SV_HTML_PART2B
        printf '    <a class="nav-logo" id="studio-btn" href="../index.html" aria-label="%s home" title="Back to %s">\n' "$(html_escape "${SITE_BRAND}")" "$(html_escape "${SITE_BRAND}")"
        printf '      <img class="nav-icon" src="%s" alt="%s" />\n' "$(html_escape "${LOGO_PATH}")" "$(html_escape "${SITE_BRAND}")"
        cat <<'SV_HTML_PART2C'
    </a>
    <div class="nav-shell">
      <span class="nav-bc"><span class="sep">&gt;</span></span>
SV_HTML_PART2C
        printf '      <a class="nav-title" id="home-btn" href="#README.md">%s</a>\n' "$(html_escape "${SITE_TITLE}")"
        cat <<'SV_HTML_PART2D'
      <div class="nav-bc" id="breadcrumb"></div>
    </div>
    <button class="nav-toggle" id="nav-toggle" type="button" aria-expanded="false" aria-controls="nav-utils nav-drawer" aria-label="Toggle navigation">
      <span class="nav-toggle-bar"></span>
      <span class="nav-toggle-bar"></span>
      <span class="nav-toggle-bar"></span>
    </button>
    <div class="nav-utils" id="nav-utils">
SV_HTML_PART2D
        printf '      <button type="button" class="nav-search-btn" id="open-search" aria-label="Search %s">\n' "$(html_escape "${SITE_TITLE}")"
        cat <<'SV_HTML_PART2E'
        <span>&#128269; Search</span>
        <kbd>Ctrl K</kbd>
      </button>
      <button type="button" class="nav-theme-btn" id="theme-toggle" aria-label="Toggle color mode" title="Toggle Dark / Light / Reading mode">
        <span class="theme-icon" id="theme-icon" aria-hidden="true">&#127769;</span>
        <span class="theme-label" id="theme-label">Dark</span>
      </button>
      <a class="nav-site-link" href="../index.html">Main Site &#8599;</a>
    </div>
    <div class="nav-drawer" id="nav-drawer" aria-label="Courses and chapters navigation"></div>
  </nav>

  <main id="content"><div class="state">Loading&#8230;</div></main>

  <footer>
    <div class="footer-links">
      <a href="../index.html">Home</a>
      <a href="../about.html">About</a>
      <a href="../people.html">People</a>
      <a href="../contact.html">Contact</a>
SV_HTML_PART2E
        if [[ -n "${GITHUB_URL}" ]]; then
            printf '      <a href="%s" target="_blank" rel="noopener">GitHub</a>\n' "$(html_escape "${GITHUB_URL}")"
        fi
        cat <<'SV_HTML_PART2F'
    </div>
SV_HTML_PART2F
        printf '    <p>Copyright &copy; %s <span>%s</span></p>\n' "${year}" "$(html_escape "${COPYRIGHT_OWNER}")"
        cat <<'SV_HTML_PART3'
  </footer>
</div>

<div class="search-modal" id="search-modal" role="dialog" aria-modal="true" aria-labelledby="search-input">
  <div class="search-panel">
    <div class="search-head">
      <span aria-hidden="true">&#128269;</span>
      <input type="search" id="search-input" placeholder="Search courses, chapters, and sections&#8230;" autocomplete="off" />
      <button type="button" class="search-close" id="close-search">Esc</button>
    </div>
    <div class="search-results" id="search-results">
      <div class="search-status">Type to search across all courses, chapters, and sections&#8230;</div>
    </div>
  </div>
</div>

<script>
(function () {
  "use strict";

  const HOME = "README.md";
  const VIEW_ROOT = new URL("./", location.href);
SV_HTML_PART3
        printf '  const THEME_STORAGE_KEY = "%s-theme";\n' "$(js_escape "${theme_slug}")"
        printf '  const SITE_CFG = {\n'
        printf '    title: "%s",\n' "$(js_escape "${SITE_TITLE}")"
        printf '    brand: "%s",\n' "$(js_escape "${SITE_BRAND}")"
        printf '    copyrightOwner: "%s",\n' "$(js_escape "${COPYRIGHT_OWNER}")"
        printf '    eyebrow: "%s",\n' "$(js_escape "${SITE_EYEBROW}")"
        printf '    tagline: "%s",\n' "$(js_escape "${SITE_TAGLINE}")"
        printf '    defaultCategory: "%s"\n' "$(js_escape "${DEFAULT_CATEGORY}")"
        printf '  };\n'
        cat <<'SV_HTML_PART3B'
  const THEME_MODES = [
    { id: "dark", label: "Dark", icon: "\uD83C\uDF19", hljs: "https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.11.1/styles/github-dark.min.css" },
    { id: "light", label: "Light", icon: "\u2600\uFE0F", hljs: "https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.11.1/styles/github.min.css" },
    { id: "reading", label: "Reading", icon: "\uD83D\uDCD6", hljs: "https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.11.1/styles/github.min.css" }
  ];
  let currentThemeIndex = 0;
  const mdCache = new Map();
  const topicChaptersCache = new Map();
  let searchEntries = null;
  let searchBuildPromise = null;
  let activeLoadId = 0;
  let activeController = null;
  let pendingSectionText = null;
  let pendingAnchor = null;
  let activeResultIndex = -1;

  const CATEGORIES = [
SV_HTML_PART3B
        cat "${tmp_cats}"
        cat <<'SV_HTML_PART3C'
  ];

  const COURSE_CATALOG = {
SV_HTML_PART3C
        cat "${tmp_entries}"
        cat <<'SV_HTML_PART4'
  };

  marked.setOptions({ gfm: true, breaks: false });

  if (window.hljs && hljs.getLanguage("verilog")) {
    hljs.registerAliases(["systemverilog", "sv"], { languageName: "verilog" });
  }

  function escapeHtml(str) {
    return String(str)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;");
  }

  function isEscaped(str, idx) {
    let bs = 0;
    for (let i = idx - 1; i >= 0 && str[i] === "\\"; i--) bs++;
    return (bs % 2) === 1;
  }

  function normalizeMathText(tex) {
    const cmdRe = /\\(?:text|textbf|textit|texttt|mathrm)\s*\{/g;
    let out = "";
    let pos = 0;
    let m;
    while ((m = cmdRe.exec(tex)) !== null) {
      out += tex.slice(pos, m.index + m[0].length);
      let i = m.index + m[0].length;
      let depth = 1;
      let inInnerMath = false;
      let bs = 0;
      while (i < tex.length && depth > 0) {
        const ch = tex[i];
        if (ch === "\\") {
          bs++;
          out += ch;
        } else {
          const escaped = (bs % 2) === 1;
          bs = 0;
          if (!escaped && ch === "$") {
            inInnerMath = !inInnerMath;
            out += ch;
          } else if (!escaped && ch === "{") {
            depth++;
            out += ch;
          } else if (!escaped && ch === "}") {
            depth--;
            out += ch;
          } else if (!escaped && !inInnerMath && ch === "_") {
            out += "\\_";
          } else {
            out += ch;
          }
        }
        i++;
      }
      pos = i;
      cmdRe.lastIndex = pos;
    }
    return out + tex.slice(pos);
  }

  function renderMarkdownWithMath(md) {
    const codeSlots = [];
    const mathSlots = [];

    let work = md.replace(/(^|\r?\n)((?:[ \t]*>)*[ \t]*(`{3,}|~{3,})[^\r\n]*\r?\n(?:[\s\S]*?\r?\n)?(?:[ \t]*>)*[ \t]*\3[ \t]*(?=\r?\n|$))/g, (_, lead, block) => {
      const idx = codeSlots.push(block) - 1;
      return lead + "\uE000SVCODE" + idx + "\uE001";
    });

    let codeWork = "";
    for (let i = 0; i < work.length; ) {
      if (work[i] === "`") {
        let len = 1;
        while (work[i + len] === "`") len++;
        const fence = work.slice(i, i + len);
        let j = i + len;
        let found = -1;
        while (j < work.length) {
          if (work[j] === "\n" && (work[j + 1] === "\n" || (work[j + 1] === "\r" && work[j + 2] === "\n"))) break;
          if (work.startsWith(fence, j) && work[j - 1] !== "`" && work[j + len] !== "`") {
            found = j + len;
            break;
          }
          j++;
        }
        if (found !== -1) {
          const idx = codeSlots.push(work.slice(i, found)) - 1;
          codeWork += "\uE000SVCODE" + idx + "\uE001";
          i = found;
          continue;
        }
        codeWork += fence;
        i += len;
        continue;
      }
      codeWork += work[i];
      i++;
    }
    work = codeWork;

    let mathWork = "";
    for (let i = 0; i < work.length; ) {
      if (work[i] === "$" && !isEscaped(work, i)) {
        if (work[i + 1] === "$") {
          let j = i + 2;
          let found = -1;
          while (j < work.length - 1) {
            if (work[j] === "$" && work[j + 1] === "$" && !isEscaped(work, j)) {
              found = j;
              break;
            }
            j++;
          }
          if (found !== -1) {
            const raw = work.slice(i, found + 2);
            const tex = normalizeMathText(work.slice(i + 2, found));
            const idx = mathSlots.push({ tex, display: true, raw }) - 1;
            mathWork += "\uE000SVMATH" + idx + "\uE001";
            i = found + 2;
            continue;
          }
        } else if (i + 1 < work.length && !/\s/.test(work[i + 1])) {
          let j = i + 1;
          let found = -1;
          while (j < work.length && work[j] !== "\r" && work[j] !== "\n") {
            if (work[j] === "\\") {
              j += 2;
              continue;
            }
            if (work[j] === "$") {
              if (!/\s/.test(work[j - 1])) {
                found = j;
              }
              break;
            }
            j++;
          }
          if (found !== -1) {
            const raw = work.slice(i, found + 1);
            const tex = normalizeMathText(work.slice(i + 1, found));
            const idx = mathSlots.push({ tex, display: false, raw }) - 1;
            mathWork += "\uE000SVMATH" + idx + "\uE001";
            i = found + 1;
            continue;
          }
        }
      }
      mathWork += work[i];
      i++;
    }
    work = mathWork;

    work = work.replace(/\uE000SVCODE(\d+)\uE001/g, (_, idx) => codeSlots[Number(idx)]);
    const html = marked.parse(work);

    return html.replace(/\uE000SVMATH(\d+)\uE001/g, (_, idx) => {
      const slot = mathSlots[Number(idx)];
      if (typeof katex !== "undefined" && typeof katex.renderToString === "function") {
        return katex.renderToString(slot.tex, { displayMode: slot.display, throwOnError: false });
      }
      return escapeHtml(slot.raw);
    });
  }

  function getHeadingPlainText(headingEl) {
    const clone = headingEl.cloneNode(true);
    clone.querySelectorAll(".katex").forEach((katexEl) => {
      const ann = katexEl.querySelector('annotation[encoding="application/x-tex"]');
      katexEl.replaceWith(document.createTextNode(ann ? ann.textContent : katexEl.textContent));
    });
    return clone.textContent.trim();
  }

  function slugify(text) {
    return String(text)
      .toLowerCase()
      .trim()
      .replace(/[^a-z0-9_\s-]/g, "")
      .replace(/\s/g, "-") || "section";
  }

  function getCourseKey(file) {
    return String(file).replace(/\.md$/i, "").split("/")[0];
  }

  function getCourseMeta(key) {
    if (COURSE_CATALOG[key]) return COURSE_CATALOG[key];
    return {
      cat: SITE_CFG.defaultCategory,
      chapters: 0,
      title: key.replace(/_/g, " "),
      desc: "Structured chapters and practical notes."
    };
  }

  function splitFileTarget(target) {
    const raw = String(target || HOME);
    const hashIdx = raw.indexOf("#");
    if (hashIdx === -1) return { file: raw || HOME, anchor: "" };
    return {
      file: raw.slice(0, hashIdx) || HOME,
      anchor: raw.slice(hashIdx + 1)
    };
  }

  function currentTarget() {
    const h = location.hash.slice(1);
    return h ? decodeURIComponent(h) : HOME;
  }

  function currentFile() {
    return splitFileTarget(currentTarget()).file;
  }

  function navigate(target, sectionText) {
    const { file, anchor } = splitFileTarget(target);
    pendingSectionText = sectionText || null;
    pendingAnchor = anchor || null;
    if (file === HOME) {
      history.pushState(null, "", location.pathname);
      load(HOME);
      return;
    }
    const fullTarget = anchor ? file + "#" + anchor : file;
    const nextHash = "#" + encodeURIComponent(fullTarget);
    if (location.hash !== nextHash) {
      location.hash = encodeURIComponent(fullTarget);
      return;
    }
    load(fullTarget);
  }

  function label(s) {
    return s.replace(/\.md$/i, "");
  }

  function updateBreadcrumb(file) {
    const bc = document.getElementById("breadcrumb");
    if (file === HOME) {
      bc.innerHTML = "";
      return;
    }
    const parts = file.split("/");
    if (parts.length === 1) {
      const meta = getCourseMeta(label(parts[0]));
      bc.innerHTML = '<span class="sep">&gt;</span><span class="crumb">' + escapeHtml(meta.title) + "</span>";
    } else {
      const parentFile = parts[0] + ".md";
      const meta = getCourseMeta(parts[0]);
      const rest = parts.slice(1).join("/");
      bc.innerHTML =
        '<span class="sep">&gt;</span>' +
        '<a class="crumb bc-link" href="#' + encodeURIComponent(parentFile) + '" data-file="' + escapeHtml(parentFile) + '">' + escapeHtml(meta.title) + "</a>" +
        '<span class="sep">&gt;</span>' +
        '<span class="crumb">' + escapeHtml(label(rest)) + "</span>";
      const link = bc.querySelector(".bc-link");
      link.addEventListener("click", (e) => {
        if (e.metaKey || e.ctrlKey || e.shiftKey || e.altKey || e.button !== 0) return;
        e.preventDefault();
        window.scrollTo(0, 0);
        navigate(parentFile);
      });
    }
  }

  function resolveHref(href, base) {
    if (!href || /^(?:[a-z]+:|\/\/)/i.test(href) || href.startsWith("#")) return null;
    const baseUrl = new URL(base, VIEW_ROOT);
    const resolvedUrl = new URL(href, baseUrl);
    if (resolvedUrl.origin !== VIEW_ROOT.origin || !resolvedUrl.pathname.startsWith(VIEW_ROOT.pathname)) return null;
    return decodeURIComponent(resolvedUrl.pathname.slice(VIEW_ROOT.pathname.length)) + resolvedUrl.search + resolvedUrl.hash;
  }

  function interceptLinks(container, base) {
    container.querySelectorAll("a[href]").forEach((a) => {
      const href = a.getAttribute("href");
      if (href && href.startsWith("#")) {
        const targetId = href.slice(1);
        const target = targetId ? document.getElementById(targetId) : null;
        if (target) {
          a.addEventListener("click", (e) => {
            e.preventDefault();
            target.scrollIntoView({ behavior: "smooth" });
          });
        }
        return;
      }
      const resolved = resolveHref(href, base);
      if (!resolved || !/\.md(?:$|[?#])/i.test(resolved)) return;
      a.setAttribute("href", "#" + encodeURIComponent(resolved));
      a.addEventListener("click", (e) => {
        if (e.metaKey || e.ctrlKey || e.shiftKey || e.altKey || e.button !== 0) return;
        e.preventDefault();
        if (!resolved.includes("#")) window.scrollTo(0, 0);
        navigate(resolved);
      });
    });
  }

  function rewriteImageSources(container, base) {
    container.querySelectorAll("img[src]").forEach((img) => {
      const src = img.getAttribute("src");
      const resolved = resolveHref(src, base);
      if (!resolved) return;
      img.setAttribute("src", resolved);
    });
  }

  function highlightCode(container) {
    if (!window.hljs) return;
    container.querySelectorAll("pre code").forEach((code) => {
      if (!code.className.includes("language-")) return;
      hljs.highlightElement(code);
    });
  }

  function addCopyButtons(container) {
    container.querySelectorAll("pre").forEach((pre) => {
      const wrap = document.createElement("div");
      wrap.className = "code-wrap";
      pre.parentNode.insertBefore(wrap, pre);
      wrap.appendChild(pre);
      const btn = document.createElement("button");
      btn.type = "button";
      btn.className = "copy-btn";
      btn.textContent = "copy";
      btn.addEventListener("click", () => {
        const text = pre.querySelector("code") ? pre.querySelector("code").innerText : pre.innerText;
        navigator.clipboard.writeText(text).then(() => {
          btn.textContent = "copied!";
          btn.classList.add("copied");
          setTimeout(() => { btn.textContent = "copy"; btn.classList.remove("copied"); }, 2000);
        }).catch(() => {
          btn.textContent = "error";
          setTimeout(() => { btn.textContent = "copy"; }, 2000);
        });
      });
      wrap.appendChild(btn);
    });
  }

  async function fetchMarkdown(file, signal) {
    if (mdCache.has(file)) return mdCache.get(file);
    const res = await fetch(file, { cache: "no-cache", signal });
    if (!res.ok) throw new Error("HTTP " + res.status);
    const raw = await res.text();
    mdCache.set(file, raw);
    return raw;
  }

  function parseTopicIndex(raw, topicFile) {
    if (topicChaptersCache.has(topicFile)) return topicChaptersCache.get(topicFile);
    const lines = raw.split(/\r?\n/);
    const chapters = [];
    let currentChap = null;

    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];
      const chapMatch = line.match(/^##\s+(\d+)\.\s+\[([^\]]+)\]\(([^)]+)\)/);
      if (chapMatch) {
        currentChap = {
          num: Number(chapMatch[1]),
          title: chapMatch[2].trim(),
          file: chapMatch[3].trim(),
          sections: []
        };
        chapters.push(currentChap);
        continue;
      }
      const secMatch = line.match(/^\s+-\s+(.+)/);
      if (secMatch && currentChap) {
        const rawSec = secMatch[1].trim();
        const linkMatch = rawSec.match(/^\[((?:\\.|[^\]])+)\]\(([^)]+)\)$/);
        if (linkMatch) {
          currentChap.sections.push({
            title: linkMatch[1].replace(/\\([\[\]])/g, "$1").trim(),
            file: linkMatch[2].trim()
          });
        } else {
          currentChap.sections.push({
            title: rawSec,
            file: currentChap.file
          });
        }
      }
    }

    topicChaptersCache.set(topicFile, chapters);
    return chapters;
  }

  function parseReadmeCourses(raw) {
    const courses = [];
    const regex = /\[([^\]]+)\]\(([^)]+\.md)\)/g;
    let m;
    while ((m = regex.exec(raw)) !== null) {
      const file = m[2].trim();
      const key = getCourseKey(file);
      const meta = getCourseMeta(key);
      courses.push({
        key,
        file,
        cat: meta.cat,
        chapters: meta.chapters || 0,
        title: meta.title,
        desc: meta.desc
      });
    }
    const orderMap = new Map(Object.keys(COURSE_CATALOG).map((k, idx) => [k, idx]));
    courses.sort((a, b) => {
      const ia = orderMap.has(a.key) ? orderMap.get(a.key) : Number.MAX_SAFE_INTEGER;
      const ib = orderMap.has(b.key) ? orderMap.get(b.key) : Number.MAX_SAFE_INTEGER;
      return ia !== ib ? ia - ib : a.key.localeCompare(b.key);
    });
    return courses;
  }

  function renderHomeDashboard(el, rawReadme) {
    const courses = parseReadmeCourses(rawReadme);
    const byCat = new Map();
    CATEGORIES.forEach((c) => byCat.set(c.id, []));
    courses.forEach((c) => {
      const list = byCat.get(c.cat) || byCat.get(SITE_CFG.defaultCategory) || (CATEGORIES[0] && byCat.get(CATEGORIES[0].id));
      if (list) list.push(c);
    });
    const initialChaps = courses.reduce((acc, c) => acc + (c.chapters || 0), 0);

    let html =
      '<section class="catalog-hero">' +
        '<p class="catalog-eyebrow">' + escapeHtml(SITE_CFG.eyebrow) + "</p>" +
        "<h1>" + escapeHtml(SITE_CFG.title) + "</h1>" +
        '<p class="catalog-sub">' + escapeHtml(SITE_CFG.tagline) + "</p>" +
        '<div class="catalog-controls">' +
          '<div class="catalog-stats">' +
            '<span class="stat-pill">' + courses.length + " Courses</span>" +
            '<span class="stat-pill g" id="stat-chapters">' + (initialChaps > 0 ? initialChaps + " Chapters" : "Loading chapters&#8230;") + "</span>" +
          "</div>" +
          '<input type="search" class="catalog-filter" id="home-filter" placeholder="Filter courses&#8230;" aria-label="Filter courses" />' +
        "</div>" +
      "</section>" +
      '<div id="catalog-groups">';

    CATEGORIES.forEach((cat) => {
      const items = byCat.get(cat.id);
      if (!items || items.length === 0) return;
      html +=
        '<section class="catalog-group" data-cat="' + cat.id + '">' +
          '<div class="catalog-group-title">' +
            "<span>" + escapeHtml(cat.title) + "</span>" +
            '<span class="catalog-group-count">' + items.length + " courses</span>" +
          "</div>" +
          '<div class="course-grid">';
      items.forEach((item) => {
        const cachedChaps = topicChaptersCache.get(item.file);
        const countLabel = cachedChaps ? cachedChaps.length + " ch" : (item.chapters ? item.chapters + " ch" : "Index");
        html +=
          '<a class="course-card" href="#' + encodeURIComponent(item.file) + '" data-file="' + escapeHtml(item.file) + '" data-search="' + escapeHtml((item.title + " " + item.desc + " " + cat.title).toLowerCase()) + '">' +
            '<div class="course-card-top">' +
              '<span class="course-title">' + escapeHtml(item.title) + "</span>" +
              '<span class="course-count" data-topic-file="' + escapeHtml(item.file) + '">' + countLabel + "</span>" +
            "</div>" +
            '<p class="course-desc">' + escapeHtml(item.desc) + "</p>" +
          "</a>";
      });
      html += "</div></section>";
    });

    html += "</div>";
    el.innerHTML = html;

    el.querySelectorAll(".course-card").forEach((card) => {
      card.addEventListener("click", (e) => {
        if (e.metaKey || e.ctrlKey || e.shiftKey || e.altKey || e.button !== 0) return;
        e.preventDefault();
        window.scrollTo(0, 0);
        navigate(card.getAttribute("data-file"));
      });
    });

    const filterInput = document.getElementById("home-filter");
    const groupsContainer = document.getElementById("catalog-groups");
    filterInput.addEventListener("input", () => {
      const q = filterInput.value.trim().toLowerCase();
      let anyVisible = false;
      groupsContainer.querySelectorAll(".catalog-group").forEach((grp) => {
        let groupVisible = 0;
        grp.querySelectorAll(".course-card").forEach((card) => {
          const match = !q || card.getAttribute("data-search").includes(q);
          card.style.display = match ? "" : "none";
          if (match) groupVisible++;
        });
        grp.style.display = groupVisible > 0 ? "" : "none";
        if (groupVisible > 0) anyVisible = true;
      });
      let emptyEl = document.getElementById("catalog-empty");
      if (!anyVisible) {
        if (!emptyEl) {
          emptyEl = document.createElement("div");
          emptyEl.id = "catalog-empty";
          emptyEl.className = "catalog-empty";
          emptyEl.textContent = "No matching courses found. Try Ctrl+K to search inside chapters and sections.";
          groupsContainer.appendChild(emptyEl);
        }
      } else if (emptyEl) {
        emptyEl.remove();
      }
    });

    ensureSearchIndex().then(() => {
      let totalChaps = 0;
      courses.forEach((c) => {
        const chaps = topicChaptersCache.get(c.file);
        if (!chaps) return;
        totalChaps += chaps.length;
        const badge = el.querySelector('.course-count[data-topic-file="' + CSS.escape(c.file) + '"]');
        if (badge) badge.textContent = chaps.length + " ch";
      });
      const statEl = document.getElementById("stat-chapters");
      if (statEl && totalChaps > 0) {
        statEl.textContent = totalChaps + " Chapters";
      }
    }).catch(() => {});
  }

  function injectChapterToc(mdEl) {
    const h2s = Array.from(mdEl.querySelectorAll("h2"));
    if (h2s.length === 0) return;

    const usedIds = new Set();
    const tocItems = h2s.map((h2) => {
      const text = getHeadingPlainText(h2);
      const base = slugify(text);
      let id = base;
      let suffix = 1;
      while (usedIds.has(id) || document.getElementById(id)) {
        id = base + "-" + suffix++;
      }
      usedIds.add(id);
      h2.id = id;
      return { id, text };
    });

    if (tocItems.length < 2) return;

    const details = document.createElement("details");
    details.className = "toc-box";
    details.open = true;

    const summary = document.createElement("summary");
    summary.textContent = "On This Page (" + tocItems.length + " sections)";
    details.appendChild(summary);

    const ol = document.createElement("ol");
    ol.className = "toc-list";
    tocItems.forEach((item) => {
      const li = document.createElement("li");
      const a = document.createElement("a");
      a.href = "#" + item.id;
      a.textContent = item.text;
      a.addEventListener("click", (e) => {
        e.preventDefault();
        document.getElementById(item.id)?.scrollIntoView({ behavior: "smooth" });
      });
      li.appendChild(a);
      ol.appendChild(li);
    });
    details.appendChild(ol);

    const firstH1 = mdEl.querySelector("h1");
    if (firstH1 && firstH1.nextSibling) {
      mdEl.insertBefore(details, firstH1.nextSibling);
    } else {
      mdEl.prepend(details);
    }
  }

  async function appendChapterNav(mdEl, file, loadId) {
    if (!file.includes("/")) return;
    const topicName = file.split("/")[0];
    const topicFile = topicName + ".md";

    try {
      const rawTopic = await fetchMarkdown(topicFile);
      if (loadId !== activeLoadId) return;
      const chapters = parseTopicIndex(rawTopic, topicFile);
      const idx = chapters.findIndex((c) => c.file === file);
      if (idx === -1) return;

      const prev = idx > 0 ? chapters[idx - 1] : null;
      const next = idx < chapters.length - 1 ? chapters[idx + 1] : null;
      const courseTitle = getCourseMeta(topicName).title;

      const navEl = document.createElement("nav");
      navEl.className = "chapter-nav";
      navEl.setAttribute("aria-label", "Chapter navigation");

      const prevHtml = prev
        ? '<a class="chap-btn prev" href="#' + encodeURIComponent(prev.file) + '" data-file="' + escapeHtml(prev.file) + '">' +
            '<span class="chap-dir">&#8592; Previous Chapter</span>' +
            '<span class="chap-name">' + prev.num + ". " + escapeHtml(prev.title) + "</span>" +
          "</a>"
        : '<span class="chap-btn prev disabled"><span class="chap-dir">&#8592; Start of Course</span><span class="chap-name">Chapter 1</span></span>';

      const indexHtml =
        '<a class="chap-btn index" href="#' + encodeURIComponent(topicFile) + '" data-file="' + escapeHtml(topicFile) + '">' +
          '<span class="chap-dir">' + escapeHtml(courseTitle) + "</span>" +
          '<span class="chap-name">Chapter ' + (idx + 1) + " of " + chapters.length + "</span>" +
        "</a>";

      const nextHtml = next
        ? '<a class="chap-btn next" href="#' + encodeURIComponent(next.file) + '" data-file="' + escapeHtml(next.file) + '">' +
            '<span class="chap-dir">Next Chapter &#8594;</span>' +
            '<span class="chap-name">' + next.num + ". " + escapeHtml(next.title) + "</span>" +
          "</a>"
        : '<span class="chap-btn next disabled"><span class="chap-dir">End of Course &#8594;</span><span class="chap-name">All chapters complete</span></span>';

      navEl.innerHTML = prevHtml + indexHtml + nextHtml;
      navEl.querySelectorAll("a[data-file]").forEach((a) => {
        a.addEventListener("click", (e) => {
          if (e.metaKey || e.ctrlKey || e.shiftKey || e.altKey || e.button !== 0) return;
          e.preventDefault();
          window.scrollTo(0, 0);
          navigate(a.getAttribute("data-file"));
        });
      });

      mdEl.appendChild(navEl);
    } catch (_) {}
  }

  function scrollToPendingSection(mdEl) {
    const anchor = pendingAnchor;
    const sectionText = pendingSectionText;
    pendingAnchor = null;
    pendingSectionText = null;

    let match = null;
    if (anchor) {
      let decodedAnchor = anchor;
      try { decodedAnchor = decodeURIComponent(anchor); } catch (_) {}
      match = document.getElementById(decodedAnchor);
      if (!match) {
        const normTarget = decodedAnchor.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "");
        const headings = Array.from(mdEl.querySelectorAll("h2, h3"));
        match = headings.find((h) => {
          const normId = (h.id || slugify(getHeadingPlainText(h))).toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "");
          return normId === normTarget;
        });
      }
    }
    if (!match && sectionText) {
      const needle = sectionText.toLowerCase();
      const headings = Array.from(mdEl.querySelectorAll("h2, h3"));
      match = headings.find((h) => getHeadingPlainText(h).toLowerCase().includes(needle) || h.textContent.trim().toLowerCase().includes(needle));
    }
    if (match) {
      requestAnimationFrame(() => match.scrollIntoView({ behavior: "smooth" }));
    }
  }

  async function ensureSearchIndex() {
    if (searchEntries) return searchEntries;
    if (searchBuildPromise) return searchBuildPromise;

    searchBuildPromise = (async () => {
      const readmeRaw = await fetchMarkdown(HOME);
      const courses = parseReadmeCourses(readmeRaw);
      const entries = [];

      courses.forEach((c) => {
        entries.push({
          type: "Course",
          title: c.title,
          meta: c.cat,
          file: c.file,
          search: (c.title + " " + c.desc).toLowerCase()
        });
      });

      await Promise.all(
        courses.map(async (c) => {
          try {
            const topicRaw = await fetchMarkdown(c.file);
            const chapters = parseTopicIndex(topicRaw, c.file);
            chapters.forEach((ch) => {
              entries.push({
                type: "Chapter",
                title: ch.num + ". " + ch.title,
                meta: c.title,
                file: ch.file,
                search: (c.title + " " + ch.title).toLowerCase()
              });
              ch.sections.forEach((sec) => {
                const secTitle = typeof sec === "string" ? sec : sec.title;
                const secFile = typeof sec === "string" ? ch.file : sec.file;
                entries.push({
                  type: "Section",
                  title: secTitle,
                  meta: c.title + " · Ch " + ch.num + ": " + ch.title,
                  file: secFile,
                  section: secTitle,
                  search: (c.title + " " + ch.title + " " + secTitle).toLowerCase()
                });
              });
            });
          } catch (_) {}
        })
      );

      searchEntries = entries;
      return entries;
    })();

    return searchBuildPromise;
  }

  /* ── MOBILE NAV ── */
  const siteNav = document.querySelector(".shell > nav");
  const navToggle = document.getElementById("nav-toggle");
  const navUtils = document.getElementById("nav-utils");
  const navDrawer = document.getElementById("nav-drawer");
  let currentNavActiveFile = HOME;

  function closeNav() {
    if (!siteNav || !navToggle) return;
    siteNav.classList.remove("nav-open");
    navToggle.setAttribute("aria-expanded", "false");
  }

  async function populateCourseChapters(detailsEl, courseFile, activeFile) {
    const listEl = detailsEl.querySelector(".nav-chap-list");
    if (!listEl) return;

    let chapters = topicChaptersCache.get(courseFile);
    if (!chapters) {
      if (detailsEl.dataset.loading === "1") return;
      detailsEl.dataset.loading = "1";
      listEl.innerHTML = '<div class="nav-chap-status">Loading chapters&#8230;</div>';
      try {
        const raw = await fetchMarkdown(courseFile);
        chapters = parseTopicIndex(raw, courseFile);
      } catch (_) {
        detailsEl.dataset.loading = "";
        listEl.innerHTML = '<div class="nav-chap-status">Could not load chapters.</div>';
        return;
      }
      detailsEl.dataset.loading = "";
      if (!detailsEl.open) return;
    }

    const targetFile = currentNavActiveFile || activeFile;
    const overviewCls = targetFile === courseFile ? "nav-chap-link active" : "nav-chap-link";
    let html =
      '<a class="' + overviewCls + '" href="#' + encodeURIComponent(courseFile) + '" data-file="' + escapeHtml(courseFile) + '">' +
        "Course Overview" +
      "</a>";

    chapters.forEach((ch) => {
      const cls = targetFile === ch.file ? "nav-chap-link active" : "nav-chap-link";
      html +=
        '<a class="' + cls + '" href="#' + encodeURIComponent(ch.file) + '" data-file="' + escapeHtml(ch.file) + '">' +
          ch.num + ". " + escapeHtml(ch.title) +
        "</a>";
    });

    listEl.innerHTML = html;

    if (siteNav && siteNav.classList.contains("nav-open") && detailsEl.classList.contains("active")) {
      const activeChap = listEl.querySelector(".nav-chap-link.active");
      if (activeChap) activeChap.scrollIntoView({ block: "nearest" });
    }
  }

  function ensureNavDrawerBuilt() {
    if (!navDrawer || navDrawer.dataset.built === "1") return;

    const byCat = new Map();
    CATEGORIES.forEach((c) => byCat.set(c.id, []));
    Object.keys(COURSE_CATALOG).forEach((key) => {
      const meta = COURSE_CATALOG[key];
      const list = byCat.get(meta.cat) || byCat.get(SITE_CFG.defaultCategory) || (CATEGORIES[0] && byCat.get(CATEGORIES[0].id));
      if (list) list.push({
        key,
        file: key + ".md",
        title: meta.title,
        chapters: meta.chapters || 0
      });
    });

    let html =
      '<a class="nav-drawer-home" href="#' + encodeURIComponent(HOME) + '" data-file="' + escapeHtml(HOME) + '">' +
        "<span>All Courses &#183; " + escapeHtml(SITE_CFG.title) + " Home</span>" +
      "</a>";

    CATEGORIES.forEach((cat) => {
      const items = byCat.get(cat.id);
      if (!items || items.length === 0) return;
      html +=
        '<div class="nav-cat-group">' +
          '<div class="nav-cat-title">' + escapeHtml(cat.title) + "</div>";
      items.forEach((item) => {
        const countText = item.chapters ? item.chapters + " ch" : "Index";
        html +=
          '<details class="nav-course" data-course-file="' + escapeHtml(item.file) + '">' +
            "<summary>" +
              '<span class="nav-course-name">' + escapeHtml(item.title) + "</span>" +
              '<span class="nav-course-count">' + countText + "</span>" +
            "</summary>" +
            '<div class="nav-chap-list"></div>' +
          "</details>";
      });
      html += "</div>";
    });

    navDrawer.innerHTML = html;
    navDrawer.dataset.built = "1";

    navDrawer.querySelectorAll(".nav-course").forEach((detailsEl) => {
      detailsEl.addEventListener("toggle", () => {
        if (detailsEl.open) {
          populateCourseChapters(detailsEl, detailsEl.getAttribute("data-course-file"), currentNavActiveFile);
        }
      });
    });

    navDrawer.addEventListener("click", (e) => {
      const link = e.target.closest("a[data-file]");
      if (!link) return;
      if (e.metaKey || e.ctrlKey || e.shiftKey || e.altKey || e.button !== 0) return;
      e.preventDefault();
      closeNav();
      window.scrollTo(0, 0);
      navigate(link.getAttribute("data-file"));
    });
  }

  function renderNavDrawer(activeFile) {
    if (!navDrawer) return;
    ensureNavDrawerBuilt();

    currentNavActiveFile = activeFile || HOME;
    const activeCourseKey = currentNavActiveFile !== HOME ? getCourseKey(currentNavActiveFile) : "";
    const activeCourseFile = activeCourseKey ? activeCourseKey + ".md" : "";

    const homeLink = navDrawer.querySelector(".nav-drawer-home");
    if (homeLink) {
      homeLink.classList.toggle("active", currentNavActiveFile === HOME);
    }

    navDrawer.querySelectorAll(".nav-course").forEach((detailsEl) => {
      const courseFile = detailsEl.getAttribute("data-course-file");
      const isActiveCourse = courseFile === activeCourseFile;
      detailsEl.classList.toggle("active", isActiveCourse);
      if (isActiveCourse) {
        detailsEl.open = true;
        populateCourseChapters(detailsEl, courseFile, currentNavActiveFile);
      } else if (detailsEl.open) {
        populateCourseChapters(detailsEl, courseFile, currentNavActiveFile);
      }
    });
  }

  if (siteNav && navToggle && navUtils) {
    navToggle.addEventListener("click", () => {
      const willOpen = !siteNav.classList.contains("nav-open");
      if (willOpen) {
        renderNavDrawer(currentFile());
        ensureSearchIndex().catch(() => {});
      }
      siteNav.classList.toggle("nav-open", willOpen);
      navToggle.setAttribute("aria-expanded", willOpen ? "true" : "false");
      if (willOpen && navDrawer) {
        requestAnimationFrame(() => {
          const activeTarget = navDrawer.querySelector(".nav-chap-link.active, .nav-course.active > summary, .nav-drawer-home.active");
          if (activeTarget) activeTarget.scrollIntoView({ block: "nearest" });
        });
      }
    });

    navUtils.addEventListener("click", (e) => {
      if (e.target.closest("a")) closeNav();
    });

    window.addEventListener("resize", () => {
      if (window.innerWidth > 640) closeNav();
    });
  }

  /* ── SEARCH MODAL UI ── */
  const searchModal = document.getElementById("search-modal");
  const searchInput = document.getElementById("search-input");
  const searchResults = document.getElementById("search-results");
  let currentMatches = [];

  function openSearchModal() {
    closeNav();
    searchModal.classList.add("open");
    searchInput.value = "";
    activeResultIndex = -1;
    searchInput.focus();
    searchResults.innerHTML = '<div class="search-status">Indexing courses&#8230;</div>';
    ensureSearchIndex().then(() => {
      renderSearchResults("");
    }).catch(() => {
      searchResults.innerHTML = '<div class="search-status">Could not load search index.</div>';
    });
  }

  function closeSearchModal() {
    searchModal.classList.remove("open");
  }

  function renderSearchResults(query) {
    if (!searchEntries) return;
    const q = query.trim().toLowerCase();
    if (!q) {
      currentMatches = searchEntries.filter((e) => e.type === "Course").slice(0, 12);
    } else {
      const terms = q.split(/\s+/);
      currentMatches = searchEntries
        .filter((e) => terms.every((t) => e.search.includes(t)))
        .slice(0, 30);
    }

    activeResultIndex = currentMatches.length > 0 ? 0 : -1;

    if (currentMatches.length === 0) {
      searchResults.innerHTML = '<div class="search-status">No results for "' + escapeHtml(query) + '"</div>';
      return;
    }

    searchResults.innerHTML = currentMatches
      .map((item, idx) => {
        const cls = idx === 0 ? "search-item active" : "search-item";
        return (
          '<a class="' + cls + '" href="#' + encodeURIComponent(item.file) + '" data-idx="' + idx + '">' +
            '<span class="search-item-meta"><span>' + escapeHtml(item.type) + "</span><span>&#183;</span><span>" + escapeHtml(item.meta) + "</span></span>" +
            '<span class="search-item-title">' + escapeHtml(item.title) + "</span>" +
          "</a>"
        );
      })
      .join("");

    searchResults.querySelectorAll(".search-item").forEach((el) => {
      el.addEventListener("click", (e) => {
        if (e.metaKey || e.ctrlKey || e.shiftKey || e.altKey || e.button !== 0) return;
        e.preventDefault();
        const item = currentMatches[Number(el.getAttribute("data-idx"))];
        if (!item) return;
        closeSearchModal();
        if (!item.file.includes("#")) window.scrollTo(0, 0);
        navigate(item.file, item.section || null);
      });
    });
  }

  function moveActiveResult(delta) {
    if (currentMatches.length === 0) return;
    const items = searchResults.querySelectorAll(".search-item");
    if (activeResultIndex >= 0 && items[activeResultIndex]) {
      items[activeResultIndex].classList.remove("active");
    }
    activeResultIndex = (activeResultIndex + delta + currentMatches.length) % currentMatches.length;
    const nextEl = items[activeResultIndex];
    if (nextEl) {
      nextEl.classList.add("active");
      nextEl.scrollIntoView({ block: "nearest" });
    }
  }

  document.getElementById("open-search").addEventListener("click", openSearchModal);
  document.getElementById("close-search").addEventListener("click", closeSearchModal);
  searchModal.addEventListener("click", (e) => {
    if (e.target === searchModal) closeSearchModal();
  });
  searchInput.addEventListener("input", () => renderSearchResults(searchInput.value));
  searchInput.addEventListener("keydown", (e) => {
    if (e.key === "ArrowDown") {
      e.preventDefault();
      moveActiveResult(1);
    } else if (e.key === "ArrowUp") {
      e.preventDefault();
      moveActiveResult(-1);
    } else if (e.key === "Enter" && activeResultIndex >= 0 && currentMatches[activeResultIndex]) {
      e.preventDefault();
      const item = currentMatches[activeResultIndex];
      closeSearchModal();
      if (!item.file.includes("#")) window.scrollTo(0, 0);
      navigate(item.file, item.section || null);
    }
  });

  document.addEventListener("keydown", (e) => {
    if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === "k") {
      e.preventDefault();
      if (searchModal.classList.contains("open")) closeSearchModal();
      else openSearchModal();
      return;
    }
    if (e.key === "/" && !searchModal.classList.contains("open")) {
      const tag = document.activeElement ? document.activeElement.tagName : "";
      if (tag !== "INPUT" && tag !== "TEXTAREA") {
        e.preventDefault();
        openSearchModal();
      }
      return;
    }
    if (e.key === "Escape") {
      if (searchModal.classList.contains("open")) {
        e.preventDefault();
        closeSearchModal();
      } else if (siteNav && siteNav.classList.contains("nav-open")) {
        e.preventDefault();
        closeNav();
        if (navToggle) navToggle.focus();
      }
    }
  });

  async function load(target) {
    const { file, anchor } = splitFileTarget(target);
    if (anchor) pendingAnchor = anchor;
    closeNav();
    renderNavDrawer(file);
    const el = document.getElementById("content");
    const loadId = ++activeLoadId;

    if (activeController) activeController.abort();
    activeController = new AbortController();

    el.innerHTML = '<div class="state">Loading&#8230;</div>';
    updateBreadcrumb(file);

    const courseKey = getCourseKey(file);
    const courseTitle = getCourseMeta(courseKey).title;
    document.title = file === HOME
      ? SITE_CFG.title + " \u2014 " + SITE_CFG.brand
      : (file.includes("/") ? label(file.split("/").slice(1).join("/")) + " \u00B7 " + courseTitle : courseTitle) + " \u2014 " + SITE_CFG.title;

    try {
      const raw = await fetchMarkdown(file, activeController.signal);
      if (loadId !== activeLoadId) return;

      if (file === HOME) {
        renderHomeDashboard(el, raw);
        return;
      }

      const ownerEsc = SITE_CFG.copyrightOwner.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
      const md = raw.replace(new RegExp("^#{1,6}\\s.*Copyright.*" + ownerEsc + ".*$", "m"), "").trimEnd();
      el.innerHTML = '<div class="md">' + renderMarkdownWithMath(md) + "</div>";
      const mdEl = el.querySelector(".md");

      rewriteImageSources(mdEl, file);
      highlightCode(mdEl);
      addCopyButtons(mdEl);
      interceptLinks(mdEl, file);

      if (file.includes("/")) {
        injectChapterToc(mdEl);
        await appendChapterNav(mdEl, file, loadId);
        if (loadId !== activeLoadId) return;
        scrollToPendingSection(mdEl);
      } else {
        parseTopicIndex(raw, file);
      }
    } catch (err) {
      if (err.name === "AbortError" || loadId !== activeLoadId) return;
      el.innerHTML =
        '<div class="state"><p>Could not load <span class="c">' + escapeHtml(file) +
        '</span></p><p style="margin-top:8px;font-size:.8rem">' + escapeHtml(err.message) + "</p></div>";
    } finally {
      if (loadId === activeLoadId) activeController = null;
    }
  }

  function applyTheme(modeId) {
    let idx = THEME_MODES.findIndex((m) => m.id === modeId);
    if (idx === -1) idx = 0;
    currentThemeIndex = idx;
    const mode = THEME_MODES[idx];
    const nextMode = THEME_MODES[(idx + 1) % THEME_MODES.length];

    document.documentElement.setAttribute("data-theme", mode.id);

    const iconEl = document.getElementById("theme-icon");
    const labelEl = document.getElementById("theme-label");
    const toggleBtn = document.getElementById("theme-toggle");
    if (iconEl) iconEl.textContent = mode.icon;
    if (labelEl) labelEl.textContent = mode.label;
    if (toggleBtn) {
      const hint = "Mode: " + mode.label + " (click for " + nextMode.label + ")";
      toggleBtn.title = hint;
      toggleBtn.setAttribute("aria-label", hint);
    }

    const hljsLink = document.getElementById("hljs-theme");
    if (hljsLink && hljsLink.getAttribute("href") !== mode.hljs) {
      hljsLink.setAttribute("href", mode.hljs);
    }

    try {
      localStorage.setItem(THEME_STORAGE_KEY, mode.id);
    } catch (_) {}
  }

  (function initTheme() {
    let saved = "dark";
    try {
      saved = localStorage.getItem(THEME_STORAGE_KEY) || "dark";
    } catch (_) {}
    applyTheme(saved);
    const toggleBtn = document.getElementById("theme-toggle");
    if (toggleBtn) {
      toggleBtn.addEventListener("click", () => {
        const nextMode = THEME_MODES[(currentThemeIndex + 1) % THEME_MODES.length];
        applyTheme(nextMode.id);
      });
    }
  })();

  document.getElementById("home-btn").addEventListener("click", (e) => {
    if (e.metaKey || e.ctrlKey || e.shiftKey || e.altKey || e.button !== 0) return;
    e.preventDefault();
    navigate(HOME);
    window.scrollTo(0, 0);
  });

  window.addEventListener("hashchange", () => load(currentTarget()));

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", () => load(currentTarget()));
  } else {
    load(currentTarget());
  }
})();
</script>
</body>
</html>
SV_HTML_PART4
    } > "${tmp_html}"; then
        mv "${tmp_html}" "${html_path}"
    else
        rm -f "${tmp_existing}" "${tmp_cats}" "${tmp_entries}" "${tmp_html}"
        return 1
    fi

    rm -f "${tmp_existing}" "${tmp_cats}" "${tmp_entries}" "${tmp_html}"
}

load_config || exit 1

# Find all directories (excluding hidden ones) and count the work before starting
LIST=$(find -mindepth 1 -maxdepth 1 -type d ! -name ".*" | sed "s/.*\///g" | sort -f)
directory_total=$(printf '%s\n' "${LIST}" | sed '/^$/d' | wc -l)
chapter_work_total=0
for i in ${LIST} ; do
    chapter_count=$(find "${i}" -mindepth 1 -maxdepth 1 -type f -name "chapter_*.md" | wc -l)
    chapter_work_total=$((chapter_work_total + chapter_count))
done
existing_markdown_total=$(find -type f -name "*.md" | wc -l)
root_markdown_total=$(find -mindepth 1 -maxdepth 1 -type f -name "*.md" | wc -l)
copyright_total=$((existing_markdown_total - root_markdown_total + directory_total + 1))
extra_work=1
[[ -f "../index.html" && -f "../CNAME" ]] && extra_work=$((extra_work + 1))
total_work=$((directory_total + chapter_work_total * 3 + copyright_total + extra_work))
progress 0 "${total_work}" "Starting"

# Remove all markdown files in the current directory
rm -f *.md

# Create a new README.md file with a title
printf '# %s\n' "${SITE_TITLE}" > README.md

progress_count=0
for i in ${LIST} ; do
    # Add each directory as a section in README.md
    if [[ -z "${DRAFT_PREFIX}" || "${i}" != "${DRAFT_PREFIX}"* ]]; then
      echo "  - ### [$(echo ${i} | sed -e 's/_/ /g')](${i}.md)" >> README.md
    fi
    # Create a new markdown file for each directory with a title
    echo "# $(echo ${i} | sed -e 's/_/ /g')" > ${i}.md

    # Find all chapter markdown files in the directory and rename them temporarily
    LIST1=$(find "${i}" -mindepth 1 -maxdepth 1 -type f -name "chapter_*.md" | sort)
    for j in ${LIST1} ; do
        TMP_NAME=$(echo ${j} | sed "s/chapter_/temp_chapter_/g")
        mv ${j} ${TMP_NAME}
        progress_count=$((progress_count + 1))
        progress "${progress_count}" "${total_work}" "Preparing ${j}"
    done

    # Rename the temporary chapter files back to their original names with zero-padded numbers
    count=1
    LIST2=$(find "${i}" -mindepth 1 -maxdepth 1 -type f -name "temp_chapter_*.md" | sort)
    for j in ${LIST2} ; do
        FINAL_NAME=$(echo ${j} | sed "s/temp_chapter_.*\./chapter_$(printf "%05d." ${count})/g")
        mv ${j} ${FINAL_NAME}
        count=$((count + 1))
        progress_count=$((progress_count + 1))
        progress "${progress_count}" "${total_work}" "Renumbering ${j}"
    done

    # Add each chapter file as a section in the directory's markdown file
    LIST3=$(find "${i}" -mindepth 1 -maxdepth 1 -type f -name "chapter_*.md" | sort)
    for j in ${LIST3} ; do
        TITLE=$(cat ${j} | grep -m 1 "^# " | sed "s/^# //g" | sed "s/:.*//g")
        echo "## $(echo "${j}" | sed "s/.*chapter_0*//g" | sed "s/\..*//g"). [$(echo ${TITLE} | sed -e 's/_/ /g')](${j})" >> ${i}.md
        emit_h2_links "${j}" >> "${i}.md"
        progress_count=$((progress_count + 1))
        progress "${progress_count}" "${total_work}" "Indexing ${j}"
    done

    progress_count=$((progress_count + 1))
    progress "${progress_count}" "${total_work}" "Processed ${i}"
done

# Find all markdown files and update copyright information
list=$(find -type f -name "*.md")
owner_ere=$(ere_escape "${COPYRIGHT_OWNER}")
owner_sed_pat=$(printf '%s' "${COPYRIGHT_OWNER}" | sed -e 's/[.[\*^$|\\]/\\&/g')
owner_sed_rep=$(sed_repl_escape "${COPYRIGHT_OWNER}")
current_year=$(date +%Y)

for file in ${list} ; do
  # Check if the file already contains a copyright notice
  if grep -Eq "Copyright \(c\) [0-9]{4} ${owner_ere}" "$file" ; then
    # Update the existing copyright notice with the current year
    sed -i "s|.*Copyright (c) [0-9]\{4\} ${owner_sed_pat}.*|##### Copyright (c) ${current_year} ${owner_sed_rep}|g" "$file"
  else
    # Add a new copyright notice if not present
    echo "" >> "$file"
    echo "##### Copyright (c) ${current_year} ${COPYRIGHT_OWNER}" >> "$file"
    echo "" >> "$file"
  fi
  progress_count=$((progress_count + 1))
  progress "${progress_count}" "${total_work}" "Updated ${file}"
done

# Generate index.html metadata, copyright, CATEGORIES, and COURSE_CATALOG from config.json
update_index_html
progress_count=$((progress_count + 1))
progress "${progress_count}" "${total_work}" "Generated index.html"

# Regenerate root sitemap.xml when inside the website repository
SITEMAP_PATH="../sitemap.xml"
if [[ -f "../index.html" && -f "../CNAME" ]]; then
  BASE_URL=$(get_base_url)
  SV_PATH=$(get_skillverse_path)
  {
    printf '<?xml version="1.0" encoding="UTF-8"?>\n'
    printf '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n\n'
    printf '  <!-- Main site pages -->\n'
    printf '  <url>\n    <loc>%s/</loc>\n    <changefreq>weekly</changefreq>\n    <priority>1.0</priority>\n  </url>\n' "${BASE_URL}"
    for page in "${SITEMAP_ROOT_PAGES[@]}"; do
      if [[ -f "../${page}" ]]; then
        printf '  <url>\n    <loc>%s/%s</loc>\n    <changefreq>monthly</changefreq>\n    <priority>0.8</priority>\n  </url>\n' "${BASE_URL}" "${page}"
      fi
    done
    while IFS= read -r person_page; do
      [[ -z "${person_page}" ]] && continue
      person_base=$(basename "${person_page}")
      printf '  <url>\n    <loc>%s/people/%s</loc>\n    <changefreq>monthly</changefreq>\n    <priority>0.7</priority>\n  </url>\n' "${BASE_URL}" "${person_base}"
    done < <(find ../people -maxdepth 1 -type f -name "*.html" 2>/dev/null | sort)

    printf '\n  <!-- %s -->\n' "${SITE_TITLE}"
    printf '  <url>\n    <loc>%s%s</loc>\n    <changefreq>weekly</changefreq>\n    <priority>0.9</priority>\n  </url>\n' "${BASE_URL}" "${SV_PATH}"

    while IFS= read -r dir; do
      [[ -z "${dir}" ]] && continue
      [[ -n "${DRAFT_PREFIX}" && "${dir}" == "${DRAFT_PREFIX}"* ]] && continue
      printf '\n  <!-- %s -->\n' "${dir//_/ }"
      printf '  <url>\n    <loc>%s%s#%s.md</loc>\n    <changefreq>monthly</changefreq>\n    <priority>0.7</priority>\n  </url>\n' "${BASE_URL}" "${SV_PATH}" "${dir}"
      while IFS= read -r chap; do
        [[ -z "${chap}" ]] && continue
        chap_base=$(basename "${chap}")
        printf '  <url>\n    <loc>%s%s#%s%%2F%s</loc>\n    <changefreq>monthly</changefreq>\n    <priority>0.6</priority>\n  </url>\n' "${BASE_URL}" "${SV_PATH}" "${dir}" "${chap_base}"
      done < <(find "${dir}" -maxdepth 1 -type f -name "chapter_*.md" | sort)
    done < <(printf '%s\n' "${LIST}" | sort -f)

    printf '\n</urlset>\n'
  } > "${SITEMAP_PATH}"
  progress_count=$((progress_count + 1))
  progress "${progress_count}" "${total_work}" "Updated sitemap.xml"
fi
