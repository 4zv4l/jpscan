![image](https://user-images.githubusercontent.com/46655455/185997026-a4470822-6947-4d32-9594-afce1c5bcb22.png)

# jpscan
jpscan in nim

> Inspired by [SaigoNoo/jpscanvf](https://github.com/SaigoNoo/jpscanvf)

## Compile
`nimble install puppy`  
`nim c -d:release --opt:size jpscan.nim`

## Configuration
You can use a file in your User directory:  
linux: `$HOME/.jpscanrc`  
windows: `C:\Users\<your_user>\.jpscanrc`  

The first line of the file will be the url to search files  
The second line will be the extensions of the files separated by spaces  
example:  
```
https://funquizzes.fun/uploads/manga/
.jpg .png .gif .mp4
```
- if you don't use one of the line, just let it blank

# TODO
- [X] Wait for [issue](https://github.com/treeform/puppy/issues/80)
- [ ] Proper config system
