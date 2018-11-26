# KaraokeToVideo, converts mp3+cdg to mp4

Project to learn a bit about Apple's media APIs.  

**KaraokeToVideoGUI**

Basic macOS app to convert mp3+cdg to mp4.  Only supports drag and drop.  There is **very** little user feedback, the app can look hung for a min or two at a time!

Drag and drop files onto the app to convert mp3+cdg to mp4.

![GUI screenshot 1](Documentation/Images/dragAndDropFiles.png)
![GUI screenshot 3](Documentation/Images/conversionInProgress.png)

Play the mp4 like any other video file.
![GUI screenshot 5](Documentation/Images/mp4Playing.png)

**KaraokeToVideo**

The command line tool converts a MP3+CDG files into an MP4.

![Command line screenshot](Documentation/Images/commandLine.png)

Example Command Line conversion
```
./KaraokeToVideo Outkast\ -\ Hey\ Ya\!.cdg Outkast\ -\ Hey\ Ya\!.mp3 Outkast\ -\ Hey\ Ya\!.mp4
```

**KaraokeLib**

Library to handle converting MP3+CDG files into an MP4.  It's not very fast.  Takes my macBook Pro about 30s

**Acknowledgements**

OpenKJ's source code really helped me understand the CDG format.  Greatly appreciated!  [OpenKJ](https://github.com/coyote1357/OpenKJ).
