#! /bin/bash

pm() {
    get_package_manager() {
        if [[ -n $PM_MANAGER ]]; then
            echo $PM_MANAGER
        else
            if command -v apt &> /dev/null; then
                echo "apt"
            elif command -v pacman &> /dev/null; then
                echo "pacman"
            elif command -v dnf &> /dev/null; then
                echo "dnf"
            elif command -v yum &> /dev/null; then
                echo "yum"
            elif command -v zypper &> /dev/null; then
                echo "zypper"
            else
                echo "Unsupported package manager or not detected."
                return 1
            fi
        fi
    }

    declare -A PM_ACTIONS
    declare -A PM_ACTION_ALIASES

    PM_ACTIONS[apt,install]="sudo apt install -y"
    PM_ACTIONS[apt,uninstall]="sudo apt remove -y"
    PM_ACTIONS[apt,update]="sudo apt upgrade -y"
    PM_ACTIONS[apt,fetch]="sudo apt update"
    PM_ACTIONS[apt,clean]="sudo apt autoclean"
    PM_ACTIONS[apt,list]="dpkg --get-selections | grep -v deinstall"
    PM_ACTIONS[apt,info]="apt show"
    PM_ACTIONS[apt,prune]="sudo apt autoremove -y"

    PM_ACTIONS[pacman,install]="sudo pacman -S --noconfirm"
    PM_ACTIONS[pacman,uninstall]="sudo pacman -Rns --noconfirm"
    PM_ACTIONS[pacman,update]="sudo pacman -Syu --noconfirm"
    PM_ACTIONS[pacman,fetch]="sudo pacman -Sy"
    PM_ACTIONS[pacman,clean]="sudo pacman -Scc"
    PM_ACTIONS[pacman,list]="pacman -Q"
    PM_ACTIONS[pacman,info]="pacman -Qi"
    PM_ACTIONS[pacman,prune]="sudo pacman -Rns --noconfirm"

    PM_ACTIONS[dnf,install]="sudo dnf install -y"
    PM_ACTIONS[dnf,uninstall]="sudo dnf remove -y"
    PM_ACTIONS[dnf,update]="sudo dnf upgrade -y"
    PM_ACTIONS[dnf,fetch]="sudo dnf check-update"
    PM_ACTIONS[dnf,clean]="sudo dnf clean all"
    PM_ACTIONS[dnf,list]="dnf list installed"
    PM_ACTIONS[dnf,info]="dnf info"
    PM_ACTIONS[dnf,prune]="sudo dnf autoremove -y"

    PM_ACTIONS[yum,install]="sudo yum install -y"
    PM_ACTIONS[yum,uninstall]="sudo yum remove -y"
    PM_ACTIONS[yum,update]="sudo yum update -y"
    PM_ACTIONS[yum,fetch]="sudo yum check-update"
    PM_ACTIONS[yum,clean]="sudo yum clean all"
    PM_ACTIONS[yum,list]="yum list installed"
    PM_ACTIONS[yum,info]="yum info"
    PM_ACTIONS[yum,prune]="sudo yum autoremove -y"

    PM_ACTIONS[zypper,install]="sudo zypper install -y"
    PM_ACTIONS[zypper,uninstall]="sudo zypper remove -y"
    PM_ACTIONS[zypper,update]="sudo zypper update -y"
    PM_ACTIONS[zypper,fetch]="sudo zypper refresh"
    PM_ACTIONS[zypper,clean]="sudo zypper clean"
    PM_ACTIONS[zypper,list]="zypper packages --installed-only"
    PM_ACTIONS[zypper,info]="zypper info"
    PM_ACTIONS[zypper,prune]="sudo zypper remove -y"

    PM_ACTION_ALIASES[i]="install"
    PM_ACTION_ALIASES[install]="install"
    PM_ACTION_ALIASES[u]="uninstall"
    PM_ACTION_ALIASES[uninstall]="uninstall"
    PM_ACTION_ALIASES[r]="uninstall"
    PM_ACTION_ALIASES[rm]="uninstall"
    PM_ACTION_ALIASES[remove]="uninstall"
    PM_ACTION_ALIASES[U]="update"
    PM_ACTION_ALIASES[up]="update"
    PM_ACTION_ALIASES[update]="update"
    PM_ACTION_ALIASES[f]="fetch"
    PM_ACTION_ALIASES[fetch]="fetch"
    PM_ACTION_ALIASES[c]="clean"
    PM_ACTION_ALIASES[clean]="clean"
    PM_ACTION_ALIASES[l]="list"
    PM_ACTION_ALIASES[ls]="list"
    PM_ACTION_ALIASES[list]="list"
    PM_ACTION_ALIASES[I]="info"
    PM_ACTION_ALIASES[info]="info"
    PM_ACTION_ALIASES[p]="prune"
    PM_ACTION_ALIASES[prune]="prune"

    PM=$(get_package_manager)

    function installed_packages() {
        case $PM in
            apt)
                dpkg-query -f '${binary:Package}\n' -W 
                ;;
            pacman)
                pacman -Qq 
                ;;
            dnf|yum)
                rpm -qa --qf '%{NAME}\n'
                ;;
            zypper)
                rpm -qa --qf '%{NAME}\n'
                ;;
        esac
    }

    function available_packages() {
        case $PM in
            apt)
                comm -23 <(apt-cache dumpavail | awk '/^Package:/{print $2}' | sort) <(dpkg-query -f '${binary:Package}\n' -W | sort)
                ;;
            pacman)
                comm -23 <(pacman -Slq | sort) <(pacman -Qq | sort)
                ;;
            dnf)
                comm -23 <(dnf repoquery --available --qf '%{name}' | sort) <(rpm -qa --qf '%{NAME}\n' | sort)
                ;;
            yum)
                comm -23 <(yum list available | awk '{print $1}' | sort) <(rpm -qa --qf '%{NAME}\n' | sort)
                ;;
            zypper)
                comm -23 <(zypper packages --not-installed | awk 'NR>2 {print $5}' | sort) <(rpm -qa --qf '%{NAME}\n' | sort)
                ;;
        esac
    }

    function all_packages() {
        case $PM in
            apt)
                {
                    installed_packages | awk '{print $1 " [installed]"}'
                    available_packages
                } | sort | uniq
                ;;
            pacman)
                {
                    installed_packages | awk '{print $1 " [installed]"}'
                    available_packages
                } | sort | uniq
                ;;
            dnf|yum)
                {
                    installed_packages | awk '{print $1 " [installed]"}'
                    available_packages
                } | sort | uniq
                ;;
            zypper)
                {
                    installed_packages | awk '{print $1 " [installed]"}'
                    available_packages
                } | sort | uniq
                ;;
        esac
    }

    function list_installed(){
        installed_packages | fzf --multi --exit-0
    }

    function list_available(){
        available_packages | fzf --multi --exit-0
    }

    function list_all(){
        all_packages | fzf --multi --exit-0
    }

