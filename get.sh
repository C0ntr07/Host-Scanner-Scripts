#!/bin/bash

echo -e "\e[32mDownloading CPE aliases...\e[39m"

rm -f cpe-aliases
wget https://anonscm.debian.org/viewvc/secure-testing/data/CPE/aliases\?view=co -O cpe-aliases

echo -e "\e[32mDownloading nmap payloads...\e[39m"

rm -f nmap-payloads
wget https://svn.nmap.org/nmap/nmap-payloads -O nmap-payloads

echo -e "\e[32mDownloading nmap probes...\e[39m"

rm -f nmap-service-probes
wget https://svn.nmap.org/nmap/nmap-service-probes -O nmap-service-probes

echo -e "\e[32mDownloading CPE dictionary...\e[39m"

rm -f cpe-dict.xml cpe-dict.xml.gz
wget http://static.nvd.nist.gov/feeds/xml/cpe/dictionary/official-cpe-dictionary_v2.3.xml.gz -O cpe-dict.xml.gz
gzip -d cpe-dict.xml.gz

echo -e "\e[32mDownloading zmap probes...\e[39m"

(
rm -rf zmap/
git init zmap
cd zmap
git config core.sparseCheckout true
git remote add origin https://github.com/zmap/zmap
echo "examples/udp-probes/*.pkt" >> .git/info/sparse-checkout
git pull --depth=1 origin master
)

rm -f cve-items.xml
year=$(date +'%Y')
for i in $(seq 2002 $year); do
	echo -e "\e[32mDownloading CVE database for $i...\e[39m"
	rm -f "cve-items-$i.xml"
	wget "http://static.nvd.nist.gov/feeds/xml/cve/nvdcve-2.0-$i.xml.gz" -O "cve-items-$i.xml.gz"

	echo -e "\e[32mProcessing CVE database for $i...\e[39m"
	gzip -d "cve-items-$i.xml.gz"
	sed -i -r -e 's#<(/)?(vuln|cvss|cpe-lang):#<\1#g' "cve-items-$i.xml"
	cat "cve-items-$i.xml" >> cve-items.xml
	rm -f "cve-items-$i.xml"
done

echo -e "\e[32mProcessing merged CVE database...\e[39m"

awk -i inplace '/^\s*<\/nvd><\?xml/{next} NR>3&&/^\s*<nvd/{next} //{print $0}' cve-items.xml