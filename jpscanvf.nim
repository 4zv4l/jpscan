import strutils, osproc, os, httpclient

proc showLogo() =
  echo "\e[33m"
  echo "	     ██╗██████╗ ███████╗ ██████╗ █████╗ ███╗   ██╗██╗   ██╗███████╗"
  echo "	     ██║██╔══██╗██╔════╝██╔════╝██╔══██╗████╗  ██║██║   ██║██╔════╝"
  echo "	     ██║██████╔╝███████╗██║     ███████║██╔██╗ ██║██║   ██║█████╗  "
  echo "	██   ██║██╔═══╝ ╚════██║██║     ██╔══██║██║╚██╗██║╚██╗ ██╔╝██╔══╝  "
  echo "	╚█████╔╝██║     ███████║╚██████╗██║  ██║██║ ╚████║ ╚████╔╝ ██║     "
  echo "	 ╚════╝ ╚═╝     ╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═══╝  ╚═══╝  ╚═╝     "
  echo "		A non official App - Just made by someone for fun				         "
  echo "\e[0m"
  echo "\n"

proc clear() =
  when defined(Windows):
    discard execCmd("cls")
  else:
    discard execCmd("clear")

proc getDest(): string =
  stdout.write "    Chemin vers la clef usb: "
  readline(stdin)

proc getFolder(path: string): string =
  for kind, path in walkDir(path):
    case kind:
      of pcDir: echo "Dir: ", path
      else: discard
  stdout.write "     Quel dossier voulez-vous créer: "
  readline(stdin)

template showMenu(dest: string) =
  showLogo()
  echo "    Chemin vers la clef usb: ", dest
  echo "    1. \e[33mChoisir un manga\e[0m"
  echo "    2. \e[32mAjouter un nouveau manga\e[0m"
  echo "    3. \e[31mSupprimer un manga\e[0m"
  echo "    4. Quitter"

proc getChoice(): uint =
  stdout.write "    Que voulez-vous faire: "
  try:
    readline(stdin).parseUInt()
  except:
    5

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
      of 1:
        let 
          mang = getManga()
          chap = getChap()
          url = "https://funquizzes.fun/uploads/manga/{mang}/{chap}/$i.jpg"
        var client = newHttpClient()
        client.downloadFile(url, dest&"/"&manga)
        client.close()
      of 2:
        let folder = getFolder(dest)
        createDir(dest&"/"&folder)
      of 3:
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
