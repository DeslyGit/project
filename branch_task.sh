#!/bin/bash

git pull
git checkout -B "storage_1c" "origin/storage_1c"
git pull
git checkout -B "branch_sync_hran" "origin/branch_sync_hran"

# Получение списка коммитов
logof=$(git log --reverse storage_1c...branch_sync_hran --pretty=format:"%h;%s|" | tr -d '\r\n')

IFS='|' read -ra my_array <<< "$logof"

for i in "${my_array[@]}"
do
    # Извлечение номера задачи
    #BranchName=($(echo $i | sed 's/.*;//' | grep -oP --regexp="$prefix\K\d+"))    
    BranchName=($(echo $i | sed 's/.*;//'))
   
    commit=($(echo $i | sed 's/;.*//'))
    # Переключение или создание feature-ветки
    git checkout -B "feature/${BranchName}" "origin/feature/${BranchName}" 2>/dev/null || git checkout -B "feature/${BranchName}" 
    
    # Cherry-pick коммита
    git cherry-pick "${commit}" --keep-redundant-commits --strategy-option recursive -X theirs 
    
    # Удаление конфликтующих файлов
    git diff --name-only --diff-filter=U | xargs -I {} sh -c 'echo "Removing conflicted file: {}"; git rm -f {}'
    
    # Фиксация изменений
    git add . || { echo "Failed to add files"; exit 1; }
    
    git commit -m "feature/${BranchName} - ${commit}" 
    git push --set-upstream origin "feature/$BranchName" 
    
done

# Сброс, слияние и возврат
git reset --hard || { echo "Failed to reset"; exit 1; }
git checkout -B "branch_sync_hran" "origin/branch_sync_hran"
git merge "storage_1c"
git push origin "branch_sync_hran"
git checkout "storage_1c"  