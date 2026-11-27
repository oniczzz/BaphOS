# BaphOS: prompt в две строки.
#   † onz  ~/projects/BaphOS  main*
#   ❯
# Стрелка алая; если прошлая команда упала — перед ней код ошибки.
function fish_prompt
    set -l last $status
    set -l red (set_color ff1a1a)
    set -l crimson (set_color c83030)
    set -l ember (set_color ff5040)
    set -l bone (set_color d8d8d8)
    set -l ash (set_color 787070)
    set -l off (set_color normal)

    set -g __fish_git_prompt_showdirtystate 1
    set -g __fish_git_prompt_char_dirtystate '*'
    set -g __fish_git_prompt_color_branch 787070
    set -l git (fish_vcs_prompt ' %s' 2>/dev/null)

    echo
    echo -s $red '† ' $bone $USER ' ' $crimson (prompt_pwd --full-length-dirs 2) $ash $git $off
    if test $last -ne 0
        echo -n -s $ember "[$last] ❯ " $off
    else
        echo -n -s $red '❯ ' $off
    end
end
