package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strconv"
	"strings"
)

var preferredSizes = []int{48, 32, 64, 24, 128, 22, 16, 256}
var imageExtensions = []string{".png", ".svg", ".xpm"}

func xdgDataDirs() []string {
	var dirs []string

	if home, ok := os.LookupEnv("HOME"); ok {
		dirs = append(dirs, filepath.Join(home, ".local", "share"))
	}

	xdgData := os.Getenv("XDG_DATA_DIRS")
	if xdgData == "" {
		xdgData = "/usr/local/share:/usr/share"
	}
	for _, d := range strings.Split(xdgData, ":") {
		if d != "" {
			dirs = append(dirs, d)
		}
	}

	return dirs
}

func currentIconTheme() string {
	candidates := []string{}

	if home, ok := os.LookupEnv("HOME"); ok {
		candidates = append(candidates,
			filepath.Join(home, ".config", "gtk-4.0", "settings.ini"),
			filepath.Join(home, ".config", "gtk-3.0", "settings.ini"),
		)
	}

	for _, path := range candidates {
		f, err := os.Open(path)
		if err != nil {
			continue
		}
		scanner := bufio.NewScanner(f)
		for scanner.Scan() {
			line := strings.TrimSpace(scanner.Text())
			if strings.HasPrefix(line, "gtk-icon-theme-name") {
				parts := strings.SplitN(line, "=", 2)
				if len(parts) == 2 {
					theme := strings.TrimSpace(parts[1])
					f.Close()
					return theme
				}
			}
		}
		f.Close()
	}

	return "hicolor"
}

type themeIndex struct {
	dirs []themeDir
}

type themeDir struct {
	path    string
	size    int
	minSize int
	maxSize int
	dirType string
}

func parseIndex(themeBasePath string) themeIndex {
	indexPath := filepath.Join(themeBasePath, "index.theme")
	f, err := os.Open(indexPath)
	if err != nil {
		return themeIndex{}
	}
	defer f.Close()

	var result themeIndex
	var currentSection string
	dirSizes := map[string]int{}
	dirMin := map[string]int{}
	dirMax := map[string]int{}
	dirTypes := map[string]string{}
	var dirList []string
	seenDirs := map[string]bool{}

	scanner := bufio.NewScanner(f)
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}
		if strings.HasPrefix(line, "[") && strings.HasSuffix(line, "]") {
			currentSection = line[1 : len(line)-1]
			if currentSection != "Icon Theme" && !seenDirs[currentSection] {
				dirList = append(dirList, currentSection)
				seenDirs[currentSection] = true
			}
			continue
		}
		if currentSection == "Icon Theme" {
			continue
		}
		parts := strings.SplitN(line, "=", 2)
		if len(parts) != 2 {
			continue
		}
		key := strings.TrimSpace(parts[0])
		val := strings.TrimSpace(parts[1])

		switch key {
		case "Size":
			if n, err := strconv.Atoi(val); err == nil {
				dirSizes[currentSection] = n
			}
		case "MinSize":
			if n, err := strconv.Atoi(val); err == nil {
				dirMin[currentSection] = n
			}
		case "MaxSize":
			if n, err := strconv.Atoi(val); err == nil {
				dirMax[currentSection] = n
			}
		case "Type":
			dirTypes[currentSection] = val
		}
	}

	for _, dir := range dirList {
		sz := dirSizes[dir]
		if sz == 0 {
			continue
		}
		mn := dirMin[dir]
		if mn == 0 {
			mn = sz
		}
		mx := dirMax[dir]
		if mx == 0 {
			mx = sz
		}
		dt := dirTypes[dir]
		if dt == "" {
			dt = "Threshold"
		}
		result.dirs = append(result.dirs, themeDir{
			path:    filepath.Join(themeBasePath, dir),
			size:    sz,
			minSize: mn,
			maxSize: mx,
			dirType: dt,
		})
	}

	return result
}