get_info() {
    local package="$1"
    case $PM in
        apt)
            apt-cache show "$package"
            ;;
        pacman)
            pacman -Qi "$package" || pacman -Si "$package"
            ;;
        dnf|yum)
            rpm -qi "$package" || dnf info "$package"
            ;;
        zypper)
            rpm -qi "$package" || zypper info "$package"
            ;;
    esac
}

 
    get_action_command() {
        local action="$1"
        local pm="$2"
        local resolved_action="${PM_ACTION_ALIASES[$action]}"

        if [[ -z "$resolved_action" ]]; then
            echo "Invalid action: $action"
            return 1
        fi

        echo "${PM_ACTIONS[$pm,$resolved_action]}"
    }

    execute_action() {
        local action_name="$1"
        local package="$2"

        local action_command
        action_command=$(get_action_command "$action_name" "$PM")
 
        eval "$action_command $package"

    }

    elif [[ "$action_name" == "list_installed" ]]; then
        
    elif [[ "$action_name" == "list_available" ]]; then
        available_packages | fzf --multi --exit-0
    elif [[ "$action_name" == "list_all" ]]; then
        all_packages | fzf --multi --exit-0
    else
        echo "No packages selected or specified."
    fi
}
 

case $1 in
    i|install)
        if [[ -n $2 ]]; then
            execute_action "install" "$2"
        else
            packages=$(available_packages | fzf --multi --exit-0)
            if [[ -z "$packages" ]]; then
                echo "No packages selected."
                return 1
            fi
            execute_action "install" "$packages"
        fi
        ;;
    u|uninstall|r|rm|remove)
        if [[ -n $2 ]]; then
            execute_action "uninstall" "$2"
        else
            packages=$(installed_packages | fzf --multi --exit-0)
            if [[ -z "$packages" ]]; then
                echo "No packages selected."
                return 1
            fi
            execute_action "uninstall" "$packages"
        fi
        ;;
    U|up|update)
        if [[ -n $2 ]]; then
            execute_action "update" "$2"
        else
            packages=$(installed_packages | fzf --multi --exit-0)
            if [[ -z "$packages" ]]; then
                echo "No packages selected."
                return 1
            fi
            execute_action "update" "$packages"
        fi
        ;;
    f|fetch)
        execute_action "fetch" ""
        ;;
    c|clean)
        execute_action "clean" ""
        ;;
    l|ls|list)
        case $2 in
            i|installed)
                execute_action "list_installed" ""
                ;;
            a|available)
                execute_action "list_available" ""
                ;;
            A|all)
                execute_action "list_all" ""
                ;;
            *)
                echo "Usage: pm l/ls/list [i/installed | a/available | A/all]"
                ;;
        esac
        ;;
    I|info)
        if [[ -n $2 ]]; then
            get_info "$2"
        else
            package=$(all_packages | fzf --multi --exit-0)
            if [[ -z "$package" ]]; then
                echo "No package selected."
                return 1
            fi
            get_info "${package%% *}"
        fi
        ;;
    p|prune)
        if [[ -n $2 ]]; then
            execute_action "prune" "$2"
        else
            packages=$(installed_packages | fzf --multi --exit-0)
            if [[ -z "$packages" ]]; then
                echo "No packages selected."
                return 1
            fi
            for package in $packages; do
                execute_action "prune" "$package"
            done
        fi
        ;;
    *)
        echo "Usage: pm [option] [package_name]"
        ;;
esac
}

