YELLOW=$(echo "\033[33m")
BLUE=$(echo "\033[36m")
RED=$(echo "\033[01;31m")
CL=$(echo "\033[m")
PURPLE=$(echo "\033[0;35m")
GREEN=$(echo "\033[0;32m")

# Проверяем, существует ли путь в PATH
if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
    # Если не существует, добавляем его
    PATH="$HOME/.local/bin:$PATH"
    # Экспортируем обновленный PATH
    export PATH
fi

error() {
  printf "${RED}✗  %s${CL}\n" "$*" >&2

  exit 1
}

started() {
  printf "${BLUE}… %s${CL}\n" "$*"
}

warn() {
  printf "${YELLOW}‼ %s${CL}\n" "$*"
}

info() {
  printf "${PURPLE}• %s${CL}\n" "$*"
}

finished() {
  printf "${GREEN}✓ %s${CL}\n" "$*"
}

is_installed() {
  command -v "$1" >/dev/null 2>&1
}

check_sudo() {
  if sudo -n true 2>/dev/null; then
      warn "Пользователь может использовать sudo."
  else
      warn "💥  Пользователь не может использовать sudo."
      exit 0
  fi
}

### Example
#
# if is_confirm "Do you want to proceed?"; then
#   echo "User confirmed."
# else
#   echo "User did not confirm."
# fi
is_confirm() {
  printf "%s [y/N] " "$1" > /dev/tty
  read -r response < /dev/tty
  case "$response" in
    [yY][eE][sS]|[yY]) return 0 ;;
    *) return 1 ;;
  esac
}

http_download_curl() {
	local_file="${1}"
	source_url="${2}"

  code="$(curl -w '%{http_code}' -sL -o "${local_file}" "${source_url}")"

	if [ "${code}" != "200" ]; then
		error "http_download_curl received HTTP status ${code}"
		return 1
	fi
	return 0
}

http_download_wget() {
	local_file="${1}"
	source_url="${2}"
  wget -q -O "${local_file}" "${source_url}" || return 1
}

http_download() {
	started "download ${2}"
	if is_installed curl; then
		http_download_curl "${@}" || return 1
		return
	elif is_installed wget; then
		http_download_wget "${@}" || return 1
		return
	fi
	error "http_download unable to find wget or curl"
	return 1
}

nexus_download() {
  http_download "$1" "https://nexus.int.205kin.ru/repository/files/$2"
}

untar() {
	tarball="${1}"
	case "${tarball}" in
	*.tar.gz | *.tgz) tar -xzf "${tarball}" ;;
	*.tar) tar -xf "${tarball}" ;;
	*.zip) unzip -- "${tarball}" ;;
	*)
		error "untar unknown archive format for ${tarball}"
		return 1
		;;
	esac
}