func dirMatchesSize(d themeDir, size int) bool {
	switch d.dirType {
	case "Fixed":
		return d.size == size
	case "Scalable":
		return size >= d.minSize && size <= d.maxSize
	case "Threshold":
		threshold := 2
		return size >= d.size-threshold && size <= d.size+threshold
	}
	return d.size == size
}

func dirSizeDistance(d themeDir, size int) int {
	switch d.dirType {
	case "Fixed":
		diff := d.size - size
		if diff < 0 {
			diff = -diff
		}
		return diff
	case "Scalable":
		if size < d.minSize {
			return d.minSize - size
		}
		if size > d.maxSize {
			return size - d.maxSize
		}
		return 0
	case "Threshold":
		threshold := 2
		if size < d.size-threshold {
			return d.size - threshold - size
		}
		if size > d.size+threshold {
			return size - d.size - threshold
		}
		return 0
	}
	diff := d.size - size
	if diff < 0 {
		diff = -diff
	}
	return diff
}

func findIconInTheme(name string, index themeIndex, size int) string {
	for _, d := range index.dirs {
		if !dirMatchesSize(d, size) {
			continue
		}
		for _, ext := range imageExtensions {
			p := filepath.Join(d.path, name+ext)
			if _, err := os.Stat(p); err == nil {
				return p
			}
		}
	}

	bestDist := 1<<31 - 1
	bestPath := ""
	for _, d := range index.dirs {
		dist := dirSizeDistance(d, size)
		if dist >= bestDist {
			continue
		}
		for _, ext := range imageExtensions {
			p := filepath.Join(d.path, name+ext)
			if _, err := os.Stat(p); err == nil {
				bestDist = dist
				bestPath = p
				break
			}
		}
	}
	return bestPath
}

func findIconInDir(name string, dir string) string {
	for _, ext := range imageExtensions {
		p := filepath.Join(dir, name+ext)
		if _, err := os.Stat(p); err == nil {
			return p
		}
	}
	return ""
}

func resolveIcon(name string, dataDirs []string, themes []string, indexCache map[string]themeIndex) string {
	if name == "" {
		return ""
	}

	if strings.HasPrefix(name, "/") {
		if _, err := os.Stat(name); err == nil {
			return name
		}
		name = strings.TrimSuffix(filepath.Base(name), filepath.Ext(name))
	}

	for _, size := range preferredSizes {
		for _, dataDir := range dataDirs {
			for _, theme := range themes {
				key := dataDir + ":" + theme
				idx, ok := indexCache[key]
				if !ok {
					idx = parseIndex(filepath.Join(dataDir, "icons", theme))
					indexCache[key] = idx
				}
				if p := findIconInTheme(name, idx, size); p != "" {
					return p
				}
			}
		}
	}

	for _, dataDir := range dataDirs {
		if p := findIconInDir(name, filepath.Join(dataDir, "pixmaps")); p != "" {
			return p
		}
	}

	return ""
}

func main() {
	args := os.Args[1:]

	if len(args) == 0 {
		fmt.Fprintln(os.Stderr, "usage: icon-resolver <name> [name ...]")
		fmt.Fprintln(os.Stderr, "       icon-resolver --batch   (newline-separated names on stdin)")
		os.Exit(1)
	}

	dataDirs := xdgDataDirs()
	currentTheme := currentIconTheme()

	var themes []string
	if currentTheme != "hicolor" {
		themes = append(themes, currentTheme)
	}
	themes = append(themes, "hicolor")

	indexCache := map[string]themeIndex{}

	if len(args) == 1 && args[0] == "--batch" {
		results := map[string]string{}
		scanner := bufio.NewScanner(os.Stdin)
		for scanner.Scan() {
			name := strings.TrimSpace(scanner.Text())
			if name == "" {
				continue
			}
			results[name] = resolveIcon(name, dataDirs, themes, indexCache)
		}
		json.NewEncoder(os.Stdout).Encode(results)
		return
	}

	results := map[string]string{}
	for _, name := range args {
		results[name] = resolveIcon(name, dataDirs, themes, indexCache)
	}
	json.NewEncoder(os.Stdout).Encode(results)
}
