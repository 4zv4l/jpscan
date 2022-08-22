import strutils, osproc, os, httpclient, rdstdin, htmlparser, xmltree, strtabs
import unicode, uri

const BaseURL = "https://funquizzes.fun/uploads/manga/"

proc showLogo() =
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

proc clear() =
  when defined(Windows):
    discard execCmd("cls")
  else:
    discard execCmd("clear")

proc getDest(): string =
  readLineFromStdin("    Chemin vers le dossier: ")

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

# fetch every manga from the website
proc fetchManga(): seq[string] =
  echo "Chargement des mangas disponibles..."
  var client = newHttpClient()
  let html_code = parseHtml(client.getContent(BaseURL))
  for a in html_code.findAll("a"):
    result.add(a.attrs["href"])

proc fetchChapi(url: string): seq[string] =
  var client = newHttpClient()
  let html_code = parseHtml(client.getContent(url))
  for a in html_code.findAll("a"):
    result.add(a.attrs["href"])

proc checkStr(s, ss: string): bool =
  let a = s.contains(ss) or ss.contains(s)
  let b = s.toLower.contains(ss.toLower) or s.toUpper.contains(ss.toUpper)
  a or b

# return the manga/url from the user choice
proc getMangaInfo(mangas: seq[string]): tuple[name: string, url: string] =
  # get user choice
  var 
    choice = readLineFromStdin("nom du manga: ")
    manga_url: seq[tuple[name: string, url: string]]
  # get similar manga names and check with user's choice
  for manga in mangas:
    if checkStr(manga, choice):
      var
        url = "https://funquizzes.fun/uploads/manga/"&manga
        name = manga.decodeUrl
      name.removeSuffix('/')
      manga_url.add((name: name,url: url))
  # if at least one match ask user
  if manga_url.len > 1:
    for manga in manga_url:
      echo manga.name
    choice = readLineFromStdin("Quel manga voulez-vous: ")
  for manga in manga_url:
    if choice == manga.name:
      return (manga.name, manga.url)
  raise

proc getChapiInfo(manga: tuple[name: string, url: string]): seq[string] =
  echo "Chargement des chapitres disponibles pour ", manga.name
  var chapitres = fetchChapi(manga.url)
  for chapitre in chapitres.mitems:
    try:
      chapitre.removeSuffix('/')
      discard chapitre.parseUINT
      result.add(chapitre)
    except: discard

proc getInfo(mangas: seq[string]): tuple[name: string, urls: seq[string]] =
  let
    manga = getMangaInfo(mangas)
    chapi = getChapiInfo(manga)
  return (manga.name, chapi)
  # download all .jpg from the folder
  # url = "https://funquizzes.fun/uploads/manga/{manga}/{chapi}/"
  

proc handle(c: uint, dest: string, mangas: seq[string]) =
  case(c):
    of 1: # download manga
      let 
        client = newHttpClient()
        info = getInfo(mangas)
      echo "=> ", info
      quit 0
      for url in info.urls:
        client.downloadFile(url, dest&"/"&info.name&"/"&extractFilename(url))
      client.close()
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
  clear()
  showLogo()
  let dest = getDest()
  var c: uint = 0
  while c != 4:
    let mangas = fetchManga()
    clear()
    showMenu(dest)
    c = getChoice()
    try:
      handle(c, dest, mangas)
    except:
      clear()
      showLogo()
      echo "error when handling your choice :)"
      echo "going back to the menu"
      sleep(1500)

try:
  main()
except CatchableError as e:
  echo e.msg
