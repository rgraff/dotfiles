# So Ruby gems with native extensions (e.g. psych) can find Homebrew's libyaml
[[ -d "$(brew --prefix libyaml 2>/dev/null)/lib/pkgconfig" ]] && \
  export PKG_CONFIG_PATH="$(brew --prefix libyaml)/lib/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"

for dir in /opt/homebrew/bin /usr/local/bin "$DOTHOME/bin" .git/safe/../../bin .git/bin; do
  case "$PATH:" in
    *:"$dir":*) PATH="`echo "$PATH"|sed -e "s#:$dir##"`" ;;
  esac
  case "$dir" in
    /*) [ ! -d "$dir" ] || PATH="$dir:$PATH" ;;
    *) PATH="$dir:$PATH" ;;
  esac
done

for dir in /usr/local/sbin /opt/local/sbin /usr/X11/bin; do
  case ":$PATH:" in
    *:"$dir":*) ;;
    *) [ ! -d "$dir" ] || PATH="$PATH:$dir" ;;
  esac
done
