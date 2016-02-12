#!/bin/bash

if [[ -z $1 || $1 == "cpealt" ]] && [[ -f cpe-aliases ]]; then
	rm -f cpe-aliases.dat cpe-aliases.dat.gz
	go run cpealt2hs.go cpe-aliases cpe-aliases.dat
	gzip -9 cpe-aliases.dat
fi

if [[ -z $1 || $1 == "nudp" ]] && [[ -f nmap-payloads ]]; then
	rm -f payloads-nmap.dat payloads-nmap.dat.gz
	go run nudp2hs.go nmap-payloads payloads-nmap.dat
	gzip -9 payloads-nmap.dat
fi

if [[ -z $1 || $1 == "zudp" ]] && [[ -d zmap/examples/udp-probes ]]; then
	rm -f payloads-zmap.dat payloads-zmap.dat.gz
	go run zudp2hs.go zmap/examples/udp-probes payloads-zmap.dat
	gzip -9 payloads-zmap.dat
fi

if [[ -z $1 || $1 == "ncpe" ]] && [[ -f nmap-service-probes ]]; then
	rm -f cpe-regex-nmap.dat cpe-regex-nmap.dat.gz
	go run ncpe2hs.go nmap-service-probes cpe-regex-nmap.dat
	gzip -9 cpe-regex-nmap.dat
fi

if [[ -z $1 || $1 == "cpe" ]] && [[ -f cpe-dict.xml ]]; then
	rm -f cpe-list.dat cpe-list.dat.gz
	go run cpe2hs.go cpe-dict.xml cpe-list.dat
	gzip -9 cpe-list.dat
fi

if [[ -z $1 || $1 == "cve" ]] && [[ -f cve-items.xml ]]; then
	rm -f cve-list.dat cve-list.dat.gz
	go run cve2hs.go cve-items.xml cve-list.dat
	gzip -9 cve-list.dat
fi