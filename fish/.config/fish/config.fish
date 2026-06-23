if status is-interactive
    fastfetch
    starship init fish | source
    mise activate fish | source
end
set fish_greeting
export PATH="$HOME/.local/bin:$PATH"
