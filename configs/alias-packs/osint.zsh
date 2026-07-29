alias whois-full='whois'
alias dns-all='dig ANY'
alias subdomains='subfinder -silent -d'
alias osint-email='theHarvester -b all -d'
alias metadata-web='exiftool'

crtsearch() {
    [[ $# -eq 1 ]] || { echo "Usage: crtsearch <domain>" >&2; return 2; }
    curl -fsSL "https://crt.sh/?output=json&q=%25.$1" | jq -r '.[].name_value' | sort -u
}
