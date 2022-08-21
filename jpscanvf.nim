import strutils, osproc, os, httpclient

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
  stdout.write "    Chemin vers le dossier: "
  readline(stdin)

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
  echo "    1. \e[33mChoisir un manga\e[0m"
  echo "    2. \e[32mAjouter un nouveau manga\e[0m"
  echo "    3. \e[31mSupprimer un manga\e[0m"
  echo "    4. Quitter"

# ask user for the menu's choice
proc getChoice(): uint =
  stdout.write "    Que voulez-vous faire: "
  try:
    readline(stdin).parseUInt()
  except:
    5

# TODO: get all chapter from folder
# return list of urls
proc getInfo(): tuple[manga: string, urls: seq[string]] =
  # download all .jpg from the folder
  # url = "https://funquizzes.fun/uploads/manga/{manga}/{chapi}/"
  ("manga", @["url1","url2"])

proc main() =
  clear()
  showLogo()
  let dest = getDest()
  var c: uint = 0
  while c != 4:
    clear()
    showMenu(dest)
    c = getChoice()
    case(c):
      of 1: # download manga
        let 
          client = newHttpClient()
          info = getInfo()
        for url in info.urls:
          client.downloadFile(url, dest&"/"&info.manga&"/"&extractFilename(url))
        client.close()
      of 2: # add manga folder
        getFolder(dest)
        stdout.write "    Dossier a creer: "
        let folder = readline(stdin)
        createDir(dest&"/"&folder)
      of 3: # remove manga folder
        getFolder(dest)
        stdout.write "    Dossier a supprimer: "
        let folder = readline(stdin)
        removeDir(dest&"/"&folder)
      of 4:
        echo "au revoir :3"
      else:
        echo "wrong choice..."
        sleep(1000)

try:
  main()
except CatchableError as e:
  echo e.msg
