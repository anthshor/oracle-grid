Automated build for an Oracle Grid and ASM
------------------------------------------

1. Install oracle-rdbms-server-12cR1-preinstall
2. Install grid and ASM 

Requires software directory with Oracle binaries already downloaded and contained within it:

```
  $ cd software/
  $ ls
  keep				linuxamd64_12102_grid_1of2.zip	linuxamd64_12102_grid_2of2.zip
```

Run
---
```
  $ vagrant up
  $ vagrant ssh
```
