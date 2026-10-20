#!/bin/bash

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

# Find all directories (excluding hidden ones) and count the work before starting
LIST=$(find -mindepth 1 -maxdepth 1 -type d ! -name ".*" | sed "s/.*\///g")
directory_total=$(printf '%s\n' "${LIST}" | sed '/^$/d' | wc -l)
chapter_work_total=0
for i in ${LIST} ; do
    chapter_count=$(find ${i} -mindepth 1 -maxdepth 1 -type f -name "chapter_*.md" | wc -l)
    chapter_work_total=$((chapter_work_total + chapter_count))
done
existing_markdown_total=$(find -type f -name "*.md" | wc -l)
root_markdown_total=$(find -mindepth 1 -maxdepth 1 -type f -name "*.md" | wc -l)
copyright_total=$((existing_markdown_total - root_markdown_total + directory_total + 1))
total_work=$((directory_total + chapter_work_total * 3 + copyright_total))
progress 0 "${total_work}" "Starting"

# Remove all markdown files in the current directory
rm -r *.md

# Create a new README.md file with a title
echo "# SkillVerse" > README.md

progress_count=0
for i in ${LIST} ; do
    # Add each directory as a section in README.md
    if [[ ${i} != ___* ]]; then
      echo "  - ### [$(echo ${i} | sed -e 's/_/ /g')](${i}.md)" >> README.md
    fi
    # Create a new markdown file for each directory with a title
    echo "# $(echo ${i} | sed -e 's/_/ /g')" > ${i}.md

    # Find all chapter markdown files in the directory and rename them temporarily
    LIST1=$(find ${i} -mindepth 1 -maxdepth 1 -type f -name "chapter_*.md")
    for j in ${LIST1} ; do
        TMP_NAME=$(echo ${j} | sed "s/chapter_/temp_chapter_/g")
        mv ${j} ${TMP_NAME}
        progress_count=$((progress_count + 1))
        progress "${progress_count}" "${total_work}" "Preparing ${j}"
    done

    # Rename the temporary chapter files back to their original names with zero-padded numbers
    count=1
    LIST2=$(find ${i} -mindepth 1 -maxdepth 1 -type f -name "temp_chapter_*.md")
    for j in ${LIST2} ; do
        FINAL_NAME=$(echo ${j} | sed "s/temp_chapter_.*\./chapter_$(printf "%05d." ${count})/g")
        mv ${j} ${FINAL_NAME}
        count=$((count + 1))
        progress_count=$((progress_count + 1))
        progress "${progress_count}" "${total_work}" "Renumbering ${j}"
    done

    # Add each chapter file as a section in the directory's markdown file
    LIST3=$(find ${i} -mindepth 1 -maxdepth 1 -type f -name "chapter_*.md")
    for j in ${LIST3} ; do
        TITLE=$(cat ${j} | grep -m 1 "^# " | sed "s/^# //g" | sed "s/:.*//g")
        echo "## $(echo "${j}" | sed "s/.*chapter_0*//g" | sed "s/\..*//g"). [$(echo ${TITLE} | sed -e 's/_/ /g')](${j})" >> ${i}.md
        cat ${j} | grep "^## " | sed "s/^## /  - /g" | sed "s/:.*//g" | sed "s/\*//g" | sed "s/#//g"  | sed "s/\`//g" >> ${i}.md
        progress_count=$((progress_count + 1))
        progress "${progress_count}" "${total_work}" "Indexing ${j}"
    done

    progress_count=$((progress_count + 1))
    progress "${progress_count}" "${total_work}" "Processed ${i}"
done

# Find all markdown files and update copyright information
list=$(find -type f -name "*.md")

for file in ${list} ; do
  # Check if the file already contains a copyright notice
  if grep -Eq "Copyright \(c\) [0-9]{4} squared-studio" $file ; then
    # Update the existing copyright notice with the current year
    sed -i "s/.*Copyright (c) [0-9]\{4\} squared-studio.*/##### Copyright (c) $(date +%Y) squared-studio/g" $file
  else
    # Add a new copyright notice if not present
    echo "" >> $file
    echo "##### Copyright (c) $(date +%Y) squared-studio" >> $file
    echo "" >> $file
  fi
  progress_count=$((progress_count + 1))
  progress "${progress_count}" "${total_work}" "Updated ${file}"
done
