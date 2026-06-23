if status is-interactive
    fastfetch
    starship init fish | source
    mise activate fish | source
end
export PATH="$HOME/.local/bin:$PATH"
