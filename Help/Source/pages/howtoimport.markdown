@title How to import feeds from another reader

You can copy your feeds from another reader and add them to NetNewsWire.

You’ll need to consult the documentation for your other reader. What you’re looking for is a mention of “exporting feeds,” “exporting subscriptions,” or “exporting an OPML file.” (OPML is the file format that most readers use to import and export feeds.)

Once you have an OPML file from your other reader, you can import the feeds into NetNewsWire. Here’s how:

1. Choose <span class="ui">File > Import Feeds…</span>.

2. In the open sheet that appears, find and select your OPML file.

NetNewsWire will merge those feeds and folders with your current feeds list.

A few notes about importing:

- NetNewsWire will avoid making duplicate feeds. However, some feeds have more than one URL that may differ by as little as one character. Those will seem like duplicated feeds, even though technically the feeds are at different URLs. (It would be cool if NetNewsWire could detect that situation. It’s on our to-do list.)

- NetNewsWire supports folders but it doesn’t support folders-within-folders. This is the same as many other readers (such as Google Reader and FeedDemon) — but there are some readers, including older versions of NetNewsWire, that support folders-within-folders. In those cases, the folder hierarchy will get flattened out in NetNewsWire — but all the feeds will still appear.

- OPML files don’t include authentication information. For any authenticated feeds, NetNewsWire will ask for your username and password.
