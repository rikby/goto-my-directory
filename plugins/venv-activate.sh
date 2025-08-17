venv-activate() {
    local color_success color_note color_error_head color_error found_activate
    color_success='\033[32m'
    color_note='\033[36m'
    color_error_head='\033[31m'
    color_error='\033[33m'
    color_error_note='\033[90m'
    color_reset='\033[0m'

    found_activate=""
    for dir in venv/bin .venv/bin bin; do
        if [ -f "$dir/activate" ]; then
            found_activate="$dir/activate"
            break
        fi
    done

    if [ -f "${found_activate}" ]; then
        source "${found_activate}" && echo -e "${color_success}✓ Python virtual environment activated successfully! ${color_note}(${ACTIVATE_SCRIPT})${color_reset}"
    else
        echo -e "${color_error_head}✗ Error: ${color_error}bin/activate not found in this directory${color_reset}" > /dev/stderr
        echo -e "${color_error_note}  Searched in: bin/, venv/bin/, .venv/bin/${color_reset}" > /dev/stderr
    fi
}