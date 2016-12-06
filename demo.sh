#!/bin/bash
highlight() {
	grep --color '[^ ]*\s*insns per cycle\|$'
}
runecho() {
	echo $@
	"$@"
}
bold=$(tput rev;tput bold)
normal=$(tput sgr0)
boldecho() {
	echo ${bold}$@${normal}
}
