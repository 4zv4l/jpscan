import strutils, osproc, os, httpclient

proc showLogo() =
  echo "\e[33m"
  echo "	     ██╗██████╗ ███████╗ ██████╗ █████╗ ███╗   ██╗██╗   ██╗███████╗"
  echo "	     ██║██╔══██╗██╔════╝██╔════╝██╔══██╗████╗  ██║██║   ██║██╔════╝"
  echo "	     ██║██████╔╝███████╗██║     ███████║██╔██╗ ██║██║   ██║█████╗  "
  echo "	██   ██║██╔═══╝ ╚════██║██║     ██╔══██║██║╚██╗██║╚██╗ ██╔╝██╔══╝  "
  echo "	╚█████╔╝██║     ███████║╚██████╗██║  ██║██║ ╚████║ ╚████╔╝ ██║     "
  echo "	 ╚════╝ ╚═╝     ╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═══╝  ╚═══╝  ╚═╝     "
  echo "		A non official App - Just made by someone for fun                "
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
proc getFolder(path: string): string =
  for kind, path in walkDir(path):
    case kind:
      of pcDir: echo "    ", path
      else: discard
  stdout.write "    Quel dossier voulez-vous créer: "
  readline(stdin)

template showMenu(dest: string) =
  showLogo()
  echo "    Chemin vers le dossier: ", dest
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

proc getInfo(): (string, string) =
  let
    manga = (echo "manga   : "; readline(stdin))
    chapi = (echo "chapitre: "; readline(stdin))
  return (manga, chapi)

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
          (manga, chapi) = getInfo()
          # download all .jpg from the folder
          url = "https://funquizzes.fun/uploads/manga/{manga}/{chapi}/"
        var client = newHttpClient()
        client.downloadFile(url, dest&"/"&manga)
        client.close()
      of 2: # add manga folder
        let folder = getFolder(dest)
        createDir(dest&"/"&folder)
      of 3: # remove manga folder
        let folder = getFolder(dest)
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
