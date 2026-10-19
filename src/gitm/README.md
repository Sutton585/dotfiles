# gitm: minimal git reference clones

#### 1. Minimal full clone (default)
Grabs just enough history to run the program—shallow (depth 1), single default branch, and no old tags:
```bash
gitm clone https://github.com/sharkdp/bat.git
# Or into a specific folder:
gitm clone https://github.com/sharkdp/bat.git my-bat
```

#### 2. Directory-only clone (sparse)
Downloads tree metadata and **only** the blobs for the specified folder(s), using the standard `--` separator:
```bash
# Only grab the 'doc' folder:
gitm clone https://github.com/sharkdp/bat.git -- doc

# Grab 'doc' and 'examples' into custom directory 'bat-docs':
gitm clone https://github.com/sharkdp/bat.git bat-docs -- doc examples
```

#### 3. No `.git` export mode (replaces `etc/snag.sh`)
Pulls the directory and immediately deletes the `.git` folder:
```bash
gitm clone --no-git https://github.com/sharkdp/bat.git -- doc
```

#### 4. Need another directory later?
If you are inside a sparse repo and realize you also need another folder:
```bash
gitm add src/assets
gitm list
```

#### 5. Regular Git passthrough
Any other Git command runs as usual:
```bash
gitm status
gitm pull
gitm diff
```