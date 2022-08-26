import strutils, rdstdin, strtabs
import htmlparser, xmltree, puppy
import os
import unicode, uri
import sequtils

# default target Url
var BaseURL = "https://funquizzes.fun/uploads/manga/"
# default extension to look for
var Extension = @[".jpg", ".png"]
# array of available Files
var Files: seq[string]

# clear the screen
proc clear() =
  if defined(Windows):
    discard execShellCmd("cls")
  else:
    discard execShellCmd("clear")

proc showLogo() =
  clear()
  echo "\e[33m"
  echo "         ██╗██████╗ ███████╗ ██████╗ █████╗ ███╗   ██╗"
  echo "         ██║██╔══██╗██╔════╝██╔════╝██╔══██╗████╗  ██║"
  echo "         ██║██████╔╝███████╗██║     ███████║██╔██╗ ██║"
  echo "    ██   ██║██╔═══╝ ╚════██║██║     ██╔══██║██║╚██╗██║"
  echo "    ╚█████╔╝██║     ███████║╚██████╗██║  ██║██║ ╚████║"
  echo "     ╚════╝ ╚═╝     ╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═══╝"
  echo "     A non official App - Just made by someone for fun"
  echo "              by default to download scan             "
  echo "\e[0m"
  echo ""

proc contains(s: string, exts: seq[string]): bool =
  for ext in exts:
    if s.contains(ext): return true
  return false

# get destination folder for files
proc getDest(): string =
  readLineFromStdin("    Path to the folder: ")

# ask user for a folder to add/remove
proc getFolder(path: string) =
  for kind, path in walkDir(path):
    case kind:
      of pcDir:
        let fn = extractFilename(path)
        if fn[0] != '.':
          echo "    ", fn
      else: discard
  echo ""

# handle the menu
proc menu(dest: string): uint =
  showLogo()
  echo "    Database loaded  : ", Files.len > 0
  echo "    Download url     : ", BaseURL
  echo:
    let a = "    Scan Extension   : "
    let b = Extension.join(" ")
    a & b
  echo "    Current content  : ", dest
  getFolder(dest)
  echo "    *................................*"
  echo:
    let c = "    1. \e[33mDownload a file"
    let d = "      (load db)\e[0m"
    if Files.len > 0: c & "\e[0m"
    else: c & d
  echo:
    let e = "    2. \e[34mShow available files"
    let f = " (load db)\e[0m"
    if Files.len > 0: e & "\e[0m"
    else: e & f
  echo "    3. \e[35mChange destination folder\e[0m"
  echo "    4. \e[32mCreate a folder\e[0m"
  echo "    5. \e[31mDelete a folder\e[0m"
  echo "    6. Quit"
  try:
    readLineFromStdin("    Your choice: ").parseUInt()
  except:
    7

# fetch all the root folders from the website
proc fetchFile() =
  echo "    fetching root directory...(this could take a while)"
  let html_code = parseHtml(fetch(BaseURL))
  for a in html_code.findAll("a"):
    var rootDir = a.attrs["href"].decodeUrl
    rootDir.removeSuffix('/')
    Files.add(rootDir)

# check str to see if they are similar
proc checkStr(s, ss: string): bool =
  let a = s.contains(ss) or ss.contains(s)
  let b = s.toLower.contains(ss.toLower) or s.toUpper.contains(ss.toUpper)
  a or b

# ask for a file to the user
proc getFile(): string =
  let choice = readLineFromStdin("    search file: ")
  var counter = 0
  for file in Files:
    if checkStr(choice, file):
      counter += 1
      echo "    - ", file
  if counter == 0: return ""
  let file = readLineFromStdin("    which file: ")
  for m in Files:
    if file == m: return file
  echo "    not a good choice.."
  sleep(1000)
  return ""

# loop through all the arborescence of the web server
# to find the .extension files
proc findAllUrls(url: string): seq[string] =
  let html_code = parseHtml(fetch(BaseURL&url))
  for a in html_code.findAll("a"):
    let entry = innerText(a)
    if entry in ["Name", "Last modified", "Size", "Description", "Parent Directory"]:
      continue
    elif entry.contains(Extension):
      result.add(BaseURL&url&entry)
    else:
      try:
        result = concat(result, findAllUrls(url&"/"&entry))
      except: discard

# get info from user to know which files download
proc getInfo(): seq[string] =
  if Files.len == 0: fetchFile()
  let file = getFile()
  if file == "":
    echo "    no file found..."
    sleep(2000)
    return @[]
  echo "    finding scans...(this could also take a while)"
  let urls = findAllUrls(file)
  return urls

# loading bar
proc loading(min, max: int) =
  stdout.write "\r    scan ", min,"/",max
  flushFile(stdout)

# download from url to file
proc dl(url, filename: string) =
  let data = fetch(url)
  writeFile(filename, data)

# download urls given in argument
proc download(urls: seq[string], dest: string) =
  for idx, url in urls:
    let filename = dest&"/"&url[BaseURL.len..<url.len]
    let dirs = filename.splitFile
    createDir(dirs.dir)
    dl(url, filename)
    loading(idx+1, urls.len)

# handle user's choice
proc handle(c: uint, dest: var string) =
  case(c):
    of 1: # download file
      createDir(dest)
      let urls = getInfo()
      if urls.len == 0: return
      download(urls, dest)
    of 2: # show available files
      if Files.len == 0: fetchFile()
      for file in Files:
        echo "    - ", file
      discard readLineFromStdin("    Press Enter to continue")
    of 3:
      dest = getDest()
    of 4: # add a folder
      getFolder(dest)
      let folder = readLineFromStdin("    Directory to create: ")
      createDir(dest&"/"&folder)
    of 5: # remove a folder
      getFolder(dest)
      let folder = readLineFromStdin("    Directory to delete: ")
      removeDir(dest&"/"&folder)
    of 6:
      echo "    bye-bye :3"
    else:
      echo "    bad choice..."
      sleep(1000)

# allow to change the default
# target url
proc loadConfig(): (string, seq[string]) =
  let path =  getHomeDir()&".jpscanrc"
  if fileExists(path):
    let f = open(path)
    defer: f.close()
    var url = f.readline()
    if url == "": url = BaseURL
    var ext = f.readline().split(" ")
    if ext[0] == "": ext = Extension
    return (url, ext)
  return (BaseURL, Extension)

proc main() =
  showLogo()
  (BaseURL, Extension) = loadConfig()
  var
    dest = getDest()
    choice: uint = 0
  while choice != 6:
    choice = menu(dest)
    try:
      handle(choice, dest)
    except CatchableError as e:
      echo e.msg
      echo "    an error occured..."
      sleep(2000)

try:
  main()
except CatchableError as e:
  echo "    unrecoverable error: ", e.msg
