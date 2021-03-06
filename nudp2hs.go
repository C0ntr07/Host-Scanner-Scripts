package main

import (
	"os"
	"bufio"
	"regexp"
	"strconv"
	"io/ioutil"
	"encoding/json"
	"encoding/binary"
)

var entries []entry

type entry struct {
	Ports []int
	Data string
}

// Reads the specified file and sends the entries for processing.
func parseInput(file string) error {
	var err error
	var fp  *os.File

	if fp, err = os.Open(file); err != nil {
		return err
	}

	defer fp.Close()

	txt, _ := ioutil.ReadAll(fp)
	dat := string(txt)

	resc, _ := regexp.Compile(`(?m:^\s*#.*$)`) // strip comments
	reme, _ := regexp.Compile(`(?m:udp\s+((?:\d+\,)*\d+)\s+((?:".+"\s*)*))`) // match udp entries from port to payload
	resp, _ := regexp.Compile(`(?m:\s*,\s*)`) // split enumerated ports by separator
	remp, _ := regexp.Compile(`(?m:"(.+)")`) // match data within the quotes optionally spread across multiple lines

	dat = resc.ReplaceAllString(dat, " ")
	mc := reme.FindAllStringSubmatch(dat, -1)

	for _, m := range mc {
		entry := entry { }

		// extract port numbers

		for _, port := range resp.Split(m[1], -1) {
			if i, e := strconv.Atoi(port); e == nil {
				entry.Ports = append(entry.Ports, i)
			}
		}

		// extract payload

		for _, data := range remp.FindAllStringSubmatch(m[2], -1) {
			entry.Data += data[1]
		}

		if unquoted, e := strconv.Unquote("\"" + entry.Data + "\""); e == nil {
			entry.Data = unquoted
		}

		entries = append(entries, entry)
	}

	return err
}

// Writes the globally loaded entries to the specified file.
func serializeEntries(file string, debug bool) error {
	var err error
	var fp  *os.File

	if fp, err = os.Create(file); err != nil {
		return err
	}

	defer fp.Close()

	bw := bufio.NewWriter(fp)

	if debug {
		var bs []byte
		bs, err = json.MarshalIndent(entries, "", "\t")

		bw.Write(bs)
		bw.Flush()

		return err
	}

	// package type: UDP payloads
	binary.Write(bw, binary.LittleEndian, uint16(10))
	// package version
	binary.Write(bw, binary.LittleEndian, uint16(1))
	// number of entries
	binary.Write(bw, binary.LittleEndian, uint32(len(entries)))

	for _, entry := range entries {
		// payload data
		binary.Write(bw, binary.LittleEndian, uint16(len(entry.Data)))
		bw.WriteString(entry.Data)

		// number of ports in entry
		binary.Write(bw, binary.LittleEndian, uint16(len(entry.Ports)))

		for _, port := range entry.Ports {
			binary.Write(bw, binary.LittleEndian, uint16(port))
		}
	}

	binary.Write(bw, binary.LittleEndian, uint32(0))

	bw.Flush()

	return err
}

// Entry point of the application.
func main() {
	if len(os.Args) < 3 {
		println("usage: nudp2hs [--json] input output")
		os.Exit(-1)
	}

	var err error
	var dbg bool

	if os.Args[1] == "--json" {
		dbg = true
		os.Args = os.Args[1:]
	}

	println("Parsing nmap payloads database...")

	if err = parseInput(os.Args[1]); err != nil {
		println(err)
		os.Exit(-1)
	}

	println("Writing parsed data...")

	if err = serializeEntries(os.Args[2], dbg); err != nil {
		println(err)
		os.Exit(-1)
	}
}