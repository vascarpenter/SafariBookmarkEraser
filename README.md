#  SafariBookmarkEraser

- Safari の Bookmarks.plist (~/Library/Safari/Bookmark.plist) を開き、おのおののURLにアクセスを試み、 Hostが死んでいたりDNS解決できなかったりしたエントリを消してデスクトップに保存し直してくれる (いきなり置き換えるのはこわいので) 
- 各ブックマークに非同期でアクセスしにいくので、メモリはたくさん必要です
- 起動前に 環境設定のセキュリティ＆プライバシーから、フルディスクアクセス>SafariBookmarkEraserをチェックする必要があります
  - これはMandatory access controlによるものか
    - https://developer.apple.com/forums/thread/678819
- Changelog
  - v0.2
    - フルディスクアクセスできない場合にエラーダイアログを表示し先に進まない
    - Save ボタンを終了するまで disable
