if status is-interactive
    fastfetch
    starship init fish | source
    mise activate fish | source
    set -gx PATH $HOME/.local/share/mise/shims $PATH
end
set fish_greeting
export PATH="$HOME/.dotnet/tools:$PATH"
export PATH="$HOME/.local/bin:$PATH"
