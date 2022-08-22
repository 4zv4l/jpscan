import strutils, rdstdin, strtabs, re
import httpclient, htmlparser, xmltree
import os, osproc
import unicode, uri

const BaseURL = "https://funquizzes.fun/uploads/manga/"

proc clear() =
  when defined(Windows):
    discard execCmd("cls")
  else:
    discard execCmd("clear")

proc showLogo() =
  clear()
  echo "\e[33m"
  echo "          ██╗██████╗ ███████╗ ██████╗ █████╗ ███╗   ██╗██╗   ██╗███████╗"
  echo "          ██║██╔══██╗██╔════╝██╔════╝██╔══██╗████╗  ██║██║   ██║██╔════╝"
  echo "          ██║██████╔╝███████╗██║     ███████║██╔██╗ ██║██║   ██║█████╗  "
  echo "     ██   ██║██╔═══╝ ╚════██║██║     ██╔══██║██║╚██╗██║╚██╗ ██╔╝██╔══╝  "
  echo "     ╚█████╔╝██║     ███████║╚██████╗██║  ██║██║ ╚████║ ╚████╔╝ ██║     "
  echo "      ╚════╝ ╚═╝     ╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═══╝  ╚═══╝  ╚═╝     "
  echo "            A non official App - Just made by someone for fun           "
  echo "\e[0m"
  echo "\n"

# get destination folder for manga
proc getDest(): string =
  readLineFromStdin("    Chemin vers le dossier: ")

# concat urls
proc concatURLS(url: string, urls: seq[string]): seq[string] =
  for u in urls:
    result.add(url&"/"&u)

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

template showMenu(dest: string) =
  showLogo()
  echo "    Contenu du dossier: ", dest
  getFolder(dest)
  echo "    *.....................................*"
  echo "    1. \e[33mTelecharger un manga\e[0m"
  echo "    2. \e[32mAjouter un nouveau dossier manga\e[0m"
  echo "    3. \e[31mSupprimer un dossier manga\e[0m"
  echo "    4. Quitter"

# ask user for the menu's choice
proc getChoice(): uint =
  try:
    readLineFromStdin("    Que voulez-vous faire: ").parseUInt()
  except:
    5

# handle the menu
proc menu(dest: string): uint =
  showMenu(dest)
  getChoice()

# fetch every manga from the website
proc fetchManga(): seq[string] =
  echo "    Chargement des mangas disponibles..."
  var client = newHttpClient()
  let html_code = parseHtml(client.getContent(BaseURL))
  for a in html_code.findAll("a"):
    result.add(a.attrs["href"])

# fetch chapter from manga url
proc fetchChapi(url: string): seq[string] =
  var client = newHttpClient()
  let html_code = parseHtml(client.getContent(url))
  for a in html_code.findAll("a"):
    result.add(a.attrs["href"])

# fetch scans from chapter url
proc fetchScans(url: string): seq[string] =
  var client = newHttpClient()
  let html_code = parseHtml(client.getContent(url))
  for a in html_code.findAll("a"):
    if find(a.attrs["href"], re".jpg$") > 0:
      result.add(a.attrs["href"])

# check str to see if they are similar
proc checkStr(s, ss: string): bool =
  let a = s.contains(ss) or ss.contains(s)
  let b = s.toLower.contains(ss.toLower) or s.toUpper.contains(ss.toUpper)
  a or b

# return the manga/url from the user choice
proc getMangaInfo(mangas: seq[string]): tuple[name: string, url: string] =
  # get user choice
  var 
    choice = readLineFromStdin("    nom du manga: ")
    manga_url: seq[tuple[name: string, url: string]]
  # get similar manga names and check with user's choice
  for manga in mangas:
    if checkStr(manga.decodeUrl, choice):
      var
        url = BaseURL&manga
        name = manga.decodeUrl
      name.removeSuffix('/')
      echo "    - ", name
      manga_url.add((name: name,url: url))
  # if at least one match ask user
  if manga_url.len > 1:
    choice = readLineFromStdin("    Quel manga voulez-vous: ")
  for manga in manga_url:
    if choice == manga.name:
      return (manga.name, manga.url)
  raise

# get chapter by manga
proc getChapiInfo(manga: tuple[name: string, url: string]): seq[string] =
  echo "Chargement des chapitres disponibles pour ", manga.name
  var chapitres = fetchChapi(manga.url)
  for chapitre in chapitres.mitems:
    try:
      chapitre.removeSuffix('/')
      discard chapitre.parseUINT
      result.add(chapitre)
    except: discard

# get scans by chapters
proc getScansInfo(manga: string, urls: seq[string], chap: seq[string]): seq[tuple[num: string, url: seq[string]]] =
  echo "Chargement des scans disponibles pour ", manga
  for idx, url in urls:
    result.add((chap[idx], fetchScans(url)))

# get info such as manga name, chapters number and scans number (images)
proc getInfo(mangas: seq[string]): tuple[name: string, chap: seq[tuple[num: string, url: seq[string]]]] =
  let
    manga = getMangaInfo(mangas)
    chapi = getChapiInfo(manga)
    mc    = concatURLS(manga.url, chapi)
    scans = getScansInfo(manga.name, mc, chapi)
  return (manga.name, scans)

# multiply string
proc `*`(s: string, num: Natural): string {.noSideEffect} =
  var res = newStringOfCap(s.len * num)
  for i in 0..num:
    res.add(s)
  return res

# loading bar
proc loading(min, max: uint) =
  stdout.write "\r    scan ", min,"/",max
  flushFile(stdout)

# return the number of scans
proc getScansNumber(chap: seq[tuple[num: string, url: seq[string]]]): uint =
  for chaps in chap:
    for scan in chaps.url:
      result += 1

# download each scan to the destination folder
proc download(info: tuple[name: string, chap: seq[tuple[num: string, url: seq[string]]]], dest: string) =
  let client = newHttpClient()
  let num_scans = getScansNumber(info.chap)
  var counter: uint = 0
  echo "    downlading scans..."
  for chapi in info.chap:
    for scan in chapi.url:
      let url = BaseURL&"/"&info.name&"/"&chapi.num&"/"&scan
      createDir(dest&"/"&info.name)
      createDir(dest&"/"&info.name&"/"&chapi.num)
      try:
        client.downloadFile(url, dest&"/"&info.name&"/"&chapi.num&"/"&scan)
      except CatchableError as e:
        echo "=> ", url
        echo e.msg
        sleep(5000)
      counter += 1
      loading(counter, num_scans)
  client.close()

# handle user's choice
proc handle(c: uint, dest: string, mangas: seq[string]) =
  case(c):
    of 1: # download manga
      createDir(dest)
      let info = getInfo(mangas)
      download(info, dest)
    of 2: # add manga folder
      getFolder(dest)
      let folder = readLineFromStdin("    Dossier a creer: ")
      createDir(dest&"/"&folder)
    of 3: # remove manga folder
      getFolder(dest)
      let folder = readLineFromStdin("    Dossier a supprimer: ")
      removeDir(dest&"/"&folder)
    of 4:
      echo "au revoir :3"
    else:
      echo "wrong choice..."
      sleep(1000)

proc main() =
  showLogo()
  let dest = getDest()
  let mangas = try: fetchManga() except: @[]
  var c: uint = 0
  while c != 4:
    c = menu(dest)
    try:
      handle(c, dest, mangas)
    except:
      echo "une erreur est survenue..."
      sleep(1500)

try:
  main()
except CatchableError as e:
  echo "error: ", e.msg
