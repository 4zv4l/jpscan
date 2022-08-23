import strutils, rdstdin, strtabs
import htmlparser, xmltree, puppy
import os, terminal
import unicode, uri
import sequtils

# default target Url
var BaseURL = "https://funquizzes.fun/uploads/manga/"
# default extension to look for
var Extension = ".jpg"
# array of available Files
var Files: seq[string]

# check for string in array of string
proc `in`(s: string, t: seq[string]): bool =
  for ss in t:
    if s == ss: return true
  return false

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
  echo "    Scan Extension   : ", Extension
  echo "    Current content  : ", dest
  getFolder(dest)
  echo "    *................................*"
  echo:
    let a = "    1. \e[33mDownload a file"
    let b = "      (load db)\e[0m"
    if Files.len > 0: a
    else: a & b
  echo:
    let c = "    2. \e[34mShow available files"
    let d = " (load db)\e[0m"
    if Files.len > 0: c
    else: c & d
  echo "    3. \e[32mCreate a folder\e[0m"
  echo "    4. \e[31mDelete a folder\e[0m"
  echo "    5. Quit"
  try:
    readLineFromStdin("    Your choice: ").parseUInt()
  except:
    6

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
  for file in Files:
    if checkStr(choice, file):
      echo "    - ", file
  let file = readLineFromStdin("    which file: ")
  for m in Files:
    if file == m: return file
  raise

# loop through all the arborescence of the web server
# to find the .extension files
proc findAllUrls(url: string): seq[string] =
  # TODO: wait for issue80 to be fixed
  # ' ' are replaced by '+'
  # https://github.com/treeform/puppy/issues/80
  let html_code = parseHtml(fetch(BaseURL&url))
  for a in html_code.findAll("a"):
    let entry = innerText(a)
    if entry in ["Name", "Last modified", "Size", "Description", "Parent Directory"]:
      echo entry
      continue
    elif entry.contains(Extension):
      result.add(BaseURL&url&entry)
    else:
      result = concat(result, findAllUrls(url&entry))

# get info from user to know which files download
proc getInfo(): seq[string] =
  if Files.len == 0: fetchFile()
  let file = getFile()
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
    let filename = dest&url[BaseURL.len..<url.len]
    dl(url, filename)
    loading(idx+1, urls.len)

# handle user's choice
proc handle(c: uint, dest: string) =
  case(c):
    of 1: # download file
      createDir(dest)
      let urls = getInfo()
      download(urls, dest)
    of 2: # show available files
      if Files.len == 0: fetchFile()
      for file in Files:
        echo "    - ", file
      discard readLineFromStdin("    Press Enter to continue")
    of 3: # add a folder
      getFolder(dest)
      let folder = readLineFromStdin("    Directory to create: ")
      createDir(dest&"/"&folder)
    of 4: # remove a folder
      getFolder(dest)
      let folder = readLineFromStdin("    Directory to delete: ")
      removeDir(dest&"/"&folder)
    of 5:
      echo "bye-bye :3"
    else:
      echo "bad choice..."
      sleep(1000)

# allow to change the default
# target url
proc loadConfig(): (string, string) =
  let path =  getHomeDir()&".jpscanrc"
  if fileExists(path):
    let f = open(path)
    defer: f.close()
    return (f.readLine(), f.readline())
  return (BaseURL, Extension)

proc main() =
  showLogo()
  (BaseURL, Extension) = loadConfig()
  let dest = getDest()
  var choice: uint = 0
  while choice != 5:
    choice = menu(dest)
    try:
      handle(choice, dest)
    except:
      echo "an error occured..."
      sleep(2000)

try:
  main()
except CatchableError as e:
  echo "error: ", e.msg
